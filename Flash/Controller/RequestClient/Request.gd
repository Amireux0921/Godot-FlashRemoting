## 异步HTTPRequest类
class_name Request extends HTTPRequest

var _Root: Node  # 根节点（用于管理子节点）

func _init(RootNode: Node = null) -> void:
	self._Root = RootNode
	# 初始化HTTP客户端（确保代理设置生效）
	

# 请求上下文类（封装响应数据）
class RequestContext:
	var Server: String = ""
	var ContentType: String = ""
	var Cookie: Dictionary = {}
	var Hander: Dictionary = {} 
	var Status: HTTPClient.Status
	var ResponseCode: HTTPClient.ResponseCode
	var Buffer: PackedByteArray = PackedByteArray()
	
	# UTF8字符串属性（安全转换）
	var UTF8: String:
		get:
			if Buffer.is_empty():
				return ""
			return Buffer.get_string_from_utf8()

## 核心请求方法（禁止外部调用）
func _DoRequest(URL: String,
				Method: HTTPClient.Method = HTTPClient.Method.METHOD_GET,
				Content: String = '',
				Cookie: Dictionary = {},
				Header: Dictionary = {}, 
				Redirect: bool = false,
				Data: PackedByteArray = [],
				Proxy: String = '') -> RequestContext:
	
	# 1. 设置代理
	_SetProxy(URL, Proxy)
	
	# 2. 处理请求数据
	var requestData: PackedByteArray
	if Method == HTTPClient.Method.METHOD_GET:
		requestData = Data
	elif Method == HTTPClient.Method.METHOD_POST:
		if !Content.is_empty():
			requestData = Content.to_utf8_buffer()
		else:
			requestData = Data
	else:
		requestData = Data
	
	# 3. 转换请求头
	var headerArray: PackedStringArray = _HandleHeader(Header, false)
	
	# 4. 发送请求（错误处理）
	var err: Error = request_raw(URL, headerArray, Method, requestData)
	if err != Error.OK:
		print("请求发送失败：", err)
		return null
	
	# 5. 等待请求完成
	var result = await request_completed as Array
	
	# 6. 封装响应上下文
	var context: RequestContext = RequestContext.new()
	context.Status = result[0] as int
	context.ResponseCode = result[1] as int
	context.Hander = _HandleHeader(result[2] as PackedStringArray, true) as Dictionary[String,String]
	context.Buffer = result[3] as PackedByteArray
	
	# 7. 解析响应头字段
	context.Server = context.Hander.get("Server", "")
	context.ContentType = context.Hander.get("Content-Type", "")
	
	# 8. 解析Cookie
	if context.Hander.has("Set-Cookie"):
		var cookieStr: String = context.Hander["Set-Cookie"]
		var cookieParts: Array = cookieStr.split("; ")
		for part in cookieParts:
			var kv: Array = part.split("=", 2)  # 仅分割第一个=（避免值含=）
			if kv.size() == 2:
				context.Cookie[kv[0]] = kv[1]
	
	return context

## 发送POST请求（封装）
func POST(URL: String, Header: Dictionary, Body: PackedByteArray) -> RequestContext:
	var req: Request = Request.new(self._Root)
	self._Root.add_child(req)
	var info: RequestContext = await req._DoRequest(
		URL,
		HTTPClient.Method.METHOD_POST,
		"",
		{},
		Header,
		false,
		Body,
        "127.0.0.1:8888"
	)
	# 修复：移除子节点并释放内存（避免泄漏）
	self._Root.remove_child(req)
	req.queue_free()
	return info

## 发送AMF请求（核心：序列化+反序列化）
func AMF(URL: String, Header: Dictionary, Message: AMFMessage) -> AMFMessage:
	# 1. 序列化AMF消息
	var writer: AMFWriter = AMFWriter.new()
	writer.WriteAMFMessage(Message)
	
	# 2. 强制设置AMF请求头（覆盖传入的Header）
	var amfHeader: Dictionary = Header.duplicate()
	amfHeader["Content-Type"] = "application/x-amf"
	
	# 3. 发送POST请求
	var req: Request = Request.new(self._Root)
	self._Root.add_child(req)
	var info: RequestContext = await req._DoRequest(
		URL,
		HTTPClient.Method.METHOD_POST,
		"",
		{},
		amfHeader,
		false,
		writer.buffer,
        "127.0.0.1:8888"
	)
	# 释放资源
	self._Root.remove_child(req)
	req.queue_free()
	
	# 4. 校验响应（严谨判断）
	if info == null:
		print("AMF请求失败：空响应上下文")
		return null
	if info.ResponseCode != HTTPClient.ResponseCode.RESPONSE_OK:
		print("AMF请求失败：响应码异常 ", info.ResponseCode)
		return null
	if !info.ContentType.begins_with("application/x-amf"):
		print("AMF请求失败：Content-Type不匹配 ", info.ContentType)
		return null
	if info.Buffer.is_empty():
		print("AMF请求失败：空响应数据")
		return null
	
	# 5. 解析AMF响应
	var reader: AMFReader = AMFReader.new()
	reader.buffer = info.Buffer
	return reader.ReadAMFMessage()

## 设置代理（修复逻辑错误）
func _SetProxy(url: String, Proxy: String) -> bool:
	if Proxy.is_empty():
		return false
	
	var proxyParts: Array = Proxy.split(':')
	if proxyParts.size() != 2:
		print("代理格式错误：", Proxy, "（正确格式：IP:端口）")
		return false
	
	var proxyHost: String = proxyParts[0]
	var proxyPort: int = int(proxyParts[1])
	
	# 修复：http用http代理，https用https代理（逻辑反转）
	if url.begins_with("https"):
		self.set_https_proxy(proxyHost, proxyPort)
	else:
		self.set_http_proxy(proxyHost, proxyPort)
	
	return true

## 转换请求头（修复空格问题）
## Ser: true = PackedStringArray → Dictionary | false = Dictionary → PackedStringArray
func _HandleHeader(Header: Variant, Ser: bool) -> Variant:
	# 空值校验
	if Header == null:
		if Ser:return {}
		return PackedStringArray()
	
	if !Ser:
		# Dictionary → PackedStringArray
		var headerDict: Dictionary = Header as Dictionary
		var headerArray: PackedStringArray = PackedStringArray()
		for key in headerDict:
			var value: String = str(headerDict[key])
			headerArray.append(str(key, ":", value))  # 无空格，符合HTTP规范
		return headerArray
	else:
		# PackedStringArray → Dictionary
		var headerArray: PackedStringArray = Header as PackedStringArray
		var headerDict: Dictionary = {}
		for line in headerArray:
			if line.is_empty():
				continue
			var kv: Array = line.split(":", 2)
			if kv.size() != 2:
				continue
			var key: String = kv[0].strip_edges()
			var value: String = kv[1].strip_edges()
			headerDict[key] = value
		return headerDict

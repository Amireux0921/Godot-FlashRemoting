##FlashRemoting远程RPC控制器[br]
##请将此类挂载到全局脚本推荐重命名(NetConnection)[br]
##然后在主场景 _ready() 函数下调用 NetConnection.Initialize()初始化控制器[br]
##如果你网关地址需要解析后端响应返回的地址，在解析成功后调用NetConnection.Initialize()也是可以的[br]
##在没初始化NetConnection.Initialize()之前，不能调用NetConnection.invoke()
class_name Connection extends Node

var _Gateway:String
var _OnResult:Signal
var _OnStatus:Signal
var _ResponseID:int
var _Handers:Dictionary
var _Req:Request



##初始化方法
func Initialize(GatewayURL:String,OnResult:Signal,OnStatus:Signal)->void:
	self._Gateway = GatewayURL
	self._OnResult = OnResult
	self._OnStatus = OnStatus
	
func _init() -> void:
	self._Req = Request.new(self)
func AddHander(Hander:Dictionary):
	self._Handers.merge(Hander)

func HanderClear():
	self._Handers.clear()

func Add_Response():
	self._ResponseID += 1

##调用类方法
func invoke(Target:String,Content:Variant)->bool:
	
	Add_Response()
	
	var Message:= await self._Req.AMF(self._Gateway,self._Handers,AMFMessage.new(3,[],[AMFBody.new(Target,str('/',self._ResponseID),Content)]))
	
	if Message == null:
		return false
	
	if _HandlerTarget(Message.Bodys[Message.Bodys.size()-Message.Bodys.size()].TargetUrl):
		
		self._OnResult.emit(Message.Bodys[Message.Bodys.size()-Message.Bodys.size()].Content)
		
	else:
		
		self._OnStatus.emit(Message.Bodys[Message.Bodys.size()-Message.Bodys.size()].Content)
	
	return true

func _HandlerTarget(Target:String)->bool:
	var list:=Target.split('/')
	if list[list.size()-1]=='onStatus': return false
	else:return true




#func invokeArray():
	
	

#func invokeMessage():
	
	

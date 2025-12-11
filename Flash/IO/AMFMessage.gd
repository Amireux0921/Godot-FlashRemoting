class_name AMFMessage

##AMF版本号 此版本好仅适用于数据包 真正的AMF版本号得从字节流中读取AMF3标识 才算真正的AMF3
var Version:int
##消息头数组
var Headers:Array[AMFHeader]
##消息体数组
var Bodys:Array[AMFBody]

const AMF0:int = 0
const AMF3:int = 3

func _init(Version:int = 3,Headers:Array[AMFHeader]=[],Bodys:Array[AMFBody]=[]) -> void:
	self.Version = Version
	self.Headers = Headers
	self.Bodys = Bodys
	

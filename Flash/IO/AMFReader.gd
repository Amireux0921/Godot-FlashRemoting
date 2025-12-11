##AmfRead 提供将AMF原始字节数组进行反序列化 因为Godot本身不支持动态类创建，所有解码的Class 都将转为字典，并且不会附带类名 仅保留属性键值对
class_name AMFReader extends StreamPeerBuffer

var buffer:PackedByteArray:
	get:
		return self.data_array
	set(value):
		self.data_array = value

var offset:int

var strings:PackedStringArray
var objects:Array[Variant]
var traits:Array[AMF3Trait]


##默认大端序读取数据
func _init(Endian:bool=true) -> void:
	self.big_endian = Endian
	self.strings = []
	self.objects = []
	self.traits = []

func CanReadByte()->bool:
	
	return self.offset < self.get_size()


func Readbyte()->int:
	var value = self.get_8()
	#seek(offset+1)
	return value

func ReadBoolean()->int:
	var value = self.get_8()
	#seek(offset+1)
	return value

func ReadInt16()->int:
	var value = self.get_16()
	#seek(offset+2)
	return value

func ReadUInt16()->int:
	var value = self.get_u16()
	#seek(offset+2)
	return value

func ReadInt32()->int:
	var value = self.get_32()
	#seek(offset+4)
	return value

func ReadUInt32()->int:
	var value = self.get_u32()
	#seek(offset+4)
	return value

func ReadDouble()->float:
	var value = self.get_double()
	#seek(offset+8)
	return value

func ReadString(length:int)->String:
	var value = self.get_utf8_string(length)
	#seek(offset+length)
	return value

func ReadAMFMessage()->AMFMessage:
	var Message = AMFMessage.new()
	
	if self.ReadInt16():Message.Version = AMFMessage.AMF3
	else:Message.Version = AMFMessage.AMF0
	Message.Headers = self.ReadAmfHeaders()
	Message.Bodys = self.ReadBodys()
	return Message


func ReadAmfHeaders()->Array[AMFHeader]:
	
	var value:Array[AMFHeader]=[]
	
	var HeaderCount = self.ReadInt16()
	#print(self.get_position())
	for i in HeaderCount:
		
		var Header:= AMFHeader.new()
		
		Header.Name = self.ReadAmf0String()
		Header.MustUnderstand = self.ReadBoolean()
		
		var headerLength = self.ReadInt32()
		
		Header.Content = self.ReadAmf0()
		
		value.append(Header)
		
		self.strings.clear()
		self.objects.clear()
		self.traits.clear()
	
	return value

func ReadBody()->AMFBody:
	
	var Body:= AMFBody.new()
	Body.TargetUri = self.ReadAmf0String()
	Body.ResponseUri = self.ReadAmf0String()
	var messageLength = self.ReadInt32()
	self.strings.clear()
	self.objects.clear()
	self.traits.clear()
	
	Body.Content = self.ReadAmf0()
	
	self.strings.clear()
	self.objects.clear()
	self.traits.clear()
	
	return Body


func ReadBodys()->Array[AMFBody]:
	
	var value:Array[AMFBody]=[]
	
	var messageCount = self.ReadInt16()
	
	for i in messageCount:
		
		var Body:= AMFBody.new()
		
		Body.TargetUrl = self.ReadAmf0String()
		Body.ResponseUrl = self.ReadAmf0String()
		
		var messageLength = self.ReadInt32()
		
		Body.Content = self.ReadAmf0()
		value.append(Body)
		
		self.strings.clear()
		self.objects.clear()
		self.traits.clear()
	
	return value


func ReadAmf0()->Variant:
	var type = self.Readbyte()
	
	match type:
		AMFType.AMF0TypeCode.Number:
			return self.ReadDouble()
		AMFType.AMF0TypeCode.Boolean:
			return self.ReadBoolean()
		AMFType.AMF0TypeCode.String:
			return self.ReadAmf0String()
		AMFType.AMF0TypeCode.ASObject:
			return self.ReadAmf0Object()
		AMFType.AMF0TypeCode.Null:
			return null
		AMFType.AMF0TypeCode.Undefined:
			return null
		AMFType.AMF0TypeCode.Reference:
			return self.ReadAmf0ObjectReference()
		AMFType.AMF0TypeCode.AssociativeArray:
			return self.ReadAmf0Array()
		AMFType.AMF0TypeCode.Array:
			return self.ReadAmf0StrictArray()
		AMFType.AMF0TypeCode.DateTime:
			return self.ReadAmf0Date()
		AMFType.AMF0TypeCode.LongString:
			return self.ReadAmf0LongString()
		AMFType.AMF0TypeCode.Undefined:
			return null
		AMFType.AMF0TypeCode.Xml:
			return self.ReadAmf0XmlDocument()
		AMFType.AMF0TypeCode.CustomClass:
			return self.ReadAmf0TypedObject()
		AMFType.AMF0TypeCode.AMF3Tag:
			return self.ReadAmf3()
		
	return null

func ReadAmf0String()->String:
	var length = self.ReadInt16()
	return self.ReadString(length)

func ReadAmf0LongString()->String:
	var length = self.ReadInt32()
	return self.ReadString(length)

func ReadAmf0Object():
	var value = ASObject.new()
	value.ClassName = ''
	value.DynamicMembersAndValues = {}
	
	self.objects.append(value)
	
	while true:
		
		var key = self.ReadAmf0String()
		
		if key.is_empty():
			self.Readbyte()
			break
		
		var data = ReadAmf0()
		
		value.DynamicMembersAndValues[key]=data
	
	return value.ToObject(AMFSerializer.Default)

func ReadAmf0TypedObject():
	
	var ClassName = self.ReadAmf0String()
	
	var value = ASObject.new()
	value.ClassName = ClassName
	value.DynamicMembersAndValues = {}
	
	self.objects.append(value)
	
	while true:
		
		var key = self.ReadAmf0String()
		
		if key.is_empty():
			self.Readbyte()
			break
		
		var data = self.ReadAmf0()
		
		value.DynamicMembersAndValues[key]=data
	
	return value


func ReadAmf0ObjectReference():
	
	var reference = self.ReadInt32()
	
	return self.objects[reference]

func ReadAmf0Array()->Dictionary:
	
	var value={}
	
	var length = self.ReadInt32()
	
	for i in length:
		
		var key = self.ReadAmf0String()
		var data = self.ReadAmf0()
		
		value[key]=data
	
	return value

func ReadAmf0StrictArray()->Array:
	
	var value = []
	
	var length = self.ReadInt32()
	
	for i in length:
		
		var data = self.ReadAmf0()
		
		value.append(data)
	
	return value

func ReadAmf0Date()->DateTime:
	
	var milliseconds:float = self.ReadDouble()
	var timeZone = self.ReadInt16()
	return DateTime.From(milliseconds)

func ReadAmf0XmlDocument()->XMLDocument:
	var xml = self.ReadAmf0LongString()
	return XML.parse_str(xml)

func ReadAmf3():
	var type = self.Readbyte()
	
	match type:
		AMFType.AMF3TypeCode.Undefined:
			return null
		AMFType.AMF3TypeCode.Null:
			return null
		AMFType.AMF3TypeCode.BooleanFalse:
			return false
		AMFType.AMF3TypeCode.BooleanTrue:
			return true
		AMFType.AMF3TypeCode.Integer:
			return self.ReadAmf3UInt29()
		AMFType.AMF3TypeCode.Number:
			return self.ReadDouble()
		AMFType.AMF3TypeCode.String:
			return self.ReadAmf3String()
		AMFType.AMF3TypeCode.Xml:
			return self.ReadAmf3XmlDocument()
		AMFType.AMF3TypeCode.DateTime:
			return self.ReadAmf3Date()
		AMFType.AMF3TypeCode.Array:
			return self.ReadAmf3Array()
		AMFType.AMF3TypeCode.Object:
			return self.ReadAmf3Object()
		AMFType.AMF3TypeCode.Xml2:
			return self.ReadAmf3XmlDocument()
		AMFType.AMF3TypeCode.ByteArray:
			return self.ReadAmf3ByteArray()
		AMFType.AMF3TypeCode.IntVector:
			return self.ReadAmf3Int32List()
		AMFType.AMF3TypeCode.UIntVector:
			return self.ReadAmf3UInt32List()
		AMFType.AMF3TypeCode.NumberVector:
			return self.ReadAmf3DoubleList()
		AMFType.AMF3TypeCode.ObjectVector:
			return self.ReadAmf3ObjectList()
	
	return null


func ReadFlags()->PackedByteArray:
	var flags = []
	
	while true:
		
		var flag = self.Readbyte()
		flags.append(flag)
		
		if (flag & 0x80) == 0x00:
			break
		
	
	return flags


# 读取 AMF3 格式的 29 位整数（对应 C# 的 ReadAmf3UInt29 方法）
func ReadAmf3UInt29() -> int:
	# 读取第一个字节
	var value_a: int = self.Readbyte()  # 假设 read_byte() 是读取单字节的方法
	
	# 1 字节情况（值在 0-0x7F 范围内）
	if value_a <= 0x7F:
		return value_a
	
	# 读取第二个字节
	var value_b: int = self.Readbyte() 
	
	# 2 字节情况（第二个字节在 0-0x7F 范围内）
	if value_b <= 0x7F:
		return (value_a & 0x7F) << 7 | value_b
	
	# 读取第三个字节
	var value_c: int = self.Readbyte() 
	
	# 3 字节情况（第三个字节在 0-0x7F 范围内）
	if value_c <= 0x7F:
		return (value_a & 0x7F) << 14 | (value_b & 0x7F) << 7 | value_c
	
	# 4 字节情况（完整 29 位）
	var value_d: int = self.Readbyte() 
	var ret: int = (value_a & 0x7F) << 22 | (value_b & 0x7F) << 15 | (value_c & 0x7F) << 8 | value_d
	
	# 处理符号位（对应 C# 中的负数转换逻辑）
	if (ret & 0x10000000) == 0x10000000:  # 268435456 = 0x10000000
		ret |= -0x20000000  # -536870912 = -0x20000000
	return ret


func ReadAmf3String()->String:
	var reference = self.ReadAmf3UInt29()
	
	if (reference & 0x01) == 0x01:
		var length = reference >> 1
		var value = self.ReadString(length)
		self.strings.append(value)
		return value
	return self.strings[reference >> 1]

func ReadAmf3XmlDocument()->XMLDocument:
	var reference = self.ReadAmf3UInt29()
	
	if (reference & 0x01) == 0x01:
		var length = reference >> 1
		var xml = self.ReadString(length)
		var value = XMLDocument.new()
		value.OuterXml = xml
		self.objects.append(value)
		
		return value
	
	return self.objects[reference >> 1]

func ReadAmf3Date()->DateTime:
	var reference = self.ReadAmf3UInt29()
	
	if (reference & 0x01) == 0x01:
		
		var milliseconds = self.ReadDouble()
		
		var value = DateTime.From(milliseconds)
		
		self.objects.append(value)
		
		return value
		
	return self.objects[reference >> 1]

func ReadAmf3Array()->Dictionary:
	var reference = self.ReadAmf3UInt29()
	
	if (reference & 0x01) == 0x01:
		
		var length = reference >> 1
		
		var value = AS3Array.new()
		
		self.objects.append(value)
		
		while true:
			
			var key = self.ReadAmf3String()
			
			if key.is_empty():
				break
			
			var data = self.ReadAmf3()
			value.SparseAssociative[key]=data
		
		for i in length:
			
			var data = self.ReadAmf3()
			value.StrictDense.append(data)
		
		return value.RestoreObject()
	
	return self.objects[reference >> 1]

func ReadAmf3Object():
	var reference = self.ReadAmf3UInt29()
	
	if (reference & 0x01) == 0x01:
		
		reference = reference >> 1
		
		var Tiait:AMF3Trait
		
		if (reference & 0x01) == 0x01:
			
			Tiait = AMF3Trait.new()
			
			reference = reference >> 1
			
			Tiait.IsExternalizable = (reference & 0x01) == 0x01
			
			reference = reference >> 1
			
			Tiait.IsDynamic = (reference & 0x01) == 0x01
			
			reference = reference >> 1
			
			var length = reference
			
			Tiait.ClassName = self.ReadAmf3String()
			
			self.traits.append(Tiait)
			
			for i in length:
				
				var member = self.ReadAmf3String()
				
				Tiait.Members.append(member)
			
		else:
			Tiait = self.traits[reference >> 1]
		
		var value = AS3Object.new()
		
		value.Trait = Tiait
		
		self.objects.append(value)
		
		if Tiait.IsExternalizable:
			print("需手动实现外部化")
			pass
		else:
			
			for i in Tiait.Members.size():
				
				var data = self.ReadAmf3()
				value.Values.append(data)
			
			if Tiait.IsDynamic:
				
				while true:
					
					var key = self.ReadAmf3String()
					
					if key.is_empty():
						break
					
					var data = self.ReadAmf3()
					
					value.DynamicMembersAndValues[key]=data
				
		
		
		
		return value.ToObject(AMFSerializer.Default)
		
	return self.objects[reference >> 1]

func ReadAmf3ByteArray()->PackedByteArray:
	var reference = self.ReadAmf3UInt29()
	
	if (reference & 0x01) == 0x01:
		
		var length = reference >> 1
		
		var value = []
		
		self.objects.append(value)
		
		for i in length:
			
			var data = self.Readbyte()
			
			value.append(data)
		
		return value
		
	return self.objects[reference >> 1]

func ReadAmf3Int32List()->Array[int]:
	var reference = self.ReadAmf3UInt29()
	
	if (reference & 0x01) == 0x01:
		
		var length = reference >> 1
		
		var fixedVector = self.ReadBoolean()
		
		var value:Array[int]=[]
		
		self.objects.append(value)
		
		for i in length:
			
			var data = self.ReadInt32()
			value.append(data)
		
		return value
		
	return self.objects[reference >> 1]


func ReadAmf3UInt32List()->Array[int]:
	var reference = self.ReadAmf3UInt29()
	
	if (reference & 0x01) == 0x01:
		
		var length = reference >> 1
		
		var fixedVector = self.ReadBoolean()
		
		var value:Array[int]=[]
		
		self.objects.append(value)
		
		for i in length:
			
			var data = self.ReadUInt32()
			value.append(data)
		
		return value
		
	return self.objects[reference >> 1]

func ReadAmf3DoubleList()->Array[float]:
	var reference = self.ReadAmf3UInt29()
	
	if (reference & 0x01) == 0x01:
		
		var length = reference >> 1
		
		var fixedVector = self.ReadBoolean()
		
		var value:Array[float]=[]
		
		self.objects.append(value)
		
		for i in length:
			
			var data = self.ReadDouble()
			value.append(data)
		
		return value
		
	return self.objects[reference >> 1]

func ReadAmf3ObjectList()->Array[Object]:
	var reference = self.ReadAmf3UInt29()
	
	if (reference & 0x01) == 0x01:
		
		var length = reference >> 1
		
		var fixedVector = self.ReadBoolean()
		
		var objectTypeName = self.ReadAmf3String()
		
		var value:Array[Object]=[] 
		
		self.objects.append(value)
		
		for i in length:
			
			var data = self.ReadAmf3()
			
			value.append(data)
		
		return value
		
	return self.objects[reference >> 1]

func ReadAmf3Dictionary()->Dictionary:
	var reference = self.ReadAmf3UInt29()
	
	if (reference & 0x01) == 0x01:
		
		var length = reference >> 1
		
		var weakKeys = self.ReadBoolean()
		
		var value:Dictionary={}
		
		self.objects.append(value)
		
		for i in length:
			
			var key = self.ReadAmf3()
			
			var data = self.ReadAmf3()
			
			value[key]=data
		
		return value
		
	return self.objects[reference >> 1]

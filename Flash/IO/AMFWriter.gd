##AmfWriter 提供将任意数据类型进行序列化,支持Godot原生类 和 class_name 自定义类的封装序列化
class_name AMFWriter extends StreamPeerBuffer

var buffer:PackedByteArray:
	get:
		return self.data_array
	set(value):
		self.data_array = value

var strings:PackedStringArray
var objects:Array[Variant]
var traits:Array[AMF3Trait]

var amf0References:Dictionary[Variant,ASObject]
var amf3References:Dictionary[Variant,AS3Object]

##在首次实例化对象的时候 设置字节序 默认为大端序 用于网络传输 ，小端序通常用于本地存储
func _init(Endian:bool=true) -> void:
	self.big_endian = Endian
	self.strings = []
	self.objects = []
	self.traits = []
	self.amf0References  = {}
	self.amf3References  = {}
	

func WriteByte(value:int):
	self.put_8(value)

func WriteBoolean(value:bool):
	self.put_8(value)

func WriteInt16(value:int):
	self.put_16(value)

func WriteUInt16(value:int):
	self.put_u16(value)

func WriteInt32(value:int):
	self.put_32(value)

func WriteUInt32(value:int):
	self.put_u32(value)

func WriteDouble(value:float):
	self.put_double(value)

func WriteString(value:String):
	self.put_data(value.to_utf8_buffer())

func WriteAMFMessage(value:AMFMessage):
	self.WriteInt16(value.Version)
	
	self.WriteAmfHeaders(value.Headers)
	self.WriteAmfBodys(value.Bodys)
	
	
	self.strings.clear()
	self.objects.clear()
	self.traits.clear()

func WriteAmfBody(value:AMFBody):
	self.WriteAmf0String(value.TargetUri)
	self.WriteAmf0String(value.ResponseUri)
	self.WriteInt32(-1)
	self.WriteAmf0(value.Content)



func WriteAmfHeaders(value:Array[AMFHeader]):
	self.WriteInt16(value.size())
	
	for item in value:
		self.WriteString(item.Name)
		self.WriteBoolean(item.MustUnderstand)
		self.WriteInt32(-1)
		self.WriteAmf0(item.Content)

func WriteAmfBodys(value:Array[AMFBody]):
	self.WriteInt16(value.size())
	
	for item in value:
		self.WriteAmf0String(item.TargetUrl)
		self.WriteAmf0String(item.ResponseUrl)

		self.WriteInt32(-1)
		
		self.WriteAmf0(item.Content)

func WriteAmf0(value:Variant):
	if value == null:
		self.WriteByte(AMFType.AMF0TypeCode.Null)
	elif value is float || value is int:
		self.WriteByte(AMFType.AMF0TypeCode.Number)
		self.WriteDouble(value)
	elif value is bool:
		WriteByte(AMFType.AMF0TypeCode.Boolean)
		WriteBoolean(value)
	elif value is String || value is StringName:
		var length = value.to_utf8_buffer().size()
		
		if length > 65535:
			self.WriteByte(AMFType.AMF0TypeCode.LongString)
			self.WriteAmf0LongString(value)
		else:
			self.WriteByte(AMFType.AMF0TypeCode.String)
			self.WriteAmf0String(value)
		
	elif value is ASObject:
# 					核心问题 无限递归引用 Array Reference  子类继承父类，套娃引用 2025/8/7
		if self.objects.has(value):
			self.WriteByte(AMFType.AMF0TypeCode.Reference)
			self.WriteAmf0ObjectReference(value)
		else:
			
			if value.IsAnonymous:
				self.WriteByte(AMFType.AMF0TypeCode.ASObject)
				self.WriteAmf0Object(value)
			else:
				self.WriteByte(AMFType.AMF0TypeCode.CustomClass)
				self.WriteAmf0TypedObject(value)
		
	elif value is Dictionary:
		self.WriteByte(AMFType.AMF0TypeCode.AssociativeArray)
		self.WriteAmf0Array(value)
	elif value is Array:
		self.WriteByte(AMFType.AMF0TypeCode.Array)
		self.WriteAmf0StrictArray(value)
	elif value is DateTime:
		self.WriteByte(AMFType.AMF0TypeCode.DateTime)
		self.WriteAmf0Date(value)
	elif value is XMLDocument:
		self.WriteByte(AMFType.AMF0TypeCode.Xml)
		self.WriteAmf0XmlDocument(value)
	else:
		WriteByte(AMFType.AMF0TypeCode.AMF3Tag)
		self.WriteAmf3(value)
		
		#var amf0Rererence:Amf0Object
		
		#if !self.amf0References.has(value):
			
			#amf0Rererence = Amf0Object.new()
			#amf0Rererence.ClassName = ''
			#amf0Rererence.DynamicMembersAndValues = {}
			
			#amf0Rererence.FromObject(value)
			
			#self.amf0References[value]=amf0Rererence
			
		
		#self.WriteAmf0(amf0Rererence)
		

func WriteAmf0String(value:String):
	self.WriteInt16(value.to_utf8_buffer().size())
	self.WriteString(value)

func WriteAmf0LongString(value:String):
	self.WriteInt32(value.to_utf8_buffer().size())
	self.WriteString(value)

func WriteAmf0Object(value:ASObject):
	
	self.objects.append(value)
	
	for item in value.DynamicMembersAndValues:
		self.WriteAmf0String(item)
		self.WriteAmf0(value.DynamicMembersAndValues[item])
	
	self.WriteAmf0String('')
	self.WriteByte(AMFType.AMF0TypeCode.EndOfObject)

func WriteAmf0TypedObject(value:ASObject):
	
	self.objects.append(value)
	
	self.WriteAmf0String(value.ClassName)
	
	for key in value.DynamicMembersAndValues:
		self.WriteAmf0String(key)
		self.WriteAmf0(value.DynamicMembersAndValues[key])
	
	self.WriteAmf0String('')
	self.WriteByte(AMFType.AMF0TypeCode.EndOfObject)

func WriteAmf0ObjectReference(value):
	self.WriteInt32(self.objects.find(value))

func WriteAmf0Array(value:Dictionary):
	self.WriteInt32(value.size())
	
	for key in value:
		self.WriteAmf0String(key)
		self.WriteAmf0(value[key])
	
	self.WriteAmf0String('')
	self.WriteByte(AMFType.AMF0TypeCode.EndOfObject)

func WriteAmf0StrictArray(value:Array[Variant]):
	self.WriteInt32(value.size())
	
	for item in value:
		self.WriteAmf0(item)
	

func WriteAmf0Date(value:DateTime):
	self.WriteDouble(value.timestamp)
	self.WriteInt16(0)

func WriteAmf0XmlDocument(value:XMLDocument):
	WriteAmf0LongString(XML.dump_str(value))

func WriteAmf3(value:Variant):
	
	if value == null:
		self.WriteByte(AMFType.AMF3TypeCode.Null)
	elif value is bool:
		
		if value:
			self.WriteByte(AMFType.AMF3TypeCode.BooleanTrue)
		else:
			self.WriteByte(AMFType.AMF3TypeCode.BooleanFalse)
	elif value is int:
		
		if value < -268435456 || value > 268435455:
			self.WriteByte(AMFType.AMF3TypeCode.Number)
			self.WriteDouble(value)
		else:
			self.WriteByte(AMFType.AMF3TypeCode.Integer)
			self.WriteAmf3UInt29(value)
	
	elif value is float:
		self.WriteByte(AMFType.AMF3TypeCode.Number)
		self.WriteDouble(value)
	elif value is String:
		self.WriteByte(AMFType.AMF3TypeCode.String)
		self.WriteAmf3String(value)
	elif value is XMLDocument:
		self.WriteByte(AMFType.AMF3TypeCode.Xml)
		self.WriteAmf3XmlDocument(value)
	elif value is DateTime:
		self.WriteByte(AMFType.AMF3TypeCode.DateTime)
		self.WriteAmf3Date(value)
	elif value is AS3Array:
		self.WriteByte(AMFType.AMF3TypeCode.Array)
		self.WriteAmf3Array(value)
	elif value is AS3Object:
		self.WriteByte(AMFType.AMF3TypeCode.Object)
		self.WriteAmf3Object(value)
	elif value is PackedByteArray:
		self.WriteByte(AMFType.AMF3TypeCode.ByteArray)
		self.WriteAmf3ByteArray(value)
	elif value is Array[int]:
		self.WriteByte(AMFType.AMF3TypeCode.IntVector)
		self.WriteAmf3Int32List(value)
	#elif value is Array[]  godot 缺少uint判断 我自己也懒得写
	elif value is Array[float]:
		self.WriteByte(AMFType.AMF3TypeCode.NumberVector)
		self.WriteAmf3DoubleList(value)
	#elif value is Array[Object]:
		#self.WriteByte(Amf3Type.AMF3Type.VECTOR_OBJECT)
		#self.WriteAmf3ObjectList(value)
	#elif value is Dictionary:
		#self.WriteByte(Amf3Type.AMF3Type.DICTIONARY)
		#self.WriteAmf3Dictionary(value)
	else:
		var amf3Rererence:AS3Object
		
		if !self.amf3References.has(amf3Rererence):
			
			amf3Rererence = AS3Object.new()
			
			amf3Rererence.Trait.ClassName = ''
			amf3Rererence.Trait.IsDynamic = false 
			amf3Rererence.Trait.IsExternalizable = false
			amf3Rererence.Trait.Members = []
			
			amf3Rererence.FromObject(value)
			self.amf3References[value] = amf3Rererence
		
		self.WriteAmf3(amf3Rererence)

func WriteAmf3UInt29(value:int):
	value = value & 0x1FFFFFFF  # 确保29位范围
	
	if value < 0x80:            # 1字节范围 [0, 0x7F]
		self.WriteByte(value)
	elif value < 0x4000:        # 2字节范围 [0x80, 0x3FFF]
		self.WriteByte(0x80 | (value >> 7))
		self.WriteByte(value & 0x7F)
	elif value < 0x200000:      # 3字节范围 [0x4000, 0x1FFFFF]
		self.WriteByte(0x80 | (value >> 14))
		self.WriteByte(0x80 | ((value >> 7) & 0x7F))
		self.WriteByte(value & 0x7F)
	else:                       # 4字节范围 [0x200000, 0x1FFFFFFF]
		self.WriteByte(0x80 | (value >> 22))
		self.WriteByte(0x80 | ((value >> 15) & 0x7F))
		self.WriteByte(0x80 | ((value >> 8) & 0x7F))
		self.WriteByte(value & 0xFF)  # 直接写入低8位
	

func WriteAmf3String(value:String):
	
	if value != '':
		
		if !self.strings.has(value):
			
			self.strings.append(value)
			
			self.WriteAmf3UInt29(value.to_utf8_buffer().size() << 1 | 0x01)
			
			self.WriteString(value)
		else:
			self.WriteAmf3UInt29(self.strings.find(value) << 1 | 0x00)
	else:
		self.WriteAmf3UInt29(value.to_utf8_buffer().size() << 1 | 0x01)
		
		self.WriteString(value)

func WriteAmf3XmlDocument(value:XMLDocument):
	if !self.objects.has(value):
		self.objects.append(value)
		self.WriteAmf3UInt29(XML.dump_str(value).to_utf8_buffer().size() << 1 | 0x01)
		self.WriteString(XML.dump_str(value))
	else:
		self.WriteAmf3UInt29(self.objects.find(value) << 1 | 0x00)

func WriteAmf3Date(value:DateTime):
	
	if !self.objects.has(value):
		self.objects.append(value)
		self.WriteAmf3UInt29(0x01)
		
		self.WriteDouble(value.timestamp)
	else:
		self.WriteAmf3UInt29(self.objects.find(value) << 1 | 0x00)

func WriteAmf3Array(value:AS3Array):
	
	if !self.objects.has(value):
		
		self.objects.append(value)
		
		self.WriteAmf3UInt29(value.StrictDense.size() << 1 | 0x01)
		
		for item in value.SparseAssociative:
			self.WriteAmf3String(item)
			self.WriteAmf3(value.SparseAssociative[item])
		
		self.WriteAmf3String('')
		
		for item in value.StrictDense:
			self.WriteAmf3(item)
	else:
		
		self.WriteAmf3UInt29(self.objects.find(value) << 1 | 0x00)

func WriteAmf3Object(value:AS3Object):
	
	if !self.objects.has(value):
		
		self.objects.append(value)
		
		if !self.traits.has(value.Trait):
			var members_count = 0
			if not value.Trait.IsExternalizable:
				members_count = value.Trait.Members.size()
			var members_part = members_count << 4
		
			var dynamic_part = 0
			if value.Trait.IsDynamic:
				dynamic_part = 0x01 << 3
		
			var externalizable_part = 0
			if value.Trait.IsExternalizable:
				externalizable_part = 0x01 << 2
		
			var fixed_part1 = 0x01 << 1
			var fixed_part2 = 0x01
		
			var total_value = members_part | dynamic_part | externalizable_part | fixed_part1 | fixed_part2
		
			self.WriteAmf3UInt29(total_value)
			self.WriteAmf3String(value.Trait.ClassName)
		
			if !value.Trait.IsExternalizable:
				
				for item in value.Trait.Members:
					self.WriteAmf3String(item)
				
		else:
			self.WriteAmf3UInt29(self.traits.find(value.Trait) << 2 | 0x00 << 1 | 0x01)
				
			
		if value.Trait.IsExternalizable:
			var externizable = value.to_string()
			pass
		else:
			
			for item in value.Values:
				
				self.WriteAmf3(item)
			
			if value.Trait.IsDynamic:
				
				for item in value.DynamicMembersAndValues:
					
					self.WriteAmf3String(item)
					self.WriteAmf3(value.DynamicMembersAndValues[item])
				
				self.WriteAmf3String('')
				
	else:
		self.WriteAmf3UInt29(objects.find(value) << 1 | 0x00)

func WriteAmf3ByteArray(value:PackedByteArray):
	
	if !self.objects.has(value):
		
		self.objects.append(value)
		
		self.WriteAmf3UInt29(value.size() << 1 | 0x01)
		
		for i in value:
			self.WriteByte(i)
	else:
		self.WriteAmf3UInt29(objects.find(value) << 1 | 0x00)

func WriteAmf3Int32List(value:Array[int]):
	
	if !self.objects.has(value):
		
		self.objects.append(value)
		
		self.WriteAmf3UInt29(value.size() << 1 | 0x01)
		self.WriteBoolean(false)
		
		for i in value:
			self.WriteInt32(i)
	else:
		self.WriteAmf3UInt29(objects.find(value) << 1 | 0x00)

func WriteAmf3UInt32List(value:Array[int]):
	
	if !self.objects.has(value):
		
		self.objects.append(value)
		
		self.WriteAmf3UInt29(value.size() << 1 | 0x01)
		self.WriteBoolean(false)
		
		for i in value:
			self.WriteUInt32(i)
	else:
		self.WriteAmf3UInt29(objects.find(value) << 1 | 0x00)

func WriteAmf3DoubleList(value:Array[float]):
	if !self.objects.has(value):
		
		self.objects.append(value)
		
		self.WriteAmf3UInt29(value.size() << 1 | 0x01)
		self.WriteBoolean(false)
		
		for i in value:
			self.WriteDouble(i)
	else:
		self.WriteAmf3UInt29(objects.find(value) << 1 | 0x00)

func WriteAmf3ObjectList(value:Array):
	
	if !self.objects.has(value):
		
		self.objects.append(value)
		
		self.WriteAmf3UInt29(value.size() << 1 | 0x01)
		self.WriteBoolean(false)
		self.WriteAmf3String('*')
		for i in value:
			self.WriteAmf3(i)
	else:
		self.WriteAmf3UInt29(objects.find(value) << 1 | 0x00)


func WriteAmf3Dictionary(value:Dictionary):
	
	if !self.objects.has(value):
		
		self.objects.append(value)
		
		self.WriteAmf3UInt29(value.size() << 1 | 0x01)
		self.WriteBoolean(false)
		for key in value:
			self.WriteAmf3(key)
			self.WriteAmf3(value[key])
	else:
		self.WriteAmf3UInt29(objects.find(value) << 1 | 0x00)

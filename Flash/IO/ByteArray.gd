##AmfWriter 提供将任意数据类型进行序列化,支持Godot原生类 和 class_name 自定义类的封装序列化
class_name ByteArray extends StreamPeerBuffer



var Buffer:PackedByteArray:
	get:
		return self.data_array
	set(value):
		self.clear()
		self.put_data(value)

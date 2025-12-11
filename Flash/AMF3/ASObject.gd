##Amf0Object对象 支持将任意Object 转换成Amf0Object
class_name ASObject extends IASObject

var ClassName: String
var IsAnonymous: bool: 
	get:
		return ClassName.is_empty()
		
var DynamicMembersAndValues: Dictionary = {}  # 存储属性键值对

func ToObject(serializer:IAMFSerializer)->Variant:
	
	if IsAnonymous:
		return DynamicMembersAndValues
	else:
		
		var Nl:= self.ClassName.split('.')
		
		var ClassInfo:ClassDBS.ClassInfo = ClassDBS.Ins.GetTypeByTraitClassName(self.ClassName)
		
		if ClassInfo != null:
			
			##如果序列化的类有Tag标签 则序列化Tag名 否则序列化 空间命名
			if ClassInfo.ClassTag.is_empty():
				self.Trait.ClassName = ClassInfo.Namespace
			else:
				self.Trait.ClassName = ClassInfo.ClassTag
			
			var script:Script = load(ClassInfo.ClassPath)
			
			var instance = script.new()
			
			if ClassInfo.Is_Abstract && instance == null:
				return self.DynamicMembersAndValues
			
			for key in DynamicMembersAndValues:
				instance.set(key,DynamicMembersAndValues[key])
			
			return instance
		else:
			##如果有类名但无法实例化 则返回字典 并附带_explicitType + 类名
			self.DynamicMembersAndValues['_explicitType'] = self.ClassName
			return self.DynamicMembersAndValues

func FromObject(value:Variant)->void:
	
	var script :Script = value.get_script()
	
	if script != null:
		
		var type:= ClassDBS.Ins.GetTypeByTraitClassName(script.get_global_name())
		
		if type.ClassTag.is_empty():
			self.Trait.ClassName = type.Namespace
		else:
			self.Trait.ClassName = type.ClassTag
		
		for item in type.ClassMembers:
			
			self.DynamicMembersAndValues[item] = value.get(item)
			
		

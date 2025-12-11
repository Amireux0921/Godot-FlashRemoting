class_name ClassDBS

static var ListClass:Array[ClassInfo]

class ClassInfo:
	var ClassBase:String
	var Is_Abstract:bool
	var ClassName:String
	var Namespace:String
	var ClassTag:String
	var ClassPath:String
	var ClassMembers:PackedStringArray


static var Ins:ClassDBS:
	get:
		return ClassDBS.new()

func _init() -> void:
	
	if !ListClass.size():
		for item in ProjectSettings.get_global_class_list():
			var script:Script = load(item.path)
			if script != null:
				var Class:=ClassInfo.new()
				Class.ClassBase = item.base
				Class.ClassName = item.class
				Class.Is_Abstract = item.is_abstract
				Class.ClassPath = item.path
				Class.Namespace = Class.ClassPath.replace('res://','').replace('/',".").replace('.gd','')
				
				for i in script.get_script_property_list():
					if i.usage == PropertyUsageFlags.PROPERTY_USAGE_SCRIPT_VARIABLE:
						Class.ClassMembers.append(i.name)
						
					if i.usage == PropertyUsageFlags.PROPERTY_USAGE_CATEGORY and i.type == Variant.Type.TYPE_NIL and i.hint==PropertyHint.PROPERTY_HINT_NONE and i.hint_string == '':
						Class.ClassTag = i.name
				ListClass.append(Class)


##查询类是否存在
func Get_Class(ClassName:String)->ClassInfo:
	
	if ClassName == '' : return null
	
	for item in ListClass:
		
		if item.ClassName == ClassName:
			return item
	
	return null

func Get_Class_Namespace(Namespace:String)->ClassInfo:
	
	if Namespace == '' : return null
	
	for i in ListClass:
		
		if Namespace == i.Namespace:
			return i
	
	return null


##查询已注册的类中是否存在@export_category所备注的标签
func Get_Class_Tag(Tag:String)->ClassInfo:
	
	if Tag == '' : return null
	
	for item in ListClass:
		
		if item.ClassTag == Tag:
			return item
	
	return null

##获取当前脚本的类名 不存在返回空字符串
func GetClassName(Value:Object):
	
	var script:Script =Value.get_script()
	
	if script == null:
		return Value.get_class()
		
	var name := script.get_global_name()
	
	for item in ListClass:
		
		if item.ClassName == name:
			return item.Namespace
	
	return ''

func CreateInstance(type:ClassInfo)->Variant:
	return load(type.ClassPath).new()


func GetTypeByTraitClassName(name:String)->ClassInfo:
	
	var classInfo:ClassInfo = self.Get_Class(name)
	
	if classInfo == null:
		
		classInfo = ClassDBS.Ins.Get_Class_Namespace(name)
	
	if classInfo == null:
		
		classInfo = ClassDBS.Ins.Get_Class_Tag(name)
	
	
	return classInfo

class_name AS3Object extends IASObject

var Trait:AMF3Trait = AMF3Trait.new()
var Values:Array[Variant]
##匿名对象成员和值
var DynamicMembersAndValues:Dictionary

func _to_string() -> String:
	return self.Trait.to_string()

## 将ASObject对象还原成原始对象
func ToObject(serializer:IAMFSerializer)->Variant: 
	
	var toObject:Variant
	
	if Trait.IsDynamic:
		
		toObject = DynamicMembersAndValues
		
	elif Trait.IsAnonymous:
		
		var dic:Dictionary={}
		
		for i in Trait.Members.size():
			
			dic[Trait.Members[i]]=Values[i]
			
		toObject = dic
	else:
		
		var Internal = ToHandleVariant()
		
		if Internal != null: return Internal
		
		if ClassDB.class_exists(self.Trait.ClassName):
			
			toObject = ClassDB.instantiate(self.Trait.ClassName)
			
			
		else:
			
			var type = ClassDBS.Ins.GetTypeByTraitClassName(self.Trait.ClassName)
			
			if type != null:
			
				toObject = ClassDBS.Ins.CreateInstance(type)
				
				for i in Trait.Members.size():
					
					var value = serializer.Normalize(Values[i])
					
					toObject.set(Trait.Members[i],value)
			else:
				
				toObject = {}
				
	return toObject


## 将任意对象封装成AS3Object
## UsageFlags: 属性过滤规则，默认仅提取脚本变量
func FromObject(value:Variant)->void:
	
	##判断是否为Object类还是内置类
	if value is Object:
		
		var script :Script = value.get_script()
		
		if script != null:
			
			if value is IExternalizable:
				self.Trait.IsExternalizable = true
			
			var ClassInfo:ClassDBS.ClassInfo = ClassDBS.Ins.GetTypeByTraitClassName(script.get_global_name())
		
		#存在脚本类 则获取其属性
			if ClassInfo != null:
				
				if ClassInfo.ClassTag.is_empty():
					self.Trait.ClassName = ClassInfo.Namespace
				else:
					self.Trait.ClassName = ClassInfo.ClassTag
				
				
				for item in ClassInfo.ClassMembers:
					
					self.Trait.Members.append(item)
					self.Values.append(value.get(item))
			else:
				
				Trait.IsDynamic = true
				
				for item in value.get_property_list():
					
					if item.usage == PropertyUsageFlags.PROPERTY_USAGE_SCRIPT_VARIABLE:
						
						self.DynamicMembersAndValues.set(item.name,value.get(item.name))
					
		else:
			
			if !ClassDB.class_exists(value.get_class()):
				
				var toobject:Object = value
				
				Trait.IsDynamic = true
				
				for item in value.get_property_list():
						
						if item.usage == PropertyUsageFlags.PROPERTY_USAGE_SCRIPT_VARIABLE:
							
							self.DynamicMembersAndValues.set(item.name,value.get(item.name))
			else:
				
				self.Trait.ClassName = value.get_class()
				
				for item in ClassDB.class_get_property_list(value.get_class(),true):
					
					if item.usage == PropertyUsageFlags.PROPERTY_USAGE_DEFAULT: 
						#print(item)
						self.Trait.Members.append(item.name)
						self.Values.append(value.get(item.name))
				
		#print_debug("封装 AS3Object 完成：",to_string())
	else: ##不是脚本类则处理内置类
		
		HandleVariant(value)
		
		return
		
		

func SetValue(name,value,a):
	self.Trait.ClassName = name
	for i in value:
		self.Trait.Members.append(i)
		self.Values.append(value[i])


func ToHandleVariant()->Variant:
	var TypeName = self.Trait.ClassName
	
	var Dic:Dictionary = {}
	
	for i in self.Trait.Members.size():
		Dic[self.Trait.Members[i]] = self.Values[i]
	
	if TypeName == 'Vector2':
		return Vector2(Dic.x,Dic.y)
	elif TypeName == 'Vector2i':
		return Vector2i(Dic.x,Dic.y)
	elif TypeName == 'Vector3':
		return Vector3(Dic.x,Dic.y,Dic.z)
	elif TypeName == 'Vector3i':
		return Vector3i(Dic.x,Dic.y,Dic.z)
	elif TypeName == 'Vector4':
		return Vector4(Dic.x,Dic.y,Dic.z,Dic.w)
	elif TypeName == 'Vector4i':
		return Vector4i(Dic.x,Dic.y,Dic.z,Dic.w)
	elif TypeName == 'AABB':
		return AABB(Dic.position,Dic.size)
	elif TypeName == 'Basis':
		return Basis(Dic.x,Dic.y,Dic.z)
	elif TypeName == 'Color':
		return Color(Dic.r,Dic.g,Dic.b,Dic.a)
	elif TypeName == 'Plane':
		return Plane(Dic.normal)
	elif TypeName == 'Projection':
		return Projection(Dic.x,Dic.y,Dic.z,Dic.w)
	elif TypeName == 'Quaternion':
		return Quaternion(Dic.x,Dic.y,Dic.z,Dic.w)
	elif TypeName == 'Rect2':
		return Rect2(Dic.position,Dic.size)
	elif TypeName == 'Rect2i':
		return Rect2i(Dic.position,Dic.size)
	elif TypeName == 'Transform2D':
		return Transform2D(Dic.x,Dic.y,Dic.origin)
	elif TypeName == 'Transform3D':
		return Transform3D(Dic.basis,Dic.origin)
	
	return null
func HandleVariant(value:Variant):
	
	if value is Vector2:
		self.SetValue('Vector2',{x = value.x, y = value.y} , true)
	elif value is Vector2i:
		self.SetValue('Vector2i',{x = value.x, y = value.y} , true)
	elif value is Vector3:
		self.SetValue('Vector3',{x = value.x, y = value.y , z = value.z} , true)
	elif value is Vector3i:
		self.SetValue('Vector3i',{x = value.x, y = value.y , z = value.z} , true)
	elif value is Vector4:
		self.SetValue('Vector4',{w = value.w , x = value.x, y = value.y , z = value.z } , true)
	elif value is Vector4i:
		self.SetValue('Vector4i',{w = value.w , x = value.x, y = value.y , z = value.z } , true)
	elif value is AABB:
		self.SetValue('AABB',{end = value.end , position = value.position , size = value.size} , true)
	elif value is Basis:
		self.SetValue('Basis',{x = value.x , y = value.y , z = value.z},true)
	elif value is Color:
		self.SetValue('Color',{r = value.r , g = value.g , b = value.b , a = value.a},true)
	elif value is Plane:
		self.SetValue('Plane',{d = value.d , normal = value.normal ,x = value.x , y = value.y , z = value.z },true)
	elif value is Projection:
		self.SetValue('Projection',{w = value.w , x = value.x, y = value.y , z = value.z } , true)
	elif value is Quaternion:
		self.SetValue('Quaternion',{w = value.w , x = value.x, y = value.y , z = value.z } , true)
	elif value is Rect2:
		self.SetValue('Rect2',{end = value.end , position = value.position , size = value.size} , true)
	elif value is Rect2i:
		self.SetValue('Rect2i',{end = value.end , position = value.position , size = value.size} , true)
	elif value is Transform2D:
		self.SetValue('Transform2D',{origin = value.origin , x = value.x , y = value.y} , true)
	elif value is Transform3D:
		self.SetValue('Transform3D',{basis = value.basis , origin = value.origin} , true)

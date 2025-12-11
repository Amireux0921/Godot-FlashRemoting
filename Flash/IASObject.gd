@abstract class_name IASObject

##将任意对象封装成ASObject
@abstract func FromObject(value:Variant)->void
##将ASObject对象还原成原始对象
@abstract func ToObject(serializer:IAMFSerializer)->Variant

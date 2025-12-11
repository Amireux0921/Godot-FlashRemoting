class_name AMF3Trait 

var ClassName:String
var IsAnonymous:bool:
	get:
		return self.ClassName.is_empty()
var IsDynamic:bool
var IsExternalizable:bool
var Members:PackedStringArray

func _to_string() -> String:
	if IsDynamic:
		return "Dynamic"
	elif IsExternalizable:
		return "Externalizable"
	elif IsAnonymous:
		return "Anonymous"
	return str("Class: ", ClassName) 

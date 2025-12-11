##基本上用不到,但已实现
class_name AS3Array

var StrictDense: Array[Variant]
var SparseAssociative: Dictionary[String,Variant]


func ToString():
	return str("Array with ",StrictDense.size()," items and ",SparseAssociative.size()," key-value pairs")


static func  FromObject(value:Variant):
	
	var v:=AS3Array.new()
	
	if value is AS3Array: return value
	
	
	elif value is Array:
		v.StrictDense = value
		return v
	else :
		v.StrictDense.append(value)
		return v
	
	
	

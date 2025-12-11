class_name AMFSerializer extends IAMFSerializer

static var _default:=AMFSerializer.new()

static var Default:AMFSerializer:
	get:
		return _default

func Normalize(value:Variant):
	
	if value is IASObject:
		return value.ToObject(self)
	
	if value is Array:
		var normalized_arr = []
		
		for i in value:
			normalized_arr.append(Normalize(i))
		
		return normalized_arr
	
	if value is Dictionary[String,Variant]:
		
		var normalized_dict: Dictionary = {}
		
		for i in value:
			
			normalized_dict[i] = Normalize(value[i])
		
		return normalized_dict
	
	if value is Dictionary:
		var normalized_dict: Dictionary = {}
		for key in value:
			var normalized_key = Normalize(key)
			normalized_dict[normalized_key] = Normalize(value[key])
		return normalized_dict
	
	return value

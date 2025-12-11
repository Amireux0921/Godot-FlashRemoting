class_name AMFHeader

var Name:String
var MustUnderstand:bool
var Content:Variant

func _init(Name:String = "",MustUnderstand:bool = false , Content:Variant = null) -> void:
	self.Name = Name
	self.MustUnderstand = MustUnderstand
	self.Content = Content
	

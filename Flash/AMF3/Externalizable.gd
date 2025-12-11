class_name Externalizable extends IExternalizable

static var Ins:Externalizable:
	get:
		return Externalizable.new()


func ReadExternal(input:IDataInput):
	pass

func WriteExternal(output:IDataOutput):
	pass

class_name AMFType

enum AMF0TypeCode {
	Number = 0,
	Boolean = 1,
	String = 2,
	ASObject = 3,
	Null = 5,
	Undefined = 6,
	Reference = 7,
	AssociativeArray = 8,
	EndOfObject = 9,
	Array = 10,
	DateTime = 11,
	LongString = 12,
	Xml = 15,
	CustomClass = 16,
	AMF3Tag = 17,
}

enum AMF3TypeCode{
	Undefined = 0,
	Null = 1,
	BooleanFalse = 2,
	BooleanTrue = 3,
	Integer = 4,
	Number = 5,
	String = 6,
	DateTime = 8,
	Array = 9,
	Object = 10,
	Xml = 11,
	Xml2 = 7,
	ByteArray = 12,
	IntVector = 13,
	UIntVector = 14,
	NumberVector = 15,
	ObjectVector = 16,
	Dictionary = 17
}

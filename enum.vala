namespace Endf {
	
	public string enum_to_string(Type type, int d) {
		EnumClass @class = (EnumClass) type.class_ref();
		unowned EnumValue value = @class.get_value(d);
		if(value != null) {
			return value.value_name;
		} else {
			return "unknown(%d)".printf(d);
		}
	}
}

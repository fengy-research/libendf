namespace Endf {
	/**
	 * Format an enum value to a string 
	 *
	 * A wrapper to something that's really lack in vala
	 **/
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

class_name State

func clone():
	var cloned =  get_script().new()
	for prop in get_property_list():
		if not prop.name in ["Reference", "Script Variables", "Script", "script" ]:
			cloned.set(prop.name, get(prop.name))
	return cloned

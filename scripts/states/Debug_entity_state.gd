extends State
class_name Debug_entity_state

var is_editing = false
var is_selected = false
var is_multiselected = false
var global_position = Vector2.ZERO

func reset():
	is_editing = false
	is_selected = false
	is_multiselected = false

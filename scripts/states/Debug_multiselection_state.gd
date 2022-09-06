extends State
class_name Debug_multiselection_state

var enabled = false
var entities = []
var area = false

func reset():
	enabled = false
	area = false
	for entity in entities:
		entity.state.is_multiselected = false
	entities = []
	

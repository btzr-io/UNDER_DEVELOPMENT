extends State
class_name Debug_manager_state
 
var edit_mode = false
var selected_entity = null
var current_action = CONSTANTS.ACTIONS.MOVE

# Multiselection state
var multiselection = Debug_multiselection_state.new()

func reset():
	edit_mode = false
	current_action = CONSTANTS.ACTIONS.MOVE
	if is_instance_valid(selected_entity):
		selected_entity.state.reset()
	multiselection.reset()

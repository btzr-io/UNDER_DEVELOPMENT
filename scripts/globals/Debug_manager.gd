extends Node
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Limit to 10 actions
const HISTORTY_MAX_SIZE = 3
onready var history = Utils.History_manager.new(HISTORTY_MAX_SIZE) 

# Main state
var state = Debug_manager_state.new()
var prev_state = null
var redo_state = null

var multiselection_delay = 0
var multiselection_max_delay = 0.15

# References
var level = null
var camera = null
var debug_ui = null
var debug_area = null
var debug_trail = null
var debug_connections = null


func _ready():
	level = get_tree().current_scene
	camera = level.get_node_or_null("Main_camera")
	debug_ui = level.get_node_or_null("Debug_ui")
	debug_area = debug_ui.get_node_or_null("Debug_area")
	debug_trail = debug_ui.get_node_or_null("Debug_trail")
	debug_connections = debug_ui.get_node_or_null("Debug_connections")
	history.connect("history_change", self, "handle_history_change")
	prev_state = get_full_state()

func set_history_checkpoint():
	redo_state = prev_state
	prev_state = get_full_state()

func get_full_state():
	var current_state = {
		"manager": state.clone(),
		"debug_area": debug_area.state.clone(),  
		"debug_trail": debug_trail.state.clone(),
	}
	if is_instance_valid(current_state["manager"].selected_entity):
		current_state["selected_entity"] = current_state["manager"].selected_entity.state.clone()
	
	return current_state

func get_history_state():
	return { "UNDO": prev_state, "EXECUTE": get_full_state() }

func handle_history_change(new_state):
	state = new_state["manager"]
	state.selected_entity.load_state(new_state["selected_entity"])
	debug_area.load_state(new_state["debug_area"])
	debug_trail.clear_points()
	debug_trail.state = new_state["debug_trail"]
	
func select_entity(entity):
	if is_instance_valid(state.selected_entity):
		state.selected_entity.state.reset()
	if is_instance_valid(entity):
		state.selected_entity = entity
		state.selected_entity.state.is_selected = true
		
		if camera:
			camera.target = state.selected_entity

func unselect_entity(entity):
	var entity_index = state.multiselection.entities.find(entity)
	if entity_index > -1:
		state.multiselection.entities[entity_index].state.is_multiselected = false
		state.multiselection.entities.remove(entity_index)
		state.multiselection.area = Utils.get_area_bounds(state.multiselection.entities)

func multiselect_entity(entity):
	entity.state.is_multiselected = true
	state.multiselection.entities.append(entity)
	state.multiselection.area = Utils.get_area_bounds(state.multiselection.entities)

	
func shake_camera(trauma = 0.4):
	if camera:
		camera.add_trauma(trauma)
	 
func handle_action():
		var exit_after_action = true
		if debug_area.state.snap_target:
			if state.current_action == CONSTANTS.ACTIONS.EDIT:
				select_entity(debug_area.snap_target)
				enter_edit_mode()
			if state.current_action == CONSTANTS.ACTIONS.CONNECT:
				state.selected_entity.add_connection(debug_area.state.snap_target)
			elif state.current_action == CONSTANTS.ACTIONS.DISCONNECT:
				state.selected_entity.remove_connection(debug_area.state.snap_target)
				debug_connections.render_input_connections()
		if state.current_action == CONSTANTS.ACTIONS.MOVE:
			var new_position = debug_area.get_world_position()
			var current_position = state.selected_entity.global_transform.origin
			history.push(get_history_state())
			state.selected_entity.global_transform.origin = new_position
			shake_camera(0.45)


func exit_edit_mode(run_action = true):
	if run_action and debug_area.overlapping_bodies > 0:
		return
	if run_action and state.current_action == CONSTANTS.ACTIONS.MULTISELECT:
		state.multiselection.enabled = false
		return
	
	debug_area.close()
	debug_trail.disconnect_target()
	state.reset()
	select_entity(state.selected_entity)
	
	
	if run_action:
		handle_action()


func enter_edit_mode():
	state.edit_mode = true
	debug_area.open()
	debug_trail.connect_target(debug_area.world_origin, state.selected_entity)
	debug_connections.render_input_connections()
	if camera:
		camera.target = debug_area.world_origin

func _physics_process(delta):
	if not is_instance_valid(state.selected_entity):
		return
	
	if Input.is_action_just_pressed("undo"):
		history.undo()
		return
	if Input.is_action_just_pressed("redo"):
		history.redo()
		return
	# Exit edit mode
	if Input.is_action_just_pressed("ui_cancel"):
		if state.edit_mode and state.selected_entity.state.is_editing:
			exit_edit_mode(false)
			return	

	# Main action: Toggle edit mode and run action
	if Input.is_action_just_released("ui_accept"):
		multiselection_delay = 0
		if debug_area.state.snap_target and state.edit_mode and state.selected_entity.state.is_editing:
			exit_edit_mode()
	
	elif Input.is_action_just_pressed("ui_accept"):
		if not state.edit_mode and not state.selected_entity.state.is_editing:
			state.multiselection.enabled = false
			enter_edit_mode()
		elif not debug_area.state.snap_target and state.edit_mode and state.selected_entity.state.is_editing:
			exit_edit_mode()
	
	# Holding action: Multiselect
	if Input.is_action_pressed("ui_accept"):
		if not state.multiselection.enabled and debug_area.state.snap_target:
			multiselection_delay += delta
			if multiselection_delay > 0.5:
				multiselection_delay = 0
				state.multiselection.enabled = true
				if not debug_area.state.snap_target.state.is_multiselected:
					multiselect_entity(debug_area.state.snap_target)
				else:
					unselect_entity(debug_area.state.snap_target)
					

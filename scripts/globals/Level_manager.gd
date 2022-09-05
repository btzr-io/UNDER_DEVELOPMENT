extends Node
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Limit to 10 actions
const HISTORTY_MAX_SIZE = 3
onready var history = Utils.History_manager.new(HISTORTY_MAX_SIZE) 

var edit_mode = false
var selected_entity = null
var multiselection = false
var multiselected_entities = []
var multiselected_area = null

var level = null
var camera = null
var current_line_connection = null
var debug_ui = null
var debug_area = null
var debug_connections = null
var debug_state = { }

var multiselection_max_delay = 0.15
var multiselection_delay =  0


func save_debug_state():
	debug_state = {
		"debug_area_connection": current_line_connection.get_state()
	}

func _ready():
	level = get_tree().current_scene
	camera = level.get_node_or_null("Main_camera")
	debug_ui = level.get_node_or_null("Debug_ui")
	debug_area = debug_ui.get_node_or_null("Debug_area")
	debug_connections = debug_ui.get_node_or_null("Debug_connections")
	current_line_connection = debug_ui.get_node_or_null("Debug_area_connection")
	history.connect("history_change", self, "handle_history_change")

func handle_history_change(new_state):
	selected_entity.global_transform.origin = new_state.position
	
func select_entity(entity):
	if is_instance_valid(selected_entity):
		selected_entity.state.reset()
	if is_instance_valid(entity):
		selected_entity = entity
		selected_entity.state.is_selected = true
		
		if camera:
			camera.target = selected_entity

func unselect_entity(entity):
	var entity_index = multiselected_entities.find(entity)
	if entity_index > -1:
		multiselected_entities[entity_index].state.is_multiselected = false
		multiselected_entities.remove(entity_index)
		multiselected_area = Utils.get_area_bounds(multiselected_entities)

func multiselect_entity(entity):
	entity.state.is_multiselected = true
	multiselected_entities.append(entity)
	multiselected_area = Utils.get_area_bounds(multiselected_entities)

func clear_multiselection():
	multiselection = false
	multiselected_area = null
	for entity in multiselected_entities:
		entity.state.is_multiselected = false
	multiselected_entities.clear()

func shake_camera(trauma = 0.4):
	if camera:
		camera.add_trauma(trauma)


func create_action(new_state, old_state):
	var action = {
		"UNDO_DATA": old_state,
		"EXECUTE_DATA": new_state
	}
	return action
	 
func handle_action():
		var exit_after_action = true
		if debug_area.snap_target:
			if debug_area.current_action == CONSTANTS.ACTIONS.EDIT:
				select_entity(debug_area.snap_target)
				enter_edit_mode()
			if debug_area.current_action == CONSTANTS.ACTIONS.CONNECT:
				selected_entity.add_connection(debug_area.snap_target)
			elif debug_area.current_action == CONSTANTS.ACTIONS.DISCONNECT:
				selected_entity.remove_connection(debug_area.snap_target)
				debug_connections.render_input_connections()
		if debug_area.current_action == CONSTANTS.ACTIONS.MOVE:
			var new_position = debug_area.get_world_position()
			var current_position = selected_entity.global_transform.origin
			history.push(create_action({ "position": new_position,}, { "position": current_position }))
			selected_entity.global_transform.origin = new_position
			shake_camera(0.45)


func exit_edit_mode(run_action = true):
	if run_action and debug_area.overlapping_bodies > 0:
		return
	if run_action and debug_area.current_action == CONSTANTS.ACTIONS.MULTISELECT:
		LM.multiselection = false
		return
	
	edit_mode = false
	debug_area.close()
	selected_entity.state.reset()
	current_line_connection.disconnect_target()
	select_entity(selected_entity)
	clear_multiselection()
	
	if run_action:
		handle_action()


func enter_edit_mode():
	edit_mode = true
	debug_area.open()
	debug_connections.render_input_connections()
	current_line_connection.connect_target(debug_area.world_origin, selected_entity)

	if camera:
		camera.target = debug_area.world_origin

func _physics_process(delta):
	if not is_instance_valid(selected_entity):
		return
	
	if Input.is_action_just_pressed("undo"):
		history.undo()
		return
	if Input.is_action_just_pressed("redo"):
		history.redo()
		return
	# Exit edit mode
	if Input.is_action_just_pressed("ui_cancel"):
		if edit_mode and selected_entity.state.is_editing:
			exit_edit_mode(false)
			return	

	# Main action: Toggle edit mode and run action
	if Input.is_action_just_released("ui_accept"):
		multiselection_delay = 0
		if debug_area.snap_target and edit_mode and selected_entity.state.is_editing:
			exit_edit_mode()
	
	elif Input.is_action_just_pressed("ui_accept"):
		if not edit_mode and not selected_entity.state.is_editing:
			multiselection = false
			enter_edit_mode()
		elif not debug_area.snap_target and edit_mode and selected_entity.state.is_editing:
			exit_edit_mode()
	
	# Holding action: Multiselect
	if Input.is_action_pressed("ui_accept"):
		if not multiselection and debug_area.snap_target:
			multiselection_delay += delta
			if multiselection_delay > 0.5:
				multiselection_delay = 0
				multiselection = true
				if not debug_area.snap_target.state.is_multiselected:
					multiselect_entity(debug_area.snap_target)
				else:
					unselect_entity(debug_area.snap_target)
					

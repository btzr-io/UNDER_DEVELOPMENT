extends Node2D
var overlapping_bodies = 0

onready var error_simulator = Utils.Error_simulator.new()


# Snap movement
var max_snap_speed = 18
var max_snap_target_speed = 15
var current_snap_speed = 0

# Motion / physics
var speed = 225
var max_speed = speed * 2.5
var current_speed = 0 
var velocity = Vector2.ZERO
var direction = Vector2.ZERO

var distance_threshold = 0.0015

# Main state
var state = Debug_area_state.new()

onready var multiselect_origin = Position2D.new()
onready var world_origin = $World_origin
onready var overlap = $World_origin/Ovelrap



func _ready():
	overlap.connect("body_exited", self, "handle_body_exit")
	overlap.connect("body_entered", self, "handle_body_enter")
	remove_child(world_origin)
	DM.level.call_deferred("add_child", world_origin)
	DM.level.call_deferred("add_child", multiselect_origin)
	
	# Target for tooltip
	$Area_UI/Tooltip.target = $Area_UI/Shape

func load_state(new_state):
	state = new_state
	visible = state.visible
	world_origin.global_position = state.global_position
	$Area_UI.global_position = get_screen_position()
	$Area_UI/Tooltip.tooltip_direction = state.last_direction.y
	$Area_UI/Tooltip.show()

func snap_to_target(new_target):
	state.snap_target = new_target

func get_world_position():
	state.global_position = world_origin.global_position
	return world_origin.global_position

func get_screen_position():
	state.global_position = world_origin.global_position
	return world_origin.get_global_transform_with_canvas().origin

func open():
	# RESET TOOLTIP
	update_ui_color(Color.cyan)
	update_ui_message(CONSTANTS.ACTIONS.MOVE)
	world_origin.global_transform.origin = DM.state.selected_entity.global_transform.origin
	var size = DM.state.selected_entity.get_current_size()
	var push_and_snap = world_origin.global_transform.origin  + state.last_direction * size.x  *  1.4
	resize_area(size)
	snap_to_position(push_and_snap)
	$Area_UI/Tooltip.tooltip_direction = state.last_direction.y
	$Area_UI/Tooltip.show()
	state.visible = true
	visible = state.visible

func close():
	state.visible = false
	visible = state.visible
	

func snap_to_position(new_position):
	state.snap_position = new_position
	
func smooth_snap_to_position(new_postion, delta):
	var current_max_speed = max_snap_speed
	if state.snap_target:
		current_max_speed = max_snap_target_speed
	current_snap_speed =  lerp(current_snap_speed, current_max_speed, 0.4)
	world_origin.global_transform.origin = lerp(world_origin.global_transform.origin, new_postion, delta  * current_snap_speed)

func cancel_snap_to_target():
	state.snap_target = null

func handle_body_enter(overlaping_body):
	if overlaping_body == self:
		return
	if overlaping_body.is_in_group("EDITABLE"):
		snap_to_target(overlaping_body)
		DM.set_history_checkpoint()
		if DM.state.multiselection.enabled:
			DM.state.current_action = CONSTANTS.ACTIONS.MULTISELECT
			if not overlaping_body.state.is_multiselected:
				DM.multiselect_entity(state.snap_target)
			else:
				DM.unselect_entity(state.snap_target)
			return
		if overlaping_body == DM.state.selected_entity:
			DM.state.current_action = CONSTANTS.ACTIONS.PLAY
		elif overlaping_body.is_in_group("CONNECTOR"):
			if DM.state.selected_entity.has_connection(overlaping_body):
				DM.state.current_action = CONSTANTS.ACTIONS.DISCONNECT
			else:
				DM.state.current_action = CONSTANTS.ACTIONS.CONNECT
		else:
			DM.state.current_action = CONSTANTS.ACTIONS.EDIT
	else:
		overlapping_bodies += 1

func handle_body_exit(overlaping_body):
	if overlaping_body == self:
		return
	elif overlaping_body.is_in_group("EDITABLE"):
		if overlaping_body == state.snap_target or state.snap_target == DM.state.selected_entity:
			cancel_snap_to_target()
			DM.state.current_action = CONSTANTS.ACTIONS.MOVE
	else:
		overlapping_bodies -= 1

func resize_area(new_size):
	var zoom =   Vector2.ONE / DM.camera.zoom
	$Area_UI/Shape.rect_size = new_size * zoom
	$Area_UI/Shape.rect_position = $Area_UI/Shape.rect_size  / 2 * -1  
	
	
func update_ui_color(new_ui_color):
	state.ui_color = new_ui_color
	modulate = new_ui_color
	DM.debug_trail.modulate = new_ui_color

func update_ui_message(text):
	state.ui_message = text
	$Area_UI/Tooltip.text = text
	
func update_ui_area():
	var size = DM.state.selected_entity.get_current_size()
	resize_area(size)

func update_ui_multiselection():
	if DM.state.multiselection.area:
		if not $Multiselect_UI.visible:
			$Multiselect_UI.show()
		$Multiselect_UI.resize(DM.state.multiselection.area.size)
		if not DM.state.multiselection.enabled and DM.state.current_action == CONSTANTS.ACTIONS.MOVE:
			$Multiselect_UI.set_style($Multiselect_UI.STYLES.DEFAULT)
			$Multiselect_UI.set_world_position(DM.state.multiselection.area.position)
			var offset = $Multiselect_UI.world_origin.to_local(DM.state.multiselection.entities.back().global_position)
			$Multiselect_UI.set_world_position(world_origin.global_position - offset)
		else:
			$Multiselect_UI.set_style($Multiselect_UI.STYLES.OUTLINE)
			$Multiselect_UI.set_world_position(DM.state.multiselection.area.position)
	elif $Multiselect_UI.visible:
		$Multiselect_UI.hide()

func push_out():
	var size = Vector2.ZERO
	if state.last_direction.abs() == Vector2.ONE:
		state.snap_position = global_transform.origin + state.last_direction * size.x * 1.2
	else:
		state.nap_position = global_transform.origin + state.last_direction * size.x * 1.4
		
func update_ui():
	var new_ui_color = state.ui_color
	var new_ui_message = $Area_UI/Tooltip.text
	update_ui_area()
	update_ui_multiselection()
	
	if DM.state.edit_mode and DM.state.selected_entity.state.is_editing:
		if overlapping_bodies > 0:
			new_ui_color = Color.red
			new_ui_message = "LOCKED"
		else:
			if DM.state.multiselection.enabled:
				DM.state.current_action = CONSTANTS.ACTIONS.MULTISELECT
			error_simulator.update_error_risk(DM.debug_trail.state.target_distance)
			if error_simulator.error_risk > 0:
				if error_simulator.error_type == CONSTANTS.BUGS.GLITCH:
					new_ui_color = Color.orange
					new_ui_message = DM.state.current_action + " + GLITCH " + str(error_simulator.error_risk) + "%"
				elif error_simulator.error_type == CONSTANTS.BUGS.ERROR:
					new_ui_color = Color.red
					new_ui_message = DM.state.current_action + " + ERROR " + str(error_simulator.error_risk) + "%"
			else:
				new_ui_color = Color.cyan
				new_ui_message = DM.state.current_action 
				if state.snap_target:
					new_ui_color = Color.green
					if DM.state.current_action == CONSTANTS.ACTIONS.DISCONNECT:
						new_ui_color = Color.red
						
	if state.ui_color != new_ui_color:
		update_ui_color(new_ui_color)
	if state.ui_message != new_ui_message:
		update_ui_message(new_ui_message)

func get_input():
	# Movement axis
	direction = Vector2.ZERO
	if Input.is_action_pressed("ui_accept") and not DM.state.multiselection.enabled and state.snap_target:
		return
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y =  Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

func _process(_delta):
	update_ui()
	if world_origin.is_inside_tree():
		$Area_UI.global_position = get_screen_position()

func _physics_process(delta):
	get_input()
		
	if direction != Vector2.ZERO:
		state.last_direction = direction
	
	if not DM.state.edit_mode:
		return
	
	if state.snap_position:
		var distance_left = world_origin.global_position.distance_squared_to(state.snap_position)
		print(distance_left)
		if distance_left <= distance_threshold:
			# Reset motion
			velocity = Vector2.ZERO
			# Reset snap motion
			state.snap_position = null
			DM.state.selected_entity.state.is_editing = true
			DM.set_history_checkpoint()
			current_snap_speed = 0
			return
		smooth_snap_to_position(state.snap_position, delta)
		return
				
	if direction == Vector2.ZERO:
		current_speed = lerp(current_speed, 0.0, 0.28)
		velocity = velocity.normalized() * current_speed
		velocity = velocity.normalized() * current_speed
		if state.snap_target:
			var next_snap_position  = state.snap_target.global_transform.origin
			smooth_snap_to_position(next_snap_position, delta)
	else:
		current_speed =  lerp(current_speed, max_speed, 0.3)
		velocity = direction.normalized() * current_speed
		if current_snap_speed > 0:
			current_snap_speed = 0
				
	world_origin.move_and_slide(velocity)
	

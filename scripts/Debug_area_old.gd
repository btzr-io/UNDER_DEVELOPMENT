extends KinematicBody2D
var overlapping_bodies = 0
var current_action = "MOVE"
onready var error_simulator = Utils.Error_simulator.new()
# Snap movement
var snap_target = null
var snap_position = null
var max_snap_speed = 18
var max_snap_target_speed = 15
var current_snap_speed = 0

# Motion / physics
var speed = 225
var max_speed = speed * 2.5
var current_speed = 0 
var velocity = Vector2.ZERO
var direction = Vector2.ZERO
var last_direction = Vector2.UP

# UI
var ui_color = Color.cyan
var ui_message = CONSTANTS.ACTIONS.MOVE

onready var overlap = $Ovelrap

func _ready():
	$Ovelrap.connect("body_exited", self, "handle_body_exit")
	$Ovelrap.connect("body_entered", self, "handle_body_enter")
	remove_child(overlap)
	LM.level.call_deferred("add_child", overlap)

func snap_to_target(new_target):
	snap_target = new_target

func get_world_position():
	return overlap.global_transform.postion

func get_screen_position():
	return overlap.get_global_transform_with_canvas().origin

func open():
	# RESET TOOLTIP
	update_ui_color(Color.cyan)
	update_tooltip_text(CONSTANTS.ACTIONS.MOVE)
	global_transform.origin = LM.selected_entity.get_global_transform_with_canvas().origin
	var size = LM.selected_entity.get_current_size() 

	var push_and_snap = global_transform.origin  + last_direction * size * ( 1.0 + LM.camera.zoom.x ) *  1.4
	snap_to_position(push_and_snap)
	show_tooltip()
	visible = true

func close():
	# RESET TOOLTIP
	hide_tooltip()
	visible = false
	

func snap_to_position(new_position):
	snap_position = new_position
	
func smooth_snap_to_position(new_postion, delta):
	var current_max_speed = max_snap_speed
	if snap_target:
		current_max_speed = max_snap_target_speed
	current_snap_speed =  lerp(current_snap_speed, current_max_speed, 0.4)
	global_transform.origin = lerp(global_transform.origin, new_postion, delta  * current_snap_speed)

func cancel_snap_to_target():
	snap_target = null

func handle_body_enter(overlaping_body):
	if overlaping_body == self:
		return
	if overlaping_body.is_in_group("EDITABLE"):
		snap_to_target(overlaping_body)
		if overlaping_body == LM.selected_entity:
			current_action = CONSTANTS.ACTIONS.PLAY
		elif overlaping_body.is_in_group("CONNECTOR"):
			if LM.selected_entity.has_connection(overlaping_body):
				current_action = CONSTANTS.ACTIONS.DISCONNECT
			else:
				current_action = CONSTANTS.ACTIONS.CONNECT
		else:
			current_action = CONSTANTS.ACTIONS.EDIT
	else:
		overlapping_bodies += 1

func handle_body_exit(overlaping_body):
	if overlaping_body == self:
		return
	elif overlaping_body.is_in_group("EDITABLE"):
		if overlaping_body == snap_target:
			cancel_snap_to_target()
			current_action = CONSTANTS.ACTIONS.MOVE
	else:
		overlapping_bodies -= 1

func resize_area(new_size):
	$Texture_UI.rect_size = new_size
	$Texture_UI.rect_position = new_size  / 2 * -1

func show_tooltip():
	var tooltip_direction = last_direction.y
	
	if tooltip_direction  <= 0:
		$Tooltip.rect_position.y = -72
	
	if tooltip_direction > 0:
		$Tooltip.rect_position.y = 40

	$Tooltip/AnimationPlayer.play("show")

func hide_tooltip():
	$Tooltip/AnimationPlayer.play_backwards("show")

func update_ui_color(new_ui_color):
	ui_color = new_ui_color
	modulate = new_ui_color
	LM.current_line_connection.modulate = new_ui_color

	
func update_tooltip_text(new_text):
	ui_message = new_text
	$Tooltip.text = new_text
	$Tooltip.rect_size = $Tooltip.get_font("font").get_string_size($Tooltip.text)

func push_out():
	var size = Vector2.ZERO
	if last_direction.abs() == Vector2.ONE:
		snap_position = global_transform.origin + last_direction * size.x * 1.2
	else:
		snap_position = global_transform.origin + last_direction * size.x * 1.4
		
func update_ui():
	var new_ui_color = ui_color
	var new_ui_message = $Tooltip.text
	
	# Auto resize tooltip
	$Tooltip.rect_size = $Tooltip.get_font("font").get_string_size($Tooltip.text)
	
	if LM.edit_mode and LM.selected_entity.state.is_editing:
		if overlapping_bodies > 0:
			new_ui_color = Color.red
			new_ui_message = "LOCKED"
		else:
			error_simulator.update_error_risk(LM.current_line_connection.target_distance)
			if error_simulator.error_risk > 0:
				if error_simulator.error_type == CONSTANTS.BUGS.GLITCH:
					new_ui_color = Color.orange
					new_ui_message = current_action + " + GLITCH " + str(error_simulator.error_risk) + "%"
				elif error_simulator.error_type == CONSTANTS.BUGS.ERROR:
					new_ui_color = Color.red
					new_ui_message = current_action + " + ERROR " + str(error_simulator.error_risk) + "%"
			else:
				new_ui_color = Color.cyan
				new_ui_message = current_action 
				if snap_target:
					new_ui_color = Color.green
					if current_action == CONSTANTS.ACTIONS.DISCONNECT:
						new_ui_color = Color.red
		
	if ui_color != new_ui_color:
		update_ui_color(new_ui_color)
	if ui_message != new_ui_message:
		update_tooltip_text(new_ui_message)

func get_input():
	# Movement axis
	direction = Vector2.ZERO
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y =  Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

func _process(_delta):
		update_ui()
		
func _physics_process(delta):
	get_input()

	if direction != Vector2.ZERO:
		last_direction = direction
	
	if not LM.edit_mode:
		return
	
	if snap_position:
		var threshold = 1.0
		var distance_left = global_transform.origin.distance_to(snap_position)
		if distance_left <= threshold:
			# Reset motion
			velocity = Vector2.ZERO
			# Reset snap motion
			snap_position = null
			LM.selected_entity.state.is_editing = true
			current_snap_speed = 0
			return
		smooth_snap_to_position(snap_position, delta)
		return
				
	if direction == Vector2.ZERO:
		current_speed = lerp(current_speed, 0.0, 0.28)
		velocity = velocity.normalized() * current_speed
		velocity = velocity.normalized() * current_speed
		if snap_target:
			var next_snap_position  = snap_target.get_global_transform_with_canvas().origin
			smooth_snap_to_position(next_snap_position, delta)
	else:
		current_speed =  lerp(current_speed, max_speed, 0.3)
		velocity = direction.normalized() * current_speed
		if current_snap_speed > 0:
			current_snap_speed = 0
				
	move_and_slide(velocity)
	

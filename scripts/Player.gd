extends KinematicBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var speed = 200
var max_speed = speed * 2.25
var velocity = Vector2.ZERO
var direction = Vector2.ZERO
var last_direction = Vector2.UP
var current_speed = 0
var target_position = null
var snap_position = null
var last_clone_instance = null
var last_clone_position = null
var last_tooltip_text = ""

# Types of bugs
var BUGS = {
	# Critical bug
	ERROR = "ERROR",
	# Minimal temporal bug
	GLITCH = "GLITCH"
}

var ACTIONS = {
	MOVE = "MOVE",
	EDIT = "EDIT",
	CONNECT = "CONNECT",
	DISCONNECT = "DISCONNECT",
	# No actions allowed
	LOCKED = "LOCKED",
	ERROR = "ERROR"
}
var overlapping_bodies = 0

var bug_chance = 0
var max_glitch_range = 50
var min_glitch_chance = 5
var max_glitch_chance = 50

var current_action = ACTIONS.MOVE

const INTERACTIVE_STATES = {
	ACTIVE =  0,
	INACTIVE = 1,
}


# State
export var is_selected = true
export var gravity = 0
var selected_target = null
var connection_target = null

var is_editing = false
var interactive_state = INTERACTIVE_STATES.ACTIVE

var is_glitched = false

var prevent_input = false

onready var line_connection = get_node("Line_connection")


func is_overlaping():
	return overlapping_bodies > 0

func snap_to_position(new_position):
	snap_position = new_position

func show_glitch_effect():
	if not $Glitch_effect.visible:
		$Glitch_effect.visible = true
		var random_flip = randi() % 4
		if random_flip == 0:
			$Glitch_effect.flip_h = false
			$Glitch_effect.flip_v = false
		if random_flip == 1 or random_flip == 3:
			$Glitch_effect.flip_h = true
		if random_flip == 2 or random_flip == 3:
			$Glitch_effect.flip_v = true
			
		is_glitched = true

func hide_glitch_effect():
	if $Glitch_effect.visible:
		$Glitch_effect.visible = false
		is_glitched = false

func show_tooltip():
	if not $Tooltip.visible:
		var tooltip_direction = last_direction.y
		if tooltip_direction  <= 0:
			$Tooltip.rect_position.y = -72
		if tooltip_direction > 0:
			$Tooltip.rect_position.y = 40
		$Tooltip/AnimationPlayer.play("show")

func _ready():
	$Ovelrap.connect("body_exited", self, "handle_body_exit")
	$Ovelrap.connect("body_entered", self, "handle_body_enter")
	$Tooltip/AnimationPlayer.connect("animation_finished", self, "handle_animation_finish")
	
	if not is_selected:
		interactive_state = INTERACTIVE_STATES.ACTIVE
		$Sprite.frame = interactive_state
		z_index = 1

func handle_animation_finish(animation_name):
	if animation_name == "show":
		is_editing = true

func close_edit_mode():
	if is_instance_valid(last_clone_instance):
		line_connection.disconnect_target()
		is_selected = false
		last_clone_instance.is_selected = true
		last_clone_instance.last_direction = last_direction
		last_clone_instance.prevent_input = true
		LM.camera.target = last_clone_instance
		LM.edit_mode = false
		queue_free()

func exit_edit_mode():
	if is_overlaping():
		return

	LM.edit_mode = false
	
	if current_action == ACTIONS.CONNECT and connection_target:
		last_clone_instance.gravity = 98  * 10
		close_edit_mode()
		return
		
	if current_action == ACTIONS.EDIT and selected_target:
		line_connection.disconnect_target()
		selected_target.is_selected = true
		selected_target.last_direction = last_direction
		if test_glitch_chance():
			selected_target.show_glitch_effect()

		selected_target.enter_edit_mode()
		is_selected = false
		LM.camera.target = selected_target
		queue_free()
		return
	
	if current_action == ACTIONS.MOVE and is_instance_valid(last_clone_instance):
		interactive_state = INTERACTIVE_STATES.ACTIVE
		$Sprite.frame = interactive_state
		instance_clone()
		line_connection.disconnect_target()
		if LM.camera:
			LM.camera.add_trauma(0.4)
		$Tooltip.hide()
		$CollisionShape2D.disabled = false
		is_editing = false
		if test_glitch_chance():
			show_glitch_effect()

func enter_edit_mode():
	if not target_position and !is_instance_valid(last_clone_instance):
		instance_clone()
		LM.edit_mode = true
		interactive_state = INTERACTIVE_STATES.INACTIVE
		$Sprite.frame = interactive_state
		line_connection.connect_target(self, last_clone_instance)
		var size = $Sprite.frames.get_frame("idle", 0).get_size()
		current_speed = max_speed
		target_position = global_transform.origin + last_direction * size.x
		$CollisionShape2D.disabled = true
		show_tooltip()
		hide_glitch_effect()
		
		if LM.camera:
			LM.camera.target = self

			
func get_glitch_chance():
	var distance = clamp(line_connection.target_distance, 1, max_glitch_range)
	var chance =   max_glitch_range * distance / 140
	if chance > min_glitch_chance:
		chance = pow(int(chance / 1.6), 2)
	if chance < min_glitch_chance:
		chance = 0
	return clamp(chance, 0, 100)

func test_glitch_chance():
	if bug_chance < min_glitch_chance or bug_chance > max_glitch_chance:
		return false
	var safety_margin = 10
	var chance = randi() % ( max_glitch_chance + safety_margin )
	return chance > 0 and chance <= bug_chance

func handle_body_enter(overlaping_body):
	if overlaping_body == self:
		return
	if overlaping_body.is_in_group("CONNECTOR") and last_clone_instance != overlaping_body:
		connection_target = overlaping_body
		current_action = ACTIONS.CONNECT
		snap_to_position(connection_target.global_transform.origin)
	elif overlaping_body.is_in_group("EDITABLE") and last_clone_instance != overlaping_body:
		selected_target = overlaping_body
		current_action = ACTIONS.EDIT
		snap_to_position(selected_target.global_transform.origin)
	else:
		overlapping_bodies += 1

func handle_body_exit(overlaping_body):
	if overlaping_body == self:
		return
	if overlaping_body.is_in_group("CONNECTOR")  and last_clone_instance != overlaping_body:
		if overlaping_body == connection_target:
			connection_target = null
			current_action = ACTIONS.MOVE
			snap_position = null
	elif overlaping_body.is_in_group("EDITABLE")  and last_clone_instance != overlaping_body:
		if overlaping_body == selected_target:
			selected_target = null
			current_action = ACTIONS.MOVE
			snap_position = null
	else:
		overlapping_bodies -= 1

func instance_clone():
	if is_instance_valid(last_clone_instance):
		last_clone_instance.queue_free()
	else:
		last_clone_instance = duplicate(DUPLICATE_USE_INSTANCING)
		last_clone_instance.is_selected = false
		last_clone_instance.prevent_input = true
		last_clone_instance.interactive_state = INTERACTIVE_STATES.ACTIVE
		LM.level.get_node("Instances").add_child(last_clone_instance)
		last_clone_instance.global_transform.origin = global_transform.origin
		last_clone_position = global_transform.origin
		last_clone_instance.get_node("CollisionShape2D").disabled = false
		z_index = 2
		 
func get_input():
	if prevent_input:
		prevent_input = false
		return

	# Movement axis
	direction = Vector2.ZERO
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")

	
func set_ui_color(color):
	if modulate != color:
		modulate = color
		line_connection.modulate = color

func update_tooltip_text(new_text):
	if last_tooltip_text != new_text:
		last_tooltip_text = new_text
		$Tooltip.text = last_tooltip_text 
		$Tooltip.rect_size = $Tooltip.get_font("font").get_string_size($Tooltip.text)
	else:
		$Tooltip.rect_size = $Tooltip.get_font("font").get_string_size($Tooltip.text)
		

func update_ui():
	if not is_editing and interactive_state == INTERACTIVE_STATES.ACTIVE:
		set_ui_color(Color.white)
			
	if is_editing and interactive_state == INTERACTIVE_STATES.INACTIVE:
		if overlapping_bodies > 0:
			set_ui_color(Color.red)
			update_tooltip_text(ACTIONS.LOCKED)
		else:
			bug_chance= get_glitch_chance()
			if bug_chance >= min_glitch_chance and bug_chance < max_glitch_chance:
				update_tooltip_text(current_action + " + GLITCH " + str(bug_chance) + "%")
				set_ui_color(Color.orange)
			elif bug_chance > max_glitch_chance:
				update_tooltip_text(current_action + " + ERROR " + str(bug_chance) + "%")
				set_ui_color(Color.red)
			else:
				set_ui_color(Color.cyan)
				update_tooltip_text(current_action) 
				if selected_target or connection_target:
					set_ui_color(Color.green)
			

func smooth_snap_position(new_postion, weight):
	global_transform.origin = lerp(global_transform.origin, new_postion, weight)

func _physics_process(delta):
	if is_selected:
		get_input()
		if target_position:
			direction = Vector2.ZERO
			current_speed =  lerp(current_speed, max_speed * 2, 0.8)
			var target_direction = global_transform.origin.direction_to(target_position).normalized()
			var target_distance = floor(global_transform.origin.distance_to(target_position))  / 10
			if target_distance < 1.0:
				target_position = null
				return
				
			velocity = target_direction * current_speed
		if direction == Vector2.ZERO:
			current_speed = lerp(current_speed, 0.0, 0.35)
			velocity = velocity.normalized() * current_speed
			velocity = velocity.normalized() * current_speed
		
			if is_editing and snap_position:
				smooth_snap_position(snap_position, delta * speed * 0.08 )
		else:
			last_direction = direction
			current_speed =  lerp(current_speed, max_speed, 0.3)
			velocity = direction.normalized() * current_speed
		
		if gravity and interactive_state == INTERACTIVE_STATES.ACTIVE:
			velocity.y += gravity
		move_and_slide(velocity)
		update_ui()

	else:
		# RESET VELOCITY
		velocity = Vector2.ZERO
		if gravity and interactive_state == INTERACTIVE_STATES.ACTIVE:
			velocity.y =  gravity
			move_and_slide(velocity)
			
	

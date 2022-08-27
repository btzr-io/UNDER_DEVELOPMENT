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

var ACTIONS = {
	MOVE = "MOVE",
	EDIT = "EDIT",
	# No actions allowed
	LOCKED = "LOCKED",
	ERROR = "ERROR"
}
var overlapping_bodies = 0

var glitch_chance = 0
var max_glitch_range = 50
var min_glitch_chance = 5

var current_action = ACTIONS.MOVE

const INTERACTIVE_STATES = {
	ACTIVE =  0,
	INACTIVE = 1,
}

export var is_selected = true
var selected_target = null

var is_editing = false
var interactive_state = INTERACTIVE_STATES.ACTIVE


onready var line_connection = get_node("Line_connection")
onready var level = get_tree().current_scene
onready var camera = get_tree().root.get_node("Level/Main_camera")


func is_overlaping():
	return overlapping_bodies > 0

func snap_to_position(new_position):
	snap_position = new_position

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
			
func exit_edit_mode():
	if is_overlaping():
		return
		
	if selected_target:
		line_connection.disconnect_target()
		selected_target.is_selected = true
		selected_target.enter_edit_mode()
		is_selected = false
		queue_free()
		return
	
	if is_instance_valid(last_clone_instance):
		interactive_state = INTERACTIVE_STATES.ACTIVE
		$Sprite.frame = interactive_state
		instance_clone()
		line_connection.disconnect_target()
		camera.add_trauma(0.4)
		$Tooltip.hide()
		$CollisionShape2D.disabled = false
		is_editing = false

func enter_edit_mode():
	if not target_position and !is_instance_valid(last_clone_instance):
		interactive_state = INTERACTIVE_STATES.INACTIVE
		$Sprite.frame = interactive_state
		line_connection.connect_target(self)
		var size = $Sprite.frames.get_frame("idle", 0).get_size()
		current_speed = max_speed
		target_position = global_transform.origin + last_direction * size.x
		instance_clone()
		$Tooltip/AnimationPlayer.play("show")
		$CollisionShape2D.disabled = true
			
func get_glitch_chance():
	var distance = clamp(line_connection.target_distance, 1, max_glitch_range)
	var chance =   max_glitch_range * distance / 140
	if chance > min_glitch_chance:
		chance = pow(int(chance / 1.6), 2)
	if chance < min_glitch_chance:
		chance = 0
	return clamp(chance, 0, 100)
	
func handle_body_enter(overlaping_body):
	if overlaping_body == self:
		return
	if overlaping_body.is_in_group("EDITABLE") and last_clone_instance != overlaping_body:
		selected_target = overlaping_body
		current_action = ACTIONS.EDIT
		snap_to_position(selected_target.global_transform.origin)
	else:
		overlapping_bodies += 1

func handle_body_exit(overlaping_body):
	if overlaping_body == self:
		return
	if overlaping_body.is_in_group("EDITABLE") and last_clone_instance != overlaping_body:
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
		level.add_child(last_clone_instance)
		last_clone_instance.global_transform.origin = global_transform.origin
		last_clone_position = global_transform.origin
		z_index = 2
		 
func get_input():
	# Detect up/down/left/right keystate and only move when pressed
	direction = Vector2.ZERO
	if Input.is_action_pressed('ui_right'):
		direction.x += 1
	if Input.is_action_pressed('ui_left'):
		direction.x -= 1
	if Input.is_action_pressed('ui_down'):
		direction.y += 1
	if Input.is_action_pressed('ui_up'):
		direction.y -= 1
	
	if Input.is_action_just_pressed("ui_accept"):
		if not is_editing:
			enter_edit_mode()
		elif is_editing:
			exit_edit_mode()
	
	
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
			glitch_chance = get_glitch_chance()
			if glitch_chance >= min_glitch_chance:
				update_tooltip_text(current_action + " + GLITCH " + str(glitch_chance) + "%")
				set_ui_color(Color.orange)
			else:
				set_ui_color(Color.cyan)
				update_tooltip_text(current_action) 
				if selected_target:
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

		velocity = move_and_slide(velocity)
		update_ui()

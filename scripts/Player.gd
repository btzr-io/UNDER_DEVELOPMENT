extends KinematicBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var clone_instance = load("res://scenes/actors/PlayerClone.tscn")

var speed = 200
var max_speed = speed * 2.25
var velocity = Vector2.ZERO
var direction = Vector2.ZERO
var last_direction = Vector2.ZERO
var current_speed = 0
var target_position = null
var last_clone_instance = null
var last_clone_position = null

const INTERACTIVE_STATES = {
	ACTIVE =  0,
	INACTIVE = 1,
}

var interactive_state = INTERACTIVE_STATES.ACTIVE
onready var line_connection = get_node("Line_connection")

onready var level = get_tree().current_scene


func _ready():
	pass

func instance_clone():
	if is_instance_valid(last_clone_instance):
		last_clone_instance.queue_free()
	else:
		last_clone_instance = clone_instance.instance()	
		level.add_child(last_clone_instance)
		last_clone_instance.global_transform.origin = global_transform.origin
		last_clone_position = global_transform.origin

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
		if not target_position and is_instance_valid(last_clone_instance):
			interactive_state = INTERACTIVE_STATES.ACTIVE
			instance_clone()
			line_connection.disconnect_target()
			$Sprite.frame = interactive_state
			return
		
		if not target_position and !is_instance_valid(last_clone_instance):
			interactive_state = INTERACTIVE_STATES.INACTIVE
			line_connection.connect_target(self)
			$Sprite.frame = interactive_state
			var size = $Sprite.frames.get_frame("idle", interactive_state).get_size()
			current_speed = max_speed
			target_position = global_transform.origin + last_direction * size.x
			instance_clone()
	
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
	
			
	else:
		last_direction = direction
		current_speed =  lerp(current_speed, max_speed, 0.3)
		velocity = direction.normalized() * current_speed
	
	

func _physics_process(_delta):
	get_input()
	velocity = move_and_slide(velocity)

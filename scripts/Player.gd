extends KinematicBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


var speed = 250
var max_speed = speed * 2.5
var velocity = Vector2.ZERO
var direction = Vector2.ZERO
var current_speed = 0

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
	
	
	if direction == Vector2.ZERO:
		current_speed = lerp(current_speed, 0.0, 0.2)
		velocity = velocity.normalized() * current_speed
	else:
		current_speed =  lerp(current_speed, max_speed, 0.3)
		velocity = direction.normalized() * current_speed


func _physics_process(delta):
	get_input()
	move_and_collide(velocity * delta)

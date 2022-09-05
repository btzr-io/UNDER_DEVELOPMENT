extends KinematicBody2D
class_name Entity

# Edit on instpector
export var auto_select = false
onready var spatial_area_ui_scene = preload("res://scenes/Spatial_area_UI.tscn")
# Props
var editable = true
var input_connections = []

# Motion / physics
var max_speed = 350.0
var current_speed = 0.0
var velocity = Vector2.ZERO
var direction = Vector2.ZERO
var last_direction = Vector2.UP

# Main state
onready var state = Debug_entity_state.new()
onready var debug_bounds = spatial_area_ui_scene.instance()

# Called when the node enters the scene tree for the first time.
func _ready():
	state.is_selected = auto_select
	if auto_select:
		state.is_selected = auto_select
		LM.select_entity(self)
	
	LM.level.get_node("Debug_ui").call_deferred("add_child", debug_bounds)

func has_connection(test_connection_origin):
	return input_connections.has(test_connection_origin)

func add_connection(connection_origin):
	input_connections.append(connection_origin)

func remove_connection(connection_origin):
	var connection_index = input_connections.find(connection_origin)
	if connection_index  != -1:
		input_connections.remove(connection_index)


func get_current_size():
	var size = $Sprite.frames.get_frame("idle", 0).get_size()
	return size


func _process(_delta):
	if LM.edit_mode and state.is_multiselected:
		debug_bounds.set_world_position(global_position)
		debug_bounds.resize(get_current_size())
		debug_bounds.modulate = LM.debug_area.modulate
		if not debug_bounds.visible:
			debug_bounds.show()
	elif debug_bounds.visible:
		debug_bounds.hide()
	
	

func _physics_process(delta):
	if not LM.edit_mode and state.is_selected:
		# Movement axis
		direction = Vector2.ZERO
		direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		direction.y =  Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	if LM.edit_mode and direction != Vector2.ZERO:
		direction = Vector2.ZERO
		
	if direction == Vector2.ZERO and current_speed > 0:
		current_speed = lerp(current_speed, 0.0, 0.35)
		velocity = velocity.normalized() * current_speed
	else:
		last_direction = direction
		current_speed =  lerp(current_speed, max_speed, 0.3)
		velocity = direction.normalized() * current_speed
	
	velocity = move_and_slide(velocity)

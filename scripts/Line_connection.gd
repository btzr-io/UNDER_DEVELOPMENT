extends Line2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var target = null
var emitting = false
var start_position = false


onready var level = get_tree().current_scene

func connect_target(new_target):
	# Reparent
	get_parent().remove_child(self)
	level.call_deferred("add_child", self)
	emitting = true
	target = new_target
	start_position = target.global_transform.origin
	points = []
func disconnect_target():
	emitting = false
	target = null
	start_position = null


func get_target_distance():
	var distance = target.global_transform.origin.distance_to(start_position) * 0.05 
	distance = int(floor(distance))
	distance = clamp(28 - distance, 12, 28)
	return distance
	
func _physics_process(_delta):
	if emitting:
		var trail_distance = get_target_distance()
		if get_point_count() < trail_distance:
			add_point(target.global_transform.origin)
		elif get_point_count() > trail_distance:
			remove_point(0)
			
		set_point_position(0, start_position)
		set_point_position(get_point_count() - 1, target.global_transform.origin)
	elif get_point_count() > 0:
		remove_point(0)

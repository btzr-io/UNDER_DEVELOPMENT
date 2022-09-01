extends Line2D


# Declare member variables here. Examples:
# var a = 2
# var b =ww "text"

var target = null
var emitting = false
var target_origin = null
var target_distance = 0
var single_line = false
var max_points = 28
var positions = []
var mapped_points = []

func connect_target(new_target, new_target_origin):
	emitting = true
	target = new_target
	points = []
	z_index = 1
	target_origin = new_target_origin
	
func disconnect_target():
	emitting = false
	target = null
	target_origin= null
	target_distance = 0
	clear_points()
	$Target_point.hide()


func _ready():
	if not single_line:
		for point_index in max_points + 1:
			var new_point = Position2D.new()
			new_point.name = get_point_name(point_index)
			mapped_points.append(new_point)
			LM.level.call_deferred("add_child", new_point)
		
func get_point_name(point_index):
	 return name + "_point_" + str(point_index)

func get_target_distance():
	var distance = Utils.get_screen_position(target).distance_to(Utils.get_screen_position(target_origin)) * 0.05 
	distance =  distance * ( 1.0 * LM.camera.zoom.x )
	distance = int(floor(distance)) 
	target_distance  = distance
	# distance = clamp(28 - distance, 12, 28)
	distance = clamp(max_points - distance, 12, max_points)
	return distance

func get_screen_point(point_index):
	return Utils.get_screen_position(mapped_points[point_index])

func sync_screen_point(point_index):
	mapped_points[point_index].global_position = positions[point_index]
	if point_index < get_point_count():
		set_point_position(point_index, get_screen_point(point_index))
	
func update_point(point_index, target):
	if point_index <= max_points:
		if point_index == get_point_count():
			add_point(Vector2.ZERO)
		if point_index > -1 and  point_index < positions.size():
			positions[point_index] = target.global_position
		else:
			positions.append(target.global_position)

func _process(_delta):
	
	if emitting:
		$Target_point.global_transform.origin = Utils.get_screen_position(target)

		if single_line:
			if get_point_count() == 0:
				clear_points()
				add_point(Utils.get_screen_position(target_origin), 0)
				add_point(Utils.get_screen_position(target), 1)
			
		else:
			var trail_distance = get_target_distance()
			if trail_distance:
				if get_point_count() < trail_distance:
					update_point(get_point_count(), target)
				elif get_point_count() > trail_distance:
					remove_point(0)
					positions.remove(0)
					
			if get_point_count() > 0:
				for point_index in positions.size():
					sync_screen_point(point_index)
		if get_point_count() > 0:
			if not $Target_point.visible:
				$Target_point.show()
			set_point_position(get_point_count() - 1,  Utils.get_screen_position(target))
			set_point_position(0, Utils.get_screen_position(target_origin))
		
	
	elif get_point_count() > 0:
		disconnect_target()

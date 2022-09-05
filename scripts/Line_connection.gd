extends Line2D

export var single_line = false
export var max_points = 100

var mapped_points = []

onready var state = Debug_line_connection_state.new()

func connect_target(new_target, new_target_origin):
	state.emitting = true
	state.target = new_target
	state.target_origin = new_target_origin
	z_index = 1
	
func disconnect_target():
	state.reset()
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
	var target_screen_position =  Utils.get_screen_position(state.target)
	var target_origin_screen_position = Utils.get_screen_position(state.target_origin)
	var distance = target_screen_position.distance_to(target_origin_screen_position) * 0.05 
	distance =  int(distance * LM.camera.zoom.x)
	state.target_distance  = distance
	# distance = clamp(28 - distance, 12, 28)
	distance = clamp(max_points - distance, 12, max_points)
	return distance

func get_screen_point(point_index):
	return Utils.get_screen_position(mapped_points[point_index])

func sync_screen_point(point_index):
	mapped_points[point_index].global_position = state.positions[point_index]
	if point_index < get_point_count():
		set_point_position(point_index, get_screen_point(point_index))
	
func update_point(point_index, target):
	if point_index <= max_points:
		if point_index == get_point_count():
			add_point(Vector2.ZERO)
		if point_index > -1 and  point_index < state.positions.size():
			state.positions[point_index] = state.target.global_position
		else:
			state.positions.append(target.global_position)
		state.points = points
func _process(_delta):
	if state.emitting:
		$Target_point.global_position = Utils.get_screen_position(state.target)

		if single_line:
			if get_point_count() == 0 or get_point_count() > 2:
				clear_points()
				state.points = []
				add_point(Utils.get_screen_position(state.target_origin), 0)
				add_point(Utils.get_screen_position(state.target), 1)
			
		else:
			var trail_distance = get_target_distance()
			if trail_distance:
				if get_point_count() < trail_distance:
					update_point(get_point_count(), state.target)
				elif get_point_count() > trail_distance:
					remove_point(0)
					state.positions.remove(0)
					state.points = points
					
			if get_point_count() > 0:
				for point_index in state.positions.size():
					sync_screen_point(point_index)
		if get_point_count() > 0:
			if not $Target_point.visible:
				$Target_point.show()
			set_point_position(get_point_count() - 1,  Utils.get_screen_position(state.target))
			set_point_position(0, Utils.get_screen_position(state.target_origin))
		
	
	elif get_point_count() > 0:
		disconnect_target()

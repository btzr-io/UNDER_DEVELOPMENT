class_name Utils

enum EDGE { LEFT = -1, RIGHT = 1, TOP = -1, BOTTOM = 1, FAR = -1, NEAR = 1 }

static func get_edge_position(target, direction_x = EDGE.LEFT, direction_y = EDGE.TOP ):
	var edge = target.global_position
	var half_size = target.get_current_size() / 2
	edge.x += half_size.x * direction_x 
	edge.y += half_size.y * direction_y
	return edge

static func compare_edge(target, edge, distance = EDGE.NEAR):
	var result = edge
	var next_edge = edge
	var target_edge = get_edge_position(target, EDGE.LEFT, EDGE.TOP)
	var replace_edge = target_edge
	if distance == EDGE.FAR:
		target_edge = edge
		next_edge = get_edge_position(target, EDGE.RIGHT, EDGE.BOTTOM)
		replace_edge = next_edge
		
	if target_edge.x < next_edge.x:
		result.x = replace_edge.x
	if target_edge.y < next_edge.y:
		result.y = replace_edge.y
	
	return result

static func get_area_bounds(targets):
	var bounds = Rect2(Vector2.ZERO, Vector2.ZERO)
	if not targets or not targets.size():
		return bounds
		
	var far = get_edge_position(targets[0], EDGE.RIGHT, EDGE.BOTTOM)
	var near = get_edge_position(targets[0], EDGE.LEFT, EDGE.TOP)

	var targets_size = targets.size()
	var last_index = targets_size
	
	
	
	for target_index in targets_size:
		if target_index < last_index:
			var current = targets[target_index]
			far = compare_edge(current, far, EDGE.FAR)
			near = compare_edge(current, near, EDGE.NEAR)
	
	bounds.size.x = far.x - near.x
	bounds.size.y = far.y - near.y
	bounds.position.x = near.x + bounds.get_center().x
	bounds.position.y = near.y + bounds.get_center().y
	
	return bounds
	
static func remove_all_children(target_parent):
	for child in target_parent.get_children():
		child.queue_free()

static func get_screen_position(target):
	return target.get_global_transform_with_canvas().origin
	
class Connection_manager:
	# State / cache
	var connections = {}
	var memoized_hash = 0
	var memoized_input_connections = {}
	# Events
	signal on_connection_added
	signal on_connection_removed
	
	func has(target, origin):
		if connections.has(target):
			var parent_connection = connections[target]
			if parent_connection.has(origin):
				return true
	
	func get_connection_name(target, origin):
		return target + "_" + origin
		
	func add(target, origin):
		if connections.has(target):
			connections[target][origin] = true
			emit_signal("on_connection_added", get_connection_name(target, origin))
			
	func remove(target, origin):
		if has(target, origin):
			connections[target].erase(origin)
			emit_signal("on_connection_removed", get_connection_name(target, origin))
	
	func remove_all(target):
		if connections.has(target):
			connections.erase(target)
		for connection_parent in connections.keys():
			if connections[connection_parent].has(target):
				connections[connection_parent].erase(target)
	
	func get_output_connections(target):
		var output_connections = []
		if connections.has(target):
			output_connections = connections.keys()
		return output_connections
	
	func get_input_connections(target):
		if memoized_input_connections.has(target):
			if memoized_hash == connections.hash():
				return memoized_input_connections[target]
		var input_connections = []
		for connection_parent in connections.keys():
			if connections[connection_parent].has(target):
				input_connections.append(connection_parent)
		memoized_hash = connections.hash()
		memoized_input_connections[target] = input_connections
		return input_connections

class History_manager:
	var history = []
	var pointer = -1
	var max_size = 3
	var has_undo = false
	var has_redo = false
	var action_after_undo = false
	signal history_change
		
	func _init(new_max_size):
		if max_size > 0:
			max_size = new_max_size
		
	func clear():
		pointer = -1
		action_after_undo = false
		history.clear()

	func push(action_data):
		# When the player executes an action  we append it to the list:
		history.append(action_data)
		# Remove old item if size  exceeded the limit
		if history.size() > max_size:
			var action = history.pop_front()
		# If the player choose a new action after undoing some, everything in the list after the current command is discarded:
		if action_after_undo:
			history = history.slice(0, history.size() -1 )
		# Point to new action added:
		pointer = history.size() - 1
		
	func undo():
		has_undo = pointer > -1
		if not has_undo: return
		# When the player chooses “Undo”, we undo the current action and move the current pointer back.
		action_after_undo = true
		var action_data = history[pointer]["UNDO"]
		pointer -= 1
		emit_signal("history_change", action_data)
		
	func redo():
		has_redo = pointer < history.size() - 1
		action_after_undo = false
		if not has_redo: return
		# When they choose “Redo”, we advance the pointer and then execute	 that action.
		pointer += 1
		var action_data = history[pointer]["EXECUTE"]
		emit_signal("history_change", action_data)


class Error_simulator:
	var error_risk = 0
	var min_glitch_risk = 5
	var max_glitch_risk = 50
	var max_glitch_range = 55
	var error_type = ""
	
	func reset():
		error_risk = 0
		error_type = ""
		
	func update_error_risk(target_distance):
		var distance = clamp(target_distance, 1, max_glitch_range)
		var risk =   max_glitch_range * distance / 500 # 140
		if risk > min_glitch_risk:
			risk = pow(int(risk / 1.6), 2)
		if risk < min_glitch_risk:
			risk = 0
		
		error_risk = clamp(risk, 0, 100)
		if error_risk >= min_glitch_risk and error_risk <= max_glitch_risk:
			error_type = CONSTANTS.BUGS.GLITCH
		elif error_risk > max_glitch_risk:
			error_type = CONSTANTS.BUGS.ERROR

	func predict_error():
		if error_risk == 0:
			return ""
		if error_risk <= max_glitch_risk:	
			var safety_margin = 10
			var risk = randi() % ( max_glitch_risk + safety_margin )
			if risk <= error_risk:
				return CONSTANTS.BUGS.GLITCH
		elif error_risk > max_glitch_risk:
			var danger_margin = 20
			var risk = randi() % ( 100 - danger_margin )
			if risk <= error_risk:
				return CONSTANTS.BUGS.ERROR
		return ""

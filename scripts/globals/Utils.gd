extends Node

func remove_all_children(target_parent):
	for child in target_parent.get_children():
		child.queue_free()

func get_screen_position(target):
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
	var max_size = 5
	var has_undo = false
	var has_redo = false
	var action_after_undo = false
	signal history_change
		
	func _init(new_max_size = 5):
		max_size = new_max_size
		
	func clear():
		history.clear()
		pointer = -1
		action_after_undo = false

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
		var action_data = history[pointer]["UNDO_DATA"]
		pointer -= 1
		emit_signal("history_change", action_data)
		
	func redo():
		has_redo = pointer < history.size() - 1
		action_after_undo = false
		if not has_redo: return
		# When they choose “Redo”, we advance the pointer and then execute	 that action.
		pointer += 1
		var action_data = history[pointer]["EXECUTE_DATA"]
		emit_signal("history_change", action_data)

		
class Entity_State:
	var is_editing = false
	var is_selected = false
	
	func reset():
		is_editing = false
		is_selected = false
		
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
		var risk =   max_glitch_range * distance / 140
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

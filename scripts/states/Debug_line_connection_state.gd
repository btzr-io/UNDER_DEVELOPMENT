extends State
class_name Debug_line_connection_state

var emitting = false
var target = null
var target_origin = null
var target_distance = 0
var points = []
var positions = []

func reset():
	emitting = false
	target = null
	target_origin = null
	target_distance = 0
	points = []
	positions = []

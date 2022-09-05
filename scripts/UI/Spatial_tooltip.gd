extends Label


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var target = null
var tooltip_direction = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


	
func show():
	visible = true
	update()
	

func update():
	# var zoom =   Vector2.ONE / LM.camera.zoom
	rect_size = get_font("font").get_string_size(text) # * zoom
	update_position()

func update_position():
	var zoom =   Vector2.ONE / LM.camera.zoom
	# Align to center
	rect_position =  rect_size  / 2 * -1 
	if tooltip_direction  <= 0:
		# Align to top
		rect_position.y  -= rect_size.y  + rect_size.y * zoom.y 
	else:
		# Alignt to bottom
		rect_position.y += rect_size.y + rect_size.y * zoom.y 
		
	# Aling to left
	rect_position.x  = -target.rect_size.x / 2

func _process(delta):
	if target:
		update()

extends Label


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var camera = get_tree().root.get_node("Level/Player/Camera2D")

func _physics_process(delta):
	var pos = camera.global_transform.origin
	var pos_x = str(int(pos.x))
	var pos_y = str(int(pos.y))
	text = "FPS " + str(Engine.get_frames_per_second()) + " X: " + pos_x + " Y: " + pos_y

extends Label

func _physics_process(_delta):
	var mode = " • " + (CONSTANTS.VIEWS.DEBUG if DM.state.edit_mode else CONSTANTS.VIEWS.RUNTIME)
	if DM.camera:
		var pos = DM.camera.global_transform.origin
		var pos_x = str(int(pos.x))
		var pos_y = str(int(pos.y))
		var position = " X: " + pos_x + " Y: " + pos_y 
		text = "FPS " + str(Engine.get_frames_per_second()) + " • " +  position + mode
	else:
		text = "FPS " + str(Engine.get_frames_per_second()) + mode

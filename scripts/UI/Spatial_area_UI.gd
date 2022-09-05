extends Node2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export (StyleBoxFlat) var default_style
export (StyleBoxFlat) var outline_style 
export (StyleBoxFlat) var flat_style 

onready var world_origin = Position2D.new()

enum STYLES { DEFAULT, OUTLINE }

# Called when the node enters the scene tree for the first time.
func _ready():
	$Shape.add_stylebox_override("panel", default_style)
	LM.level.call_deferred("add_child", world_origin)


func set_style(style=STYLES.DEFAULT):
	if style == STYLES.DEFAULT:
		$Shape.add_stylebox_override("panel", default_style)
	if style == STYLES.OUTLINE:
		$Shape.add_stylebox_override("panel", outline_style)

func set_world_position(new_position):
	world_origin.global_position = new_position

func resize(new_size):
	var zoom =   Vector2.ONE / LM.camera.zoom
	$Shape.rect_size = new_size  * zoom

func update_position():
	global_position = Utils.get_screen_position(world_origin)
	$Shape.rect_position = $Shape.rect_size  / 2 * -1  

func _process(_delta):
	update_position()

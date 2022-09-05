extends Camera2D

export var decay = 0.8  # How quickly the shaking stops [0, 1].
export var max_offset = Vector2(100, 75)  # Maximum hor/ver shake in pixels.
export var max_roll = 0.1  # Maximum rotation in radians (use sparingly).
export (NodePath) var target_path  # Assign the node this camera will follow.

var trauma = 0.0  # Current shake strength.
var trauma_power = 2  # Trauma exponent. Use [2, 3].

onready var noise = OpenSimplexNoise.new()
onready var target = get_node_or_null(target_path)
var noise_y = 0

var next_zoom = Vector2.ZERO

func _ready():
	randomize()
	noise.seed = randi()
	noise.period = 4
	noise.octaves = 2


func add_trauma(amount):
	trauma = min(trauma + amount, 1.0)
	
func _input(event : InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			next_zoom = Vector2.ZERO
			match event.button_index:
				BUTTON_WHEEL_UP:
					next_zoom = zoom - Vector2.ONE * 0.25
				BUTTON_WHEEL_DOWN:
					next_zoom = zoom + Vector2.ONE * 0.25
			if next_zoom != Vector2.ZERO:
				next_zoom.x = clamp(next_zoom.x, 0.1, 1.0)
				next_zoom.y = clamp(next_zoom.y, 0.1, 1.0)
			
func _physics_process(delta):
	if next_zoom:
		zoom = zoom.linear_interpolate(next_zoom, smoothing_speed * 2.0 * delta)
	if target and is_instance_valid(target):
		global_transform.origin = target.global_transform.origin
	if trauma:
		trauma = max(trauma - decay * delta, 0)
		shake()

func shake():
	var amount = pow(trauma, trauma_power)
	noise_y += 1
	rotation = max_roll * amount * noise.get_noise_2d(noise.seed, noise_y)
	offset.x = max_offset.x * amount * noise.get_noise_2d(noise.seed*2, noise_y)
	offset.y = max_offset.y * amount * noise.get_noise_2d(noise.seed*3, noise_y)

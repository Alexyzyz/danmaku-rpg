extends Camera3D

var revolve_t: float

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_placeholder_move(delta)
	pass

func _placeholder_move(delta):
	var PLANAR_DISTANCE = 1
	var angle = lerpf(0, 2 * PI, revolve_t)
	var planar_pos = PLANAR_DISTANCE * Vector2(cos(angle), sin(angle))
	var pos = Vector3(planar_pos.x, position.y, planar_pos.y)
	position = pos
	look_at(Vector3.ZERO)
	
	revolve_t = fmod(revolve_t + 0.05 * delta, 1)

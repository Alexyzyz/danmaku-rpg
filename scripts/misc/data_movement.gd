class_name MovementData

var position: Vector2
var direction: Vector2

var direction_angle: float :
	set(value):
		direction_angle = value
		direction = UtilMath.get_vector_from_angle(direction_angle)

var speed: float
var max_speed: float = INF
var acceleration: float

func update(delta: float) -> Vector2:
	speed = min(speed + delta * acceleration, max_speed)
	
	if speed == 0:
		return position
	
	position += direction * speed * delta
	return position

func reset():
	speed = 0
	max_speed = INF
	acceleration = 0

func rotate(angle: float):
	direction_angle += angle

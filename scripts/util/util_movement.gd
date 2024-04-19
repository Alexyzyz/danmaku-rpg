class_name UtilMovement

class MovementData:
	var position: Vector2
	var direction: float
	var direction_vector: Vector2
	var last_direction: float

	var speed: float
	var max_speed: float = INF
	var acceleration: float

static func get_new_pos(movement: MovementData, delta: float) -> MovementData:
	movement.speed = min(movement.speed + delta * movement.acceleration, movement.max_speed)
	
	if movement.speed == 0:
		return movement
	if movement.direction != movement.last_direction:
		movement.direction_vector = UtilMath.get_vector_from_angle(movement.direction)
	
	movement.last_direction = movement.direction
	movement.position += movement.direction_vector * movement.speed * delta
	return movement

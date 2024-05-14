class_name UtilMath

static func get_vector_from_angle(direction: float) -> Vector2:
	return Vector2(cos(direction), sin(direction))

static func get_angle_from_vector(direction: Vector2) -> float:
	return direction.angle()

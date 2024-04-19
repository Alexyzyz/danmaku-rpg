class_name UtilMath

static func get_vector_from_angle(direction: float) -> Vector2:
	return Vector2(cos(direction), sin(direction))

static func get_angle_from_vector(direction: Vector2) -> float:
	var normalized_dir = direction.normalized()
	return atan2(normalized_dir.y, normalized_dir.x)

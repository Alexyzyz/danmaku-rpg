class_name UtilMath

static func get_vector_from_angle(p_direction: float) -> Vector2:
	return Vector2(cos(p_direction), sin(p_direction))


static func get_angle_from_vector(p_direction: Vector2) -> float:
	return p_direction.angle()


static func is_between(p_value: float, p_a: float, p_b: float) -> bool:
	return p_a < p_value and p_value < p_b


static func vec2_is_inside(p_vec2: Vector2, p_min: Vector2, p_max: Vector2) -> bool:
	return p_vec2.x < p_min.x or p_vec2.x > p_max.x \
		or p_vec2.y < p_min.y or p_vec2.y > p_max.y


static func exp_decay(
	p_a: float,
	p_b: float,
	p_decay: float,
	p_delta: float) -> float:
	
	return p_b + (p_a - p_b) * exp(-p_decay * p_delta)


static func clamp_scroll(p_value: int, p_delta: int, p_min: int, p_max: int):
	var new_value: int = p_value + p_delta
	
	if new_value < p_min:
		var underflow: int = new_value - p_min + 1
		return p_max - underflow
	elif new_value > p_max:
		var overflow: int = new_value - p_max - 1
		return p_min + overflow
	else:
		return new_value


class_name UtilMovement
extends Node

static func get_direction_vector() -> Vector2:
	var moved_right = 1 if Input.is_action_pressed("game_move_right") else 0
	var moved_left = 1 if Input.is_action_pressed("game_move_left") else 0
	var moved_up = 1 if Input.is_action_pressed("game_move_up") else 0
	var moved_down = 1 if Input.is_action_pressed("game_move_down") else 0
	
	var x_axis = moved_right - moved_left
	var y_axis = moved_up - moved_down
	return Vector2(x_axis, -y_axis).normalized()

class_name BattlePlayerShotRegularProjectile
extends Node2D

var damage: float

var _manager: BattlePlayerShotRegular
var _direction: Vector2
var _speed: float

# Main methods

func set_up(p_manager: BattlePlayerShotRegular, p_position: Vector2, p_angle: float, p_shot_damage):
	position = p_position
	
	_manager = p_manager
	_direction = UtilMath.get_vector_from_angle(p_angle)
	_speed = 700
	
	damage = p_shot_damage


func update(p_delta: float):
	_move(p_delta)


# Public methods

func destroy():
	_manager.handle_destroyed_shot(self)
	queue_free()


# Private methods

func _move(p_delta: float):
	var new_pos: Vector2 = position + p_delta * _speed * _direction
	if BattleManager.is_oob(new_pos):
		destroy()
		return
	position = new_pos


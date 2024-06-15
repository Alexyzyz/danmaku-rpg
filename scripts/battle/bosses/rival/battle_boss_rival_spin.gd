class_name BattleBossRivalSpin
extends Node2D

const MAX_HEALTH: float = 600

const SPIRAL_SHOOT_TIME: float = 0.1
const SPIRAL_SHOOT_ANGLE_STEP: float = 0.63 * PI
const MOVE_TIME: float = 2

var _parent: Node2D
var _spiral_shoot_alarm: float
var _spiral_shoot_angle: float
var _move_alarm: float
var _pos_start: Vector2
var _pos_target: Vector2
var _move_t: float

# Public methods

func set_up():
	_parent = get_parent()
	_pos_start = _parent.position
	_pos_target = _pos_start
	pass


func update(p_delta: float):
	_handle_shoot_spiral(p_delta)
	_handle_movement(p_delta)
	_handle_move(p_delta)
	pass


# Private methods

func _handle_move(p_delta: float):
	if _move_alarm > 0:
		_move_alarm -= p_delta
		return
	_move_alarm = MOVE_TIME
	
	_move_t = 0
	_pos_start = _parent.position
	var angle: float = randf_range(0, TAU)
	var distance: float = randf_range(40, 80)
	_pos_target = _pos_start + distance * UtilMath.get_vector_from_angle(angle)
	pass


func _handle_movement(p_delta: float):
	_move_t = UtilMath.exp_decay(_move_t, 1, 4, p_delta)
	var new_position: Vector2 = lerp(_pos_start, _pos_target, _move_t)
	_parent.position = new_position.clamp(Vector2.ZERO, BattleManager.battle_area_size)


func _handle_shoot_spiral(p_delta: float):
	_spiral_shoot_angle += p_delta * SPIRAL_SHOOT_ANGLE_STEP
	if _spiral_shoot_alarm > 0:
		_spiral_shoot_alarm -= p_delta
		return
	_spiral_shoot_alarm = SPIRAL_SHOOT_TIME
	
	var bullet_list: Array[Bullet] = BattleBulletManager.shoot_bullet_ring(
			_parent.position, _spiral_shoot_angle, 200, 5
	)
	
	for bullet in bullet_list:
		# bullet.acceleration = 100
		# bullet.max_speed = 500
		bullet.behavior = BulletBehavior.new(bullet)

	pass

# Subclasses

class BulletBehavior:
	
	var _bullet: Bullet
	var _total_rotation: float
	
	func _init(p_bullet: Bullet):
		_bullet = p_bullet
	
	
	func update(p_delta: float):
		var rotate_by: float = p_delta * 0.23 * PI
		_bullet.rotate(rotate_by)
		
		_total_rotation += rotate_by
		if _total_rotation > 0.7 * PI:
			_bullet.behavior = null
		pass

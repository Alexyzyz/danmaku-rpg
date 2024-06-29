class_name BattleEnemyConstrictor
extends Node2D

const MAX_HEALTH: float = 500
const CONSTRICT_WAVE_TIME: float = 4

var _parent: Node2D
var _attack_wave_alarm: float
var _attack_constrictor: AttackConstrictor

# Main methods

func set_up():
	_parent = get_parent()
	_attack_constrictor = AttackConstrictor.new(_parent)
	pass

func update(p_delta: float):
	_handle_attack_wave(p_delta)
	
	_attack_constrictor.update(p_delta)
	pass

# Private methods

func _handle_attack_wave(p_delta: float):
	if _attack_wave_alarm > 0:
		_attack_wave_alarm -= p_delta
		return
	_attack_wave_alarm = CONSTRICT_WAVE_TIME
	_attack_constrictor.reset()
	pass

# Subclasses

class AttackConstrictor:
	const ANGLE_MAX: float = 0.3 * PI
	const ANGLE_MIN: float = 0.01 * PI
	const BULLET_COUNT: int = 24
	const BULLET_SPEED: float = 240
	const SHOOT_TIME: float = 0.07
	
	var _parent: Node2D
	var _shoot_alarm: float
	var _target_angle: float
	var _shoot_index: int
	var _curve_shoot_angle: Curve
	
	func _init(p_parent: Node2D):
		_parent = p_parent
		_curve_shoot_angle = preload("res://scripts/battle/enemies/constrictor/curve_battle_enemy_constrictor_shoot_angle.tres")
	
	func update(p_delta: float):
		if _shoot_index > BULLET_COUNT:
			return
		_handle_attack(p_delta)
		pass
	
	func reset():
		_target_angle = UtilMath.get_angle_from_vector(BattleManager.get_player().position - _parent.position)
		_shoot_alarm = 0
		_shoot_index = 0
		pass
	
	func _handle_attack(p_delta: float):
		if _shoot_alarm > 0:
			_shoot_alarm -= p_delta
			return
		_shoot_alarm = SHOOT_TIME
		
		var shoot_angle = ANGLE_MIN \
				+ (ANGLE_MAX - ANGLE_MIN) \
				* _curve_shoot_angle.sample(_shoot_index / float(BULLET_COUNT))
		
		var bullet_left: Bullet = BattleBulletManager.shoot_bullet(_parent.position, _target_angle + shoot_angle, BULLET_SPEED)
		var bullet_right: Bullet = BattleBulletManager.shoot_bullet(_parent.position, _target_angle - shoot_angle, BULLET_SPEED)
		
		bullet_left.behavior = BulletBehavior.new(bullet_left, BULLET_SPEED)
		bullet_right.behavior = BulletBehavior.new(bullet_right, BULLET_SPEED)
		
		_shoot_index += 1
		pass
	
	class BulletBehavior:
		const END_SPEED: float = 80
		const SPEED_CHANGE_TIME: float = 0.5
		
		var _bullet: Bullet
		var _alarm: float = 0.2
		var _speed_change_alarm: float
		var _start_speed: float
		
		func _init(p_bullet: Bullet, p_start_speed: float):
			_bullet = p_bullet
			_start_speed = p_start_speed
		
		func update(p_delta: float):
			if _alarm > 0:
				_alarm -= p_delta
				return
			
			_speed_change_alarm += p_delta
			if _speed_change_alarm > SPEED_CHANGE_TIME:
				_bullet.speed = END_SPEED
				_bullet.behavior = null
				return
			_bullet.speed = lerpf(_start_speed, END_SPEED, _speed_change_alarm / float (SPEED_CHANGE_TIME))
		
		

class_name BattleEnemyDenseRing
extends Node2D

const MAX_HEALTH: float = 300

var _parent: Node2D
var _attack_shoot_queue: EventQueue
var _movement_queue: EventQueue

var _attack_ring: AttackRing
var _movement: MovementHandler


# Main methods

func set_up():
	_parent = get_parent()
	_attack_ring = AttackRing.new(_parent)
	_movement = MovementHandler.new(_parent)
	
	_attack_shoot_queue = EventQueue.new(
		[
			Event.new(0, Callable(_shoot)),
			Event.new(4.5),
		]
	)
	
	_movement_queue = EventQueue.new(
		[
			Event.new(0, Callable(_move)),
			Event.new(1),
		]
	)


func update(p_delta: float):
	_attack_shoot_queue.update(p_delta)
	_movement_queue.update(p_delta)
	_movement.update(p_delta)
	pass


# Private methods

func _move():
	var angle: float = randf_range(0, TAU)
	var dir: Vector2 = UtilMath.get_vector_from_angle(angle)
	var distance: float = randf_range(40, 80)
	_movement.move_to(_parent.position + distance * dir)

func _shoot():
	var angle: float = randf_range(0, TAU)
	BattleBulletManager.shoot_bullet_ring(_parent.position, angle, 60, 128)


# Subclasses

class AttackRing:
	const SHOOT_TIME: float = 2
	
	var _parent: Node2D
	var _shoot_alarm: float
	
	func _init(p_parent: Node2D):
		_parent = p_parent
	
	
	func update(p_delta: float):
		if _shoot_alarm > 0:
			_shoot_alarm -= p_delta
			return
		_shoot_alarm = SHOOT_TIME
		
		BattleBulletManager.shoot_bullet_ring(_parent.position, randf_range(0, TAU), 10, 32)
		pass


class MovementHandler:
	var _parent: Node2D
	var _last_pos: Vector2
	var _target_pos: Vector2
	var _t: float
	
	func _init(p_parent: Node2D):
		_parent = p_parent
		_last_pos = _parent.position
		_target_pos = _parent.position
	
	
	func update(p_delta: float):
		_t = UtilMath.exp_decay(_t, 1, 4, p_delta)
		var new_pos: Vector2 = lerp(_last_pos, _target_pos, _t)
		
		_parent.position = new_pos.clamp(Vector2.ZERO, BattleManager.battle_area_size)
	
	
	func move_to(p_new_pos: Vector2):
		_last_pos = _parent.position
		_target_pos = p_new_pos
		_t = 0


class_name BattleBossMiscMajorSwarms
extends Node2D

var _owner: Node2D
var _main_attack: MainAttack
var _main_movement: MainMovement

# Main methods

func set_up(p_owner: Node2D):
	_owner = p_owner
	_main_attack = MainAttack.new(p_owner)
	_main_movement = MainMovement.new(p_owner)

func tick(p_delta: float):
	_main_attack.tick(p_delta)
	_main_movement.tick(p_delta)

# Subclasses

class MainMovement:
	var _owner: BattleEnemy
	
	func _init(p_owner: BattleEnemy):
		_owner = p_owner
	
	func tick(p_delta: float):
		var direction: Vector2 = (BattleManager.get_player().position - _owner.position).normalized()
		direction = p_delta * 10 * direction
		_owner.move_to(direction)
		

class MainAttack:
	const TIMER: float = 0.07
	const ANGLE_SPEED: float = 0.4507 * TAU # 0.45 * TAU
	
	var _owner: Node2D
	var _tickable_list: Array[SwarmAttack]
	var _alarm: float
	var _angle: float
	
	var _on_tickable_end: Callable = func(p_tickable: SwarmAttack):
		_tickable_list.erase(p_tickable)
	
	# Main methods
	
	func _init(p_owner: Node2D):
		_owner = p_owner
	
	# Public methods
	
	func tick(p_delta: float):
		for tickable in _tickable_list:
			tickable.tick(p_delta)
		
		if _alarm > 0:
			_alarm -= p_delta
			return
		_alarm = TIMER
		
		var new_swarm: SwarmAttack = SwarmAttack.new(_owner, _angle, _on_tickable_end)
		_tickable_list.push_back(new_swarm)
		_angle += ANGLE_SPEED
	

class SwarmAttack:
	const BULLET_COUNT: int = 16
	const BULLET_SPREAD: float = 16
	const BULLET_SPEED: float = 0
	const BULLET_ACCELERATION: float = 100
	const BULLET_MAX_SPEED: float = 100
	const TIMER: float = 0.001
	
	var _owner: Node2D
	var _bullet_index: int
	var _angle: float
	var _alarm: float
	var _on_tickable_end: Callable
	
	# Main methods
	
	func _init(p_owner: Node2D, p_angle: float, p_on_tickable_end: Callable):
		_owner = p_owner
		_angle = p_angle
		_on_tickable_end = p_on_tickable_end
	
	# Public methods
	
	func tick(p_delta: float):
		if _alarm > 0:
			_alarm -= p_delta
			return
		_alarm = TIMER
		
		for i in 3:
			_bullet_index += 1
			if _bullet_index >= BULLET_COUNT:
				_on_tickable_end.call(self)
				return
			
			var pos: Vector2 = \
				_owner.position + \
				Vector2(
					randf_range(-BULLET_SPREAD, BULLET_SPREAD),
					randf_range(-BULLET_SPREAD, BULLET_SPREAD))
			
			var bullet: Bullet = BattleBulletManager.shoot_bullet(
				pos,
				_angle,
				BULLET_SPEED,
				UtilBulletResource.default
			)
			if bullet == null:
				continue
			bullet.acceleration = BULLET_ACCELERATION
			bullet.max_speed = BULLET_MAX_SPEED
	

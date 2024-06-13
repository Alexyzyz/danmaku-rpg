class_name BattleShotDetonatorProjectile
extends Node2D

const EFFECTIVE_DISTANCE: float = 100

var _damage_min: float
var _damage_max: float
var _damage_curve: Curve

var _manager: BattleShotDetonator
var _direction: Vector2
var _speed: float

# Main methods

func set_up(
		p_manager: BattleShotDetonator,
		p_position: Vector2,
		p_angle: float,
		p_damage_min: float,
		p_damage_max: float,
		p_damage_curve: Curve):
	
	position = p_position
	
	_manager = p_manager
	_direction = UtilMath.get_vector_from_angle(p_angle)
	_speed = 700
	
	_damage_min = p_damage_min
	_damage_max = p_damage_max
	_damage_curve = p_damage_curve


func update(p_delta: float):
	_move(p_delta)


# Public methods

func detonate():
	var enemies: Array[BattleEnemy] = BattleManager.get_enemies()
	for enemy in enemies:
		var vector_to_enemy: Vector2 = enemy.position - position
		var distance: float = vector_to_enemy.length()
		if distance > EFFECTIVE_DISTANCE:
			continue
		damage_enemy(enemy, distance)
		pass
	BattleManager.spawn_ripple(position)
	destroy()
	pass


func damage_enemy(p_enemy: BattleEnemy, p_distance: float):
	var t: float = 1 - (p_distance / EFFECTIVE_DISTANCE)
	var damage: float = _damage_min + (_damage_max - _damage_min) * _damage_curve.sample(t)
	p_enemy.damage(damage, p_enemy.global_position)
	pass


func destroy():
	_manager.handle_destroyed_shot()
	queue_free()


# Private methods

func _move(p_delta: float):
	var new_pos: Vector2 = position + p_delta * _speed * _direction
	if BattleManager.is_oob(new_pos):
		destroy()
		return
	position = new_pos


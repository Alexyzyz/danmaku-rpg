class_name BattleEnemyWindSuck
extends Node2D

const MAX_HEALTH: float = 300
const SUCK_RADIUS: float = 300
const SUCK_MAX_STRENGTH: float = 120

var _parent: Node2D
var _suck_strength_curve: Curve
var _direction: Vector2
var _speed: float = 50

# Main methods

func set_up():
	_parent = get_parent()
	_suck_strength_curve = preload("res://scripts/battle/enemies/wind_suck/curve_battle_enemy_wind_suck_strength.tres")
	_direction = UtilMath.get_vector_from_angle(randf_range(0, TAU))
	pass


func update(p_delta: float):
	_move(p_delta)
	_suck_player(p_delta)
	pass


# Private methods

func _move(p_delta: float):
	var new_pos: Vector2 = _parent.position + p_delta * _speed * _direction
	if new_pos.x < 0 or new_pos.x > BattleManager.battle_area_east_x:
		_direction.x *= -1
	if new_pos.y < 0 or new_pos.y > BattleManager.battle_area_south_y:
		_direction.y *= -1
	new_pos = new_pos.clamp(Vector2.ZERO, BattleManager.battle_area_size)
	_parent.position = new_pos


func _suck_player(p_delta: float):
	var player: BattlePlayer = BattleManager.get_player()
	var me_to_player_vector: Vector2 = _parent.position - player.position
	var player_distance: float = me_to_player_vector.length()
	
	if player_distance > SUCK_RADIUS:
		return
	var t: float = 1 - (player_distance / SUCK_RADIUS)
	var suck_strength: float = SUCK_MAX_STRENGTH * _suck_strength_curve.sample(t)
	
	# Prevents jittering motion
	if suck_strength > player_distance:
		player.push(me_to_player_vector)
		return
	
	player.push(suck_strength * me_to_player_vector.normalized())
	pass


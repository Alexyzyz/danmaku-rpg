class_name BattleShotDetonator
extends Node2D

const SHOOT_COOLDOWN_TIME: float = 0

const SHOT_DAMAGE_MIN: float = 10
const SHOT_DAMAGE_MAX: float = 80

const AIM_NOTCHES: int = 32
const AIM_TICK_TIME: float = 0.01

var _player: BattlePlayer
# This shot only has one active projectile at a time
var _projectile: Node2D

var _shoot_cooldown_alarm: float = 0

var _aim_angle: float = -PI / 2
var _aim_tick_alarm: float

var _prefab_shot: PackedScene

@export var _curve_damage: Curve

# Main methods

func set_up():
	_player = BattleManager.get_player()
	_prefab_shot = preload("res://prefabs/battle/shots/detonator/prefab_battle_shot_detonator_projectile.tscn")


func update(p_delta: float):
	_handle_shoot_input(p_delta)
	_handle_aim_inputs(p_delta)
	_update_projectile(p_delta)


func handle_destroyed_shot():
	_projectile = null


func get_projectiles() -> Array[Node2D]:
	return []


# Private methods

func _handle_shoot_input(p_delta: float):
	if _shoot_cooldown_alarm > 0:
		_shoot_cooldown_alarm -= p_delta
		return
	
	if !Input.is_action_just_pressed("game_confirm"):
		return
	
	# CASE 2 ✦ Detonate pre-existing projectile
	if _projectile != null:
		_shoot_cooldown_alarm = SHOOT_COOLDOWN_TIME
		_projectile.detonate()
		return
	
	# CASE 1 ✦ Launch a projectile
	var new_shot: BattleShotDetonatorProjectile = _prefab_shot.instantiate()
	BattleManager._parent_player_shots.add_child(new_shot)
	_projectile = new_shot
	new_shot.set_up(
			self, _player.position, _aim_angle,
			SHOT_DAMAGE_MIN, SHOT_DAMAGE_MAX, _curve_damage)


func _handle_aim_inputs(p_delta: float):
	var aim_left: int = 1 if Input.is_action_pressed("battle_aim_left") else 0
	var aim_right: int = 1 if Input.is_action_pressed("battle_aim_right") else 0
	var aim_axis: int = aim_right - aim_left
	
	if aim_axis == 0:
		_aim_tick_alarm = AIM_TICK_TIME
		return
	
	if _aim_tick_alarm > 0:
		_aim_tick_alarm -= p_delta
		return
	_aim_tick_alarm = AIM_TICK_TIME
	
	_aim_angle += aim_axis * TAU / AIM_NOTCHES


func _update_projectile(p_delta: float):
	if _projectile != null:
		_projectile.update(p_delta)


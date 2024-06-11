class_name BattlePlayerShotRegular
extends Node2D

const SHOOT_TIME: float = 0.06

const SHOT_DAMAGE: float = 3

const AIM_NOTCHES: int = 32
const AIM_TICK_TIME: float = 0.01

var _player: BattlePlayer
var _projectile_list: Array[Node2D] = []

var _shoot_alarm: float

var _aim_angle: float = -PI / 2
var _aim_tick_alarm: float

var _is_shooting: bool

var _prefab_shot: PackedScene

# Main methods

func set_up():
	_player = BattleManager.get_player()
	_prefab_shot = preload("res://prefabs/battle/player_shots/regular/prefab_battle_player_shot_regular_projectile.tscn")


func update(p_delta: float):
	_handle_shoot_input(p_delta)
	_handle_aim_inputs(p_delta)
	_update_projectiles(p_delta)


func handle_destroyed_shot(p_shot: Node2D):
	_projectile_list.erase(p_shot)


func get_projectiles() -> Array[Node2D]:
	return _projectile_list


# Private methods

func _handle_shoot_input(p_delta: float):
	if Input.is_action_just_pressed("game_confirm"):
		_is_shooting = !_is_shooting
	
	if !_is_shooting:
		return
	if _shoot_alarm > 0:
		_shoot_alarm -= p_delta
		return
	_shoot_alarm = SHOOT_TIME
	
	var new_shot: BattlePlayerShotRegularProjectile = _prefab_shot.instantiate()
	BattleManager._parent_player_shots.add_child(new_shot)
	_projectile_list.push_back(new_shot)
	new_shot.set_up(self, _player.position, _aim_angle, SHOT_DAMAGE)


func _handle_aim_inputs(p_delta: float):
	var aim_left: int = 1 if Input.is_action_pressed("game_aim_left") else 0
	var aim_right: int = 1 if Input.is_action_pressed("game_aim_right") else 0
	var aim_axis: int = aim_right - aim_left
	
	if aim_axis == 0:
		_aim_tick_alarm = AIM_TICK_TIME
		return
	
	if _aim_tick_alarm > 0:
		_aim_tick_alarm -= p_delta
		return
	_aim_tick_alarm = AIM_TICK_TIME
	
	_aim_angle += aim_axis * TAU / AIM_NOTCHES


func _update_projectiles(p_delta: float):
	for projectile in _projectile_list:
		projectile.update(p_delta)


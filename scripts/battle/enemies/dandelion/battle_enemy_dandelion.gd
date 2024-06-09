class_name BattleEnemyDandelion
extends Node2D

const MAX_HEALTH: float = 200
const SPAWN_TIME: float = 5

var _parent: Node2D
var _spawn_alarm: float
# Prefabs
var _prefab_enemy: PackedScene

# Public methods

func set_up():
	_parent = get_parent()
	_prefab_enemy = preload("res://prefabs/prefab_enemy.tscn")
	pass


func update(p_delta: float):
	_move(p_delta)
	_handle_spawning(p_delta)
	pass


# Private methods

func _handle_spawning(p_delta: float):
	if _spawn_alarm > 0:
		_spawn_alarm -= p_delta
		return
	_spawn_alarm = SPAWN_TIME
	
	var new_enemy: BattleEnemy = _prefab_enemy.instantiate()
	new_enemy.set_up(_parent.position, null, 20, BattleEnemy.HealthDisplay.BAR, false)
	new_enemy.set_behavior(BattleEnemyDandelionSeedling)
	BattleManager.add_minor_enemy(new_enemy)
	
	var new_seedling: BattleEnemyDandelionSeedling = new_enemy.get_behavior()
	new_seedling.set_up()


func _move(p_delta: float):
	var dir := Vector2(BattleManager.get_player().position - _parent.position).normalized()
	_parent.position += p_delta * 50 * dir

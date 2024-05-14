class_name BossMechanicSideAimAttack
extends Node2D

class SpawnMinionAttack:
	var alarm: float
	var timer: float = 0.25
	var spawn_on_the_left: bool
var spawn_minion_attack: SpawnMinionAttack

class MinionsShootAttack:
	var alarm: float
	var timer: float = 1
var minions_shoot_attack: MinionsShootAttack

var prefab_minion = preload("res://scripts/battle/bosses/mechanic/side_aim_attack/boss_mechanic_side_aim_attack_minion.tscn")

static var minion_list: Array[BossMechanicSideAimAttackMinion]

func _ready():
	spawn_minion_attack = SpawnMinionAttack.new()
	minions_shoot_attack = MinionsShootAttack.new()

func _process(delta):
	_handle_spawn_minion_attack(delta)
	_handle_minions_shoot_attack(delta)

# Public methods

static func handle_minion_despawn(minion: BossMechanicSideAimAttackMinion):
	var i = minion_list.find(minion)
	minion_list.remove_at(i)
	minion.queue_free()

# Private methods

func _handle_spawn_minion_attack(delta):
	if spawn_minion_attack.alarm > 0:
		spawn_minion_attack.alarm -= delta
		return
	spawn_minion_attack.alarm = spawn_minion_attack.timer
	
	var spawn_pos = Vector2(0, 0)
	if !spawn_minion_attack.spawn_on_the_left:
		spawn_pos = BattleManager.battle_area_size
		spawn_pos.y = 0
	
	var new_minion: BossMechanicSideAimAttackMinion = prefab_minion.instantiate()	
	BattleManager.parent.add_child(new_minion)
	minion_list.append(new_minion)
	
	new_minion.set_up(spawn_pos, PI / 2, 120)
	
	spawn_minion_attack.spawn_on_the_left = !spawn_minion_attack.spawn_on_the_left

func _handle_minions_shoot_attack(delta):
	if minions_shoot_attack.alarm > 0:
		minions_shoot_attack.alarm -= delta
		return
	minions_shoot_attack.alarm = minions_shoot_attack.timer
	
	for i in minion_list.size():
		var minion = minion_list[i]
		minion.shoot_at_player()

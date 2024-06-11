class_name BattleEnemyElitePriest
extends Node2D

var _attack_main: AttackMain = AttackMain.new()

@onready var _bullet_texture: Texture2D = preload("res://sprites/bullets/spr_bullet_0.png")

# Public methods

func set_up(p_shooter: Node2D):
	pass


func tick(delta):
	_attack_main.tick(delta)


# Subclasses

class AttackMain:
	var _alarm: AlarmData
	var _attack_summon_minion_list: Array[AttackSummonMinion]
	
	func _init():
		_alarm = AlarmData.new(2, 0, _summon_minions)
	
	func tick(delta: float):
		_alarm.tick(delta)
		for i in _attack_summon_minion_list:
			i.tick(delta)
	
	var _summon_minions = func():
		_attack_summon_minion_list.push_back(AttackSummonMinion.new())

class AttackSummonMinion:
	const SQRT_2: float = sqrt(2)
	const RANDOM_OFFSET: float = 0 # 10
	
	var alarm: AlarmData
	
	var minion_pos_list: Array[Vector2]
	var minion_list: Array[MinionShooter]
	var player_pos: Vector2
	var starting_angle: float = randf_range(0, PI)
	
	func _init():
		alarm = AlarmData.new(0.01, 0, _summon)
		_set_up_positions()
		player_pos = BattleManager.get_player().position
	
	func tick(delta: float):
		alarm.tick(delta)
		for i in minion_list:
			i.tick(delta)
	
	func _set_up_positions():
		var angle_step: float = TAU / 6
		var curr_angle: float = starting_angle
		for i in range(6):
			var pos = Vector2(cos(curr_angle), sin(curr_angle))
			minion_pos_list.push_back(pos)
			curr_angle += angle_step
		minion_pos_list.shuffle()

	var _summon = func():
		if minion_pos_list.size() == 0:
			return
		
		var random_offset: Vector2 = Vector2(randf_range(-RANDOM_OFFSET, RANDOM_OFFSET), randf_range(-RANDOM_OFFSET, RANDOM_OFFSET))
		var minion_pos: Vector2 = minion_pos_list.pop_front()
		
		var new_minion = MinionShooter.new(player_pos + 100 * minion_pos + random_offset, starting_angle)
		minion_list.push_back(new_minion)

class MinionShooter:
	var alarm: AlarmData
	var shoot_pos: Vector2
	var shoot_dir: float
	var shoot_count: int = 4
	
	var _bullet_texture: Texture2D = preload("res://sprites/bullets/spr_bullet_0.png")
	
	func _init(pos: Vector2, dir: float):
		alarm = AlarmData.new(0.03, 0, _shoot)
		shoot_pos = pos
		shoot_dir = dir
	
	func tick(delta: float):
		alarm.tick(delta)
	
	var _shoot = func():
		if shoot_count == 0:
			return
		shoot_count -= 1
		
		var bullet_list: Array[Bullet] = BattleBulletManager.shoot_bullet_ring(
			shoot_pos,
			shoot_dir,
			3,
			3,
			UtilBulletResource.default)
		
		for i in bullet_list.size():
			var bullet: Bullet = bullet_list[i]
			if is_instance_valid(bullet):
				bullet.acceleration = 200
				bullet.max_speed = 300
		

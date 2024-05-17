class_name EnemyNatureTriangleAimer
extends Node2D

var shooter: Node2D
var attack_main: AttackMain

# Public methods

func set_up(shooter: Node2D):
	self.shooter = shooter
	attack_main = AttackMain.new(shooter)

func tick(delta: float):
	attack_main.tick(delta)

# Private methods

class AttackMain:
	var shooter: Node2D
	var alarm_a: AlarmData
	var alarm_b: AlarmData
	var tick_list: Array = []
	
	func _init(shooter: Node2D):
		self.shooter = shooter
		alarm_a = AlarmData.new(3, 0, _shoot_triangle_slow)
		alarm_b = AlarmData.new(1.7, 1, _shoot_triangle_fast)
	
	func tick(delta: float):
		alarm_a.tick(delta)
		alarm_b.tick(delta)
		for x in tick_list:
			x.tick(delta)
	
	func _shoot_triangle_slow():
		var direction = UtilMath.get_angle_from_vector(BattleManager.obj_player.position - shooter.position)
		var new_tickable = AttackTriangle.new(
				shooter,
				direction,
				7,
				0.05,
				0.5 * TAU,
				150,
				UtilBulletResource.default)
		tick_list.push_back(new_tickable)
	
	func _shoot_triangle_fast():
		var direction = UtilMath.get_angle_from_vector(BattleManager.obj_player.position - shooter.position)
		var new_tickable = AttackTriangle.new(
				shooter,
				direction,
				5,
				0.01,
				0.01 * TAU,
				200,
				UtilBulletResource.rice)
		tick_list.push_back(new_tickable)

class AttackTriangle:	
	var shooter: Node2D
	var alarm: AlarmData
	var shoot_direction: float
	var shoot_index: int = 0
	var shoot_count: int
	var shoot_time: float
	var spread_angle_max: float
	var bullet_speed: float
	var bullet_resource: BulletResource
	
	func _init(
		shooter: Node2D,
		shoot_direction: float,
		shoot_count: int,
		shoot_time: float,
		spread_angle_max: float,
		bullet_speed: float,
		bullet_resource: BulletResource):
		
		self.shooter = shooter
		self.shoot_direction = shoot_direction
		self.shoot_count = shoot_count
		self.shoot_time = shoot_time
		self.spread_angle_max = spread_angle_max
		self.bullet_speed = bullet_speed
		self.bullet_resource = bullet_resource
		
		alarm = AlarmData.new(shoot_time, 0, _shoot_triangles)
	
	func tick(delta: float):
		alarm.tick(delta)
	
	var _shoot_triangles = func():
		if shoot_index >= shoot_count:
			return
		
		var spread_angle: float = spread_angle_max * (float(shoot_index) / float(shoot_count))
		BattleManager.shoot_bullet_ring(
			shooter.position,
			shoot_direction,
			bullet_speed,
			shoot_index,
			spread_angle,
			bullet_resource)
		
		shoot_index += 1
	

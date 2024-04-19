class_name BossMechanicSpiralSpawnAttackAI
extends Node2D

enum AttackState {
	IDLE,
	SPIRAL
}
var current_attack: AttackState = AttackState.SPIRAL

class IdleCooldown:
	var alarm: float
	var timer: float = 1
	
	func reset():
		alarm = timer
var idle_cooldown: IdleCooldown = IdleCooldown.new()

class SpiralAttack:
	const ANGLE_DELTA: float = 37
	const DISTANCE_DELTA: float = 7
	const SPIRAL_ARM_COUNT: int = 7
	
	var alarm: float
	var timer: float = 0.0001
	var last_spawn_pos: Array[Vector2]
	var base_angle: float
	var angle: float
	var spiral_direction: int = 1
	var base_distance: float = 32
	var distance: float
	
	var bullet_index: int
	var bullet_count: int = 64
	
	func reset():
		alarm = timer
		base_angle = randf_range(0, 2 * PI)
		angle = 0
		distance = base_distance
		spiral_direction = 1 if spiral_direction == -1 else -1
		bullet_index = 0
		
		last_spawn_pos.clear()
		for i in SPIRAL_ARM_COUNT:
			last_spawn_pos.push_back(Vector2.ZERO)
var spiral_attack: SpiralAttack = SpiralAttack.new()

func _ready():
	spiral_attack.reset()

func _process(delta):
	if current_attack == AttackState.IDLE:
		_handle_idle_cooldown(delta)
	elif current_attack == AttackState.SPIRAL:
		_handle_spiral_attack(delta)

func _handle_spiral_attack(delta):
	if spiral_attack.alarm > 0:
		spiral_attack.alarm -= delta
		return
	spiral_attack.alarm = spiral_attack.timer
	
	# Prepare to cool down
	if spiral_attack.bullet_index > spiral_attack.bullet_count:
		current_attack = AttackState.IDLE
		idle_cooldown.reset()
		return
	
	# The attack
	for i in spiral_attack.SPIRAL_ARM_COUNT:
		var true_angle = spiral_attack.base_angle + spiral_attack.angle + i * (2 * PI / spiral_attack.SPIRAL_ARM_COUNT)
		var spawn_pos: Vector2 = position + spiral_attack.distance * Vector2(cos(true_angle), sin(true_angle))
		var new_bullet = BattleManager.shoot_bullet(spawn_pos, randf_range(0, 2 * PI), 10, UtilBulletResource.rice)
		
		var bullet_dir: float
		if spiral_attack.bullet_index < 2:
			bullet_dir = UtilMath.get_angle_from_vector(spawn_pos - position)
			new_bullet.destroy()
		else:
			bullet_dir = UtilMath.get_angle_from_vector(spiral_attack.last_spawn_pos[i] - spawn_pos)
		spiral_attack.last_spawn_pos[i] = spawn_pos
		
		new_bullet.movement.acceleration = 50
		new_bullet.movement.max_speed = 1000
		new_bullet.movement.direction = bullet_dir
	
	spiral_attack.angle += spiral_attack.spiral_direction * spiral_attack.ANGLE_DELTA
	spiral_attack.distance += spiral_attack.DISTANCE_DELTA
	spiral_attack.bullet_index += 1

func _handle_idle_cooldown(delta):
	if idle_cooldown.alarm > 0:
		idle_cooldown.alarm -= delta
		return
	current_attack = AttackState.SPIRAL
	spiral_attack.reset()

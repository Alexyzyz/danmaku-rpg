class_name BossMechanicSpiralSpawnAttackAI
extends Node2D

@export var ANGLE_DELTA: float = 2.006
@export var DISTANCE_DELTA: float = 3.955
@export var SPIRAL_ARM_COUNT: int = 4

var spiral_attack_a: SpiralAttack = SpiralAttack.new()
var spiral_attack_b: SpiralAttack = SpiralAttack.new()

@onready var _bullet_texture: Texture2D = preload("res://sprites/bullets/spr_bullet_1.png")

# Main methods

func _ready():
	spiral_attack_a.reset()
	spiral_attack_b.reset()
	
	spiral_attack_a.base_hue = 0.1
	
	spiral_attack_b.alarm = 1.2
	spiral_attack_b.spiral_direction = -1
	spiral_attack_b.base_hue = 0.15
	

func _process(delta):
	_handle_spiral_attack(spiral_attack_a, delta)
	_handle_spiral_attack(spiral_attack_b, delta)

func _handle_spiral_attack(spiral_attack: SpiralAttack, delta):
	if spiral_attack.alarm > 0:
		spiral_attack.alarm -= delta
		return
	
	if spiral_attack.state == SpiralAttack.State.COOLDOWN:
		spiral_attack.reset()
		spiral_attack.state = SpiralAttack.State.ACTIVE
		spiral_attack.alarm = spiral_attack.shoot_timer
	
	# Check if it's in cool down
	if spiral_attack.bullet_index > spiral_attack.bullet_count:
		spiral_attack.unwind_pattern()
		spiral_attack.state = SpiralAttack.State.COOLDOWN
		spiral_attack.alarm = spiral_attack.cooldown_timer
		return
	
	# The attack
	var curr_angle = spiral_attack.angle
	var next_angle = curr_angle + spiral_attack.spiral_direction * ANGLE_DELTA
	
	var curr_distance = spiral_attack.distance
	var next_distance = curr_distance + DISTANCE_DELTA
	
	var bullet_dir = -(
		curr_distance * Vector2(cos(curr_angle), sin(curr_angle)) -
		next_distance * Vector2(cos(next_angle), sin(next_angle))
		)
	
	var bullet_color: Color = Color.from_hsv(spiral_attack.hue, 1, 1, 1)
	spiral_attack.hue += delta / 15
	spiral_attack.hue = fmod(spiral_attack.hue, 1.0)
	
	for i in SPIRAL_ARM_COUNT:
		var ring_angle_step: float = i * (TAU / SPIRAL_ARM_COUNT)
		var ring_angle: float = curr_angle + ring_angle_step 
		var spawn_pos: Vector2 = get_parent().position + curr_distance * Vector2(cos(ring_angle), sin(ring_angle))
		var ring_dir: float = UtilMath.get_angle_from_vector(bullet_dir.rotated((ring_angle_step)))
		
		var new_bullet: Bullet = BattleBulletManager.shoot_bullet(
			spawn_pos,
			ring_dir,
			5,
			UtilBulletResource.default)
		if new_bullet == null:
			continue
		new_bullet.max_speed = 1000
		spiral_attack.bullet_list.push_back(new_bullet)
	
	spiral_attack.angle = next_angle
	spiral_attack.distance = next_distance
	spiral_attack.bullet_index += 1

# Subclasses

class SpiralAttack:
	enum State {
		COOLDOWN,
		ACTIVE
	}
	
	var state: State = State.COOLDOWN
	var alarm: float
	var shoot_timer: float = 0.001
	var cooldown_timer: float = 1
	
	var bullet_list: Array[Bullet]
	var base_angle: float
	var angle: float
	var base_distance: float = 32
	var distance: float
	var base_hue: float
	var hue: float
	var spiral_direction: int = 1
	
	var bullet_index: int
	var bullet_count: int = 64
	
	func reset():
		alarm = shoot_timer
		base_angle = randf_range(0, 2 * PI)
		angle = base_angle
		distance = base_distance
		hue = base_hue
		bullet_index = 0
	
	func unwind_pattern():
		for bullet in bullet_list:
			if !is_instance_valid(bullet):
				continue
			bullet.acceleration = 50
		bullet_list.clear()

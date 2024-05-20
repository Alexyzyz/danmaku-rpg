extends Node2D

var spiral_attack: SpiralAttack = SpiralAttack.new()
var ring_attack: RingAttack = RingAttack.new()

@onready var _bullet_texture = preload("res://sprites/bullets/spr_bullet_0.png")

func _process(delta):
	_shoot(delta)
	# _shoot_ring(delta)

func _shoot(delta):
	if spiral_attack.alarm > 0:
		spiral_attack.alarm -= delta
		return
	spiral_attack.alarm = 0.0001
	spiral_attack.angle += 1
	
	var bullet: Bullet = BattleBulletManager.shoot_bullet(
		get_parent().position,
		spiral_attack.angle,
		0,
		_bullet_texture)
	bullet.acceleration = 1 # 200

func _shoot_ring(delta):
	if ring_attack.alarm > 0:
		ring_attack.alarm -= delta
		return
	ring_attack.alarm = 0.05
	ring_attack.angle += 1
	
	var bullet_in_ring_count: float = 10
	var step: float = 1 / bullet_in_ring_count
	var ring_radius: float = 20
	
	for i in bullet_in_ring_count:
		var offset_angle = lerpf(0, 2 * PI, i * step)
		var offset = ring_radius * Vector2(cos(offset_angle), sin(offset_angle))
		
		var bullet: Bullet = BattleBulletManager.shoot_bullet(get_parent().position + offset, ring_attack.angle, 100, _bullet_texture)
		bullet.acceleration = 1

# Subclasses

class SpiralAttack:
	var alarm: float
	var angle: float

class RingAttack:
	var alarm: float
	var angle: float

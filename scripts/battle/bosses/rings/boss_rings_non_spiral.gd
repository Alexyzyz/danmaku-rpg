extends Node2D

class SpiralAttack:
	var alarm: float
	var angle: float
var spiral_attack: SpiralAttack = SpiralAttack.new()

class RingAttack:
	var alarm: float
	var angle: float
var ring_attack: RingAttack = RingAttack.new()

func _process(delta):
	_shoot(delta)
	_shoot_ring(delta)

func _shoot(delta):
	if spiral_attack.alarm > 0:
		spiral_attack.alarm -= delta
		return
	spiral_attack.alarm = 0.01
	spiral_attack.angle += 1
	
	BattleManager.shoot_bullet(position, spiral_attack.angle, 50, Color.WHITE, UtilBulletResource.rice)

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
		
		BattleManager.shoot_bullet(position + offset, ring_attack.angle, 100)

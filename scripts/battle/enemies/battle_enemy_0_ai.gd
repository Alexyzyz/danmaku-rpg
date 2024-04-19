extends Node2D

var sprite_bullet_main: Resource = preload("res://sprites/bullets/spr_bullet_1.png")
var sprite_bullet_main_dropshadow: Resource = preload("res://sprites/bullets/spr_bullet_1_dropshadow.png")

class SpiralAttack:
	var alarm: float
	var angle: float
var spiral_attack: SpiralAttack

class RingAttack:
	var alarm: float
	var angle: float
var ring_attack: RingAttack

var debug_play: bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	spiral_attack = SpiralAttack.new()
	ring_attack = RingAttack.new()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !BattleManager.debug_play:
		return
	
	_shoot(delta)
	_shoot_ring(delta)
	pass

func _shoot(delta):
	if spiral_attack.alarm > 0:
		spiral_attack.alarm -= delta
		return
	spiral_attack.alarm = 0.01
	spiral_attack.angle = fmod(spiral_attack.angle + 0.103, 1)
	
	BattleManager.shoot_bullet(
		position, spiral_attack.angle, 50,
		sprite_bullet_main, sprite_bullet_main_dropshadow)

func _shoot_ring(delta):
	if ring_attack.alarm > 0:
		ring_attack.alarm -= delta
		return
	ring_attack.alarm = 0.05
	ring_attack.angle = fmod(ring_attack.angle + 0.103, 1)
	
	var bullet_in_ring_count: float = 10
	var step: float = 1 / bullet_in_ring_count
	var ring_radius: float = 20
	
	for i in bullet_in_ring_count:
		var offset_angle = lerpf(0, 2 * PI, i * step)
		var offset = ring_radius * Vector2(cos(offset_angle), sin(offset_angle))
		
		BattleManager.shoot_bullet(position + offset, ring_attack.angle, 100)

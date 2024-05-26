class_name BossShamanWarpingBulletsAttack
extends Node2D

var _ring_attack: RingAttack = RingAttack.new(get_parent())

@onready var _bullet_texture: Texture2D = preload("res://sprites/bullets/spr_bullet_0.png")

func _process(delta: float):
	# _handle_ring_attack(delta)
	if Input.is_action_pressed("debug_e"):
		_ring_attack.tick(delta)
	pass

# Private functions

func _handle_ring_attack(delta: float):
	if !Input.is_action_pressed("debug_e"):
		return
	_ring_attack.shoot()

# Subclasses

class RingAttack:
	var _parent: Node2D
	
	var _alarm: float
	var _timer: float = 0.01
	var _angle: float
	var _bullets_in_ring: int = 32
	
	func _init(parent: Node2D):
		_parent = parent
	
	func tick(delta: float):
		if _alarm > 0:
			_alarm -= delta
			return
		_alarm = _timer
		shoot()
	
	func shoot():
		BattleBulletManager.shoot_bullet_ring(
			_parent.position,
			UtilMath.get_angle_from_vector(BattleManager.obj_player.position - _parent.position) + _angle,
			300,
			11,
			UtilBulletResource.default)
		_angle += TAU / 127

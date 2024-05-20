class_name BossShamanWarpingBulletsAttack
extends Node2D

var ring_attack_a: RingAttack = RingAttack.new()

@onready var _bullet_texture: Texture2D = preload("res://sprites/bullets/spr_bullet_0.png")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_handle_ring_attack(ring_attack_a, delta)

# Private functions

func _handle_ring_attack(attack: RingAttack, delta: float):
	if !Input.is_action_just_pressed("debug_e"):
		return
	
	# print(position)
	BattleBulletManager.shoot_bullet_ring(get_parent().position, randf_range(0, TAU), 200, _bullet_texture, 32)

# Subclasses

class RingAttack:
	var alarm: float
	var timer: float = 0.1
	var bullets_in_ring: int = 32

class_name BossShamanWarpingBulletsAttack
extends Node2D

class RingAttack:
	var alarm: float
	var timer: float = 0.1
	var bullets_in_ring: int = 32
var ring_attack_a: RingAttack = RingAttack.new()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_handle_ring_attack(ring_attack_a, delta)

# Private functions

func _handle_ring_attack(attack: RingAttack, delta: float):
	if !Input.is_action_just_pressed("debug_e"):
		return
	
	var angle_step: float = TAU / (attack.bullets_in_ring - 1)
	var base_angle: float = randf_range(0, angle_step)
	for i in attack.bullets_in_ring:
		BattleManager.shoot_bullet(position, base_angle + i * angle_step, 50, Color.WHITE, UtilBulletResource.default)
	

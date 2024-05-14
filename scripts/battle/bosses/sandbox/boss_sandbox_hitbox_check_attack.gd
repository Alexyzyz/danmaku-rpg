class_name BossSandboxHitboxCheckAttack
extends Node2D

class LaneAttack:
	var alarm: float
	var timer: float = 0.2
	var bullet_count: int = 16
	var wing_direction: int = 1
var _lane_attack_a: LaneAttack = LaneAttack.new()

# Main methods

func _ready():
	pass # Replace with function body.

func _process(delta):
	_handle_lane_attack(delta)

# Private methods

func _handle_lane_attack(delta: float):
	if _lane_attack_a.alarm > 0:
		_lane_attack_a.alarm -= delta
		return
	_lane_attack_a.alarm = _lane_attack_a.timer
	_lane_attack_a.wing_direction *= -1
	
	var aim_direction: float = UtilMath.get_angle_from_vector(BattleManager.obj_player.position - position)
	var modify_bullet: Callable = func(bullet: BattleBullet, i: int):
		if _lane_attack_a.wing_direction == 1:
			bullet.movement.speed = 80 + i * 10
		else:
			bullet.movement.speed = 80 + _lane_attack_a.bullet_count * 10 - i * 10
	
	BattleManager.shoot_bullet_ring(
		position,
		aim_direction,
		120,
		_lane_attack_a.bullet_count,
		PI / 4,
		modify_bullet,
		UtilBulletResource.default)

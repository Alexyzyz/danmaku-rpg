class_name BossMechanicSideAimAttackMinion
extends Node2D

var movement: MovementData = MovementData.new()
var is_broken: bool = false

@warning_ignore("unused_private_class_variable")
@onready var _bullet_texture = preload("res://sprites/bullets/spr_bullet_0.png")

func _ready():
	pass

func _process(delta):
	_move(delta)

# Public methods

func set_up(pos: Vector2, dir: float, spd: float):
	movement.position = pos
	movement.set_bullet_rotation(dir)
	movement.speed = spd
	
	position = pos

func shoot_at_player():
	var angle: float = UtilMath.get_angle_from_vector(BattleManager.obj_player.position - position)
	BattleBulletManager.shoot_bullet(position, angle, 160, UtilBulletResource.default)

# Private methods

func _move(delta):
	movement.update(delta)
	
	if movement.position.y > BattleManager.battle_area_size.y + 100:
		BossMechanicSideAimAttack.handle_minion_despawn(self)
		return
	
	position = movement.position

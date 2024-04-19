class_name BattleBullet
extends Node2D

var movement: UtilMovement.MovementData = UtilMovement.MovementData.new()
var sprite_has_direction: bool = false

var collision_grid_prev: BattleBullet
var collision_grid_next: BattleBullet
var last_collision_cell: Vector2i

var has_been_grazed: bool = false
var graze_modulate_t: float

var debug_play: bool = true

@onready var obj_sprite: Sprite2D = $Sprite
@onready var obj_sprite_dropshadow: Sprite2D = $DropShadow

func _process(delta):
	if !BattleManager.debug_play:
		return
	
	_move(delta)
	_handle_graze_animation()

# Public methods

func destroy():
	BattleManager.handle_destroyed_bullet(self)

func graze():
	graze_modulate_t = 1

func set_up(
	position: Vector2, direction: float, speed: float,
	bullet_resource: UtilBulletResource.BulletResource = UtilBulletResource.default,
	has_direction: bool = true):
	
	movement.position = position
	movement.direction = direction
	movement.speed = speed
	self.position = position
	_set_up_sprites(bullet_resource.sprite, bullet_resource.dropshadow_sprite, has_direction)

# Private methods

func _move(delta: float):
	movement = UtilMovement.get_new_pos(movement, delta)
	rotation = movement.direction + PI / 2
	
	BattleManager.update_collision_grid(self, movement.position)

func _handle_graze_animation():
	obj_sprite.modulate = Color(1, 1, 1) - graze_modulate_t * 0.1 * Color(1, 1, 1)
	if graze_modulate_t < 0.01:
		graze_modulate_t = 0
		return
	graze_modulate_t = lerpf(graze_modulate_t, 0, 0.2)

func _set_up_sprites(
	sprite: Resource,
	sprite_dropshadow: Resource,
	has_direction: bool = true):
	
	obj_sprite.texture = sprite
	obj_sprite_dropshadow.texture = sprite_dropshadow
	sprite_has_direction = has_direction

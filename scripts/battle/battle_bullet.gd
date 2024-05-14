class_name BattleBullet
extends Node2D

var color: Color
var movement: MovementData = MovementData.new()
var sprite_has_direction: bool = false

var has_been_grazed: bool = false
var graze_modulate_t: float

var sp_manager: SpatialPartitioningManager
var sp_cell_prev: BattleBullet
var sp_cell_next: BattleBullet
var sp_last_cell: Vector2i

var debug_play: bool = true
var debug_cell: Vector2i

@onready var obj_sprite: Sprite2D = $Sprite
@onready var obj_sprite_dropshadow: Sprite2D = $DropShadow

# Main methods

func _process(delta):
	if !BattleManager._debug_play:
		return
	
	_move(delta)
	_handle_graze_animation()

# Public methods

func set_up(
	# Mandatory
	position: Vector2,
	direction: float,
	speed: float,
	
	# Optional
	color: Color = Color.WHITE,
	bullet_resource: UtilBulletResource.BulletResource = UtilBulletResource.default,
	has_direction: bool = true):
	
	movement.position = position
	movement.set_bullet_rotation(direction)
	movement.speed = speed
	self.position = position
	
	_set_up_sprites(bullet_resource.sprite, bullet_resource.dropshadow_sprite, color, has_direction)

func disable():
	set_process(false)
	obj_sprite.visible = false
	obj_sprite_dropshadow.visible = false
	movement.reset()

func enable():
	set_process(true)
	obj_sprite.visible = true
	obj_sprite_dropshadow.visible = true

func graze():
	graze_modulate_t = 1

func destroy():
	sp_manager.handle_destroyed_obj(self)

# Private methods

func _move(delta: float):
	movement.update(delta)
	# _move_wrap_around_screen()
	
	if sp_manager != null:
		sp_manager.update_sp_grid(self, movement.position)
		debug_cell = sp_manager.get_cell(position)
	
	position = movement.position
	rotation = movement.direction_angle + PI / 2

func _move_wrap_around_screen():
	if movement.position.x < BattleManager.battle_area_west_x:
		movement.position.x = BattleManager.battle_area_east_x - 8
	elif movement.position.x > BattleManager.battle_area_east_x:
		movement.position.x = BattleManager.battle_area_west_x + 8
	
	if movement.position.y > BattleManager.battle_area_south_y:
		movement.position.y = BattleManager.battle_area_north_y + 8
	elif movement.position.y < BattleManager.battle_area_north_y:
		movement.position.y = BattleManager.battle_area_south_y - 8

func _handle_graze_animation():
	obj_sprite.modulate = Color(1, 1, 1) - graze_modulate_t * 0.1 * Color(1, 1, 1)
	if graze_modulate_t < 0.01:
		graze_modulate_t = 0
		return
	graze_modulate_t = lerpf(graze_modulate_t, 0, 0.2)

func _set_up_sprites(
	sprite: Resource,
	sprite_dropshadow: Resource,
	color: Color,
	has_direction: bool = true):
	
	obj_sprite.texture = sprite
	obj_sprite.self_modulate = color
	obj_sprite_dropshadow.texture = sprite_dropshadow
	sprite_has_direction = has_direction
	
	self.color = color

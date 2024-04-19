class_name BattleBullet
extends Node2D

var SPRITE_ANGLE_OFFSET_TO_JUSTIFY_DRAWING_THEM_POINTING_NORTH = PI / 2

var sprite_has_direction: bool = false

@onready var movement_2d_component: Movement2DComponent = $Movement2DComponent
var direction: Vector2
var direction_angle: float
var speed: float

var collision_grid_prev: BattleBullet
var collision_grid_next: BattleBullet
var last_collision_cell: Vector2i

var has_been_grazed: bool = false
var graze_modulate_t: float

var debug_play: bool = true

@onready var obj_sprite: Sprite2D = $Sprite
@onready var obj_sprite_dropshadow: Sprite2D = $DropShadow

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
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

func set_up_with_angle_dir(
	pos: Vector2, dir: float, spd: float,
	sprite: Resource, sprite_dropshadow: Resource,
	has_direction: bool = true):
	
	position = pos
	direction = Vector2(cos(dir), sin(dir))
	direction_angle = dir
	speed = spd
	
	_set_up_sprites(sprite, sprite_dropshadow, has_direction)

func set_up_with_vector_dir(
	pos: Vector2, dir: Vector2, spd: float,
	sprite: Resource, sprite_dropshadow: Resource,
	has_direction: bool = true):
	
	var normalized_dir = dir.normalized()
	
	position = pos
	direction = dir
	direction_angle = atan2(normalized_dir.y, normalized_dir.x)
	speed = spd
	
	_set_up_sprites(sprite, sprite_dropshadow, has_direction)

# Private methods

func _move(delta):
	if speed == 0:
		return
	
	var new_position: Vector2 = position + direction * speed * delta
	BattleManager.update_collision_grid(self, new_position)
	
	if !sprite_has_direction:
		return
	rotation = direction_angle + SPRITE_ANGLE_OFFSET_TO_JUSTIFY_DRAWING_THEM_POINTING_NORTH

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

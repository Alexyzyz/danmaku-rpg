class_name BattlePlayerShot
extends Node2D

var movement: MovementData = MovementData.new()

var sp_manager: SpatialPartitioningManager
var sp_cell_prev: BattlePlayerShot
var sp_cell_next: BattlePlayerShot
var sp_last_cell: Vector2i

var damage: float

@onready var _child_sprite: Sprite2D = $Sprite
@onready var _child_sprite_dropshadow: Sprite2D = $DropShadow

# Main methods

func _process(p_delta: float):
	_move(p_delta)

# Public methods

func set_up(p_position: Vector2, p_angle: float, p_shot_damage):
	movement.position = p_position
	movement.direction_angle = p_angle
	movement.speed = 700
	position = p_position
	damage = p_shot_damage

func disable():
	set_process(false)
	visible = false
	movement.reset()

func enable():
	set_process(true)
	visible = true

func destroy():
	sp_manager.handle_destroyed_obj(self)

# Private methods

func _move(delta: float):
	movement.update(delta)
	
	if sp_manager != null:
		sp_manager.update_sp_grid(self, movement.position)
	
	position = movement.position
	rotation = movement.direction_angle + PI / 2

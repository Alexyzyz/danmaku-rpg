class_name BattlePlayerShot
extends Node2D

var movement: MovementData = MovementData.new()

var sp_manager: SpatialPartitioningManager
var sp_cell_prev: BattlePlayerShot
var sp_cell_next: BattlePlayerShot
var sp_last_cell: Vector2i

@onready var child_sprite: Sprite2D = $Sprite

# Main methods

func _process(delta):
	_move(delta)

# Public methods

func set_up(position: Vector2):
	movement.position = position
	movement.direction_angle = -PI / 2
	movement.speed = 700
	self.position = position

func disable():
	set_process(false)
	child_sprite.visible = false
	movement.reset()

func enable():
	set_process(true)
	child_sprite.visible = true

func destroy():
	sp_manager.handle_destroyed_obj(self)

# Private methods

func _move(delta: float):
	movement.update(delta)
	
	if sp_manager != null:
		sp_manager.update_sp_grid(self, movement.position)
	
	position = movement.position
	rotation = movement.direction_angle + PI / 2

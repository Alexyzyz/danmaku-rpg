class_name Movement2DComponent
extends Node2D

var _SPRITE_ANGLE_OFFSET_TO_JUSTIFY_DRAWING_THEM_POINTING_NORTH = PI / 2

var owner_object: Node2D
var on_move: Callable

var direction: Vector2
var direction_angle: float
var speed: float

var object_has_direction: bool
var object_is_in_collision_grid: bool

func _ready():
	owner_object = get_parent()

func _process(delta):
	_move

# Public methods

func set_movement_with_angle(direction: float, speed: float):
	self.direction = Vector2(cos(direction), sin(direction))
	direction_angle = direction
	self.speed = speed

func set_movement_with_vector(direction: Vector2, speedd: float):
	var normalized_dir = direction.normalized()
	
	self.direction = normalized_dir
	direction_angle = atan2(normalized_dir.y, normalized_dir.x)
	self.speed = speed

# Private methods

func _move(delta):
	if speed == 0:
		return
	var new_position: Vector2 = owner_object.position + direction * speed * delta
	
	if object_has_direction:
		rotation = direction_angle + _SPRITE_ANGLE_OFFSET_TO_JUSTIFY_DRAWING_THEM_POINTING_NORTH
	
	if on_move != null:
		on_move.call()
	
	# BattleManager.update_collision_grid(owner_object, new_position)


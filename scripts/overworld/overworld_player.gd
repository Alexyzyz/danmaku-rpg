class_name OverworldPlayer
extends Node3D

const MOVEMENT_SPEED: float = 2

@onready var _child_sprite: AnimatedSprite3D = $Sprite

# Main methods

func _ready():
	pass # Replace with function body.

func _process(delta: float):
	_handle_movement_inputs(delta)

# Public methods

# Private methods

func _handle_movement_inputs(delta: float):
	var planar_direction: Vector2 = UtilMovement.get_direction_vector()
	var direction: Vector3 = Vector3(planar_direction.x, 0, planar_direction. y)
	
	position += MOVEMENT_SPEED * direction * delta
	
	if direction.length() == 0:
		_child_sprite.stop()
	else:
		_child_sprite.play()
		_child_sprite.flip_h = direction.x < 0
	

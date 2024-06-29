class_name OverworldPlayer
extends Node3D

const MOVEMENT_SPEED: float = 10
const STEP_TIME: float = 0.2

var _step_alarm: float
var _child_sprite: AnimatedSprite3D

# Main methods

func _ready():
	_set_up()


func _process(delta: float):
	_handle_movement_inputs(delta)


# Public methods


# Private methods

func _set_up():
	_child_sprite = $Sprite


func _handle_movement_inputs(p_delta: float):
	var planar_direction: Vector2 = UtilMovement.get_direction_vector()
	var direction: Vector3 = Vector3(planar_direction.x, 0, planar_direction. y)
	
	position += p_delta * MOVEMENT_SPEED * direction
	
	if direction.length() == 0:
		_child_sprite.stop()
		return
	
	_child_sprite.play()
	_child_sprite.flip_h = direction.x < 0
	
	if _step_alarm > 0:
		_step_alarm -= p_delta
		return
	_step_alarm = STEP_TIME
	OverworldManager.increase_step_count()


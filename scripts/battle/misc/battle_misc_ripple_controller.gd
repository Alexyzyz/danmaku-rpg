@tool
class_name BattleMiscRipple
extends ColorRect

const TICKS_UNTIL_DEATH: float = 2

var _shader_tick: float

var _debug_alarm: float

func _ready():
	pass # Replace with function body.

func _process(p_delta: float):
	_handle_shader(p_delta)

# Private methods

func set_up(p_position: Vector2):
	global_position = p_position - size / 2
	_shader_tick = 0

func _handle_shader(p_delta: float):
	var shader_material: ShaderMaterial = material as ShaderMaterial
	shader_material.set_shader_parameter("tick", _shader_tick)
	
	_shader_tick += p_delta
	if _shader_tick > TICKS_UNTIL_DEATH:
		if Engine.is_editor_hint():
			_shader_tick = 0
		else:
			queue_free()
		pass
	pass

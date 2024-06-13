class_name BattleSkillCameraPhoto
extends Node2D

var _texture: ImageTexture
var _child_sprite: Sprite2D
var _index: int
var _start_pos: Vector2
var _target_pos: Vector2
var _fly_t: float

# Main methods

func _process(p_delta: float):
	_fly_to_pin(p_delta)
	pass


# Public methods

func set_up(
		p_texture: ImageTexture,
		p_position: Vector2,
		p_angle: float,
		p_index: int):
	
	_child_sprite = $Sprite
	
	_texture = p_texture
	_index = p_index
	
	_child_sprite.texture = p_texture
	
	_target_pos = BattleManager._parent_skill_camera_photos.position
	_target_pos += _index * Vector2(0, 100)
	
	_start_pos = BattleManager.get_battle_arena_parent().to_local(p_position)
	position = _start_pos
	
	rotation = p_angle
	pass


# Private methods

func _fly_to_pin(p_delta: float):
	_fly_t = UtilMath.exp_decay(_fly_t, 1, 10, p_delta)
	position = lerp(_start_pos, _target_pos, _fly_t)


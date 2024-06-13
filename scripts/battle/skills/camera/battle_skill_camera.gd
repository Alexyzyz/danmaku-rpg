class_name BattleSkillCamera
extends Node2D

const ZOOM_DURATION_MAX: float = 1
const ZOOM_DELTA_SCALE: float = 0.5

const VIEWFINDER_IDLE_DISTANCE: float = 100
const VIEWFINDER_SPEED: float = 500
const VIEWFINDER_SCALE_MAX: float = 1
const VIEWFINDER_SCALE_MIN: float = 0.5

var _player: BattlePlayer
var _viewfinder: BattleSkillCameraViewfinder
var _is_aiming: bool
var _zoom_duration: float
var _photo_index: int
# Viewfinder
var _viewfinder_scale: float
# Prefabs
var _prefab_viewfinder: PackedScene
var _prefab_photo: PackedScene

# Main methods

func set_up():
	_prefab_viewfinder = preload("res://prefabs/battle/skills/camera/prefab_battle_skill_camera_viewfinder.tscn")
	_prefab_photo = preload("res://prefabs/battle/skills/camera/prefab_battle_skill_camera_photo.tscn")
	
	_player = BattleManager.get_player()
	_viewfinder = _prefab_viewfinder.instantiate()
	_player.add_child(_viewfinder)


func update(_p_delta: float):
	var unscaled_delta: float = BattleManager.get_unscaled_delta()
	_handle_skill_input(unscaled_delta)
	_handle_aiming_inputs(unscaled_delta)
	_handle_idle_viewfinder(unscaled_delta)
	pass


# Private methods

func _handle_skill_input(p_delta: float):
	if Input.is_action_just_released("battle_skill"):
		if _is_aiming:
			_shoot(p_delta)
			return
	
	if Input.is_action_just_pressed("battle_skill"):
		if not _is_aiming:
			BattleManager.set_camera_delta_scale(0.3)
			_player.toggle_can_move(false)
			_is_aiming = true


func _handle_aiming_inputs(p_delta: float):
	if not _is_aiming:
		return
	
	var east: int = 1 if Input.is_action_pressed("game_move_right") else 0
	var west: int = 1 if Input.is_action_pressed("game_move_left") else 0
	var north: int = 1 if Input.is_action_pressed("game_move_up") else 0
	var south: int = 1 if Input.is_action_pressed("game_move_down") else 0
	var direction := Vector2(east - west, south - north).normalized()
	
	_viewfinder.position += p_delta * VIEWFINDER_SPEED * direction
	_viewfinder.look_at(_player.global_position)
	
	_zoom_duration += p_delta
	if _zoom_duration > ZOOM_DURATION_MAX:
		_shoot(p_delta)
		return
	
	var t: float = _zoom_duration / ZOOM_DURATION_MAX
	_viewfinder.scale = Vector2.ONE * lerp(VIEWFINDER_SCALE_MAX, VIEWFINDER_SCALE_MIN, t)
	pass


func _handle_idle_viewfinder(p_delta):
	if _is_aiming:
		return
	_viewfinder.position = VIEWFINDER_IDLE_DISTANCE * UtilMath.get_vector_from_angle(-PI / 2)
	pass


func _shoot(p_delta: float):
	BattleManager.set_camera_delta_scale(1)
	_player.toggle_can_move(true)
	_is_aiming = false
	_zoom_duration = 0
	
	_viewfinder.clear_bullets()
	_viewfinder.rotation = 0
	_viewfinder.scale = Vector2.ONE * VIEWFINDER_SCALE_MAX
	
	_generate_photo()
	pass


func _generate_photo():
	var texture := ImageTexture.new()
	texture = texture.create_from_image(_viewfinder.get_photo_image())
	
	var photo: BattleSkillCameraPhoto = _prefab_photo.instantiate()
	BattleManager.get_battle_arena_parent().add_child(photo)
	photo.set_up(texture, _viewfinder.global_position, _viewfinder.rotation, _photo_index)
	_photo_index += 1
	pass


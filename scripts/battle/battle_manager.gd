class_name BattleManager
extends Node

const VIEWPORT_VERTICAL_PADDING: float = 20
const BATTLE_AREA_ASPECT_RATIO: float = 0.75
const HIT_FREEZE_TIME: float = 1
const HIT_FREEZE_REBOUND_T: float = 0.5

# Important positions
static var origin_from_center: Vector2
static var origin_from_top_left: Vector2
# Battle area dimensions
static var battle_area_size: Vector2
static var battle_area_west_x: float
static var battle_area_east_x: float
static var battle_area_north_y: float
static var battle_area_south_y: float

static var _enemy_list: Array[Node2D]
static var _minor_enemy_list: Array[Node2D]
static var _hit_freeze_alarm: float
# Delta time
static var _unscaled_delta: float
static var _delta_scale: float = 1
static var _delta_scale_camera: float = 1
# Prefabs
static var _prefab_enemy: PackedScene
static var _prefab_ripple: PackedScene
static var _prefab_enemy_ripple: PackedScene
static var _prefab_scene_overworld: PackedScene
# Parents
static var _parent_level: Node
static var _parent_battle: Node
static var _parent_battle_top_left: Node2D
static var _parent_skill_camera_photos: Node2D
static var _parent_enemy: Node2D
static var _parent_enemy_bullets: Node2D
static var _parent_player_shots: Node2D
static var _parent_background_shader: Control
static var _parent_debug: Node2D
# Important objects
static var _scene_tree: SceneTree
static var _obj_player: BattlePlayer
static var _obj_background_scene: Node3D
static var _obj_skill_camera_background_dark: ColorRect
# Resources
static var _sprite_bullet_default: CompressedTexture2D
static var _sprite_bullet_default_dropshadow: CompressedTexture2D

static var _debug_play: bool = true

# Main methods

func _ready():
	_set_up_resources()
	_set_up_objects()
	_set_up_battle_area()
	BattleBulletManager.set_up()
	_set_up_battle()
	
	_obj_player.set_up(UtilShotType.DETONATOR, UtilSkill.CAMERA)


func _process(p_delta: float):
	_unscaled_delta = p_delta
	
	var scaled_delta: float = p_delta * _delta_scale * _delta_scale_camera
	
	_obj_player.update(scaled_delta)
	_update_enemies(scaled_delta)
	_update_background_scene(scaled_delta)
	BattleBulletManager.update(scaled_delta)
	
	_handle_hit_freeze(p_delta)
	_debug()


# Public functions

static func get_unscaled_delta() -> float:
	return _unscaled_delta


static func set_camera_delta_scale(p_scale: float):
	_delta_scale_camera = p_scale


static func get_player() -> BattlePlayer:
	return _obj_player


static func get_battle_parent() -> Node2D:
	return _parent_battle


static func get_battle_arena_parent() -> Node2D:
	return _parent_battle_top_left


static func get_enemies() -> Array[BattleEnemy]:
	var list: Array[BattleEnemy] = []
	list.append_array(_enemy_list)
	list.append_array(_minor_enemy_list)
	return list


static func is_oob(p_position: Vector2) -> bool:
	return UtilMath.vec2_is_inside(p_position, Vector2.ZERO, battle_area_size)


static func add_minor_enemy(p_minor_enemy: Node2D):
	_parent_enemy.add_child(p_minor_enemy)
	_minor_enemy_list.push_back(p_minor_enemy)


static func handle_player_hit():
	spawn_ripple(_obj_player.global_position)
	_delta_scale = 0
	_hit_freeze_alarm = HIT_FREEZE_TIME
	pass


static func handle_enemy_defeat(p_enemy: BattleEnemy):
	spawn_ripple(p_enemy.position)
	_enemy_list.erase(p_enemy)
	p_enemy.queue_free()
	
	var enemy_count = _enemy_list.size()
	if enemy_count == 0:
		_handle_end_battle()
		return
	
	BattleUIEnemyRemaining.show_enemy_remaining(enemy_count)


static func handle_minor_enemy_defeat(p_minor_enemy: Node2D):
	spawn_ripple(p_minor_enemy.position)
	_minor_enemy_list.erase(p_minor_enemy)
	p_minor_enemy.queue_free()


static func spawn_ripple(p_pos: Vector2):
	var ripple: BattleMiscRipple = _prefab_ripple.instantiate()
	_parent_level.get_node("DebugA").add_child(ripple)
	ripple.set_up(p_pos)


static func skill_camera_toggle_background(p_state: bool):
	_obj_skill_camera_background_dark.visible = p_state


# Private functions

func _set_up_resources():
	_prefab_enemy = preload("res://prefabs/prefab_enemy.tscn")
	_prefab_ripple = preload("res://prefabs/battle/misc/prefab_battle_misc_ripple.tscn")
	_prefab_enemy_ripple = preload("res://prefabs/battle/misc/prefab_battle_misc_enemy_ripple.tscn")
	_prefab_scene_overworld = preload("res://scenes/scene_overworld.tscn")
	
	_sprite_bullet_default = preload("res://sprites/bullets/spr_bullet_0.png")
	_sprite_bullet_default_dropshadow = preload("res://sprites/bullets/spr_bullet_0_dropshadow.png")


func _set_up_objects():
	_scene_tree = get_tree()
	_obj_player = $"../Level/Node2D/TopLeft/Player"
	_obj_skill_camera_background_dark = $"../Level/SkillCameraBackground"
	_obj_background_scene = $"../Level/Background/SubViewportContainer/SubViewport/BackgroundScene"
	
	_parent_level = $"../Level"
	_parent_battle = $"../Level/Node2D"
	_parent_battle_top_left = $"../Level/Node2D/TopLeft"
	_parent_skill_camera_photos = $"../Level/Node2D/TopLeft/SkillCameraPhotoParent"
	_parent_enemy = $"../Level/Node2D/TopLeft/EnemyParent"
	_parent_enemy_bullets = $"../Level/Node2D/TopLeft/EnemyBulletParent"
	_parent_player_shots = $"../Level/Node2D/TopLeft/PlayerShotParent"
	_parent_background_shader = $"../Level/BackgroundShader"
	_parent_debug = $"../Level/Node2D/TopLeft/DebugParent"


func _set_up_battle():
	# Position the player
	_obj_player.position = Vector2(battle_area_size.x / 2, battle_area_south_y - 100)
	
	var behavior_list: Array[Script] = [
		# BattleEnemyElitePriest,
		# BattleEnemyNatureTriangleAimer,
		# BattleEnemyDandelion,
		# BattleBossMiscMajorSwarms,
		# BattleBossMiscMajorSphere,
		# BattleBossMiscScatter,
	]
	var fixed_behavior_list: Array[Script] = [
		# BattleEnemyTimekeeperFast,
		# BattleBossMiscScatter,
		# BattleBossRivalSpin,
		BattleEnemyNatureTriangleAimer,
		# BattleEnemyDandelion,
		# BattleEnemyDenseRing,
		# BattleEnemyWindSuck,
		BattleEnemyConstrictor,
	]
	var spawn_region_start: Vector2 = Vector2(0, 0)
	var spawn_region_end: Vector2 = Vector2(battle_area_size.x, battle_area_size.y)
	
	while fixed_behavior_list.size() > 0:
		var enemy: BattleEnemy = _prefab_enemy.instantiate()
		var behavior: Script = fixed_behavior_list.pop_back()
		# var behavior: Script = behavior_list.pick_random()
		var spawn_pos: Vector2 = Vector2(
			randf_range(spawn_region_start.x, spawn_region_end.x),
			randf_range(spawn_region_start.y, spawn_region_end.y / 2))
		# spawn_pos = Vector2(battle_area_size.x / 2, battle_area_size.y / 2)
		
		var enemy_ripple_shader: ColorRect # = _prefab_enemy_ripple.instantiate()
		# _parent_background_shader.add_child(enemy_ripple_shader)
		enemy.set_up(spawn_pos, enemy_ripple_shader, behavior.MAX_HEALTH, BattleEnemy.HealthDisplay.CIRCLE)
		enemy.set_behavior(behavior)
		
		_parent_enemy.add_child(enemy)
		_enemy_list.append(enemy)


func _set_up_battle_area():
	var viewport_rect_size: Vector2 = get_viewport().get_visible_rect().size
	var battle_area_height = viewport_rect_size.y - VIEWPORT_VERTICAL_PADDING * 2
	var battle_area_width = battle_area_height * BATTLE_AREA_ASPECT_RATIO
	
	battle_area_size = Vector2(battle_area_width, battle_area_height)
	origin_from_center = viewport_rect_size / 2
	origin_from_top_left = origin_from_center - battle_area_size / 2
	
	# Every object in the battle area will now be shifted here
	_parent_battle_top_left.position = origin_from_top_left
	
	battle_area_west_x = 0
	battle_area_east_x = battle_area_width
	battle_area_north_y = 0
	battle_area_south_y = battle_area_height


func _handle_hit_freeze(p_delta: float):
	if _hit_freeze_alarm <= 0:
		_hit_freeze_alarm = 0
		_delta_scale = 1
		return
	_hit_freeze_alarm -= p_delta
	
	var t: float = _hit_freeze_alarm / HIT_FREEZE_TIME
	
	if UtilMath.is_between(t, HIT_FREEZE_REBOUND_T, 1.0):
		return
	
	var tt: float = (HIT_FREEZE_REBOUND_T - t) / HIT_FREEZE_REBOUND_T
	_delta_scale = lerp(0, 1, tt)
	pass


func _update_enemies(p_delta: float):
	for enemy in _enemy_list:
		enemy.update(p_delta)
	for minor_enemy in _minor_enemy_list:
		minor_enemy.update(p_delta)


func _update_background_scene(p_delta: float):
	if _obj_background_scene.has_method("update"):
		_obj_background_scene.update(p_delta)


func _handle_delta_scaling(p_delta: float):
	pass


static func _handle_end_battle():
	await _scene_tree.create_timer(2.0).timeout
	_scene_tree.change_scene_to_packed(_prefab_scene_overworld)


# Debug methods

func _debug():
	if not Input.is_action_pressed("game_debug"):
		return
	
	if Input.is_key_pressed(KEY_Q):
		_obj_player.position = origin_from_top_left
		return
	
	if Input.is_key_pressed(KEY_W):
		_obj_player.position = origin_from_center
		return
	
	if Input.is_action_just_pressed("debug_e"):
		_debug_play = !_debug_play
		return
	
	if Input.is_action_just_pressed("debug_quit"):
		get_tree().quit()

class_name BattleManager
extends Node

const VIEWPORT_VERTICAL_PADDING: float = 20
const BATTLE_AREA_ASPECT_RATIO: float = 0.75
const HIT_FREEZE_TIME: float = 1
const HIT_FREEZE_REBOUND_T: float = 0.5

# Spatial partitioning
# NOTE: We may eventually do away with the spatial partitioning class
# or at least refactor it to be more general and work with non-node objects
static var sp_player_shots: SpatialPartitioningManager

# Important positions
static var origin_from_center: Vector2
static var origin_from_top_left: Vector2
# Battle area dimensions
static var battle_area_size: Vector2
static var battle_area_west_x: float
static var battle_area_east_x: float
static var battle_area_north_y: float
static var battle_area_south_y: float
# Delta time
static var delta_scale: float = 1

static var _enemy_list: Array[Node2D]
static var _minor_enemy_list: Array[Node2D]
static var _hit_freeze_alarm: float
# Prefabs
static var _prefab_enemy: PackedScene
static var _prefab_enemy_bullet: PackedScene
static var _prefab_player_shot: PackedScene
static var _prefab_ripple: PackedScene
static var _prefab_enemy_ripple: PackedScene
# Parents
static var _parent_level: Node
static var _parent_top_left: Node2D
static var _parent_enemy: Node2D
static var _parent_enemy_bullets: Node2D
static var _parent_player_shots: Node2D
static var _parent_background_shader: Control
static var _parent_debug: Node2D
# Important objects
static var _obj_player: BattlePlayer
static var _obj_background_scene: Node3D
# Resources
static var _sprite_bullet_default = preload("res://sprites/bullets/spr_bullet_0.png")
static var _sprite_bullet_default_dropshadow = preload("res://sprites/bullets/spr_bullet_0_dropshadow.png")

static var _debug_play: bool = true

# Main methods

func _ready():
	_set_up_prefabs()
	_set_up_objects()
	_set_up_battle_area()
	BattleBulletManager.set_up()
	_set_up_spatial_partitions()
	_set_up_battle()


func _process(p_delta: float):
	var scaled_delta: float = p_delta * delta_scale
	
	_obj_player.update(scaled_delta)
	_update_enemies(scaled_delta)
	_update_background_scene(scaled_delta)
	BattleBulletManager.update(scaled_delta)
	
	_handle_hit_freeze(p_delta)
	_debug()


# Public functions

static func get_player() -> BattlePlayer:
	return _obj_player


static func add_minor_enemy(p_minor_enemy: Node2D):
	_parent_enemy.add_child(p_minor_enemy)
	_minor_enemy_list.push_back(p_minor_enemy)


static func player_shoot_shot(p_aim_angle: float, p_shot_damage: float):
	var new_shot: BattlePlayerShot = sp_player_shots.spawn_obj(_obj_player.position)
	if new_shot == null:
		return
	new_shot.set_up(_obj_player.position, p_aim_angle, p_shot_damage)


static func handle_player_hit():
	_spawn_ripple(_obj_player.position)
	delta_scale = 0
	_hit_freeze_alarm = HIT_FREEZE_TIME
	pass


static func handle_enemy_defeat(p_enemy: BattleEnemy):
	_spawn_ripple(p_enemy.position)
	_enemy_list.erase(p_enemy)
	p_enemy.queue_free()
	
	var enemy_count = _enemy_list.size()
	if enemy_count == 0:
		return
	
	BattleUIEnemyRemaining.show_enemy_remaining(enemy_count)


static func handle_minor_enemy_defeat(p_minor_enemy: Node2D):
	_spawn_ripple(p_minor_enemy.position)
	_minor_enemy_list.erase(p_minor_enemy)
	p_minor_enemy.queue_free()


# Private functions

func _set_up_prefabs():
	_prefab_enemy = preload("res://prefabs/prefab_enemy.tscn")
	_prefab_enemy_bullet = preload("res://prefabs/prefab_bullet.tscn")
	_prefab_player_shot = preload("res://prefabs/prefab_player_priest_shot.tscn")
	_prefab_ripple = preload("res://prefabs/battle/misc/prefab_battle_misc_ripple.tscn")
	_prefab_enemy_ripple = preload("res://prefabs/battle/misc/prefab_battle_misc_enemy_ripple.tscn")


func _set_up_objects():
	_obj_player = $"../Level/Node2D/TopLeft/Player"
	_obj_background_scene = $"../Level/Background/SubViewportContainer/SubViewport/BackgroundScene"
	
	_parent_level = $"../Level"
	_parent_top_left = $"../Level/Node2D/TopLeft"
	_parent_enemy = $"../Level/Node2D/TopLeft/EnemyParent"
	_parent_enemy_bullets = $"../Level/Node2D/TopLeft/EnemyBulletParent"
	_parent_player_shots = $"../Level/Node2D/TopLeft/PlayerShotParent"
	_parent_background_shader = $"../Level/BackgroundShader"
	_parent_debug = $"../Level/Node2D/TopLeft/DebugParent"


func _set_up_spatial_partitions():
	sp_player_shots = SpatialPartitioningManager.new(
		_prefab_player_shot,
		_parent_player_shots,
		100
	)


func _set_up_battle():
	# Position the player
	_obj_player.position = Vector2(battle_area_size.x / 2, battle_area_south_y - 100)
	
	var behavior_list: Array[Script] = [
		# BattleEnemyElitePriest,
		# BattleEnemyNatureTriangleAimer,
		BattleEnemyDandelion,
		# BattleBossMiscMajorSwarms,
		# BattleBossMiscMajorSphere,
		# BattleBossMiscScatter,
	]
	var fixed_behavior_list: Array[Script] = [
		BattleEnemyTimekeeperFast,
		# BattleBossMiscScatter,
		# BattleEnemyNatureTriangleAimer,
		# BattleEnemyDandelion,
		BattleEnemyDenseRing,
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
	_parent_top_left.position = origin_from_top_left
	
	battle_area_west_x = 0
	battle_area_east_x = battle_area_width
	battle_area_north_y = 0
	battle_area_south_y = battle_area_height


func _handle_hit_freeze(p_delta: float):
	if _hit_freeze_alarm <= 0:
		_hit_freeze_alarm = 0
		delta_scale = 1
		return
	_hit_freeze_alarm -= p_delta
	
	var t: float = _hit_freeze_alarm / HIT_FREEZE_TIME
	
	if UtilMath.is_between(t, HIT_FREEZE_REBOUND_T, 1.0):
		return
	
	var tt: float = (HIT_FREEZE_REBOUND_T - t) / HIT_FREEZE_REBOUND_T
	delta_scale = lerp(0, 1, tt)
	pass


func _update_enemies(p_delta: float):
	for enemy in _enemy_list:
		enemy.update(p_delta)
	for minor_enemy in _minor_enemy_list:
		minor_enemy.update(p_delta)


func _update_background_scene(p_delta: float):
	if _obj_background_scene.has_method("update"):
		_obj_background_scene.update(p_delta)


static func _spawn_ripple(p_pos: Vector2):
	var ripple: BattleMiscRipple = _prefab_ripple.instantiate()
	_parent_top_left.add_child(ripple)
	ripple.set_up(p_pos)


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

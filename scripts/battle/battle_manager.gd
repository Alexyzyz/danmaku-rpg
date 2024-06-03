class_name BattleManager
extends Node

const VIEWPORT_VERTICAL_PADDING: float = 20
const BATTLE_AREA_ASPECT_RATIO: float = 0.75

# Spatial partitioning
# NOTE: We may eventually do away with the spatial partitioning class
# or at least refactor it to be more general and work with non-node objects
static var sp_player_shots: SpatialPartitioningManager
# Important objects
static var parent: Node2D
static var obj_player: BattlePlayer
# Important positions
static var origin_from_center: Vector2
static var origin_from_top_left: Vector2
# Battle area dimensions
static var battle_area_size: Vector2
static var battle_area_west_x: float
static var battle_area_east_x: float
static var battle_area_north_y: float
static var battle_area_south_y: float

# Prefabs
static var _prefab_enemy_bullet: PackedScene
static var _prefab_player_shot: PackedScene
static var _prefab_ripple: PackedScene
# Parents
static var _parent_level: Node
static var _parent_top_left: Node2D
static var _parent_enemy_bullets: Node2D
static var _parent_player_shots: Node2D
# Other
static var _enemy_list: Array[Node2D]
# Resources
static var _sprite_bullet_default = preload("res://sprites/bullets/spr_bullet_0.png")
static var _sprite_bullet_default_dropshadow = preload("res://sprites/bullets/spr_bullet_0_dropshadow.png")

static var _debug_play: bool = true

# Prefabs
@onready var _prefab_enemy: PackedScene = preload("res://prefabs/prefab_enemy.tscn")
# Parents
@onready var _parent_enemy: Node2D = $"../Level/Node2D/TopLeft/EnemyParent"
@onready var _parent_debug: Node2D = $"../Level/Node2D/TopLeft/DebugParent"
# Other
@onready var _obj_top_left: Node2D = $"../Level/Node2D/TopLeft"

# Called when the node enters the scene tree for the first time.
func _ready():
	# Set prefabs
	_prefab_enemy_bullet = preload("res://prefabs/prefab_bullet.tscn")
	_prefab_player_shot = preload("res://prefabs/prefab_player_priest_shot.tscn")
	_prefab_ripple = preload("res://prefabs/battle/misc/prefab_battle_misc_ripple.tscn")
	
	# Set children
	parent = $"../Level/Node2D/TopLeft"
	obj_player = $"../Level/Node2D/TopLeft/Player"
	
	_parent_level = $"../Level"
	_parent_top_left = $"../Level/Node2D/TopLeft"
	_parent_enemy_bullets = $"../Level/Node2D/TopLeft/EnemyBulletParent"
	_parent_player_shots = $"../Level/Node2D/TopLeft/PlayerShotParent"
	
	# Set up stuff
	_set_up_battle_area()
	BattleBulletManager.set_up()
	
	# Set up spatial partitions
	sp_player_shots = SpatialPartitioningManager.new(
		_prefab_player_shot,
		_parent_player_shots,
		100
	)
	
	# Position stuff
	obj_player.position = Vector2(battle_area_size.x / 2, battle_area_south_y - 100)
	
	# Spawn enemies
	_set_up_battle()

func _process(_delta):
	_debug()

# Public functions

static func get_player() -> BattlePlayer:
	return obj_player

static func player_shoot_shot(p_aim_angle: float, p_shot_damage: float):
	var new_shot: BattlePlayerShot = sp_player_shots.spawn_obj(obj_player.position)
	if new_shot == null:
		return
	new_shot.set_up(obj_player.position, p_aim_angle, p_shot_damage)

static func handle_defeated_enemy(p_enemy: BattleEnemy):
	var ripple: BattleMiscRipple = _prefab_ripple.instantiate()
	ripple.set_up(p_enemy.position)
	_parent_top_left.add_child(ripple)
	
	_enemy_list.erase(p_enemy)
	p_enemy.queue_free()
	
	var enemy_count = _enemy_list.size()
	if enemy_count == 0:
		return
	
	BattleUIEnemyRemaining.show_enemy_remaining(enemy_count)

# Private functions

func _set_up_battle():
	var behavior_list: Array[Script] = [
		BattleEnemyElitePriest,
		BattleEnemyNatureTriangleAimer,
		BattleBossMiscMajorSwarms,
		#BattleBossMiscMajorSphere
	]
	var spawn_region_start: Vector2 = Vector2(0, 0)
	var spawn_region_end: Vector2 = Vector2(battle_area_size.x, battle_area_size.y)
	
	for i in 3:
		var enemy: BattleEnemy = _prefab_enemy.instantiate()
		var behavior: Script = behavior_list.pick_random()
		var spawn_pos: Vector2 = Vector2(
			randf_range(spawn_region_start.x, spawn_region_end.x),
			randf_range(spawn_region_start.y, spawn_region_end.y / 2))
		# spawn_pos = Vector2(battle_area_size.x / 2, battle_area_size.y / 2)
		
		enemy.set_up(spawn_pos)
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
	_obj_top_left.position = origin_from_top_left
	
	battle_area_west_x = 0
	battle_area_east_x = battle_area_width
	battle_area_north_y = 0
	battle_area_south_y = battle_area_height

# Debug methods

func _debug():
	if not Input.is_action_pressed("game_debug"):
		return
	
	if Input.is_key_pressed(KEY_Q):
		obj_player.position = origin_from_top_left
		return
	
	if Input.is_key_pressed(KEY_W):
		obj_player.position = origin_from_center
		return
	
	if Input.is_action_just_pressed("debug_e"):
		_debug_play = !_debug_play
		return
	
	if Input.is_action_just_pressed("debug_quit"):
		get_tree().quit()


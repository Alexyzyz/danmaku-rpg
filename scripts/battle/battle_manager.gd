class_name BattleManager
extends Node

const VIEWPORT_VERTICAL_PADDING: float = 20
const BATTLE_AREA_ASPECT_RATIO: float = 0.75

# Spatial partitioning
static var sp_enemy_bullets: SpatialPartitioningManager
static var sp_player_shots: SpatialPartitioningManager
# Important objects
static var parent: Node2D
static var obj_player: BattlePlayer
static var obj_boss: Node2D
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
# Parents
static var _parent_enemy_bullets: Node2D
static var _parent_player_shots: Node2D
# Other
static var _enemy_list: Array[Node2D]
# Resources
static var _sprite_bullet_default = preload("res://sprites/bullets/spr_bullet_0.png")
static var _sprite_bullet_default_dropshadow = preload("res://sprites/bullets/spr_bullet_0_dropshadow.png")

static var _debug_play: bool = true

# Parents
@onready var _parent_debug: Node2D = $"../Level/Node2D/TopLeft/DebugParent"
# Other
@onready var _obj_enemy: Node2D = $"../Level/Node2D/TopLeft/Enemy"
@onready var _obj_top_left: Node2D = $"../Level/Node2D/TopLeft"

# Called when the node enters the scene tree for the first time.
func _ready():
	# Set prefabs
	_prefab_enemy_bullet = preload("res://prefabs/prefab_bullet.tscn")
	_prefab_player_shot = preload("res://prefabs/prefab_player_priest_shot.tscn")
	
	# Set children
	parent = $"../Level/Node2D/TopLeft"
	obj_player = $"../Level/Node2D/TopLeft/Player"
	obj_boss = $"../Level/Node2D/TopLeft/Enemy"
	
	_parent_enemy_bullets = $"../Level/Node2D/TopLeft/EnemyBulletParent"
	_parent_player_shots = $"../Level/Node2D/TopLeft/PlayerShotParent"
	
	# Set up stuff
	_set_up_battle_area()
	
	# Set up spatial partitions
	sp_enemy_bullets = SpatialPartitioningManager.new(
		_prefab_enemy_bullet,
		_parent_enemy_bullets,
		1500
	)
	sp_player_shots = SpatialPartitioningManager.new(
		_prefab_player_shot,
		_parent_player_shots,
		100
	)
	
	# Position stuff
	obj_player.position = Vector2(battle_area_size.x / 2, battle_area_south_y - 100)
	obj_boss.position = Vector2(battle_area_size.x / 2, battle_area_north_y + 200)

func _process(_delta):
	_debug()
	_debug_update_ui()

# Public functions

static func player_shoot_shot():
	var new_shot: BattlePlayerShot = sp_player_shots.spawn_obj(obj_player.position)
	if new_shot == null:
		return
	new_shot.set_up(obj_player.position)

static func shoot_bullet(
	# Mandatory
	position: Vector2,
	direction: float,
	speed: float,
	# Optional
	color: Color = Color.WHITE,
	bullet_resource: UtilBulletResource.BulletResource = UtilBulletResource.default) -> BattleBullet:
	
	var new_bullet: BattleBullet = sp_enemy_bullets.spawn_obj(position)
	if new_bullet == null:
		return
	
	new_bullet.set_up(position, direction, speed, color, bullet_resource)
	return new_bullet

static func shoot_bullet_ring(
	# Mandatory
	position: Vector2,
	direction: float,
	speed: float,
	bullet_count: int,
	# Optional
	ring_radius: float = TAU,
	modify_bullet: Callable = func(bullet: BattleBullet, i: int): pass,
	bullet_resource: UtilBulletResource.BulletResource = UtilBulletResource.default) -> Array[BattleBullet]:
	
	var bullet_list: Array[BattleBullet] = []
	var angle_step: float = ring_radius / bullet_count
	
	var angle_offset_even_offset: float = angle_step / 2 if bullet_count % 2 == 0 else angle_step
	var angle_offset: float = ring_radius - angle_step * (bullet_count / 2) - angle_offset_even_offset
	
	var curr_angle: float = direction - angle_offset
	for i in bullet_count:
		var new_bullet = shoot_bullet(position, curr_angle, speed, Color.WHITE, bullet_resource)
		modify_bullet.call(new_bullet, i)
		bullet_list.push_back(new_bullet)
		curr_angle += angle_step
	return bullet_list

# Private functions

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

func _debug_update_ui():
	BattleDebugManager.update_bullet_count(sp_enemy_bullets.get_active_obj_count())

class_name BattleManager
extends Node

const _VIEWPORT_VERTICAL_PADDING: float = 20
const _BATTLE_AREA_ASPECT_RATIO: float = 0.75
const _MAX_BULLET_COUNT = 1500

# Spatial partitioning
const _SP_GRID_SIZE = Vector2(20, 26)
const _SP_GRID_PADDING = 0

# ✨ NEW ✨ spatial partitioning
static var sp_enemy_bullets: SpatialPartitioningManager
static var sp_player_shots: SpatialPartitioningManager

# Prefabs
@onready var prefab_debug_cell = preload("res://prefabs/debug/prefab_debug_cell.tscn")
# Parents
@onready var parent_debug: Node2D = $"../Level/Node2D/TopLeft/DebugParent"
# Other
@onready var obj_enemy: Node2D = $"../Level/Node2D/TopLeft/Enemy"
@onready var obj_top_left: Node2D = $"../Level/Node2D/TopLeft"

# Public static variables
# Feel free to use these

static var obj_player: BattlePlayer
static var obj_boss: Node2D

static var battle_area_size: Vector2
static var battle_area_west_x: float
static var battle_area_east_x: float
static var battle_area_north_y: float
static var battle_area_south_y: float

static var parent: Node2D
static var origin_from_center: Vector2
static var origin_from_top_left: Vector2

# Private static variables
# Do not use these

# Prefabs
static var _prefab_bullet: PackedScene
# Parents
static var _parent_enemy_bullets: Node2D
static var _parent_player_shots: Node2D
# Other
static var _bullet_inactive_pool: Array[BattleBullet]
static var _enemy_list: Array[Node2D]

static var _sp_cell_list = []
static var _sp_cell_size: Vector2

static var _sprite_bullet_default = preload("res://sprites/bullets/spr_bullet_0.png")
static var _sprite_bullet_default_dropshadow = preload("res://sprites/bullets/spr_bullet_0_dropshadow.png")

static var _debug_play: bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	# Set prefabs
	_prefab_bullet = preload("res://prefabs/prefab_bullet.tscn")
	
	# Set children
	parent = $"../Level/Node2D/TopLeft"
	obj_player = $"../Level/Node2D/TopLeft/Player"
	obj_boss = $"../Level/Node2D/TopLeft/Enemy"
	
	_parent_enemy_bullets = $"../Level/Node2D/TopLeft/EnemyBulletParent"
	_parent_player_shots = $"../Level/Node2D/TopLeft/PlayerShotParent"
	
	# Set spatial partitions
	sp_enemy_bullets = SpatialPartitioningManager.new(
		_prefab_bullet,
		_parent_enemy_bullets,
		1500
	)
	# sp_player_shots = SpatialPartitioningManager.new()
	
	# Set up stuff
	_set_up_battle_area()
	_set_up_bullet_pool()
	_set_up_sp_grid()
	
	# Position stuff
	obj_player.position = Vector2(battle_area_size.x / 2, battle_area_south_y - 100)
	obj_boss.position = Vector2(battle_area_size.x / 2, battle_area_north_y + 200)
	
	# debug_draw_cells()

func _process(_delta):
	_debug()
	_update_bullet_count()

# Public functions

static func shoot_bullet(
	position: Vector2, direction: float, speed: float,
	color: Color = Color.WHITE,
	bullet_resource: UtilBulletResource.BulletResource = UtilBulletResource.default) -> BattleBullet:
	
	var cell = get_cell(position)
	if is_cell_oob(cell):
		return
	
	var new_bullet: BattleBullet = _bullet_inactive_pool.pop_front()
	if new_bullet == null:
		return
	new_bullet.enable()
	
	new_bullet.set_up(position, direction, speed, color, bullet_resource)
	_add_to_sp_grid(new_bullet, get_cell(position))
	
	return new_bullet

static func shoot_bullet_ring(
	position: Vector2, direction: float, speed: float, bullet_count: int,
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

static func update_sp_grid(bullet: BattleBullet, new_pos: Vector2):
	# Destroy the bullet if it strayed outside the grid
	var new_cell = get_cell(new_pos)
	if is_cell_oob(new_cell):
		handle_destroyed_bullet(bullet)
		return
	
	# No need to update if the bullet is still in the same cell
	var old_cell = bullet.sp_last_cell
	if old_cell.x == new_cell.x and old_cell.y == new_cell.y:
		return
	
	# Update if the bullet changed cell
	_remove_bullet_from_cell(bullet, old_cell)
	_add_to_sp_grid(bullet, new_cell)

static func handle_destroyed_bullet(bullet: BattleBullet):
	var last_cell = bullet.sp_last_cell
	
	if !is_cell_oob(last_cell):
		_remove_bullet_from_cell(bullet, last_cell)
	
	bullet.disable()
	_bullet_inactive_pool.push_back(bullet)

static func get_bullet_in_cell(cell: Vector2i):
	if is_cell_oob(cell):
		print("get_bullets_in_cell(): Cell position out of bounds!")
		return null
	var bullet = _sp_cell_list[cell.x][cell.y]
	if is_instance_valid(bullet):
		return bullet
	return null

static func get_bullet_in_position(position: Vector2):
	var cell: Vector2i = get_cell(position)
	return get_bullet_in_cell(cell)

static func get_bullet_in_cells_surrounding(position: Vector2) -> Array[BattleBullet]:
	var center_cell = get_cell(position)
	var cell_list: Array[BattleBullet] = []
	
	for x_offset in 3:
		for y_offset in 3:
			var offset = Vector2i(x_offset - 1, y_offset - 1)
			var cell = center_cell + offset
			if is_cell_oob(center_cell + offset):
				continue
			cell_list.append(get_bullet_in_cell(cell))
	
	return cell_list

static func get_cell(position: Vector2) -> Vector2i:
	var cell_x: int = (int)(position.x / _sp_cell_size.x)
	var cell_y: int = (int)(position.y / _sp_cell_size.y)
	return Vector2i(cell_x, cell_y)

static func is_cell_oob(cell: Vector2i) -> bool:
	return cell.x < 0 or cell.y < 0 \
		or cell.x > _SP_GRID_SIZE.x + _SP_GRID_PADDING \
		or cell.y > _SP_GRID_SIZE.y + _SP_GRID_PADDING

# Private functions

func _set_up_battle_area():
	var viewport_rect_size: Vector2 = get_viewport().get_visible_rect().size
	var battle_area_height = viewport_rect_size.y - _VIEWPORT_VERTICAL_PADDING * 2
	var battle_area_width = battle_area_height * _BATTLE_AREA_ASPECT_RATIO
	
	battle_area_size = Vector2(battle_area_width, battle_area_height)
	origin_from_center = viewport_rect_size / 2
	origin_from_top_left = origin_from_center - battle_area_size / 2
	obj_top_left.position = origin_from_top_left
	
	battle_area_west_x = 0
	battle_area_east_x = battle_area_width
	battle_area_north_y = 0
	battle_area_south_y = battle_area_height

func _set_up_bullet_pool():
	for i in _MAX_BULLET_COUNT:
		var new_bullet: BattleBullet = _prefab_bullet.instantiate()
		new_bullet.name = "Bullet"
		new_bullet.set_process(false)
		_parent_enemy_bullets.add_child(new_bullet)
		_bullet_inactive_pool.push_back(new_bullet)

func _set_up_sp_grid():
	var off_by_one_safety_padding = 1
	for i in _SP_GRID_SIZE.x + _SP_GRID_PADDING + off_by_one_safety_padding:
		_sp_cell_list.append([])
		for j in _SP_GRID_SIZE.y + _SP_GRID_PADDING + off_by_one_safety_padding:
			_sp_cell_list[i].append(null)
	
	_sp_cell_size = Vector2(
		battle_area_size.x / _SP_GRID_SIZE.x,
		battle_area_size.y / _SP_GRID_SIZE.y)

static func _add_to_sp_grid(bullet: BattleBullet, cell: Vector2i):	
	bullet.sp_last_cell = cell
	bullet.sp_cell_prev = null
	bullet.sp_cell_next = _sp_cell_list[cell.x][cell.y]
	_sp_cell_list[cell.x][cell.y] = bullet
	
	if bullet.sp_cell_next != null:
		bullet.sp_cell_next.sp_cell_prev = bullet

static func _remove_bullet_from_cell(bullet: BattleBullet, old_cell: Vector2i):
	if bullet.sp_cell_prev != null:
		bullet.sp_cell_prev.sp_cell_next = bullet.sp_cell_next
	
	if bullet.sp_cell_next != null:
		bullet.sp_cell_next.sp_cell_prev = bullet.sp_cell_prev
	
	if _sp_cell_list[old_cell.x][old_cell.y] == bullet:
		_sp_cell_list[old_cell.x][old_cell.y] = bullet.sp_cell_next

func _update_bullet_count():
	BattleDebugManager.update_bullet_count(_MAX_BULLET_COUNT - _bullet_inactive_pool.size())

# Debug methods :: For debugging purposes

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
	
func _debug_draw_cells():
	const SPRITE_SIDE_LENGTH = 64
	var grid_width: int = floor(_SP_GRID_SIZE.x)
	var grid_height: int = floor(_SP_GRID_SIZE.y)
	
	for y in grid_height:
		var offset = 0 if y % 2 == 0 else 1
		for x in grid_width:
			if (x + offset) % 2 == 0:
				continue
			
			var debug_cell: Sprite2D = prefab_debug_cell.instantiate()
			parent_debug.add_child(debug_cell)
			
			var cell_size = Vector2(battle_area_size.x / grid_width, battle_area_size.y / grid_height)
			debug_cell.scale = cell_size / (2 * SPRITE_SIDE_LENGTH)
			debug_cell.position = Vector2(x * cell_size.x, y * cell_size.y)

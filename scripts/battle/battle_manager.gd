class_name BattleManager
extends Node

const VIEWPORT_VERTICAL_PADDING: float = 20
const BATTLE_AREA_ASPECT_RATIO: float = 0.75
const COLLISION_GRID_SIZE = Vector2(20, 26)
const COLLISION_GRID_PADDING = 0

@onready var prefab_debug_cell = preload("res://prefabs/debug/prefab_debug_cell.tscn")
@onready var parent_debug: Node2D = $"../Level/Node2D/TopLeft/DebugParent"
@onready var obj_enemy: Node2D = $"../Level/Node2D/TopLeft/Enemy"
@onready var obj_top_left: Node2D = $"../Level/Node2D/TopLeft"

static var _prefab_bullet: PackedScene
static var _parent_bullet: Node2D

static var parent: Node2D
static var obj_player: BattlePlayer
static var origin_from_center: Vector2
static var origin_from_top_left: Vector2

static var battle_area_size: Vector2
static var collision_grid = []
static var collision_grid_cell_size: Vector2

static var debug_play: bool = true

static var _sprite_bullet_default = preload("res://sprites/bullets/spr_bullet_0.png")
static var _sprite_bullet_default_dropshadow = preload("res://sprites/bullets/spr_bullet_0_dropshadow.png")

# Called when the node enters the scene tree for the first time.
func _ready():
	var viewport_rect_size: Vector2 = get_viewport().get_visible_rect().size
	var battle_area_height = viewport_rect_size.y - VIEWPORT_VERTICAL_PADDING * 2
	var battle_area_width = battle_area_height * BATTLE_AREA_ASPECT_RATIO
	
	battle_area_size = Vector2(battle_area_width, battle_area_height)
	origin_from_center = viewport_rect_size / 2
	origin_from_top_left = origin_from_center - battle_area_size / 2
	obj_top_left.position = origin_from_top_left
	
	set_up_collision_grid()
	
	parent = $"../Level/Node2D/TopLeft"
	obj_player = $"../Level/Node2D/TopLeft/Player"
	
	_prefab_bullet = preload("res://prefabs/prefab_bullet.tscn")
	_parent_bullet = $"../Level/Node2D/TopLeft/BulletParent"
	
	debug_draw_cells()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	debug()
	pass

# Collision grid handler

func set_up_collision_grid():
	var off_by_one_safety_padding = 1
	for i in COLLISION_GRID_SIZE.x + COLLISION_GRID_PADDING + off_by_one_safety_padding:
		collision_grid.append([])
		for j in COLLISION_GRID_SIZE.y + COLLISION_GRID_PADDING + off_by_one_safety_padding:
			collision_grid[i].append(null)
	
	collision_grid_cell_size = Vector2(
		battle_area_size.x / COLLISION_GRID_SIZE.x,
		battle_area_size.y / COLLISION_GRID_SIZE.y)

static func add_to_collision_grid(bullet: BattleBullet):
	var cell = get_cell(bullet.position)
	if is_cell_oob(cell):
		bullet.queue_free()
		return
	
	bullet.last_collision_cell = cell
	bullet.collision_grid_prev = null
	bullet.collision_grid_next = collision_grid[cell.x][cell.y]
	collision_grid[cell.x][cell.y] = bullet
	
	if bullet.collision_grid_next != null:
		bullet.collision_grid_next.collision_grid_prev = bullet

static func update_collision_grid(bullet: BattleBullet, new_pos: Vector2):
	var old_cell = get_cell(bullet.position)
	var new_cell = get_cell(new_pos)
	
	# WARNING
	# I'm not exactly sure why this has to be done here
	# but otherwise the game is prone to crashing so...
	bullet.position = new_pos
	
	# Destroy the bullet if it strayed outside the grid
	if is_cell_oob(new_cell):
		handle_destroyed_bullet(bullet)
		return
	
	# No need to update if the bullet is still in the same cell
	if old_cell.x == new_cell.x and old_cell.y == new_cell.y:
		return
	
	# Update if the bullet changed cell
	remove_bullet_from_cell(bullet, old_cell)
	add_to_collision_grid(bullet)

static func handle_destroyed_bullet(bullet: BattleBullet):
	var last_cell = bullet.last_collision_cell
	
	if !is_cell_oob(last_cell):
		remove_bullet_from_cell(bullet, last_cell)
	
	bullet.queue_free()

static func remove_bullet_from_cell(bullet: BattleBullet, old_cell: Vector2i):
	if bullet.collision_grid_prev != null:
		bullet.collision_grid_prev.collision_grid_next = bullet.collision_grid_next
	
	if bullet.collision_grid_next != null:
		bullet.collision_grid_next.collision_grid_prev = bullet.collision_grid_prev
	
	if collision_grid[old_cell.x][old_cell.y] == bullet:
		collision_grid[old_cell.x][old_cell.y] = bullet.collision_grid_next

static func get_bullet_in_cell(cell: Vector2i):
	if is_cell_oob(cell):
		print("get_bullets_in_cell(): Cell position out of bounds!")
		return null
	var bullet = collision_grid[cell.x][cell.y]
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
	var cell_x: int = (int)(position.x / collision_grid_cell_size.x)
	var cell_y: int = (int)(position.y / collision_grid_cell_size.y)
	return Vector2i(cell_x, cell_y)

static func is_cell_oob(cell: Vector2i) -> bool:
	return cell.x < 0 or cell.y < 0 \
		or cell.x > COLLISION_GRID_SIZE.x + COLLISION_GRID_PADDING \
		or cell.y > COLLISION_GRID_SIZE.y + COLLISION_GRID_PADDING

# Bullet shooting handler

static func shoot_bullet(
	pos: Vector2, angle: float, spd: float,
	bullet_resource: UtilBulletResource.BulletResource = UtilBulletResource.default) -> BattleBullet:
	
	var new_bullet: BattleBullet = _prefab_bullet.instantiate()
	new_bullet.name = "Bullet"
	_parent_bullet.add_child(new_bullet)
	
	new_bullet.set_up(pos, angle, spd, bullet_resource)
	BattleManager.add_to_collision_grid(new_bullet)
	
	return new_bullet

# Debugging purposes

func debug():
	if not Input.is_action_pressed("game_debug"):
		return
	
	if Input.is_key_pressed(KEY_Q):
		obj_player.position = origin_from_top_left
		return
	
	if Input.is_key_pressed(KEY_W):
		obj_player.position = origin_from_center
		return
	
	if Input.is_action_just_pressed("debug_e"):
		debug_play = !debug_play
		return
	
	if Input.is_action_just_pressed("debug_quit"):
		get_tree().quit()
	
func debug_draw_cells():
	const SPRITE_SIDE_LENGTH = 64
	var grid_width: int = floor(COLLISION_GRID_SIZE.x)
	var grid_height: int = floor(COLLISION_GRID_SIZE.y)
	
	for y in grid_height:
		var offset = 0 if y % 2 == 0 else 1
		for x in grid_width:
			if (x + offset) % 2 == 0:
				print(x)
				continue
			
			var debug_cell: Sprite2D = prefab_debug_cell.instantiate()
			parent_debug.add_child(debug_cell)
			
			var cell_size = Vector2(battle_area_size.x / grid_width, battle_area_size.y / grid_height)
			debug_cell.scale = cell_size / (2 * SPRITE_SIDE_LENGTH)
			debug_cell.position = Vector2(x * cell_size.x, y * cell_size.y)

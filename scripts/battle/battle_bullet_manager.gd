class_name BattleBulletManager
extends Node2D

const BULLET_MAX_COUNT: int = 2000
const SP_GRID_SIZE: Vector2i = Vector2i(20, 26)
const SP_GRID_PADDING: int = 0

static var _bullet_list: Array[Bullet]
static var _first_inactive_bullet: Bullet

static var _sp_cell_list = []
static var _sp_cell_size: Vector2

static var _debug_active_bullet_count: int = 0

@onready var _debug_bullet_drop_shadow: Texture2D = preload("res://sprites/bullets/spr_bullet_0_dropshadow.png")

# Main methods

func _ready():
	BattleBulletManager._sp_set_up_grid()
	_op_set_up_pool()

func _process(delta: float):
	_update_bullets(delta)
	_debug_update_bullet_count()
	
	queue_redraw()

func _physics_process(_delta: float):
	pass

func _draw():
	_draw_bullets_drop_shadow()
	_draw_bullets()

# Public methods

static func shoot_bullet(
	pos: Vector2,
	angle: float,
	speed: float,
	# Optional
	resource: BulletResource = UtilBulletResource.default) -> Bullet:
	
	var bullet: Bullet = _first_inactive_bullet
	if bullet == null:
		return
	if sp_is_cell_oob(sp_get_cell(pos)):
		return
	
	_first_inactive_bullet = bullet.next_inactive
	bullet.next_inactive = null
	bullet.is_active = true
	
	bullet.set_up(pos, UtilMath.get_vector_from_angle(angle), speed, resource)
	_sp_add_to_grid(bullet, sp_get_cell(pos))
	return bullet

static func shoot_bullet_ring(
	pos: Vector2,
	angle: float,
	speed: float,
	bullet_count: int,
	# Optional
	resource: BulletResource = UtilBulletResource.default,
	ring_radius: float = TAU,
	modify_bullet: Callable = func(_bullet: Bullet, _i: int): pass) -> Array[Bullet]:
	
	var bullet_list: Array[Bullet] = []
	var angle_step: float = ring_radius / bullet_count
	
	var angle_offset_even_offset: float = angle_step / 2 if bullet_count % 2 == 0 else angle_step
	var angle_offset: float = ring_radius - angle_step * (bullet_count / 2) - angle_offset_even_offset
	
	var curr_angle: float = angle - angle_offset
	for i in bullet_count:
		var new_bullet: Bullet = shoot_bullet(pos, curr_angle, speed, resource)
		curr_angle += angle_step
		
		if new_bullet == null:
			continue
		if modify_bullet != null:
			modify_bullet.call(new_bullet, i)
		
		bullet_list.push_back(new_bullet)
	return bullet_list

# Public methods :: Spatial partitioning

static func sp_update_grid(bullet: Bullet, new_pos: Vector2):	
	# Pass 1 ✦ Remove the bullet early if it's out of bounds
	var new_cell: Vector2i = sp_get_cell(new_pos)
	if sp_is_cell_oob(new_cell):
		sp_destroy_bullet(bullet)
		return
	
	# Pass 2 ✦ No need to update if the bullet is still in the same cell
	var old_cell: Vector2i = bullet.sp_last_cell
	if old_cell.x == new_cell.x and old_cell.y == new_cell.y:
		return
	
	# Pass 3 ✦ Update if the bullet changed cell
	_sp_remove_bullet_from_cell(bullet, old_cell)
	_sp_add_to_grid(bullet, new_cell)

static func sp_destroy_bullet(bullet: Bullet):
	var last_cell: Vector2i = bullet.sp_last_cell
	if !sp_is_cell_oob(last_cell):
		_sp_remove_bullet_from_cell(bullet, last_cell)
	
	bullet.is_active = false
	bullet.next_inactive = _first_inactive_bullet
	_first_inactive_bullet = bullet

static func sp_get_bullet_in_cell(cell: Vector2i) -> Bullet:
	# Pass 1 ✦ Cell must be in-of-bounds
	if sp_is_cell_oob(cell):
		print("get_bullet_in_cell(): Cell position out of bounds!")
		return null
	
	# Pass 2 ✦ Head bullet must exist and be in memory
	var head_bullet: Bullet = _sp_cell_list[cell.x][cell.y]
	if is_instance_valid(head_bullet):
		return head_bullet
	
	return null

static func sp_get_bullet_in_position(p_position: Vector2) -> Bullet:
	var cell: Vector2i = sp_get_cell(p_position)
	return sp_get_bullet_in_cell(cell)

static func sp_get_bullet_in_cells_surrounding(p_position: Vector2) -> Array[Bullet]:
	var center_cell: Vector2i = sp_get_cell(p_position)
	var cell_list: Array[Bullet] = []
	
	for x_offset in 3:
		for y_offset in 3:
			var offset: Vector2i = Vector2i(x_offset - 1, y_offset - 1)
			var cell: Vector2i = center_cell + offset
			if sp_is_cell_oob(cell):
				continue
			cell_list.append(sp_get_bullet_in_cell(cell))
	
	return cell_list

static func sp_get_cell(p_position: Vector2) -> Vector2i:
	var cell_x: int = (int)(p_position.x / _sp_cell_size.x)
	var cell_y: int = (int)(p_position.y / _sp_cell_size.y)
	return Vector2i(cell_x, cell_y)

static func sp_is_cell_oob(p_cell: Vector2i) -> bool:
	return p_cell.x < 0 or p_cell.y < 0 \
		or p_cell.x > SP_GRID_SIZE.x + SP_GRID_PADDING \
		or p_cell.y > SP_GRID_SIZE.y + SP_GRID_PADDING

# Private methods

func _op_set_up_pool():
	_first_inactive_bullet = Bullet.new()
	_bullet_list.push_back(_first_inactive_bullet)
	
	var prev: Bullet = _first_inactive_bullet
	for i in BULLET_MAX_COUNT - 1:
		var new_bullet: Bullet = Bullet.new()
		prev.next_inactive = new_bullet
		prev = new_bullet
		_bullet_list.push_back(new_bullet)

func _update_bullets(delta: float):
	for bullet in _bullet_list:
		if !bullet.is_active:
			continue
		bullet.tick(delta)

func _move_bounce_on_screen(bullet: Bullet) -> Vector2:
	if bullet.position.x < BattleManager.battle_area_west_x or \
		bullet.position.x > BattleManager.battle_area_east_x:
		bullet.position.x = clamp(bullet.position.x, BattleManager.battle_area_west_x, BattleManager.battle_area_east_x)
		bullet.direction.x *= -1
	
	if bullet.position.y > BattleManager.battle_area_south_y or \
		bullet.position.y < BattleManager.battle_area_north_y:
		bullet.position.y = clamp(bullet.position.y, BattleManager.battle_area_north_y, BattleManager.battle_area_south_y)
		bullet.direction.y *= -1
	return bullet.position

# Private methods :: Spatial partitioning

static func _sp_set_up_grid():
	for i in SP_GRID_SIZE.x + SP_GRID_PADDING + 1:
		_sp_cell_list.append([])
		for j in SP_GRID_SIZE.y + SP_GRID_PADDING + 1:
			_sp_cell_list[i].append(null)
	
	_sp_cell_size = Vector2(
		BattleManager.battle_area_size.x / SP_GRID_SIZE.x,
		BattleManager.battle_area_size.y / SP_GRID_SIZE.y)

static func _sp_add_to_grid(bullet: Bullet, cell: Vector2i):
	bullet.sp_last_cell = cell
	bullet.sp_cell_prev = null
	bullet.sp_cell_next = _sp_cell_list[cell.x][cell.y]
	_sp_cell_list[cell.x][cell.y] = bullet
	
	if bullet.sp_cell_next != null:
		bullet.sp_cell_next.sp_cell_prev = bullet

static func _sp_remove_bullet_from_cell(bullet: Bullet, old_cell: Vector2i):
	if bullet.sp_cell_prev != null:
		bullet.sp_cell_prev.sp_cell_next = bullet.sp_cell_next
	
	if bullet.sp_cell_next != null:
		bullet.sp_cell_next.sp_cell_prev = bullet.sp_cell_prev
	
	if _sp_cell_list[old_cell.x][old_cell.y] == bullet:
		_sp_cell_list[old_cell.x][old_cell.y] = bullet.sp_cell_next

# Private methods :: Rendering

func _draw_bullets_drop_shadow():
	for bullet in _bullet_list:
		if !bullet.is_active:
			continue
		
		var texture: Texture2D = bullet.resource.texture_drop_shadow
		if texture == null:
			return
		var offset = texture.get_size() / 2.0
		draw_texture(
			texture,
			bullet.position - offset,
			Color(0, 0, 0, 0.8)
		)

func _draw_bullets():
	for bullet in _bullet_list:
		if !bullet.is_active:
			continue
		
		var texture: Texture2D = bullet.resource.texture
		if texture == null:
			return
		var offset = texture.get_size() / 2.0
		draw_texture(
			texture,
			bullet.position - offset,
			bullet.get_graze_modulation()
		)

# Private methods :: Debugging

func _debug_update_bullet_count():
	BattleDebugManager.update_bullet_count(_debug_active_bullet_count)

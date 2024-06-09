class_name BattleBulletManager
extends Node2D

const BULLET_MAX_COUNT: int = 1500
const SP_GRID_SIZE: Vector2i = Vector2i(20, 26)
const SP_GRID_PADDING: int = 0

static var _bullet_list: Array[Bullet]
static var _first_inactive_bullet: Bullet

static var _sp_cell_list = []
static var _sp_cell_size: Vector2

static var _debug_active_bullet_count: int = 0

@onready var _debug_bullet_drop_shadow: Texture2D = preload("res://sprites/bullets/spr_bullet_0_dropshadow.png")

# Main methods

func _process(_p_delta: float):
	queue_redraw()


func _draw():
	_draw_bullets_drop_shadow()
	_draw_bullets()


# Public methods

static func update(p_delta: float):
	if p_delta == 0:
		return
	
	_update_bullets(p_delta)
	_debug_update_bullet_count()


static func set_up():
	_sp_set_up_grid()
	_op_set_up_pool()


static func shoot_bullet(
	p_pos: Vector2,
	p_angle: float,
	p_speed: float,
	# Optional
	p_resource: BulletResource = UtilBulletResource.default) -> Bullet:
	
	var bullet: Bullet = _first_inactive_bullet
	if bullet == null:
		return
	if sp_is_cell_oob(sp_get_cell(p_pos)):
		return
	
	_debug_active_bullet_count += 1
	
	_first_inactive_bullet = bullet.next_inactive
	bullet.next_inactive = null
	bullet.is_active = true
	
	bullet.set_up(p_pos, UtilMath.get_vector_from_angle(p_angle), p_speed, p_resource)
	_sp_add_to_grid(bullet, sp_get_cell(p_pos))
	return bullet


static func shoot_bullet_ring(
	p_pos: Vector2,
	p_angle: float,
	p_speed: float,
	p_bullet_count: int,
	# Optional
	p_resource: BulletResource = UtilBulletResource.default,
	p_ring_radius: float = TAU,
	p_modify_bullet: Callable = func(_bullet: Bullet, _i: int): pass) -> Array[Bullet]:
	
	var bullet_list: Array[Bullet] = []
	var angle_step: float = p_ring_radius / p_bullet_count
	
	var angle_offset_even_offset: float = angle_step / 2 if p_bullet_count % 2 == 0 else angle_step
	var angle_offset: float = p_ring_radius - angle_step * (p_bullet_count / 2) - angle_offset_even_offset
	
	var curr_angle: float = p_angle - angle_offset
	for i in p_bullet_count:
		var new_bullet: Bullet = shoot_bullet(p_pos, curr_angle, p_speed, p_resource)
		curr_angle += angle_step
		
		if new_bullet == null:
			continue
		if p_modify_bullet != null:
			p_modify_bullet.call(new_bullet, i)
		
		bullet_list.push_back(new_bullet)
	return bullet_list


# Public methods :: Spatial partitioning

static func sp_update_grid(p_bullet: Bullet, p_new_pos: Vector2):
	# Pass 1 ✦ Remove the bullet early if it's out of bounds
	var new_cell: Vector2i = sp_get_cell(p_new_pos)
	if sp_is_cell_oob(new_cell):
		sp_destroy_bullet(p_bullet)
		return
	
	# Pass 2 ✦ No need to update if the bullet is still in the same cell
	var old_cell: Vector2i = p_bullet.sp_last_cell
	if old_cell.x == new_cell.x and old_cell.y == new_cell.y:
		return
	
	# Pass 3 ✦ Update if the bullet changed cell
	_sp_remove_bullet_from_cell(p_bullet, old_cell)
	_sp_add_to_grid(p_bullet, new_cell)


static func sp_destroy_bullet(p_bullet: Bullet):
	_debug_active_bullet_count -= 1
	
	var last_cell: Vector2i = p_bullet.sp_last_cell
	if !sp_is_cell_oob(last_cell):
		_sp_remove_bullet_from_cell(p_bullet, last_cell)
	
	p_bullet.is_active = false
	p_bullet.next_inactive = _first_inactive_bullet
	_first_inactive_bullet = p_bullet


static func sp_get_bullet_in_cell(p_cell: Vector2i) -> Bullet:
	# Pass 1 ✦ Cell must be in-of-bounds
	if sp_is_cell_oob(p_cell):
		print("get_bullet_in_cell(): Cell position out of bounds!")
		return null
	
	# Pass 2 ✦ Head bullet must exist and be in memory
	var head_bullet: Bullet = _sp_cell_list[p_cell.x][p_cell.y]
	if is_instance_valid(head_bullet):
		return head_bullet
	
	return null


static func sp_get_bullet_in_position(p_position: Vector2) -> Bullet:
	var cell: Vector2i = sp_get_cell(p_position)
	return sp_get_bullet_in_cell(cell)


static func sp_get_bullet_in_cells_surrounding(p_position: Vector2, p_range: int = 3) -> Array[Bullet]:
	var center_cell: Vector2i = sp_get_cell(p_position)
	var cell_list: Array[Bullet] = []
	
	var offset_offset: int = floor(p_range / 2.0)
	for x_offset in p_range:
		for y_offset in p_range:
			var offset: Vector2i = Vector2i(x_offset, y_offset) - offset_offset * Vector2i.ONE
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


static func sp_get_cell_size() -> Vector2:
	return _sp_cell_size


# Private methods

static func _op_set_up_pool():
	_first_inactive_bullet = Bullet.new()
	_bullet_list.push_back(_first_inactive_bullet)
	
	var prev: Bullet = _first_inactive_bullet
	for i in BULLET_MAX_COUNT - 1:
		var new_bullet: Bullet = Bullet.new()
		prev.next_inactive = new_bullet
		prev = new_bullet
		_bullet_list.push_back(new_bullet)


static func _update_bullets(p_delta: float):
	for bullet in _bullet_list:
		if !bullet.is_active:
			continue
		bullet.tick(p_delta)


func _move_bounce_on_screen(p_bullet: Bullet) -> Vector2:
	if p_bullet.position.x < BattleManager.battle_area_west_x or \
		p_bullet.position.x > BattleManager.battle_area_east_x:
		p_bullet.position.x = clamp(p_bullet.position.x, BattleManager.battle_area_west_x, BattleManager.battle_area_east_x)
		p_bullet.direction.x *= -1
	
	if p_bullet.position.y > BattleManager.battle_area_south_y or \
		p_bullet.position.y < BattleManager.battle_area_north_y:
		p_bullet.position.y = clamp(p_bullet.position.y, BattleManager.battle_area_north_y, BattleManager.battle_area_south_y)
		p_bullet.direction.y *= -1
	return p_bullet.position


# Private methods ✦ Spatial partitioning

static func _sp_set_up_grid():
	for i in SP_GRID_SIZE.x + SP_GRID_PADDING + 1:
		_sp_cell_list.append([])
		for j in SP_GRID_SIZE.y + SP_GRID_PADDING + 1:
			_sp_cell_list[i].append(null)
	
	_sp_cell_size = Vector2(
		BattleManager.battle_area_size.x / SP_GRID_SIZE.x,
		BattleManager.battle_area_size.y / SP_GRID_SIZE.y)


static func _sp_add_to_grid(p_bullet: Bullet, p_cell: Vector2i):
	p_bullet.sp_last_cell = p_cell
	p_bullet.sp_cell_prev = null
	p_bullet.sp_cell_next = _sp_cell_list[p_cell.x][p_cell.y]
	_sp_cell_list[p_cell.x][p_cell.y] = p_bullet
	
	if p_bullet.sp_cell_next != null:
		p_bullet.sp_cell_next.sp_cell_prev = p_bullet


static func _sp_remove_bullet_from_cell(p_bullet: Bullet, p_old_cell: Vector2i):
	if p_bullet.sp_cell_prev != null:
		p_bullet.sp_cell_prev.sp_cell_next = p_bullet.sp_cell_next
	
	if p_bullet.sp_cell_next != null:
		p_bullet.sp_cell_next.sp_cell_prev = p_bullet.sp_cell_prev
	
	if _sp_cell_list[p_old_cell.x][p_old_cell.y] == p_bullet:
		_sp_cell_list[p_old_cell.x][p_old_cell.y] = p_bullet.sp_cell_next


# Private methods ✦ Rendering

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
			bullet.get_color()
		)


# Private methods ✦ Debugging

static func _debug_update_bullet_count():
	BattleDebugManager.update_bullet_count(_debug_active_bullet_count)


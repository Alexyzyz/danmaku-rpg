class_name BattleBulletManager
extends Node2D

const BULLET_MAX_COUNT: int = 2000
const SP_GRID_SIZE: Vector2i = Vector2i(20, 26)
const SP_GRID_PADDING: int = 0

static var _active_bullet_ll: BulletLinkedList
static var _inactive_bullet_ll: BulletLinkedList

static var _sp_cell_list = []
static var _sp_cell_size: Vector2

@onready var _debug_bullet_drop_shadow: Texture2D = preload("res://sprites/bullets/spr_bullet_0_dropshadow.png")

# Main methods

func _ready():
	_sp_set_up_grid()
	_set_up_pool()

func _process(delta: float):
	_update_bullets(delta)
	_debug_update_bullet_count()
	queue_redraw()
	pass

func _physics_process(delta: float):
	pass

func _draw():
	var current_bullet: Bullet = _active_bullet_ll.get_head()
	while current_bullet != null:
		var texture: Texture2D = _debug_bullet_drop_shadow
		if texture == null:
			current_bullet = current_bullet.next
			continue
		
		var offset = texture.get_size() / 2.0
		draw_texture(
			texture,
			current_bullet.position - offset,
			Color(0, 0, 0, 0.8)
		)
		current_bullet = current_bullet.next
	
	# NOTE: Experimental
	# Trying out adding in drop shadow by rendering in two passes
	
	current_bullet = _active_bullet_ll.get_head()
	while current_bullet != null:
		var texture = current_bullet.texture
		if texture == null:
			current_bullet = current_bullet.next
			continue
		
		var offset = texture.get_size() / 2.0
		draw_texture(
			texture,
			current_bullet.position - offset,
			Color(1, 1, 1, 1)
		)
		current_bullet = current_bullet.next

# Public methods

static func shoot_bullet(
	position: Vector2,
	angle: float,
	speed: float,
	texture: Texture2D) -> Bullet:
	
	var bullet: Bullet = _inactive_bullet_ll.get_tail()
	if bullet == null:
		return
	_inactive_bullet_ll.remove_node(bullet)
	_active_bullet_ll.push_head(bullet)
	
	bullet.set_up(position, UtilMath.get_vector_from_angle(angle), speed, texture)
	return bullet

static func shoot_bullet_ring(
	# Mandatory
	position: Vector2,
	angle: float,
	speed: float,
	texture: Texture2D,
	bullet_count: int,
	# Optional
	ring_radius: float = TAU,
	modify_bullet: Callable = func(bullet: Bullet, i: int): pass) -> Array[Bullet]:
	
	var bullet_list: Array[Bullet] = []
	var angle_step: float = ring_radius / bullet_count
	
	var angle_offset_even_offset: float = angle_step / 2 if bullet_count % 2 == 0 else angle_step
	var angle_offset: float = ring_radius - angle_step * (bullet_count / 2) - angle_offset_even_offset
	
	var curr_angle: float = angle - angle_offset
	for i in bullet_count:
		var new_bullet = shoot_bullet(position, curr_angle, speed, texture)
		if modify_bullet != null:
			modify_bullet.call(new_bullet, i)
		bullet_list.push_back(new_bullet)
		curr_angle += angle_step
	return bullet_list

# Private methods

func _set_up_pool():
	_active_bullet_ll = BulletLinkedList.new()
	_inactive_bullet_ll = BulletLinkedList.new()
	
	for i in BULLET_MAX_COUNT:
		var new_bullet = Bullet.new(self)
		_inactive_bullet_ll.push_tail(new_bullet)
	

func _update_bullets(delta: float):
	var current_bullet: Bullet = _active_bullet_ll.get_head()
	while current_bullet != null:
		var new_position: Vector2 = current_bullet.update(delta)
		_sp_update_grid(current_bullet, new_position)
		current_bullet = current_bullet.next

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

func _sp_set_up_grid():
	for i in SP_GRID_SIZE.x + SP_GRID_PADDING + 1:
		_sp_cell_list.append([])
		for j in SP_GRID_SIZE.y + SP_GRID_PADDING + 1:
			_sp_cell_list[i].append(null)
	
	_sp_cell_size = Vector2(
		BattleManager.battle_area_size.x / SP_GRID_SIZE.x,
		BattleManager.battle_area_size.y / SP_GRID_SIZE.y)

func _sp_update_grid(bullet: Bullet, new_pos: Vector2):
	# Destroy the bullet if it strays outside of the grid
	var new_cell = _sp_get_cell(new_pos)
	if _sp_is_cell_oob(new_cell):
		_sp_handle_destroyed_bullet(bullet)
		return
	
	# No need to update if the bullet is still in the same cell
	var old_cell = bullet.sp_last_cell
	if old_cell.x == new_cell.x and old_cell.y == new_cell.y:
		return
	
	# Update if the bullet changed cell
	_sp_remove_bullet_from_cell(bullet, old_cell)
	_sp_add_to_grid(bullet, new_cell)

func _sp_add_to_grid(bullet: Bullet, cell: Vector2i):
	bullet.sp_last_cell = cell
	bullet.sp_cell_prev = null
	bullet.sp_cell_next = _sp_cell_list[cell.x][cell.y]
	_sp_cell_list[cell.x][cell.y] = bullet
	
	if bullet.sp_cell_next != null:
		bullet.sp_cell_next.sp_cell_prev = bullet

func _sp_handle_destroyed_bullet(bullet: Bullet):
	var last_cell = bullet.sp_last_cell
	
	if !_sp_is_cell_oob(last_cell):
		_sp_remove_bullet_from_cell(bullet, last_cell)
	
	_active_bullet_ll.remove_node(bullet)
	_inactive_bullet_ll.push_tail(bullet)
	

func _sp_remove_bullet_from_cell(bullet: Bullet, old_cell: Vector2i):
	if bullet.sp_cell_prev != null:
		bullet.sp_cell_prev.sp_cell_next = bullet.sp_cell_next
	
	if bullet.sp_cell_next != null:
		bullet.sp_cell_next.sp_cell_prev = bullet.sp_cell_prev
	
	if _sp_cell_list[old_cell.x][old_cell.y] == bullet:
		_sp_cell_list[old_cell.x][old_cell.y] = bullet.sp_cell_next

func _sp_get_cell(position: Vector2) -> Vector2i:
	var cell_x: int = (int)(position.x / _sp_cell_size.x)
	var cell_y: int = (int)(position.y / _sp_cell_size.y)
	return Vector2i(cell_x, cell_y)

func _sp_is_cell_oob(cell: Vector2i) -> bool:
	return cell.x < 0 or cell.y < 0 \
		or cell.x > SP_GRID_SIZE.x + SP_GRID_PADDING \
		or cell.y > SP_GRID_SIZE.y + SP_GRID_PADDING

func _debug_update_bullet_count():
	var current_bullet: Bullet = _active_bullet_ll.get_head()
	var i: int = 0
	while current_bullet != null:
		i += 1
		current_bullet = current_bullet.next
	BattleDebugManager.update_bullet_count(i)

# Subclasses

class BulletLinkedList:
	var head: Bullet
	var tail: Bullet
	
	func push_head(node: Bullet):
		if head == null:
			head = node
			tail = node
			return
		
		node.next = head
		head.prev = node
		head = node
	
	func push_tail(node: Bullet):
		if head == null:
			head = node
			tail = node
			return
		
		tail.next = node
		node.prev = tail
		tail = node
	
	func get_head() -> Bullet:
		return head
	
	func get_tail() -> Bullet:
		return tail
	
	func remove_node(node: Bullet):
		# Case with ZERO nodes
		if head == null and tail == null:
			return
		
		# Case with only ONE node
		# serving as both the head and the tail
		if node == head and node == tail:
			head = null
			tail = null
			return
		
		# Case with only TWO nodes
		# The head and the tail
		elif node == head:
			if node.next != null:
				node.next.prev = null
				head = node.next
		elif node == tail:
			if node.prev != null:
				node.prev.next = null
				tail = node.prev
		
		# Case with MORE nodes
		else:
			if node.next != null:
				node.next.prev = node.prev
			
			if node.prev != null:
				node.prev.next = node.next
	

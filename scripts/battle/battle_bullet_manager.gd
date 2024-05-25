class_name BattleBulletManager
extends Node2D

const BULLET_MAX_COUNT: int = 10 # 2000
const SP_GRID_SIZE: Vector2i = Vector2i(20, 26)
const SP_GRID_PADDING: int = 0

static var _active_bullet_ll: BulletLinkedList
static var _inactive_bullet_ll: BulletLinkedList

static var _bullet_to_be_spawned_list: Array[Callable]
static var _bullet_to_be_destroyed_list: Array[Bullet]

static var _sp_cell_list = []
static var _sp_cell_size: Vector2

@onready var _debug_bullet_drop_shadow: Texture2D = preload("res://sprites/bullets/spr_bullet_0_dropshadow.png")

var debug_last_thing: String

# Main methods

func _ready():
	_set_up_sp_grid()
	_set_up_pool()

func _process(delta: float):
	_active_bullet_ll.iterate(_update_bullets.bind(delta))
	
	_spawn_bullets()
	_clear_bullets()
	
	_debug_update_bullet_count()
	queue_redraw()
	pass

func _physics_process(delta: float):
	pass

func _draw():
	_active_bullet_ll.iterate(_draw_bullets_drop_shadow)
	
	# NOTE: Experimental
	# Trying out adding in drop shadow by rendering in two passes
	
	_active_bullet_ll.iterate(_draw_bullets)

func _draw_bullets_drop_shadow(bullet: Bullet):
	var texture: Texture2D = _debug_bullet_drop_shadow
	if texture == null:
		return
	var offset = texture.get_size() / 2.0
	draw_texture(
		texture,
		bullet.position - offset,
		Color(0, 0, 0, 0.8)
	)

func _draw_bullets(bullet: Bullet):
	var texture: Texture2D = bullet.texture
	if texture == null:
		return
	var offset = texture.get_size() / 2.0
	draw_texture(
		texture,
		bullet.position - offset,
		bullet.get_graze_modulation()
	)

# Public methods

static func shoot_bullet(
	position: Vector2,
	angle: float,
	speed: float,
	texture: Texture2D) -> Bullet:
	
	var bullet: Bullet = _inactive_bullet_ll.get_tail()
	if bullet == null:
		return
	
	bullet.set_up(position, UtilMath.get_vector_from_angle(angle), speed, texture)
	
	_inactive_bullet_ll.remove_node(bullet)
	_active_bullet_ll.push_tail(bullet)
	
	# DANGER:
	# This probably won't return the bullet reference in a usable way
	# because the spawn method gets called later
	return bullet

static func _queue_spawn_bullet(bullet: Bullet, position: Vector2, angle: float, speed: float, texture: Texture2D):
	_inactive_bullet_ll.remove_node(bullet)
	_active_bullet_ll.push_tail(bullet)
	
	bullet.set_up(position, UtilMath.get_vector_from_angle(angle), speed, texture)

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

static func destroy_bullet(bullet: Bullet):
	var last_cell = bullet.sp_last_cell
	
	if !sp_is_cell_oob(last_cell):
		_sp_remove_bullet_from_cell(bullet, last_cell)
	
	_active_bullet_ll.remove_node(bullet)
	_inactive_bullet_ll.push_tail(bullet)

static func sp_get_bullet_in_cell(cell: Vector2i) -> Bullet:
	if sp_is_cell_oob(cell):
		print("get_bullet_in_cell(): Cell position out of bounds!")
		return null
	var obj = _sp_cell_list[cell.x][cell.y]
	if is_instance_valid(obj):
		return obj
	return null

static func sp_get_bullet_in_position(position: Vector2) -> Bullet:
	var cell: Vector2i = sp_get_cell(position)
	return sp_get_bullet_in_cell(cell)

static func sp_get_bullet_in_cells_surrounding(position: Vector2) -> Array[Bullet]:
	var center_cell: Vector2i = sp_get_cell(position)
	var cell_list: Array[Bullet] = []
	
	for x_offset in 3:
		for y_offset in 3:
			var offset: Vector2i = Vector2i(x_offset - 1, y_offset - 1)
			var cell: Vector2i = center_cell + offset
			if sp_is_cell_oob(center_cell + offset):
				continue
			cell_list.append(sp_get_bullet_in_cell(cell))
	
	return cell_list

static func sp_get_cell(position: Vector2) -> Vector2i:
	var cell_x: int = (int)(position.x / _sp_cell_size.x)
	var cell_y: int = (int)(position.y / _sp_cell_size.y)
	return Vector2i(cell_x, cell_y)

static func sp_is_cell_oob(cell: Vector2i) -> bool:
	return cell.x < 0 or cell.y < 0 \
		or cell.x > SP_GRID_SIZE.x + SP_GRID_PADDING \
		or cell.y > SP_GRID_SIZE.y + SP_GRID_PADDING

# Private methods

func _set_up_pool():
	_active_bullet_ll = BulletLinkedList.new(0)
	_inactive_bullet_ll = BulletLinkedList.new(1)
	
	for i in BULLET_MAX_COUNT:
		var new_bullet: Bullet = Bullet.new(self)
		new_bullet.debug_index = i
		_inactive_bullet_ll.push_tail(new_bullet, false)

func _update_bullets(bullet: Bullet, delta: float):
	var new_position: Vector2 = bullet.update(delta)
	_sp_update_grid(bullet, new_position)

func _spawn_bullets():
	var spawn_call: Callable
	while _bullet_to_be_spawned_list.size() > 0:
		spawn_call = _bullet_to_be_spawned_list.pop_back()
		spawn_call.call()

func _clear_bullets():
	# DANGER:
	# There's currently a bug that causes cycles to form in these linked lists.
	# This is urgent and catastrophically game-breaking.
	# Please spend time to work on fixing it.
	
	var bullet: Bullet = _bullet_to_be_destroyed_list.pop_back()
	while bullet != null:
		destroy_bullet(bullet)
		bullet = _bullet_to_be_destroyed_list.pop_back()

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

func _set_up_sp_grid():
	for i in SP_GRID_SIZE.x + SP_GRID_PADDING + 1:
		_sp_cell_list.append([])
		for j in SP_GRID_SIZE.y + SP_GRID_PADDING + 1:
			_sp_cell_list[i].append(null)
	
	_sp_cell_size = Vector2(
		BattleManager.battle_area_size.x / SP_GRID_SIZE.x,
		BattleManager.battle_area_size.y / SP_GRID_SIZE.y)

func _sp_update_grid(bullet: Bullet, new_pos: Vector2):
	# Destroy the bullet if it strays outside of the grid
	var new_cell = sp_get_cell(new_pos)
	if sp_is_cell_oob(new_cell):
		_bullet_to_be_destroyed_list.push_back(bullet)
		# destroy_bullet(bullet)
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

static func _sp_remove_bullet_from_cell(bullet: Bullet, old_cell: Vector2i):
	if bullet.sp_cell_prev != null:
		bullet.sp_cell_prev.sp_cell_next = bullet.sp_cell_next
	
	if bullet.sp_cell_next != null:
		bullet.sp_cell_next.sp_cell_prev = bullet.sp_cell_prev
	
	if _sp_cell_list[old_cell.x][old_cell.y] == bullet:
		_sp_cell_list[old_cell.x][old_cell.y] = bullet.sp_cell_next

func _debug_update_bullet_count():
	var current_bullet: Bullet = _active_bullet_ll.head
	var i: int = 0
	while current_bullet != null:
		i += 1
		current_bullet = current_bullet.next
	BattleDebugManager.update_bullet_count(i)

# Subclasses

class BulletLinkedList:
	var head: Bullet = null
	var tail: Bullet = null
	
	var debug_stack: int
	
	var on_cycle_detected: Callable
	
	func _init(debug_stack: int, on_cycle_detected: Callable = func(): get_tree().quit()):
		self.debug_stack = debug_stack
		self.on_cycle_detected = on_cycle_detected
	
	func get_chain() -> String:
		var seen_nodes: Array[Bullet] = []
		var current: Bullet = head
		var prev: Bullet = null
		var text: String = "NULL"
		var i: int = 0
		
		while current != null:
			var bullet_text: String = current.debug_stack + str(current.debug_index)
			if current == head:
				bullet_text = "[" + bullet_text + "]"
			elif current == tail:
				bullet_text = "(" + bullet_text + ")"
			
			if prev != null:
				if current.prev == prev:
					text += " <> " + bullet_text
				else:
					text += " > " + bullet_text
			else:
				text += " < " + bullet_text
			
			if current in seen_nodes:
				print("Cycle exists with run-length " + str(i) + "\n" + text + ", CYCLE!")
				on_cycle_detected.call()
				return ""
			
			seen_nodes.push_back(current)
			prev = current
			current = current.next
			i += 1
		
		return "No cycle!\n" + text + " > NULL"
	
	func push_tail(node: Bullet, debug: bool = true):
		var culprit: String = node.debug_stack + str(node.debug_index)
		var case: String = "Just went in."
		var before: String = "BEFORE\n" + get_chain() + "\n\n"
		var after: String
		
		if node == null:
			if debug:
				after = "AFTER\n" + get_chain() + "\n\n"
				print("PUSH_TAIL()\n" + case + "\n\n" + before + after)
			return
		
		node.next = null
		node.prev = null
		
		# Case with ZERO nodes
		if head == null or tail == null:
			head = node
			tail = node
			case = "Case of ZERO nodes."
		
		# Case with ONE node
		elif head == tail:
			head.next = node
			node.prev = head
			tail = node
			case = "Case of ONE node."
		
		# Case with MORE nodes
		else:
			tail.next = node
			node.prev = tail
			tail = node
			case = "Case of MORE nodes"
		
		node.head = head
		
		self.debug_stack = debug_stack
		node.debug_stack = "A" if debug_stack == 0 else "B"
		
		if debug:
			var chain: String = get_chain()
			after = "AFTER\n" + chain + "\n\n"
			print("PUSH_TAIL(" + culprit + ")\n" + case + "\n\n" + before + after)
			if chain.ends_with("CYCLE!"):
				pass
	
	func get_tail() -> Bullet:
		return tail
	
	func iterate(function: Callable, debug: bool = false):
		var text: String = ""
		var i: int = 0
		
		var current: Bullet = head
		while current != null:
			text += current.debug_stack + str(current.debug_index) + " -> "
			i += 1
			if i > 500:
				# print(text)
				break
			
			function.call(current)
			current = current.next
		
		if debug:
			print(i)
	
	func remove_node(node: Bullet):
		var culprit: String = node.debug_stack + str(node.debug_index)
		var case: String = "Just went in."
		var before: String = "BEFORE\n" + get_chain() + "\n\n"
		var after: String
		
		if node.head != head:
			print("STRAY BULLET ALERT")
			return
		
		# Case with ZERO nodes
		if head == null:
			after = "AFTER\n" + get_chain() + "\n\n"
			print("REMOVE_NODE()\n" + case + "\n\n" + before + after)
			return
		
		# Case with ONE node
		elif head == tail:
			head = null
			tail = null
			case = "Case of ONE node."
		
		# Case with TWO nodes
		elif node == head:
			head = node.next
			if head != null:
				head.prev = null
				if head.next == null:
					tail = head
			case = "Case of TWO nodes."
		
		elif node == tail:
			tail = node.prev
			if tail != null:
				tail.next = null
				if tail.prev == null:
					head = tail
			case = "Case of TWO nodes."
		
		# Case with MORE nodes
		else:
			if node.next != null:
				node.next.prev = node.prev
			if node.prev != null:
				node.prev.next = node.next
			case = "Case of MORE nodes."
		
		node.head = null
		
		after = "AFTER\n" + get_chain() + "\n\n"
		print("REMOVE NODE(" + culprit + ")\n" + case + "\n\n" + before + after)

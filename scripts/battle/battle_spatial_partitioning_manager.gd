class_name SpatialPartitioningManager

const _SP_GRID_SIZE = Vector2i(20, 26)
const _SP_GRID_PADDING = 0

var _sp_cell_list = []
var _sp_cell_size: Vector2

var _obj_prefab: PackedScene
var _obj_parent: Node
var _obj_inactive_pool: Array[Node2D]
var _obj_max_count: int

# Main methods

func _init(
	# Mandatory
	prefab: PackedScene,
	parent: Node,
	max_count: int,
	# Optional
	partitions: Vector2i = _SP_GRID_SIZE):
	_obj_prefab = prefab
	_obj_parent = parent
	_obj_max_count = max_count
	
	_set_up_sp_grid()
	_populate_obj_pool()

# Public methods

func spawn_obj(position: Vector2) -> Node2D:
	var cell = get_cell(position)
	if is_cell_oob(cell):
		return
	
	var obj = _obj_inactive_pool.pop_front()
	if obj == null:
		return
	
	obj.enable()
	_add_to_sp_grid(obj, get_cell(position))
	return obj

func handle_destroyed_obj(obj: Node2D):
	var last_cell = obj.sp_last_cell
	
	if !is_cell_oob(last_cell):
		_remove_obj_from_cell(obj, last_cell)
	
	obj.disable()
	_obj_inactive_pool.push_back(obj)

func update_sp_grid(obj: Node2D, new_pos: Vector2):
	# Destroy the object if it strayed outside the grid
	var new_cell = get_cell(new_pos)
	if is_cell_oob(new_cell):
		handle_destroyed_obj(obj)
		return
	
	# No need to update if the object is still in the same cell
	var old_cell = obj.sp_last_cell
	if old_cell.x == new_cell.x and old_cell.y == new_cell.y:
		return
	
	# Update if the object changed cell
	_remove_obj_from_cell(obj, old_cell)
	_add_to_sp_grid(obj, new_cell)

func get_obj_in_cell(cell: Vector2i) -> Node2D:
	if is_cell_oob(cell):
		print("get_obj_in_cell(): Cell position out of bounds!")
		return null
	var obj = _sp_cell_list[cell.x][cell.y]
	if is_instance_valid(obj):
		return obj
	return null

func get_obj_in_position(position: Vector2) -> Node2D:
	var cell: Vector2i = get_cell(position)
	return get_obj_in_cell(cell)

func get_obj_in_cells_surrounding(position: Vector2) -> Array[Node2D]:
	var center_cell = get_cell(position)
	var cell_list: Array[Node2D] = []
	
	for x_offset in 3:
		for y_offset in 3:
			var offset = Vector2i(x_offset - 1, y_offset - 1)
			var cell = center_cell + offset
			if is_cell_oob(center_cell + offset):
				continue
			cell_list.append(get_obj_in_cell(cell))
	
	return cell_list

func get_cell(position: Vector2) -> Vector2i:
	var cell_x: int = (int)(position.x / _sp_cell_size.x)
	var cell_y: int = (int)(position.y / _sp_cell_size.y)
	return Vector2i(cell_x, cell_y)

func is_cell_oob(cell: Vector2i) -> bool:
	return cell.x < 0 or cell.y < 0 \
		or cell.x > _SP_GRID_SIZE.x + _SP_GRID_PADDING \
		or cell.y > _SP_GRID_SIZE.y + _SP_GRID_PADDING

func get_active_obj_count() -> int:
	return _obj_max_count - _obj_inactive_pool.size()

# Private methods

func _set_up_sp_grid():
	var SAFETY_PADDING = 1
	for i in _SP_GRID_SIZE.x + _SP_GRID_PADDING + SAFETY_PADDING:
		_sp_cell_list.append([])
		for j in _SP_GRID_SIZE.y + _SP_GRID_PADDING + SAFETY_PADDING:
			_sp_cell_list[i].append(null)
	
	_sp_cell_size = Vector2(
		BattleManager.battle_area_size.x / _SP_GRID_SIZE.x,
		BattleManager.battle_area_size.y / _SP_GRID_SIZE.y)

func _populate_obj_pool():
	for i in _obj_max_count:
		var new_obj: Node2D = _obj_prefab.instantiate()
		new_obj.set_process(false)
		new_obj.name = "Object"
		new_obj.sp_manager = self
		
		_obj_parent.add_child(new_obj)
		_obj_inactive_pool.push_back(new_obj)

func _add_to_sp_grid(obj: Node2D, cell: Vector2i):	
	obj.sp_last_cell = cell
	obj.sp_cell_prev = null
	obj.sp_cell_next = _sp_cell_list[cell.x][cell.y]
	_sp_cell_list[cell.x][cell.y] = obj
	
	if obj.sp_cell_next != null:
		obj.sp_cell_next.sp_cell_prev = obj

func _remove_obj_from_cell(obj: Node2D, old_cell: Vector2i):
	if obj.sp_cell_prev != null:
		obj.sp_cell_prev.sp_cell_next = obj.sp_cell_next
	
	if obj.sp_cell_next != null:
		obj.sp_cell_next.sp_cell_prev = obj.sp_cell_prev
	
	if _sp_cell_list[old_cell.x][old_cell.y] == obj:
		_sp_cell_list[old_cell.x][old_cell.y] = obj.sp_cell_next

class_name BattleEnemyTimekeeperFast
extends Node2D

const MAX_HEALTH: float = 200
const TIMEKEEPING_RADIUS: float = 150

var _parent: Node2D
var _angle: float
var _angle_speed: float
var _angle_acceleration: float
var _angle_acceleration_change_alarm: float

# Public methods

func set_up():
	_parent = get_parent()
	pass


func update(p_delta: float):
	_move(p_delta)
	_handle_time()
	pass


# Private methods

func _move(p_delta: float):
	if _angle_acceleration_change_alarm > 0:
		_angle_acceleration_change_alarm -= p_delta
	else:
		var offset: float = PI / 16
		_angle_acceleration = randf_range(-offset, offset)
		_angle_acceleration_change_alarm = randf_range(1, 3)
	
	_angle_speed += p_delta * _angle_acceleration
	_angle += p_delta * _angle_speed
	
	var dir: Vector2 = UtilMath.get_vector_from_angle(_angle)
	var new_pos: Vector2 = _parent.position + p_delta * 50 * dir
	_parent.position = new_pos.clamp(Vector2.ZERO, BattleManager.battle_area_size)


func _handle_time():
	var tile_radius: int = int(TIMEKEEPING_RADIUS / BattleBulletManager.sp_get_cell_size().y)
	
	var bullet_list: Array[Bullet] = \
			BattleBulletManager.sp_get_bullet_in_cells_surrounding(
				_parent.position, 2 * tile_radius)
	
	for head_bullet in bullet_list:
		var bullet: Bullet = head_bullet
		while bullet != null:
			var bullet_distance: float = (bullet.position - _parent.position).length()
			var t: float = min(1, bullet_distance / (0.8 * TIMEKEEPING_RADIUS))
			
			var scale_value: float = lerpf(1.6, 1, t)
			bullet.delta_scale = scale_value * scale_value * scale_value
			bullet = bullet.sp_cell_next


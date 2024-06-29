class_name Bullet

const HITBOX_RADIUS: float = 2

var position: Vector2
var prev_position: Vector2
var direction: Vector2

var speed: float
var max_speed: float = INF
var acceleration: float

var is_deadly: bool
var delta_scale: float
# Rendering
var resource: BulletResource
var color: Color
# Custom behavior per tick
var behavior

# Object pooling stuff
var is_active: bool
var next_inactive: Bullet
# Bullet spatial partitioning
var sp_cell_next: Bullet
var sp_cell_prev: Bullet
var sp_last_cell: Vector2i

var _move_per_tick: bool
var _graze_modulation_t: float

# Public methods

func set_up(
	p_position: Vector2,
	p_direction: Vector2,
	p_speed: float,
	p_resource: BulletResource):
	
	position = p_position
	prev_position = p_position
	direction = p_direction
	speed = p_speed
	max_speed = INF
	acceleration = 0
	
	resource = p_resource
	color = Color.WHITE
	
	is_deadly = true
	delta_scale = 1
	
	behavior = null
	_move_per_tick = true


func update(p_delta: float):
	if !is_active:
		return
	_update_graze()
	
	var scaled_delta: float = delta_scale * p_delta
	if _move_per_tick:
		_move(scaled_delta)
	if behavior != null:
		if behavior.has_method("update"):
			behavior.update(p_delta)


func toggle_move_per_tick(p_state: bool):
	_move_per_tick = p_state


func move_to(p_new_pos: Vector2):
	if !is_active:
		return
	prev_position = position
	BattleBulletManager.sp_update_grid(self, p_new_pos)
	position = p_new_pos


func rotate(p_angle: float):
	if !is_active:
		return
	direction = direction.rotated(p_angle)


func set_rotation(p_angle: float):
	if !is_active:
		return
	direction = direction.rotated(p_angle - direction.angle())


func graze():
	if !is_active:
		return
	_graze_modulation_t = 1.0


func destroy():
	BattleBulletManager.sp_destroy_bullet(self)


func get_rect():
	return Rect2(
		position.x - HITBOX_RADIUS,
		position.y - HITBOX_RADIUS,
		position.x + HITBOX_RADIUS,
		position.y + HITBOX_RADIUS).abs()


func get_rect_midway_pos():
	var midway_pos: Vector2 = (position - prev_position) / 2
	return Rect2(
		midway_pos.x - HITBOX_RADIUS,
		midway_pos.y - HITBOX_RADIUS,
		midway_pos.x + HITBOX_RADIUS,
		midway_pos.y + HITBOX_RADIUS).abs()


func get_color() -> Color:
	return color - _graze_modulation_t * 0.1 * Color.WHITE


# Private methods

func _move(p_delta: float):
	speed = min(speed + p_delta * acceleration, max_speed)
	if speed == 0:
		return
	
	prev_position = position
	var new_pos: Vector2 = position + p_delta * speed * direction
	BattleBulletManager.sp_update_grid(self, new_pos)
	position = new_pos
	# TODO: Re-add logic for rotation here.


func _update_graze():
	if _graze_modulation_t > 0.01:
		_graze_modulation_t = lerpf(_graze_modulation_t, 0, 0.2)
	else:
		_graze_modulation_t = 0


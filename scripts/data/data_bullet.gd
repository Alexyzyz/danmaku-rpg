class_name Bullet

const HITBOX_RADIUS: float = 2

var manager: BattleBulletManager

var position: Vector2
var last_position: Vector2
var direction: Vector2

var speed: float
var max_speed: float = INF
var acceleration: float

# Rendering
var texture: Texture2D

# Custom behavior per tick
var on_tick: Callable

# Bullet linked list
var head: Bullet
var next: Bullet
var prev: Bullet

# Bullet spatial partitioning
var sp_cell_next: Bullet
var sp_cell_prev: Bullet
var sp_last_cell: Vector2i

# Debug purposes
var debug_index: int = 0
var debug_stack: String = "A"

var _graze_modulation_t: float

# Main methods

func _init(manager: BattleBulletManager):
	self.manager = manager

# Public methods

func set_up(
	position: Vector2,
	direction: Vector2,
	speed: float,
	texture: Texture2D):
	
	self.position = position
	self.direction = direction
	self.speed = speed
	self.texture = texture
	
	max_speed = INF
	acceleration = 0

func update(delta: float) -> Vector2:
	if _graze_modulation_t > 0.01:
		_graze_modulation_t = lerpf(_graze_modulation_t, 0, 0.2)
	else:
		_graze_modulation_t = 0
	
	speed = min(speed + delta * acceleration, max_speed)
	if speed == 0:
		return position
	
	last_position = position
	var new_position: Vector2 = position + speed * direction * delta
	position = new_position
	
	return new_position

func rotate(angle: float):
	direction = direction.rotated(angle)

func set_rotation(angle: float):
	direction = direction.rotated(angle - direction.angle())

func graze():
	_graze_modulation_t = 1.0

func destroy():
	BattleBulletManager.destroy_bullet(self)

func get_rect():
	return Rect2(
		position.x - HITBOX_RADIUS,
		position.y - HITBOX_RADIUS,
		position.x + HITBOX_RADIUS,
		position.y + HITBOX_RADIUS)

func get_rect_midway_pos():
	var midway_pos: Vector2 = (position - last_position) / 2
	return Rect2(
		midway_pos.x - HITBOX_RADIUS,
		midway_pos.y - HITBOX_RADIUS,
		midway_pos.x + HITBOX_RADIUS,
		midway_pos.y + HITBOX_RADIUS)

func get_graze_modulation() -> Color:
	return Color(1, 1, 1) - _graze_modulation_t * 0.1 * Color(1, 1, 1)

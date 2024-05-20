class_name Bullet

var manager: BattleBulletManager

var position: Vector2
var last_position: Vector2
var direction: Vector2

var speed: float
var max_speed: float = INF
var acceleration: float

var texture: Texture2D
var on_tick: Callable

var next: Bullet
var prev: Bullet

var sp_cell_next: Bullet
var sp_cell_prev: Bullet
var sp_last_cell: Vector2i

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

extends Node2D

var obj_battle_manager: battle_manager

var atk0_alarm: float
var atk0_angle: float

var atk1_alarm: float
var atk1_angle: float

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	shoot(delta)
	shoot_ring(delta)
	pass

func shoot(delta):
	if atk0_alarm > 0:
		atk0_alarm -= delta
		return
	atk0_alarm = 0.01
	atk0_angle = fmod(atk0_angle + 0.103, 1)
	
	obj_battle_manager.shoot_bullet_at_angle(position, atk0_angle, 1)

func shoot_ring(delta):
	if atk1_alarm > 0:
		atk1_alarm -= delta
		return
	atk1_alarm = 0.05
	atk1_angle = fmod(atk1_angle + 0.103, 1)
	
	var bullet_in_ring_count: float = 10
	var step: float = 1 / bullet_in_ring_count
	var ring_radius: float = 20
	
	for i in bullet_in_ring_count:
		var offset_angle = lerpf(0, 2 * PI, i * step)
		var offset = ring_radius * Vector2(cos(offset_angle), sin(offset_angle))
		print(offset)
		
		obj_battle_manager.shoot_bullet_at_angle(position + offset, atk1_angle, 2)

func set_up(manager):
	obj_battle_manager = manager

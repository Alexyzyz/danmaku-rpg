extends Node2D

var direction: Vector2
var speed: float

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	move(delta)

func move(delta):
	position += direction * speed

func set_up(pos: Vector2, dir: Vector2, spd: float):
	position = pos
	direction = dir
	speed = spd

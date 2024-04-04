extends Node2D

const BASE_SPEED: float = 300

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	move(delta)
	pass

func move(delta):
	var moved_right = 1 if Input.is_action_pressed("game_move_right") else 0
	var moved_left = 1 if Input.is_action_pressed("game_move_left") else 0
	var moved_up = 1 if Input.is_action_pressed("game_move_up") else 0
	var moved_down = 1 if Input.is_action_pressed("game_move_down") else 0
	
	var x_axis = moved_right - moved_left
	var y_axis = moved_up - moved_down
	var direction = Vector2(x_axis, -y_axis).normalized()
	
	position += BASE_SPEED * delta * direction

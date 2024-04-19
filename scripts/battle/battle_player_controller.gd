class_name BattlePlayer
extends Node2D

const BASE_SPEED: float = 300
const BASE_FOCUS_SPEED: float = 150

const GRAZE_RADIUS = 50

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_move(delta)
	_check_collision()
	pass

func _move(delta):
	var moved_right = 1 if Input.is_action_pressed("game_move_right") else 0
	var moved_left = 1 if Input.is_action_pressed("game_move_left") else 0
	var moved_up = 1 if Input.is_action_pressed("game_move_up") else 0
	var moved_down = 1 if Input.is_action_pressed("game_move_down") else 0
	
	var x_axis = moved_right - moved_left
	var y_axis = moved_up - moved_down
	var direction = Vector2(x_axis, -y_axis).normalized()
	
	var speed = BASE_FOCUS_SPEED if Input.is_action_pressed("game_focus") else BASE_SPEED
	var new_position = position + speed * delta * direction
	new_position.x = clamp(new_position.x, 0, BattleManager.battle_area_size.x)
	new_position.y = clamp(new_position.y, 0, BattleManager.battle_area_size.y)
	
	position = new_position

func _check_collision():
	var bullet_list: Array[BattleBullet] = BattleManager.get_bullet_in_cells_surrounding(position)
	var cell = BattleManager.get_cell(position)
	
	var list_length = 0
	
	for i in bullet_list.size():
		var bullet = bullet_list[i]
		while bullet != null:
			list_length += 1
			if list_length > 1000:
				print("[WARNING] Bullet count: " + str(list_length))
			
			var distance = (bullet.position - position).length()
			if distance < GRAZE_RADIUS:
				bullet.graze()
				# print("Grazed bullet within " + str(distance))
			bullet = bullet.collision_grid_next
	
	# print("Bullets in cells surrounding (" + str(cell.x) + "," + str(cell.y) + "): " + str(list_length))

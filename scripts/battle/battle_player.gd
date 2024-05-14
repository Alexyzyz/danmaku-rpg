class_name BattlePlayer
extends Node2D

const BASE_SPEED: float = 400
const BASE_FOCUS_SPEED: float = 150

const INVINCIBLE_TIME: float = 3
const GRAZE_RADIUS = 50
const HITBOX_RADIUS: float = 10

# Prefabs
@onready var prefab_shot: PackedScene = preload("res://prefabs/prefab_player_priest_shot.tscn")
# Children
@onready var child_sprite: Sprite2D = $Rig
@onready var child_hitbox: Sprite2D = $Hitbox

var is_focused: bool
var invincible_alarm: float

# Main methods

func _ready():
	pass # Replace with function body.

func _process(delta):
	_handle_move_inputs(delta)
	_handle_focus_input()
	_handle_invincibility(delta)
	_check_collision()
	pass

# Private methods

func _handle_shoot_input(delta):
	pass

func _handle_move_inputs(delta):
	var direction = UtilMovement.get_direction_vector()
	
	var speed = BASE_FOCUS_SPEED if is_focused else BASE_SPEED
	var new_position = position + speed * delta * direction
	new_position.x = clamp(new_position.x, 0, BattleManager.battle_area_size.x)
	new_position.y = clamp(new_position.y, 0, BattleManager.battle_area_size.y)
	
	position = new_position
	
	# Update the sprite
	
	if direction.x == 0:
		child_sprite.frame = 0
	else:
		child_sprite.frame = 1
		child_sprite.flip_h = direction.x < 0

func _handle_focus_input():
	is_focused = Input.is_action_pressed("game_focus")
	child_hitbox.visible = is_focused

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
				if distance < HITBOX_RADIUS:
					bullet.destroy()
					_handle_on_hit()
			bullet = bullet.sp_cell_next
	
	# print("Bullets in cells surrounding (" + str(cell.x) + "," + str(cell.y) + "): " + str(list_length))

func _handle_on_hit():
	if invincible_alarm > 0:
		return
	
	position = Vector2(BattleManager.battle_area_size.x / 2, BattleManager.battle_area_south_y - 100)
	invincible_alarm = INVINCIBLE_TIME

func _handle_invincibility(delta: float):
	if invincible_alarm > 0:
		invincible_alarm -= delta
		
		var flicker = int(10 * invincible_alarm) % 2 == 0
		print("flicker :: " + str(flicker))
		child_sprite.self_modulate.a = 0.75 if flicker else 1
		return
	child_sprite.self_modulate.a = 1
	

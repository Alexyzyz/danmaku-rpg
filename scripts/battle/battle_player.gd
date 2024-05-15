class_name BattlePlayer
extends Node2D

const BASE_SPEED: float = 400
const BASE_FOCUS_SPEED: float = 150

const INVINCIBLE_TIME: float = 3
const STOP_SHOOTING_TIME: float = 0.4
const SHOOT_TIME: float = 0.06

const GRAZE_RADIUS: float = 50
const HITBOX_RADIUS: float = 2

var _invincible_alarm: float
var _stop_shooting_alarm: float
var _shoot_alarm: float

var _is_shooting: bool
var _is_focused: bool

var _debug_grazed_count: int
var _debug_closest_distance: float

# Prefabs
@onready var prefab_shot: PackedScene = preload("res://prefabs/prefab_player_priest_shot.tscn")
# Children
@onready var child_sprite: Sprite2D = $Rig
@onready var child_hitbox: Sprite2D = $Hitbox

# Main methods

func _ready():
	pass # Replace with function body.

func _process(delta):
	_handle_shoot_input(delta)
	_handle_move_inputs(delta)
	_handle_focus_input()
	_handle_invincibility(delta)
	_check_collision()
	pass

# Private methods

func _handle_shoot_input(delta):
	if _stop_shooting_alarm > 0:
		_stop_shooting_alarm -= delta
	
	if _is_shooting:
		if _shoot_alarm > 0:
			_shoot_alarm -= delta
		else:
			if _stop_shooting_alarm > 0:
				_shoot_alarm = SHOOT_TIME
			else:
				_is_shooting = false
			BattleManager.player_shoot_shot()
	
	if Input.is_action_pressed("game_confirm"):
		_stop_shooting_alarm = STOP_SHOOTING_TIME
		_is_shooting = true

func _handle_move_inputs(delta):
	var direction = UtilMovement.get_direction_vector()
	
	var speed = BASE_FOCUS_SPEED if _is_focused else BASE_SPEED
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
	_is_focused = Input.is_action_pressed("game_focus")
	child_hitbox.visible = _is_focused

func _check_collision():
	var bullet_list: Array[Node2D] = BattleManager.sp_enemy_bullets.get_obj_in_cells_surrounding(position)
	var cell = BattleManager.sp_enemy_bullets.get_cell(position)
	
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
				if distance < HITBOX_RADIUS:
					# print("Grazed bullet within " + str(distance))
					bullet.destroy()
					_handle_on_hit()
			
			if distance < _debug_closest_distance:
				_debug_closest_distance = distance
			_debug_grazed_count += 1
			if _debug_grazed_count > 100:
				_debug_grazed_count = 0
				print("Closest distance: " + str(_debug_closest_distance))
				_debug_closest_distance = INF
			bullet = bullet.sp_cell_next
	
	# print("Bullets in cells surrounding (" + str(cell.x) + "," + str(cell.y) + "): " + str(list_length))

func _handle_on_hit():
	if _invincible_alarm > 0:
		return
	
	position = Vector2(BattleManager.battle_area_size.x / 2, BattleManager.battle_area_south_y - 100)
	_invincible_alarm = INVINCIBLE_TIME

func _handle_invincibility(delta: float):
	if _invincible_alarm > 0:
		_invincible_alarm -= delta
		
		var flicker = int(10 * _invincible_alarm) % 2 == 0
		child_sprite.self_modulate.a = 0.75 if flicker else 1
		return
	child_sprite.self_modulate.a = 1
	

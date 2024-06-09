class_name BattlePlayer
extends Node2D

const BASE_SPEED: float = 400
const BASE_FOCUS_SPEED: float = 150

const INVINCIBLE_TIME: float = 3

const SHOOT_TIME: float = 0.06

const SHOT_DAMAGE: float = 3

const AIM_NOTCHES: int = 32
const AIM_TICK_TIME: float = 0.01

const GRAZE_RADIUS: float = 50
const HITBOX_RADIUS: float = 3

var _invincible_alarm: float
var _stop_shooting_alarm: float
var _shoot_alarm: float

var _aim_angle: float = -PI / 2
var _aim_tick_alarm: float

var _is_shooting: bool
var _is_focused: bool
var _is_aiming: bool

var _debug_grazed_count: int
var _debug_closest_distance: float

# Prefabs
@onready var prefab_shot: PackedScene = preload("res://prefabs/prefab_player_priest_shot.tscn")
# Children
@onready var child_sprite: Sprite2D = $Rig
@onready var child_hitbox: Sprite2D = $Hitbox

# Main methods

func _ready():
	pass


# Public methods

func update(p_delta: float):
	if p_delta == 0:
		return
	
	_handle_shoot_input(p_delta)
	_handle_aim_inputs(p_delta)
	_handle_move_inputs(p_delta)
	_handle_focus_input()
	_handle_invincibility(p_delta)
	_check_collision()


func get_rect():
	return Rect2(
		position.x - HITBOX_RADIUS,
		position.y - HITBOX_RADIUS,
		position.x + HITBOX_RADIUS,
		position.y + HITBOX_RADIUS).abs()


# Private methods

func _handle_shoot_input(p_delta: float):	
	if Input.is_action_just_pressed("game_confirm"):
		_is_shooting = !_is_shooting
	
	if !_is_shooting:
		return
	
	if _shoot_alarm > 0:
		_shoot_alarm -= p_delta
		return
	_shoot_alarm = SHOOT_TIME
	BattleManager.player_shoot_shot(_aim_angle, SHOT_DAMAGE)


func _handle_aim_inputs(p_delta: float):
	var aim_left: int = 1 if Input.is_action_pressed("game_aim_left") else 0
	var aim_right: int = 1 if Input.is_action_pressed("game_aim_right") else 0
	var aim_axis: int = aim_right - aim_left
	
	if aim_axis == 0:
		_aim_tick_alarm = AIM_TICK_TIME
		return
	
	if _aim_tick_alarm > 0:
		_aim_tick_alarm -= p_delta
		return
	_aim_tick_alarm = AIM_TICK_TIME
	
	_aim_angle += aim_axis * TAU / AIM_NOTCHES


func _handle_move_inputs(p_delta: float):
	var direction = UtilMovement.get_direction_vector()
	
	var speed = BASE_FOCUS_SPEED if _is_focused else BASE_SPEED
	var new_position = position + p_delta * speed * direction
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
	var bullet_list: Array[Bullet] = \
			BattleBulletManager.sp_get_bullet_in_cells_surrounding(position)
	
	for head_bullet in bullet_list:
		var bullet: Bullet = head_bullet
		while bullet != null:
			_check_collision_with_bullet(bullet)
			bullet = bullet.sp_cell_next
	
	# var cell = BattleBulletManager.sp_get_cell(position)
	# print("Bullets in cells surrounding (" + str(cell.x) + "," + str(cell.y) + "): " + str(debug_bullet_count))


func _check_collision_with_bullet(p_bullet: Bullet):
	if !p_bullet.is_deadly:
		p_bullet = p_bullet.sp_cell_next
		return
	
	# PHASE 1 ✦ Bounding box check
	if !get_rect().intersects(p_bullet.get_rect()) and \
		!get_rect().intersects(p_bullet.get_rect_midway_pos()):
		p_bullet = p_bullet.sp_cell_next
		return
	
	# PHASE 2 ✦ Distance check
	var distance: float = (p_bullet.position - position).length()
	if distance < GRAZE_RADIUS:
		p_bullet.graze()
	
	if distance < HITBOX_RADIUS + p_bullet.HITBOX_RADIUS:
		p_bullet.destroy()
		_handle_on_hit()
	else:
		var midway_distance = (p_bullet.prev_position - position).length()
		if midway_distance < HITBOX_RADIUS + p_bullet.HITBOX_RADIUS:
			p_bullet.destroy()
			_handle_on_hit()


func _handle_on_hit():
	if _invincible_alarm > 0:
		return
	# position = Vector2(BattleManager.battle_area_size.x / 2, BattleManager.battle_area_south_y - 100)
	BattleManager.handle_player_hit()
	_invincible_alarm = INVINCIBLE_TIME


func _handle_invincibility(p_delta: float):
	if _invincible_alarm > 0:
		_invincible_alarm -= p_delta
		
		var do_flicker: bool = int(10 * _invincible_alarm) % 2 == 0
		child_sprite.self_modulate.a = 0.6 if do_flicker else 1.0
		return
	child_sprite.self_modulate.a = 1


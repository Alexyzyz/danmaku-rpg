class_name BattlePlayer
extends Node2D

const BASE_SPEED: float = 400
const BASE_FOCUS_SPEED: float = 150

const INVINCIBLE_TIME: float = 3

const GRAZE_RADIUS: float = 50
const HITBOX_RADIUS: float = 3

var _shot_manager: Node2D
var _is_focused: bool
var _invincible_alarm: float
var _move_dir: Vector2

var _debug_grazed_count: int
var _debug_closest_distance: float

@onready var child_sprite: Sprite2D = $Rig
@onready var child_hitbox: Sprite2D = $Hitbox

# Main methods

func set_up(p_shot_manager_prefab: PackedScene):
	var shot_manager: Node2D = p_shot_manager_prefab.instantiate()
	shot_manager.set_up()
	_shot_manager = shot_manager
	add_child(shot_manager)


# Public methods

func update(p_delta: float):
	if p_delta == 0:
		return
	
	_handle_shoot(p_delta)
	_handle_move_inputs(p_delta)
	_handle_focus_input()
	_handle_invincibility(p_delta)
	_update_position(p_delta)
	_check_collision()


func get_projectiles() -> Array[Node2D]:
	return _shot_manager.get_projectiles()


func get_rect():
	return Rect2(
		position.x - HITBOX_RADIUS,
		position.y - HITBOX_RADIUS,
		position.x + HITBOX_RADIUS,
		position.y + HITBOX_RADIUS).abs()


func push(p_push_dir: Vector2):
	_move_dir += p_push_dir


# Private methods

func _handle_shoot(p_delta: float):
	_shot_manager.update(p_delta)


func _handle_move_inputs(_p_delta: float):
	var direction = UtilMovement.get_direction_vector()
	var speed = BASE_FOCUS_SPEED if _is_focused else BASE_SPEED
	_move_dir += speed * direction
	
	# Update the sprite
	if direction.x == 0:
		child_sprite.frame = 0
	else:
		child_sprite.frame = 1
		child_sprite.flip_h = direction.x < 0


func _handle_focus_input():
	_is_focused = Input.is_action_pressed("game_focus")
	child_hitbox.visible = _is_focused


func _update_position(p_delta: float):
	var new_position = position + p_delta * _move_dir
	new_position.x = clamp(new_position.x, 0, BattleManager.battle_area_size.x)
	new_position.y = clamp(new_position.y, 0, BattleManager.battle_area_size.y)
	
	position = new_position
	_move_dir = Vector2.ZERO


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


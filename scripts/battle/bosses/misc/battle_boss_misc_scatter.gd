class_name BattleBossMiscScatter
extends Node2D

const MAX_HEALTH: float = 200
const SCATTER_WAVE_TIME: float = 4

var _parent: Node2D
var _scatter_wave_alarm: float
var _attack_scatter: AttackScatter

# Main methods

func set_up():
	_parent = get_parent()
	_attack_scatter = AttackScatter.new()
	pass


func update(p_delta: float):
	_handle_attack_scatter(p_delta)
	_attack_scatter.update(p_delta)
	pass


# Private methods

func _handle_attack_scatter(p_delta: float):
	if _scatter_wave_alarm > 0:
		_scatter_wave_alarm -= p_delta
		return
	_scatter_wave_alarm = SCATTER_WAVE_TIME
	_attack_scatter.reset()
	pass

# Subclasses

class AttackScatter:
	const SCATTER_STRIP_COUNT: int = 20
	const SCATTER_STRIP_BULLET_COUNT: int = 10
	const SCATTER_TIME: float = 0
	const DISPERSE_TIME: float = 0.2
	
	var _parent: Node2D
	var _bullet_list: Array[Bullet]
	var _scatter_alarm: float
	var _scatter_index: int
	var _disperse_alarm: float
	
	# Public methods
	
	func update(p_delta: float):
		if _scatter_index > SCATTER_STRIP_COUNT:
			_disperse_bullets(p_delta)
			return
		
		if _scatter_alarm > 0:
			_scatter_alarm -= p_delta
			return
		_scatter_alarm = SCATTER_TIME
		
		_spawn_strip()
		_scatter_index += 1
	
	
	func reset():
		_scatter_index = 0
		_scatter_alarm = 0
		_disperse_alarm = DISPERSE_TIME
	
	
	# Private methods
	
	func _disperse_bullets(p_delta: float):
		if _disperse_alarm > 0:
			_disperse_alarm -= p_delta
			return
		
		for bullet in _bullet_list:
			bullet.speed = 0
			bullet.acceleration = 100
			bullet.max_speed = 10
		_bullet_list.clear()
	
	
	func _spawn_strip():
		var segment_width: float = \
				BattleManager.battle_area_size.x / SCATTER_STRIP_COUNT
		var segment_height: float = \
				BattleManager.battle_area_size.y / SCATTER_STRIP_BULLET_COUNT
		
		var strip_x: float = _scatter_index * segment_width
		
		for i in SCATTER_STRIP_BULLET_COUNT:
			var next_x: float = strip_x + randf_range(-segment_width / 2, segment_width / 2)
			var next_y: float = i * segment_height + randf_range(0, segment_height)
			
			var pos := Vector2(next_x, next_y)
			var distance_to_player: float = \
					(BattleManager.get_player().position - pos).length()
			if distance_to_player < 100:
				continue
			
			var angle: float = randf_range(0, TAU)
			
			var new_bullet: Bullet = BattleBulletManager.shoot_bullet(pos, angle, 0)
			if new_bullet != null:
				_bullet_list.push_back(new_bullet)

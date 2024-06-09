class_name BattleEnemyDandelionSeedling
extends Node2D

enum State {
	DORMANT,
	ACTIVE,
}

const GERMINATE_TIME: float = 8
const ACTIVE_SHOOT_TIME: float = 0.5

var _parent: BattleEnemy
var _direction: Vector2
var _base_speed: float
var _speed: float
var _state: State = State.DORMANT
var _germinate_alarm: float
var _active_shoot_alarm: float

# Main methods

func set_up():
	_parent = get_parent()
	_direction = UtilMath.get_vector_from_angle(randf_range(0, TAU))
	_base_speed = randf_range(10, 30)
	_speed = _base_speed
	_germinate_alarm = GERMINATE_TIME
	pass


func update(p_delta: float):
	_move(p_delta)
	if _state == State.DORMANT:
		_handle_state_dormant(p_delta)
	else:
		_handle_state_active(p_delta)
	pass


# Private methods

func _move(p_delta: float):
	_parent.position += p_delta * _speed * _direction
	pass


func _handle_state_dormant(p_delta: float):
	_germinate_alarm -= p_delta
	if _germinate_alarm > 0:
		var t: float = _germinate_alarm / GERMINATE_TIME
		if t < 0.1:
			var tt: float = (0.1 - t) / 0.1
			_speed = lerpf(_base_speed, 0, tt)
		return
	_state = State.ACTIVE
	_parent.blocks_shots = false
	_parent.modulate.a = 0.5
	_parent.set_health_display_alpha(0)
	_speed = 0


func _handle_state_active(p_delta: float):
	if _active_shoot_alarm > 0:
		_active_shoot_alarm -= p_delta
		return
	_active_shoot_alarm = ACTIVE_SHOOT_TIME
	
	var shoot_angle = randf_range(0, TAU)
	var shoot_speed = 25 # randf_range(10, 40)
	BattleBulletManager.shoot_bullet(
		_parent.position, shoot_angle, shoot_speed
	)
	pass

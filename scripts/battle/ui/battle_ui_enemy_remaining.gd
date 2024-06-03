class_name BattleUIEnemyRemaining
extends Control

const BLINK_TIME: float = 2
const BLINK_RATE: float = 6 * TAU
const BLINK_RANGE: float = 0.25

static var _blink_alarm: float
static var _blink_tick: float

static var _child_label: Label

@export var _color_start: Color
@export var _color_end: Color

# Main methods

func _ready():
	_child_label = $Label
	_child_label.self_modulate.a = 0

func _process(p_delta: float):
	_animate_text(p_delta)

# Public methods

static func show_enemy_remaining(p_enemy_count: int):
	_blink_alarm = BLINK_TIME
	if p_enemy_count == 1:
		_child_label.text = "LAST ONE!!"
		return
	_child_label.text = str(p_enemy_count) + " LEFT"

# Private methods

func _animate_text(p_delta: float):
	if _blink_alarm <= 0:
		return
	
	_child_label.self_modulate = lerp(_color_start, _color_end, 0.5 + 0.5 * sin(_blink_tick))
	_blink_tick = fmod(_blink_tick + BLINK_RATE * p_delta, TAU)
	
	_blink_alarm -= p_delta
	if _blink_alarm <= 0:
		_child_label.self_modulate.a = 0

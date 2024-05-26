class_name AlarmData

var alarm: float
var timer: float
var is_ticking: bool = true
var on_ring: Callable
var play_once: bool
var stop: bool

# Main methods

func _init(
	p_timer: float,
	p_alarm: float,
	p_on_ring: Callable,
	p_play_once: bool = false):
	
	alarm = p_alarm
	timer = p_timer
	on_ring = p_on_ring
	play_once = p_play_once

# Public methods

func tick(delta: float):
	if stop:
		return
	if alarm > 0:
		alarm -= delta
		return
	if !play_once:
		alarm = timer
	else:
		stop = true
	on_ring.call()

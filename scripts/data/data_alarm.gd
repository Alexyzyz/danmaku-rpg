class_name AlarmData

var alarm: float
var timer: float
var is_ticking: bool = true
var on_ring: Callable
var play_once: bool
var stop: bool

# Main methods

func _init(timer: float, alarm: float, on_ring: Callable, play_once: bool = false):
	self.alarm = alarm
	self.timer = timer
	self.on_ring = on_ring
	self.play_once = play_once

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

class_name AlarmData

var alarm: float
var timer: float
var is_ticking: bool = true
var on_ring: Callable

# Main methods

func _init(timer: float, alarm: float, on_ring: Callable):
	self.alarm = alarm
	self.timer = timer
	self.on_ring = on_ring

# Public methods

func tick(delta: float):
	if alarm > 0:
		alarm -= delta
		return
	alarm = timer
	on_ring.call()

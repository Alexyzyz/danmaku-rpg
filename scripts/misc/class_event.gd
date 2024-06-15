class_name Event

var on_update: Callable
var duration: float

func _init(p_duration: float, p_on_update: Callable = func (): pass):
	on_update = p_on_update
	duration = p_duration


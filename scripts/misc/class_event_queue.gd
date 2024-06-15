class_name EventQueue

var _queue: Array[Event]
var _index: int
var _current_event: Event
var _alarm: float
var _is_paused: bool

# Main methods

func _init(p_queue: Array[Event]):
	_queue = p_queue
	_handle_next_event()


# Public methods

func update(p_delta: float):
	if _alarm > 0:
		_alarm -= p_delta
		if _current_event.on_update != null:
			_current_event.on_update.call()
		return
	
	_index = UtilMath.clamp_scroll(_index, 1, 0, _queue.size() - 1)
	_handle_next_event()


# Private methods

func _handle_next_event():
	_current_event = _queue[_index]
	_alarm = _current_event.duration
	
	if _current_event.on_update != null:
		_current_event.on_update.call()


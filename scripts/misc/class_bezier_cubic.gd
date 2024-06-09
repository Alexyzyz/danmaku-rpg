class_name CubicBezier

var _p0: Vector2
var _p1: Vector2
var _p2: Vector2
var _p3: Vector2

var start: Vector2 :
	get:
		return _p0
	set(value):
		_p0 = value

var end: Vector2 :
	get:
		return _p3
	set(value):
		_p3 = value

var control_a: Vector2 :
	get:
		return _p1 - _p0
	set(value):
		_p1 = _p0 + value

var control_b: Vector2 :
	get:
		return _p3 - _p2
	set(value):
		_p2 = _p3 + value

# Main methods

func _init(start: Vector2, end: Vector2, control_a: Vector2, control_b: Vector2):
	self.start = start
	self.end = end
	
	self.control_a = control_a
	self.control_b = control_b

# Public methods

func interpolate(t: float) -> Vector2:
	var p: Vector2 = lerp(_p0, _p1, t)
	var q: Vector2 = lerp(_p1, _p2, t)
	var r: Vector2 = lerp(_p2, _p3, t)
	
	var a: Vector2 = lerp(p, q, t)
	var b: Vector2 = lerp(q, r, t)
	
	return lerp(a, b, t)

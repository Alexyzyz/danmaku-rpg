class_name DialogueBox
extends Node2D

var MID_CORNER_VERTEX_COUNT: int = 2
var VERTICES_PER_POLYGON: int = 8
var BOX_WIDTH: float = 250.0
var BOX_HEIGHT: float = 50.0

var _top_left: Vector2 = Vector2(-BOX_WIDTH, -BOX_HEIGHT)
var _top_right: Vector2 = Vector2(BOX_WIDTH, -BOX_HEIGHT)
var _bottom_left: Vector2 = Vector2(-BOX_WIDTH, BOX_HEIGHT)
var _bottom_right: Vector2 = Vector2(BOX_WIDTH, BOX_HEIGHT)

var _fixed_point_list_a: Array[Vector2] = [
	_top_left,
	_top_right,
	_bottom_right,
	_bottom_left,
]

var _fixed_point_list: Array[Vector2] = [
	lerp(_top_left, _top_right, 0.1),
	lerp(_top_left, _top_right, 0.5),
	lerp(_top_left, _top_right, 0.9),
	
	lerp(_top_right, _bottom_right, 0.1),
	lerp(_top_right, _bottom_right, 0.5),
	lerp(_top_right, _bottom_right, 0.9),
	
	lerp(_bottom_right, _bottom_left, 0.1),
	lerp(_bottom_right, _bottom_left, 0.5),
	lerp(_bottom_right, _bottom_left, 0.9),
	
	lerp(_bottom_left, _top_left, 0.1),
	lerp(_bottom_left, _top_left, 0.5),
	lerp(_bottom_left, _top_left, 0.9),
]

var _curve_list: Array[BoxCurve] = []
var _polygon_list: Array[Polygon2D] = []

@onready var _parent_polygon: Node2D = $PolygonParent
@onready var _child_portrait: Sprite2D = $Sprite

# Main methods

func _ready():
	# _set_up_fixed_points()
	_set_up()

func _process(delta: float):
	_randomize_curves(delta)
	_update_outer_edges()

# Private methods

func _set_up_fixed_points():
	var corner_point_list: Array[Vector2] = [
		Vector2(-BOX_WIDTH, -BOX_HEIGHT),
		Vector2(BOX_WIDTH, -BOX_HEIGHT),
		Vector2(BOX_WIDTH, BOX_HEIGHT),
		Vector2(-BOX_WIDTH, BOX_HEIGHT),
		Vector2(-BOX_WIDTH, -BOX_HEIGHT)
	]
	var t_randrange: float = MID_CORNER_VERTEX_COUNT / (MID_CORNER_VERTEX_COUNT + 1)
	
	for i in corner_point_list.size() - 1:
		var corner_point = corner_point_list[i]
		var next_corner_point = corner_point_list[i + 1]
		_fixed_point_list.push_back(corner_point)
		
		var current_t: float = 0
		for j in MID_CORNER_VERTEX_COUNT:
			_fixed_point_list.push_back(lerp(corner_point, next_corner_point, current_t))
			current_t = randf_range(current_t, min(current_t + t_randrange, 1))

func _set_up():
	var prev_curve: BoxCurve
	
	# Polygon in the center
	var center_polygon: Polygon2D = Polygon2D.new()
	center_polygon.set_polygon([
		Vector2(-BOX_WIDTH, -BOX_HEIGHT),
		Vector2(BOX_WIDTH, -BOX_HEIGHT),
		Vector2(BOX_WIDTH, BOX_HEIGHT),
		Vector2(-BOX_WIDTH, BOX_HEIGHT),
	])
	_parent_polygon.add_child(center_polygon)
	
	var fixed_point_count: int = _fixed_point_list.size()
	for i in fixed_point_count:
		var j = (i + 1) % fixed_point_count
		var fixed_point: Vector2 = _fixed_point_list[i]
		var next_fixed_point: Vector2 = _fixed_point_list[j]
		
		# New curves
		var new_curve: BoxCurve = BoxCurve.new(2 * fixed_point, 2 * next_fixed_point)
		if prev_curve != null:
			prev_curve.next_curve = new_curve
		prev_curve = new_curve
		_curve_list.push_back(new_curve)
		
		if i > INF:
			continue
		# New polygons
		var new_polygon: Polygon2D = Polygon2D.new()
		var new_polygon_vertices: Array[Vector2] = []
		
		# This is the "outer" part of the polygon
		# which will be controlled by a bezier curve.
		for x in VERTICES_PER_POLYGON + 1:
			var midway_point: Vector2 = lerp(
				2 * fixed_point,
				2 * next_fixed_point,
				float(x) / float(VERTICES_PER_POLYGON))
			new_polygon_vertices.push_back(midway_point)
		
		# This is the "inner" part of the polygon.
		new_polygon_vertices.push_back(next_fixed_point)
		new_polygon_vertices.push_back(fixed_point)
		
		new_polygon.set_polygon(new_polygon_vertices)
		_polygon_list.push_back(new_polygon)
		_parent_polygon.add_child(new_polygon)
	
	_curve_list.back().next_curve = _curve_list[0]

func _update_outer_edges():
	var polygon_count = _polygon_list.size()
	for i in polygon_count:
		var polygon = _polygon_list[i]
		for j in VERTICES_PER_POLYGON:
			polygon.polygon[j] = _curve_list[i].curve.interpolate(float(j) / float(VERTICES_PER_POLYGON))

func _randomize_curves(delta: float):
	var curve_count: int = _curve_list.size()
	var i: int = 0
	while i < curve_count:
		var curve = _curve_list[i]
		curve.tick(delta)
		i += 1
		

class BoxCurve:
	var next_curve: BoxCurve
	var curve: CubicBezier
	
	var _base_angle: float
	var _angle: float
	var _length: float
	var _max_angle: float
	var _max_length: float
	var _angle_tick: float
	var _length_tick: float
	var _angle_tick_speed: float = 1
	var _length_tick_speed: float = 1
	
	func _init(
		start: Vector2,
		end: Vector2):
		
		curve = CubicBezier.new(start, end, Vector2.ZERO, Vector2.ZERO)
		
		_base_angle = UtilMath.get_angle_from_vector(start - end)
		_angle = randf_range(0, TAU)
		_max_angle = PI / 8
		_max_length = 20
		_angle_tick_speed = randf_range(1, 3)
		_length_tick_speed = randf_range(1, 3)
	
	# Public methods
	
	func tick(delta: float):
		_angle_tick += _angle_tick_speed * delta
		_length_tick += _length_tick_speed * delta
		
		_angle = _base_angle + _max_angle * sin(_angle_tick)
		_length = _max_length + _max_length * sin(_length_tick)
		
		curve.control_b = _length * UtilMath.get_vector_from_angle(_angle)
		next_curve.curve.control_a = curve.control_b

extends Node

class_name battle_manager

const BATTLE_AREA_SIZE: Vector2 = Vector2(300, 400)

@onready var prefab_bullet = preload("res://prefabs/bullet.tscn")
@onready var obj_player: Node2D = $Node2D/Player

var origin_from_center: Vector2
var origin_from_top_left: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	origin_from_center = get_viewport().get_visible_rect().size / 2
	origin_from_top_left = origin_from_center - BATTLE_AREA_SIZE / 2
	
	$Node2D/Enemy.set_up(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	debug()
	pass

# Utility functions

func shoot_bullet_at_direction(pos: Vector2, dir: Vector2, spd: float):
	var new_bullet = prefab_bullet.instantiate()
	new_bullet.name = "Bullet"
	$Node2D.add_child(new_bullet)
	new_bullet.set_up(pos, dir.normalized(), spd)

func shoot_bullet_at_angle(pos: Vector2, angle: float, spd: float):
	var true_angle = lerpf(0, 2 * PI, clamp(0, 1, angle))
	var direction = Vector2(cos(true_angle), sin(true_angle))
	shoot_bullet_at_direction(pos, direction, spd)

func debug():
	if not Input.is_action_pressed("game_debug"):
		return
	
	if Input.is_key_pressed(KEY_Q):
		obj_player.position = origin_from_top_left
		return
	
	if Input.is_key_pressed(KEY_W):
		obj_player.position = origin_from_center
		return
	

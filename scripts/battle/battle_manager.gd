extends Node

class_name battle_manager

const BATTLE_AREA_SIZE: Vector2 = Vector2(300, 400)

@onready var obj_player: Node2D = $Node2D/Player

var origin_from_center: Vector2
var origin_from_top_left: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	origin_from_center = get_viewport().get_visible_rect().size / 2
	origin_from_top_left = origin_from_center - BATTLE_AREA_SIZE / 2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	debug()
	pass

# Utility functions

func debug():
	if not Input.is_action_pressed("game_debug"):
		return
	
	if Input.is_key_pressed(KEY_Q):
		obj_player.position = origin_from_top_left
		return
	
	if Input.is_key_pressed(KEY_W):
		obj_player.position = origin_from_center
		return
	

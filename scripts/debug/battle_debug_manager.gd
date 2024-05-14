class_name BattleDebugManager
extends Node

static var _child_debug_bullet_count: Label
static var _child_debug_framerate: Label

# Public functions

static func update_bullet_count(count: int):
	_child_debug_bullet_count.text = "Bullet Count: " + str(count)

# Private functions

func _ready():
	_child_debug_bullet_count = $DebugBulletCount
	_child_debug_framerate = $DebugFramerate

func _process(delta):
	_child_debug_framerate.text = "FPS: %.3f" % (1 / delta)

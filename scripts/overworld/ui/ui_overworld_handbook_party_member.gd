class_name UIOverworldHandbookPartyMember
extends Control

@export var _my_label: Control

var _animation_t: float
var _target_animation_t: float

var _initial_rotation: float
var _focus_rotation: float
var _swivel_direction: int = 1

@onready var _child_photo: Control = $Photo
@onready var _child_photo_shadow: Control = $PhotoShadow

# Main methods

func _ready():
	_initial_rotation = rotation
	unfocus()

func _process(_delta):
	_handle_animation()

# Public methods

func set_up(focus_rotation: float):
	_focus_rotation = focus_rotation

func focus():
	_target_animation_t = 1
	
	modulate.a = 1
	_my_label.modulate.a = 1
	_child_photo_shadow.modulate.a = 1

func unfocus():
	_target_animation_t = 0
	
	modulate.a = 0.5
	_my_label.modulate.a = 0.2
	_child_photo_shadow.modulate.a = 0

# Private methods

func _handle_animation():
	_animation_t = lerpf(_animation_t, _target_animation_t, 0.5)
	
	rotation = lerpf(_initial_rotation, _focus_rotation, _animation_t)
	_child_photo.scale = Vector2.ONE * lerpf(1, 1.2, _animation_t)
	
	# _child_photo_shadow.scale = Vector2.ONE * lerpf(1, 0.9, _animation_t)
	# _child_photo_shadow.self_modulate.a = lerpf(0.7, 0.5, _animation_t)

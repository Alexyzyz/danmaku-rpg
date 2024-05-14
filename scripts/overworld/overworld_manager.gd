class_name OverworldManager
extends Node

enum OverworldState {
	IDLE,
	MENU_OPEN
}

static var overworld_state: OverworldState = OverworldState.IDLE

@export var overworld_ui_menu: UIOverworldHandbook

# Public functions

static func change_state(new_state: OverworldState):
	overworld_state = new_state

# Private functions

func _process(_delta):
	_handle_inputs()

func _handle_inputs():
	if overworld_state == OverworldState.IDLE:
		_handle_idle_inputs()
	elif overworld_state == OverworldState.MENU_OPEN:
		_handle_menu_inputs()

func _handle_idle_inputs():
	if Input.is_action_just_pressed("game_menu"):
		overworld_ui_menu.open_handbook()
		change_state(OverworldState.MENU_OPEN)

func _handle_menu_inputs():
	overworld_ui_menu.handle_inputs()

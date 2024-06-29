class_name OverworldManager
extends Node

enum OverworldState {
	IDLE,
	MENU_OPEN
}

static var overworld_state: OverworldState = OverworldState.IDLE
static var _scene_tree: SceneTree
static var _step_count: int
static var _prefab_scene_battle: PackedScene

@export var overworld_ui_menu: UIOverworldHandbook

# Private functions

func _ready():
	_scene_tree = get_tree()
	_prefab_scene_battle = preload("res://scenes/scene_battle.tscn")


func _process(_delta):
	_handle_inputs()


# Public functions

static func change_state(new_state: OverworldState):
	overworld_state = new_state


static func increase_step_count():
	_step_count += 1
	
	if _step_count > 35:
		_step_count = 0
		_handle_start_battle()


# Private functions

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


static func _handle_start_battle():
	_scene_tree.change_scene_to_packed(_prefab_scene_battle)


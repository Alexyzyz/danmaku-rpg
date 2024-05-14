class_name UIOverworldHandbook
extends Control

enum MenuState {
	PARTY,
	GEARS,
	ALBUM
}

var _menu_state: MenuState = MenuState.PARTY

var _party_selection: PartySelection
var _party_selection_handbook_tab: PartySelection = PartySelection.new()
var _party_selection_primary_shot: PartySelection = PartySelection.new()
var _party_selection_secondary_shot: PartySelection = PartySelection.new()
var _party_selection_support_shot: PartySelection = PartySelection.new()

@onready var _node_bookmark_tab: Control
@onready var _node_primary_shot: UIOverworldHandbookPartyMember = $Background/PartyMenu/PartyMember1
@onready var _node_secondary_shot: UIOverworldHandbookPartyMember = $Background/PartyMenu/PartyMember2
@onready var _node_support_shot: UIOverworldHandbookPartyMember = $Background/PartyMenu/PartyMember3

# Main methods

func _ready():
	_set_up_selection_flowchart()

# Public methods

func handle_inputs():
	if Input.is_action_just_pressed("game_menu"):
		# Close the handbook UI, and
		# return to the idle overworld state
		close_handbook()
		OverworldManager.change_state(OverworldManager.OverworldState.IDLE)
		return
	
	_handle_party_inputs()

func open_handbook():
	visible = true

func close_handbook():
	visible = false

# Private methods

func _set_up_selection_flowchart():
	# Set up nodes
	_node_primary_shot.set_up(-0.0103 * PI)
	_node_secondary_shot.set_up(0.05 * PI)
	_node_support_shot.set_up(-0.0105 * PI)
	
	_party_selection_primary_shot.node = _node_primary_shot
	_party_selection_secondary_shot.node = _node_secondary_shot
	_party_selection_support_shot.node = _node_support_shot
	
	# Set up links
	_party_selection_handbook_tab.next = _party_selection_primary_shot
	
	# _party_selection_primary_shot.prev = _party_selection_handbook_tab
	_party_selection_primary_shot.next = _party_selection_secondary_shot
	
	_party_selection_secondary_shot.prev = _party_selection_primary_shot
	_party_selection_secondary_shot.next = _party_selection_support_shot
	
	_party_selection_support_shot.prev = _party_selection_secondary_shot
	
	# Set initial selection
	_party_selection = _party_selection_primary_shot
	_party_selection.node.focus()

func _handle_party_inputs():
	var x_axis: int = (
		(1 if Input.is_action_just_pressed("game_move_right") else 0) -
		(1 if Input.is_action_just_pressed("game_move_left") else 0)
	)
	
	if x_axis == 1 and _party_selection.next != null:
		_party_selection.node.unfocus()
		_party_selection = _party_selection.next
		_party_selection.node.focus()
	elif x_axis == -1 and _party_selection.prev != null:
		_party_selection.node.unfocus()
		_party_selection = _party_selection.prev
		_party_selection.node.focus()

# Subclasses

class PartySelection:
	var next: PartySelection
	var prev: PartySelection
	var node: UIOverworldHandbookPartyMember

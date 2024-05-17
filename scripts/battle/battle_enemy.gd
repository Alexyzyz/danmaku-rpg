class_name BattleEnemy
extends Node2D

const BB_SIDE_LENGTH: float = 50

var health: float = 100
var max_health: float = 100

@onready var _child_behavior: Node2D = $Behavior
@onready var _child_health_bar: TextureProgressBar = $Control/HealthBar

# Main methods

func _ready():
	_child_behavior.set_up(self)

func _process(delta):
	_child_behavior.tick(delta)
	_check_if_hit()

# Private methods

func _check_if_hit():
	var player_shots: Array[Node2D] = BattleManager.sp_player_shots.get_obj_in_cells_surrounding(position)
	
	for shot in player_shots:
		while shot != null:	
			var next_shot = shot.sp_cell_next
			var distance = (shot.position - position).length()
			if distance < BB_SIDE_LENGTH:
				shot.destroy()
				health -= shot.damage
				_child_health_bar.value = health
			shot = next_shot

func _draw_health_bar():
	pass

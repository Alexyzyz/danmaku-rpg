class_name BattleEnemy
extends Node2D

const BB_SIDE_LENGTH: float = 50

var health: float = 100
var max_health: float = 100

var _child_behavior: Node2D
var _child_health_bar: TextureProgressBar

# Main methods

func _ready():
	pass

func _process(p_delta: float):
	_check_if_hit()
	_tick_behavior(p_delta)

# Public methods

func set_up(p_position: Vector2):
	_child_behavior = $Behavior
	_child_health_bar = $Control/HealthBar
	
	position = p_position

func set_behavior(p_behavior_script: Script):
	_child_behavior.set_script(p_behavior_script)
	if _child_behavior.has_method("set_up"):
		_child_behavior.set_up(self)

func move_to(p_direction: Vector2):
	position += p_direction

func move_along_curve(p_curve: CubicBezier, p_time: float):
	pass

# Private methods

func _check_if_hit():
	var player_shots: Array[Node2D] = BattleManager.sp_player_shots.get_obj_in_cells_surrounding(position)
	
	for shot in player_shots:
		while shot != null:
			var next_shot = shot.sp_cell_next
			var distance = (shot.position - position).length()
			if distance < BB_SIDE_LENGTH:
				shot.destroy()
				
				BattleUIShotDamageManager.spawn_damage_number(shot.damage, shot.global_position)
				health -= shot.damage
				
				if health <= 0:
					BattleManager.handle_defeated_enemy(self)
					return
				_child_health_bar.value = health
			shot = next_shot

func _tick_behavior(p_delta: float):
	if _child_behavior == null:
		return
	if _child_behavior.has_method("tick"):
		_child_behavior.tick(p_delta)

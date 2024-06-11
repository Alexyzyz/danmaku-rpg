class_name BattleEnemy
extends Node2D

enum HealthDisplay {
	BAR,
	CIRCLE,
}

const BB_SIDE_LENGTH: float = 50

var health: float
var blocks_shots: bool = true

var _is_major: bool
var _health_display: HealthDisplay
var _obj_ripple_shader: ColorRect
var _child_behavior: Node2D
var _child_health_bar: TextureProgressBar
var _child_health_circle: TextureProgressBar

# Public methods

func set_up(
	p_position: Vector2,
	p_ripple_shader: ColorRect,
	p_max_health: float = 100,
	p_health_display: HealthDisplay = HealthDisplay.BAR,
	p_is_major: bool = true):
	
	health = p_max_health
	
	_health_display = p_health_display
	_is_major = p_is_major
	_obj_ripple_shader = p_ripple_shader
	_child_behavior = $Behavior
	_child_health_bar = $Control/HealthBar
	_child_health_circle = $Control/HealthCircle
	
	_child_health_bar.max_value = p_max_health
	_child_health_bar.value = p_max_health
	
	_child_health_circle.max_value = p_max_health
	_child_health_circle.value = p_max_health
	
	if _health_display == HealthDisplay.BAR:
		_child_health_circle.visible = false
	else:
		_child_health_bar.visible = false
	
	position = p_position


func update(p_delta: float):
	if p_delta == 0:
		return
	
	_check_if_hit()
	
	# _obj_ripple_shader.position = global_position - _obj_ripple_shader.size / 2
	
	if _child_behavior == null:
		return
	
	# NOTE:
	# The method name update() is preferred.
	# Replace tick() with update() soon.
	if _child_behavior.has_method("tick"):
		_child_behavior.tick(p_delta)
	if _child_behavior.has_method("update"):
		_child_behavior.update(p_delta)


func damage(p_damage: float, p_position: Vector2):
	BattleUIShotDamageManager.spawn_damage_number(
		p_damage, p_position)
	health -= p_damage
	
	if health <= 0:
		if _is_major:
			BattleManager.handle_enemy_defeat(self)
		else:
			BattleManager.handle_minor_enemy_defeat(self)
		# _obj_ripple_shader.queue_free()
		return
	
	_child_health_bar.value = health
	_child_health_circle.value = health


func get_behavior() -> Node2D:
	return _child_behavior


func set_behavior(p_behavior_script: Script):
	_child_behavior.set_script(p_behavior_script)
	if _child_behavior.has_method("set_up"):
		_child_behavior.set_up()


func move_to(p_direction: Vector2):
	position += p_direction


func set_health_display_alpha(p_alpha: float):
	_child_health_bar.modulate.a = p_alpha
	_child_health_circle.modulate.a = p_alpha


# Private methods

func _check_if_hit():
	if not blocks_shots:
		return
	
	var player_shots: Array[Node2D] = BattleManager.get_player().get_projectiles()
	for shot in player_shots:
		_check_if_shot_hit(shot)


func _check_if_shot_hit(p_shot: Node2D):
	if p_shot == null:
		print(p_shot)
		return
	var distance = (p_shot.position - position).length()
	if distance > BB_SIDE_LENGTH:
		return
	damage(p_shot.damage, p_shot.global_position)
	p_shot.destroy()


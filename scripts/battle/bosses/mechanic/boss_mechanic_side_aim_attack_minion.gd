extends Node2D

var is_broken: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func shoot_at_player():
	var dir: Vector2 = BattleManager.obj_player.position - position
	BattleManager.shoot_bullet_at_direction(position, dir, 1)
	pass


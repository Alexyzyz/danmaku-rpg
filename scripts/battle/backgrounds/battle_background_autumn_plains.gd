class_name BattleBackgroundAutumnPlains
extends Node3D

var _cloud_list: Array[Cloud]
var _prefab_cloud: PackedScene = preload("res://prefabs/battle/backgrounds/autumn_plains/battle_background_autumn_plains_cloud.tscn")

# Main methods

func _ready():
	_set_up()

func _process(p_delta: float):
	_update_clouds(p_delta)

# Private methods

func _set_up():
	var spawn_z: float = 0
	for i in 10:
		var new_cloud_instance: Sprite3D = _prefab_cloud.instantiate()
		add_child(new_cloud_instance)
		
		var new_cloud = Cloud.new(new_cloud_instance, spawn_z, randf() > 0.5)
		_cloud_list.push_back(new_cloud)
		
		spawn_z -= randf_range(1, 2)
	
	for cloud in _cloud_list:
		cloud.set_spawn_z(spawn_z)

func _update_clouds(p_delta: float):
	for cloud in _cloud_list:
		cloud.update(p_delta)

# Subclasses

class Cloud:
	var obj: Sprite3D
	var direction: Vector3
	var speed: float
	
	var respawn_z: float
	var respawn_tick: float
	
	func _init(p_obj: Sprite3D, p_spawn_z: float, p_on_the_left: bool):
		obj = p_obj
		direction = Vector3.BACK
		speed = 2.5
		
		var x_side: float = -1 if p_on_the_left else 1
		var y_offset: float = randf_range(-0.5, 0.5)
		
		obj.position.x = x_side * (1.4 + randf_range(0, 4))
		obj.position.y += y_offset
		obj.position.z = p_spawn_z
	
	# Public methods
	
	func update(p_delta: float):
		obj.position += speed * direction * p_delta
		
		if obj.position.z < -20:
			respawn_tick = 0
		elif obj.position.z > 5:
			obj.position.z = respawn_z
			respawn_tick = 0
		else:
			respawn_tick += p_delta
		
		obj.modulate.a = lerp(0, 1, min(1, 0.5 * respawn_tick))
	
	func set_spawn_z(p_z: float):
		respawn_z = p_z


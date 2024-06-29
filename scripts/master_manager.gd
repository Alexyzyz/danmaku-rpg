extends Node

enum Scene {
	OVERWORLD,
	BATTLE,
}

static var _current_scene: Node
static var _scene_prefab_dict: Dictionary = {
	Scene.OVERWORLD: preload("res://scenes/scene_overworld.tscn"),
	Scene.BATTLE: preload("res://scenes/scene_battle.tscn"),
}

# Main methods

func _ready():
	pass # Replace with function body.


func _process(delta):
	pass


# Public methods

func change_scene(p_scene: Scene):
	var new_scene_prefab: PackedScene = _scene_prefab_dict[p_scene]
	var new_scene: Node = new_scene_prefab.instantiate()
	get_tree().root.add_child(new_scene)
	pass

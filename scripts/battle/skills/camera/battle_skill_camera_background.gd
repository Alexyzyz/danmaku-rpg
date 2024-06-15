class_name SkillCameraBackground
extends Control

# Reference to the viewfinder sprite
@export var viewfinder: Node2D

func _process(delta):
	if viewfinder == null:
		return
	
	var shader_material = self.material as ShaderMaterial
	shader_material.set_shader_parameter("viewfinder_position", viewfinder.global_position)
	shader_material.set_shader_parameter("viewfinder_rotation", viewfinder.rotation)
	shader_material.set_shader_parameter("viewfinder_scale", viewfinder.scale)

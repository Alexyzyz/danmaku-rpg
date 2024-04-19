class_name UtilBulletResource
extends Node

class BulletResource:
	var sprite: Resource
	var dropshadow_sprite: Resource
	
	func _init(sprite: Resource, dropshadow_sprite: Resource):
		self.sprite = sprite
		self.dropshadow_sprite = dropshadow_sprite

static var default: BulletResource = BulletResource.new(
	load("res://sprites/bullets/spr_bullet_0.png"),
	load("res://sprites/bullets/spr_bullet_0_dropshadow.png")
)

static var rice: BulletResource = BulletResource.new(
	load("res://sprites/bullets/spr_bullet_1.png"),
	load("res://sprites/bullets/spr_bullet_1_dropshadow.png")
)

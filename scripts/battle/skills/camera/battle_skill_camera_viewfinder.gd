class_name BattleSkillCameraViewfinder
extends Node2D

const SIZE := Vector2(120, 120)

func clear_bullets():
	var local_rect: Rect2 = _get_local_rect()
	
	var bullet_list: Array[Bullet] = BattleBulletManager._bullet_list
	for bullet in bullet_list:
		if not bullet.is_active:
			continue
		var local_ev_pos: Vector2 = _to_local(bullet.position + BattleManager.origin_from_top_left)
		if local_rect.has_point(local_ev_pos):
			bullet.destroy()
	pass


func get_photo_image() -> Image:
	var texture: Texture2D = get_viewport().get_texture()
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = texture
	atlas_texture.region = Rect2(global_position - SIZE  / 2, SIZE)
	
	# atlas_texture.get_image().save_png("C:/Users/LENOVO/Documents/_Alexyz/Temp/debug_screenshot.png")
	
	return atlas_texture.get_image()


# Private methods

func _get_local_rect() -> Rect2:
	return Rect2(Vector2.ZERO - SIZE / 2, SIZE)


func _to_local(p_global_pos: Vector2) -> Vector2:
	return get_global_transform().affine_inverse() * p_global_pos


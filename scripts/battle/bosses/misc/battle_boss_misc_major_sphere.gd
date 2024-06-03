class_name BattleBossMiscMajorSphere
extends Node2D

var _owner: Node2D
var _sphere_attack: SphereAttack

# Main methods

func set_up(p_owner: Node2D):
	_owner = p_owner
	_sphere_attack = SphereAttack.new(p_owner)

func tick(p_delta: float):
	_sphere_attack.tick(p_delta)

# Subclasses

class SphereAttack:
	const BULLET_COUNT: int = 500
	const SPHERE_RADIUS: float = 300
	const ROTATION_SPEED: Vector3 = 0.2 * Vector3(0.203 * TAU, 0.211 * TAU, 0.237 * TAU)
	
	var _owner: Node2D
	var _bullet_point_list: Array[BulletPointPair] = []
	var _rotation: Vector3
	var _radius: float
	var _radius_tick: float
	
	func _init(p_owner: Node2D):
		_owner = p_owner
		_spawn_sphere()
	
	# Public methods
	
	func tick(p_delta: float):
		_update_sphere(p_delta)
		pass
	
	# Private methods
	
	func _spawn_sphere():
		for i in BULLET_COUNT:
			# Step 1 ✦ Assign a bullet for that point
			var x: float = randfn(0, 1)
			var y: float = randfn(0, 1)
			var z: float = randfn(0, 1)
			var new_point: Vector3 = Vector3(x, y, z).normalized()
			
			# Step 2 ✦ Generate a random point on the sphere
			
			var spawn_pos: Vector2 = _owner.position + SPHERE_RADIUS * Vector2(new_point.x, new_point.y)
			var new_bullet: Bullet = BattleBulletManager.shoot_bullet(
				spawn_pos, 0, 0, UtilBulletResource.default
			)
			if new_bullet == null:
				print(spawn_pos)
				continue
			new_bullet.toggle_move_per_tick(false)
			
			_bullet_point_list.push_back(BulletPointPair.new(new_bullet, new_point))
	
	func _update_sphere(p_delta: float):
		_rotation += ROTATION_SPEED * p_delta
		for bullet_point in _bullet_point_list:
			var bullet: Bullet = bullet_point.bullet
			
			if !bullet.is_active:
				_bullet_point_list.erase(bullet_point)
				continue
			
			var base_pos: Vector3 = bullet_point.point
			var pos: Vector3 = base_pos
			
			pos = pos.rotated(Vector3.RIGHT, _rotation.x)
			pos = pos.rotated(Vector3.UP, _rotation.y)
			pos = pos.rotated(Vector3.FORWARD, _rotation.z)
			
			if pos.z > 0:
				bullet.color = 0.5 * Color.WHITE
				bullet.is_deadly = false
			else:
				bullet.color = Color.WHITE
				bullet.is_deadly = true
			
			_radius = 0.8 * SPHERE_RADIUS + 0.2 * SPHERE_RADIUS * sin(_radius_tick)
			_radius_tick += p_delta / 1000
			bullet.move_to(_owner.position + _radius * Vector2(pos.x, pos.y))
	
class BulletPointPair:
	var bullet: Bullet
	var point: Vector3
	
	func _init(p_bullet: Bullet, p_point: Vector3):
		bullet = p_bullet
		point = p_point

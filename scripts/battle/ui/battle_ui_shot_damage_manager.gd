class_name BattleUIShotDamageManager
extends Control

const NUMBER_POOL_SIZE: int = 100

static var _prefab_number: PackedScene
static var _number_list: Array[DamageNumber] = []
static var _first_inactive_number: DamageNumber

# Main methods

func _ready():
	_set_up()

func _process(p_delta: float):
	_update(p_delta)

# Public methods

static func spawn_damage_number(
	p_damage: int,
	p_position: Vector2,
	p_offset: float = 30):
	
	if _first_inactive_number == null:
		return
	
	var number: DamageNumber = _first_inactive_number
	_first_inactive_number = number.next_inactive
	
	var pos_offset: Vector2 = Vector2(
		randf_range(-p_offset, p_offset),
		randf_range(-p_offset, p_offset))
	var pos_offset_rect: Vector2 = number.obj.size / 2
	
	number.spawn(p_damage, p_position + pos_offset - pos_offset_rect)

static func despawn_damage_number(p_number: DamageNumber):
	p_number.next_inactive = _first_inactive_number
	_first_inactive_number = p_number

# Private methods

func _set_up():
	_prefab_number = preload("res://prefabs/battle/ui/prefab_battle_ui_shot_damage_number.tscn")
	
	var prev: DamageNumber
	for i in NUMBER_POOL_SIZE:
		var instance: Label = _prefab_number.instantiate()
		add_child(instance)
		instance.visible = false
		
		var number: DamageNumber = DamageNumber.new(instance)
		_number_list.push_back(number)
		
		if _first_inactive_number == null:
			_first_inactive_number = number
		
		if prev == null:
			prev = number
		else:
			prev.next_inactive = number
		
		prev = number

func _update(p_delta: float):
	for number in _number_list:
		if !number.is_active:
			continue
		number.update(p_delta)

# Subclasses

class DamageNumber:
	const FADE_OUT_TIME: float = 0.1
	const FADE_IN_TIME: float = 0.2
	const DESPAWN_TIME: float = 1
	
	var obj: Label
	var is_active: bool = false
	var next_inactive: DamageNumber
	
	var _tick: float
	
	func _init(p_obj: Label):
		obj = p_obj
	
	# Public methods
	
	func spawn(p_damage: int, p_position: Vector2):
		is_active = true
		_tick = 0
		
		obj.visible = true
		obj.text = str(p_damage)
		obj.position = p_position
		
	
	func update(p_delta: float):
		_tick += p_delta
		
		if _tick > FADE_IN_TIME + DESPAWN_TIME + FADE_OUT_TIME:
			_despawn()
		elif _tick > FADE_IN_TIME + DESPAWN_TIME:
			var t: float = (_tick - FADE_IN_TIME - DESPAWN_TIME) / FADE_OUT_TIME
			obj.self_modulate.a = lerp(1, 0, t)
		elif _tick <= FADE_IN_TIME:
			var t: float = _tick / FADE_IN_TIME
			obj.self_modulate.a = lerp(0, 1, t)
			obj.scale = Vector2.ONE * lerp(2, 1, t)
	
	# Private methods
	
	func _despawn():
		obj.visible = false
		is_active = false
		BattleUIShotDamageManager.despawn_damage_number(self)
	

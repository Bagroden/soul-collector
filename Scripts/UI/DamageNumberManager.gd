extends Node2D
class_name DamageNumberManager

# Синглтон для глобального доступа
static var instance: DamageNumberManager

func _ready():
	instance = self

func show_damage_number(target_position: Vector2, damage: int, is_critical: bool = false, is_miss: bool = false, is_heal: bool = false, damage_type: String = "physical"):
	"""Показывает всплывающую цифру урона в указанной позиции"""
	if not instance:
		return
	
	# Создаем экземпляр DamageNumber
	var damage_number_scene = preload("res://Scripts/UI/DamageNumber.gd")
	var damage_number = damage_number_scene.new()
	
	# Настраиваем позицию с небольшим случайным смещением и поднимаем выше
	var random_offset = Vector2(randf_range(-20, 20), randf_range(-130, -120))
	damage_number.position = target_position + random_offset
	
	# Добавляем на сцену ПЕРЕД настройки параметров
	add_child(damage_number)
	
	# Ждем один кадр, чтобы узел успел инициализироваться
	await get_tree().process_frame
	
	# Настраиваем параметры после добавления в сцену
	damage_number.setup_damage(damage, is_critical, is_miss, is_heal, damage_type)

# Статические методы для удобного доступа
static func show_damage(target_position: Vector2, damage: int, is_critical: bool = false, is_miss: bool = false, is_heal: bool = false, damage_type: String = "physical"):
	"""Статический метод для показа урона"""
	if instance:
		instance.show_damage_number(target_position, damage, is_critical, is_miss, is_heal, damage_type)

static func show_damage_on_character(character: Node2D, damage: int, is_critical: bool = false, is_miss: bool = false, is_heal: bool = false, damage_type: String = "physical"):
	"""Статический метод для показа урона над персонажем"""
	if not instance or not character:
		return
	
	# Получаем позицию персонажа
	var character_position = character.global_position
	
	# Если у персонажа есть визуальный компонент, используем его позицию
	if character.has_method("get_visual_position"):
		character_position = character.get_visual_position()
	elif character.has_node("Visual"):
		character_position = character.get_node("Visual").global_position
	elif character.has_node("Sprite2D"):
		character_position = character.get_node("Sprite2D").global_position
	elif character.has_node("AnimatedSprite2D"):
		character_position = character.get_node("AnimatedSprite2D").global_position
	
	# Показываем урон
	instance.show_damage_number(character_position, damage, is_critical, is_miss, is_heal, damage_type)

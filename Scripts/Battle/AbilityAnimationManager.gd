# res://Scripts/Battle/AbilityAnimationManager.gd
# Менеджер для управления анимациями способностей врагов
extends Node
class_name AbilityAnimationManager

## Путь к ресурсу с данными об анимациях способностей
const ANIMATION_DATA_PATH = "res://Data/AbilityAnimations.tres"

var animation_data: AbilityAnimationData

func _ready() -> void:
	_load_animation_data()

func _load_animation_data() -> void:
	# Пытаемся загрузить существующий ресурс
	if ResourceLoader.exists(ANIMATION_DATA_PATH):
		animation_data = load(ANIMATION_DATA_PATH) as AbilityAnimationData
		if animation_data == null:
			# Если ресурс существует, но не является AbilityAnimationData, создаем новый
			print("Предупреждение: Ресурс по пути ", ANIMATION_DATA_PATH, " не является AbilityAnimationData. Создаем новый.")
			animation_data = AbilityAnimationData.new()
			_save_animation_data()
		else:
			print("DEBUG: Ресурс анимаций загружен. Анимаций: ", animation_data.ability_animations.size())
			for key in animation_data.ability_animations:
				print("DEBUG:   - ", key, " -> ", animation_data.ability_animations[key])
	else:
		# Если ресурс не существует, создаем новый
		print("Ресурс анимаций способностей не найден. Создаем новый по пути: ", ANIMATION_DATA_PATH)
		animation_data = AbilityAnimationData.new()
		_save_animation_data()

func _save_animation_data() -> void:
	if animation_data:
		var dir = ANIMATION_DATA_PATH.get_base_dir()
		if not DirAccess.dir_exists_absolute(dir):
			DirAccess.make_dir_recursive_absolute(dir)
		ResourceSaver.save(animation_data, ANIMATION_DATA_PATH)
		print("Данные анимаций способностей сохранены в: ", ANIMATION_DATA_PATH)

## Получить имя анимации для способности
## Возвращает имя анимации или пустую строку, если анимация не задана
func get_animation_for_ability(ability_id: String) -> String:
	if animation_data:
		return animation_data.get_animation_for_ability(ability_id)
	return ""

## Проверить, есть ли анимация для способности
func has_animation_for_ability(ability_id: String) -> bool:
	if animation_data:
		return animation_data.has_animation_for_ability(ability_id)
	return false

## Проиграть анимацию способности на визуальном компоненте врага
## Возвращает true, если анимация была проиграна, false если использована fallback анимация
func play_ability_animation(visual_node: Node, ability_id: String) -> bool:
	if not visual_node:
		print("DEBUG: play_ability_animation - visual_node is null")
		return false
	
	var animation_name = get_animation_for_ability(ability_id)
	print("DEBUG: play_ability_animation - ability_id: ", ability_id, ", animation_name: ", animation_name)
	
	if animation_name != "" and visual_node.has_method("play_animation"):
		# Проверяем, есть ли такая анимация в sprite_frames
		# AnimatedSprite2D всегда имеет свойство sprite_frames, проверяем его напрямую
		if visual_node.sprite_frames != null:
			if visual_node.sprite_frames.has_animation(animation_name):
				print("DEBUG: Проигрываем анимацию '", animation_name, "' для способности '", ability_id, "'")
				visual_node.play_animation(animation_name)
				return true
			else:
				print("Предупреждение: Анимация '", animation_name, "' не найдена в sprite_frames. Используется стандартная атака.")
		else:
			print("Предупреждение: У visual_node нет sprite_frames. Используется стандартная атака.")
	
	# Fallback: используем стандартную атаку
	if visual_node.has_method("play_attack"):
		print("DEBUG: Используем fallback - стандартная атака")
		visual_node.play_attack()
		return false
	
	return false

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
			animation_data = AbilityAnimationData.new()
			_save_animation_data()
		else:
			for key in animation_data.ability_animations:
	else:
		# Если ресурс не существует, создаем новый
		animation_data = AbilityAnimationData.new()
		_save_animation_data()

func _save_animation_data() -> void:
	if animation_data:
		var dir = ANIMATION_DATA_PATH.get_base_dir()
		if not DirAccess.dir_exists_absolute(dir):
			DirAccess.make_dir_recursive_absolute(dir)
		ResourceSaver.save(animation_data, ANIMATION_DATA_PATH)

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
		return false
	
	var animation_name = get_animation_for_ability(ability_id)
	
	if animation_name != "" and visual_node.has_method("play_animation"):
		# Проверяем, есть ли такая анимация в sprite_frames
		# AnimatedSprite2D всегда имеет свойство sprite_frames, проверяем его напрямую
		if visual_node.sprite_frames != null:
			if visual_node.sprite_frames.has_animation(animation_name):
				visual_node.play_animation(animation_name)
				return true
			else:
		else:
	
	# Fallback: используем стандартную атаку
	if visual_node.has_method("play_attack"):
		visual_node.play_attack()
		return false
	
	return false

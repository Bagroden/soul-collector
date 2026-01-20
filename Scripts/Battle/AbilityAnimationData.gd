# res://Scripts/Battle/AbilityAnimationData.gd
# Ресурс для хранения привязки способностей врагов к анимациям
extends Resource
class_name AbilityAnimationData

## Словарь, где ключ - ID способности (например, "rat_bite"), значение - имя анимации (например, "rat_bite_anim")
@export var ability_animations: Dictionary = {}

## Получить имя анимации для способности
## Возвращает имя анимации или пустую строку, если анимация не задана
func get_animation_for_ability(ability_id: String) -> String:
	if ability_animations.has(ability_id):
		return ability_animations[ability_id]
	return ""

## Установить анимацию для способности
func set_animation_for_ability(ability_id: String, animation_name: String) -> void:
	ability_animations[ability_id] = animation_name

## Проверить, есть ли анимация для способности
func has_animation_for_ability(ability_id: String) -> bool:
	return ability_animations.has(ability_id) and ability_animations[ability_id] != ""

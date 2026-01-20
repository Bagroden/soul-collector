# res://Scripts/PassiveAbilities/Uncommon/Rage.gd
extends PassiveAbility

func _init():
	id = "rage"                                 # ⚠️ ВАЖНО: Уникальный ID
	name = "Ярость"                             # ⚠️ ВАЖНО: Отображаемое имя
	description = "Каждое получение урона дает X к физическому урону на 3 раунда. Бонус стакается."
	rarity = "uncommon"                         # ⚠️ ВАЖНО: Редкость способности
	ability_type = AbilityType.OFFENSIVE       # ⚠️ ВАЖНО: Тип способности
	trigger_type = TriggerType.ON_DAMAGE_TAKEN # ⚠️ ВАЖНО: Когда срабатывает
	# Значения для каждого уровня
	level_values = [1, 2, 3]  # 1/2/3 к физическому урону
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", _context.get("level", 1))
	var current_value = get_value_for_level(current_level)
	
	# Применяем бонус к физическому урону
	if owner.has_method("add_physical_damage_bonus"):
		owner.add_physical_damage_bonus(current_value)
		
		# Создаем эффект "Ярость" для визуального отображения
		owner.add_effect("rage", 3.0, 1, {
			"damage_bonus": current_value,
			"remaining_turns": 3
		})
		
		return {
			"success": true,
			"message": "Ярость - " + owner.display_name + " получает +" + str(current_value) + " к физическому урону на 3 раунда!",
			"effect": "rage",
			"damage_bonus": current_value,
			"duration": 3
		}
	
	return {"success": false, "message": "Ярость не сработала"}

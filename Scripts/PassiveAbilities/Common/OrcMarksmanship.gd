# res://Scripts/PassiveAbilities/Common/OrcMarksmanship.gd
extends PassiveAbility

func _init():
	id = "orc_marksmanship"
	name = "Точность орка"
	description = "Увеличивает меткость"
	rarity = "common"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.PASSIVE
	# Значения для каждого уровня
	level_values = [12.0, 22.0, 38.0]  # +12%/22%/38% меткость
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var accuracy_bonus = get_value_for_level(current_level)
	
	# Эта способность пассивная и применяется через get_stat_modifier
	return {
		"success": true,
		"message": owner.display_name + " имеет повышенную меткость",
		"stat_modifier": "accuracy",
		"value": accuracy_bonus
	}

func get_stat_modifier(stat_name: String, current_level: int) -> float:
	if stat_name == "accuracy":
		return get_value_for_level(current_level)
	return 0.0


# res://Scripts/PassiveAbilities/Rare/BladeMastery.gd
extends PassiveAbility

func _init():
	id = "blade_mastery"
	name = "Мастерство клинка"
	description = "Увеличивает физический урон"
	rarity = "rare"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.PASSIVE
	# Значения для каждого уровня: % увеличения физического урона
	level_values = [20.0, 35.0, 55.0]  # +20%/35%/55% физический урон
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var damage_bonus = get_value_for_level(current_level)
	
	# Эта способность пассивная и применяется через get_stat_modifier
	return {
		"success": true,
		"message": owner.display_name + " владеет мастерством клинка",
		"stat_modifier": "physical_damage",
		"value": damage_bonus
	}

func get_stat_modifier(stat_name: String, current_level: int) -> float:
	if stat_name == "physical_damage" or stat_name == "damage_percent":
		return get_value_for_level(current_level)
	return 0.0


# res://Scripts/PassiveAbilities/Legendary/Headshot.gd
extends PassiveAbility

func _init():
	id = "headshot"
	name = "Выстрел в голову"
	description = "Критические удары наносят огромный дополнительный урон"
	rarity = "legendary"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_CRIT
	# Значения для каждого уровня: дополнительный % урона к критам
	level_values = [60.0, 100.0, 150.0]  # +60%/100%/150% к криту
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var extra_crit_damage = get_value_for_level(current_level)
	
	# Эта способность модифицирует критический урон
	return {
		"success": true,
		"message": owner.display_name + " готовит смертельный выстрел в голову!",
		"crit_damage_bonus": extra_crit_damage,
		"effect": "headshot"
	}

func get_stat_modifier(stat_name: String, current_level: int) -> float:
	if stat_name == "crit_damage":
		return get_value_for_level(current_level)
	return 0.0

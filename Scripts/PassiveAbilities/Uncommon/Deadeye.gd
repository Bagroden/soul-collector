# res://Scripts/PassiveAbilities/Uncommon/Deadeye.gd
extends PassiveAbility

func _init():
	id = "deadeye"
	name = "Мертвый глаз"
	description = "Увеличивает шанс критического удара"
	rarity = "uncommon"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.PASSIVE
	# Значения для каждого уровня
	level_values = [7.0, 12.0, 20.0]  # +7%/12%/20% шанс крита
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var crit_bonus = get_value_for_level(current_level)
	
	# Эта способность пассивная и применяется через get_stat_modifier
	return {
		"success": true,
		"message": owner.display_name + " имеет повышенный шанс крита",
		"stat_modifier": "crit_chance",
		"value": crit_bonus
	}

func get_stat_modifier(stat_name: String, current_level: int) -> float:
	if stat_name == "crit_chance":
		return get_value_for_level(current_level)
	return 0.0


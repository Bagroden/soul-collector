# res://Scripts/PassiveAbilities/Rare/EnchantedBones.gd
extends PassiveAbility

func _init():
	id = "enchanted_bones"
	name = "Зачарованные кости"
	description = "Увеличивает защиту и магическое сопротивление благодаря темной магии, пропитывающей кости"
	rarity = "rare"
	ability_type = AbilityType.DEFENSIVE
	trigger_type = TriggerType.PASSIVE
	# Бонус защиты для каждого уровня
	level_values = [10.0, 15.0, 20.0]
	value = 10.0  # Значение по умолчанию (1 уровень)

# Магическое сопротивление для каждого уровня
var magic_resists = [7.0, 14.0, 21.0]

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var armor_bonus = get_value_for_level(current_level)
	var magic_resist = magic_resists[current_level - 1]
	
	# Эта способность пассивная и применяется через get_stat_modifier
	return {
		"success": true,
		"message": owner.display_name + " защищен зачарованными костями",
		"armor_bonus": armor_bonus,
		"magic_resist": magic_resist
	}

func get_stat_modifier(stat_name: String, current_level: int) -> float:
	if stat_name == "armor" or stat_name == "defense":
		return get_value_for_level(current_level)
	elif stat_name == "magic_resistance":
		return magic_resists[current_level - 1]
	return 0.0


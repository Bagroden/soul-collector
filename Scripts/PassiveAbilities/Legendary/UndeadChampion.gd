# res://Scripts/PassiveAbilities/Legendary/UndeadChampion.gd
extends PassiveAbility

func _init():
	id = "undead_champion"
	name = "Чемпион нежити"
	description = "Увеличивает все характеристики"
	rarity = "legendary"
	ability_type = AbilityType.SPECIAL
	trigger_type = TriggerType.PASSIVE
	# Значения для каждого уровня: бонус ко всем характеристикам
	level_values = [5, 10, 15]  # +5/+10/+15 ко всем характеристикам
	value = 5  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var stat_bonus = int(get_value_for_level(current_level))
	
	# Эта способность пассивная и применяется через get_stat_modifier
	return {
		"success": true,
		"message": owner.display_name + " - Чемпион нежити!",
		"stat_bonus": stat_bonus
	}

func get_stat_modifier(stat_name: String, current_level: int) -> float:
	var stat_bonus = get_value_for_level(current_level)
	
	# Применяем бонус ко всем основным характеристикам
	if stat_name in ["strength", "agility", "vitality", "endurance", "intelligence", "wisdom"]:
		return stat_bonus
	
	return 0.0


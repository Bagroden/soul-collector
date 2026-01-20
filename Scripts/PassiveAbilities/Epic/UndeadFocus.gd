# res://Scripts/PassiveAbilities/Epic/UndeadFocus.gd
extends PassiveAbility

func _init():
	id = "undead_focus"
	name = "Нежить фокус"
	description = "Каждый ход накапливает концентрацию, увеличивающую урон. Максимум 5 стаков. Сбрасывается при получении урона."
	rarity = "epic"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_TURN_START
	# Значения для каждого уровня: % урона за стак
	level_values = [5.0, 8.0, 12.0]  # +5%/8%/12% урона за стак
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var damage_per_stack = get_value_for_level(current_level)
	
	# Получаем текущее количество стаков концентрации
	var focus_stacks = owner.get_meta("undead_focus_stacks", 0)
	
	# Максимум 5 стаков
	if focus_stacks < 5:
		focus_stacks += 1
		owner.set_meta("undead_focus_stacks", focus_stacks)
		
		var total_damage_bonus = damage_per_stack * focus_stacks
		
		return {
			"success": true,
			"message": owner.display_name + " накапливает концентрацию! (Стак " + str(focus_stacks) + "/5, +" + str(int(total_damage_bonus)) + "% урона)",
			"focus_stacks": focus_stacks,
			"damage_bonus": total_damage_bonus,
			"effect": "undead_focus"
		}
	
	return {
		"success": true,
		"message": owner.display_name + " полностью сконцентрирован! (5/5 стаков)",
		"focus_stacks": 5,
		"damage_bonus": damage_per_stack * 5
	}

func get_stat_modifier(stat_name: String, current_level: int, owner: Node = null) -> float:
	if stat_name == "damage_percent" and owner:
		var focus_stacks = owner.get_meta("undead_focus_stacks", 0)
		var damage_per_stack = get_value_for_level(current_level)
		return damage_per_stack * focus_stacks
	return 0.0


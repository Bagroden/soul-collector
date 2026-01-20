# res://Scripts/PassiveAbilities/Rare/TharnokArmor.gd
extends PassiveAbility

func _init():
	id = "tharnok_armor"
	name = "Броня Тарнока"
	description = "Увеличивает защиту на X"
	rarity = "uncommon"
	ability_type = AbilityType.DEFENSIVE
	trigger_type = TriggerType.PASSIVE
	# Значения для каждого уровня: +защиты
	level_values = [20.0, 35.0, 55.0]  # +20/+35/+55 защиты
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Постоянный эффект уже применен в _apply_passive_effects
	# Здесь только возвращаем информацию о способности
	
	return {
		"success": true,
		"message": owner.display_name + " получает броню Тарнока!",
		"effect": "tharnok_armor"
	}

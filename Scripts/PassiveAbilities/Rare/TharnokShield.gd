# res://Scripts/PassiveAbilities/Rare/TharnokShield.gd
extends PassiveAbility

func _init():
	id = "tharnok_shield"
	name = "Щит Тарнока"
	description = "Блокирует X% урона"
	rarity = "common"
	ability_type = AbilityType.DEFENSIVE
	trigger_type = TriggerType.PASSIVE
	# Значения для каждого уровня: % блокируемого урона
	level_values = [10.0, 20.0, 30.0]  # 10%/20%/30% блокирования
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Постоянный эффект уже применен в _apply_passive_effects
	# Здесь только возвращаем информацию о способности
	return {
		"success": true,
		"message": owner.display_name + " получает защиту щита Тарнока!",
		"effect": "tharnok_shield"
	}

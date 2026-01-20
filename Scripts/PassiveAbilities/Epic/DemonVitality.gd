# res://Scripts/PassiveAbilities/Epic/DemonVitality.gd
extends PassiveAbility

var vitality_bonus: int = 10

func _init():
	id = "demon_vitality"
	name = "Живучесть Демона"
	description = "Увеличивает живучесть на 10"
	rarity = "epic"
	ability_type = AbilityType.UTILITY
	trigger_type = TriggerType.PASSIVE
	value = 10.0  # +10 живучести

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Постоянный эффект - увеличивает живучесть
	owner.vitality += vitality_bonus
	# Пересчитываем бонусы от характеристик
	owner.calculate_stat_bonuses()
	owner.apply_stat_bonuses()
	
	return {
		"success": true,
		"message": owner.display_name + " становится более живучим!",
		"vitality_bonus": vitality_bonus,
		"effect": "demon_vitality"
	}

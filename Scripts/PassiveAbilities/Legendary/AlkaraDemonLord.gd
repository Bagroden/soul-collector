# res://Scripts/PassiveAbilities/Legendary/AlkaraDemonLord.gd
extends PassiveAbility

var strength_bonus: int = 20
var intelligence_bonus: int = 20

func _init():
	id = "alkara_demon_lord"
	name = "Владыка демонов"
	description = "Сила и интеллект увеличены на 20 единиц"
	rarity = "legendary"
	ability_type = AbilityType.UTILITY
	trigger_type = TriggerType.PASSIVE
	value = 20.0  # +20 к силе и интеллекту

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Постоянный эффект - увеличивает силу и интеллект
	owner.strength += strength_bonus
	owner.intelligence += intelligence_bonus
	
	# Пересчитываем бонусы от характеристик
	if owner.has_method("calculate_stat_bonuses"):
		owner.calculate_stat_bonuses()
	if owner.has_method("apply_stat_bonuses"):
		owner.apply_stat_bonuses()
	
	return {
		"success": true,
		"message": owner.display_name + " становится владыкой демонов!",
		"strength_bonus": strength_bonus,
		"intelligence_bonus": intelligence_bonus,
		"effect": "alkara_demon_lord"
	}

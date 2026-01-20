# res://Scripts/PassiveAbilities/Epic/MousePack.gd
extends PassiveAbility

var agility_bonus: int = 15

func _init():
	id = "mouse_pack"
	name = "Ловкий"
	description = "Увеличение ловкости на 15"
	rarity = "epic"
	ability_type = AbilityType.UTILITY
	trigger_type = TriggerType.PASSIVE
	value = 15.0  # +15 ловкости

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Постоянный эффект - увеличивает ловкость
	return {
		"success": true,
		"message": owner.display_name + " становится более ловким!",
		"agility_bonus": agility_bonus,
		"effect": "mouse_pack"
	}

# res://Scripts/PassiveAbilities/Epic/AlkaraSoulDrain.gd
extends PassiveAbility

var soul_multiplier: float = 1.5  # +50% душ

func _init():
	id = "alkara_soul_drain"
	name = "Поглощение души"
	description = "Увеличивает количество получаемых душ после победы над врагом на 50%"
	rarity = "epic"
	ability_type = AbilityType.UTILITY
	trigger_type = TriggerType.PASSIVE
	value = 50.0  # +50% душ

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Постоянный эффект - увеличивает получаемые души
	return {
		"success": true,
		"message": owner.display_name + " усиливает поглощение душ!",
		"soul_multiplier": soul_multiplier,
		"effect": "alkara_soul_drain"
	}

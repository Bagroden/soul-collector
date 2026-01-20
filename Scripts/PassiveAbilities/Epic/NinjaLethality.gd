# res://Scripts/PassiveAbilities/Epic/NinjaLethality.gd
extends PassiveAbility

var backstab_damage_multiplier: float = 2.0

func _init():
	id = "ninja_lethality"
	name = "Летальность"
	description = "Увеличивает урон в спину на 100%"
	rarity = "epic"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.PASSIVE
	value = 100.0  # +100% урона в спину

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Постоянный эффект - увеличивает множитель урона в спину
	# Эта способность работает через систему ударов в спину в battle_manager
	return {
		"success": true,
		"message": owner.display_name + " становится более смертоносным!",
		"backstab_multiplier_bonus": backstab_damage_multiplier,
		"effect": "ninja_lethality"
	}

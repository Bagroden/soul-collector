# res://Scripts/PassiveAbilities/Legendary/CurseMaster.gd
extends PassiveAbility

var curse_amplification: float = 2.0

func _init():
	id = "curse_master"
	name = "Мастер проклятий"
	description = "Все проклятия накладываются с двойной силой"
	rarity = "legendary"
	ability_type = AbilityType.UTILITY
	trigger_type = TriggerType.PASSIVE
	value = 100.0  # 100% шанс

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Постоянный эффект - усиливает все проклятия
	return {
		"success": true,
		"message": owner.display_name + " усиливает все проклятия!",
		"effect": "curse_master"
	}

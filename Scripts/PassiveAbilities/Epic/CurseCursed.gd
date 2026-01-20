# res://Scripts/PassiveAbilities/Epic/CurseCursed.gd
extends PassiveAbility

var armor_per_hit: int = 1
var magic_resistance_per_hit: int = 1

func _init():
	id = "curse_cursed"
	name = "Проклятый"
	description = "За каждый полученный удар получает 1 ед. брони и 1% магического сопротивления"
	rarity = "epic"
	ability_type = AbilityType.DEFENSIVE
	trigger_type = TriggerType.ON_DAMAGE_TAKEN
	value = 100.0  # 100% шанс при получении урона

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Увеличиваем защиту и магическое сопротивление
	owner.defense += armor_per_hit
	owner.magic_resistance += magic_resistance_per_hit
	
	return {
		"success": true,
		"message": owner.display_name + " становится сильнее от проклятия!",
		"armor_bonus": armor_per_hit,
		"magic_resistance_bonus": magic_resistance_per_hit,
		"effect": "curse_cursed"
	}

# res://Scripts/PassiveAbilities/Rare/Infection.gd
extends PassiveAbility

var poison_damage: int = 5
var poison_duration: float = 5.0

func _init():
	id = "infection"
	name = "Инфекция"
	description = "15% шанс отравить врага (5 урона ядом в течение 5 раундов, стакается 5 раз)"
	rarity = "rare"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	value = 15.0
	max_stacks = 5

func execute_ability(owner: Node, target: Node = null, _context: Dictionary = {}) -> Dictionary:
	if not target:
		return {"success": false, "message": "Нет цели для инфекции"}
	
	if randf() < (value / 100.0):
		if target.has_method("add_effect"):
			target.add_effect("poison", poison_duration, 1)
		
		return {
			"success": true,
			"message": owner.display_name + " заражает " + target.display_name + "!",
			"effect": "poison",
			"duration": poison_duration,
			"stacks": 1
		}
	
	return {"success": false, "message": "Инфекция не сработала"}

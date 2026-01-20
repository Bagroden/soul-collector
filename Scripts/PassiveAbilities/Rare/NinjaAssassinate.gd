# res://Scripts/PassiveAbilities/Rare/NinjaAssassinate.gd
extends PassiveAbility

var assassinate_multiplier: float = 2.0

func _init():
	id = "ninja_assassinate"
	name = "Убийство ниндзя"
	description = "30% шанс атаковать в спину (урон x1.5)"
	rarity = "rare"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	value = 30.0  # 30% шанс удара в спину

func execute_ability(owner: Node, target: Node = null, _context: Dictionary = {}) -> Dictionary:
	if not target:
		return {"success": false, "message": "Нет цели для убийства"}
	
	# Эта способность теперь работает через систему ударов в спину в battle_manager
	# Она просто увеличивает шанс удара в спину
	return {
		"success": true,
		"message": owner.display_name + " готовится к удару из тени!",
		"backstab_chance_bonus": value / 100.0,
		"effect": "ninja_assassinate"
	}

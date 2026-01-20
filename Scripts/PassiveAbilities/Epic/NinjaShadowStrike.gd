# res://Scripts/PassiveAbilities/Epic/NinjaShadowStrike.gd
extends PassiveAbility

func _init():
	id = "ninja_shadow_strike"
	name = "Удар из тени"
	description = "50% шанс атаковать в спину (урон x1.5)"
	rarity = "epic"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	value = 50.0  # 50% шанс удара в спину

func execute_ability(owner: Node, target: Node = null, _context: Dictionary = {}) -> Dictionary:
	if not target:
		return {"success": false, "message": "Нет цели для удара из тени"}
	
	# Эта способность работает через систему ударов в спину в battle_manager
	return {
		"success": true,
		"message": owner.display_name + " исчезает в тени!",
		"backstab_chance_bonus": value / 100.0,
		"effect": "ninja_shadow_strike"
	}

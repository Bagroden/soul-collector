# res://Scripts/PassiveAbilities/Common/QuickStrike.gd
extends PassiveAbility

func _init():
	id = "quick_strike"
	name = "Быстрый удар"
	description = "Шанс атаковать дважды за ход"
	rarity = "common"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	value = 15.0  # 15% шанс двойной атаки

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Проверяем шанс двойной атаки
	if randf() < (value / 100.0):
		# Добавляем эффект для дополнительной атаки
		if owner.has_method("add_effect"):
			owner.add_effect("quick_strike", 1.0, 1)
		
		return {
			"success": true,
			"message": owner.display_name + " готов к двойной атаке!",
			"effect": "quick_strike"
		}
	
	return {"success": false, "message": "Быстрый удар не сработал"}

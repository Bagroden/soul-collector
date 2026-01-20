# res://Scripts/PassiveAbilities/Common/RatBite.gd
extends PassiveAbility

var extra_damage: int = 5  # Дополнительный урон

func _init():
	id = "rat_bite"
	name = "Крысиный укус"
	description = "15% шанс нанести дополнительный урон при атаке"
	rarity = "common"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	value = 15.0  # 15% шанс

func execute_ability(owner: Node, target: Node = null, _context: Dictionary = {}) -> Dictionary:
	if not target:
		return {"success": false, "message": "Нет цели для укуса"}
	
	# Проверяем шанс укуса
	if randf() < (value / 100.0):
		var _damage = _context.get("damage", 0)
		var extra_damage_amount = extra_damage
		
		return {
			"success": true,
			"message": owner.display_name + " кусает " + target.display_name + "!",
			"extra_damage": extra_damage_amount,
			"effect": "rat_bite"
		}
	
	return {"success": false, "message": "Крысиный укус не сработал"}

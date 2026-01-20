# res://Scripts/PassiveAbilities/Uncommon/MouseNimble.gd
extends PassiveAbility

func _init():
	id = "mouse_nimble"
	name = "Проворство мыши"
	description = "15% шанс увернуться от атаки"
	rarity = "uncommon"
	ability_type = AbilityType.DEFENSIVE
	trigger_type = TriggerType.ON_DAMAGE_TAKEN
	value = 15.0  # 15% шанс

func execute_ability(owner: Node, _target: Node = null, context: Dictionary = {}) -> Dictionary:
	var damage_amount = context.get("damage", 0)
	
	# Проверяем шанс уворота
	if randf() < (value / 100.0):
		return {
			"success": true,
			"message": owner.display_name + " проворно увернулась!",
			"damage_blocked": damage_amount,
			"effect": "mouse_nimble"
		}
	
	return {"success": false, "message": "Проворство не сработало"}

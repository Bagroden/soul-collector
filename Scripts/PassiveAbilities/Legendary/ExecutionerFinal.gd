# res://Scripts/PassiveAbilities/Legendary/ExecutionerFinal.gd
extends PassiveAbility

var damage_multiplier: float = 3.0  # +300% урона
var counter_attack_duration: float = 1.0  # 1 ход для контратаки

func _init():
	id = "executioner_final"
	name = "Последний приговор"
	description = "При получении смертельного урона не умирает, вместо этого его хп снижается до 1 и проводит контратаку с усилением в 300% к урону"
	rarity = "legendary"
	ability_type = AbilityType.DEFENSIVE
	trigger_type = TriggerType.ON_DAMAGE_TAKEN
	value = 100.0  # 100% шанс при смертельном уроне

func execute_ability(owner: Node, _target: Node = null, context: Dictionary = {}) -> Dictionary:
	# Проверяем, что владелец получает смертельный урон
	var damage_amount = context.get("damage", 0)
	var current_hp = owner.hp
	
	if current_hp <= damage_amount and current_hp > 0:
		# Устанавливаем HP в 1
		owner.hp = 1
		
		# Накладываем эффект усиленной контратаки
		if owner.has_method("add_effect"):
			owner.add_effect("final_judgment", counter_attack_duration, 1, {
				"damage_multiplier": damage_multiplier
			})
		
		return {
			"success": true,
			"message": owner.display_name + " выносит последний приговор!",
			"hp_set_to": 1,
			"damage_multiplier": damage_multiplier,
			"effect": "executioner_final"
		}
	
	return {"success": false, "message": "Последний приговор не активирован"}

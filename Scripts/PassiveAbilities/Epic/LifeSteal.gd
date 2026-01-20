# res://Scripts/PassiveAbilities/Epic/LifeSteal.gd
extends PassiveAbility

func _init():
	id = "life_steal"
	name = "Вампиризм"
	description = "Восстановление 20% здоровья от нанесенного магического урона"
	rarity = "epic"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	value = 20.0  # 20% от урона в здоровье

func execute_ability(owner: Node, _target: Node = null, context: Dictionary = {}) -> Dictionary:
	var damage_dealt = context.get("damage", 0)
	var heal_amount = int(damage_dealt * (value / 100.0))
	
	if heal_amount > 0 and owner.has_method("heal"):
		owner.heal(heal_amount)
		
		return {
			"success": true,
			"message": owner.display_name + " восстанавливает " + str(heal_amount) + " здоровья!",
			"heal_amount": heal_amount,
			"effect": "life_steal"
		}
	
	return {"success": false, "message": "Вампиризм не сработал"}

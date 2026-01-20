# res://Scripts/PassiveAbilities/Legendary/MouseKing.gd
extends PassiveAbility

var counter_damage: float = 0.8  # 80% от заблокированного урона

func _init():
	id = "mouse_king"
	name = "Смертельный уворот"
	description = "При срабатывании уворота есть 50% шанс провести контр атаку"
	rarity = "legendary"
	ability_type = AbilityType.DEFENSIVE
	trigger_type = TriggerType.ON_DAMAGE_TAKEN
	value = 50.0  # 50% шанс контр атаки

func execute_ability(owner: Node, target: Node = null, context: Dictionary = {}) -> Dictionary:
	var damage_amount = context.get("damage", 0)
	
	# Проверяем шанс смертельного уворота
	if randf() < (value / 100.0):
		var counter_damage_amount = int(damage_amount * counter_damage)
		
		# Контратакуем
		if target and target.has_method("take_damage"):
			target.take_damage(counter_damage_amount)
			# Показываем всплывающую цифру урона от контратаки
			if DamageNumberManager.instance:
				DamageNumberManager.show_damage_on_character(target, counter_damage_amount, false, false, false, "physical")
		
		return {
			"success": true,
			"message": owner.display_name + " совершает смертельный уворот и контратакует!",
			"damage_blocked": damage_amount,
			"counter_damage": counter_damage_amount,
			"effect": "mouse_king"
		}
	
	return {"success": false, "message": "Смертельный уворот не сработал"}

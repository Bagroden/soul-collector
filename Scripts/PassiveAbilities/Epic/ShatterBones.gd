# res://Scripts/PassiveAbilities/Epic/ShatterBones.gd
extends PassiveAbility

func _init():
	id = "shatter_bones"
	name = "Раздробление костей"
	description = "Шанс оглушить противника на 1 раунд"
	rarity = "epic"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	# Значения для каждого уровня: % шанса оглушения
	level_values = [10.0, 17.0, 25.0]  # 10%/17%/25% шанс
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var stun_chance = get_value_for_level(current_level)
	
	# Проверяем шанс оглушения
	var roll = randf() * 100.0
	
	if roll <= stun_chance and target:
		# Применяем оглушение на 1 раунд
		target.set_meta("stunned", true)
		target.set_meta("stun_duration", 1)
		
		return {
			"success": true,
			"message": owner.display_name + " оглушает " + target.display_name + "!",
			"stunned": true,
			"duration": 1,
			"effect": "shatter_bones"
		}
	
	return {"success": false}


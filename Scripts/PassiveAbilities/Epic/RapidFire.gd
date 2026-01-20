# res://Scripts/PassiveAbilities/Epic/RapidFire.gd
extends PassiveAbility

func _init():
	id = "rapid_fire"
	name = "Быстрая стрельба"
	description = "Шанс дополнительного выстрела при атаке"
	rarity = "epic"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	# Значения для каждого уровня: % шанс дополнительного выстрела
	level_values = [20.0, 30.0, 45.0]  # 20%/30%/45% шанс
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var proc_chance = get_value_for_level(current_level)
	
	var roll = randf() * 100.0
	
	if roll <= proc_chance and target:
		# Отмечаем, что следующая атака будет двойной
		if not owner.has_meta("rapid_fire_active"):
			owner.set_meta("rapid_fire_active", true)
			
			return {
				"success": true,
				"message": owner.display_name + " делает быстрый выстрел!",
				"extra_attack": true,
				"effect": "rapid_fire"
			}
	
	return {"success": false}


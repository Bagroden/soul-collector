# res://Scripts/PassiveAbilities/Legendary/Assassinate.gd
extends PassiveAbility

func _init():
	id = "assassinate"
	name = "Убийство"
	description = "Огромный урон при низком HP цели"
	rarity = "legendary"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	# Значения для каждого уровня: множитель урона при HP цели < 30%
	level_values = [2.5, 3.5, 5.0]  # x2.5/x3.5/x5.0 урон
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var assassinate_multiplier = get_value_for_level(current_level)
	
	if target:
		var target_hp_percent = (float(target.hp) / float(target.max_hp)) * 100.0
		
		# Если HP цели меньше 30%, активируем убийство
		if target_hp_percent <= 30.0:
			# Отмечаем, что следующая атака будет убийством
			if not owner.has_meta("assassinate_active"):
				owner.set_meta("assassinate_active", true)
				owner.set_meta("assassinate_multiplier", assassinate_multiplier)
				
				return {
					"success": true,
					"message": owner.display_name + " готовится к убийству!",
					"damage_multiplier": assassinate_multiplier,
					"effect": "assassinate"
				}
	
	return {"success": false}


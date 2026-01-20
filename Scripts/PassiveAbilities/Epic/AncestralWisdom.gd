# res://Scripts/PassiveAbilities/Epic/AncestralWisdom.gd
extends PassiveAbility

func _init():
	id = "ancestral_wisdom"
	name = "Мудрость предков"
	description = "Конвертирует часть потраченной маны на каст заклинания в барьер."
	rarity = "epic"
	ability_type = AbilityType.DEFENSIVE
	trigger_type = TriggerType.ON_ABILITY_USE
	# Значения для каждого уровня: % потраченной маны, конвертируемой в барьер
	level_values = [30.0, 60.0, 100.0]  # 30%/60%/100% потраченной маны в барьер
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var mana_to_barrier_percent = get_value_for_level(current_level)
	
	# Получаем количество потраченной маны из контекста
	var mana_spent = _context.get("mana_spent", 0)
	
	if mana_spent > 0 and owner.has_method("add_magic_barrier"):
		# Конвертируем часть маны в барьер
		var barrier_amount = int(mana_spent * (mana_to_barrier_percent / 100.0))
		
		if barrier_amount > 0:
			owner.add_magic_barrier(barrier_amount)
			
			return {
				"success": true,
				"message": owner.display_name + " конвертирует " + str(barrier_amount) + " маны в барьер!",
				"barrier_amount": barrier_amount,
				"effect": "ancestral_wisdom"
			}
	
	return {"success": false}


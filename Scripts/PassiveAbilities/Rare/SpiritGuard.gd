# res://Scripts/PassiveAbilities/Rare/SpiritGuard.gd
extends PassiveAbility

func _init():
	id = "spirit_guard"
	name = "Духовный страж"
	description = "Создает магический барьер, который поглощает урон"
	rarity = "rare"
	ability_type = AbilityType.DEFENSIVE
	trigger_type = TriggerType.PASSIVE
	# Значения для каждого уровня: множитель мудрости для барьера
	level_values = [1.8, 2.3, 3.0]  # Мудрость × 1.8/2.3/3.0
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var barrier_multiplier = get_value_for_level(current_level)
	
	# Создаем магический барьер на основе мудрости
	if owner.has_method("get_wisdom"):
		var wisdom = owner.get_wisdom()
		var barrier_amount = int(wisdom * barrier_multiplier)
		
		if owner.has_method("add_magic_barrier"):
			owner.add_magic_barrier(barrier_amount)
			
			return {
				"success": true,
				"message": owner.display_name + " создает духовный барьер!",
				"barrier_amount": barrier_amount,
				"effect": "spirit_guard"
			}
	
	return {"success": false}


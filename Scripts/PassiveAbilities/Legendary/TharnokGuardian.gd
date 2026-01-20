# res://Scripts/PassiveAbilities/Legendary/TharnokGuardian.gd
extends PassiveAbility

func _init():
	id = "tharnok_guardian"
	name = "Страж Тарнока"
	description = "Отражает часть урона атакующему"
	rarity = "epic"
	ability_type = AbilityType.DEFENSIVE
	trigger_type = TriggerType.ON_DAMAGE_TAKEN
	# Значения для каждого уровня: % отраженного урона
	level_values = [20.0, 35.0, 50.0]  # 20%/35%/50% отражения
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var reflect_percent = get_value_for_level(current_level)
	
	# Получаем фактический урон из контекста (урон после вычета брони)
	var actual_damage = _context.get("damage", 0)
	if actual_damage <= 0 or not target:
		return {"success": false}
	
	# Вычисляем отраженный урон от фактического урона
	var reflected_damage = int(actual_damage * (reflect_percent / 100.0))
	
	if reflected_damage > 0:
		return {
			"success": true,
			"message": owner.display_name + " отражает " + str(reflected_damage) + " урона!",
			"reflected_damage": reflected_damage,
			"effect": "tharnok_guardian"
		}
	
	return {"success": false}

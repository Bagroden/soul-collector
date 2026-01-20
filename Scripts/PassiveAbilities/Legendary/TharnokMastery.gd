# res://Scripts/PassiveAbilities/Legendary/TharnokMastery.gd
extends PassiveAbility

func _init():
	id = "tharnok_mastery"
	name = "Стойкость Тарнока"
	description = "При получении урона от ударов получает стаки 'Кровь демона'. Каждый стак 'Кровь демона' дает регенерацию здоровья на 3 раунда. Максимум 5 стаков. X% регенерация здоровья за стак"
	rarity = "legendary"
	ability_type = AbilityType.SPECIAL
	trigger_type = TriggerType.ON_DAMAGE_TAKEN
	# Значения для каждого уровня: % регенерации за стак
	level_values = [1.0, 2.0, 3.0]  # 1%/2%/3% регенерации за стак
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = context.get("ability_level", 1)
	var regen_percent = get_value_for_level(current_level)
	
	# Получаем фактический урон из контекста
	var actual_damage = context.get("damage", 0)
	if actual_damage <= 0:
		return {"success": false}
	
	# Добавляем стак "Кровь демона" (максимум 5 стаков)
	if owner.has_method("add_effect") and owner.has_method("get_effect_stacks"):
		var demon_blood_stacks = owner.get_effect_stacks("demon_blood")
		if demon_blood_stacks < 5:
			# Добавляем новый стак или обновляем существующий
			if owner.has_effect("demon_blood"):
				# Обновляем существующий эффект через add_effect (он сам увеличит стаки)
				owner.add_effect("demon_blood", 3.0, 1, {"regen_percent": regen_percent})
			else:
				# Создаем новый эффект
				owner.add_effect("demon_blood", 3.0, 1, {"regen_percent": regen_percent})
			
			var final_stacks = owner.get_effect_stacks("demon_blood")
			return {
				"success": true,
				"message": owner.display_name + " получает стак 'Кровь демона'! (" + str(final_stacks) + "/5)",
				"effect": "tharnok_mastery",
				"stacks": final_stacks
			}
	
	return {"success": false}

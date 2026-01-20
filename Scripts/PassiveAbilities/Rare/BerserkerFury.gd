# res://Scripts/PassiveAbilities/Rare/BerserkerFury.gd
extends PassiveAbility

func _init():
	id = "berserker_fury"
	name = "Боевое безумие"
	description = "Получение стаков при получении урона. Увеличение урона и скорости за каждый стак. Максимум 5 стаков."
	rarity = "rare"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_DAMAGE_TAKEN
	# Значения для каждого уровня: % увеличения скорости и физического урона за стак
	# Формат: [speed_bonus, damage_bonus] для каждого уровня
	# 1 уровень: +3% скорость, +3% урон, -5% меткость за стак
	# 2 уровень: +5% скорость, +5% урон, -5% меткость за стак
	# 3 уровень: +7% скорость, +7% урон, -5% меткость за стак
	level_values = [3.0, 5.0, 7.0]  # % бонуса за стак
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var damage_type = _context.get("damage_type", "physical")
	
	# Боевое безумие не срабатывает от дотов (bleeding, poison, rotten, neurotoxin)
	if damage_type in ["bleeding", "poison", "rotten", "neurotoxin"]:
		return {"success": false}
	
	# Проверяем, есть ли уже эффект "Боевое безумие"
	if owner and owner.has_method("add_effect"):
		var fury_bonus_per_stack = get_value_for_level(current_level)
		var accuracy_penalty = 5.0  # -5% меткости за стак
		
		# Добавляем стак Боевого безумия (максимум 5 стаков, длительность 2 раунда)
		if "berserker_fury" in owner.effects:
			var existing_effect = owner.effects["berserker_fury"]
			var fury_stacks = existing_effect.get("stacks", 1)
			# Увеличиваем стаки (максимум 5)
			existing_effect["stacks"] = min(fury_stacks + 1, 5)
			existing_effect["duration"] = 2.0  # Обновляем длительность до 2 раундов
			existing_effect["speed_bonus_per_stack"] = fury_bonus_per_stack
			existing_effect["damage_bonus_per_stack"] = fury_bonus_per_stack
			existing_effect["accuracy_penalty_per_stack"] = accuracy_penalty
		else:
			# Создаем новый эффект
			owner.add_effect("berserker_fury", 2.0, 1, {
				"speed_bonus_per_stack": fury_bonus_per_stack,
				"damage_bonus_per_stack": fury_bonus_per_stack,
				"accuracy_penalty_per_stack": accuracy_penalty
			})
		
		var final_stacks = owner.effects.get("berserker_fury", {}).get("stacks", 1)
		return {
			"success": true,
			"message": owner.display_name + " получает стак Боевого безумия! (Стаков: " + str(final_stacks) + "/5)",
			"effect": "berserker_fury",
			"stacks": final_stacks
		}
	
	return {"success": false}

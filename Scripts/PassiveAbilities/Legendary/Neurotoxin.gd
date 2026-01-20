# res://Scripts/PassiveAbilities/Legendary/Neurotoxin.gd
extends PassiveAbility

func _init():
	id = "neurotoxin"                                 # ⚠️ ВАЖНО: Уникальный ID
	name = "Нейротоксин"                              # ⚠️ ВАЖНО: Отображаемое имя
	description = "17% шанс при атаке наложить нейротоксин. Нейротоксин уменьшает меткость цели на X% за стак. Максимум 3 стака"
	rarity = "legendary"                                   # ⚠️ ВАЖНО: Редкость способности
	ability_type = AbilityType.OFFENSIVE              # ⚠️ ВАЖНО: Тип способности
	trigger_type = TriggerType.ON_ATTACK              # ⚠️ ВАЖНО: Когда срабатывает
	# Значения для каждого уровня
	level_values = [5.0, 10.0, 15.0]  # -5%/-10%/-15% меткости за стак
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(_owner: Node, target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", _context.get("level", 1))
	var current_value = get_value_for_level(current_level)
	
	# Проверяем шанс срабатывания (17%)
	if randf() * 100 < 17.0:
		if target and target.has_method("add_effect"):
			# Проверяем, есть ли уже нейротоксин
			if target.has_effect("neurotoxin"):
				var existing_effect = target.effects["neurotoxin"]
				var existing_stacks = existing_effect.get("stacks", 1)
				
				# Увеличиваем стаки (максимум 3)
				if existing_stacks < 3:
					target.add_effect("neurotoxin", 5.0, existing_stacks + 1, {"accuracy_reduction": current_value})
					return {
						"success": true,
						"message": "Нейротоксин усилен! " + target.display_name + " получает " + str(existing_stacks + 1) + " стак нейротоксина (меткость -" + str(int(current_value * (existing_stacks + 1))) + "%)",
						"effect": "neurotoxin",
						"target": target
					}
				else:
					return {
						"success": true,
						"message": "Нейротоксин уже на максимуме! " + target.display_name + " имеет 3 стака нейротоксина",
						"effect": "neurotoxin_max",
						"target": target
					}
			else:
				# Накладываем первый стак нейротоксина
				target.add_effect("neurotoxin", 5.0, 1, {"accuracy_reduction": current_value})
				return {
					"success": true,
					"message": "Нейротоксин! " + target.display_name + " отравлен нейротоксином (меткость -" + str(int(current_value)) + "%)",
					"effect": "neurotoxin",
					"target": target
				}
	
	return {"success": false, "message": "Нейротоксин не сработал"}

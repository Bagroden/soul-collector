# res://Scripts/PassiveAbilities/Rare/SneakyStrike.gd
extends PassiveAbility

func _init():
	id = "sneaky_strike"                              # ⚠️ ВАЖНО: Уникальный ID
	name = "Подлый удар"                              # ⚠️ ВАЖНО: Отображаемое имя
	description = "X% шанс при атаке игнорировать броню цели"
	rarity = "rare"                               # ⚠️ ВАЖНО: Редкость способности
	ability_type = AbilityType.OFFENSIVE              # ⚠️ ВАЖНО: Тип способности
	trigger_type = TriggerType.ON_ATTACK              # ⚠️ ВАЖНО: Когда срабатывает
	# Значения для каждого уровня
	level_values = [10.0, 20.0, 30.0]  # 10%/20%/30% шанс игнорировать броню
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", _context.get("level", 1))
	var current_value = get_value_for_level(current_level)
	
	# Проверяем шанс срабатывания
	if randf() * 100 < current_value:
		# Добавляем эффект игнорирования брони
		if target and target.has_method("add_effect"):
			target.add_effect("armor_ignore", 1.0, 1, {"ignore_armor": true})
			
			return {
				"success": true,
				"message": "Подлый удар - " + owner.display_name + " игнорирует броню " + target.display_name + "!",
				"effect": "armor_ignore",
				"target": target
			}
	
	return {"success": false, "message": "Подлый удар не сработал"}

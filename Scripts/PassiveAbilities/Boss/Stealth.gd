# res://Scripts/PassiveAbilities/Boss/Stealth.gd
extends PassiveAbility

func _init():
	id = "stealth"                              # ⚠️ ВАЖНО: Уникальный ID
	name = "Скрытность"                         # ⚠️ ВАЖНО: Отображаемое имя
	description = "В начале боя становится невидимым на 2 хода. В невидимости получает +50% к урону и +25% к увороту."
	rarity = "boss"                             # ⚠️ ВАЖНО: Редкость способности
	ability_type = AbilityType.UTILITY          # ⚠️ ВАЖНО: Тип способности
	trigger_type = TriggerType.ON_TURN_START    # ⚠️ ВАЖНО: Когда срабатывает
	# Значения для каждого уровня
	level_values = [2.0, 3.0, 4.0]  # 2/3/4 хода невидимости
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", _context.get("level", 1))
	var current_value = get_value_for_level(current_level)
	
	# Получаем номер раунда из контекста
	var round_number = _context.get("round_number", 1)
	
	print("Скрытность: владелец=", owner.display_name, ", уровень=", current_level, ", раунд=", round_number)
	
	# Активируем невидимость только в начале боя (первые 2-4 хода)
	if round_number <= current_value:
		if owner.has_method("add_effect"):
			owner.add_effect("stealth", current_value, 1, {
				"damage_bonus": 0.5,  # +50% к урону
				"dodge_bonus": 0.25   # +25% к увороту
			})
			return {
				"success": true,
				"message": "Скрытность - " + owner.display_name + " становится невидимым! (+50% урон, +25% уворот)",
				"effect": "stealth",
				"duration": current_value
			}
	
	return {"success": false, "message": "Скрытность не активирована"}

# res://Scripts/PassiveAbilities/Common/Restlessness.gd
extends PassiveAbility

func _init():
	id = "restlessness"                         # ⚠️ ВАЖНО: Уникальный ID
	name = "Суетливость"                        # ⚠️ ВАЖНО: Отображаемое имя
	description = "X% шанс двойной атаки с уменьшенным уроном на Y%"
	rarity = "common"                           # ⚠️ ВАЖНО: Редкость способности
	ability_type = AbilityType.OFFENSIVE      # ⚠️ ВАЖНО: Тип способности
	trigger_type = TriggerType.ON_ATTACK       # ⚠️ ВАЖНО: Когда срабатывает
	# Значения для каждого уровня
	level_values = [20.0, 30.0, 40.0]  # 20%/30%/40% шанс двойной атаки
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", _context.get("level", 1))
	var current_value = get_value_for_level(current_level)
	
	# Значения уменьшения урона для каждого уровня (в десятичных дробях)
	var damage_reduction = [0.4, 0.35, 0.3][current_level - 1]  # 0.4 = 40%
	
	
	# Проверяем шанс двойной атаки
	var roll = randf() * 100
	if roll < current_value:
		# Добавляем эффект для дополнительной атаки
		owner.add_effect("restlessness_attack", 1.0, 1, {"damage_reduction": damage_reduction})
		
		print("✅ СУЕТЛИВОСТЬ СРАБОТАЛА! ", owner.display_name, " (шанс: ", current_value, "%, выпало: ", snappedf(roll, 0.01), "%)")
		
		return {
			"success": true,
			"message": "Суетливость - " + owner.display_name + " совершает двойную атаку! (урон -" + str(int(damage_reduction * 100)) + "%)",
			"effect": "restlessness_attack",
			"damage_reduction": damage_reduction,
			"extra_action": true
		}
	
	# print("❌ Суетливость не сработала для ", owner.display_name, " (шанс: ", current_value, "%, выпало: ", snappedf(roll, 0.01), "%)")
	return {"success": false, "message": "Суетливость не сработала"}

# res://Scripts/PassiveAbilities/Boss/ShadowStrike.gd
extends PassiveAbility

func _init():
	id = "shadow_strike"                        # ⚠️ ВАЖНО: Уникальный ID
	name = "Теневой удар"                       # ⚠️ ВАЖНО: Отображаемое имя
	description = "При атаке имеет шанс нанести дополнительный теневой урон, который игнорирует броню."
	rarity = "boss"                             # ⚠️ ВАЖНО: Редкость способности
	ability_type = AbilityType.OFFENSIVE        # ⚠️ ВАЖНО: Тип способности
	trigger_type = TriggerType.ON_ATTACK        # ⚠️ ВАЖНО: Когда срабатывает
	# Значения для каждого уровня
	level_values = [15.0, 20.0, 25.0]  # 15%/20%/25% шанс теневого удара
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", _context.get("level", 1))
	var current_value = get_value_for_level(current_level)
	
	print("Теневой удар: владелец=", owner.display_name, ", уровень=", current_level, ", шанс=", current_value, "%")
	
	# Проверяем шанс теневого удара
	if randf() < (current_value / 100.0):
		# Рассчитываем теневой урон (игнорирует броню)
		var shadow_damage = int(owner.attack_power * 0.5)  # 50% от атаки
		
		# Наносим теневой урон цели (игнорирует броню)
		if _target and _target.has_method("take_damage"):
			_target.take_damage(shadow_damage, "shadow")
			return {
				"success": true,
				"message": "Теневой удар - " + owner.display_name + " наносит теневой урон! Урон: " + str(shadow_damage) + " (игнорирует броню)",
				"effect": "shadow_strike",
				"damage": shadow_damage,
				"damage_type": "shadow"
			}
	
	return {"success": false, "message": "Теневой удар не сработал"}

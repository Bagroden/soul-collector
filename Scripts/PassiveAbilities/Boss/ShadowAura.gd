# res://Scripts/PassiveAbilities/Boss/ShadowAura.gd
extends PassiveAbility

# Массив шансов невидимости для каждого уровня
var stealth_chances: Array[float] = [15.0, 20.0, 25.0]  # 15%/20%/25% шанс невидимости

func _init():
	id = "shadow_aura"                          # ⚠️ ВАЖНО: Уникальный ID
	name = "Теневая аура"                       # ⚠️ ВАЖНО: Отображаемое имя
	description = "Пассивно увеличивает уворот на 5/10/15%. Каждый ход 15/20/25% шанс войти в невидимость на 1 ход (+50% урон, +25% уворот)."
	rarity = "boss"                             # ⚠️ ВАЖНО: Редкость способности
	ability_type = AbilityType.UTILITY          # ⚠️ ВАЖНО: Тип способности (изменено на UTILITY)
	trigger_type = TriggerType.ON_TURN_START    # ⚠️ ВАЖНО: Когда срабатывает
	# Значения для каждого уровня: [бонус уворота%]
	level_values = [5.0, 10.0, 15.0]  # 5%/10%/15% к увороту
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", _context.get("level", 1))
	var dodge_bonus = get_value_for_level(current_level)
	var stealth_chance = stealth_chances[current_level - 1]
	
	# 1. ПАССИВНЫЙ ЭФФЕКТ: Применяем постоянный бонус к увороту (если еще не применен)
	if not owner.has_meta("shadow_aura_dodge_applied"):
		if owner.has_method("add_dodge_bonus"):
			owner.add_dodge_bonus(dodge_bonus / 100.0)
		owner.set_meta("shadow_aura_dodge_applied", true)
		print("Теневая аура: ", owner.display_name, " получает постоянный бонус +", dodge_bonus, "% к увороту")
	
	# 2. АКТИВНЫЙ ЭФФЕКТ: Проверяем шанс войти в невидимость
	var roll = randf() * 100.0
	if roll < stealth_chance:
		# Входим в невидимость на 1 ход
		if owner.has_method("add_effect"):
			owner.add_effect("stealth", 1.0, 1, {
				"damage_bonus": 0.5,  # +50% к урону
				"dodge_bonus": 0.25   # +25% к увороту
			})
			print("✨ Теневая аура: ", owner.display_name, " входит в невидимость! (шанс: ", stealth_chance, "%, выпало: ", snappedf(roll, 0.1), "%)")
			return {
				"success": true,
				"message": "✨ Теневая аура - " + owner.display_name + " растворяется в тенях! (+50% урон, +25% уворот на 1 ход)",
				"effect": "shadow_aura_stealth"
			}
	
	# Если невидимость не сработала, просто показываем пассивный бонус
	return {
		"success": true,
		"message": "",  # Не показываем сообщение каждый ход для пассивного бонуса
		"passive_dodge_bonus": dodge_bonus
	}

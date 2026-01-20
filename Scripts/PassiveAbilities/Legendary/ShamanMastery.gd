# res://Scripts/PassiveAbilities/Legendary/ShamanMastery.gd
extends PassiveAbility

func _init():
	id = "shaman_mastery"
	name = "Мастерство шамана"
	description = "Увеличивает мудрость и выпускает молнии во врагов при получении урона. Молния наносит 2 * мудрость магического урона."
	rarity = "legendary"
	ability_type = AbilityType.SPECIAL
	trigger_type = TriggerType.ON_DAMAGE_TAKEN
	# Значения для каждого уровня: +X к мудрости и % шанс молнии
	level_values = [15.0, 25.0, 40.0]  # +15/+25/+40 к мудрости
	# Вторичные значения: % шанс ударить молнией
	level_values_secondary = [30.0, 60.0, 100.0]  # 30%/60%/100% шанс молнии
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, attacker: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var wisdom_bonus = int(get_value_for_level(current_level))
	var lightning_chance = level_values_secondary[current_level - 1]
	
	# Увеличиваем мудрость (применяется один раз при активации способности)
	if not owner.has_meta("shaman_mastery_wisdom_applied"):
		if owner.has_method("set") and "wisdom" in owner:
			owner.wisdom += wisdom_bonus
			owner.set_meta("shaman_mastery_wisdom_applied", true)
			owner.set_meta("shaman_mastery_wisdom_bonus", wisdom_bonus)
	
	# Проверяем шанс молнии при получении урона
	if attacker and randf() * 100.0 <= lightning_chance:
		# Получаем мудрость владельца (с учетом бонуса)
		var wisdom = owner.wisdom if "wisdom" in owner else 0
		var lightning_damage = int(2 * wisdom)
		
		# Наносим урон молнией атакующему
		if attacker.has_method("take_damage"):
			attacker.take_damage(lightning_damage, "magic")
			
			return {
				"success": true,
				"message": owner.display_name + " выпускает молнию! Урон: " + str(lightning_damage),
				"lightning_damage": lightning_damage,
				"target": attacker,
				"effect": "shaman_mastery_lightning"
			}
	
	return {"success": false}


# res://Scripts/PassiveAbilities/Uncommon/BloodFlow.gd
extends PassiveAbility

func _init():
	id = "blood_flow"
	name = "Кровоток"
	description = "Шанс вызвать кровотечение от физического урона. Каждый стак кровотечения отнимает 2% от максимума ОЗ. Максимум 5 стаков."
	rarity = "rare"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	# Значения для каждого уровня
	level_values = [15.0, 25.0, 40.0]  # 15%/25%/40% шанс кровотечения
	value = level_values[0]  # Значение по умолчанию (1 уровень)
	duration = 3.0  # Кровотечение длится 3 хода

func execute_ability(_owner: Node, target: Node = null, _context: Dictionary = {}) -> Dictionary:
	if not target:
		return {"success": false, "message": "Нет цели для кровотечения"}
	
	# Проверяем, что урон физический
	var damage_type = _context.get("damage_type", "physical")
	if damage_type != "physical":
		return {"success": false, "message": "Кровотечение срабатывает только от физического урона"}
	
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var bleed_chance = get_value_for_level(current_level)
	
	# Проверяем шанс кровотечения
	if randf() < (bleed_chance / 100.0):
		# Применяем эффект кровотечения с 1 стаком
		if target.has_method("add_effect"):
			var source_id = _owner.get_instance_id() if _owner else 0
			target.add_effect("bleeding", duration, 1, {"source_id": source_id})
		
		# Формируем сообщение с учетом номера удара
		var hit_number = _context.get("hit_number", 0)
		var message = target.display_name + " истекает кровью!"
		if hit_number > 0:
			message += " (удар " + str(hit_number) + ")"
		
		return {
			"success": true,
			"message": message,
			"effect": "bleeding",
			"duration": duration,
			"stacks": 1
		}
	
	return {"success": false, "message": "Кровотечение не вызвано"}

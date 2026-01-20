# res://Scripts/PassiveAbilities/Rare/Revenge.gd
extends PassiveAbility

func _init():
	id = "revenge"                              # ⚠️ ВАЖНО: Уникальный ID
	name = "Месть"                              # ⚠️ ВАЖНО: Отображаемое имя
	description = "За каждые потерянные X ОЗ, в следующем раунде получает бонусное 1 ОД"
	rarity = "rare"                             # ⚠️ ВАЖНО: Редкость способности
	ability_type = AbilityType.UTILITY         # ⚠️ ВАЖНО: Тип способности
	trigger_type = TriggerType.ON_TURN_START  # ⚠️ ВАЖНО: Когда срабатывает
	# Значения для каждого уровня
	level_values = [200, 150, 100]  # 200/150/100 ОЗ за бонусное ОД
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", _context.get("level", 1))
	var current_value = get_value_for_level(current_level)
	
	# Получаем урон, полученный в этом раунде
	var round_number = _context.get("round_number", 0)
	var damage_this_round = 0
	
	# Получаем урон за раунд из переменной владельца
	if owner.has_method("get_damage_this_round"):
		damage_this_round = owner.get_damage_this_round()
	elif _context.has("damage_this_round"):
		damage_this_round = _context.get("damage_this_round", 0)
	else:
		# Если нет информации об уроне за раунд, используем старую логику как fallback
		var max_hp = owner.get_max_hp() if owner.has_method("get_max_hp") else owner.max_hp
		var current_hp = owner.hp if "hp" in owner else owner.current_hp
		damage_this_round = max_hp - current_hp
	
	# Вычисляем количество бонусных ОД на основе урона за раунд
	var bonus_actions = int(damage_this_round / current_value)
	
	# Проверяем, не были ли уже добавлены бонусные ОД в этом раунде
	if owner.has_method("get") and owner.get("revenge_used_round") == round_number:
		return {"success": false, "message": "Месть уже использована в этом раунде"}
	
	if bonus_actions > 0:
		# Применяем бонусные ОД
		if owner.has_method("add_action_points"):
			owner.add_action_points(bonus_actions)
			# Отмечаем, что месть использована в этом раунде
			if owner.has_method("set"):
				owner.set("revenge_used_round", round_number)
			print("Месть сработала! Добавлено ", bonus_actions, " бонусных ОД")
			return {
				"success": true,
				"message": "Месть - " + owner.display_name + " получает +" + str(bonus_actions) + " бонусных ОД!",
				"effect": "revenge_bonus",
				"bonus_actions": bonus_actions
			}
		else:
			print("ОШИБКА: У владельца нет метода add_action_points")
	
	print("Месть не сработала - недостаточно урона за раунд")
	return {"success": false, "message": "Месть не сработала"}

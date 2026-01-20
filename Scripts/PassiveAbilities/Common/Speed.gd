# res://Scripts/PassiveAbilities/Common/Speed.gd
extends PassiveAbility

func _init():
	id = "speed"
	name = "Скорость"
	description = "Шанс 7% получить еще одно действие в раунде"
	rarity = "common"
	ability_type = AbilityType.UTILITY
	trigger_type = TriggerType.ON_TURN_START
	value = 7.0  # 7% шанс дополнительного действия

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий раунд из контекста или другим способом
	# Если контекст не содержит раунда, пытаемся получить его через battle_manager (косвенно, так как battle_manager недоступен напрямую из пассивки)
	# Лучший способ - проверять speed_triggered_round на владельце
	
	# Проверяем, срабатывала ли уже скорость в этом раунде
	if owner.has_method("get") and owner.get("speed_triggered_round") != -1:
		return {"success": false, "message": "Скорость уже сработала в этом раунде"}
	
	# Проверяем шанс дополнительного действия в начале хода
	if randf() < (value / 100.0):
		# Дополнительное действие получено - добавляем очко действий
		if owner.has_method("add_action_point"):
			owner.add_action_point()
			
		# Запоминаем раунд срабатывания (мы не знаем точный номер раунда здесь, но если он не -1, то сработала)
		# В начале следующего раунда reset_round_counters сбросит его в -1
		if owner.has_method("set"):
			owner.set("speed_triggered_round", 999) # Ставим любое значение != -1
		
		return {
			"success": true,
			"message": owner.display_name + " получает дополнительное действие!",
			"effect": "extra_action"
		}
	
	return {"success": false, "message": "Дополнительное действие не получено"}

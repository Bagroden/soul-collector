# res://Scripts/Battle/BattleLog.gd
extends Node
class_name BattleLog

# Структура для записи события боя
class BattleEvent:
	var timestamp: float
	var event_type: String
	var actor: String
	var target: String
	var value: int
	var description: String
	var details: Dictionary
	
	func _init(time: float, type: String, actor_name: String, target_name: String = "", val: int = 0, desc: String = "", extra_details: Dictionary = {}):
		timestamp = time
		event_type = type
		actor = actor_name
		target = target_name
		value = val
		description = desc
		details = extra_details

# Список всех событий боя
var events: Array[BattleEvent] = []
var battle_start_time: float = 0.0
var current_round: int = 1
var round_start_time: float = 0.0

func _ready():
	battle_start_time = Time.get_unix_time_from_system()

func start_battle():
	events.clear()
	battle_start_time = Time.get_unix_time_from_system()
	current_round = 1
	round_start_time = battle_start_time
	log_event("battle_start", "Система", "", 0, "Бой начался")

func log_round_start():
	log_event("round_start", "Система", "", 0, "=== РАУНД " + str(current_round) + " ===")

func next_round():
	round_start_time = Time.get_unix_time_from_system()
	log_round_start()
	current_round += 1

func log_damage(attacker: String, target: String, damage: int, is_critical: bool = false, damage_type: String = "physical", attacker_level: int = 0, target_level: int = 0, target_current_hp: int = 0, target_max_hp: int = 0, ability_name: String = ""):
	var desc = attacker
	if attacker_level > 0:
		desc += " (ур. " + str(attacker_level) + ")"
	
	# Добавляем информацию о способности или обычной атаке
	if ability_name != "":
		desc += " использует '" + ability_name + "' и наносит " + str(damage) + " урона " + target
	else:
		desc += " наносит " + str(damage) + " урона " + target
	
	if target_level > 0:
		desc += " (ур. " + str(target_level) + ")"
	if is_critical:
		desc += " (КРИТИЧЕСКИЙ УДАР!)"
	
	# Добавляем информацию о здоровье цели
	if target_current_hp > 0 and target_max_hp > 0:
		var previous_hp = target_current_hp + damage
		desc += ". ОЗ " + target + ": " + str(target_current_hp) + " (" + str(previous_hp) + " - " + str(damage) + ")"
	
	log_event("damage", attacker, target, damage, desc, {"critical": is_critical, "damage_type": damage_type, "attacker_level": attacker_level, "target_level": target_level, "target_hp": target_current_hp, "target_max_hp": target_max_hp, "ability_name": ability_name})

func log_heal(healer: String, target: String, heal_amount: int, target_current_hp: int = 0, target_max_hp: int = 0):
	var desc = target + " восстанавливает " + str(heal_amount) + " здоровья"
	
	# Добавляем информацию о здоровье цели
	if target_current_hp > 0 and target_max_hp > 0:
		var previous_hp = target_current_hp - heal_amount
		desc += ". ОЗ " + target + ": " + str(target_current_hp) + " (" + str(previous_hp) + " + " + str(heal_amount) + ")"
	
	log_event("heal", healer, target, heal_amount, desc, {"target_hp": target_current_hp, "target_max_hp": target_max_hp})

func log_regeneration(target: String, resource_type: String, amount: int, target_current_value: int = 0, target_max_value: int = 0):
	var resource_name = ""
	match resource_type:
		"hp":
			resource_name = "здоровья"
		"mp":
			resource_name = "маны"
		"stamina":
			resource_name = "выносливости"
		_:
			resource_name = resource_type
	
	var desc = target + " восстанавливает " + str(amount) + " " + resource_name + " (регенерация)"
	
	# Добавляем информацию о ресурсе для здоровья
	if resource_type == "hp" and target_current_value > 0 and target_max_value > 0:
		var previous_hp = target_current_value - amount
		desc += ". ОЗ " + target + ": " + str(target_current_value) + " (" + str(previous_hp) + " + " + str(amount) + ")"
	
	log_event("regeneration", target, "", amount, desc, {"resource_type": resource_type, "target_value": target_current_value, "target_max_value": target_max_value})

func log_dodge(attacker: String, dodger: String):
	var desc = dodger + " увернулся от атаки " + attacker
	log_event("dodge", dodger, attacker, 0, desc)

func log_passive_ability(actor: String, ability_name: String, success: bool, description: String = ""):
	var desc = ""
	if success:
		desc = description
	else:
		desc = actor + " - " + ability_name + " (не сработала)"
	
	log_event("passive_ability", actor, "", 0, desc, {"ability": ability_name, "success": success})

func log_effect_damage(target: String, effect_name: String, damage: int, stacks: int = 1):
	var desc = target + " получает " + str(damage) + " урона от " + effect_name
	if stacks > 1:
		desc += " (стаки: " + str(stacks) + ")"
	
	log_event("effect_damage", effect_name, target, damage, desc, {"stacks": stacks})

func log_battle_end(winner: String, duration: float):
	var desc = "Бой завершен. Победитель: " + winner + " (длительность: " + str(duration) + "с)"
	log_event("battle_end", winner, "", 0, desc, {"duration": duration})

func log_event(event_type: String, actor: String, target: String, value: int, description: String, details: Dictionary = {}):
	var current_time = Time.get_unix_time_from_system()
	var event = BattleEvent.new(current_time, event_type, actor, target, value, description, details)
	events.append(event)
	print(description)

func get_events_by_type(event_type: String) -> Array[BattleEvent]:
	var filtered_events: Array[BattleEvent] = []
	for event in events:
		if event.event_type == event_type:
			filtered_events.append(event)
	return filtered_events

func get_battle_statistics() -> Dictionary:
	var stats = {
		"total_events": events.size(),
		"damage_events": get_events_by_type("damage").size(),
		"heal_events": get_events_by_type("heal").size(),
		"dodge_events": get_events_by_type("dodge").size(),
		"passive_ability_events": get_events_by_type("passive_ability").size(),
		"effect_damage_events": get_events_by_type("effect_damage").size(),
		"magic_barrier_events": get_events_by_type("magic_barrier").size(),
		"magic_barrier_block_events": get_events_by_type("magic_barrier_block").size(),
		"total_damage_dealt": 0,
		"total_healing": 0,
		"critical_hits": 0,
		"successful_passives": 0
	}
	
	# Подсчитываем статистику
	for event in events:
		match event.event_type:
			"damage":
				stats.total_damage_dealt += event.value
				if event.details.get("critical", false):
					stats.critical_hits += 1
			"heal":
				stats.total_healing += event.value
			"passive_ability":
				if event.details.get("success", false):
					stats.successful_passives += 1
	
	return stats

func get_battle_log_text() -> String:
	var log_text = "=== ЛОГ БОЯ ===\n\n"
	var round_started = false
	
	for event in events:
		# Добавляем разделитель раунда
		if event.event_type == "round_start":
			if round_started:
				log_text += "\n" + "─".repeat(50) + "\n\n"  # Разделитель между раундами
			log_text += "[color=yellow]" + event.description + "[/color]\n"
			# Убираем current_round += 1 - это было ошибкой!
			round_started = true
			continue
		
		# Добавляем отступ для событий раунда
		if round_started:
			log_text += "  "
		
		var colored_text = _get_colored_event_text(event)
		log_text += colored_text + "\n"
	
	return log_text

func _get_colored_event_text(event: BattleEvent) -> String:
	match event.event_type:
		"round_start":
			return "[color=yellow]" + event.description + "[/color]"
		"damage":
			var text = event.description
			if event.details.get("critical", false):
				# Для критических ударов: основной текст белый, "КРИТИЧЕСКИЙ УДАР" целиком красный, цифры урона по типу, цифры здоровья розовые
				var damage_value = str(event.value)
				var damage_type = event.details.get("damage_type", "physical")
				var damage_color = "cyan" if damage_type == "magic" else ("lime" if damage_type == "poison" else "orange")
				
				# Сначала окрашиваем цифры здоровья светло-красным цветом
				var target_hp = event.details.get("target_hp", 0)
				var target_max_hp = event.details.get("target_max_hp", 0)
				if target_hp > 0:
					text = text.replace(str(target_hp), "[color=lightcoral]" + str(target_hp) + "[/color]")
				if target_max_hp > 0:
					text = text.replace(str(target_max_hp), "[color=lightcoral]" + str(target_max_hp) + "[/color]")
				
				# Затем окрашиваем цифры урона (только в основном тексте, не в скобках)
				text = text.replace(" наносит " + damage_value + " урона", " наносит [color=" + damage_color + "]" + damage_value + "[/color] урона")
				
				# Затем окрашиваем "КРИТИЧЕСКИЙ УДАР" целиком красным
				text = text.replace("(КРИТИЧЕСКИЙ УДАР!)", "[color=red](КРИТИЧЕСКИЙ УДАР!)[/color]")
				
				# Окрашиваем имена игроков и врагов
				text = text.replace("Player", "[color=gold]Player[/color]")
				# Окрашиваем имена врагов серебряным цветом
				text = text.replace("Гоблин", "[color=silver]Гоблин[/color]")
				text = text.replace("Слизень", "[color=silver]Слизень[/color]")
				text = text.replace("Крыса", "[color=silver]Крыса[/color]")
				text = text.replace("Летучая мышь", "[color=silver]Летучая мышь[/color]")
				text = text.replace("Демон", "[color=silver]Демон[/color]")
				text = text.replace("Алкар", "[color=silver]Алкар[/color]")
				
				# Остальной текст остается белым (по умолчанию)
			else:
				# Определяем цвет цифры урона в зависимости от типа урона
				var damage_value = str(event.value)
				var damage_type = event.details.get("damage_type", "physical")
				var damage_color = "cyan" if damage_type == "magic" else ("lime" if damage_type == "poison" else "orange")
				
				# Сначала окрашиваем цифры здоровья светло-красным цветом
				var target_hp = event.details.get("target_hp", 0)
				var target_max_hp = event.details.get("target_max_hp", 0)
				if target_hp > 0:
					text = text.replace(str(target_hp), "[color=lightcoral]" + str(target_hp) + "[/color]")
				if target_max_hp > 0:
					text = text.replace(str(target_max_hp), "[color=lightcoral]" + str(target_max_hp) + "[/color]")
				
				# Затем окрашиваем цифры урона (только в основном тексте, не в скобках)
				text = text.replace(" наносит " + damage_value + " урона", " наносит [color=" + damage_color + "]" + damage_value + "[/color] урона")
				
				# Окрашиваем имена игроков и врагов
				text = text.replace("Player", "[color=gold]Player[/color]")
				# Окрашиваем имена врагов серебряным цветом
				text = text.replace("Гоблин", "[color=silver]Гоблин[/color]")
				text = text.replace("Слизень", "[color=silver]Слизень[/color]")
				text = text.replace("Крыса", "[color=silver]Крыса[/color]")
				text = text.replace("Летучая мышь", "[color=silver]Летучая мышь[/color]")
				text = text.replace("Демон", "[color=silver]Демон[/color]")
				text = text.replace("Алкар", "[color=silver]Алкар[/color]")
			return text
		"effect_damage":
			var effect_name = event.details.get("effect_name", "")
			if effect_name == "bleeding":
				return "[color=red]" + event.description + "[/color]"
			elif effect_name == "poison":
				return "[color=green]" + event.description + "[/color]"
			elif effect_name == "Оглушение":
				return "[color=yellow]" + event.description + "[/color]"
			else:
				return "[color=purple]" + event.description + "[/color]"
		"heal":
			return "[color=green]" + event.description + "[/color]"
		"regeneration":
			var resource_type = event.details.get("resource_type", "")
			match resource_type:
				"hp":
					return "[color=red]" + event.description + "[/color]"
				"mp":
					return "[color=cyan]" + event.description + "[/color]"
				"stamina":
					return "[color=green]" + event.description + "[/color]"
				_:
					return "[color=green]" + event.description + "[/color]"
		"dodge":
			return "[color=cyan]" + event.description + "[/color]"
		"passive_ability":
			var success = event.details.get("success", false)
			var ability_name = event.details.get("ability", "")
			if success:
				return "[color=yellow]" + ability_name + "[/color] - [color=green]" + event.description + "[/color]"
			else:
				return "[color=yellow]" + ability_name + "[/color] - [color=red]" + event.description + "[/color]"
		"battle_start", "battle_end":
			return "[color=yellow]" + event.description + "[/color]"
		_:
			return event.description

func clear_log():
	events.clear()

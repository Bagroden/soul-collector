# res://Scripts/Systems/SoulRestorationManager.gd
extends Node

signal charges_changed(current_charges: int, max_charges: int)
signal soul_restoration_used(charges_remaining: int)

# Настройки способности
var max_charges: int = 2  # Максимальное количество зарядов
var current_charges: int = 2  # Текущее количество зарядов
var restoration_percentage: float = 0.35  # Процент восстановления (35%)

# Улучшения через души
var soul_upgrades: Dictionary = {
	"charges": 0,  # Бонус к зарядам
	"efficiency": 0.0,  # Бонус к эффективности (дополнительные %)
	"barrier": 0  # Бонус магического барьера при использовании
}

func _ready():
	# Подключаемся к сигналам комнат отдыха
	var room_generator = get_node_or_null("/root/RoomGenerator")
	if room_generator:
		room_generator.connect("rest_room_entered", _on_rest_room_entered)
	
	# Пересчитываем бонусы при старте (с задержкой, чтобы PlayerManager успел загрузиться)
	await get_tree().create_timer(0.1).timeout
	recalculate_bonuses_from_learned_abilities()

func can_use_charge() -> bool:
	"""Проверяет, можно ли использовать заряд"""
	return current_charges > 0

func use_charge() -> bool:
	"""Использует заряд, возвращает true если успешно"""
	if current_charges > 0:
		current_charges -= 1
		charges_changed.emit(current_charges, get_max_charges())
		soul_restoration_used.emit(current_charges)
		return true
	return false

func restore_all_charges():
	"""Восстанавливает все заряды (вызывается в комнатах отдыха)"""
	current_charges = get_max_charges()
	charges_changed.emit(current_charges, get_max_charges())

func get_max_charges() -> int:
	"""Возвращает максимальное количество зарядов с учетом улучшений"""
	return max_charges + soul_upgrades["charges"]

func get_restoration_percentage() -> float:
	"""Возвращает процент восстановления с учетом улучшений"""
	return restoration_percentage + soul_upgrades["efficiency"]

func get_barrier_bonus() -> int:
	"""Возвращает бонус магического барьера при использовании"""
	return soul_upgrades.get("barrier", 0)

func get_current_charges() -> int:
	"""Возвращает текущее количество зарядов"""
	return current_charges

func add_soul_upgrade(upgrade_type: String, value: float):
	"""Добавляет улучшение от души"""
	match upgrade_type:
		"charges":
			soul_upgrades["charges"] += int(value)
		"efficiency":
			soul_upgrades["efficiency"] += value
		"barrier":
			soul_upgrades["barrier"] += int(value)
	
	# Обновляем максимальные заряды
	charges_changed.emit(current_charges, get_max_charges())

func _on_rest_room_entered():
	"""Обработчик входа в комнату отдыха"""
	restore_all_charges()

func save_data() -> Dictionary:
	"""Сохраняет данные для сохранения игры"""
	return {
		"max_charges": max_charges,
		"current_charges": current_charges,
		"restoration_percentage": restoration_percentage,
		"soul_upgrades": soul_upgrades
	}

func load_data(data: Dictionary):
	"""Загружает данные из сохранения"""
	max_charges = data.get("max_charges", 2)
	current_charges = data.get("current_charges", 2)
	restoration_percentage = data.get("restoration_percentage", 0.35)
	soul_upgrades = data.get("soul_upgrades", {"charges": 0, "efficiency": 0.0, "barrier": 0})
	
	charges_changed.emit(current_charges, get_max_charges())

func recalculate_bonuses_from_learned_abilities():
	"""Пересчитывает бонусы на основе изученных способностей развития души"""
	# Сбрасываем все улучшения
	soul_upgrades = {"charges": 0, "efficiency": 0.0, "barrier": 0}
	
	# Получаем PlayerData
	var player_manager = get_node_or_null("/root/PlayerManager")
	if not player_manager:
		return
	
	var player_data = player_manager.get_player_data()
	if not player_data:
		return
	
	# Инициализируем систему пассивных способностей
	player_data.initialize_passive_system()
	
	var passive_ability_manager = player_data.passive_ability_manager
	if not passive_ability_manager:
		return
	
	# Считаем бонус духовной мощи
	var spiritual_power_bonus = 0
	
	# Проходим по всем изученным способностям
	for ability_id in player_data.learned_passives:
		var ability = passive_ability_manager.get_ability(ability_id)
		if not ability or not ("soul" in ability.tags):
			continue
		
		# Определяем тип способности и добавляем соответствующий бонус
		if "soul_restoration_efficiency_" in ability_id:
			# Эффективность: разные бонусы для каждого уровня
			var level = int(ability_id.replace("soul_restoration_efficiency_", ""))
			var efficiency_bonuses = [0.05, 0.10, 0.20, 0.30, 0.45, 0.65]
			if level > 0 and level <= efficiency_bonuses.size():
				soul_upgrades["efficiency"] = efficiency_bonuses[level - 1]
			
		elif "soul_restoration_charges_" in ability_id:
			# Заряды: каждый уровень добавляет 1 заряд
			soul_upgrades["charges"] += 1
			
		elif "soul_restoration_barrier_" in ability_id:
			# Барьер: зависит от уровня
			var level = int(ability_id.replace("soul_restoration_barrier_", ""))
			var barrier_values = [40, 80, 120, 120, 160, 200]
			if level > 0 and level <= barrier_values.size():
				soul_upgrades["barrier"] = barrier_values[level - 1]
		
		elif "spiritual_power_upgrade_" in ability_id:
			# Духовная мощь: каждый уровень добавляет к максимальной духовной мощи
			var level = int(ability_id.replace("spiritual_power_upgrade_", ""))
			var power_values = [1, 2, 3, 4, 5]
			if level > 0 and level <= power_values.size():
				spiritual_power_bonus += power_values[level - 1]
	
	# Применяем бонус духовной мощи
	if spiritual_power_bonus > 0:
		var base_max_spiritual_power = 5 + (player_data.level - 1)
		player_data.max_spiritual_power = base_max_spiritual_power + spiritual_power_bonus
		# Пересчитываем текущую духовную мощь
		player_data._recalculate_used_spiritual_power()
		player_data.emit_signal("spiritual_power_changed", player_data.spiritual_power, player_data.max_spiritual_power, player_data.used_spiritual_power)
	
	# Если текущие заряды больше нового максимума, уменьшаем до максимума
	if current_charges > get_max_charges():
		current_charges = get_max_charges()
	
	# Обновляем UI
	charges_changed.emit(current_charges, get_max_charges())

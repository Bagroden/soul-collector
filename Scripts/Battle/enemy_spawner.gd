# res://Scripts/Battle/enemy_spawner.gd
extends Node

var location_manager

func _ready():
	# Получаем менеджер локаций
	location_manager = get_node_or_null("/root/LocationManager")
	if not location_manager:
		# Создаем менеджер если его нет
		var script = load("res://Scripts/LocationManagerAutoload.gd")
		location_manager = Node.new()
		location_manager.set_script(script)
		location_manager.name = "LocationManager"
		get_tree().root.add_child(location_manager)
		await get_tree().process_frame
	

func spawn_random_enemy(force_elite: bool = false, enemy_index: int = 0) -> Node2D:
	"""Спавнит врага с детерминированной редкостью на основе комнаты
	
	Args:
		force_elite: Если true и комната элитная, враг будет элитным. Если false, будет обычной редкости.
		enemy_index: Индекс врага в комнате (0, 1, 2...) для детерминированного выбора
	"""
	var enemy_scene_path = ""
	var rarity = "common"
	var is_boss = false
	
	# Проверяем, есть ли генератор комнат
	var room_generator = get_node_or_null("/root/RoomGenerator")
	
	if room_generator:
		var current_room = room_generator.get_current_room()
		
		# Проверяем, является ли это босс-комнатой
		if current_room and current_room.room_type == RoomData.RoomType.BOSS:
			is_boss = true
			# Для боссов используем заданную сцену и редкость
			if current_room.enemy_scene != "":
				enemy_scene_path = current_room.enemy_scene
				rarity = "boss"
			else:
				# Fallback для босса - детерминированный выбор
				enemy_scene_path = _get_deterministic_enemy_from_pool(current_room, enemy_index)
				rarity = "boss"
		# Проверяем, является ли это квестовой комнатой с заданным врагом
		elif current_room and current_room.is_quest_room and current_room.enemy_scene != "":
			# Для квестовых комнат используем заданную сцену и редкость
			enemy_scene_path = current_room.enemy_scene
			if current_room.enemy_rarity != "":
				rarity = current_room.enemy_rarity
			else:
				rarity = "common"
		else:
			# ДЛЯ ОБЫЧНЫХ КОМНАТ - ВЫБИРАЕМ ВРАГА ДЕТЕРМИНИРОВАННО
			# Используем seed на основе комнаты для одинакового результата
			var seed_value = (current_room.room_name.hash() + enemy_index * 1000) if current_room else (enemy_index * 1000)
			seed(seed_value)
			
			# Выбираем врага детерминированно из пула
			enemy_scene_path = _get_deterministic_enemy_from_pool(current_room, enemy_index)
			
			if current_room and current_room.enemy_rarity != "":
				# Используем редкость комнаты как базовую, с вариативностью (детерминированной)
				# Если force_elite = true, то принудительно делаем врага элитным
				if force_elite:
					var base_rarity = _get_rarity_based_on_room_deterministic(current_room.enemy_rarity, enemy_index)
					# Если базовая редкость позволяет быть элитным (rare, epic, legendary, но не mythic)
					if base_rarity in ["rare", "epic", "legendary"]:
						rarity = "elite_" + base_rarity
					else:
						rarity = base_rarity
				else:
					rarity = _get_rarity_based_on_room_deterministic(current_room.enemy_rarity, enemy_index)
			else:
				# Fallback - используем взвешенную генерацию (детерминированную)
				if force_elite:
					var base_rarity = _get_random_rarity_weighted()
					if base_rarity in ["rare", "epic", "legendary"]:
						rarity = "elite_" + base_rarity
					else:
						rarity = base_rarity
				else:
					rarity = _get_random_rarity_weighted()
			
			# Восстанавливаем состояние генератора случайных чисел
			randomize()
	else:
		# Fallback к старой системе
		enemy_scene_path = location_manager.get_random_enemy_for_location()
		rarity = _get_random_rarity_weighted()
	
	if enemy_scene_path == "" or not ResourceLoader.exists(enemy_scene_path):
		# Fallback - используем демонов как заглушку
		enemy_scene_path = "res://Scenes/Battle/Enemy_AlkaraDemon.tscn"
	
	# Загружаем и создаем врага
	var enemy_scene: PackedScene = load(enemy_scene_path)
	var enemy_instance: Node2D = enemy_scene.instantiate()
	
	# Устанавливаем редкость врага
	_set_enemy_rarity(enemy_instance, rarity)
	
	print("Спавн врага: ", enemy_instance.display_name if "display_name" in enemy_instance else "Unknown", 
		  " | Редкость: ", rarity, " | Босс: ", is_boss, " | Индекс: ", enemy_index)
	
	return enemy_instance

func _get_deterministic_enemy_from_pool(_room: RoomData, _enemy_index: int) -> String:
	"""Выбирает врага из пула локации детерминированно на основе комнаты и индекса
	ВАЖНО: seed должен быть уже установлен перед вызовом этой функции!"""
	if not location_manager or not location_manager.current_location:
		return ""
	
	var current_location = location_manager.current_location
	if not current_location.enemy_pools or current_location.enemy_pools.is_empty():
		return ""
	
	# Вычисляем общий вес
	var total_weight = 0
	for pool in current_location.enemy_pools:
		if pool:
			total_weight += pool.spawn_weight
	
	if total_weight <= 0:
		return ""
	
	# Используем детерминированный выбор (seed уже установлен в вызывающей функции)
	var random_roll = randi() % total_weight
	
	var current_weight = 0
	for pool in current_location.enemy_pools:
		if pool:
			current_weight += pool.spawn_weight
			if random_roll < current_weight:
				return pool.enemy_scene
	
	# Fallback
	if current_location.enemy_pools.size() > 0:
		return current_location.enemy_pools[0].enemy_scene
	
	return ""

func _get_random_rarity() -> String:
	"""УСТАРЕВШАЯ ФУНКЦИЯ - используйте _get_random_rarity_weighted()"""
	return _get_random_rarity_weighted()

func _get_random_rarity_weighted() -> String:
	"""Генерирует случайную редкость с учетом сложности локации"""
	# Получаем текущую сложность
	var difficulty = 1
	var player_manager = get_node_or_null("/root/PlayerManager")
	if player_manager:
		var player_data = player_manager.get_player_data()
		if player_data and location_manager and location_manager.current_location:
			var current_location_id = location_manager.current_location.location_id
			difficulty = player_data.get_selected_difficulty(current_location_id)
	
	# Веса редкостей зависят от сложности
	var weights = {}
	
	match difficulty:
		1:  # Сложность I - в основном обычные враги
			weights = {
				"common": 45,
				"uncommon": 30,
				"rare": 15,
				"epic": 7,
				"legendary": 3
			}
		2:  # Сложность II - больше необычных и редких
			weights = {
				"common": 25,
				"uncommon": 35,
				"rare": 25,
				"epic": 10,
				"legendary": 5
			}
		3:  # Сложность III - много редких, эпических и легендарных
			weights = {
				"common": 10,
		"uncommon": 20,
				"rare": 30,
				"epic": 25,
				"legendary": 15
			}
		_:  # Fallback
			weights = {
				"common": 40,
				"uncommon": 30,
		"rare": 20,
				"epic": 7,
				"legendary": 3
	}
	
	# Шанс на элитного врага (накладывается на базовую редкость)
	var elite_chance = 0.0
	var elite_rarities = []  # Какие редкости могут быть элитными
	
	match difficulty:
		1:
			elite_chance = 0.05  # 5% шанс элитного
			elite_rarities = ["rare", "epic", "legendary"]  # Только rare+
		2:
			elite_chance = 0.20  # 20% шанс элитного
			elite_rarities = ["uncommon", "rare", "epic", "legendary"]  # Uncommon+
		3:
			elite_chance = 0.30  # 30% шанс элитного
			elite_rarities = ["uncommon", "rare", "epic", "legendary"]  # Uncommon+
	
	var total_weight = 0
	for weight in weights.values():
		total_weight += weight
	
	var random_roll = randi() % total_weight
	var current_weight = 0
	var base_rarity = "common"
	
	for rarity in weights.keys():
		current_weight += weights[rarity]
		if random_roll < current_weight:
			base_rarity = rarity
			break
	
	# Проверяем, станет ли враг элитным
	if base_rarity in elite_rarities:
		var elite_roll = randf()
		if elite_roll < elite_chance:
			return "elite_" + base_rarity
	
	return base_rarity

func _get_rarity_based_on_room(room_rarity: String) -> String:
	"""Генерирует редкость врага на основе редкости комнаты с вариативностью"""
	# Получаем приоритет редкости комнаты
	var room_priority = _get_rarity_priority(room_rarity)
	
	# Взвешенная система: в основном редкость комнаты, с небольшой вариативностью
	# ВАЖНО: Враги НЕ могут быть реже комнаты (только на том же уровне или ниже)
	var roll = randf()
	var target_priority = room_priority
	
	if roll < 0.8:
		# 80% - точно редкость комнаты
		target_priority = room_priority
	else:
		# 20% - на 1 уровень ниже (для вариативности, но не реже комнаты)
		target_priority = max(1, room_priority - 1)
	
	# Преобразуем приоритет обратно в редкость
	var base_rarity = _get_rarity_from_priority(target_priority)
	
	# Проверяем шанс на элитного врага
	var elite_chance = 0.0
	var elite_rarities = []
	var player_manager = get_node_or_null("/root/PlayerManager")
	if player_manager:
		var player_data = player_manager.get_player_data()
		if player_data and location_manager and location_manager.current_location:
			var current_location_id = location_manager.current_location.location_id
			var difficulty = player_data.get_selected_difficulty(current_location_id)
			match difficulty:
				1:
					elite_chance = 0.05  # 5% шанс элитного
					elite_rarities = ["rare", "epic", "legendary"]
				2:
					elite_chance = 0.20  # 20% шанс элитного
					elite_rarities = ["uncommon", "rare", "epic", "legendary"]
				3:
					elite_chance = 0.30  # 30% шанс элитного
					elite_rarities = ["uncommon", "rare", "epic", "legendary"]
	
	if base_rarity in elite_rarities:
		var elite_roll = randf()
		if elite_roll < elite_chance:
			var elite_rarity = "elite_" + base_rarity
			var elite_priority = _get_rarity_priority(elite_rarity)
			var base_rarity_priority = _get_rarity_priority(base_rarity)
			
			# ВАЖНО: Элитный враг может появиться только если:
			# 1. Базовая редкость точно соответствует редкости комнаты (не ниже)
			# 2. Элитный враг не будет реже комнаты
			# Это предотвращает появление elite_epic в legendary комнате
			if base_rarity_priority == room_priority:
				# Базовая редкость точно соответствует комнате - элитный враг может появиться
				# Но только если его приоритет не превышает приоритет комнаты более чем на 1
				# (elite_legendary имеет приоритет 6, legendary комната - 5, разница = 1, допустимо)
				if elite_priority <= room_priority + 1:
					return elite_rarity
			elif base_rarity_priority < room_priority:
				# Базовая редкость ниже комнаты (20% случай) - не делаем элитного врага
				return base_rarity
			# Если условия не выполнены, возвращаем базовую редкость
			return base_rarity
	
	return base_rarity

func _get_rarity_based_on_room_deterministic(room_rarity: String, _enemy_index: int) -> String:
	"""Генерирует редкость врага на основе редкости комнаты с вариативностью (детерминированно)
	Использует уже установленный seed на основе комнаты и enemy_index"""
	# Получаем приоритет редкости комнаты
	var room_priority = _get_rarity_priority(room_rarity)
	
	# Взвешенная система: в основном редкость комнаты, с небольшой вариативностью
	# ВАЖНО: Враги НЕ могут быть реже комнаты (только на том же уровне или ниже)
	var roll = randf()  # Используем уже установленный seed
	var target_priority = room_priority
	
	if roll < 0.8:
		# 80% - точно редкость комнаты
		target_priority = room_priority
	else:
		# 20% - на 1 уровень ниже (для вариативности, но не реже комнаты)
		target_priority = max(1, room_priority - 1)
	
	# Преобразуем приоритет обратно в редкость
	var base_rarity = _get_rarity_from_priority(target_priority)
	
	# Проверяем шанс на элитного врага (только для rare, epic, legendary)
	var elite_chance = 0.0
	var elite_rarities = []
	var player_manager = get_node_or_null("/root/PlayerManager")
	if player_manager:
		var player_data = player_manager.get_player_data()
		if player_data and location_manager and location_manager.current_location:
			var current_location_id = location_manager.current_location.location_id
			var difficulty = player_data.get_selected_difficulty(current_location_id)
			match difficulty:
				1:
					elite_chance = 0.05  # 5% шанс элитного
					elite_rarities = ["rare", "epic", "legendary"]
				2:
					elite_chance = 0.20  # 20% шанс элитного
					elite_rarities = ["uncommon", "rare", "epic", "legendary"]
				3:
					elite_chance = 0.30  # 30% шанс элитного
					elite_rarities = ["uncommon", "rare", "epic", "legendary"]
	
	if base_rarity in elite_rarities:
		var elite_roll = randf()  # Используем уже установленный seed
		if elite_roll < elite_chance:
			var elite_rarity = "elite_" + base_rarity
			var elite_priority = _get_rarity_priority(elite_rarity)
			var base_rarity_priority = _get_rarity_priority(base_rarity)
			
			# ВАЖНО: Элитный враг может появиться только если:
			# 1. Базовая редкость точно соответствует редкости комнаты (не ниже)
			# 2. Элитный враг не будет реже комнаты
			# Это предотвращает появление elite_epic в legendary комнате
			if base_rarity_priority == room_priority:
				# Базовая редкость точно соответствует комнате - элитный враг может появиться
				# Но только если его приоритет не превышает приоритет комнаты более чем на 1
				# (elite_legendary имеет приоритет 6, legendary комната - 5, разница = 1, допустимо)
				if elite_priority <= room_priority + 1:
					return elite_rarity
			elif base_rarity_priority < room_priority:
				# Базовая редкость ниже комнаты (20% случай) - не делаем элитного врага
				return base_rarity
			# Если условия не выполнены, возвращаем базовую редкость
			return base_rarity
	
	return base_rarity

func _get_rarity_priority(rarity: String) -> int:
	"""Возвращает приоритет редкости (чем выше, тем реже)"""
	match rarity.to_lower():
		"common":
			return 1
		"uncommon":
			return 2
		"rare":
			return 3
		"epic":
			return 4
		"legendary":
			return 5
		"mythic":
			return 6
		"boss":
			return 7
		"elite_rare":
			return 4  # Элитный rare = между epic и legendary
		"elite_epic":
			return 5  # Элитный epic = между legendary и mythic
		"elite_legendary":
			return 6  # Элитный legendary = между mythic и boss
		_:
			return 1  # По умолчанию common

func _get_rarity_from_priority(priority: int) -> String:
	"""Преобразует приоритет обратно в редкость"""
	match priority:
		1:
			return "common"
		2:
			return "uncommon"
		3:
			return "rare"
		4:
			return "epic"
		5:
			return "legendary"
		6:
			return "mythic"
		7:
			return "boss"
		_:
			return "common"

func _get_rarity_level_bonus(rarity: String) -> int:
	"""Возвращает бонус к уровню врага в зависимости от редкости"""
	match rarity.to_lower():
		"common":
			return 0
		"uncommon":
			return 1
		"rare":
			return 2
		"epic":
			return 3
		"elite_rare":
			return 2 + 3  # Базовый бонус rare (2) + элитный бонус (3)
		"elite_epic":
			return 3 + 3  # Базовый бонус epic (3) + элитный бонус (3)
		"elite_legendary":
			return 4 + 3  # Базовый бонус legendary (4) + элитный бонус (3)
		"legendary":
			return 4
		"boss":
			return 5
		"mythic":
			return 6
		_:
			return 0

func _get_difficulty_level_bonus(difficulty: int) -> int:
	"""Возвращает бонус к уровню врагов от сложности"""
	match difficulty:
		1:
			return 0
		2:
			return 2
		3:
			return 5
		_:
			return 0

func _set_enemy_rarity(enemy: Node2D, rarity: String):
	# Устанавливаем уровень врага на основе уровня игрока + бонус от редкости + бонус от сложности
	var player_manager = get_node_or_null("/root/PlayerManager")
	var enemy_level = 1
	if player_manager:
		if not player_manager.has_method("get_player_data"):
			print("ОШИБКА: player_manager не имеет метода get_player_data в enemy_spawner!")
			enemy_level = 1
		else:
			var player_data = player_manager.get_player_data()
			if player_data:
				# Получаем текущую локацию и выбранную сложность
				if not location_manager:
					location_manager = get_node_or_null("/root/LocationManager")
				var difficulty_bonus = 0
				
				if location_manager and location_manager.current_location:
					var current_location_id = location_manager.current_location.location_id
					var selected_difficulty = player_data.get_selected_difficulty(current_location_id)
					difficulty_bonus = _get_difficulty_level_bonus(selected_difficulty)
				
				# Уровень врага = уровень игрока + бонус от редкости + бонус от сложности
				var rarity_bonus = _get_rarity_level_bonus(rarity)
				enemy_level = max(1, player_data.level + rarity_bonus + difficulty_bonus)
			else:
				print("ОШИБКА: player_data не найден в enemy_spawner!")
				enemy_level = 1
	else:
		print("ОШИБКА: player_manager не найден в enemy_spawner!")
		enemy_level = 1
	
	# Устанавливаем уровень врага
	if enemy.has_method("set_enemy_level"):
		enemy.set_enemy_level(enemy_level)
	else:
		enemy.level = enemy_level
		enemy.calculate_stat_bonuses()
		enemy.apply_stat_bonuses()
		enemy.hp = enemy.max_hp
		enemy.mp = enemy.max_mp
		enemy.stamina = enemy.max_stamina
	
	# Устанавливаем редкость и соответствующие бонусы
	enemy.rarity = rarity
	
	if not enemy.has_method("set_rarity"):
		# Если у врага нет метода set_rarity, добавляем базовые бонусы к max_hp
		match rarity:
			"uncommon":
				enemy.max_hp = int(enemy.max_hp * 1.2)
				enemy.max_mp = int(enemy.max_mp * 1.2)
				enemy.max_stamina = int(enemy.max_stamina * 1.2)
			"rare":
				enemy.max_hp = int(enemy.max_hp * 1.4)  # 40% бонус
				enemy.max_mp = int(enemy.max_mp * 1.4)
				enemy.max_stamina = int(enemy.max_stamina * 1.4)
			"epic":
				enemy.max_hp = int(enemy.max_hp * 1.6)  # 60% бонус
				enemy.max_mp = int(enemy.max_mp * 1.6)
				enemy.max_stamina = int(enemy.max_stamina * 1.6)
			"elite_rare":
				enemy.max_hp = int(enemy.max_hp * 1.4 * 1.25)  # 40% от rare + 25% элитный бонус = 75%
				enemy.max_mp = int(enemy.max_mp * 1.4 * 1.25)
				enemy.max_stamina = int(enemy.max_stamina * 1.4 * 1.25)
			"elite_epic":
				enemy.max_hp = int(enemy.max_hp * 1.6 * 1.25)  # 60% от epic + 25% элитный бонус = 100%
				enemy.max_mp = int(enemy.max_mp * 1.6 * 1.25)
				enemy.max_stamina = int(enemy.max_stamina * 1.6 * 1.25)
			"elite_legendary":
				enemy.max_hp = int(enemy.max_hp * 1.8 * 1.25)  # 80% от legendary + 25% элитный бонус = 125%
				enemy.max_mp = int(enemy.max_mp * 1.8 * 1.25)
				enemy.max_stamina = int(enemy.max_stamina * 1.8 * 1.25)
			"legendary":
				enemy.max_hp = int(enemy.max_hp * 1.8)  # 80% бонус
				enemy.max_mp = int(enemy.max_mp * 1.8)
				enemy.max_stamina = int(enemy.max_stamina * 1.8)
			"boss":
				enemy.max_hp = int(enemy.max_hp * 2.0)  # 100% бонус
				enemy.max_mp = int(enemy.max_mp * 2.0)
				enemy.max_stamina = int(enemy.max_stamina * 2.0)
			"mythic":
				enemy.max_hp = int(enemy.max_hp * 2.5)  # 150% бонус
				enemy.max_mp = int(enemy.max_mp * 2.5)
				enemy.max_stamina = int(enemy.max_stamina * 2.5)
	
	# Обновляем текущее ХП и другие ресурсы на максимум
	enemy.hp = enemy.max_hp
	enemy.mp = enemy.max_mp
	enemy.stamina = enemy.max_stamina

func get_enemy_info(scene_path: String) -> Dictionary:
	# Возвращает информацию о враге по пути к сцене
	var scene: PackedScene = load(scene_path)
	var temp_instance: Node2D = scene.instantiate()
	var info: Dictionary = {
		"name": temp_instance.display_name,
		"hp": temp_instance.max_hp,
		"attack": temp_instance.attack_power,
		"defense": temp_instance.defense,
		"rarity": temp_instance.rarity
	}
	temp_instance.queue_free()
	return info

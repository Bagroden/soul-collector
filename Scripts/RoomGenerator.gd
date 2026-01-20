# res://Scripts/RoomGenerator.gd
class_name RoomGenerator
extends Node

var current_location
var current_room: RoomData
var rooms_cleared: int = 0
var max_rooms: int = 8  # Максимум комнат в локации

signal room_cleared(room: RoomData)
signal location_completed()

func _ready():
	pass

func start_location(location):
	if not location:
		print("ОШИБКА: Передана пустая локация в start_location!")
		return
	
	current_location = location
	
	# Проверяем режим босса
	var player_manager = get_node_or_null("/root/PlayerManager")
	var is_boss_mode = false
	if player_manager:
		var player_data = player_manager.get_player_data()
		if player_data:
			var selected_mode = player_data.get_selected_mode(location.location_id)
			is_boss_mode = (selected_mode == "boss")
	
	# Если выбран режим босса, сразу генерируем босс-комнату
	if is_boss_mode:
		rooms_cleared = 0  # Сбрасываем прогресс для режима босса
		current_room = _create_boss_room()
		print("👑 Режим босса активирован для локации ", location.location_id)
		return
	
	# НЕ сбрасываем rooms_cleared здесь - это сбрасывает прогресс!
	# rooms_cleared должен сохраняться между возвратами в RoomSelector
	# rooms_cleared = 0  # ← УБРАЛИ ЭТУ СТРОКУ!
	
	# Проверяем, что локация имеет необходимые данные
	if not location.enemy_pools:
		print("ОШИБКА: Локация не имеет enemy_pools!")
		return
	
	# Генерируем первую комнату только если это начало локации
	if rooms_cleared == 0:
		_generate_first_room()

func _generate_first_room():
	# Первая комната - случайный бой с любой редкостью
	current_room = _create_battle_room()  # Без параметра - случайная редкость
	
	
	if not current_room:
		print("ОШИБКА: Не удалось создать первую комнату!")

func generate_next_room_options() -> Array[RoomData]:
	# Генерируем 3 варианта следующих комнат
	var options: Array[RoomData] = []
	
	# Проверяем, не последняя ли это комната
	if rooms_cleared >= max_rooms - 1:
		# Последняя комната - всегда босс
		var boss_room = _create_boss_room()
		options.append(boss_room)
		return options
	
	# Проверяем, нужно ли добавить квестовую комнату
	var quest_room_type = _check_for_quest_room()
	
	if quest_room_type != "":
		# Добавляем квестовую комнату в один из слотов (случайный)
		var quest_slot = randi() % 3
		for i in range(3):
			if i == quest_slot:
				var quest_room: RoomData = null
				match quest_room_type:
					"thiefs_lair":
						quest_room = _create_thiefs_lair_quest_room()
					"ritual_clearing":
						quest_room = _create_ritual_clearing_quest_room()
					"necromancer_crypt":
						quest_room = _create_necromancer_crypt_quest_room()
				
				if quest_room:
					options.append(quest_room)
				else:
					# Fallback на обычную комнату
					var room_type = _get_random_room_type()
					var room = _create_room_by_type(room_type)
					options.append(room)
			else:
				var room_type = _get_random_room_type()
				var room = _create_room_by_type(room_type)
				options.append(room)
	else:
		# Генерируем 3 случайные комнаты
		for i in range(3):
			var room_type = _get_random_room_type()
			var room = _create_room_by_type(room_type)
			options.append(room)
	
	return options

func _get_random_room_type() -> RoomData.RoomType:
	# Веса для разных типов комнат (БЕЗ BOSS - он только в конце)
	var weights = {
		RoomData.RoomType.BATTLE: 90,        # 90% - обычный бой
		RoomData.RoomType.REST: 10           # 10% - отдых
		# Убрали ELITE_BATTLE - элитные враги теперь появляются случайно в обычных комнатах
		# Убрали EVENT и TREASURE
		# BOSS только в последней комнате!
	}
	
	var total_weight = 0
	for weight in weights.values():
		total_weight += weight
	
	var random_roll = randi() % total_weight
	var current_weight = 0
	
	for room_type in weights.keys():
		current_weight += weights[room_type]
		if random_roll < current_weight:
			return room_type
	
	return RoomData.RoomType.BATTLE

func _create_room_by_type(room_type: RoomData.RoomType) -> RoomData:
	match room_type:
		RoomData.RoomType.BATTLE:
			return _create_battle_room()
		RoomData.RoomType.REST:
			return _create_rest_room()
		RoomData.RoomType.BOSS:
			return _create_boss_room()
		_:
			return _create_battle_room()

func _create_battle_room(rarity: String = "") -> RoomData:
	var room = RoomData.new()
	room.room_type = RoomData.RoomType.BATTLE
	
	# Выбираем редкость комнаты (не врага!)
	if rarity == "":
		rarity = _get_random_enemy_rarity()
	
	room.enemy_rarity = rarity  # Это редкость комнаты, которая будет применена к врагу
	
	
	# Выбираем случайного врага из пула локации (независимо от его базовой редкости)
	room.enemy_scene = _get_random_enemy_from_pool()
	
	# Генерируем название и описание
	room.room_name = _get_battle_room_name(rarity)
	room.description = _get_battle_room_description_with_rarity(rarity)
	
	# Убираем награды
	room.exp_reward = 0
	room.gold_reward = 0
	
	return room

func _create_elite_room() -> RoomData:
	var room = RoomData.new()
	room.room_type = RoomData.RoomType.ELITE_BATTLE
	
	# Выбираем базовую редкость для элитного врага (rare, epic или legendary)
	var base_rarity = _get_random_elite_base_rarity()
	
	# Формируем редкость в формате "elite_rare", "elite_epic" или "elite_legendary"
	room.enemy_rarity = "elite_" + base_rarity
	
	# Выбираем случайного врага из пула (кроме босса)
	room.enemy_scene = _get_random_enemy_for_elite()
	
	# Генерируем название и описание в зависимости от базовой редкости
	var rarity_adjective = ""
	match base_rarity:
		"rare":
			rarity_adjective = "Редкий"
		"epic":
			rarity_adjective = "Эпический"
		"legendary":
			rarity_adjective = "Легендарный"
	
	room.room_name = "Элитная комната"
	room.description = "Здесь обитает " + rarity_adjective + " Элитный враг! Будьте осторожны!"
	
	# Убираем награды
	room.exp_reward = 0
	room.gold_reward = 0
	
	return room

func _get_random_elite_base_rarity() -> String:
	# Получаем текущую сложность
	var difficulty = _get_current_difficulty()
	
	# Настраиваем веса для элитных врагов
	# Элитные редкие попадаются чаще, эпические и легендарные - в 3 раза реже обычных
	var weights = {}
	
	match difficulty:
		1:  # Сложность I: только элитные редкие
			weights = {
				"rare": 100
			}
		2:  # Сложность II: добавляются элитные эпические
			weights = {
				"rare": 60,
				"epic": 5  # В 3 раза реже чем обычные epic (15/3 = 5)
			}
		3:  # Сложность III: добавляются элитные легендарные
			weights = {
				"rare": 50,
				"epic": 7,  # В 3 раза реже чем обычные epic (20/3 ≈ 7)
				"legendary": 3  # В 3 раза реже чем обычные legendary (10/3 ≈ 3)
			}
		_:
			weights = {
				"rare": 100
			}
	
	var total_weight = 0
	for weight in weights.values():
		total_weight += weight
	
	var random_roll = randi() % total_weight
	var current_weight = 0
	
	for rarity in weights.keys():
		current_weight += weights[rarity]
		if random_roll < current_weight:
			return rarity
	
	return "rare"  # Fallback

func _create_rest_room() -> RoomData:
	var room = RoomData.new()
	room.room_type = RoomData.RoomType.REST
	room.room_name = "Тихая поляна"
	room.description = "Безопасное место для отдыха. Здесь можно восстановить силы."
	room.exp_reward = 0
	room.gold_reward = 0
	return room

# Удалены методы _create_event_room() и _create_treasure_room() - больше не используются

func _create_boss_room() -> RoomData:
	var room = RoomData.new()
	room.room_type = RoomData.RoomType.BOSS
	
	# Проверяем, это режим босса локации или обычный минибосс
	var player_manager = get_node_or_null("/root/PlayerManager")
	var is_location_boss = false
	if player_manager:
		var player_data = player_manager.get_player_data()
		if player_data and current_location:
			var selected_mode = player_data.get_selected_mode(current_location.location_id)
			is_location_boss = (selected_mode == "boss")
	
	if is_location_boss:
		room.room_name = "Босс локации"
		room.description = "Здесь обитает могущественный Босс локации с особыми наградами!"
	else:
		room.room_name = "Логово босса"
		# Безопасный доступ к boss_enemy
		var _boss_name = "Неизвестный босс"
		if current_location:
			_boss_name = current_location.boss_enemy
		room.description = "Здесь обитает могущественный Босс!"
	
	room.enemy_scene = _get_boss_enemy()
	room.enemy_rarity = "epic" if not is_location_boss else "legendary"  # Босс локации - легендарный
	room.exp_reward = 0
	room.gold_reward = 0
	return room

func _get_random_enemy_rarity() -> String:
	# Получаем текущую сложность
	var difficulty = _get_current_difficulty()
	
	# Настраиваем веса в зависимости от сложности
	var weights = {}
	
	match difficulty:
		1:  # Сложность I: только common, uncommon, rare, elite
			weights = {
				"common": 40,
				"uncommon": 30,
				"rare": 25,
				# Epic и Legendary недоступны на 1 сложности
			}
		2:  # Сложность II: добавляются epic и legendary
			weights = {
				"common": 30,
				"uncommon": 25,
				"rare": 20,
				"epic": 15,
				"legendary": 10
			}
		3:  # Сложность III: добавляются mythic, больше редких
			weights = {
				"common": 20,
				"uncommon": 20,
				"rare": 25,
				"epic": 20,
				"legendary": 10,
				"mythic": 5
			}
		_:  # По умолчанию (как сложность I)
			weights = {
				"common": 40,
				"uncommon": 30,
				"rare": 25,
			}
	
	var total_weight = 0
	for weight in weights.values():
		total_weight += weight
	
	var random_roll = randi() % total_weight
	var current_weight = 0
	
	for rarity in weights.keys():
		current_weight += weights[rarity]
		if random_roll < current_weight:
			return rarity
	
	return "common"

func _get_current_difficulty() -> int:
	"""Возвращает текущую выбранную сложность для локации"""
	var player_manager = get_node_or_null("/root/PlayerManager")
	if not player_manager:
		return 1
	
	var player_data = player_manager.get_player_data()
	if not player_data or not current_location:
		return 1
	
	return player_data.get_selected_difficulty(current_location.location_id)

func _get_random_enemy_from_pool() -> String:
	"""Выбирает случайного врага из пула локации независимо от редкости"""
	if not current_location:
		print("ОШИБКА: current_location не установлена!")
		return "res://Scenes/Battle/Enemy_AlkaraDemon.tscn"
	
	# Проверяем, что enemy_pools существует и не пустой
	if not current_location.enemy_pools:
		print("ОШИБКА: enemy_pools не найден в локации!")
		return "res://Scenes/Battle/Enemy_AlkaraDemon.tscn"
	
	if current_location.enemy_pools.is_empty():
		print("ОШИБКА: enemy_pools пустой!")
		return "res://Scenes/Battle/Enemy_AlkaraDemon.tscn"
	
	# Выбираем случайного врага из пула с учетом весов (spawn_weight)
	var total_weight = 0
	for pool in current_location.enemy_pools:
		if pool:
			total_weight += pool.spawn_weight
	
	if total_weight <= 0:
		print("ОШИБКА: общий вес врагов равен 0!")
		return "res://Scenes/Battle/Enemy_AlkaraDemon.tscn"
	
	var random_roll = randi() % total_weight
	var current_weight = 0
	
	for pool in current_location.enemy_pools:
		if pool:
			current_weight += pool.spawn_weight
			if random_roll < current_weight:
				return pool.enemy_scene
	
	# Fallback - возвращаем первого врага
	if current_location.enemy_pools.size() > 0:
		var first_pool = current_location.enemy_pools[0]
		if first_pool:
			print("Fallback - первый враг: ", first_pool.enemy_scene, " (базовая редкость: ", first_pool.rarity, ")")
			return first_pool.enemy_scene
	
	return "res://Scenes/Battle/Enemy_AlkaraDemon.tscn"

func _get_enemy_for_rarity(rarity: String) -> String:
	if not current_location:
		print("ОШИБКА: current_location не установлена!")
		return "res://Scenes/Battle/Enemy_AlkaraDemon.tscn"
	
	# Проверяем, что enemy_pools существует и не пустой
	if not current_location.enemy_pools:
		print("ОШИБКА: enemy_pools не найден в локации!")
		return "res://Scenes/Battle/Enemy_AlkaraDemon.tscn"
	
	if current_location.enemy_pools.is_empty():
		print("ОШИБКА: enemy_pools пустой!")
		return "res://Scenes/Battle/Enemy_AlkaraDemon.tscn"
	
	# Сначала ищем врагов с нужной редкостью
	var matching_pools = []
	for pool in current_location.enemy_pools:
		if pool and pool.rarity == rarity:
			matching_pools.append(pool)
	
	# Если нашли врагов с нужной редкостью, выбираем из них
	if not matching_pools.is_empty():
		var total_weight = 0
		for pool in matching_pools:
			total_weight += pool.spawn_weight
		
		if total_weight > 0:
			var random_roll = randi() % total_weight
			var current_weight = 0
			
			for pool in matching_pools:
				current_weight += pool.spawn_weight
				if random_roll < current_weight:
					print("Выбран враг с редкостью ", rarity, ": ", pool.enemy_scene, " (вес: ", pool.spawn_weight, ")")
					return pool.enemy_scene
	
	# Если не нашли врагов с нужной редкостью, выбираем случайного
	print("ВНИМАНИЕ: Не найдено врагов с редкостью ", rarity, ", выбираем случайного")
	var fallback_total_weight = 0
	for pool in current_location.enemy_pools:
		if pool:
			fallback_total_weight += pool.spawn_weight
	
	if fallback_total_weight <= 0:
		print("ОШИБКА: общий вес врагов равен 0!")
		return "res://Scenes/Battle/Enemy_AlkaraDemon.tscn"
	
	var fallback_random_roll = randi() % fallback_total_weight
	var fallback_current_weight = 0
	
	for pool in current_location.enemy_pools:
		if pool:
			fallback_current_weight += pool.spawn_weight
			if fallback_random_roll < fallback_current_weight:
				return pool.enemy_scene
	
	# Fallback - возвращаем первого врага
	if current_location.enemy_pools.size() > 0:
		var first_pool = current_location.enemy_pools[0]
		if first_pool:
			print("Fallback - первый враг: ", first_pool.enemy_scene, " (редкость: ", first_pool.rarity, ")")
			return first_pool.enemy_scene
	
	return "res://Scenes/Battle/Enemy_AlkaraDemon.tscn"

func _get_random_enemy_for_elite() -> String:
	# Выбираем случайного врага из пула (кроме босса)
	if not current_location:
		print("ОШИБКА: current_location не установлена для элитного врага!")
		return "res://Scenes/Battle/Enemy_AlkaraDemon.tscn"
	
	if not current_location.enemy_pools:
		print("ОШИБКА: enemy_pools не найден для элитного врага!")
		return "res://Scenes/Battle/Enemy_AlkaraDemon.tscn"
	
	if current_location.enemy_pools.is_empty():
		print("ОШИБКА: enemy_pools пустой для элитного врага!")
		return "res://Scenes/Battle/Enemy_AlkaraDemon.tscn"
	
	# Выбираем случайного врага из пула с учетом весов
	var total_weight = 0
	for pool in current_location.enemy_pools:
		if pool:
			total_weight += pool.spawn_weight
	
	if total_weight <= 0:
		print("ОШИБКА: общий вес врагов равен 0 для элитного врага!")
		return "res://Scenes/Battle/Enemy_AlkaraDemon.tscn"
	
	var random_roll = randi() % total_weight
	var current_weight = 0
	
	for pool in current_location.enemy_pools:
		if pool:
			current_weight += pool.spawn_weight
			if random_roll < current_weight:
				return pool.enemy_scene
	
	# Fallback - возвращаем первого врага
	if current_location.enemy_pools.size() > 0:
		var first_pool = current_location.enemy_pools[0]
		if first_pool:
			print("Fallback - первый элитный враг: ", first_pool.enemy_scene)
			return first_pool.enemy_scene
	
	return "res://Scenes/Battle/Enemy_AlkaraDemon.tscn"

func _get_boss_enemy() -> String:
	# Используем boss_enemy из LocationData
	if not current_location:
		print("ОШИБКА: current_location не установлена для босса!")
		return "res://Scenes/Battle/Enemy_AlkaraDemon.tscn"
	
	# Проверяем, есть ли установленный босс
	if current_location.boss_enemy and current_location.boss_enemy != "":
		var boss_scene = "res://Scenes/Battle/Enemy_" + current_location.boss_enemy + ".tscn"
		# Проверяем, существует ли файл
		if ResourceLoader.exists(boss_scene):
			return boss_scene
	
	# Fallback: ищем эпического или легендарного врага из пула
	if not current_location.enemy_pools:
		print("ОШИБКА: enemy_pools не найден для босса!")
		return "res://Scenes/Battle/Enemy_AlkaraDemon.tscn"
	
	if current_location.enemy_pools.is_empty():
		print("ОШИБКА: enemy_pools пустой для босса!")
		return "res://Scenes/Battle/Enemy_AlkaraDemon.tscn"
	
	# Ищем эпического или легендарного врага
	for pool in current_location.enemy_pools:
		if pool:
			if pool.rarity == "epic" or pool.rarity == "legendary":
				return pool.enemy_scene
	
	# Если не нашли, берем последнего (обычно самого сильного)
	if current_location.enemy_pools.size() > 0:
		var last_pool = current_location.enemy_pools[-1]
		if last_pool:
			return last_pool.enemy_scene
	
	return "res://Scenes/Battle/Enemy_AlkaraDemon.tscn"

func _get_battle_room_name(rarity: String) -> String:
	"""Генерирует название комнаты в зависимости от локации и редкости"""
	# Получаем ID текущей локации
	var location_id = "dungeon"  # По умолчанию
	if current_location and "location_id" in current_location:
		location_id = current_location.location_id
	
	# Получаем названия для текущей локации
	var location_names = _get_location_room_names(location_id)
	
	# Выбираем названия для нужной редкости
	var rarity_names = location_names.get(rarity, location_names["common"])
	if rarity_names.size() == 0:
		# Fallback на общие названия, если для редкости нет вариантов
		rarity_names = location_names["common"]
	
	return rarity_names[randi() % rarity_names.size()]

func _get_location_room_names(location_id: String) -> Dictionary:
	"""Возвращает словарь названий комнат для указанной локации"""
	var all_location_names = {
		"dungeon": {
			"common": ["Темный коридор", "Заброшенная камера", "Пыльный зал", "Подземный проход", "Каменная комната"],
			"uncommon": ["Опасный проход", "Зараженная камера", "Теневой угол", "Заброшенная тюрьма", "Гнилой склеп"],
			"rare": ["Древняя тюрьма", "Проклятый зал", "Тайная комната", "Забытый подвал", "Мрачный коридор"],
			"epic": ["Элитная камера", "Магический зал", "Запретная зона", "Древний склеп", "Темная камера пыток"],
			"legendary": ["Легендарная тюрьма", "Мистический зал", "Божественная камера", "Проклятый подвал", "Забытая тюрьма"]
		},
		"forest": {
			"common": ["Лесная тропа", "Заросшая поляна", "Тенистая роща", "Густой подлесок", "Лесная опушка"],
			"uncommon": ["Опасная тропа", "Зараженная поляна", "Темная роща", "Заброшенная тропа", "Гнилая поляна"],
			"rare": ["Древняя роща", "Проклятая поляна", "Тайная тропа", "Забытая поляна", "Мрачная роща"],
			"epic": ["Элитная роща", "Магическая поляна", "Запретная тропа", "Древняя поляна", "Темная роща"],
			"legendary": ["Легендарная роща", "Мистическая поляна", "Божественная тропа", "Проклятая роща", "Забытая поляна"]
		},
		"dark_forest": {
			"common": ["Зачарованная тропа", "Мистическая поляна", "Теневой лес", "Волшебная роща", "Магическая опушка"],
			"uncommon": ["Опасная тропа", "Зараженная поляна", "Темная роща", "Проклятая тропа", "Гнилая поляна"],
			"rare": ["Древняя роща", "Проклятая поляна", "Тайная тропа", "Забытая поляна", "Мрачная роща"],
			"epic": ["Элитная роща", "Магическая поляна", "Запретная тропа", "Древняя поляна", "Темная роща"],
			"legendary": ["Легендарная роща", "Мистическая поляна", "Божественная тропа", "Проклятая роща", "Забытая поляна"]
		},
		"cemetery": {
			"common": ["Заброшенная могила", "Старый склеп", "Разрушенная часовня", "Заросшая могила", "Забытый склеп"],
			"uncommon": ["Опасный склеп", "Зараженная могила", "Теневой склеп", "Проклятая могила", "Гнилой склеп"],
			"rare": ["Древний склеп", "Проклятая могила", "Тайный склеп", "Забытая могила", "Мрачный склеп"],
			"epic": ["Элитный склеп", "Магическая могила", "Запретный склеп", "Древняя могила", "Темный склеп"],
			"legendary": ["Легендарный склеп", "Мистическая могила", "Божественный склеп", "Проклятый склеп", "Забытая могила"]
		},
		"demon_lair": {
			"common": ["Демонический коридор", "Адский зал", "Проклятый проход", "Темный коридор", "Огненная комната"],
			"uncommon": ["Опасный проход", "Зараженный зал", "Теневой коридор", "Проклятый зал", "Гнилой проход"],
			"rare": ["Древний зал", "Проклятый коридор", "Тайная камера", "Забытый зал", "Мрачный коридор"],
			"epic": ["Элитный зал", "Магический коридор", "Запретная камера", "Древний коридор", "Темный зал"],
			"legendary": ["Легендарный зал", "Мистический коридор", "Божественная камера", "Проклятый зал", "Забытый коридор"]
		},
		"mysterious_wastelands": {
			"common": ["Пещерный проход", "Темная пещера", "Заброшенный грот", "Каменная пещера", "Подземный грот"],
			"uncommon": ["Опасный проход", "Зараженная пещера", "Теневой грот", "Проклятая пещера", "Гнилой проход"],
			"rare": ["Древняя пещера", "Проклятый грот", "Тайная пещера", "Забытый грот", "Мрачная пещера"],
			"epic": ["Элитная пещера", "Магический грот", "Запретная пещера", "Древний грот", "Темная пещера"],
			"legendary": ["Легендарная пещера", "Мистический грот", "Божественная пещера", "Проклятый грот", "Забытая пещера"]
		},
		"sinister_swamps": {
			"common": ["Болотная тропа", "Трясина", "Заболоченная поляна", "Туманное болото", "Гнилое болото"],
			"uncommon": ["Опасная трясина", "Зараженное болото", "Теневая тропа", "Проклятая трясина", "Гнилая поляна"],
			"rare": ["Древнее болото", "Проклятая трясина", "Тайная тропа", "Забытое болото", "Мрачная трясина"],
			"epic": ["Элитное болото", "Магическая трясина", "Запретная тропа", "Древняя трясина", "Темное болото"],
			"legendary": ["Легендарное болото", "Мистическая трясина", "Божественная тропа", "Проклятое болото", "Забытая трясина"]
		},
		"volcanic_valley": {
			"common": ["Лавовая тропа", "Огненная долина", "Вулканический проход", "Раскаленная долина", "Пылающая тропа"],
			"uncommon": ["Опасная тропа", "Зараженная долина", "Теневая тропа", "Проклятая долина", "Гнилая тропа"],
			"rare": ["Древняя долина", "Проклятая тропа", "Тайная долина", "Забытая тропа", "Мрачная долина"],
			"epic": ["Элитная долина", "Магическая тропа", "Запретная долина", "Древняя тропа", "Темная долина"],
			"legendary": ["Легендарная долина", "Мистическая тропа", "Божественная долина", "Проклятая долина", "Забытая тропа"]
		},
		"angel_halls": {
			"common": ["Небесный зал", "Светлый коридор", "Божественный проход", "Сияющий зал", "Священный коридор"],
			"uncommon": ["Опасный зал", "Зараженный коридор", "Теневой проход", "Проклятый зал", "Гнилой коридор"],
			"rare": ["Древний зал", "Проклятый коридор", "Тайный зал", "Забытый коридор", "Мрачный зал"],
			"epic": ["Элитный зал", "Магический коридор", "Запретный зал", "Древний коридор", "Темный зал"],
			"legendary": ["Легендарный зал", "Мистический коридор", "Божественный зал", "Проклятый зал", "Забытый коридор"]
		}
	}
	
	# Возвращаем названия для локации или дефолтные (подземелье)
	return all_location_names.get(location_id, all_location_names["dungeon"])

func _get_battle_room_description_with_rarity(rarity: String) -> String:
	"""Генерирует описание комнаты на основе редкости самого редкого врага"""
	var rarity_name = ""
	
	# Обрабатываем элитные редкости
	if rarity.begins_with("elite_"):
		var base_rarity = rarity.substr(6)  # Убираем "elite_"
		match base_rarity:
			"rare":
				rarity_name = "Элитный Редкий"
			"epic":
				rarity_name = "Элитный Эпический"
			"legendary":
				rarity_name = "Элитный Легендарный"
			_:
				rarity_name = "Элитный"
		return "Здесь обитает " + rarity_name + " враг! Будьте осторожны!"
	
	# Обычные редкости
	match rarity.to_lower():
		"common":
			rarity_name = "Обычный"
		"uncommon":
			rarity_name = "Необычный"
		"rare":
			rarity_name = "Редкий"
		"epic":
			rarity_name = "Эпический"
		"legendary":
			rarity_name = "Легендарный"
		"mythic":
			rarity_name = "Мифический"
		"boss":
			rarity_name = "Босс"
		_:
			rarity_name = "Обычный"
	
	return "Здесь обитает " + rarity_name + " враг."

# Удалены методы _get_exp_reward_for_rarity() и _get_gold_reward_for_rarity() - больше не используются

func clear_current_room():
	if current_room:
		current_room.is_cleared = true
		rooms_cleared += 1
		# НЕ испускаем сигнал room_cleared здесь - это создает рекурсию!
		# Сигнал должен испускаться только в нужных местах
		
		# Проверяем, завершена ли локация
		if rooms_cleared >= max_rooms:
			print("Локация завершена! Все комнаты пройдены.")
			emit_signal("location_completed")
	else:
		print("ОШИБКА: current_room не установлена при попытке очистки!")

func emit_room_cleared_signal():
	# Отдельная функция для испускания сигнала room_cleared
	if current_room:
		emit_signal("room_cleared", current_room)

func get_current_room() -> RoomData:
	return current_room

func set_current_room(room: RoomData):
	current_room = room

func reset_location_progress():
	# Сбрасываем прогресс только при начале новой локации
	rooms_cleared = 0

# ============================================================================
# КВЕСТОВЫЕ КОМНАТЫ
# ============================================================================

func _check_for_quest_room() -> String:
	"""Проверяет, нужно ли добавить квестовую комнату. Возвращает тип комнаты или пустую строку"""
	if not current_location:
		return ""
	
	# Комната появляется после 3-й комнаты (rooms_cleared >= 3)
	if rooms_cleared < 3:
		return ""
	
	# Проверяем статус квестов через PlayerData
	var player_manager = get_node_or_null("/root/PlayerManager")
	if not player_manager:
		return ""
	
	var player_data = player_manager.get_player_data()
	if not player_data:
		return ""
	
	var location_id = current_location.location_id
	
	# 1. Проверка комнаты "Логово вора" (Урна душ) - Подземелье под городом
	if location_id == "dungeon":
		var quest_active = player_data.is_quest_active("find_soul_urn")
		var has_urn = player_data.has_soul_urn
		print("DEBUG: Проверка комнаты 'Логово вора': quest_active=", quest_active, ", has_urn=", has_urn, ", rooms_cleared=", rooms_cleared)
		if quest_active and not has_urn:
			var chance = randf()
			print("DEBUG: Шанс появления комнаты: ", chance)
			if chance < 0.5:  # 50% шанс
				print("DEBUG: Комната 'Логово вора' будет добавлена!")
				return "thiefs_lair"
			else:
				print("DEBUG: Комната 'Логово вора' не появилась (шанс не выпал)")
	
	# 2. Проверка комнаты "Ритуальная поляна" (Кристалл познания) - Тёмный лес
	if location_id == "forest":
		if player_data.is_quest_active("find_knowledge_crystal") and not player_data.has_knowledge_crystal:
			if randf() < 0.5:  # 50% шанс
				return "ritual_clearing"
	
	# 3. Проверка комнаты "Склеп некроманта" (Филактерия) - Заброшенное кладбище
	if location_id == "cemetery":
		if player_data.has_knowledge_crystal and not player_data.has_phylactery:
			if randf() < 0.5:  # 50% шанс
				return "necromancer_crypt"
	
	return ""

func _create_thiefs_lair_quest_room() -> RoomData:
	"""Создает квестовую комнату 'Логово вора' с редким слизнем"""
	var room = RoomData.new()
	room.room_type = RoomData.RoomType.BATTLE
	room.room_id = "thiefs_lair"
	room.room_name = "Логово вора"
	room.description = "Старое убежище, где когда-то скрывался вор. В воздухе витает зловещая аура..."
	room.is_quest_room = true  # Помечаем как квестовую
	
	# Устанавливаем редкого слизня
	room.enemy_scene = "res://Scenes/Battle/Enemy_Slime.tscn"
	room.enemy_rarity = "rare"  # Редкий слизень с Урной душ
	
	room.exp_reward = 0
	room.gold_reward = 0
	
	print("📜 Создана квестовая комната: Логово вора (Редкий слизень)")
	
	return room

func _create_ritual_clearing_quest_room() -> RoomData:
	"""Создает квестовую комнату 'Ритуальная поляна' с Орком культистом"""
	var room = RoomData.new()
	room.room_type = RoomData.RoomType.BATTLE
	room.room_id = "ritual_clearing"
	room.room_name = "Ритуальная поляна"
	room.description = "Загадочная поляна в глубине леса. В центре стоит каменный алтарь, покрытый древними рунами. Орк культист проводит темный ритуал..."
	room.is_quest_room = true  # Помечаем как квестовую
	
	# Устанавливаем эпического Орка шамана (Орк культист)
	room.enemy_scene = "res://Scenes/Battle/Enemy_OrcShaman.tscn"
	room.enemy_rarity = "epic"  # Эпический Орк шаман с Кристаллом познания
	
	room.exp_reward = 0
	room.gold_reward = 0
	
	print("📜 Создана квестовая комната: Ритуальная поляна (Орк культист)")
	
	return room

func _create_necromancer_crypt_quest_room() -> RoomData:
	"""Создает квестовую комнату 'Склеп некроманта' с Древним скелетом"""
	var room = RoomData.new()
	room.room_type = RoomData.RoomType.BATTLE
	room.room_id = "necromancer_crypt"
	room.room_name = "Склеп некроманта"
	room.description = "Древний склеп, пропитанный магией некромантии. В центре стоит саркофаг, из которого доносится странное свечение. Древний скелет охраняет свою филактерию..."
	room.is_quest_room = true  # Помечаем как квестовую
	
	# Устанавливаем легендарного Элитного скелета (Древний скелет)
	room.enemy_scene = "res://Scenes/Battle/Enemy_EliteSkeleton.tscn"
	room.enemy_rarity = "legendary"  # Легендарный Элитный скелет с Филактерией
	
	room.exp_reward = 0
	room.gold_reward = 0
	
	print("📜 Создана квестовая комната: Склеп некроманта (Древний скелет)")
	
	return room

# res://Scripts/PlayerManager.gd
extends Node

var player_data: PlayerData
var is_initialized: bool = false
var is_in_location: bool = false  # Флаг для отслеживания прохождения локации

func _ready():
	# PlayerManager теперь автозагрузка, поэтому он создается только один раз
	initialize_player()
	
	# Пытаемся загрузить сохраненные данные
	var game_loaded = load_game_data()
	
	# Если игра не загружена (новая игра), инициализируем осколки душ
	if not game_loaded:
		print("PlayerManager._ready() - новая игра, инициализируем осколки душ")
		var soul_shard_manager = get_node_or_null("/root/SoulShard")
		if soul_shard_manager:
			soul_shard_manager.load_soul_shards()  # Это установит тестовый баланс
		else:
			print("ОШИБКА: SoulShardManager не найден для новой игры!")

func initialize_player():
	if not is_initialized:
		player_data = PlayerData.new()
		player_data.name = "PlayerData"
		add_child(player_data)
		is_initialized = true
		
		# Синхронизация из инспектора теперь происходит в battle_manager.gd
	else:
		# Если уже инициализирован, сбрасываем к начальным значениям
		reset_player_to_default()
	
	# Активируем начальный квест "Урна душ" при создании нового игрока
	# (теперь это происходит всегда, а не только при первой инициализации)
	player_data.add_quest("find_soul_urn")
	print("📜 Начальный квест 'find_soul_urn' добавлен в доступные квесты")

func _sync_from_inspector():
	# Синхронизируем значения из инспектора PlayerBody в глобальный менеджер
	# Это нужно сделать только один раз при инициализации
	var player_body = get_tree().get_first_node_in_group("player")
	if player_body and player_body.has_method("get_inspector_stats"):
		var inspector_stats = player_body.get_inspector_stats()
		if inspector_stats:
			player_data.strength = inspector_stats.strength
			player_data.agility = inspector_stats.agility
			player_data.vitality = inspector_stats.vitality
			player_data.endurance = inspector_stats.endurance
			player_data.intelligence = inspector_stats.intelligence
			player_data.wisdom = inspector_stats.wisdom
			player_data.calculate_stat_bonuses()
			player_data.apply_stat_bonuses()

func get_player_data() -> PlayerData:
	if not is_initialized:
		initialize_player()
	return player_data

func reset_player_to_default():
	"""Полностью сбрасывает данные игрока к начальным значениям"""
	if player_data:
		# Сбрасываем все характеристики к начальным значениям
		player_data.level = 1
		player_data.experience = 0
		player_data.gold = 0
		player_data.stat_points = 20
		
		# Сбрасываем базовые характеристики
		player_data.base_strength = 5
		player_data.base_agility = 5
		player_data.base_vitality = 5
		player_data.base_endurance = 5
		player_data.base_intelligence = 5
		player_data.base_wisdom = 5
		
		# Сбрасываем финальные характеристики
		player_data.strength = 5
		player_data.agility = 5
		player_data.vitality = 5
		player_data.endurance = 5
		player_data.intelligence = 5
		player_data.wisdom = 5
		
		# Сбрасываем ресурсы
		player_data.current_hp = 100
		player_data.max_hp = 100
		player_data.current_mp = 100
		player_data.max_mp = 100
		player_data.current_stamina = 100
		player_data.max_stamina = 100
		player_data.base_hp = 100
		player_data.base_mp = 100
		player_data.base_stamina = 100
		
		# Сбрасываем духовную мощь
		player_data.spiritual_power = 5
		player_data.max_spiritual_power = 5
		player_data.used_spiritual_power = 0
		
		# Очищаем все пассивные способности
		player_data.learned_passives.clear()
		player_data.active_passives.clear()
		
		# Сбрасываем бонусы от пассивных способностей
		player_data.passive_strength_bonus = 0
		player_data.passive_agility_bonus = 0
		player_data.passive_vitality_bonus = 0
		player_data.passive_endurance_bonus = 0
		player_data.passive_intelligence_bonus = 0
		player_data.passive_wisdom_bonus = 0
		player_data.passive_hp_bonus = 0
		
	# Сбрасываем мета-прогрессию и квесты
	player_data.met_soul_sculptor = false
	player_data.seen_first_dialogue = false
	player_data.has_soul_urn = false
	player_data.soul_urn_delivered = false
	player_data.soul_urn_reward_received = false
	player_data.has_knowledge_crystal = false
	player_data.knowledge_crystal_delivered = false
	player_data.has_phylactery = false
	player_data.phylactery_delivered = false
	player_data.has_ancient_skull = false
	player_data.ancient_skull_delivered = false
	player_data.max_passive_level = 0
	player_data.max_soul_development_level = 0
	
	# Очищаем квесты
	player_data.available_quests.clear()
	player_data.active_quests.clear()
	player_data.completed_quests.clear()
	
	# Сбрасываем сложности локаций
	player_data.unlocked_difficulties.clear()
	player_data.selected_difficulty.clear()
	player_data.unlocked_location_bosses.clear()
	player_data.selected_mode.clear()
	
	# Пересчитываем бонусы
	player_data.calculate_stat_bonuses()
	player_data.apply_stat_bonuses()
	
	# Активируем начальный квест "Урна душ" при старте новой игры
	player_data.add_quest("find_soul_urn")
	print("📜 Начальный квест 'find_soul_urn' активирован при старте новой игры")
	
	print("Данные игрока сброшены к начальным значениям")
	print("Base stats: STR=", player_data.base_strength, " AGI=", player_data.base_agility, " VIT=", player_data.base_vitality)
	print("Final stats: STR=", player_data.strength, " AGI=", player_data.agility, " VIT=", player_data.vitality)

func save_game_data():
	# Сохраняем все данные игры в файл
	if not player_data:
		return false
	
	var save_data = {
			"player_data": {
				"level": player_data.level,
				"experience": player_data.experience,
				"gold": player_data.gold,
				"stat_points": player_data.stat_points,
				"strength": player_data.strength,
				"agility": player_data.agility,
				"vitality": player_data.vitality,
				"endurance": player_data.endurance,
				"intelligence": player_data.intelligence,
				"wisdom": player_data.wisdom,
				"base_strength": player_data.base_strength,
				"base_agility": player_data.base_agility,
				"base_vitality": player_data.base_vitality,
				"base_endurance": player_data.base_endurance,
				"base_intelligence": player_data.base_intelligence,
				"base_wisdom": player_data.base_wisdom,
				"current_hp": player_data.current_hp,
				"max_hp": player_data.max_hp,
				"current_mp": player_data.current_mp,
				"max_mp": player_data.max_mp,
				"current_stamina": player_data.current_stamina,
				"max_stamina": player_data.max_stamina,
				"base_hp": player_data.base_hp,
				"base_mp": player_data.base_mp,
				"base_stamina": player_data.base_stamina,
			"spiritual_power": player_data.spiritual_power,
			"max_spiritual_power": player_data.max_spiritual_power,
			"used_spiritual_power": player_data.used_spiritual_power,
			"learned_passives": player_data.learned_passives,
			"active_passives": player_data.active_passives,
			
		# Мета-прогрессия (квесты и артефакты)
		"met_soul_sculptor": player_data.met_soul_sculptor,
		"seen_first_dialogue": player_data.seen_first_dialogue,
		"has_soul_urn": player_data.has_soul_urn,
		"soul_urn_delivered": player_data.soul_urn_delivered,
		"soul_urn_reward_received": player_data.soul_urn_reward_received,
		"has_knowledge_crystal": player_data.has_knowledge_crystal,
		"knowledge_crystal_delivered": player_data.knowledge_crystal_delivered,
		"has_phylactery": player_data.has_phylactery,
		"phylactery_delivered": player_data.phylactery_delivered,
		"has_ancient_skull": player_data.has_ancient_skull,
		"ancient_skull_delivered": player_data.ancient_skull_delivered,
		"max_passive_level": player_data.max_passive_level,
		"max_soul_development_level": player_data.max_soul_development_level,
		"available_quests": player_data.available_quests,
		"active_quests": player_data.active_quests,
		"completed_quests": player_data.completed_quests,
		
		# Система сложностей
		"unlocked_difficulties": player_data.unlocked_difficulties,
		"selected_difficulty": player_data.selected_difficulty,
		"unlocked_location_bosses": player_data.unlocked_location_bosses,
		"selected_mode": player_data.selected_mode
		},
		"game_progress": {
			"unlocked_locations": get_unlocked_locations(),
			"current_location": get_current_location_id(),
			"rooms_cleared": get_rooms_cleared() if is_in_location else 0
		}
	}
	
	# Сохраняем осколки душ
	var soul_shard_manager = get_node_or_null("/root/SoulShard")
	if soul_shard_manager:
		soul_shard_manager.save_soul_shards()
	
	# Сохраняем новые валюты
	var strong_souls_manager = get_node_or_null("/root/StrongSouls")
	if strong_souls_manager:
		strong_souls_manager.save_data()
	
	var great_souls_manager = get_node_or_null("/root/GreatSouls")
	if great_souls_manager:
		great_souls_manager.save_data()
	
	var divine_souls_manager = get_node_or_null("/root/DivineSouls")
	if divine_souls_manager:
		divine_souls_manager.save_data()
	
	var save_file = FileAccess.open("user://savegame.dat", FileAccess.WRITE)
	if save_file == null:
		return false
	
	save_file.store_string(JSON.stringify(save_data))
	save_file.close()
	
	return true

func load_game_data():
	# Загружаем данные игры из файла
	if not FileAccess.file_exists("user://savegame.dat"):
		return false
	
	var save_file = FileAccess.open("user://savegame.dat", FileAccess.READ)
	if save_file == null:
		return false
	
	var json_string = save_file.get_as_text()
	save_file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		return false
	
	var save_data = json.get_data()
	
	# Загружаем данные игрока
	if save_data.has("player_data"):
		var player_save = save_data["player_data"]
		player_data.level = player_save.get("level", 1)
		player_data.experience = player_save.get("experience", 0)
		player_data.gold = player_save.get("gold", 0)
		player_data.stat_points = player_save.get("stat_points", 20)
		player_data.strength = player_save.get("strength", 5)
		player_data.agility = player_save.get("agility", 5)
		player_data.vitality = player_save.get("vitality", 5)
		player_data.endurance = player_save.get("endurance", 5)
		player_data.intelligence = player_save.get("intelligence", 5)
		player_data.wisdom = player_save.get("wisdom", 5)
		player_data.base_strength = player_save.get("base_strength", 5)
		player_data.base_agility = player_save.get("base_agility", 5)
		player_data.base_vitality = player_save.get("base_vitality", 5)
		player_data.base_endurance = player_save.get("base_endurance", 5)
		player_data.base_intelligence = player_save.get("base_intelligence", 5)
		player_data.base_wisdom = player_save.get("base_wisdom", 5)
		player_data.current_hp = player_save.get("current_hp", 100)
		player_data.max_hp = player_save.get("max_hp", 100)
		player_data.current_mp = player_save.get("current_mp", 100)
		player_data.max_mp = player_save.get("max_mp", 100)
		player_data.current_stamina = player_save.get("current_stamina", 100)
		player_data.max_stamina = player_save.get("max_stamina", 100)
		player_data.base_hp = player_save.get("base_hp", 100)
		player_data.base_mp = player_save.get("base_mp", 100)
		player_data.base_stamina = player_save.get("base_stamina", 100)
		
		# Загружаем духовную мощь (если нет в сохранении, рассчитываем заново)
		player_data.spiritual_power = player_save.get("spiritual_power", 5 + (player_data.level - 1))
		player_data.max_spiritual_power = player_save.get("max_spiritual_power", 5 + (player_data.level - 1))
		player_data.used_spiritual_power = player_save.get("used_spiritual_power", 0)
		
		# Приводим массивы к правильному типу Array[String]
		var learned_passives_data = player_save.get("learned_passives", [])
		var active_passives_data = player_save.get("active_passives", [])
		
		# Очищаем массивы и заполняем заново с правильным типом
		player_data.learned_passives.clear()
		player_data.active_passives.clear()
		
		for passive_id in learned_passives_data:
			if passive_id is String:
				player_data.learned_passives.append(passive_id)
		
		for passive_id in active_passives_data:
			if passive_id is String:
				player_data.active_passives.append(passive_id)
		
		# Загружаем мета-прогрессию (квесты и артефакты)
		player_data.met_soul_sculptor = player_save.get("met_soul_sculptor", false)
		player_data.seen_first_dialogue = player_save.get("seen_first_dialogue", false)
		player_data.has_soul_urn = player_save.get("has_soul_urn", false)
		player_data.soul_urn_delivered = player_save.get("soul_urn_delivered", false)
		player_data.soul_urn_reward_received = player_save.get("soul_urn_reward_received", false)
		player_data.has_knowledge_crystal = player_save.get("has_knowledge_crystal", false)
		player_data.knowledge_crystal_delivered = player_save.get("knowledge_crystal_delivered", false)
		# Загружаем Филактерию с обратной совместимостью
		player_data.has_phylactery = player_save.get("has_phylactery", false)
		player_data.phylactery_delivered = player_save.get("phylactery_delivered", false)
		# Загружаем Древний череп
		player_data.has_ancient_skull = player_save.get("has_ancient_skull", false)
		player_data.ancient_skull_delivered = player_save.get("ancient_skull_delivered", false)
		# Обратная совместимость со старыми сохранениями
		if player_save.has("has_eternity_sphere") and not player_data.has_phylactery:
			player_data.has_phylactery = player_save.get("has_eternity_sphere", false)
		player_data.max_passive_level = player_save.get("max_passive_level", 0)
		player_data.max_soul_development_level = player_save.get("max_soul_development_level", 0)
		
		# Загружаем квесты
		var available_quests_data = player_save.get("available_quests", [])
		var active_quests_data = player_save.get("active_quests", [])
		var completed_quests_data = player_save.get("completed_quests", [])
		
		player_data.available_quests.clear()
		player_data.active_quests.clear()
		player_data.completed_quests.clear()
		
		for quest_id in available_quests_data:
			if quest_id is String:
				player_data.available_quests.append(quest_id)
		
		for quest_id in active_quests_data:
			if quest_id is String:
				player_data.active_quests.append(quest_id)
		
		for quest_id in completed_quests_data:
			if quest_id is String:
				player_data.completed_quests.append(quest_id)
		
		# Загружаем сложности локаций
		player_data.unlocked_difficulties = player_save.get("unlocked_difficulties", {})
		player_data.selected_difficulty = player_save.get("selected_difficulty", {})
		player_data.unlocked_location_bosses = player_save.get("unlocked_location_bosses", {})
		player_data.selected_mode = player_save.get("selected_mode", {})
		
		# Инициализируем систему пассивных способностей
		player_data.initialize_passive_system()
		
		# Применяем бонусы от активных пассивных способностей
		player_data.apply_active_passive_bonuses()
		
		# Пересчитываем бонусы
		player_data.calculate_stat_bonuses()
		player_data.apply_stat_bonuses()
	
	# Загружаем прогресс игры
	if save_data.has("game_progress"):
		var progress_save = save_data["game_progress"]
		load_unlocked_locations(progress_save.get("unlocked_locations", []))
		set_current_location_id(progress_save.get("current_location", "dungeon"))
		set_rooms_cleared(progress_save.get("rooms_cleared", 0))
	
	# Загружаем осколки душ только если есть основное сохранение игры
	var soul_shard_manager = get_node_or_null("/root/SoulShard")
	if soul_shard_manager:
		soul_shard_manager.load_soul_shards()
	else:
		print("ОШИБКА: SoulShardManager не найден в PlayerManager.load_game_data()!")
	
	# Загружаем новые валюты
	var strong_souls_manager = get_node_or_null("/root/StrongSouls")
	if strong_souls_manager:
		strong_souls_manager.load_data()
	
	var great_souls_manager = get_node_or_null("/root/GreatSouls")
	if great_souls_manager:
		great_souls_manager.load_data()
	
	var divine_souls_manager = get_node_or_null("/root/DivineSouls")
	if divine_souls_manager:
		divine_souls_manager.load_data()
	
	return true

func save_player_state():
	# Сохраняем состояние игрока (вызывается из battle_manager)
	save_game_data()

func load_player_state():
	# Загружаем состояние игрока (вызывается из battle_manager)
	load_game_data()

# Вспомогательные функции для работы с прогрессом игры
func get_unlocked_locations() -> Array:
	# Получаем список разблокированных локаций
	var location_manager = get_node_or_null("/root/LocationManager")
	if not location_manager:
		return ["dungeon"]  # По умолчанию только подземелье открыто
	
	var unlocked = []
	for location_id in location_manager.locations.keys():
		var location = location_manager.locations[location_id]
		if location.is_unlocked:
			unlocked.append(location_id)
	
	return unlocked

func load_unlocked_locations(unlocked_list: Array):
	# Загружаем список разблокированных локаций
	var location_manager = get_node_or_null("/root/LocationManager")
	if not location_manager:
		return
	
	# Сначала закрываем все локации
	for location in location_manager.locations.values():
		location.is_unlocked = false
	
	# Затем открываем сохраненные
	for location_id in unlocked_list:
		if location_id in location_manager.locations:
			location_manager.locations[location_id].is_unlocked = true

func get_current_location_id() -> String:
	# Получаем ID текущей локации
	var location_manager = get_node_or_null("/root/LocationManager")
	if not location_manager or not location_manager.current_location:
		return "dungeon"
	
	return location_manager.current_location.location_id

func set_current_location_id(location_id: String):
	# Устанавливаем текущую локацию
	var location_manager = get_node_or_null("/root/LocationManager")
	if not location_manager:
		return
	
	if location_id in location_manager.locations:
		location_manager.set_current_location(location_id)

func get_rooms_cleared() -> int:
	# Получаем количество пройденных комнат
	var room_generator = get_node_or_null("/root/RoomGenerator")
	if not room_generator:
		return 0
	
	return room_generator.rooms_cleared

func set_rooms_cleared(rooms: int):
	# Устанавливаем количество пройденных комнат
	var room_generator = get_node_or_null("/root/RoomGenerator")
	if not room_generator:
		return
	
	room_generator.rooms_cleared = rooms

func has_save_file() -> bool:
	# Проверяем, есть ли файл сохранения
	return FileAccess.file_exists("user://savegame.dat")

func delete_save_file():
	# Удаляем файл сохранения
	if FileAccess.file_exists("user://savegame.dat"):
		DirAccess.remove_absolute("user://savegame.dat")

# Функции для управления состоянием прохождения локации
func set_in_location(value: bool):
	"""Устанавливает флаг прохождения локации"""
	is_in_location = value

func is_player_in_location() -> bool:
	"""Проверяет, находится ли игрок в процессе прохождения локации"""
	return is_in_location

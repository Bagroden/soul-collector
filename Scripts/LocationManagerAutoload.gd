# res://Scripts/LocationManagerAutoload.gd
extends Node

class EnemyPool:
	var enemy_scene: String
	var rarity: String  # "common", "uncommon", "rare", "epic", "legendary", "mythic"
	var spawn_weight: int  # вес для случайного выбора
	var min_level: int
	var max_level: int
	
	func _init(scene: String = "", rarity_type: String = "common", weight: int = 100, min_lvl: int = 1, max_lvl: int = 1):
		enemy_scene = scene
		rarity = rarity_type
		spawn_weight = weight
		min_level = min_lvl
		max_level = max_lvl

var locations: Dictionary = {}
var current_location
var player_level: int = 1
var location_order: Array[String] = ["test_arena", "dungeon", "forest", "cemetery", "sinister_swamps", "demon_lair"]  # Порядок прохождения локаций

signal location_changed(location)

func _ready():
	_initialize_locations()

func _initialize_locations():
	# Тестовая арена (для тестирования боев) - создаем первой
	var test_arena = LocationData.new()
	test_arena.location_id = "test_arena"
	test_arena.location_name = "Тестовая арена"
	test_arena.description = "Специальная арена для тестирования боев с любыми врагами. Здесь можно сражаться бесконечно и выбирать противников."
	test_arena.min_level = 1
	test_arena.max_level = 50
	test_arena.is_unlocked = true  # Всегда доступна
	test_arena.boss_enemy = "TestBoss"
	test_arena.exp_reward = 0  # Не даем опыт в тестовой арене
	test_arena.gold_reward = 0  # Не даем золото в тестовой арене
	
	# Добавляем всех врагов для тестирования
	test_arena.enemy_pools = [
		# Обычные враги
		EnemyPool.new("res://Scenes/Battle/Enemy_Rat.tscn", "common", 100, 1, 50),
		EnemyPool.new("res://Scenes/Battle/Enemy_Bat.tscn", "common", 100, 1, 50),
		EnemyPool.new("res://Scenes/Battle/Enemy_Slime.tscn", "common", 100, 1, 50),
		EnemyPool.new("res://Scenes/Battle/Enemy_RottenSlime.tscn", "common", 100, 1, 50),
		
		# Демоны
		EnemyPool.new("res://Scenes/Battle/Enemy_AlkaraDemon.tscn", "uncommon", 100, 1, 50),
		EnemyPool.new("res://Scenes/Battle/Enemy_CurseDemon.tscn", "uncommon", 100, 1, 50),
		EnemyPool.new("res://Scenes/Battle/Enemy_ExecutionerDemon.tscn", "rare", 100, 1, 50),
		EnemyPool.new("res://Scenes/Battle/Enemy_TharnokDemon.tscn", "rare", 100, 1, 50),
		
		# Гоблины
		EnemyPool.new("res://Scenes/Battle/Enemy_Goblin.tscn", "common", 100, 1, 50),
		EnemyPool.new("res://Scenes/Battle/Enemy_GoblinWarrior.tscn", "common", 100, 1, 50),
		EnemyPool.new("res://Scenes/Battle/Enemy_GoblinThief.tscn", "uncommon", 100, 1, 50),
		EnemyPool.new("res://Scenes/Battle/Enemy_GoblinMage.tscn", "uncommon", 100, 1, 50),
		
		# Боссы
		EnemyPool.new("res://Scenes/Battle/Enemy_DarkStalker.tscn", "epic", 100, 1, 50),
		EnemyPool.new("res://Scenes/Battle/Enemy_TharnokDemon.tscn", "legendary", 100, 1, 50)
	]
	
	# Подземелье под городом (1-3 уровни)
	var dungeon = LocationData.new()
	dungeon.location_id = "dungeon"
	dungeon.location_name = "Подземелье под городом"
	dungeon.description = "Тёмные туннели под старым городом, кишащие грызунами и слизнями."
	dungeon.min_level = 1
	dungeon.max_level = 3
	dungeon.is_unlocked = true  # Первая локация всегда открыта
	dungeon.boss_enemy = "RottenSlime"
	dungeon.exp_reward = 50
	dungeon.gold_reward = 25
	
	# Добавляем врагов для подземелья
	dungeon.enemy_pools = [
		EnemyPool.new("res://Scenes/Battle/Enemy_Rat.tscn", "common", 40, 1, 2),
		EnemyPool.new("res://Scenes/Battle/Enemy_Bat.tscn", "common", 25, 2, 3),
		EnemyPool.new("res://Scenes/Battle/Enemy_Slime.tscn", "common", 30, 1, 3)
	]
	
	# Лес (3-7 уровни)
	var forest = LocationData.new()
	forest.location_id = "forest"
	forest.location_name = "Лес гоблинов"
	forest.description = "Густой лес, где обитают гоблины и опасные хищники."
	forest.min_level = 3
	forest.max_level = 7
	forest.is_unlocked = false
	forest.required_previous_location = "dungeon"
	forest.boss_enemy = "DarkStalker"
	forest.exp_reward = 150
	forest.gold_reward = 75
	
	forest.enemy_pools = [
		EnemyPool.new("res://Scenes/Battle/Enemy_GoblinWarrior.tscn", "common", 25, 3, 5),
		EnemyPool.new("res://Scenes/Battle/Enemy_GoblinThief.tscn", "common", 25, 4, 6),
		EnemyPool.new("res://Scenes/Battle/Enemy_GoblinMage.tscn", "common", 25, 5, 7),
		EnemyPool.new("res://Scenes/Battle/Enemy_GoblinWarrior.tscn", "uncommon", 10, 5, 7),
		EnemyPool.new("res://Scenes/Battle/Enemy_GoblinThief.tscn", "uncommon", 10, 5, 7),
		EnemyPool.new("res://Scenes/Battle/Enemy_GoblinMage.tscn", "uncommon", 10, 6, 8)
	]
	
	# Заброшенное кладбище (8-15 уровни) - ИСПРАВЛЕННАЯ ВЕРСИЯ СО СКЕЛЕТАМИ
	var cemetery = LocationData.new()
	cemetery.location_id = "cemetery"
	cemetery.location_name = "Заброшенное кладбище"
	cemetery.description = "Забытое кладбище, где обитают мертвецы и нежить."
	cemetery.min_level = 8
	cemetery.max_level = 15
	cemetery.is_unlocked = false
	cemetery.required_previous_location = "forest"
	cemetery.boss_enemy = "SkeletonLord"  # Босс локации - Скелет лорд
	cemetery.exp_reward = 300
	cemetery.gold_reward = 150
	
	# Добавляем врагов для заброшенного кладбища (НЕЖИТЬ - СКЕЛЕТЫ)
	cemetery.enemy_pools = [
		EnemyPool.new("res://Scenes/Battle/Enemy_SkeletonSwordsman.tscn", "common", 25, 8, 10),
		EnemyPool.new("res://Scenes/Battle/Enemy_SkeletonCrossbowman.tscn", "uncommon", 22, 9, 11),
		EnemyPool.new("res://Scenes/Battle/Enemy_Ghoul.tscn", "rare", 18, 10, 12),
		EnemyPool.new("res://Scenes/Battle/Enemy_EliteSkeleton.tscn", "epic", 12, 11, 13),
		EnemyPool.new("res://Scenes/Battle/Enemy_EliteSkeleton.tscn", "legendary", 8, 12, 14),
		EnemyPool.new("res://Scenes/Battle/Enemy_SkeletonSwordsman.tscn", "uncommon", 15, 8, 11)
	]
	
	# Заглушки для остальных локаций
	_add_placeholder_locations()
	
	# Сохраняем локации (тестовая арена сохраняется последней, чтобы не перезаписаться)
	locations["dungeon"] = dungeon
	locations["forest"] = forest
	locations["cemetery"] = cemetery
	locations["test_arena"] = test_arena
	
	# Принудительно разблокируем тестовую арену
	if "test_arena" in locations:
		locations["test_arena"].is_unlocked = true

func _add_placeholder_locations():
	var placeholder_locations = [
		{"id": "sinister_swamps", "name": "Туманные болота", "desc": "Много веков орки живут на этих болотах.", "min": 10, "max": 15, "prev": "cemetery"},
		{"id": "dark_forest", "name": "Гиблый лес", "desc": "Опасный лес, где скрываются разбойники и головорезы", "min": 8, "max": 12, "prev": "sinister_swamps"},
		{"id": "mysterious_wastelands", "name": "Древняя пещера", "desc": "Мало кто вернулся из вошедших.", "min": 12, "max": 18, "prev": "dark_forest"},
		{"id": "volcanic_valley", "name": "Вулканическая долина", "desc": "Раскалённая долина у подножия вулкана", "min": 15, "max": 20, "prev": "mysterious_wastelands"},
		{"id": "bandit_camp", "name": "Лагерь бандитов", "desc": "Укреплённый лагерь разбойников", "min": 18, "max": 25, "prev": "volcanic_valley"},
		{"id": "demon_lair", "name": "Демоническое логово", "desc": "Логово демонов из преисподней", "min": 20, "max": 30, "prev": "bandit_camp"},
		{"id": "angel_halls", "name": "Чертоги ангелов", "desc": "Небесные чертоги божественных существ", "min": 25, "max": 40, "prev": "demon_lair"}
	]
	
	for loc_data in placeholder_locations:
		var location = LocationData.new()
		location.location_id = loc_data.id
		location.location_name = loc_data.name
		location.description = loc_data.desc
		location.min_level = loc_data.min
		location.max_level = loc_data.max
		location.is_unlocked = false
		location.required_previous_location = loc_data.prev
		location.boss_enemy = "Boss_" + loc_data.id
		location.exp_reward = loc_data.min * 20
		location.gold_reward = loc_data.min * 10
		
		# Добавляем врагов для локации
		if loc_data.id == "sinister_swamps":
			# Туманные болота - орки
			location.enemy_pools = [
				EnemyPool.new("res://Scenes/Battle/Enemy_OrcArcher.tscn", "common", 30, 10, 12),
				EnemyPool.new("res://Scenes/Battle/Enemy_OrcAssassin.tscn", "common", 25, 10, 12),
				EnemyPool.new("res://Scenes/Battle/Enemy_OrcBerserker.tscn", "common", 20, 11, 13),
				EnemyPool.new("res://Scenes/Battle/Enemy_OrcShaman.tscn", "common", 15, 11, 13),
				EnemyPool.new("res://Scenes/Battle/Enemy_OrcArcher.tscn", "uncommon", 25, 12, 13),
				EnemyPool.new("res://Scenes/Battle/Enemy_OrcAssassin.tscn", "uncommon", 20, 12, 14),
				EnemyPool.new("res://Scenes/Battle/Enemy_OrcBerserker.tscn", "uncommon", 18, 13, 14),
				EnemyPool.new("res://Scenes/Battle/Enemy_OrcShaman.tscn", "uncommon", 15, 13, 14),
				EnemyPool.new("res://Scenes/Battle/Enemy_OrcArcher.tscn", "rare", 20, 13, 14),
				EnemyPool.new("res://Scenes/Battle/Enemy_OrcAssassin.tscn", "rare", 18, 13, 15),
				EnemyPool.new("res://Scenes/Battle/Enemy_OrcBerserker.tscn", "rare", 15, 14, 15),
				EnemyPool.new("res://Scenes/Battle/Enemy_OrcShaman.tscn", "rare", 12, 14, 15),
				EnemyPool.new("res://Scenes/Battle/Enemy_OrcBerserker.tscn", "epic", 10, 14, 15),
				EnemyPool.new("res://Scenes/Battle/Enemy_OrcShaman.tscn", "epic", 8, 14, 15),
				EnemyPool.new("res://Scenes/Battle/Enemy_OrcShaman.tscn", "legendary", 5, 15, 15)
			]
		else:
			# Добавляем заглушки врагов для остальных локаций
			location.enemy_pools = [
			EnemyPool.new("res://Scenes/Battle/Enemy_Placeholder.tscn", "common", 50, loc_data.min, loc_data.max),
			EnemyPool.new("res://Scenes/Battle/Enemy_Placeholder.tscn", "uncommon", 30, loc_data.min + 1, loc_data.max),
			EnemyPool.new("res://Scenes/Battle/Enemy_Placeholder.tscn", "rare", 15, loc_data.min + 2, loc_data.max),
			EnemyPool.new("res://Scenes/Battle/Enemy_Placeholder.tscn", "epic", 4, loc_data.min + 3, loc_data.max),
			EnemyPool.new("res://Scenes/Battle/Enemy_Placeholder.tscn", "legendary", 1, loc_data.max, loc_data.max)
		]
		
		# Не перезаписываем тестовую арену
		if loc_data.id != "test_arena":
			locations[loc_data.id] = location
		else:
			print("Пропускаем перезапись тестовой арены в _add_placeholder_locations()")
	
	# Специальная обработка для Демонической цитадели - добавляем демонов
	# Система выбирает врага из пула по редкости комнаты
	if "demon_lair" in locations:
		var demon_lair = locations["demon_lair"]
		demon_lair.enemy_pools = [
			# Common (20-24 уровни)
			EnemyPool.new("res://Scenes/Battle/Enemy_AlkaraDemon.tscn", "common", 35, 20, 24),
			EnemyPool.new("res://Scenes/Battle/Enemy_CurseDemon.tscn", "common", 30, 20, 24),
			EnemyPool.new("res://Scenes/Battle/Enemy_ExecutionerDemon.tscn", "common", 25, 21, 24),
			EnemyPool.new("res://Scenes/Battle/Enemy_TharnokDemon.tscn", "common", 20, 22, 24),
			# Uncommon (23-27 уровни)
			EnemyPool.new("res://Scenes/Battle/Enemy_AlkaraDemon.tscn", "uncommon", 30, 23, 27),
			EnemyPool.new("res://Scenes/Battle/Enemy_CurseDemon.tscn", "uncommon", 25, 24, 27),
			EnemyPool.new("res://Scenes/Battle/Enemy_ExecutionerDemon.tscn", "uncommon", 20, 25, 27),
			EnemyPool.new("res://Scenes/Battle/Enemy_TharnokDemon.tscn", "uncommon", 15, 26, 27),
			# Rare (26-30 уровни)
			EnemyPool.new("res://Scenes/Battle/Enemy_AlkaraDemon.tscn", "rare", 20, 26, 29),
			EnemyPool.new("res://Scenes/Battle/Enemy_CurseDemon.tscn", "rare", 18, 27, 29),
			EnemyPool.new("res://Scenes/Battle/Enemy_ExecutionerDemon.tscn", "rare", 15, 28, 30),
			EnemyPool.new("res://Scenes/Battle/Enemy_TharnokDemon.tscn", "rare", 12, 28, 30),
			# Epic (28-30 уровни)
			EnemyPool.new("res://Scenes/Battle/Enemy_ExecutionerDemon.tscn", "epic", 10, 28, 30),
			EnemyPool.new("res://Scenes/Battle/Enemy_TharnokDemon.tscn", "epic", 8, 29, 30),
			# Legendary (30 уровень)
			EnemyPool.new("res://Scenes/Battle/Enemy_TharnokDemon.tscn", "legendary", 5, 30, 30)
		]

func get_location(location_id: String):
	return locations.get(location_id, null)

func get_available_locations() -> Array[LocationData]:
	# Возвращает список доступных локаций
	var available: Array[LocationData] = []
	
	for location in locations.values():
		if location.is_unlocked:
			available.append(location)
	
	return available

func unlock_location(location_id: String):
	if location_id in locations:
		locations[location_id].is_unlocked = true
		emit_signal("location_changed", locations[location_id])

func set_current_location(location_id: String):
	if location_id in locations:
		current_location = locations[location_id]
		emit_signal("location_changed", current_location)

func get_current_location_id() -> String:
	"""Возвращает ID текущей локации"""
	if current_location:
		return current_location.location_id
	return ""

func get_random_enemy_for_location() -> String:
	if not current_location:
		return ""
	
	var total_weight = 0
	for pool in current_location.enemy_pools:
		total_weight += pool.spawn_weight
	
	if total_weight == 0:
		return ""
	
	var random_roll = randi() % total_weight
	var current_weight = 0
	
	for pool in current_location.enemy_pools:
		current_weight += pool.spawn_weight
		if random_roll < current_weight:
			return pool.enemy_scene
	
	# Fallback
	return current_location.enemy_pools[0].enemy_scene

func get_enemy_rarity_for_scene(scene_path: String) -> String:
	if not current_location:
		return "common"
	
	for pool in current_location.enemy_pools:
		if pool.enemy_scene == scene_path:
			return pool.rarity
	
	return "common"

func check_location_progression():
	# Проверяем, какие локации можно разблокировать
	for location in locations.values():
		if not location.is_unlocked and location.required_previous_location != "":
			var prev_location = locations.get(location.required_previous_location)
			if prev_location and prev_location.is_unlocked:
				# Проверяем, прошёл ли игрок предыдущую локацию
				# Пока что просто разблокируем следующую локацию
				unlock_location(location.location_id)

func unlock_next_location_after_boss(current_location_id: String) -> String:
	"""Разблокирует следующую локацию после победы над боссом текущей локации"""
	if not current_location_id in locations:
		return ""
	
	# Ищем локацию, которая требует текущую как предыдущую
	for location in locations.values():
		if location.required_previous_location == current_location_id and not location.is_unlocked:
			unlock_location(location.location_id)
			return location.location_name
	
	return ""

func get_next_location(location) -> LocationData:
	# Возвращает следующую локацию в порядке прохождения
	if not location:
		return null
	
	var current_index = location_order.find(location.location_id)
	if current_index >= 0 and current_index < location_order.size() - 1:
		var next_location_id = location_order[current_index + 1]
		return locations.get(next_location_id)
	
	return null

# res://Scripts/LocationManager.gd
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
var current_location: LocationData
var player_level: int = 1

signal location_changed(location: LocationData)

func _ready():
	_initialize_locations()

func _initialize_locations():
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
	cemetery.boss_enemy = "RottenSlime"  # Для теста используем того же босса
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
	
	# Сохраняем локации
	locations["dungeon"] = dungeon
	locations["forest"] = forest
	locations["cemetery"] = cemetery

func _add_placeholder_locations():
	var placeholder_locations = [
		{"id": "sinister_swamps", "name": "Туманные болота", "desc": "Много веков орки живут на этих болотах.", "min": 10, "max": 15, "prev": "cemetery"},
		{"id": "mysterious_wastelands", "name": "Древняя пещера", "desc": "Мало кто вернулся из вошедших.", "min": 12, "max": 18, "prev": "sinister_swamps"},
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
		
		# Добавляем заглушки врагов
		location.enemy_pools = [
			EnemyPool.new("res://Scenes/Battle/Enemy_Placeholder.tscn", "common", 50, loc_data.min, loc_data.max),
			EnemyPool.new("res://Scenes/Battle/Enemy_Placeholder.tscn", "uncommon", 30, loc_data.min + 1, loc_data.max),
			EnemyPool.new("res://Scenes/Battle/Enemy_Placeholder.tscn", "rare", 15, loc_data.min + 2, loc_data.max),
			EnemyPool.new("res://Scenes/Battle/Enemy_Placeholder.tscn", "epic", 4, loc_data.min + 3, loc_data.max),
			EnemyPool.new("res://Scenes/Battle/Enemy_Placeholder.tscn", "legendary", 1, loc_data.max, loc_data.max)
		]
		
		locations[loc_data.id] = location

func get_location(location_id: String) -> LocationData:
	return locations.get(location_id, null)

func get_available_locations() -> Array[LocationData]:
	var available: Array[LocationData] = []
	for location in locations.values():
		if location.is_unlocked:
			available.append(location)
	return available

func unlock_location(location_id: String):
	if location_id in locations:
		locations[location_id].is_unlocked = true
		print("Локация разблокирована: ", locations[location_id].location_name)

func set_current_location(location_id: String):
	if location_id in locations:
		current_location = locations[location_id]
		emit_signal("location_changed", current_location)
		print("Текущая локация: ", current_location.location_name)

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

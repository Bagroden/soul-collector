# Scripts/Systems/AbilityLearningSystem_New.gd
extends Node

signal ability_learned(ability_id: String, progress: int)
signal progress_updated(ability_id: String, progress: int)

# Конфигурация изучения способностей
var ability_learning_config = {}
# Текущий прогресс изучения
var learning_progress = {}

func _ready():
	_initialize_learning_config()
	_load_progress()

func _initialize_learning_config():
	"""Инициализация конфигурации изучения способностей"""
	ability_learning_config = {
		"rat_vitality": {
			"name": "Крысиная живучесть",
			"required_progress": [100, 500, 1000],  # Прогресс для каждого уровня
			"required_soul_shards": [100, 1000, 10000],  # Осколки душ для каждого уровня
			"sources": {
				"common_rat": 10,      # 10 очков за обычную крысу
				"uncommon_rat": 20,    # 20 очков за необычную крысу
				"rare_rat": 30,        # 30 очков за редкую крысу
				"epic_rat": 30,        # 30 очков за эпическую крысу
				"legendary_rat": 30   # 30 очков за легендарную крысу
			}
		},
		"dodge": {
			"name": "Уворот",
			"required_progress": [100, 500, 1000],  # Прогресс для каждого уровня
			"required_soul_shards": [100, 1000, 10000],  # Осколки душ для каждого уровня
			"sources": {
				"uncommon_rat": 10,   # 10 очков за необычную крысу
				"rare_rat": 20,        # 20 очков за редкую крысу
				"epic_rat": 30,        # 30 очков за эпическую крысу
				"legendary_rat": 30   # 30 очков за легендарную крысу
			}
		},
		"blood_flow": {
			"name": "Кровоток",
			"required_progress": [100, 500, 1000],  # Прогресс для каждого уровня
			"required_soul_shards": [100, 1000, 10000],  # Осколки душ для каждого уровня
			"sources": {
				"rare_rat": 10,        # 10 очков за редкую крысу
				"epic_rat": 20,        # 20 очков за эпическую крысу
				"legendary_rat": 30    # 30 очков за легендарную крысу
			}
		},
		"agility": {
			"name": "Изворотливость",
			"required_progress": [100, 500, 1000],  # Прогресс для каждого уровня
			"required_soul_shards": [100, 1000, 10000],  # Осколки душ для каждого уровня
			"sources": {
				"epic_rat": 10,        # 10 очков за эпическую крысу
				"legendary_rat": 20    # 20 очков за легендарную крысу
			}
		},
		"slime_armor": {
			"name": "Слизистая броня",
			"required_progress": [100, 500, 1000],  # Прогресс для каждого уровня
			"required_soul_shards": [100, 1000, 10000],  # Осколки душ для каждого уровня
			"sources": {
				"common_slime": 10,      # 10 очков за обычного слизня
				"uncommon_slime": 20,    # 20 очков за необычного слизня
				"rare_slime": 30,        # 30 очков за редкого слизня
				"epic_slime": 30,        # 30 очков за эпического слизня
				"legendary_slime": 30   # 30 очков за легендарного слизня
			}
		},
		"acid_hits": {
			"name": "Кислотные удары",
			"required_progress": [100, 500, 1000],  # Прогресс для каждого уровня
			"required_soul_shards": [100, 1000, 10000],  # Осколки душ для каждого уровня
			"sources": {
				"uncommon_slime": 10,   # 10 очков за необычного слизня
				"rare_slime": 20,        # 20 очков за редкого слизня
				"epic_slime": 30,        # 30 очков за эпического слизня
				"legendary_slime": 30   # 30 очков за легендарного слизня
			}
		},
		"slime_regeneration": {
			"name": "Регенерация слизи",
			"required_progress": [100, 500, 1000],  # Прогресс для каждого уровня
			"required_soul_shards": [100, 1000, 10000],  # Осколки душ для каждого уровня
			"sources": {
				"rare_slime": 10,        # 10 очков за редкого слизня
				"epic_slime": 20,        # 20 очков за эпического слизня
				"legendary_slime": 30   # 30 очков за легендарного слизня
			}
		},
		"slime_vitality": {
			"name": "Живучесть слизня",
			"required_progress": [100, 500, 1000],  # Прогресс для каждого уровня
			"required_soul_shards": [100, 1000, 10000],  # Осколки душ для каждого уровня
			"sources": {
				"epic_slime": 10,        # 10 очков за эпического слизня
				"legendary_slime": 20   # 20 очков за легендарного слизня
			}
		},
		"massive": {
			"name": "Массивность",
			"required_progress": [100, 500, 1000],  # Прогресс для каждого уровня
			"required_soul_shards": [100, 1000, 10000],  # Осколки душ для каждого уровня
			"sources": {
				"legendary_slime": 10   # 10 очков за легендарного слизня
			}
		},
		"rotten_aura": {
			"name": "Гнилостная аура",
			"required_progress": [100, 500, 1000],  # Прогресс для каждого уровня
			"required_soul_shards": [100, 1000, 10000],  # Осколки душ для каждого уровня
			"sources": {
				"boss_rotten_slime": 30   # 30 очков за босса гнилого слизня
			}
		}
	}

func add_progress(ability_id: String, progress_gain: int):
	"""Добавляет прогресс к способности"""
	if ability_id in ability_learning_config:
		if not ability_id in learning_progress:
			learning_progress[ability_id] = {
				"current_progress": 0,
				"current_level": 0,
				"is_learned": false,
				"learned_at": ""
			}
		
		var progress = learning_progress[ability_id]
		progress.current_progress += progress_gain
		
		# Отправляем сигнал об обновлении прогресса
		progress_updated.emit(ability_id, progress.current_progress)
		
		# Сохраняем прогресс
		_save_progress()

func learn_ability(ability_id: String, level: int) -> bool:
	"""Изучает способность определенного уровня"""
	if not ability_id in ability_learning_config:
		print("❌ ОШИБКА: Способность %s не найдена в конфигурации!" % ability_id)
		return false
	
	var config = ability_learning_config[ability_id]
	var progress = learning_progress.get(ability_id, {
		"current_progress": 0,
		"current_level": 0,
		"is_learned": false,
		"learned_at": ""
	})
	
	# Проверяем, что уровень доступен для изучения
	if level < 1 or level > 3:
		print("❌ ОШИБКА: Неверный уровень способности %d!" % level)
		return false
	
	# Проверяем требования прогресса
	var required_progress = config.required_progress[level - 1]
	if progress.current_progress < required_progress:
		print("❌ Недостаточно прогресса для изучения %s уровня %d (нужно: %d, есть: %d)" % [config.name, level, required_progress, progress.current_progress])
		return false
	
	# Проверяем требования осколков душ
	var required_soul_shards = config.required_soul_shards[level - 1]
	if not SoulShardManager.has_enough_soul_shards(required_soul_shards):
		print("❌ Недостаточно осколков душ для изучения %s уровня %d (нужно: %d, есть: %d)" % [config.name, level, required_soul_shards, SoulShardManager.soul_shards])
		return false
	
	# Изучаем способность
	progress.current_level = level
	progress.is_learned = true
	progress.learned_at = Time.get_datetime_string_from_system()
	
	# Списываем осколки душ
	SoulShardManager.spend_soul_shards(required_soul_shards)
	
	# Списываем прогресс
	progress.current_progress -= required_progress
	
	learning_progress[ability_id] = progress
	
	print("🎉 СПОСОБНОСТЬ ИЗУЧЕНА: %s (уровень %d)" % [config.name, level])
	print("💰 Потрачено: %d осколков душ, %d очков прогресса" % [required_soul_shards, required_progress])
	print("📊 Осталось прогресса: %d" % progress.current_progress)
	
	# Отправляем сигнал
	ability_learned.emit(ability_id, progress.current_progress)
	
	# Сохраняем прогресс
	_save_progress()
	
	return true

func get_ability_progress(ability_id: String) -> Dictionary:
	"""Возвращает прогресс изучения способности"""
	if ability_id in learning_progress:
		return learning_progress[ability_id]
	else:
		return {
			"current_progress": 0,
			"current_level": 0,
			"is_learned": false,
			"learned_at": ""
		}

func is_ability_learned(ability_id: String) -> bool:
	"""Проверяет, изучена ли способность"""
	if ability_id in learning_progress:
		return learning_progress[ability_id].is_learned
	return false

func get_ability_level(ability_id: String) -> int:
	"""Возвращает текущий уровень способности"""
	if ability_id in learning_progress:
		return learning_progress[ability_id].current_level
	return 0

func can_learn_ability(ability_id: String, level: int) -> Dictionary:
	"""Проверяет, можно ли изучить способность определенного уровня"""
	var result = {
		"can_learn": false,
		"reason": "",
		"required_progress": 0,
		"required_soul_shards": 0,
		"current_progress": 0,
		"current_soul_shards": 0
	}
	
	if not ability_id in ability_learning_config:
		result.reason = "Способность не найдена"
		return result
	
	var config = ability_learning_config[ability_id]
	var progress = get_ability_progress(ability_id)
	
	if level < 1 or level > 3:
		result.reason = "Неверный уровень"
		return result
	
	var required_progress = config.required_progress[level - 1]
	var required_soul_shards = config.required_soul_shards[level - 1]
	
	result.required_progress = required_progress
	result.required_soul_shards = required_soul_shards
	result.current_progress = progress.current_progress
	result.current_soul_shards = SoulShardManager.soul_shards
	
	if progress.current_progress < required_progress:
		result.reason = "Недостаточно прогресса"
		return result
	
	if SoulShardManager.soul_shards < required_soul_shards:
		result.reason = "Недостаточно осколков душ"
		return result
	
	result.can_learn = true
	result.reason = "Можно изучить"
	return result

func _save_progress():
	"""Сохраняет прогресс изучения способностей"""
	var save_data = {
		"learning_progress": learning_progress,
		"save_time": Time.get_datetime_string_from_system()
	}
	
	var file = FileAccess.open("user://ability_learning_progress.save", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("💾 Прогресс изучения способностей сохранен")
	else:
		print("❌ ОШИБКА: Не удалось сохранить прогресс изучения способностей!")

func _load_progress():
	"""Загружает прогресс изучения способностей"""
	if FileAccess.file_exists("user://ability_learning_progress.save"):
		var file = FileAccess.open("user://ability_learning_progress.save", FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			
			if parse_result == OK:
				var save_data = json.data
				learning_progress = save_data.get("learning_progress", {})
				print("📂 Прогресс изучения способностей загружен")
			else:
				print("❌ ОШИБКА: Не удалось загрузить прогресс изучения способностей!")
				learning_progress = {}
	else:
		print("📂 Файл прогресса изучения способностей не найден, начинаем с нуля")
		learning_progress = {}

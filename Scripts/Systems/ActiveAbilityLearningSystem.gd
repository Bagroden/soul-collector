# res://Scripts/Systems/ActiveAbilityLearningSystem.gd
extends Node

## Система изучения активных способностей врагов
## Игрок может изучать способности врагов, побеждая их в бою

# Сигналы
signal ability_learned(ability_id: String, ability_name: String)
signal progress_updated(ability_id: String, current_progress: int, required_progress: int)

# Прогресс изучения способностей
var learning_progress: Dictionary = {}  # {ability_id: {current_progress, is_learned, learned_at}}

# Путь к файлу сохранения
const SAVE_FILE_PATH = "user://active_ability_learning.save"

# Конфигурация изучения активных способностей
var learning_config = {
	# === КРЫСА ===
	"rat_bite": {
		"ability_name": "Крысиный укус",
		"ability_id": "rat_bite",
		"rarity": "common",
		"required_progress": 100,
		"enemy_type": "rat",
		"enemy_display_name": "Крыса",
		"damage_type": "physical",
		"description": "Быстрая атака с шансом кровотечения",
		"sources": {
			"common": 10,
			"uncommon": 15,
			"rare": 20,
			"epic": 25,
			"legendary": 30
		}
	},
	
	# === СЛИЗЕНЬ ===
	"slime_acid_blast": {
		"ability_name": "Кислотный взрыв",
		"ability_id": "slime_acid_blast",
		"rarity": "uncommon",
		"required_progress": 100,
		"enemy_type": "slime",
		"enemy_display_name": "Слизень",
		"damage_type": "physical",
		"description": "Кислотная атака, снижающая броню",
		"sources": {
			"uncommon": 10,
			"rare": 15,
			"epic": 20,
			"legendary": 25
		}
	},
	
	# === ГНИЛОЙ СЛИЗЕНЬ ===
	"rotten_slime_blast": {
		"ability_name": "Гнилостный взрыв",
		"ability_id": "rotten_slime_blast",
		"rarity": "rare",
		"required_progress": 100,
		"enemy_type": "rotten_slime",
		"enemy_display_name": "Гнилой слизень",
		"damage_type": "physical",
		"description": "Атака с гнилью, вызывающая ауру",
		"sources": {
			"rare": 10,
			"epic": 15,
			"legendary": 20
		}
	},
	
	# === ЛЕТУЧАЯ МЫШЬ ===
	"bat_swoop": {
		"ability_name": "Пикирование",
		"ability_id": "bat_swoop",
		"rarity": "common",
		"required_progress": 100,
		"enemy_type": "bat",
		"enemy_display_name": "Летучая мышь",
		"damage_type": "physical",
		"description": "Быстрая атака с шансом оглушения",
		"sources": {
			"common": 10,
			"uncommon": 15,
			"rare": 20,
			"epic": 25,
			"legendary": 30
		}
	},
	
	# === ГОБЛИН ВОИН ===
	"double_strike": {
		"ability_name": "Двойной удар",
		"ability_id": "double_strike",
		"rarity": "uncommon",
		"required_progress": 100,
		"enemy_type": "goblin_warrior",
		"enemy_display_name": "Гоблин воин",
		"damage_type": "physical",
		"description": "Два быстрых удара",
		"sources": {
			"uncommon": 10,
			"rare": 15,
			"epic": 20,
			"legendary": 25
		}
	},
	
	# === ГОБЛИН ВОР ===
	"poison_strike": {
		"ability_name": "Ядовитый удар",
		"ability_id": "poison_strike",
		"rarity": "rare",
		"required_progress": 100,
		"enemy_type": "goblin_thief",
		"enemy_display_name": "Гоблин вор",
		"damage_type": "poison",
		"description": "Ядовитая атака с наложением стаков яда",
		"sources": {
			"rare": 10,
			"epic": 15,
			"legendary": 20
		}
	},
	
	# === ГОБЛИН КОЛДУН ===
	"magic_arrows": {
		"ability_name": "Магические стрелы",
		"ability_id": "magic_arrows",
		"rarity": "rare",
		"required_progress": 100,
		"enemy_type": "goblin_mage",
		"enemy_display_name": "Гоблин колдун",
		"damage_type": "magic",
		"description": "Выпускает множество магических стрел",
		"sources": {
			"rare": 10,
			"epic": 15,
			"legendary": 20
		}
	},
	
	# === СКЕЛЕТ АРБАЛЕТЧИК ===
	"crossbow_shot": {
		"ability_name": "Арбалетный выстрел",
		"ability_id": "crossbow_shot",
		"rarity": "uncommon",
		"required_progress": 100,
		"enemy_type": "skeleton_crossbowman",
		"enemy_display_name": "Скелет арбалетчик",
		"damage_type": "physical",
		"description": "Точный выстрел с бонусом к криту",
		"sources": {
			"uncommon": 10,
			"rare": 15,
			"epic": 20,
			"legendary": 25
		}
	},
	
	# === СКЕЛЕТ МЕЧНИК ===
	"slashing_strike": {
		"ability_name": "Рубящий удар",
		"ability_id": "slashing_strike",
		"rarity": "common",
		"required_progress": 100,
		"enemy_type": "skeleton_swordsman",
		"enemy_display_name": "Скелет мечник",
		"damage_type": "physical",
		"description": "Быстрая атака мечом",
		"sources": {
			"common": 10,
			"uncommon": 15,
			"rare": 20,
			"epic": 25,
			"legendary": 30
		}
	},
	
	# === ГУЛЬ ===
	"tombstone": {
		"ability_name": "Надгробие",
		"ability_id": "tombstone",
		"rarity": "epic",
		"required_progress": 100,
		"enemy_type": "ghoul",
		"enemy_display_name": "Гуль",
		"damage_type": "magic",
		"description": "Массовая магическая атака с параличом",
		"sources": {
			"epic": 10,
			"legendary": 15
		}
	},
	
	# === ЭЛИТНЫЙ СКЕЛЕТ ===
	"crushing_hammer": {
		"ability_name": "Сокрушительный молот",
		"ability_id": "crushing_hammer",
		"rarity": "epic",
		"required_progress": 100,
		"enemy_type": "elite_skeleton",
		"enemy_display_name": "Элитный скелет",
		"damage_type": "physical",
		"description": "Два удара молотом с оглушением",
		"sources": {
			"epic": 10,
			"legendary": 15
		}
	},
	
	# === ОРК ЛУЧНИК ===
	"orc_arrow_shot": {
		"ability_name": "Точный выстрел",
		"ability_id": "orc_arrow_shot",
		"rarity": "uncommon",
		"required_progress": 100,
		"enemy_type": "orc_archer",
		"enemy_display_name": "Орк лучник",
		"damage_type": "physical",
		"description": "Точный выстрел из лука",
		"sources": {
			"uncommon": 10,
			"rare": 15,
			"epic": 20,
			"legendary": 25
		}
	},
	
	# === ОРК УБИЙЦА ===
	"orc_backstab": {
		"ability_name": "Удар в спину",
		"ability_id": "orc_backstab",
		"rarity": "rare",
		"required_progress": 100,
		"enemy_type": "orc_assassin",
		"enemy_display_name": "Орк убийца",
		"damage_type": "physical",
		"description": "Скрытая атака с увеличенным уроном",
		"sources": {
			"rare": 10,
			"epic": 15,
			"legendary": 20
		}
	},
	
	# === ОРК БЕРСЕРК ===
	"orc_berserker_strike": {
		"ability_name": "Яростный удар",
		"ability_id": "orc_berserker_strike",
		"rarity": "epic",
		"required_progress": 100,
		"enemy_type": "orc_berserker",
		"enemy_display_name": "Орк берсерк",
		"damage_type": "physical",
		"description": "Мощная атака с яростью",
		"sources": {
			"epic": 10,
			"legendary": 15
		}
	},
	
	# === ОРК ШАМАН ===
	"orc_spirit_blast": {
		"ability_name": "Духовный взрыв",
		"ability_id": "orc_spirit_blast",
		"rarity": "rare",
		"required_progress": 100,
		"enemy_type": "orc_shaman",
		"enemy_display_name": "Орк шаман",
		"damage_type": "magic",
		"description": "Магическая атака духов",
		"sources": {
			"rare": 10,
			"epic": 15,
			"legendary": 20
		}
	},
	
	# === ТЁМНЫЙ ШАТУН ===
	"shadow_spikes": {
		"ability_name": "Теневые шипы",
		"ability_id": "shadow_spikes",
		"rarity": "legendary",
		"required_progress": 100,
		"enemy_type": "dark_stalker",
		"enemy_display_name": "Тёмный шатун",
		"damage_type": "shadow",
		"description": "Шипы из тени с автокритом при невидимости",
		"sources": {
			"legendary": 10
		}
	},
	
	# === ДЕМОН АЛКАРА ===
	"alkara_dark_blast": {
		"ability_name": "Темный взрыв",
		"ability_id": "alkara_dark_blast",
		"rarity": "epic",
		"required_progress": 100,
		"enemy_type": "alkara_demon",
		"enemy_display_name": "Демон Алкара",
		"damage_type": "magic",
		"description": "Мощная магическая атака с вампиризмом",
		"sources": {
			"epic": 10,
			"legendary": 15
		}
	},
	
	# === ДЕМОН ПРОКЛЯТИЯ ===
	"curse_blast": {
		"ability_name": "Проклятый взрыв",
		"ability_id": "curse_blast",
		"rarity": "rare",
		"required_progress": 100,
		"enemy_type": "curse_demon",
		"enemy_display_name": "Демон проклятия",
		"damage_type": "magic",
		"description": "Магическая атака с проклятием",
		"sources": {
			"rare": 10,
			"epic": 15,
			"legendary": 20
		}
	},
	
	# === ДЕМОН ПАЛАЧ ===
	"executioner_strike": {
		"ability_name": "Удар палача",
		"ability_id": "executioner_strike",
		"rarity": "epic",
		"required_progress": 100,
		"enemy_type": "executioner_demon",
		"enemy_display_name": "Демон палач",
		"damage_type": "physical",
		"description": "Два разрушительных удара",
		"sources": {
			"epic": 10,
			"legendary": 15
		}
	},
	
	# === ДЕМОН ТАРНОК ===
	"tharnok_crushing_strike": {
		"ability_name": "Сокрушающий удар",
		"ability_id": "tharnok_crushing_strike",
		"rarity": "legendary",
		"required_progress": 100,
		"enemy_type": "tharnok_demon",
		"enemy_display_name": "Демон Тарнок",
		"damage_type": "physical",
		"description": "Два сокрушающих удара с оглушением",
		"sources": {
			"legendary": 10
		}
	},
	
	# === СКЕЛЕТ ЛОРД (БОСС) ===
	"armor_strike": {
		"ability_name": "Удар брони",
		"ability_id": "armor_strike",
		"rarity": "legendary",
		"required_progress": 100,
		"enemy_type": "skeleton_lord",
		"enemy_display_name": "Скелет лорд",
		"damage_type": "physical",
		"description": "Мощный удар, масштабирующийся с защитой",
		"sources": {
			"legendary": 15
		}
	}
}

func _ready():
	load_progress()

## Добавить прогресс изучения за победу над врагом
func add_progress(enemy_type: String, enemy_rarity: String) -> void:
	var enemy_rarity_lower = enemy_rarity.to_lower()
	
	# Проверяем все способности, которые можно изучить с этого врага
	for ability_id in learning_config:
		var config = learning_config[ability_id]
		
		# Проверяем, соответствует ли тип врага
		if config["enemy_type"] == enemy_type:
			# Проверяем, есть ли прогресс для этой редкости
			if config["sources"].has(enemy_rarity_lower):
				var progress_to_add = config["sources"][enemy_rarity_lower]
				
				# Инициализируем прогресс если нужно
				if not learning_progress.has(ability_id):
					learning_progress[ability_id] = {
						"current_progress": 0,
						"is_learned": false,
						"learned_at": null
					}
				
				# Не добавляем прогресс, если уже изучено
				if learning_progress[ability_id]["is_learned"]:
					continue
				
				# Добавляем прогресс
				learning_progress[ability_id]["current_progress"] += progress_to_add
				
				print("📖 Активная способность '%s': +%d прогресса (%d/%d)" % [
					config["ability_name"],
					progress_to_add,
					learning_progress[ability_id]["current_progress"],
					config["required_progress"]
				])
				
				# Ограничиваем максимум
				if learning_progress[ability_id]["current_progress"] > config["required_progress"]:
					learning_progress[ability_id]["current_progress"] = config["required_progress"]
				
				# Проверяем завершение изучения
				if learning_progress[ability_id]["current_progress"] >= config["required_progress"]:
					_on_ability_ready_to_learn(ability_id)
				else:
					# Отправляем сигнал об обновлении прогресса
					progress_updated.emit(
						ability_id,
						learning_progress[ability_id]["current_progress"],
						config["required_progress"]
					)
				
				# Сохраняем прогресс
				save_progress()

## Вызывается когда способность готова к изучению (100%)
func _on_ability_ready_to_learn(ability_id: String) -> void:
	if not learning_config.has(ability_id):
		return
	
	var config = learning_config[ability_id]
	
	# Отправляем сигнал о готовности к изучению
	progress_updated.emit(
		ability_id,
		config["required_progress"],
		config["required_progress"]
	)

## Изучить способность (вызывается из UI)
func learn_ability(ability_id: String) -> bool:
	if not learning_config.has(ability_id):
		return false
	
	if not learning_progress.has(ability_id):
		return false
	
	var config = learning_config[ability_id]
	
	# Проверяем, достигнут ли требуемый прогресс
	if learning_progress[ability_id]["current_progress"] < config["required_progress"]:
		return false
	
	# Проверяем, не изучена ли уже
	if learning_progress[ability_id]["is_learned"]:
		return false
	
	# Изучаем способность
	learning_progress[ability_id]["is_learned"] = true
	learning_progress[ability_id]["learned_at"] = Time.get_datetime_string_from_system()
	
	print("✨ Активная способность '%s' изучена!" % config["ability_name"])
	
	# Отправляем сигнал
	ability_learned.emit(ability_id, config["ability_name"])
	
	# Сохраняем
	save_progress()
	
	return true

## Получить прогресс изучения способности
func get_ability_progress(ability_id: String) -> Dictionary:
	if not learning_config.has(ability_id):
		return {}
	
	var config = learning_config[ability_id]
	var progress_data = learning_progress.get(ability_id, {
		"current_progress": 0,
		"is_learned": false,
		"learned_at": null
	})
	
	return {
		"ability_id": ability_id,
		"ability_name": config["ability_name"],
		"current_progress": progress_data["current_progress"],
		"required_progress": config["required_progress"],
		"is_learned": progress_data["is_learned"],
		"learned_at": progress_data.get("learned_at", null),
		"rarity": config["rarity"],
		"description": config["description"],
		"damage_type": config["damage_type"]
	}

## Проверить, изучена ли способность
func is_ability_learned(ability_id: String) -> bool:
	if not learning_progress.has(ability_id):
		return false
	return learning_progress[ability_id]["is_learned"]

## Получить список изученных способностей
func get_learned_abilities() -> Array[String]:
	var learned = []
	for ability_id in learning_progress:
		if learning_progress[ability_id]["is_learned"]:
			learned.append(ability_id)
	return learned

## Получить список всех способностей
func get_all_abilities() -> Array[String]:
	var abilities = []
	for ability_id in learning_config:
		abilities.append(ability_id)
	return abilities

## Получить способности по редкости
func get_abilities_by_rarity(rarity: String) -> Array[String]:
	var abilities = []
	for ability_id in learning_config:
		if learning_config[ability_id]["rarity"] == rarity:
			abilities.append(ability_id)
	return abilities

## Сохранить прогресс
func save_progress() -> void:
	var save_data = {
		"learning_progress": learning_progress,
		"last_updated": Time.get_datetime_string_from_system()
	}
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()

## Загрузить прогресс
func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()
		
		if save_data and save_data.has("learning_progress"):
			learning_progress = save_data["learning_progress"]

## Сбросить весь прогресс (для тестирования)
func reset_progress() -> void:
	learning_progress.clear()
	save_progress()

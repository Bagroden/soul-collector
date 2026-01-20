# res://Scripts/Systems/AbilitySlotManager.gd
extends Node

## Менеджер слотов активных способностей
## Управляет 4 слотами для использования способностей в бою

signal slot_changed(slot_index: int, ability_id: String)
signal slots_updated()

# Максимальное количество слотов
const MAX_SLOTS = 4

# Текущие слоты (индекс 0-3)
var equipped_slots: Array[String] = ["", "", "", ""]

# Кулдауны способностей (ability_id -> оставшиеся раунды)
var ability_cooldowns: Dictionary = {}

# Путь к файлу сохранения
const SAVE_FILE_PATH = "user://ability_slots.save"

func _ready():
	load_slots()

## Установить способность в слот
func set_slot(slot_index: int, ability_id: String) -> bool:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		push_error("Неверный индекс слота: %d" % slot_index)
		return false
	
	# Проверяем, изучена ли способность
	if ability_id != "":
		if not ActiveAbilityLearningSystem:
			push_error("ActiveAbilityLearningSystem не найден!")
			return false
		
		if not ActiveAbilityLearningSystem.is_ability_learned(ability_id):
			push_error("Способность '%s' не изучена!" % ability_id)
			return false
	
	# Проверяем, не занята ли эта способность в другом слоте
	if ability_id != "":
		for i in range(MAX_SLOTS):
			if i != slot_index and equipped_slots[i] == ability_id:
				# Убираем из старого слота
				equipped_slots[i] = ""
				slot_changed.emit(i, "")
	
	# Устанавливаем способность
	equipped_slots[slot_index] = ability_id
	
	# Отправляем сигналы
	slot_changed.emit(slot_index, ability_id)
	slots_updated.emit()
	
	# Сохраняем
	save_slots()
	
	print("🎯 Слот %d: %s" % [slot_index + 1, ability_id if ability_id != "" else "Пусто"])
	
	return true

## Очистить слот
func clear_slot(slot_index: int) -> bool:
	return set_slot(slot_index, "")

## Получить способность из слота
func get_slot(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return ""
	return equipped_slots[slot_index]

## Получить все слоты
func get_all_slots() -> Array[String]:
	return equipped_slots.duplicate()

## Проверить, занят ли слот
func is_slot_empty(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return true
	return equipped_slots[slot_index] == ""

## Получить индекс слота для способности (или -1 если не установлена)
func get_slot_index_for_ability(ability_id: String) -> int:
	for i in range(MAX_SLOTS):
		if equipped_slots[i] == ability_id:
			return i
	return -1

## Проверить, установлена ли способность в какой-либо слот
func is_ability_equipped(ability_id: String) -> bool:
	return get_slot_index_for_ability(ability_id) != -1

## Установить кулдаун для способности
func set_cooldown(ability_id: String, rounds: int) -> void:
	if rounds > 0:
		ability_cooldowns[ability_id] = rounds
		print("⏱️ Кулдаун '%s': %d раунд(ов)" % [ability_id, rounds])
	else:
		ability_cooldowns.erase(ability_id)

## Получить оставшийся кулдаун способности
func get_cooldown(ability_id: String) -> int:
	return ability_cooldowns.get(ability_id, 0)

## Проверить, на кулдауне ли способность
func is_on_cooldown(ability_id: String) -> bool:
	return get_cooldown(ability_id) > 0

## Уменьшить все кулдауны на 1 раунд
func reduce_cooldowns() -> void:
	var to_remove = []
	for ability_id in ability_cooldowns:
		ability_cooldowns[ability_id] -= 1
		if ability_cooldowns[ability_id] <= 0:
			to_remove.append(ability_id)
			print("✅ Кулдаун '%s' завершён!" % ability_id)
	
	# Удаляем завершившиеся кулдауны
	for ability_id in to_remove:
		ability_cooldowns.erase(ability_id)

## Сбросить все кулдауны (например, после боя)
func reset_cooldowns() -> void:
	ability_cooldowns.clear()
	print("🔄 Все кулдауны сброшены")

## Получить информацию о слоте для UI
func get_slot_info(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return {}
	
	var ability_id = equipped_slots[slot_index]
	if ability_id == "":
		return {
			"slot_index": slot_index,
			"is_empty": true,
			"ability_id": "",
			"ability_name": "Пусто",
			"cooldown": 0
		}
	
	var progress_data = ActiveAbilityLearningSystem.get_ability_progress(ability_id)
	var cooldown = get_cooldown(ability_id)
	
	return {
		"slot_index": slot_index,
		"is_empty": false,
		"ability_id": ability_id,
		"ability_name": progress_data.get("ability_name", "Неизвестно"),
		"description": progress_data.get("description", ""),
		"rarity": progress_data.get("rarity", "common"),
		"damage_type": progress_data.get("damage_type", "physical"),
		"cooldown": cooldown,
		"is_on_cooldown": cooldown > 0
	}

## Сохранить слоты
func save_slots() -> void:
	var save_data = {
		"equipped_slots": equipped_slots,
		"last_updated": Time.get_datetime_string_from_system()
	}
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()

## Загрузить слоты
func load_slots() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()
		
		if save_data and save_data.has("equipped_slots"):
			# Проверяем, что загруженные данные корректны
			var loaded_slots = save_data["equipped_slots"]
			if loaded_slots is Array and loaded_slots.size() == MAX_SLOTS:
				equipped_slots = []
				for slot in loaded_slots:
					if slot is String:
						equipped_slots.append(slot)
					else:
						equipped_slots.append("")
				
				print("💾 Слоты загружены: %s" % str(equipped_slots))

## Получить количество занятых слотов
func get_equipped_count() -> int:
	var count = 0
	for slot in equipped_slots:
		if slot != "":
			count += 1
	return count

## Сбросить все слоты (для тестирования)
func reset_slots() -> void:
	for i in range(MAX_SLOTS):
		equipped_slots[i] = ""
	save_slots()
	slots_updated.emit()
	print("🔄 Все слоты очищены")

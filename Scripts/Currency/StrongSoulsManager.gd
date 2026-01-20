# res://Scripts/Currency/StrongSoulsManager.gd
extends Node
class_name StrongSoulsManager

var strong_souls: int = 0

signal strong_souls_changed(new_amount: int)

func _ready():
	# Загружаем сохраненные данные
	load_data()

func add_strong_souls(amount: int):
	"""Добавляет сильные души"""
	strong_souls += amount
	emit_strong_souls_changed()
	save_data()  # Автоматически сохраняем при изменении

func spend_strong_souls(amount: int) -> bool:
	"""Тратит сильные души. Возвращает true если успешно"""
	if strong_souls >= amount:
		strong_souls -= amount
		emit_strong_souls_changed()
		save_data()  # Автоматически сохраняем при изменении
		return true
	return false

func get_strong_souls() -> int:
	"""Возвращает количество сильных душ"""
	return strong_souls

func emit_strong_souls_changed():
	"""Испускает сигнал об изменении количества сильных душ"""
	if has_signal("strong_souls_changed"):
		emit_signal("strong_souls_changed", strong_souls)

func save_data():
	"""Сохраняет данные сильных душ"""
	var data = {
		"strong_souls": strong_souls
	}
	
	var json_string = JSON.stringify(data)
	var file = FileAccess.open("user://strong_souls.save", FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("StrongSoulsManager: Данные сохранены: ", data)
	else:
		print("ОШИБКА: Не удалось создать файл для сохранения сильных душ!")

func reset_data():
	"""Сбрасывает данные сильных душ (для новой игры)"""
	strong_souls = 0
	emit_strong_souls_changed()
	# Удаляем файл сохранения
	if FileAccess.file_exists("user://strong_souls.save"):
		DirAccess.remove_absolute("user://strong_souls.save")
	print("StrongSoulsManager: Данные сброшены")

func load_data():
	"""Загружает данные сильных душ"""
	if not FileAccess.file_exists("user://strong_souls.save"):
		print("StrongSoulsManager: Файл сохранения не найден, используем значения по умолчанию")
		emit_strong_souls_changed()
		return
	
	var file = FileAccess.open("user://strong_souls.save", FileAccess.READ)
	if file == null:
		print("ОШИБКА: Не удалось открыть файл сильных душ для чтения!")
		emit_strong_souls_changed()
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("ОШИБКА: Не удалось распарсить файл сильных душ!")
		emit_strong_souls_changed()
		return
	
	var data = json.get_data()
	strong_souls = data.get("strong_souls", 0)
	
	print("StrongSoulsManager: Данные загружены: ", data)
	emit_strong_souls_changed()

# res://Scripts/Currency/DivineSoulsManager.gd
extends Node
class_name DivineSoulsManager

var divine_souls: int = 0

signal divine_souls_changed(new_amount: int)

func _ready():
	# Загружаем сохраненные данные
	load_data()

func add_divine_souls(amount: int):
	"""Добавляет божественные души"""
	divine_souls += amount
	emit_divine_souls_changed()
	save_data()  # Автоматически сохраняем при изменении

func spend_divine_souls(amount: int) -> bool:
	"""Тратит божественные души. Возвращает true если успешно"""
	if divine_souls >= amount:
		divine_souls -= amount
		emit_divine_souls_changed()
		save_data()  # Автоматически сохраняем при изменении
		return true
	return false

func get_divine_souls() -> int:
	"""Возвращает количество божественных душ"""
	return divine_souls

func emit_divine_souls_changed():
	"""Испускает сигнал об изменении количества божественных душ"""
	if has_signal("divine_souls_changed"):
		emit_signal("divine_souls_changed", divine_souls)

func save_data():
	"""Сохраняет данные божественных душ"""
	var data = {
		"divine_souls": divine_souls
	}
	
	var json_string = JSON.stringify(data)
	var file = FileAccess.open("user://divine_souls.save", FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("DivineSoulsManager: Данные сохранены: ", data)
	else:
		print("ОШИБКА: Не удалось создать файл для сохранения божественных душ!")

func reset_data():
	"""Сбрасывает данные божественных душ (для новой игры)"""
	divine_souls = 0
	emit_divine_souls_changed()
	# Удаляем файл сохранения
	if FileAccess.file_exists("user://divine_souls.save"):
		DirAccess.remove_absolute("user://divine_souls.save")
	print("DivineSoulsManager: Данные сброшены")

func load_data():
	"""Загружает данные божественных душ"""
	if not FileAccess.file_exists("user://divine_souls.save"):
		print("DivineSoulsManager: Файл сохранения не найден, используем значения по умолчанию")
		emit_divine_souls_changed()
		return
	
	var file = FileAccess.open("user://divine_souls.save", FileAccess.READ)
	if file == null:
		print("ОШИБКА: Не удалось открыть файл божественных душ для чтения!")
		emit_divine_souls_changed()
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("ОШИБКА: Не удалось распарсить файл божественных душ!")
		emit_divine_souls_changed()
		return
	
	var data = json.get_data()
	divine_souls = data.get("divine_souls", 0)
	
	print("DivineSoulsManager: Данные загружены: ", data)
	emit_divine_souls_changed()

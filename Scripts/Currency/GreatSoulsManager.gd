# res://Scripts/Currency/GreatSoulsManager.gd
extends Node
class_name GreatSoulsManager

var great_souls: int = 0

signal great_souls_changed(new_amount: int)

func _ready():
	# Загружаем сохраненные данные
	load_data()

func add_great_souls(amount: int):
	"""Добавляет великие души"""
	great_souls += amount
	emit_great_souls_changed()
	save_data()  # Автоматически сохраняем при изменении

func spend_great_souls(amount: int) -> bool:
	"""Тратит великие души. Возвращает true если успешно"""
	if great_souls >= amount:
		great_souls -= amount
		emit_great_souls_changed()
		save_data()  # Автоматически сохраняем при изменении
		return true
	return false

func get_great_souls() -> int:
	"""Возвращает количество великих душ"""
	return great_souls

func emit_great_souls_changed():
	"""Испускает сигнал об изменении количества великих душ"""
	if has_signal("great_souls_changed"):
		emit_signal("great_souls_changed", great_souls)

func save_data():
	"""Сохраняет данные великих душ"""
	var data = {
		"great_souls": great_souls
	}
	
	var json_string = JSON.stringify(data)
	var file = FileAccess.open("user://great_souls.save", FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
	else:
		print("ОШИБКА: Не удалось создать файл для сохранения великих душ!")

func reset_data():
	"""Сбрасывает данные великих душ (для новой игры)"""
	great_souls = 0
	emit_great_souls_changed()
	# Удаляем файл сохранения
	if FileAccess.file_exists("user://great_souls.save"):
		DirAccess.remove_absolute("user://great_souls.save")

func load_data():
	"""Загружает данные великих душ"""
	if not FileAccess.file_exists("user://great_souls.save"):
		emit_great_souls_changed()
		return
	
	var file = FileAccess.open("user://great_souls.save", FileAccess.READ)
	if file == null:
		print("ОШИБКА: Не удалось открыть файл великих душ для чтения!")
		emit_great_souls_changed()
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("ОШИБКА: Не удалось распарсить файл великих душ!")
		emit_great_souls_changed()
		return
	
	var data = json.get_data()
	great_souls = data.get("great_souls", 0)
	emit_great_souls_changed()

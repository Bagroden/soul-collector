# res://Scripts/IntroManager.gd
extends Node

## Менеджер для управления показом вступительного ролика

const INTRO_FLAG_FILE = "user://intro_shown.dat"

func is_intro_shown() -> bool:
	"""Проверяет, было ли показано интро"""
	return FileAccess.file_exists(INTRO_FLAG_FILE)

func mark_intro_as_shown():
	"""Отмечает, что интро было показано"""
	var file = FileAccess.open(INTRO_FLAG_FILE, FileAccess.WRITE)
	if file:
		file.store_8(1)
		file.close()
		print("✅ Интро отмечено как просмотренное")

func reset_intro_flag():
	"""Сбрасывает флаг показа интро (для повторного просмотра)"""
	if FileAccess.file_exists(INTRO_FLAG_FILE):
		DirAccess.remove_absolute(INTRO_FLAG_FILE)
		print("🔄 Флаг интро сброшен")

func should_show_intro() -> bool:
	"""Определяет, нужно ли показывать интро при запуске"""
	# Можно добавить дополнительные проверки:
	# - версия игры
	# - настройки игрока
	# - debug режим
	return not is_intro_shown()

func show_intro():
	"""Показывает вступительный ролик"""
	SceneTransition.change_scene("res://Scenes/UI/IntroScene.tscn")


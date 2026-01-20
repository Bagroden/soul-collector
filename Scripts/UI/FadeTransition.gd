# res://Scripts/UI/FadeTransition.gd
extends Control

signal transition_finished

@onready var fade_rect = $FadeRect

var is_fade_in: bool = false

func _ready():
	# Устанавливаем размеры на весь экран
	anchors_preset = Control.PRESET_FULL_RECT
	
	# Если это осветление (новый экран), начинаем с черного
	if is_fade_in:
		fade_rect.modulate.a = 1.0
		# Начинаем осветление СРАЗУ, без ожидания
		fade_in()
	else:
		# Если это затемнение, начинаем с прозрачного
		fade_rect.modulate.a = 0.0

func fade_out_and_change_scene(scene_path: String, duration: float = 1.0):
	"""Затемняет экран и меняет сцену"""
	print("FadeTransition: Начинаем затемнение к ", scene_path)
	
	# Создаем анимацию затемнения
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tween.finished
	
	print("FadeTransition: Затемнение завершено, меняем сцену")
	
	# Меняем сцену
	get_tree().change_scene_to_file(scene_path)
	
	print("FadeTransition: Сцена изменена")
	transition_finished.emit()

func fade_in(duration: float = 1.5):
	"""Плавно убирает затемнение с экрана"""
	print("FadeTransition: Начинаем осветление")
	
	# Создаем анимацию осветления
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, duration)
	await tween.finished
	
	print("FadeTransition: Осветление завершено")
	transition_finished.emit()
	queue_free()

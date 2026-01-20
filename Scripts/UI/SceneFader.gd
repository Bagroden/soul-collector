# res://Scripts/UI/SceneFader.gd
extends Node

const FadeTransitionScene = preload("res://Scenes/UI/FadeTransition.tscn")

func _ready():
	# Подключаемся к сигналу смены сцены
	get_tree().connect("scene_changed", Callable(self, "_on_scene_changed"))

func _on_scene_changed():
	"""Вызывается после смены сцены - добавляем черный фон и осветление"""
	print("SceneFader: Сцена изменена, добавляем черный фон")
	
	# Создаем черный фон СРАЗУ
	var black_overlay = ColorRect.new()
	black_overlay.name = "BlackOverlay"
	black_overlay.color = Color.BLACK
	black_overlay.anchors_preset = Control.PRESET_FULL_RECT
	black_overlay.modulate.a = 1.0  # Полностью черный
	get_tree().current_scene.add_child(black_overlay)
	
	# Ждем один кадр и начинаем осветление
	await get_tree().process_frame
	
	# Создаем анимацию осветления
	var tween = create_tween()
	tween.tween_property(black_overlay, "modulate:a", 0.0, 1.5)
	await tween.finished
	
	# Удаляем черный фон (с проверкой)
	if is_instance_valid(black_overlay):
		black_overlay.queue_free()
	print("SceneFader: Осветление завершено")

func fade_to_scene(scene_path: String, duration: float = 1.0):
	"""Затемняет экран и меняет сцену"""
	print("SceneFader: Начинаем переход к ", scene_path)
	
	# Создаем черный фон для затемнения
	var fade_out_overlay = ColorRect.new()
	fade_out_overlay.name = "FadeOutOverlay"
	fade_out_overlay.color = Color.BLACK
	fade_out_overlay.anchors_preset = Control.PRESET_FULL_RECT
	fade_out_overlay.modulate.a = 0.0  # Начинаем прозрачным
	get_tree().current_scene.add_child(fade_out_overlay)
	
	# Анимируем затемнение
	var tween = create_tween()
	tween.tween_property(fade_out_overlay, "modulate:a", 1.0, duration)
	await tween.finished
	
	print("SceneFader: Затемнение завершено, меняем сцену")
	
	# Удаляем затемняющий фон (с проверкой)
	if is_instance_valid(fade_out_overlay):
		fade_out_overlay.queue_free()
	
	# Меняем сцену
	get_tree().change_scene_to_file(scene_path)
	
	print("SceneFader: Сцена изменена")

# res://Scripts/UI/SimpleTransition.gd
extends Control

func fade_to_scene(scene_path: String, duration: float = 0.5):
	"""Простой переход с затемнением используя встроенные инструменты Godot"""
	print("Начинаем переход к: ", scene_path)
	
	# Создаем ColorRect для затемнения
	var fade_rect = ColorRect.new()
	fade_rect.name = "FadeRect"
	fade_rect.color = Color.BLACK
	fade_rect.anchors_preset = Control.PRESET_FULL_RECT
	fade_rect.modulate.a = 0.0  # Начинаем прозрачным
	
	# Добавляем поверх всего экрана
	get_tree().current_scene.add_child(fade_rect)
	
	# Анимируем затемнение
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUART)
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tween.finished
	
	print("Затемнение завершено, меняем сцену...")
	
	# Меняем сцену
	get_tree().change_scene_to_file(scene_path)
	
	print("Сцена изменена")
	
	# Удаляем себя после завершения
	queue_free()

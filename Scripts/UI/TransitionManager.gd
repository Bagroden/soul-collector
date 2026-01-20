extends Node

var current_transition: Control = null
var fade_out_overlay: Control = null

func _ready():
	# Подключаемся к сигналу смены сцены
	get_tree().scene_changed.connect(_on_scene_changed)

func start_transition(scene_path: String):
	"""Запускает переход к указанной сцене"""
	print("TransitionManager: Начинаем переход к ", scene_path)
	
	# Создаем черный экран прямо в корне дерева
	_create_fade_overlay()
	
	# Запускаем анимацию затемнения
	_animate_fade_out(scene_path)

func _create_fade_overlay():
	"""Создает черный экран поверх всего"""
	fade_out_overlay = Control.new()
	fade_out_overlay.name = "FadeOverlay"
	fade_out_overlay.anchors_preset = Control.PRESET_FULL_RECT
	fade_out_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var fade_rect = ColorRect.new()
	fade_rect.name = "FadeRect"
	fade_rect.anchors_preset = Control.PRESET_FULL_RECT
	fade_rect.color = Color.BLACK
	fade_rect.modulate.a = 0.0  # Начинаем прозрачным
	fade_out_overlay.add_child(fade_rect)
	
	get_tree().root.add_child(fade_out_overlay)

func _animate_fade_out(scene_path: String):
	"""Анимирует затемнение и меняет сцену"""
	var fade_rect = fade_out_overlay.get_node("FadeRect")
	
	# Анимация затемнения
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 2.0)
	await tween.finished
	
	print("TransitionManager: Затемнение завершено, меняем сцену")
	
	# Меняем сцену
	get_tree().change_scene_to_file(scene_path)
	
	print("TransitionManager: Сцена изменена, убираем черный экран")
	
	# Убираем черный экран
	_remove_fade_overlay()


func _on_scene_changed():
	"""Вызывается при смене сцены"""
	print("TransitionManager: Сцена изменена")

func _remove_fade_overlay():
	"""Убирает черный экран"""
	if fade_out_overlay:
		print("TransitionManager: Убираем черный экран")
		fade_out_overlay.queue_free()
		fade_out_overlay = null
	else:
		print("TransitionManager: Черный экран не найден")

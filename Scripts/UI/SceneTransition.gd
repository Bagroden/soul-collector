# scene_transition.gd
extends CanvasLayer

# Ссылка на узел AnimationPlayer
@onready var animation_player = $AnimationPlayer

# Переменная для хранения пути к следующей сцене
var next_scene_path: String = ""

func _ready():
	# Создаем анимации программно
	_create_animations()
	
	# Настраиваем ColorRect чтобы он не блокировал клики
	var color_rect = $ColorRect
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# При запуске делаем экран прозрачным, чтобы избежать черного экрана
	animation_player.play("RESET")

func _create_animations():
	"""Создает анимации программно"""
	
	# Анимация RESET (0.1 сек) - прозрачный экран
	var reset_animation = Animation.new()
	reset_animation.length = 0.1
	var reset_track = reset_animation.add_track(Animation.TYPE_VALUE)
	reset_animation.track_set_path(reset_track, NodePath("ColorRect:color"))
	reset_animation.track_insert_key(reset_track, 0.0, Color(0, 0, 0, 0))
	
	# Анимация fade_to_black (0.5 сек) - затемнение
	var fade_to_black_animation = Animation.new()
	fade_to_black_animation.length = 0.5
	var fade_to_black_track = fade_to_black_animation.add_track(Animation.TYPE_VALUE)
	fade_to_black_animation.track_set_path(fade_to_black_track, NodePath("ColorRect:color"))
	fade_to_black_animation.track_insert_key(fade_to_black_track, 0.0, Color(0, 0, 0, 0))  # Прозрачный
	fade_to_black_animation.track_insert_key(fade_to_black_track, 0.5, Color(0, 0, 0, 1))  # Черный
	
	# Анимация fade_from_black (0.5 сек) - проявление
	var fade_from_black_animation = Animation.new()
	fade_from_black_animation.length = 0.5
	var fade_from_black_track = fade_from_black_animation.add_track(Animation.TYPE_VALUE)
	fade_from_black_animation.track_set_path(fade_from_black_track, NodePath("ColorRect:color"))
	fade_from_black_animation.track_insert_key(fade_from_black_track, 0.0, Color(0, 0, 0, 1))  # Черный
	fade_from_black_animation.track_insert_key(fade_from_black_track, 0.5, Color(0, 0, 0, 0))  # Прозрачный
	
	# Добавляем анимации в AnimationPlayer
	animation_player.add_animation_library("", AnimationLibrary.new())
	animation_player.get_animation_library("").add_animation("RESET", reset_animation)
	animation_player.get_animation_library("").add_animation("fade_to_black", fade_to_black_animation)
	animation_player.get_animation_library("").add_animation("fade_from_black", fade_from_black_animation)

# Главная функция, которую мы будем вызывать из других скриптов
func change_scene(scene_path: String):
	# Сохраняем путь и запускаем анимацию затемнения
	next_scene_path = scene_path
	animation_player.play("fade_to_black")
	
	# Ждём, пока анимация затемнения не закончится
	await animation_player.animation_finished
	
	# Когда экран стал черным, меняем сцену
	var error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		print("Ошибка при загрузке сцены: ", error)
		# Если сцена не загрузилась, просто проявляем экран обратно
		animation_player.play("fade_from_black")
		return

	# После успешной загрузки новой сцены, запускаем анимацию проявления
	animation_player.play("fade_from_black")

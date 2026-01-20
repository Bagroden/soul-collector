extends Control

signal transition_finished

var target_scene: String = ""
var animation_player: AnimationPlayer
var fade_rect: ColorRect

func _ready():
	animation_player = $AnimationPlayer
	fade_rect = $FadeRect
	animation_player.animation_finished.connect(_on_animation_finished)
	
	# Создаем анимацию программно
	_create_fade_animation()

func _create_fade_animation():
	"""Создает анимацию затемнения программно"""
	var animation = Animation.new()
	animation.length = 2.0
	
	# Трек для цвета (только затемнение)
	var color_track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(color_track, NodePath("FadeRect:color"))
	animation.track_insert_key(color_track, 0.0, Color(0, 0, 0, 0))  # Прозрачный
	animation.track_insert_key(color_track, 1.0, Color(0, 0, 0, 1))  # Черный
	
	# Добавляем анимацию в AnimationPlayer
	animation_player.add_animation_library("", AnimationLibrary.new())
	animation_player.get_animation_library("").add_animation("fade", animation)

func start_transition(scene_path: String):
	"""Запускает переход к указанной сцене"""
	target_scene = scene_path
	print("ScreenTransition: Начинаем переход к ", scene_path)
	
	# Запускаем анимацию затемнения
	animation_player.play("fade")

func _on_animation_finished(animation_name: String):
	if animation_name == "fade":
		print("ScreenTransition: Затемнение завершено, меняем сцену")
		# Меняем сцену когда экран полностью черный
		if target_scene != "":
			print("ScreenTransition: Меняем сцену на ", target_scene)
			get_tree().change_scene_to_file(target_scene)
			target_scene = ""
		
		# Уведомляем о завершении
		transition_finished.emit()
		
		# Удаляем себя
		queue_free()

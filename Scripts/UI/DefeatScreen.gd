# res://Scripts/UI/DefeatScreen.gd
extends Control

@onready var defeat_title = $CenterContainer/VBoxContainer/DefeatTitle
@onready var defeat_message = $CenterContainer/VBoxContainer/DefeatMessage
@onready var soul_message = $CenterContainer/VBoxContainer/SoulMessage
@onready var btn_save = $CenterContainer/VBoxContainer/Btn_Save

signal defeat_screen_closed

func _ready():
	# Подключаем сигнал кнопки
	btn_save.connect("pressed", Callable(self, "_on_save_button_pressed"))
	
	# Запускаем анимацию появления
	_start_appear_animation()

func _start_appear_animation():
	"""Анимация появления экрана поражения"""
	# Начинаем с прозрачности
	modulate = Color(1, 1, 1, 0)
	
	# Анимация появления
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 1.0)
	tween.play()
	
	# Анимация пульсации заголовка
	var title_tween = create_tween()
	title_tween.tween_property(defeat_title, "scale", Vector2(1.1, 1.1), 0.5)
	title_tween.tween_property(defeat_title, "scale", Vector2(1.0, 1.0), 0.5)
	title_tween.set_loops()
	
	# Анимация появления кнопки с задержкой
	btn_save.modulate = Color(1, 1, 1, 0)
	var button_tween = create_tween()
	button_tween.tween_interval(1.5)  # Задержка перед появлением кнопки
	button_tween.tween_property(btn_save, "modulate", Color(1, 1, 1, 1), 0.5)
	button_tween.play()

func _on_save_button_pressed():
	"""Обрабатывает нажатие кнопки 'Спастись'"""
	print("Игрок выбрал 'Спастись' - возвращаемся к подготовке персонажа")
	
	# Анимация исчезновения
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(Callable(self, "_return_to_character_preparation"))
	tween.play()

func _return_to_character_preparation():
	"""Возвращает игрока к экрану подготовки персонажа"""
	# Осколки душ за забег уже перенесены в хранилище при смерти игрока
	# (в battle_manager.gd при вызове _on_player_died())
	
	# Восстанавливаем заряды восстановления души
	var soul_restoration_manager = get_node_or_null("/root/SoulRestorationManager")
	if soul_restoration_manager:
		soul_restoration_manager.restore_all_charges()
	
	# Останавливаем боевую музыку с плавным затуханием
	var music_player = get_node_or_null("/root/MusicPlayer")
	if music_player:
		music_player.stop_music(true)  # fade_out=true
	
	# Переходим к экрану подготовки персонажа
	SceneTransition.change_scene("res://Scenes/UI/CharacterPreparation.tscn")
	
	# Отправляем сигнал о закрытии экрана поражения
	emit_signal("defeat_screen_closed")

func _unhandled_key_input(event):
	"""Обрабатывает нажатия клавиш"""
	if event.pressed:
		match event.keycode:
			KEY_ENTER, KEY_SPACE:
				_on_save_button_pressed()
			KEY_ESCAPE:
				_on_save_button_pressed()

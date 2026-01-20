# res://Scripts/MainMenu.gd
extends Control

@onready var btn_new_game = $VBoxContainer/Btn_NewGame
@onready var btn_continue = $VBoxContainer/Btn_Continue
@onready var btn_load = $VBoxContainer/Btn_Load
@onready var btn_settings = $VBoxContainer/Btn_Settings
@onready var btn_exit = $VBoxContainer/Btn_Exit
@onready var title_label = $Title

func _ready():
	# Подключаем сигналы кнопок
	btn_new_game.connect("pressed", Callable(self, "_on_new_game_pressed"))
	btn_continue.connect("pressed", Callable(self, "_on_continue_pressed"))
	btn_load.connect("pressed", Callable(self, "_on_load_pressed"))
	btn_settings.connect("pressed", Callable(self, "_on_settings_pressed"))
	btn_exit.connect("pressed", Callable(self, "_on_exit_pressed"))
	
	# Подключаем сигнал закрытия окна для сохранения
	get_tree().get_root().connect("close_requested", Callable(self, "_on_window_close_requested"))
	
	# Подключаем кнопку "Вернуться в бой" если она есть
	var btn_return = get_node_or_null("Btn_ReturnToBattle")
	if btn_return:
		btn_return.connect("pressed", Callable(self, "_on_return_to_battle_pressed"))
	
	# Проверяем наличие сохранения для кнопки "Продолжить"
	_check_save_exists()
	
	# Запускаем анимацию заголовка
	_start_title_animation()
	
	# Инициализируем фоновую музыку
	_initialize_background_music()
	
	# Устанавливаем фоновое изображение
	_setup_background_image()
	
	# Показываем дисклеймер о разработке игры
	await get_tree().create_timer(0.5).timeout  # Небольшая задержка после загрузки
	_show_development_disclaimer()

func _check_save_exists():
	# Проверяем наличие файла сохранения
	var player_manager = get_node_or_null("/root/PlayerManager")
	if player_manager and player_manager.has_save_file():
		btn_continue.disabled = false
	else:
		btn_continue.disabled = true

func _on_new_game_pressed():
	# Воспроизводим звук нажатия кнопки
	if SoundManager:
		SoundManager.play_sound("page", -5.0)
	
	# Проверяем, есть ли прогресс изучения способностей
	var ability_learning_system = get_node_or_null("/root/AbilityLearningSystem")
	var has_learning_progress = false
	
	if ability_learning_system:
		has_learning_progress = ability_learning_system.has_any_progress()
	
	# Если есть прогресс изучения, показываем предупреждение
	if has_learning_progress:
		_show_new_game_warning()
	else:
		_start_new_game()

func _show_new_game_warning():
	"""Показывает предупреждение о потере прогресса изучения способностей"""
	var dialog = ConfirmationDialog.new()
	dialog.title = "Новая игра"
	dialog.dialog_text = "⚠️ ВНИМАНИЕ!\n\nПри создании новой игры весь прогресс изучения способностей врагов будет потерян.\n\nВы уверены, что хотите продолжить?"
	dialog.get_ok_button().text = "Да, продолжить"
	dialog.get_cancel_button().text = "Отмена"
	
	add_child(dialog)
	dialog.popup_centered()
	
	# Подключаем сигналы
	dialog.confirmed.connect(_on_new_game_confirmed)
	dialog.canceled.connect(_on_new_game_canceled.bind(dialog))

func _on_new_game_confirmed():
	"""Подтверждение создания новой игры"""
	# Воспроизводим звук подтверждения
	if SoundManager:
		SoundManager.play_sound("page", -5.0)
	
	_start_new_game()

func _on_new_game_canceled(dialog: ConfirmationDialog):
	"""Отмена создания новой игры"""
	dialog.queue_free()

func _start_new_game():
	"""Начинает новую игру"""
	
	# Удаляем старое сохранение при начале новой игры
	var player_manager = get_node_or_null("/root/PlayerManager")
	if player_manager:
		print("MainMenu: Начало новой игры - удаление сохранения и сброс данных")
		player_manager.delete_save_file()
		# Сбрасываем данные игрока к начальным
		player_manager.initialize_player()
		
		# Проверяем что данные сброшены правильно
		var player_data = player_manager.get_player_data()
		if player_data:
			print("MainMenu: После сброса - Base STR=", player_data.base_strength, " Final STR=", player_data.strength)
	
	# Сбрасываем прогресс изучения способностей
	var ability_learning_system = get_node_or_null("/root/AbilityLearningSystem")
	if ability_learning_system:
		ability_learning_system.reset_learning_progress()
	
	# Сбрасываем прогресс локаций (блокируем все кроме первой)
	var location_manager = get_node_or_null("/root/LocationManager")
	if location_manager:
		# Блокируем все локации кроме первой
		for location in location_manager.locations.values():
			location.is_unlocked = false
		# Разблокируем только первую локацию
		if "dungeon" in location_manager.locations:
			location_manager.locations["dungeon"].is_unlocked = true
		location_manager.current_location = location_manager.locations.get("dungeon")
	
	# Сбрасываем все валюты к начальным значениям
	var soul_shard_manager = get_node_or_null("/root/SoulShard")
	if soul_shard_manager:
		soul_shard_manager.reset_soul_shards()
		print("MainMenu: Осколки душ сброшены")
	
	var strong_souls_manager = get_node_or_null("/root/StrongSouls")
	if strong_souls_manager:
		strong_souls_manager.reset_data()
	
	var great_souls_manager = get_node_or_null("/root/GreatSouls")
	if great_souls_manager:
		great_souls_manager.reset_data()
	
	var divine_souls_manager = get_node_or_null("/root/DivineSouls")
	if divine_souls_manager:
		divine_souls_manager.reset_data()
	
	# Переходим к экрану подготовки персонажа
	SceneTransition.change_scene("res://Scenes/UI/CharacterPreparation.tscn")

func _on_continue_pressed():
	# Воспроизводим звук нажатия кнопки
	if SoundManager:
		SoundManager.play_sound("page", -5.0)
	
	# Загружаем сохраненные данные
	var player_manager = get_node_or_null("/root/PlayerManager")
	if player_manager:
		player_manager.load_game_data()
	
	# Осколки душ за забег уже перенесены в хранилище при завершении уровня
	# (в RoomSelector.gd при вызове _return_to_location_selector())
	
	# Переходим к экрану подготовки персонажа с плавным переходом
	SceneTransition.change_scene("res://Scenes/UI/CharacterPreparation.tscn")

func _on_load_pressed():
	# Воспроизводим звук нажатия кнопки
	if SoundManager:
		SoundManager.play_sound("page", -5.0)
	
	# В будущем здесь будет экран загрузки сохранений
	_show_load_dialog()

func _on_settings_pressed():
	"""Открывает экран настроек"""
	# Воспроизводим звук нажатия кнопки
	if SoundManager:
		SoundManager.play_sound("page", -5.0)
	
	var settings_scene = preload("res://Scenes/UI/SettingsScreen.tscn")
	var settings_instance = settings_scene.instantiate()
	
	# Устанавливаем предыдущую сцену
	settings_instance.set_previous_scene("res://Scenes/MainMenu.tscn")
	
	# Добавляем к текущей сцене
	add_child(settings_instance)

func _on_exit_pressed():
	# Воспроизводим звук нажатия кнопки
	if SoundManager:
		SoundManager.play_sound("page", -5.0)
	
	# Сохраняем игру перед выходом
	var player_manager = get_node_or_null("/root/PlayerManager")
	if player_manager:
		player_manager.save_game_data()
	
	get_tree().quit()

# === ИНТРО ===

func _on_watch_intro_pressed():
	"""Показывает интро (для кнопки в настройках или меню)"""
	if SoundManager:
		SoundManager.play_sound("page", -5.0)
	SceneTransition.change_scene("res://Scenes/UI/IntroScene.tscn")

func _on_window_close_requested():
	# Сохраняем игру при закрытии окна
	var player_manager = get_node_or_null("/root/PlayerManager")
	if player_manager:
		player_manager.save_game_data()
		print("Игра сохранена при закрытии окна")
	
	get_tree().quit()

func _show_load_dialog():
	# Временная заглушка для диалога загрузки
	var dialog = AcceptDialog.new()
	dialog.title = "Загрузка"
	dialog.dialog_text = "Функция загрузки будет добавлена в будущих версиях"
	add_child(dialog)
	dialog.popup_centered()
	dialog.connect("confirmed", Callable(dialog, "queue_free"))

func _show_settings_dialog():
	# Временная заглушка для диалога настроек
	var dialog = AcceptDialog.new()
	dialog.title = "Настройки"
	dialog.dialog_text = "Функция настроек будет добавлена в будущих версиях"
	add_child(dialog)
	dialog.popup_centered()
	dialog.connect("confirmed", Callable(dialog, "queue_free"))

func _start_title_animation():
	# Проверяем, что заголовок найден
	if not title_label:
		return
	
	# Создаем анимацию пульсации для заголовка
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(title_label, "modulate", Color(0.3, 1.0, 1.0, 1.0), 3.0)  # Яркая вариация #37feee
	tween.tween_property(title_label, "modulate", Color(0.1, 0.6, 0.7, 0.8), 3.0)  # Тусклая вариация #37feee

func _initialize_background_music():
	"""Инициализирует фоновую музыку для главного меню"""
	var music_player = get_node_or_null("/root/MusicPlayer")
	if music_player:
		# Загружаем музыкальный файл
		var main_menu_music = preload("res://Audio/Music/Background/Action 5 Loop.ogg")
		if main_menu_music:
			music_player.play_music(main_menu_music, true, true, 4.0, -15.0)  # fade_in=true, crossfade=true, 4 секунды, начальная громкость -15dB

func _setup_background_image():
	"""Устанавливает фоновое изображение для главного меню"""
	var background_node = get_node("Background")
	if background_node:
		# Загружаем изображение
		var background_texture = load("res://Assets/Mainmenu.png")
		if background_texture:
			# Преобразуем ColorRect в TextureRect
			var texture_rect = TextureRect.new()
			texture_rect.name = "BackgroundTexture"
			texture_rect.anchors_preset = Control.PRESET_FULL_RECT
			texture_rect.anchor_right = 1.0
			texture_rect.anchor_bottom = 1.0
			texture_rect.texture = background_texture
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			
			# Добавляем полупрозрачный слой
			var overlay = ColorRect.new()
			overlay.name = "Overlay"
			overlay.anchors_preset = Control.PRESET_FULL_RECT
			overlay.anchor_right = 1.0
			overlay.anchor_bottom = 1.0
			overlay.color = Color(0, 0, 0, 0.3)
			
			# Заменяем старый фон
			background_node.queue_free()
			add_child(texture_rect)
			add_child(overlay)
			move_child(overlay, 0)  # Перемещаем overlay под VBoxContainer
			move_child(texture_rect, 0)  # Перемещаем texture_rect под overlay

func _on_return_to_battle_pressed():
	# Воспроизводим звук нажатия кнопки
	if SoundManager:
		SoundManager.play_sound("page", -5.0)
	
	print("Возвращаемся в бой...")
	# Удаляем главное меню (этот узел)
	queue_free()

func _show_development_disclaimer():
	"""Показывает дисклеймер о разработке игры при запуске"""
	# Создаем окно
	var window = Window.new()
	window.title = "Soul Collector - Early Access"
	window.size = Vector2i(700, 600)  # Увеличено с 550 до 600
	window.popup_window = true
	window.transient = true
	window.exclusive = true
	window.unresizable = true
	
	# Подключаем сигнал закрытия окна по крестику
	window.close_requested.connect(func():
		if SoundManager:
			SoundManager.play_sound("page", -5.0)
		window.queue_free()
	)
	
	# Создаем панель с темным фоном
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Стилизуем панель
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.98)
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.8, 0.4, 0.0, 1.0)  # Оранжевая рамка
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.shadow_size = 10
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel.add_theme_stylebox_override("panel", panel_style)
	
	# Создаем контейнер для содержимого
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 15)
	vbox.offset_left = 30
	vbox.offset_right = -30
	vbox.offset_top = 30
	vbox.offset_bottom = -30
	
	# Заголовок
	var title = RichTextLabel.new()
	title.bbcode_enabled = true
	title.fit_content = true
	title.scroll_active = false
	title.custom_minimum_size = Vector2(0, 50)  # Уменьшено с 60 до 50
	title.text = "[center][color=#FF8800][b]⚠️ ИГРА В РАЗРАБОТКЕ ⚠️[/b][/color][/center]"
	title.add_theme_font_size_override("bold_font_size", 26)  # Уменьшено с 28 до 26
	vbox.add_child(title)
	
	# Создаем ScrollContainer для прокрутки текста
	var scroll_container = ScrollContainer.new()
	scroll_container.custom_minimum_size = Vector2(0, 400)
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Основной текст
	var content = RichTextLabel.new()
	content.bbcode_enabled = true
	content.fit_content = true  # Разрешаем тексту занимать нужную высоту
	content.scroll_active = false  # Отключаем встроенную прокрутку (используем ScrollContainer)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var disclaimer_text = """[center][color=#FFAA44][b]Внимание![/b][/color][/center]

Эта игра находится на ранней стадии разработки (Early Access). В процессе игры могут возникать ошибки и баги.

[color=#44FF88][b]✓ Доступно в игре:[/b][/color]

• [color=#88DDFF][b]5 локаций[/b][/color] для прохождения
• [color=#88DDFF][b]22 типа врагов[/b][/color] (обычные + элитные + боссы)
• [color=#88DDFF][b]130+ пассивных способностей[/b][/color] для изучения
• Система мета-прогрессии (изучение способностей)
• Развитие персонажа и распределение характеристик
• Квестовая линия с Архитектором душ

[color=#FFDD44][b]📋 В будущих обновлениях:[/b][/color]

• Изучение [b]активных способностей[/b] врагов
• Дополнительные локации ([color=#FF6666]4 новые зоны[/color])
• [color=#FF4444][b]Убер-боссы[/b][/color] для экстремального вызова
• Уникальные [color=#AA44FF]мифические способности[/color]
• Новые квесты и сюжетные линии
• Система крафта и улучшений

[center][color=#44FF44][b]Спасибо за тестирование игры![/b][/color]
[color=#AAAAAA]Ваши отзывы помогают сделать игру лучше[/color][/center]"""
	
	content.text = disclaimer_text
	content.add_theme_font_size_override("normal_font_size", 16)
	content.add_theme_font_size_override("bold_font_size", 18)
	
	# Добавляем текст в ScrollContainer, а ScrollContainer в vbox
	scroll_container.add_child(content)
	vbox.add_child(scroll_container)
	
	# Кнопка "Продолжить"
	var button = Button.new()
	button.text = "Понятно, продолжить"
	button.custom_minimum_size = Vector2(0, 50)
	button.add_theme_font_size_override("font_size", 18)
	
	# Стилизуем кнопку
	var button_normal = StyleBoxFlat.new()
	button_normal.bg_color = Color(0.2, 0.5, 0.8, 1.0)
	button_normal.corner_radius_top_left = 8
	button_normal.corner_radius_top_right = 8
	button_normal.corner_radius_bottom_left = 8
	button_normal.corner_radius_bottom_right = 8
	button.add_theme_stylebox_override("normal", button_normal)
	
	var button_hover = StyleBoxFlat.new()
	button_hover.bg_color = Color(0.3, 0.6, 1.0, 1.0)
	button_hover.corner_radius_top_left = 8
	button_hover.corner_radius_top_right = 8
	button_hover.corner_radius_bottom_left = 8
	button_hover.corner_radius_bottom_right = 8
	button.add_theme_stylebox_override("hover", button_hover)
	
	var button_pressed = StyleBoxFlat.new()
	button_pressed.bg_color = Color(0.15, 0.4, 0.7, 1.0)
	button_pressed.corner_radius_top_left = 8
	button_pressed.corner_radius_top_right = 8
	button_pressed.corner_radius_bottom_left = 8
	button_pressed.corner_radius_bottom_right = 8
	button.add_theme_stylebox_override("pressed", button_pressed)
	
	button.pressed.connect(func():
		if SoundManager:
			SoundManager.play_sound("page", -5.0)
		window.queue_free()
	)
	
	vbox.add_child(button)
	
	# Собираем все вместе
	panel.add_child(vbox)
	window.add_child(panel)
	add_child(window)
	
	# Центрируем окно
	await get_tree().process_frame
	var screen_size = DisplayServer.screen_get_size()
	var window_size = window.size
	window.position = Vector2i(
		(screen_size.x - window_size.x) / 2,
		(screen_size.y - window_size.y) / 2
	)
	
	window.show()

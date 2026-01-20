# res://Scripts/UI/CharacterPreparation.gd
extends Control

@onready var back_button = $MainContainer/ActionContainer/BackButton
@onready var start_journey_button = $MainContainer/ActionContainer/StartJourneyButton
@onready var reset_stats_button = $MainContainer/ActionContainer/ResetStatsButton
@onready var distribute_stats_button = $MainContainer/ActionContainer/DistributeStatsButton
@onready var soul_shard_storage_label = $SoulShardStorageIndicator/SoulShardsLabel
@onready var strong_souls_label = $StrongSoulsIndicator/StrongSoulsLabel
@onready var great_souls_label = $GreatSoulsIndicator/GreatSoulsLabel
@onready var divine_souls_label = $DivineSoulsIndicator/DivineSoulsLabel

## Вихрь душ для колодца
var soul_vortex: Node2D = null

## NPC Скульптор душ
var soul_sculptor: Node2D = null

func _ready():
	# Подключаем сигналы
	back_button.pressed.connect(_on_back_button_pressed)
	start_journey_button.pressed.connect(_on_start_journey_button_pressed)
	reset_stats_button.pressed.connect(_on_reset_stats_button_pressed)
	distribute_stats_button.pressed.connect(_on_distribute_stats_button_pressed)
	
	# Стилизуем кнопку "Отправиться в путешествие"
	_style_journey_button()
	
	# Устанавливаем цвета кнопок
	reset_stats_button.add_theme_color_override("font_color", Color("ff6666"))  # Красный
	distribute_stats_button.add_theme_color_override("font_color", Color("6666ff"))  # Синий
	
	# Скрываем кнопки - функционал перенесен в диалог Скульптора душ
	reset_stats_button.visible = false
	distribute_stats_button.visible = false
	
	# Инициализируем музыку для подготовки персонажа
	_initialize_character_music()
	
	# Осколки душ за забег уже перенесены в хранилище при завершении уровня или поражении
	# (в battle_manager.gd или RoomSelector.gd)
	
	# Обновляем индикатор хранилища осколков душ
	_update_soul_shard_storage_display()
	
	# Обновляем индикаторы новых валют
	_update_currency_display()
	
	# Инициализируем подсказки для душ
	_setup_soul_tooltips()
	
	# Создаем и запускаем вихрь душ для колодца
	_initialize_soul_vortex()
	
	# Создаем NPC Скульптора душ
	_initialize_soul_sculptor()

func _initialize_soul_vortex() -> void:
	"""Инициализирует анимацию вихря душ для колодца"""
	var soul_vortex_script = load("res://Scripts/UI/SoulWellVortex.gd")
	if not soul_vortex_script:
		push_error("Не удалось загрузить скрипт SoulWellVortex.gd")
		return
	
	soul_vortex = Node2D.new()
	soul_vortex.set_script(soul_vortex_script)
	soul_vortex.name = "SoulWellVortex"
	soul_vortex.z_index = 10  # Поверх фона (UI окна на z_index = 100)
	add_child(soul_vortex)

func _initialize_soul_sculptor() -> void:
	"""Инициализирует NPC Скульптора душ"""
	print("=== Инициализация Скульптора душ ===")
	var sculptor_script = load("res://Scripts/NPC/SoulSculptor.gd")
	if not sculptor_script:
		push_error("Не удалось загрузить скрипт SoulSculptor.gd")
		return
	
	soul_sculptor = Node2D.new()
	soul_sculptor.set_script(sculptor_script)
	soul_sculptor.name = "SoulSculptor"
	soul_sculptor.z_index = 15  # Поверх вихря (UI окна на z_index = 100)
	
	# Позиционируем NPC рядом с колодцем душ
	# Центр экрана примерно 960x540, колодец в центре
	# Размещаем СПРАВА от колодца (правее на 500, выше на 350 от низа)
	var viewport_size = get_viewport_rect().size
	soul_sculptor.position = Vector2(viewport_size.x / 2 + 500, viewport_size.y - 350)
	
	add_child(soul_sculptor)

func open_passive_abilities_window():
	"""Открывает окно пассивных способностей (вызывается извне, например от NPC)"""
	print("📚 Открытие окна пассивных способностей...")
	
	# ИНИЦИАЛИЗАЦИЯ СИСТЕМЫ ПАССИВНЫХ СПОСОБНОСТЕЙ
	var player_manager = get_node_or_null("/root/PlayerManager")
	if player_manager:
		var player_data = player_manager.get_player_data()
		if player_data:
			player_data.initialize_passive_system()
			
			# Изучаем базовые способности если еще не изучены
			var learned_passives = player_data.get_learned_passives()
			var abilities_to_learn = ["player_fortress", "player_strong", "player_wise", "player_vitality"]
			
			for ability_id in abilities_to_learn:
				if ability_id not in learned_passives:
					player_data.learn_passive_ability(ability_id)
	
	_show_passive_abilities_window()

func _on_back_button_pressed():
	"""Возвращается в главное меню"""
	# Воспроизводим звук нажатия кнопки
	if SoundManager:
		SoundManager.play_sound("page", -5.0)
	
	SceneTransition.change_scene("res://Scenes/MainMenu.tscn")

func _on_start_journey_button_pressed():
	"""Начинает путешествие - переходит к выбору уровня"""
	# Воспроизводим звук нажатия кнопки
	if SoundManager:
		SoundManager.play_sound("page", -5.0)
	
	# Обновляем индикатор хранилища осколков душ перед началом путешествия
	_update_soul_shard_storage_display()
	
	# Сбрасываем счетчик осколков душ за забег при начале нового забега
	var soul_shard_manager = get_node_or_null("/root/SoulShard")
	if soul_shard_manager:
		soul_shard_manager.reset_run_soul_shards()
	
	# Восстанавливаем заряды восстановления души при входе на уровень
	var soul_restoration_manager = get_node_or_null("/root/SoulRestorationManager")
	if soul_restoration_manager:
		soul_restoration_manager.restore_all_charges()
	
	# Переходим к выбору локации
	SceneTransition.change_scene("res://Scenes/LocationSelector.tscn")

func _show_passive_abilities_window():
	"""Показывает окно пассивных способностей"""
	# Получаем данные игрока
	var player_manager = get_node_or_null("/root/PlayerManager")
	if not player_manager:
		print("PlayerManager не найден")
		return
	
	var player_data = player_manager.get_player_data()
	if not player_data:
		print("Данные игрока не найдены")
		return
	
	# Инициализируем систему пассивных способностей
	player_data.initialize_passive_system()
	
	# Инициализация завершена
	
	# Загружаем полноценное окно пассивных способностей
	var passive_window_scene = preload("res://Scenes/UI/PassiveAbilitiesWindow.tscn")
	var passive_window = passive_window_scene.instantiate()
	passive_window.z_index = 100  # Поверх всего (NPC на 15, вихрь на 10)
	add_child(passive_window)



func _on_distribute_stats_button_pressed():
	"""Обрабатывает нажатие кнопки распределения характеристик"""
	# Воспроизводим звук нажатия кнопки
	if SoundManager:
		SoundManager.play_sound("page", -5.0)
	
	print("Открываем экран характеристик...")
	
	# Загружаем сцену StatsScreen
	var stats_scene = preload("res://Scenes/StatsScreen.tscn")
	var stats_instance = stats_scene.instantiate()
	
	# Устанавливаем предыдущую сцену
	stats_instance.set_previous_scene("res://Scenes/UI/CharacterPreparation.tscn")
	
	# Устанавливаем z_index для отображения поверх всего
	stats_instance.z_index = 100  # Поверх всего (NPC на 15, вихрь на 10)
	
	# Добавляем к текущей сцене
	add_child(stats_instance)
	
	# Принудительно обновляем отображение статистики
	stats_instance.update_display()
	
	print("Экран характеристик открыт с возвратом на CharacterPreparation")

func _on_reset_stats_button_pressed():
	"""Обрабатывает нажатие кнопки сброса характеристик"""
	# Воспроизводим звук нажатия кнопки
	if SoundManager:
		SoundManager.play_sound("page", -5.0)
	
	print("Сброс характеристик к дефолтным значениям...")
	
	var player_manager = get_node_or_null("/root/PlayerManager")
	if player_manager:
		var player_data = player_manager.get_player_data()
		if player_data:
			player_data.reset_stats_to_default()
			print("Характеристики сброшены к дефолтным значениям!")
			
			# Показываем сообщение об успехе
			_show_message("Характеристики сброшены к дефолтным значениям!")
		else:
			print("ОШИБКА: PlayerData не найден")
			_show_message("ОШИБКА: Данные игрока не найдены!")
	else:
		print("ОШИБКА: PlayerManager не найден")
		_show_message("ОШИБКА: Менеджер игрока не найден!")

func _show_message(text: String):
	"""Показывает сообщение пользователю"""
	var dialog = AcceptDialog.new()
	dialog.title = "Информация"
	dialog.dialog_text = text
	# AcceptDialog - это Window, popup автоматически отображается поверх всего
	add_child(dialog)
	dialog.popup_centered()
	dialog.connect("confirmed", Callable(dialog, "queue_free"))
	dialog.connect("canceled", Callable(dialog, "queue_free"))


func _on_ability_learning_button_pressed(initial_tab: int = 0):
	"""Открывает экран изучения пассивных способностей
	initial_tab: 0 = Обычные способности, 1 = Развитие души"""
	# Воспроизводим звук нажатия кнопки
	if SoundManager:
		SoundManager.play_sound("page", -5.0)
	
	# Загружаем сцену экрана изучения пассивных способностей
	var ability_learning_scene = preload("res://Scenes/UI/AbilityLearningScreen.tscn")
	var ability_learning_instance = ability_learning_scene.instantiate()
	ability_learning_instance.z_index = 100  # Поверх всего (NPC на 15, вихрь на 10)
	add_child(ability_learning_instance)
	
	# Устанавливаем начальную вкладку, если указана
	if ability_learning_instance.has_method("set_initial_tab"):
		ability_learning_instance.set_initial_tab(initial_tab)
	
	print("Открыт экран изучения пассивных способностей (вкладка: ", initial_tab, ")")

func _update_soul_shard_storage_display():
	"""Обновляет отображение количества осколков душ в хранилище"""
	var soul_shard_manager = get_node_or_null("/root/SoulShard")
	if soul_shard_manager and soul_shard_storage_label:
		var total_soul_shards = soul_shard_manager.get_soul_shards()
		soul_shard_storage_label.text = "Колодец душ: %d" % total_soul_shards

func _update_currency_display():
	"""Обновляет отображение всех валют"""
	# Обновляем сильные души
	var strong_souls_manager = get_node_or_null("/root/StrongSouls")
	if strong_souls_manager and strong_souls_label:
		var strong_souls = strong_souls_manager.get_strong_souls()
		strong_souls_label.text = "Сильные души: %d" % strong_souls
	
	# Обновляем великие души
	var great_souls_manager = get_node_or_null("/root/GreatSouls")
	if great_souls_manager and great_souls_label:
		var great_souls = great_souls_manager.get_great_souls()
		great_souls_label.text = "Великие души: %d" % great_souls
	
	# Обновляем божественные души
	var divine_souls_manager = get_node_or_null("/root/DivineSouls")
	if divine_souls_manager and divine_souls_label:
		var divine_souls = divine_souls_manager.get_divine_souls()
		divine_souls_label.text = "Божественные души: %d" % divine_souls

func _setup_soul_tooltips():
	"""Настраивает подсказки для различных типов душ"""
	# Подсказка для колодца душ (обычные осколки душ)
	if soul_shard_storage_label:
		soul_shard_storage_label.mouse_filter = Control.MOUSE_FILTER_STOP
		soul_shard_storage_label.tooltip_text = "Осколки душ - базовая валюта для изучения способностей.\nПолучаются за победу над любыми врагами."
	
	# Подсказка для сильных душ
	if strong_souls_label:
		strong_souls_label.mouse_filter = Control.MOUSE_FILTER_STOP
		strong_souls_label.tooltip_text = "Сильные души получаются за победу над элитными врагами.\nЭлитные враги доступны со 2 уровня сложности локации."
	
	# Подсказка для великих душ
	if great_souls_label:
		great_souls_label.mouse_filter = Control.MOUSE_FILTER_STOP
		great_souls_label.tooltip_text = "Великие души получаются за победу над финальным боссом локации.\nИспользуются для изучения мощных способностей."
	
	# Подсказка для божественных душ
	if divine_souls_label:
		divine_souls_label.mouse_filter = Control.MOUSE_FILTER_STOP
		divine_souls_label.tooltip_text = "Божественные души получаются за победу над мифическими врагами.\nБудут введены в следующих обновлениях."

func _initialize_character_music():
	"""Инициализирует музыку для экрана подготовки персонажа"""
	var music_player = get_node_or_null("/root/MusicPlayer")
	if music_player:
		# Загружаем музыкальный файл для подготовки персонажа
		var character_music = preload("res://Audio/Music/Background/Action 5 Loop.ogg")
		if character_music:
			# Проверяем, играет ли уже нужная музыка
			if not music_player.is_playing_music(character_music):
				music_player.play_music(character_music, true, true)  # fade_in=true, crossfade=true
			else:
				pass  # Музыка уже играет
		else:
			print("Музыкальный файл не найден: res://Audio/Music/Background/Action 5 Loop.ogg")
	else:
		print("MusicPlayer не найден в автозагрузках")

func _exit_tree() -> void:
	"""Очистка при выходе из сцены"""
	if soul_vortex:
		if soul_vortex.has_method("cleanup"):
			soul_vortex.cleanup()
		soul_vortex.queue_free()
	
	if soul_sculptor:
		soul_sculptor.queue_free()

func _style_journey_button():
	"""Стилизует кнопку 'Отправиться в путешествие' в стиле dark fantasy"""
	# Увеличиваем размер кнопки и опускаем ниже
	start_journey_button.custom_minimum_size = Vector2(350, 80)
	start_journey_button.size = Vector2(350, 80)
	start_journey_button.position.y += 80  # Опускаем на 80 пикселей ниже
	
	# Создаем темный фон в стиле dark fantasy
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.08, 0.08, 0.12, 0.95)  # Очень темный, почти черный
	normal_style.border_color = Color(0.2, 0.5, 0.7, 1.0)  # Голубая рамка
	normal_style.border_width_left = 3
	normal_style.border_width_right = 3
	normal_style.border_width_top = 3
	normal_style.border_width_bottom = 3
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	normal_style.shadow_size = 10
	normal_style.shadow_color = Color(0.1, 0.3, 0.5, 0.5)  # Голубоватая тень
	normal_style.shadow_offset = Vector2(0, 3)
	
	# Стиль при наведении - более яркий, но все еще темный
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.12, 0.15, 0.2, 0.98)  # Темно-синеватый оттенок
	hover_style.border_color = Color(0.3, 0.7, 0.9, 1.0)  # Яркая голубая рамка
	hover_style.border_width_left = 4
	hover_style.border_width_right = 4
	hover_style.border_width_top = 4
	hover_style.border_width_bottom = 4
	hover_style.corner_radius_top_left = 8
	hover_style.corner_radius_top_right = 8
	hover_style.corner_radius_bottom_left = 8
	hover_style.corner_radius_bottom_right = 8
	hover_style.shadow_size = 15
	hover_style.shadow_color = Color(0.2, 0.6, 0.9, 0.6)  # Голубое свечение
	hover_style.shadow_offset = Vector2(0, 0)
	
	# Стиль при нажатии - еще темнее
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.05, 0.05, 0.08, 1.0)  # Почти черный
	pressed_style.border_color = Color(0.15, 0.4, 0.6, 1.0)  # Темно-голубая рамка
	pressed_style.border_width_left = 2
	pressed_style.border_width_right = 2
	pressed_style.border_width_top = 2
	pressed_style.border_width_bottom = 2
	pressed_style.corner_radius_top_left = 8
	pressed_style.corner_radius_top_right = 8
	pressed_style.corner_radius_bottom_left = 8
	pressed_style.corner_radius_bottom_right = 8
	pressed_style.shadow_size = 5
	pressed_style.shadow_color = Color(0, 0, 0, 0.9)
	pressed_style.shadow_offset = Vector2(0, 1)
	
	# Применяем стили
	start_journey_button.add_theme_stylebox_override("normal", normal_style)
	start_journey_button.add_theme_stylebox_override("hover", hover_style)
	start_journey_button.add_theme_stylebox_override("pressed", pressed_style)
	
	# Настраиваем текст в стиле dark fantasy
	start_journey_button.add_theme_font_size_override("font_size", 20)
	start_journey_button.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95, 1.0))  # Легкий голубоватый оттенок
	start_journey_button.add_theme_color_override("font_hover_color", Color(0.9, 0.95, 1.0, 1.0))  # Светло-голубой при наведении
	start_journey_button.add_theme_color_override("font_pressed_color", Color(0.7, 0.75, 0.8, 1.0))  # Приглушенный при нажатии
	
	# Добавляем голубоватую тень для текста
	start_journey_button.add_theme_color_override("font_shadow_color", Color(0.0, 0.2, 0.4, 0.8))
	start_journey_button.add_theme_constant_override("shadow_offset_x", 2)
	start_journey_button.add_theme_constant_override("shadow_offset_y", 2)

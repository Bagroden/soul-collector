# Scripts/UI/AbilityLearningWindow.gd
class_name AbilityLearningWindow
extends Control

@onready var ability_list = $VBoxContainer/ScrollContainer/AbilityList
@onready var close_button = $VBoxContainer/CloseButton
@onready var close_button_top = $CloseButtonTop

var ability_learning_system: Node

func _ready():
	# Получаем ссылку на систему изучения способностей
	ability_learning_system = get_node_or_null("/root/AbilityLearningSystem")
	
	# Если система не найдена, создаем её
	if not ability_learning_system:
		print("AbilityLearningSystem не найден, создаем систему...")
		var system_script = preload("res://Scripts/Systems/AbilityLearningSystem.gd")
		ability_learning_system = Node.new()
		ability_learning_system.set_script(system_script)
		ability_learning_system.name = "AbilityLearningSystem"
		get_tree().root.add_child(ability_learning_system)
		await get_tree().process_frame
		print("AbilityLearningSystem создан и добавлен в сцену")
	
	# Подписываемся на события изучения
	ability_learning_system.ability_learned.connect(_on_ability_learned)
	ability_learning_system.progress_updated.connect(_on_progress_updated)
	
	# Настраиваем кнопки закрытия
	close_button.pressed.connect(_on_close_button_pressed)
	close_button_top.pressed.connect(_on_close_button_pressed)
	
	# Загружаем список способностей
	_load_ability_list()
	
	# Делаем окно модальным и устанавливаем фокус
	set_process_unhandled_key_input(true)

func _unhandled_key_input(event):
	"""Обработка нажатий клавиш"""
	if event.pressed and event.keycode == KEY_ESCAPE:
		_on_close_button_pressed()

func _load_ability_list():
	"""Загружает список способностей для изучения"""
	# Очищаем список
	for child in ability_list.get_children():
		child.queue_free()
	
	# Получаем конфигурацию способностей
	var config = ability_learning_system.ability_learning_config
	
	for ability_id in config:
		var ability_config = config[ability_id]
		_create_ability_item(ability_id, ability_config)

func _create_ability_item(ability_id: String, ability_config: Dictionary):
	"""Создает элемент списка для способности"""
	var item = HBoxContainer.new()
	ability_list.add_child(item)
	
	# Название способности
	var name_label = Label.new()
	name_label.text = ability_config.name
	name_label.custom_minimum_size.x = 200
	item.add_child(name_label)
	
	# Прогресс изучения
	var progress = ability_learning_system.get_ability_progress(ability_id)
	var progress_label = Label.new()
	progress_label.text = str(int(progress.current_progress)) + "/" + str(int(ability_config.required_progress)) + "%"
	progress_label.custom_minimum_size.x = 100
	item.add_child(progress_label)
	
	# Прогресс-бар
	var progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = ability_config.required_progress
	progress_bar.value = progress.current_progress
	progress_bar.custom_minimum_size.x = 200
	item.add_child(progress_bar)
	
	# Статус изучения
	var status_label = Label.new()
	if progress.is_learned:
		status_label.text = "✅ Изучена"
		status_label.modulate = Color.GREEN
	else:
		status_label.text = "❌ Не изучена"
		status_label.modulate = Color.RED
	item.add_child(status_label)
	
	# Кнопка изучения (если способность изучена и еще не добавлена в пассивные способности игрока)
	if progress.is_learned:
		# Проверяем, не добавлена ли уже способность в пассивные способности игрока
		var player_manager = get_node_or_null("/root/PlayerManager")
		var already_learned = false
		
		if player_manager:
			var player_data = player_manager.get_player_data()
			if player_data:
				var learned_passives = player_data.get_learned_passives()
				var ability_mapping = {
					"rat_vitality": "player_rat_vitality",
					"dodge": "dodge",
					"blood_flow": "blood_flow",
					"agility": "player_agility",
					"cornered": "player_cornered"
				}
				var player_ability_id = ability_mapping.get(ability_id)
				if player_ability_id and player_ability_id in learned_passives:
					already_learned = true
		
		if not already_learned:
			var learn_button = Button.new()
			learn_button.text = "Изучить"
			learn_button.custom_minimum_size.x = 80
			learn_button.add_theme_color_override("font_color", Color.CYAN)
			learn_button.pressed.connect(_on_learn_ability_button_pressed.bind(ability_id))
			item.add_child(learn_button)
		else:
			# Показываем статус "Уже изучена"
			var menu_status_label = Label.new()
			menu_status_label.text = "✅ В меню"
			menu_status_label.add_theme_color_override("font_color", Color.GREEN)
			menu_status_label.custom_minimum_size.x = 80
			item.add_child(menu_status_label)
	
	# Кнопка деталей
	var details_button = Button.new()
	details_button.text = "Детали"
	details_button.pressed.connect(_on_details_button_pressed.bind(ability_id))
	item.add_child(details_button)

func _on_ability_learned(ability_id: String, _progress: int):
	"""Обработка изучения новой способности"""
	var ability_name = ability_learning_system.ability_learning_config[ability_id].name
	_show_notification("🎉 Изучена новая способность: " + ability_name)
	
	# Обновляем список
	_load_ability_list()

func _on_progress_updated(_ability_id: String, _progress: int):
	"""Обновление прогресса изучения"""
	# Обновляем список способностей
	_load_ability_list()

func _on_details_button_pressed(ability_id: String):
	"""Показывает детали способности"""
	var ability_config = ability_learning_system.ability_learning_config[ability_id]
	var progress = ability_learning_system.get_ability_progress(ability_id)
	
	var details_text = "=== ДЕТАЛИ СПОСОБНОСТИ ===\n"
	details_text += "Название: " + ability_config.name + "\n"
	details_text += "Прогресс: " + str(int(progress.current_progress)) + "/" + str(int(ability_config.required_progress)) + "%\n"
	details_text += "Статус: " + ("Изучена" if progress.is_learned else "Не изучена") + "\n"
	
	if progress.is_learned:
		details_text += "Изучена: " + str(progress.learned_at) + "\n"
	
	details_text += "\nИсточники прогресса:\n"
	for source in ability_config.sources:
		details_text += "  - " + source + ": " + str(ability_config.sources[source]) + "%\n"
	
	_show_details_dialog(details_text)

func _show_details_dialog(text: String):
	"""Показывает диалог с деталями"""
	var dialog = AcceptDialog.new()
	dialog.title = "Детали способности"
	dialog.dialog_text = text
	dialog.size = Vector2(400, 300)
	add_child(dialog)
	dialog.popup_centered()
	
	# Автоматически закрываем диалог через 5 секунд
	await get_tree().create_timer(5.0).timeout
	if dialog and is_instance_valid(dialog):
		dialog.queue_free()

func _show_notification(text: String):
	"""Показывает уведомление"""
	var notification_label = Label.new()
	notification_label.text = text
	notification_label.add_theme_color_override("font_color", Color.YELLOW)
	notification_label.add_theme_font_size_override("font_size", 16)
	notification_label.position = Vector2(50, 50)
	add_child(notification_label)
	
	# Анимация появления
	var tween = create_tween()
	tween.tween_property(notification_label, "modulate:a", 1.0, 0.5)
	tween.tween_interval(2.0)  # Используем tween_interval вместо tween_delay
	tween.tween_property(notification_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(notification_label.queue_free)

func _on_learn_ability_button_pressed(ability_id: String):
	"""Обрабатывает изучение способности игроком"""
	# Получаем менеджер игрока
	var player_manager = get_node_or_null("/root/PlayerManager")
	if not player_manager:
		_show_notification("❌ Ошибка: PlayerManager не найден!")
		return
	
	var player_data = player_manager.get_player_data()
	if not player_data:
		_show_notification("❌ Ошибка: Данные игрока не найдены!")
		return
	
	# Проверяем, что способность действительно изучена
	if not ability_learning_system.is_ability_learned(ability_id):
		_show_notification("❌ Способность еще не изучена!")
		return
	
	# Добавляем способность в изученные пассивные способности игрока
	var success = _add_learned_ability_to_player(ability_id, player_data)
	
	if success:
		_show_notification("✅ Способность добавлена в меню пассивных способностей!")
		_load_ability_list()
		_refresh_passive_abilities_window()
		
		# Сохраняем данные игрока после изучения способности
		if player_manager:
			player_manager.save_game_data()
	else:
		_show_notification("❌ Ошибка при добавлении способности!")

func _add_learned_ability_to_player(ability_id: String, player_data) -> bool:
	"""Добавляет изученную способность в систему пассивных способностей игрока"""
	# Маппинг способностей врагов на способности игрока
	var ability_mapping = {
		"rat_vitality": "player_rat_vitality",      # Крысиная живучесть -> Крысиная живучесть игрока
		"dodge": "dodge",                           # Уворот -> Уворот (оригинальная способность)
		"blood_flow": "blood_flow",                 # Кровоток -> Кровоток (оригинальная способность)
		"agility": "player_agility",                # Изворотливость -> Изворотливость игрока
		"cornered": "player_cornered"               # Загнанный в угол -> Загнанный в угол игрока
	}
	
	# Получаем соответствующую способность игрока
	var player_ability_id = ability_mapping.get(ability_id)
	
	if not player_ability_id:
		return false
	
	# Проверяем, не изучена ли уже эта способность
	var learned_passives = player_data.get_learned_passives()
	
	if player_ability_id in learned_passives:
		_show_notification("ℹ️ Способность уже добавлена в меню пассивных способностей!")
		return false
	
	# Изучаем способность
	var _learn_result = player_data.learn_passive_ability(player_ability_id)
	
	# Проверяем, что способность действительно добавлена
	var updated_learned_passives = player_data.get_learned_passives()
	
	return player_ability_id in updated_learned_passives

func _refresh_passive_abilities_window():
	"""Обновляет окно пассивных способностей, если оно открыто"""
	var passive_window = get_node_or_null("/root/CharacterPreparation/PassiveAbilitiesWindow")
	if passive_window and passive_window.has_method("update_ui"):
		passive_window.update_ui()

func _on_close_button_pressed():
	"""Закрывает окно изучения способностей"""
	queue_free()

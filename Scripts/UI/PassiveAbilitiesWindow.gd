# res://Scripts/UI/PassiveAbilitiesWindow.gd
extends Control

# UI элементы
@onready var abilities_grid: GridContainer = $MainPanel/VBoxContainer/ContentContainer/AbilitiesGrid
@onready var search_line_edit: LineEdit = $MainPanel/VBoxContainer/ControlsPanel/SearchContainer/SearchLineEdit
@onready var filter_option_button: OptionButton = $MainPanel/VBoxContainer/ControlsPanel/FilterContainer/FilterOptionButton
@onready var enable_all_button: Button = $MainPanel/VBoxContainer/ControlsPanel/QuickActionsContainer/EnableAllButton
@onready var disable_all_button: Button = $MainPanel/VBoxContainer/ControlsPanel/QuickActionsContainer/DisableAllButton
@onready var info_label: Label = $MainPanel/VBoxContainer/Footer/InfoLabel
@onready var close_button: Button = $MainPanel/VBoxContainer/Header/CloseButton
@onready var close_button_footer: Button = $MainPanel/VBoxContainer/Footer/CloseButton2
@onready var learn_button: Button = $MainPanel/VBoxContainer/Footer/LearnButton

# Данные
var player_data: PlayerData
var passive_abilities: Array[Dictionary] = []
var filtered_abilities: Array[Dictionary] = []

# Цвета для редкости
var rarity_colors = {
	"common": Color.WHITE,
	"uncommon": Color.GREEN,
	"rare": Color.BLUE,
	"epic": Color.PURPLE,
	"legendary": Color.ORANGE,
	"mythic": Color.RED
}

# Цвета фона для редкости
var rarity_bg_colors = {
	"common": Color(0.2, 0.2, 0.2, 0.8),
	"uncommon": Color(0.1, 0.3, 0.1, 0.8),
	"rare": Color(0.1, 0.1, 0.3, 0.8),
	"epic": Color(0.3, 0.1, 0.3, 0.8),
	"legendary": Color(0.4, 0.2, 0.1, 0.8),
	"mythic": Color(0.4, 0.1, 0.1, 0.8)
}

func _ready():
	# Подключаем сигналы
	close_button.pressed.connect(_on_close_button_pressed)
	close_button_footer.pressed.connect(_on_close_button_pressed)
	learn_button.pressed.connect(_on_learn_button_pressed)
	search_line_edit.text_changed.connect(_on_search_text_changed)
	filter_option_button.item_selected.connect(_on_filter_selected)
	enable_all_button.pressed.connect(_on_enable_all_pressed)
	disable_all_button.pressed.connect(_on_disable_all_pressed)
	
	# Инициализируем фильтры
	_setup_filters()
	
	# Получаем данные игрока
	player_data = PlayerManager.get_player_data()
	
	# Подписываемся на изменение духовной мощи
	if player_data:
		player_data.spiritual_power_changed.connect(_on_spiritual_power_changed)
	
	# Инициализируем систему пассивных способностей
	player_data.initialize_passive_system()
	
	# Загружаем пассивные способности
	load_passive_abilities()
	
	# Обновляем UI
	update_ui()

func _setup_filters():
	"""Настраиваем фильтры"""
	filter_option_button.add_item("Все", 0)
	filter_option_button.add_item("Common", 1)
	filter_option_button.add_item("Uncommon", 2)
	filter_option_button.add_item("Rare", 3)
	filter_option_button.add_item("Epic", 4)
	filter_option_button.add_item("Legendary", 5)

func load_passive_abilities():
	"""Загружаем пассивные способности игрока"""
	# Синхронизируем активные способности с фактическими бонусами
	player_data.sync_active_passives_with_bonuses()
	
	# Получаем доступные способности для UI
	passive_abilities = player_data.get_available_passives_for_ui()
	
	# Применяем фильтры
	apply_filters()

func apply_filters():
	"""Применяем фильтры к списку способностей"""
	filtered_abilities.clear()
	
	var search_text = search_line_edit.text.to_lower()
	var selected_filter = filter_option_button.get_selected_id()
	
	for ability in passive_abilities:
		# Фильтр по тексту
		if search_text != "" and not ability.name.to_lower().contains(search_text):
			continue
		
		# Фильтр по редкости
		if selected_filter > 0:
			var rarity_map = ["", "common", "uncommon", "rare", "epic", "legendary"]
			if ability.rarity != rarity_map[selected_filter]:
				continue
		
		filtered_abilities.append(ability)

func update_ui():
	"""Обновляем интерфейс"""
	update_abilities_grid()
	update_info_label()

func update_abilities_grid():
	"""Обновляем сетку способностей"""
	# Очищаем сетку
	for child in abilities_grid.get_children():
		child.queue_free()
	
	# Настраиваем отступы в сетке
	abilities_grid.add_theme_constant_override("h_separation", 10)  # Горизонтальные отступы
	abilities_grid.add_theme_constant_override("v_separation", 10)  # Вертикальные отступы
	
	# Добавляем карточки способностей
	for ability_data in filtered_abilities:
		create_ability_card(ability_data)

func create_ability_card(ability_data: Dictionary):
	"""Создаем карточку способности"""
	var card = Panel.new()
	card.custom_minimum_size = Vector2(280, 130)  # Увеличили высоту карточки
	abilities_grid.add_child(card)
	
	# Настройка стиля карточки
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = rarity_bg_colors.get(ability_data.rarity, Color(0.2, 0.2, 0.2, 0.8))
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = rarity_colors.get(ability_data.rarity, Color.WHITE)
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	card.add_theme_stylebox_override("panel", style_box)
	
	# Основной контейнер
	var main_container = VBoxContainer.new()
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_container.offset_left = 10
	main_container.offset_top = 10
	main_container.offset_right = -10
	main_container.offset_bottom = -10
	card.add_child(main_container)
	
	# Заголовок с названием и редкостью
	var header_container = HBoxContainer.new()
	main_container.add_child(header_container)
	
	var name_label = Label.new()
	# Добавляем уровень к названию способности
	var level_text = ""
	if ability_data.has("level") and ability_data.level > 0:
		level_text = " (ур. " + str(ability_data.level) + ")"
	name_label.text = ability_data.name + level_text
	name_label.add_theme_color_override("font_color", rarity_colors.get(ability_data.rarity, Color.WHITE))
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_container.add_child(name_label)
	
	var rarity_label = Label.new()
	rarity_label.text = ability_data.rarity.capitalize()
	rarity_label.add_theme_color_override("font_color", rarity_colors.get(ability_data.rarity, Color.WHITE))
	rarity_label.add_theme_font_size_override("font_size", 10)
	header_container.add_child(rarity_label)
	
	# Стоимость духовной мощи
	var cost_label = Label.new()
	var spiritual_cost = player_data.get_spiritual_power_cost(ability_data.rarity)
	cost_label.text = " [" + str(spiritual_cost) + " ДМ]"
	cost_label.add_theme_color_override("font_color", Color.YELLOW)
	cost_label.add_theme_font_size_override("font_size", 10)
	header_container.add_child(cost_label)
	
	# Контейнер для описания с фиксированной высотой
	var desc_container = VBoxContainer.new()
	desc_container.custom_minimum_size = Vector2(0, 60)  # Фиксированная высота для описания
	desc_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.add_child(desc_container)
	
	# Описание с учетом уровня
	var desc_label = Label.new()
	var description = ability_data.description
	
	# Получаем конфигурацию способности из AbilityLearningSystem для динамических описаний
	if AbilityLearningSystem:
		var ability_config = AbilityLearningSystem.ability_learning_config.get(ability_data.id, {})
		if ability_config.has("description"):
			description = ability_config.get("description", ability_data.description)
		
		var level_values = ability_config.get("level_values", [])
		var current_level = ability_data.get("level", 0)
		
		# Если есть значения для уровней, показываем описание с соответствующим значением
		if level_values.size() > 0 and current_level > 0:
			var value_to_show = level_values[min(current_level - 1, level_values.size() - 1)]
			# Заменяем плейсхолдер X на актуальное значение
			description = description.replace("X", str(value_to_show))
			
			# Проверяем, есть ли вторичные значения (для способностей с двумя параметрами)
			var level_values_secondary = ability_config.get("level_values_secondary", [])
			if level_values_secondary.size() > 0:
				var secondary_value_to_show = level_values_secondary[min(current_level - 1, level_values_secondary.size() - 1)]
				# Заменяем плейсхолдер Y на вторичное значение
				description = description.replace("Y", str(secondary_value_to_show))
	
	desc_label.text = description
	desc_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	desc_container.add_child(desc_label)
	
	# Кнопка переключения
	var toggle_button = Button.new()
	toggle_button.text = "АКТИВНА" if ability_data.is_active else "НЕАКТИВНА"
	toggle_button.custom_minimum_size = Vector2(0, 25)  # Уменьшили высоту кнопки
	toggle_button.add_theme_font_size_override("font_size", 11)  # Уменьшили размер шрифта
	
	# Стиль кнопки в зависимости от состояния
	var button_style = StyleBoxFlat.new()
	if ability_data.is_active:
		button_style.bg_color = Color(0.2, 0.6, 0.2, 0.8)
		toggle_button.add_theme_color_override("font_color", Color.WHITE)
	else:
		button_style.bg_color = Color(0.4, 0.4, 0.4, 0.8)
		toggle_button.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	
	button_style.corner_radius_top_left = 4
	button_style.corner_radius_top_right = 4
	button_style.corner_radius_bottom_left = 4
	button_style.corner_radius_bottom_right = 4
	toggle_button.add_theme_stylebox_override("normal", button_style)
	
	toggle_button.pressed.connect(_on_toggle_passive.bind(ability_data.id))
	main_container.add_child(toggle_button)

func _on_toggle_passive(ability_id: String):
	"""Переключаем состояние пассивной способности"""
	# Проверяем, активирует ли игрок способность или деактивирует
	var is_activating = ability_id not in player_data.active_passives
	
	if is_activating:
		# Проверяем, можно ли активировать
		var check_result = player_data.can_activate_passive(ability_id)
		if not check_result.can_activate:
			_show_error_message(check_result.reason)
			return
	
	var success = player_data.toggle_passive_ability(ability_id)
	if success:
		# Перезагружаем данные и обновляем UI
		load_passive_abilities()
		update_ui()
		
		
		# Сохраняем игру после изменения пассивных способностей
		var player_manager = get_node_or_null("/root/PlayerManager")
		if player_manager:
			player_manager.save_game_data()

func _on_spiritual_power_changed(_current: int, _max_power: int, _used: int):
	"""Обработка изменения духовной мощи"""
	update_info_label()

func _show_error_message(message: String):
	"""Показывает сообщение об ошибке"""
	var dialog = AcceptDialog.new()
	dialog.title = "Ошибка активации"
	dialog.dialog_text = message
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)

func _on_search_text_changed(_new_text: String):
	"""Обработка изменения текста поиска"""
	apply_filters()
	update_ui()

func _on_filter_selected(_index: int):
	"""Обработка выбора фильтра"""
	apply_filters()
	update_ui()

func _on_enable_all_pressed():
	"""Включаем все способности"""
	for ability in filtered_abilities:
		if not ability.is_active:
			player_data.activate_passive_ability(ability.id)
	
	load_passive_abilities()
	update_ui()
	
	
	# Сохраняем игру
	var player_manager = get_node_or_null("/root/PlayerManager")
	if player_manager:
		player_manager.save_game_data()

func _on_disable_all_pressed():
	"""Выключаем все способности"""
	for ability in filtered_abilities:
		if ability.is_active:
			player_data.deactivate_passive_ability(ability.id)
	
	load_passive_abilities()
	update_ui()
	
	
	# Сохраняем игру
	var player_manager = get_node_or_null("/root/PlayerManager")
	if player_manager:
		player_manager.save_game_data()

func update_info_label():
	"""Обновляем информационную метку"""
	var active_count = 0
	var total_count = passive_abilities.size()
	
	for passive_data in passive_abilities:
		if passive_data.is_active:
			active_count += 1
	
	# Получаем информацию о духовной мощи
	var spiritual_power_text = ""
	if player_data:
		var available = player_data.spiritual_power
		var max_power = player_data.max_spiritual_power
		var used = player_data.used_spiritual_power
		spiritual_power_text = " | Духовная мощь: %d / %d (использовано: %d)" % [available, max_power, used]
	
	info_label.text = "Активных способностей: " + str(active_count) + " из " + str(total_count) + spiritual_power_text

func _on_learn_button_pressed():
	"""Изучаем базовые пассивные способности"""
	# Изучаем базовые способности
	var abilities_to_learn = ["player_fortress", "player_strong", "player_wise", "player_vitality"]
	var _learned_count = 0
	
	for ability_id in abilities_to_learn:
		var success = player_data.learn_passive_ability(ability_id)
		if success:
			_learned_count += 1
	
	# Обновляем UI
	load_passive_abilities()
	update_ui()
	
	# Сохраняем игру после изучения новых способностей
	var player_manager = get_node_or_null("/root/PlayerManager")
	if player_manager:
		player_manager.save_game_data()

func _on_close_button_pressed():
	"""Закрываем окно"""
	# Сохраняем игру перед закрытием окна
	var player_manager = get_node_or_null("/root/PlayerManager")
	if player_manager:
		player_manager.save_game_data()
	
	queue_free()


func show_window():
	"""Показываем окно"""
	visible = true
	# Обновляем данные при показе
	load_passive_abilities()
	update_ui()

func hide_window():
	"""Скрываем окно"""
	visible = false

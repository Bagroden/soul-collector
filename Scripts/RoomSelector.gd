# res://Scripts/RoomSelector.gd
extends Control

@onready var room_name_label = $VBoxContainer/CurrentRoomInfo/RoomName
@onready var room_description_label = $VBoxContainer/CurrentRoomInfo/RoomDescription
@onready var room_options_container = $VBoxContainer/RoomOptions
@onready var progress_bar = $VBoxContainer/ProgressInfo/ProgressBar
@onready var btn_back = $VBoxContainer/HBoxContainer/Btn_Back
@onready var background_texture = $Background

var room_generator
var location_manager

# Маппинг локаций на фоны
var location_backgrounds: Dictionary = {
	"dungeon": "res://Assets/Backgrounds/Dungeon_under_town4.png",
	"forest": "res://Assets/Backgrounds/Darkforest2.png",
	"dark_forest": "res://Assets/Backgrounds/Darkforest2.png",
	"cemetery": "res://Assets/Backgrounds/Cemetery2.png",  # Заброшенное кладбище
	"demon_lair": "res://Assets/Backgrounds/Demon_citadel_rooms.png",
	"sinister_swamps": "res://Assets/Backgrounds/Swampland2.png",
}

func _ready():
	# Скрываем блок с информацией о текущей комнате (он не нужен при выборе)
	var current_room_info = $VBoxContainer/CurrentRoomInfo
	if current_room_info:
		current_room_info.visible = false
	
	# Подключаем сигналы
	btn_back.connect("pressed", Callable(self, "_on_back_pressed"))
	
	# Улучшаем дизайн кнопки возврата
	_style_back_button()
	
	# Получаем менеджеры
	location_manager = get_node_or_null("/root/LocationManager")
	if not location_manager:
		# Создаем менеджер если его нет
		var script = load("res://Scripts/LocationManagerAutoload.gd")
		location_manager = Node.new()
		location_manager.set_script(script)
		location_manager.name = "LocationManager"
		get_tree().root.add_child(location_manager)
		await get_tree().process_frame
	
	# Получаем или создаем генератор комнат
	room_generator = get_node_or_null("/root/RoomGenerator")
	if not room_generator:
		# Создаем глобальный генератор комнат
		room_generator = RoomGenerator.new()
		room_generator.name = "RoomGenerator"
		get_tree().root.add_child(room_generator)
		await get_tree().process_frame
	
	# Подключаем сигналы генератора (только если не подключены)
	if not room_generator.is_connected("room_cleared", Callable(self, "_on_room_cleared")):
		room_generator.connect("room_cleared", Callable(self, "_on_room_cleared"))
	if not room_generator.is_connected("location_completed", Callable(self, "_on_location_completed")):
		room_generator.connect("location_completed", Callable(self, "_on_location_completed"))
	
	# Устанавливаем бэкграунд в зависимости от локации
	_update_background()
	
	# Начинаем локацию
	_start_location()
	
	# Проверяем, есть ли результат последнего боя
	_check_battle_result()

func _start_location():
	var current_location = location_manager.current_location
	if current_location:
		# Проверяем, нужно ли сбросить прогресс (новая локация)
		var should_reset = (room_generator.current_location == null or room_generator.current_location.location_id != current_location.location_id)
		if should_reset:
			room_generator.reset_location_progress()
		
		# Устанавливаем флаг прохождения локации
		var player_manager = get_node_or_null("/root/PlayerManager")
		if player_manager:
			player_manager.set_in_location(true)
		
		room_generator.start_location(current_location)
		_show_current_room()
		_show_room_options()

func _show_current_room():
	# Проверяем, что room_generator еще существует
	if not is_instance_valid(room_generator):
		return
	
	var current_room = room_generator.get_current_room()
	if current_room:
		room_name_label.text = current_room.room_name
		room_description_label.text = current_room.description
		
		# Обновляем прогресс
		_update_progress_bar()

func _update_progress_bar():
	# Проверяем, что room_generator еще существует
	if not is_instance_valid(room_generator):
		return
	
	# Обновляем прогресс бар с красивым дизайном
	var rooms_cleared = room_generator.rooms_cleared
	var max_rooms = room_generator.max_rooms
	var progress_percent = (float(rooms_cleared) / float(max_rooms)) * 100.0
	
	# Проверяем, что прогресс бар существует
	if not progress_bar:
		print("ОШИБКА: progress_bar не найден!")
		return
	
	# Принудительно обновляем прогресс бар
	progress_bar.value = rooms_cleared
	progress_bar.max_value = max_rooms
	
	# Улучшаем стиль прогресс-бара
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	bg_style.border_width_left = 2
	bg_style.border_width_top = 2
	bg_style.border_width_right = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(0.4, 0.4, 0.6, 1.0)
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_right = 8
	bg_style.corner_radius_bottom_left = 8
	progress_bar.add_theme_stylebox_override("background", bg_style)
	
	var fill_style = StyleBoxFlat.new()
	# Градиент от синего к фиолетовому
	var fill_color = Color(0.3, 0.6, 1.0, 1.0)  # Яркий синий
	if progress_percent > 50:
		fill_color = Color(0.6, 0.4, 1.0, 1.0)  # Фиолетовый для большей части
	if progress_percent > 80:
		fill_color = Color(1.0, 0.7, 0.3, 1.0)  # Золотой для почти завершенного
	fill_style.bg_color = fill_color
	fill_style.corner_radius_top_left = 6
	fill_style.corner_radius_top_right = 6
	fill_style.corner_radius_bottom_right = 6
	fill_style.corner_radius_bottom_left = 6
	progress_bar.add_theme_stylebox_override("fill", fill_style)
	
	# Устанавливаем минимальную высоту
	progress_bar.custom_minimum_size = Vector2(0, 30)
	
	# Обновляем текст прогресса если есть
	var progress_label = $VBoxContainer/ProgressInfo/ProgressLabel
	if progress_label:
		progress_label.text = "📊 Прогресс: " + str(rooms_cleared) + "/" + str(max_rooms) + " (" + str(int(progress_percent)) + "%)"
		progress_label.add_theme_font_size_override("font_size", 16)
		progress_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.85, 1.0))
		progress_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		progress_label.add_theme_constant_override("shadow_offset_x", 1)
		progress_label.add_theme_constant_override("shadow_offset_y", 1)
	

func _show_room_options():
	# Проверяем, что room_generator еще существует
	if not is_instance_valid(room_generator):
		return
	
	# Очищаем контейнер опций
	for child in room_options_container.get_children():
		child.queue_free()
	
	# Получаем варианты комнат
	var options = room_generator.generate_next_room_options()
	
	# Создаем горизонтальный контейнер для карточек
	var cards_container = HBoxContainer.new()
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_container.add_theme_constant_override("separation", 20)
	cards_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	room_options_container.add_child(cards_container)
	
	# Создаем карточки для каждого варианта
	for i in range(options.size()):
		var room = options[i]
		var room_card = _create_room_card(room, i)
		cards_container.add_child(room_card)

func _create_room_card(room: RoomData, index: int) -> Control:
	"""Создает красивую карточку комнаты с современным дизайном"""
	# Получаем информацию о комнате
	var is_quest = room.get("is_quest_room") if room.get("is_quest_room") != null else false
	var room_type = room.room_type
	var enemy_rarity = room.enemy_rarity if room.enemy_rarity else "common"
	
	# Получаем уровень способности "Видящий"
	var seer_level = _get_seer_level()
	
	# Получаем цветовую схему и иконку для комнаты
	# Если уровень "Видящий" < 2, скрываем редкость (используем нейтральный стиль)
	var room_style = _get_room_style(room_type, enemy_rarity, is_quest, seer_level)
	
	# Основной контейнер карточки
	var card_container = PanelContainer.new()
	card_container.custom_minimum_size = Vector2(320, 480)
	card_container.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Стиль панели карточки
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = room_style.bg_color
	panel_style.border_width_left = room_style.border_width
	panel_style.border_width_top = room_style.border_width
	panel_style.border_width_right = room_style.border_width
	panel_style.border_width_bottom = room_style.border_width
	panel_style.border_color = room_style.border_color
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel_style.shadow_color = Color(0, 0, 0, 0.6)
	panel_style.shadow_size = 12
	panel_style.shadow_offset = Vector2(0, 4)
	card_container.add_theme_stylebox_override("panel", panel_style)
	
	# Добавляем эффект свечения для особых комнат
	if room_style.has_glow:
		_add_room_glow_effect(card_container, room_style.glow_color)
	
	# Внутренний контейнер с отступами
	var inner_container = VBoxContainer.new()
	inner_container.add_theme_constant_override("separation", 12)
	inner_container.add_theme_constant_override("margin_left", 20)
	inner_container.add_theme_constant_override("margin_top", 20)
	inner_container.add_theme_constant_override("margin_right", -20)
	inner_container.add_theme_constant_override("margin_bottom", -20)
	card_container.add_child(inner_container)
	
	# Заголовок направления
	var direction_label = Label.new()
	var directions = ["← НАЛЕВО", "↑ ПРЯМО", "→ НАПРАВО"]
	direction_label.text = directions[index] if index < directions.size() else "НАПРАВЛЕНИЕ " + str(index + 1)
	direction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	direction_label.add_theme_font_size_override("font_size", 16)
	direction_label.add_theme_color_override("font_color", room_style.direction_color)
	inner_container.add_child(direction_label)
	
	# Декоративная линия
	var line = ColorRect.new()
	line.custom_minimum_size = Vector2(0, 2)
	line.color = room_style.border_color
	line.color.a = 0.5
	inner_container.add_child(line)
	
	# Метка типа комнаты (если есть)
	if room_style.type_label != "":
		var type_label = Label.new()
		type_label.text = room_style.type_label
		type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		type_label.add_theme_font_size_override("font_size", 14)
		type_label.add_theme_color_override("font_color", room_style.type_label_color)
		if room_style.has_shadow:
			type_label.add_theme_color_override("font_shadow_color", room_style.shadow_color)
			type_label.add_theme_constant_override("shadow_offset_x", 1)
			type_label.add_theme_constant_override("shadow_offset_y", 1)
		inner_container.add_child(type_label)
	
	# Название комнаты с иконкой
	var name_label = Label.new()
	name_label.text = room_style.icon + " " + room.room_name + " " + room_style.icon
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", room_style.font_size)
	name_label.add_theme_color_override("font_color", room_style.name_color)
	if room_style.has_shadow:
		name_label.add_theme_color_override("font_shadow_color", room_style.shadow_color)
		name_label.add_theme_constant_override("shadow_offset_x", 2)
		name_label.add_theme_constant_override("shadow_offset_y", 2)
	inner_container.add_child(name_label)
	
	# Описание комнаты в контейнере
	var desc_container = PanelContainer.new()
	var desc_style = StyleBoxFlat.new()
	desc_style.bg_color = Color(0, 0, 0, 0.3)
	desc_style.corner_radius_top_left = 8
	desc_style.corner_radius_top_right = 8
	desc_style.corner_radius_bottom_right = 8
	desc_style.corner_radius_bottom_left = 8
	desc_container.add_theme_stylebox_override("panel", desc_style)
	desc_container.custom_minimum_size = Vector2(0, 100)
	inner_container.add_child(desc_container)
	
	# Получаем информацию о врагах в зависимости от уровня способности "Видящий"
	var room_info_text = _get_room_info_text(room, seer_level)
	var use_bbcode = (seer_level >= 3)  # Используем BBCode для уровня 3
	
	var desc_label: Control
	if use_bbcode:
		# Для уровня 3 используем RichTextLabel для цветного текста
		desc_label = RichTextLabel.new()
		desc_label.bbcode_enabled = true
		desc_label.fit_content = true
		desc_label.scroll_active = false
		(desc_label as RichTextLabel).text = room_info_text
	else:
		# Для уровней 1-2 используем обычный Label
		desc_label = Label.new()
		(desc_label as Label).text = room_info_text
	
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if desc_label is Label:
		(desc_label as Label).vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		(desc_label as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 13)
	if not use_bbcode:
		desc_label.add_theme_color_override("font_color", room_style.desc_color)
	desc_label.add_theme_constant_override("margin_left", 12)
	desc_label.add_theme_constant_override("margin_top", 12)
	desc_label.add_theme_constant_override("margin_right", -12)
	desc_label.add_theme_constant_override("margin_bottom", -12)
	desc_container.add_child(desc_label)
	
	# Добавляем hover эффект для всей карточки
	card_container.mouse_entered.connect(func(): _on_card_mouse_entered(card_container, room_style))
	card_container.mouse_exited.connect(func(): _on_card_mouse_exited(card_container, room_style))
	
	# Добавляем обработчик клика на карточку
	card_container.gui_input.connect(func(event): _on_card_clicked(event, room))
	
	return card_container

func _get_room_style(room_type: RoomData.RoomType, enemy_rarity: String, is_quest: bool, seer_level: int = 0) -> Dictionary:
	"""Возвращает стиль оформления для комнаты
	seer_level: уровень способности 'Видящий' (0-3). Если < 2, редкость скрывается."""
	var style = {
		"bg_color": Color(0.1, 0.1, 0.15, 0.9),
		"border_color": Color(0.4, 0.4, 0.6, 1),
		"border_width": 2,
		"direction_color": Color(0.8, 0.6, 0.4, 1),
		"name_color": Color(0.8, 0.8, 0.8, 1),
		"desc_color": Color(0.7, 0.7, 0.7, 1),
		"type_label": "",
		"type_label_color": Color(1, 1, 1, 1),
		"icon": "⚔️",
		"font_size": 16,
		"button_text": "Выбрать",
		"button_font_size": 14,
		"button_color": Color(0.9, 0.9, 0.9, 1),
		"has_glow": false,
		"glow_color": Color(1, 1, 1, 1),
		"has_shadow": false,
		"shadow_color": Color(0, 0, 0, 0.8)
	}
	
	# КВЕСТОВЫЕ КОМНАТЫ (высший приоритет)
	if is_quest:
		style.bg_color = Color(0.15, 0.1, 0.05, 0.95)
		style.border_color = Color(1.0, 0.8, 0.2, 1.0)
		style.border_width = 3
		style.direction_color = Color(1.0, 0.85, 0.3, 1)
		style.name_color = Color(1.0, 0.9, 0.3, 1)
		style.desc_color = Color(0.9, 0.9, 0.9, 1)
		style.type_label = "📜 КВЕСТОВАЯ КОМНАТА 📜"
		style.type_label_color = Color(1.0, 0.8, 0.2, 1)
		style.icon = "⭐"
		style.font_size = 20
		style.button_text = "⚔️ Войти"
		style.button_font_size = 16
		style.button_color = Color(1.0, 0.9, 0.3, 1)
		style.has_glow = true
		style.glow_color = Color(1.2, 1.1, 1.0, 1.0)
		style.has_shadow = true
		style.shadow_color = Color(0.8, 0.6, 0.0, 0.8)
		return style
	
	# БОСС
	if room_type == RoomData.RoomType.BOSS:
		style.bg_color = Color(0.05, 0.05, 0.05, 0.95)  # Почти черный фон
		style.border_color = Color(0.3, 0.3, 0.3, 1.0)  # Темно-серая рамка
		style.border_width = 3
		style.direction_color = Color(0.8, 0.8, 0.8, 1)  # Светло-серый
		style.name_color = Color(0.9, 0.9, 0.9, 1)  # Почти белый
		style.desc_color = Color(0.85, 0.85, 0.85, 1)  # Светло-серый
		style.type_label = "👑 БОСС ЛОКАЦИИ 👑"
		style.type_label_color = Color(0.9, 0.9, 0.9, 1)  # Почти белый
		style.icon = "👑"
		style.font_size = 20
		style.button_text = "⚔️ К БОССУ"
		style.button_font_size = 16
		style.button_color = Color(0.9, 0.9, 0.9, 1)  # Почти белый
		style.has_glow = true
		style.glow_color = Color(1.15, 1.15, 1.15, 1.0)  # Белое свечение
		style.has_shadow = true
		style.shadow_color = Color(0.0, 0.0, 0.0, 0.9)  # Черная тень
		return style
	
	# ОТДЫХ
	if room_type == RoomData.RoomType.REST:
		style.bg_color = Color(0.05, 0.15, 0.1, 0.9)
		style.border_color = Color(0.3, 0.8, 0.5, 1.0)
		style.border_width = 2
		style.direction_color = Color(0.5, 1.0, 0.7, 1)
		style.name_color = Color(0.5, 1.0, 0.7, 1)
		style.desc_color = Color(0.8, 1.0, 0.9, 1)
		style.type_label = "🌿 БЕЗОПАСНОЕ МЕСТО 🌿"
		style.type_label_color = Color(0.4, 0.9, 0.6, 1)
		style.icon = "🌿"
		style.font_size = 17
		style.button_text = "🛡️ Отдохнуть"
		style.button_font_size = 14
		style.button_color = Color(0.5, 1.0, 0.7, 1)
		style.has_glow = true
		style.glow_color = Color(1.0, 1.15, 1.1, 1.0)
		style.has_shadow = false
		return style
	
	# ОБЫЧНЫЙ БОЙ - определяем по редкости врага
	if room_type == RoomData.RoomType.BATTLE:
		# Если уровень "Видящий" < 2, скрываем редкость - используем нейтральный стиль
		if seer_level < 2:
			style.bg_color = Color(0.12, 0.12, 0.12, 0.9)
			style.border_color = Color(0.6, 0.6, 0.6, 1.0)
			style.border_width = 2
			style.name_color = Color(0.8, 0.8, 0.8, 1)
			style.type_label = ""  # Скрываем текст редкости
			style.type_label_color = Color(0.7, 0.7, 0.7, 1)
			style.icon = "⚔️"
			style.has_glow = false
			style.has_shadow = false
			return style
		
		# Сначала проверяем элитные редкости
		if enemy_rarity.to_lower().begins_with("elite_"):
			var base_rarity = enemy_rarity.to_lower().substr(6)  # Убираем "elite_"
			match base_rarity:
				"rare":
					style.bg_color = Color(0.1, 0.15, 0.25, 0.95)
					style.border_color = Color(0.5, 0.8, 1.2, 1.0)
					style.border_width = 3
					style.name_color = Color(0.6, 0.9, 1.2, 1)
					style.type_label = "⭐ Элитный Редкий враг ⭐"
					style.type_label_color = Color(0.6, 0.9, 1.2, 1)
					style.icon = "⭐"
					style.font_size = 17
					style.has_glow = true
					style.glow_color = Color(1.1, 1.1, 1.2, 1.0)
					style.has_shadow = true
					style.shadow_color = Color(0.2, 0.4, 0.6, 0.8)
				"epic":
					style.bg_color = Color(0.2, 0.1, 0.25, 0.95)
					style.border_color = Color(0.9, 0.5, 1.2, 1.0)
					style.border_width = 3
					style.name_color = Color(1.0, 0.6, 1.2, 1)
					style.type_label = "⭐ Элитный Эпический враг ⭐"
					style.type_label_color = Color(1.0, 0.6, 1.2, 1)
					style.icon = "⭐"
					style.font_size = 18
					style.has_glow = true
					style.glow_color = Color(1.2, 1.1, 1.3, 1.0)
					style.has_shadow = true
					style.shadow_color = Color(0.5, 0.2, 0.6, 0.8)
				"legendary":
					style.bg_color = Color(0.25, 0.15, 0.05, 0.95)
					style.border_color = Color(1.2, 0.8, 0.4, 1.0)
					style.border_width = 4
					style.name_color = Color(1.2, 0.9, 0.5, 1)
					style.desc_color = Color(1.1, 1.0, 0.8, 1)
					style.type_label = "⭐ Элитный Легендарный враг ⭐"
					style.type_label_color = Color(1.2, 0.9, 0.5, 1)
					style.icon = "⭐"
					style.font_size = 19
					style.button_font_size = 16
					style.has_glow = true
					style.glow_color = Color(1.3, 1.2, 1.1, 1.0)
					style.has_shadow = true
					style.shadow_color = Color(0.6, 0.4, 0.1, 0.9)
				_:
					# Fallback для неизвестных элитных редкостей
					style.bg_color = Color(0.15, 0.15, 0.15, 0.95)
					style.border_color = Color(1.0, 0.8, 0.2, 1.0)
					style.border_width = 3
					style.name_color = Color(1.0, 0.9, 0.4, 1)
					style.type_label = "⭐ Элитный враг ⭐"
					style.type_label_color = Color(1.0, 0.9, 0.4, 1)
					style.icon = "⭐"
					style.has_glow = true
					style.glow_color = Color(1.2, 1.1, 1.0, 1.0)
		else:
			# Обычные редкости
			match enemy_rarity.to_lower():
				"common":
					style.bg_color = Color(0.12, 0.12, 0.12, 0.9)
					style.border_color = Color(0.6, 0.6, 0.6, 1.0)
					style.border_width = 2
					style.name_color = Color(0.8, 0.8, 0.8, 1)
					style.type_label = "Обычный враг"
					style.type_label_color = Color(0.7, 0.7, 0.7, 1)
					style.icon = "⚔️"
				
				"uncommon":
					style.bg_color = Color(0.05, 0.15, 0.05, 0.9)
					style.border_color = Color(0.4, 0.9, 0.4, 1.0)
					style.border_width = 2
					style.name_color = Color(0.5, 1.0, 0.5, 1)
					style.type_label = "🟢 Необычный враг"
					style.type_label_color = Color(0.5, 1.0, 0.5, 1)
					style.icon = "⚔️"
				
				"rare":
					style.bg_color = Color(0.05, 0.1, 0.2, 0.95)
					style.border_color = Color(0.3, 0.6, 1.0, 1.0)
					style.border_width = 2
					style.name_color = Color(0.4, 0.7, 1.0, 1)
					style.type_label = "🔵 Редкий враг"
					style.type_label_color = Color(0.4, 0.7, 1.0, 1)
					style.icon = "⚔️"
					style.has_glow = true
					style.glow_color = Color(1.0, 1.05, 1.15, 1.0)
				
				"epic":
					style.bg_color = Color(0.15, 0.05, 0.2, 0.95)
					style.border_color = Color(0.7, 0.3, 1.0, 1.0)
					style.border_width = 3
					style.name_color = Color(0.8, 0.4, 1.0, 1)
					style.type_label = "🟣 Эпический враг"
					style.type_label_color = Color(0.8, 0.4, 1.0, 1)
					style.icon = "⚔️"
					style.font_size = 17
					style.has_glow = true
					style.glow_color = Color(1.1, 1.0, 1.2, 1.0)
				
				"legendary":
					style.bg_color = Color(0.2, 0.1, 0.0, 0.95)
					style.border_color = Color(1.0, 0.6, 0.2, 1.0)
					style.border_width = 3
					style.name_color = Color(1.0, 0.7, 0.3, 1)
					style.desc_color = Color(1.0, 0.9, 0.7, 1)
					style.type_label = "🟠 Легендарный враг"
					style.type_label_color = Color(1.0, 0.7, 0.3, 1)
					style.icon = "⚔️"
					style.font_size = 18
					style.button_font_size = 15
					style.has_glow = true
					style.glow_color = Color(1.2, 1.1, 1.0, 1.0)
					style.has_shadow = true
					style.shadow_color = Color(0.5, 0.3, 0.0, 0.8)
				
				"mythic":
					style.bg_color = Color(0.2, 0.05, 0.05, 0.95)  # Темно-красный фон
					style.border_color = Color(1.0, 0.2, 0.2, 1.0)  # Ярко-красная рамка
					style.border_width = 3
					style.name_color = Color(1.0, 0.3, 0.3, 1)  # Ярко-красный
					style.desc_color = Color(1.0, 0.7, 0.7, 1)  # Светло-красный
					style.type_label = "✨ Мифический враг ✨"
					style.type_label_color = Color(1.0, 0.2, 0.2, 1)  # Красный
					style.icon = "✨"
					style.font_size = 19
					style.button_text = "⚔️ ВЫЗОВ"
					style.button_font_size = 16
					style.button_color = Color(1.0, 0.3, 0.3, 1)  # Ярко-красный
					style.has_glow = true
					style.glow_color = Color(1.3, 1.0, 1.0, 1.0)  # Красное свечение
					style.has_shadow = true
					style.shadow_color = Color(0.5, 0.0, 0.0, 0.9)  # Красно-черная тень
				
				_:
					# Fallback для неизвестных редкостей - используем стиль "uncommon"
					style.bg_color = Color(0.05, 0.15, 0.05, 0.9)
					style.border_color = Color(0.4, 0.9, 0.4, 1.0)
					style.border_width = 2
					style.name_color = Color(0.5, 1.0, 0.5, 1)
					style.type_label = "🟢 Необычный враг"
					style.type_label_color = Color(0.5, 1.0, 0.5, 1)
					style.icon = "⚔️"
	
	return style

func _on_card_mouse_entered(card: PanelContainer, room_style: Dictionary):
	"""Эффект при наведении на карточку"""
	if not card:
		return
	
	# Меняем курсор на указатель
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	
	# Увеличиваем карточку и добавляем свечение
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "scale", Vector2(1.05, 1.05), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Усиливаем свечение
	if room_style.has_glow:
		var glow_node = card.get_node_or_null("GlowEffect")
		if glow_node:
			tween.tween_property(glow_node, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.2)

func _on_card_mouse_exited(card: PanelContainer, room_style: Dictionary):
	"""Эффект при уходе курсора с карточки"""
	if not card:
		return
	
	# Возвращаем курсор к обычному
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	
	# Возвращаем карточку к исходному размеру
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Возвращаем свечение
	if room_style.has_glow:
		var glow_node = card.get_node_or_null("GlowEffect")
		if glow_node:
			tween.tween_property(glow_node, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)

func _on_card_clicked(event: InputEvent, room: RoomData):
	"""Обработка клика по карточке комнаты"""
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			# Выбираем комнату при клике
			_on_room_selected(room)

func _add_room_glow_effect(card: PanelContainer, glow_color: Color):
	"""Добавляет анимированное свечение для карточки комнаты"""
	# Создаем эффект свечения через ColorRect поверх карточки
	var glow_rect = ColorRect.new()
	glow_rect.name = "GlowEffect"
	glow_rect.color = Color(glow_color.r, glow_color.g, glow_color.b, 0.2)
	glow_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow_rect.z_index = -1
	
	var glow_style = StyleBoxFlat.new()
	glow_style.bg_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.15)
	glow_style.corner_radius_top_left = 16
	glow_style.corner_radius_top_right = 16
	glow_style.corner_radius_bottom_right = 16
	glow_style.corner_radius_bottom_left = 16
	glow_rect.add_theme_stylebox_override("panel", glow_style)
	
	card.add_child(glow_rect)
	
	# Анимация пульсации свечения (упрощенная версия без бесконечного цикла)
	# Просто устанавливаем начальную яркость свечения
	glow_rect.modulate = Color(1.0, 1.0, 1.0, 0.2)

func _update_background():
	"""Обновляет бэкграунд в зависимости от текущей локации"""
	if not location_manager or not location_manager.current_location:
		# Если локация не установлена, используем дефолтный фон
		if background_texture:
			var default_bg = load("res://Assets/background.png")
			if default_bg:
				background_texture.texture = default_bg
		return
	
	var location_id = location_manager.current_location.location_id
	var bg_path = location_backgrounds.get(location_id, "res://Assets/background.png")
	
	# Загружаем и устанавливаем текстуру
	if background_texture:
		var bg_texture = load(bg_path)
		if bg_texture:
			background_texture.texture = bg_texture
		else:
			print("ОШИБКА: Не удалось загрузить бэкграунд: ", bg_path)
			# Fallback на дефолтный фон
			var default_bg = load("res://Assets/background.png")
			if default_bg:
				background_texture.texture = default_bg

func _on_room_selected(room: RoomData):
	
	# НЕ очищаем предыдущую комнату здесь - это сбрасывает прогресс!
	# Комната должна очищаться только после её прохождения
	
	# Устанавливаем новую комнату
	room_generator.set_current_room(room)
	
	# Переходим к соответствующему экрану
	match room.room_type:
		RoomData.RoomType.BATTLE, RoomData.RoomType.BOSS:
			# Счетчик осколков душ за забег НЕ сбрасывается при переходах между комнатами
			# Он сбрасывается только в начале нового забега (при переходе к выбору локации)
			# Переходим к бою
			SceneTransition.change_scene("res://Scenes/Battle/BattleScene.tscn")
		RoomData.RoomType.REST:
			# Отдых - восстанавливаем ресурсы
			_handle_rest_room(room)

func _on_battle_completed():
	# Вызывается когда игрок возвращается из боя
	
	# Проверяем, что room_generator еще существует
	if not is_instance_valid(room_generator):
		print("⚠️ room_generator был освобожден, возвращаемся в главное меню")
		SceneTransition.change_scene("res://Scenes/MainMenu.tscn")
		return
	
	# Даем награды за победу
	var current_room = room_generator.get_current_room()
	
	if current_room:
		var player_manager = get_node_or_null("/root/PlayerManager")
		
		if player_manager:
			var player_data = player_manager.get_player_data()
			
			if player_data:
				# Убрали начисление опыта и золота - награды больше не используются
				pass
			else:
				print("ОШИБКА: PlayerData не найдена!")
		else:
			print("ОШИБКА: PlayerManager не найден!")
	else:
		print("ОШИБКА: Текущая комната не найдена!")
	
	# Очищаем текущую комнату после победы в бою
	room_generator.clear_current_room()
	# Испускаем сигнал только после очистки комнаты
	room_generator.emit_room_cleared_signal()
	
	# Обновляем прогресс бар
	_update_progress_bar()
	
	_show_current_room()
	_show_room_options()

func _handle_rest_room(_room: RoomData):
	
	# Восстанавливаем ресурсы игрока
	var player_manager = get_node_or_null("/root/PlayerManager")
	if player_manager:
		var player_data = player_manager.get_player_data()
		if player_data:
			player_data.current_hp = player_data.max_hp
			player_data.current_mp = player_data.max_mp
			player_data.current_stamina = player_data.max_stamina
	
	# Восстанавливаем заряды восстановления души
	var soul_restoration_manager = get_node_or_null("/root/SoulRestorationManager")
	if soul_restoration_manager:
		soul_restoration_manager.restore_all_charges()
	
	# Проверяем, что room_generator еще существует
	if not is_instance_valid(room_generator):
		print("⚠️ room_generator был освобожден в комнате отдыха")
		return
	
	room_generator.clear_current_room()
	room_generator.emit_room_cleared_signal()
	_update_progress_bar()
	_show_current_room()
	_show_room_options()

# Удалены методы _handle_event_room() и _handle_treasure_room() - больше не используются

func _on_room_cleared(_room: RoomData):
	# НЕ вызываем clear_current_room() здесь - это создает рекурсию!
	# clear_current_room() уже был вызван в clear_current_room()
	_show_current_room()
	_show_room_options()

func _on_location_completed():
	
	# Получаем информацию о текущей и следующей локации
	var current_location = location_manager.current_location
	var next_location = null
	var was_unlocked_now = false
	
	if current_location:
		next_location = location_manager.get_next_location(current_location)
		
		# Разблокируем следующую локацию если она есть
		if next_location:
			if next_location.location_id is String:
				# Проверяем, не разблокирована ли уже следующая локация
				if not next_location.is_unlocked:
					location_manager.unlock_location(next_location.location_id)
					was_unlocked_now = true  # Локация была только что разблокирована
					print("✅ Разблокирована новая локация: ", next_location.location_name)
			else:
				print("ОШИБКА: location_id не является строкой!")
		else:
			print("Следующая локация не найдена")
	
	# Показываем сообщение о завершении локации
	await _show_location_completion_dialog(current_location, next_location, was_unlocked_now)

func _show_location_completion_dialog(current_location, next_location, was_unlocked_now: bool):
	# Удаляем все существующие диалоги перед созданием нового
	await _cleanup_existing_dialogs()
	
	# Дополнительная проверка - убеждаемся, что нет активных диалогов
	var active_dialogs = []
	for child in get_children():
		if child is AcceptDialog or child is Panel:
			active_dialogs.append(child)
	
	if active_dialogs.size() > 0:
		print("ОШИБКА: Найдены активные диалоги после очистки: ", active_dialogs.size())
		for dialog in active_dialogs:
			print("Принудительно удаляем активный диалог: ", dialog.name)
			if dialog.get_parent():
				dialog.get_parent().remove_child(dialog)
			dialog.free()
		# Ждем еще один кадр
		await get_tree().process_frame
	
	# Создаем затемняющий оверлей для красивого фона
	var overlay = ColorRect.new()
	overlay.name = "LocationCompletionOverlay"
	overlay.color = Color(0, 0, 0, 0.85)  # Полупрозрачный черный
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # Блокируем клики по фону
	add_child(overlay)
	
	# Анимация появления оверлея
	overlay.modulate = Color(1, 1, 1, 0)
	var fade_tween = create_tween()
	fade_tween.tween_property(overlay, "modulate:a", 1.0, 0.3)
	await fade_tween.finished
	
	# Создаем КРАСИВЫЙ кастомный диалог
	var dialog_panel = Panel.new()
	dialog_panel.name = "LocationCompletionDialog"
	dialog_panel.custom_minimum_size = Vector2(700, 400)
	dialog_panel.set_anchors_preset(Control.PRESET_CENTER)
	dialog_panel.position = Vector2(-350, -200)  # Центрируем
	
	# Создаем стильный фон для панели
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.05, 0.15, 0.95)  # Темно-фиолетовый с прозрачностью
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.8, 0.6, 0.2, 1.0)  # Золотая рамка
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_left = 15
	panel_style.corner_radius_bottom_right = 15
	panel_style.shadow_color = Color(0.8, 0.6, 0.2, 0.3)
	panel_style.shadow_size = 10
	dialog_panel.add_theme_stylebox_override("panel", panel_style)
	
	add_child(dialog_panel)
	
	# Анимация появления панели (масштабирование)
	dialog_panel.scale = Vector2(0.7, 0.7)
	dialog_panel.modulate = Color(1, 1, 1, 0)
	var dialog_tween = create_tween().set_parallel(true)
	dialog_tween.tween_property(dialog_panel, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	dialog_tween.tween_property(dialog_panel, "modulate:a", 1.0, 0.3)
	await dialog_tween.finished
	
	# Контейнер для контента
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	dialog_panel.add_child(vbox)
	
	# Заголовок "ЛОКАЦИЯ ЗАВЕРШЕНА!"
	var title_label = Label.new()
	title_label.text = "⚔️ ЛОКАЦИЯ ЗАВЕРШЕНА! ⚔️"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))  # Золотой
	title_label.add_theme_color_override("font_outline_color", Color.BLACK)
	title_label.add_theme_constant_override("outline_size", 3)
	vbox.add_child(title_label)
	
	# Разделитель
	var separator1 = HSeparator.new()
	separator1.add_theme_constant_override("separation", 10)
	vbox.add_child(separator1)
	
	# Сообщение о прохождении
	var completion_label = RichTextLabel.new()
	completion_label.bbcode_enabled = true
	completion_label.fit_content = true
	completion_label.scroll_active = false
	completion_label.custom_minimum_size = Vector2(650, 100)
	
	var message_text = "[center][font_size=24]Поздравляем! Вы успешно прошли локацию:[/font_size]\n"
	message_text += "[font_size=28][color=#FFD700]" + current_location.location_name + "[/color][/font_size][/center]"
	
	completion_label.text = message_text
	vbox.add_child(completion_label)
	
	# Если разблокирована новая локация - показываем сообщение
	if was_unlocked_now and next_location:
		var unlock_label = RichTextLabel.new()
		unlock_label.bbcode_enabled = true
		unlock_label.fit_content = true
		unlock_label.scroll_active = false
		unlock_label.custom_minimum_size = Vector2(650, 100)
		
		var unlock_text = "[center][font_size=20][wave amp=30 freq=5][color=#00FF00]🎉 НОВАЯ ЛОКАЦИЯ РАЗБЛОКИРОВАНА! 🎉[/color][/wave][/font_size]\n\n"
		unlock_text += "[font_size=22]Теперь доступна локация:\n[color=#87CEEB]" + next_location.location_name + "[/color][/font_size][/center]"
		
		unlock_label.text = unlock_text
		vbox.add_child(unlock_label)
	
	# Кнопка "Продолжить"
	var continue_button = Button.new()
	continue_button.text = "Продолжить"
	continue_button.custom_minimum_size = Vector2(200, 60)
	continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Стиль кнопки
	var btn_style_normal = StyleBoxFlat.new()
	btn_style_normal.bg_color = Color(0.2, 0.5, 0.8, 1.0)  # Синий
	btn_style_normal.border_width_left = 2
	btn_style_normal.border_width_right = 2
	btn_style_normal.border_width_top = 2
	btn_style_normal.border_width_bottom = 2
	btn_style_normal.border_color = Color(0.4, 0.7, 1.0)
	btn_style_normal.corner_radius_top_left = 10
	btn_style_normal.corner_radius_top_right = 10
	btn_style_normal.corner_radius_bottom_left = 10
	btn_style_normal.corner_radius_bottom_right = 10
	
	var btn_style_hover = btn_style_normal.duplicate()
	btn_style_hover.bg_color = Color(0.3, 0.6, 0.9, 1.0)  # Светлее при наведении
	btn_style_hover.shadow_color = Color(0.4, 0.7, 1.0, 0.5)
	btn_style_hover.shadow_size = 5
	
	continue_button.add_theme_stylebox_override("normal", btn_style_normal)
	continue_button.add_theme_stylebox_override("hover", btn_style_hover)
	continue_button.add_theme_stylebox_override("pressed", btn_style_normal)
	continue_button.add_theme_font_size_override("font_size", 24)
	continue_button.add_theme_color_override("font_color", Color.WHITE)
	
	vbox.add_child(continue_button)
	
	# Подключаем сигнал для закрытия диалога
	continue_button.connect("pressed", Callable(self, "_on_location_completion_confirmed").bind(overlay, dialog_panel))

func _on_location_completion_confirmed(overlay: ColorRect, dialog_panel: Panel):
	"""Обрабатывает закрытие диалога завершения локации"""
	# Анимация исчезновения диалога
	if is_instance_valid(dialog_panel):
		var dialog_tween = create_tween().set_parallel(true)
		dialog_tween.tween_property(dialog_panel, "scale", Vector2(0.7, 0.7), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		dialog_tween.tween_property(dialog_panel, "modulate:a", 0.0, 0.3)
		await dialog_tween.finished
		dialog_panel.queue_free()
	
	# Анимация исчезновения оверлея
	if is_instance_valid(overlay):
		var fade_tween = create_tween()
		fade_tween.tween_property(overlay, "modulate:a", 0.0, 0.3)
		await fade_tween.finished
		overlay.queue_free()
	
	# Возвращаемся к выбору локаций
	_return_to_location_selector()

func _cleanup_existing_dialogs():
	# Удаляем все существующие диалоги и оверлеи принудительно
	var dialogs_to_remove = []
	var overlays_to_remove = []
	
	for child in get_children():
		if child is AcceptDialog:
			dialogs_to_remove.append(child)
		elif child is Panel and child.name == "LocationCompletionDialog":
			dialogs_to_remove.append(child)  # Добавляем кастомные Panel диалоги
		elif child is ColorRect and child.name == "LocationCompletionOverlay":
			overlays_to_remove.append(child)
	
	# Принудительно удаляем все найденные диалоги
	for dialog in dialogs_to_remove:
		if is_instance_valid(dialog):
			# Отключаем от родителя
			if dialog.get_parent():
				dialog.get_parent().remove_child(dialog)
			# Удаляем объект
			dialog.free()
	
	# Удаляем оверлеи
	for overlay in overlays_to_remove:
		if is_instance_valid(overlay):
			overlay.queue_free()
	
	# Ждем кадр для завершения удаления
	await get_tree().process_frame
	
	# Финальная проверка
	var remaining_dialogs = []
	for child in get_children():
		if child is AcceptDialog:
			remaining_dialogs.append(child)
	
	if remaining_dialogs.size() > 0:
		print("ОШИБКА: остались диалоги после принудительной очистки: ", remaining_dialogs.size())
		for dialog in remaining_dialogs:
			if is_instance_valid(dialog):
				print("Принудительно удаляем оставшийся диалог: ", dialog.name)
				if dialog.get_parent():
					dialog.get_parent().remove_child(dialog)
				dialog.free()

func _return_to_location_selector():
	# При завершении уровня игрок попадает сразу на экран подготовки персонажа
	# Сбрасываем флаг прохождения локации
	var player_manager = get_node_or_null("/root/PlayerManager")
	if player_manager:
		player_manager.set_in_location(false)
	
	# Переносим осколки душ за забег в хранилище (Колодец душ)
	var soul_shard_manager = get_node_or_null("/root/SoulShard")
	if soul_shard_manager:
		soul_shard_manager.deposit_run_soul_shards()
	
	# Восстанавливаем заряды восстановления души
	var soul_restoration_manager = get_node_or_null("/root/SoulRestorationManager")
	if soul_restoration_manager:
		soul_restoration_manager.restore_all_charges()
	
	# Очищаем глобальный RoomGenerator при завершении уровня
	var global_room_generator = get_node_or_null("/root/RoomGenerator")
	if global_room_generator:
		global_room_generator.queue_free()
	
	# Сохраняем игру перед возвратом к экрану подготовки
	if player_manager:
		player_manager.save_game_data()
	
	# Переходим сразу к экрану подготовки персонажа
	SceneTransition.change_scene("res://Scenes/UI/CharacterPreparation.tscn")

func _style_back_button():
	"""Улучшает дизайн кнопки возврата в Колодец душ"""
	if not btn_back:
		return
	
	btn_back.text = "🏛️ Вернуться в Колодец душ"
	btn_back.custom_minimum_size = Vector2(280, 60)
	btn_back.add_theme_font_size_override("font_size", 18)
	
	# Стиль normal - темный с золотистой рамкой
	var btn_style_normal = StyleBoxFlat.new()
	btn_style_normal.bg_color = Color(0.15, 0.12, 0.1, 0.95)
	btn_style_normal.border_width_left = 3
	btn_style_normal.border_width_top = 3
	btn_style_normal.border_width_right = 3
	btn_style_normal.border_width_bottom = 3
	btn_style_normal.border_color = Color(0.7, 0.6, 0.4, 1.0)
	btn_style_normal.corner_radius_top_left = 12
	btn_style_normal.corner_radius_top_right = 12
	btn_style_normal.corner_radius_bottom_right = 12
	btn_style_normal.corner_radius_bottom_left = 12
	btn_style_normal.shadow_color = Color(0, 0, 0, 0.6)
	btn_style_normal.shadow_size = 8
	btn_style_normal.shadow_offset = Vector2(0, 3)
	btn_back.add_theme_stylebox_override("normal", btn_style_normal)
	
	# Стиль hover - светлее с яркой рамкой
	var btn_style_hover = StyleBoxFlat.new()
	btn_style_hover.bg_color = Color(0.25, 0.2, 0.15, 0.95)
	btn_style_hover.border_width_left = 3
	btn_style_hover.border_width_top = 3
	btn_style_hover.border_width_right = 3
	btn_style_hover.border_width_bottom = 3
	btn_style_hover.border_color = Color(1.0, 0.85, 0.5, 1.0)
	btn_style_hover.corner_radius_top_left = 12
	btn_style_hover.corner_radius_top_right = 12
	btn_style_hover.corner_radius_bottom_right = 12
	btn_style_hover.corner_radius_bottom_left = 12
	btn_style_hover.shadow_color = Color(0, 0, 0, 0.7)
	btn_style_hover.shadow_size = 10
	btn_style_hover.shadow_offset = Vector2(0, 4)
	btn_back.add_theme_stylebox_override("hover", btn_style_hover)
	
	# Стиль pressed - темнее
	var btn_style_pressed = StyleBoxFlat.new()
	btn_style_pressed.bg_color = Color(0.1, 0.08, 0.06, 0.95)
	btn_style_pressed.border_width_left = 3
	btn_style_pressed.border_width_top = 3
	btn_style_pressed.border_width_right = 3
	btn_style_pressed.border_width_bottom = 3
	btn_style_pressed.border_color = Color(0.5, 0.4, 0.3, 1.0)
	btn_style_pressed.corner_radius_top_left = 12
	btn_style_pressed.corner_radius_top_right = 12
	btn_style_pressed.corner_radius_bottom_right = 12
	btn_style_pressed.corner_radius_bottom_left = 12
	btn_back.add_theme_stylebox_override("pressed", btn_style_pressed)
	
	# Цвета текста
	btn_back.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6, 1.0))
	btn_back.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.8, 1.0))
	btn_back.add_theme_color_override("font_pressed_color", Color(0.8, 0.7, 0.5, 1.0))
	btn_back.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	btn_back.add_theme_constant_override("shadow_offset_x", 2)
	btn_back.add_theme_constant_override("shadow_offset_y", 2)

func _on_back_pressed():
	
	# Сбрасываем прогресс локации при возврате в колодец душ
	if is_instance_valid(room_generator):
		room_generator.reset_location_progress()
	
	# Сбрасываем флаг прохождения локации
	var player_manager = get_node_or_null("/root/PlayerManager")
	if player_manager:
		player_manager.set_in_location(false)
	
	# Переносим осколки душ за забег в хранилище (Колодец душ)
	var soul_shard_manager = get_node_or_null("/root/SoulShard")
	if soul_shard_manager:
		soul_shard_manager.deposit_run_soul_shards()
	
	# Восстанавливаем заряды восстановления души
	var soul_restoration_manager = get_node_or_null("/root/SoulRestorationManager")
	if soul_restoration_manager:
		soul_restoration_manager.restore_all_charges()
	
	# Очищаем глобальный RoomGenerator при возврате
	var global_room_generator = get_node_or_null("/root/RoomGenerator")
	if global_room_generator:
		global_room_generator.queue_free()
	
	# Сохраняем игру перед возвратом к экрану подготовки
	if player_manager:
		player_manager.save_game_data()
	
	# Переходим к экрану подготовки персонажа (Колодец душ)
	SceneTransition.change_scene("res://Scenes/UI/CharacterPreparation.tscn")

func _on_battle_defeat():
	"""Обработка поражения в бою - сброс прогресса и возврат в Колодец душ"""
	print("Игрок проиграл бой. Сброс прогресса локации и возврат в Колодец душ...")
	
	# Сбрасываем прогресс локации
	if is_instance_valid(room_generator):
		room_generator.reset_location_progress()
		print("DEBUG: Прогресс локации сброшен")
	
	# Сбрасываем флаг прохождения локации
	var player_manager = get_node_or_null("/root/PlayerManager")
	if player_manager:
		player_manager.set_in_location(false)
	
	# ТЕРЯЕМ осколки душ за текущий забег (не переносим в хранилище)
	var soul_shard_manager = get_node_or_null("/root/SoulShard")
	if soul_shard_manager:
		var lost_shards = soul_shard_manager.get_run_soul_shards()
		soul_shard_manager.reset_run_soul_shards()  # Очищаем осколки за забег
		print("DEBUG: Потеряно ", lost_shards, " осколков душ за этот забег")
	
	# Восстанавливаем заряды восстановления души
	var soul_restoration_manager = get_node_or_null("/root/SoulRestorationManager")
	if soul_restoration_manager:
		soul_restoration_manager.restore_all_charges()
	
	# Очищаем глобальный RoomGenerator
	var global_room_generator = get_node_or_null("/root/RoomGenerator")
	if global_room_generator:
		global_room_generator.queue_free()
	
	# Сохраняем игру перед возвратом
	if player_manager:
		player_manager.save_game_data()
	
	# Переходим к экрану подготовки персонажа (Колодец душ)
	SceneTransition.change_scene("res://Scenes/UI/CharacterPreparation.tscn")


func _check_battle_result():
	# Проверяем, есть ли результат последнего боя
	var battle_result = get_node_or_null("/root/BattleResult")
	
	if battle_result and battle_result.has_result:
		var was_won = battle_result.was_battle_won()
		
		if was_won:
			# Победа - обрабатываем результат боя
			_on_battle_completed()
		else:
			# Поражение - сбрасываем прогресс локации и возвращаем в Колодец душ
			print("DEBUG: Игрок проиграл бой. Сброс прогресса локации...")
			_on_battle_defeat()
		
		# Очищаем результат боя
		battle_result.clear_result()

func _get_seer_level() -> int:
	"""Возвращает уровень способности 'Видящий' (0-3)"""
	var player_manager = get_node_or_null("/root/PlayerManager")
	if not player_manager:
		return 0
	
	var player_data = player_manager.get_player_data()
	if not player_data:
		return 0
	
	# Проверяем изученные способности
	var ability_learning_system = get_node_or_null("/root/AbilityLearningSystem")
	if not ability_learning_system:
		return 0
	
	# Проверяем уровни способности "Видящий"
	if ability_learning_system.is_ability_learned("seer_3"):
		return 3
	elif ability_learning_system.is_ability_learned("seer_2"):
		return 2
	elif ability_learning_system.is_ability_learned("seer_1"):
		return 1
	
	return 0

func _get_room_info_text(room: RoomData, seer_level: int) -> String:
	"""Возвращает текст информации о комнате в зависимости от уровня способности 'Видящий'"""
	# Для комнат отдыха не показываем информацию о врагах
	if room.room_type == RoomData.RoomType.REST:
		return room.description
	
	# Без способности "Видящий" - враги неизвестны
	if seer_level == 0:
		return "Здесь обитает неизвестный враг"
	
	var info_parts = []
	
	# Уровень 1: только количество врагов
	if seer_level == 1:
		var enemy_count = _get_enemy_count_for_room(room)
		return "Врагов: " + str(enemy_count)
	
	# Уровень 2: редкость комнаты и количество врагов
	if seer_level >= 2:
		var room_rarity_text = _get_rarity_display_name(room.enemy_rarity)
		var enemy_count = _get_enemy_count_for_room(room)
		info_parts.append(room_rarity_text + " враг")
		info_parts.append("Врагов: " + str(enemy_count))
	
	# Уровень 3: полная информация о врагах
	if seer_level >= 3:
		info_parts.clear()  # Очищаем предыдущую информацию
		var room_rarity_text = _get_rarity_display_name(room.enemy_rarity)
		info_parts.append(room_rarity_text + " враг")
		info_parts.append("")  # Пустая строка для разделения
		
		# Получаем информацию о каждом враге
		var enemy_info = _get_detailed_enemy_info(room)
		info_parts.append_array(enemy_info)
	
	if info_parts.is_empty():
		return "Здесь обитает неизвестный враг"
	
	return "\n".join(info_parts)

func _get_enemy_count_for_room(room: RoomData) -> int:
	"""Определяет количество врагов в комнате (использует ту же логику, что и battle_manager)
	Использует детерминированный seed на основе комнаты для одинакового результата"""
	var player_manager = get_node_or_null("/root/PlayerManager")
	if not player_manager:
		return 1
	
	var player_data = player_manager.get_player_data()
	if not player_data:
		return 1
	
	location_manager = get_node_or_null("/root/LocationManager")
	if not location_manager or not location_manager.current_location:
		return 1
	
	var current_location_id = location_manager.current_location.location_id
	var difficulty = player_data.get_selected_difficulty(current_location_id)
	
	# Проверяем, это босс-комната
	var is_boss_room = (room.room_type == RoomData.RoomType.BOSS)
	
	# Боссы
	if is_boss_room:
		match difficulty:
			1: return 1
			2: return 2
			3: return 3
			_: return 1
	
	# Обычные комнаты - используем детерминированный seed на основе названия комнаты
	var seed_value = room.room_name.hash()  # Используем hash названия комнаты как seed
	seed(seed_value)
	
	var count = 1
	match difficulty:
		1:  # Легко: 70% - 1 враг, 30% - 2 врага
			count = 2 if randf() < 0.3 else 1
		2:  # Средне: 20% - 1, 60% - 2, 20% - 3
			var roll = randf()
			if roll < 0.2:
				count = 1
			elif roll < 0.8:
				count = 2
			else:
				count = 3
		3:  # Сложно: 10% - 1, 20% - 2, 70% - 3
			var roll = randf()
			if roll < 0.1:
				count = 1
			elif roll < 0.3:
				count = 2
			else:
				count = 3
		_:
			count = 1
	
	# Восстанавливаем состояние генератора случайных чисел
	randomize()
	
	return count

func _get_rarity_display_name(rarity: String) -> String:
	"""Возвращает отображаемое имя редкости"""
	match rarity.to_lower():
		"common":
			return "Обычный"
		"uncommon":
			return "Необычный"
		"rare":
			return "Редкий"
		"epic":
			return "Эпический"
		"legendary":
			return "Легендарный"
		"mythic":
			return "Мифический"
		"boss":
			return "Босс"
		_:
			if rarity.to_lower().begins_with("elite_"):
				var base_rarity = rarity.to_lower().substr(6)
				return "Элитный " + _get_rarity_display_name(base_rarity)
			return "Неизвестный"

func _get_detailed_enemy_info(room: RoomData) -> Array[String]:
	"""Генерирует детальную информацию о врагах в комнате (для уровня 3 способности 'Видящий')"""
	var enemy_info: Array[String] = []
	var enemy_count = _get_enemy_count_for_room(room)
	
	# Получаем информацию о каждом враге
	for i in range(enemy_count):
		var enemy_data = _simulate_enemy_generation(room, i)
		if enemy_data:
			var info_line = str(enemy_data.level) + " ур. "
			
			# Добавляем звезду для элитных врагов
			if enemy_data.is_elite:
				info_line += "[color=gold]*[/color] "
			
			# Получаем цвет для имени врага в зависимости от редкости
			var rarity_color = _get_rarity_color_for_bbcode(enemy_data.rarity)
			info_line += "[color=" + rarity_color + "]" + enemy_data.name + "[/color]"
			
			enemy_info.append(info_line)
	
	return enemy_info

func _get_rarity_color_for_bbcode(rarity: String) -> String:
	"""Возвращает цвет редкости в формате BBCode"""
	var base_rarity = rarity.to_lower()
	if base_rarity.begins_with("elite_"):
		base_rarity = base_rarity.substr(6)
	
	match base_rarity:
		"common":
			return "#cccccc"  # Серый
		"uncommon":
			return "#00ff00"  # Зеленый
		"rare":
			return "#0080ff"  # Синий
		"epic":
			return "#cc00ff"  # Фиолетовый
		"legendary":
			return "#ff8000"  # Оранжевый
		"mythic":
			return "#ff0000"  # Красный
		"boss":
			return "#800080"  # Темно-фиолетовый
		_:
			return "#ffffff"  # Белый

func _simulate_enemy_generation(room: RoomData, enemy_index: int) -> Dictionary:
	"""Симулирует генерацию врага для получения информации о нем (без создания объекта)
	Использует детерминированный seed для одинакового результата"""
	location_manager = get_node_or_null("/root/LocationManager")
	if not location_manager or not location_manager.current_location:
		return {}
	
	# Используем детерминированный seed на основе комнаты и индекса врага
	# ТОЧНО ТАКОЙ ЖЕ seed, как в enemy_spawner.spawn_random_enemy()
	var seed_value = (room.room_name.hash() + enemy_index * 1000)  # Уникальный seed для каждого врага
	seed(seed_value)
	
	# Для босс-комнат и квестовых комнат используем заданную сцену врага
	var enemy_scene_path: String
	if room.room_type == RoomData.RoomType.BOSS and room.enemy_scene != "":
		# Для боссов используем заданную сцену (для первого врага - босс, для остальных - спутники)
		if enemy_index == 0:
			enemy_scene_path = room.enemy_scene
		else:
			# Для спутников босса выбираем из пула детерминированно
			enemy_scene_path = _get_random_enemy_from_pool_deterministic(enemy_index)
	elif room.is_quest_room and room.enemy_scene != "":
		# Для квестовых комнат используем заданную сцену врага
		enemy_scene_path = room.enemy_scene
	else:
		# Для обычных комнат ВСЕГДА выбираем врага из пула детерминированно (игнорируем room.enemy_scene для консистентности)
		# Это гарантирует, что отображение совпадет с реальными врагами
		enemy_scene_path = _get_random_enemy_from_pool_deterministic(enemy_index)
	
	# Определяем редкость врага используя ТОЧНО ТУ ЖЕ логику, что и enemy_spawner
	# ВАЖНО: Делаем это сразу после выбора врага, до любых других операций,
	# чтобы порядок вызовов randf()/randi() был идентичен enemy_spawner
	var rarity: String
	if room.room_type == RoomData.RoomType.BOSS:
		# Для босс-комнат используем редкость "boss" для первого врага (босса)
		if enemy_index == 0:
			rarity = "boss"
		else:
			# Для спутников босса используем редкость комнаты
			if room.enemy_rarity != "":
				rarity = _get_rarity_based_on_room_simulated(room.enemy_rarity, enemy_index)
			else:
				rarity = _get_random_rarity_weighted_simulated()
	elif room.is_quest_room and room.enemy_rarity != "":
		# Для квестовых комнат используем редкость комнаты напрямую
		rarity = room.enemy_rarity
	elif room.enemy_rarity != "":
		# Используем редкость комнаты как базовую, с вариативностью (детерминированной)
		rarity = _get_rarity_based_on_room_simulated(room.enemy_rarity, enemy_index)
	else:
		# Fallback - используем взвешенную генерацию (детерминированную)
		rarity = _get_random_rarity_weighted_simulated()
	
	if enemy_scene_path == "" or not ResourceLoader.exists(enemy_scene_path):
		randomize()  # Восстанавливаем состояние
		return {}
	
	# Загружаем сцену, чтобы получить display_name
	var enemy_scene: PackedScene = load(enemy_scene_path)
	var temp_enemy = enemy_scene.instantiate()
	var enemy_name = temp_enemy.display_name if "display_name" in temp_enemy else "Неизвестный враг"
	temp_enemy.queue_free()
	
	# Проверяем, является ли враг элитным
	var is_elite = rarity.to_lower().begins_with("elite_")
	
	# Вычисляем уровень врага
	var player_manager = get_node_or_null("/root/PlayerManager")
	var player_level = 1
	if player_manager:
		var player_data = player_manager.get_player_data()
		if player_data:
			player_level = player_data.level
	
	var location_manager_node = get_node_or_null("/root/LocationManager")
	var difficulty = 1
	if location_manager_node and location_manager_node.current_location:
		var current_location_id = location_manager_node.current_location.location_id
		if player_manager:
			var player_data = player_manager.get_player_data()
			if player_data:
				difficulty = player_data.get_selected_difficulty(current_location_id)
	
	var difficulty_bonus = _get_difficulty_bonus(difficulty)
	var rarity_bonus = _get_rarity_bonus(rarity)
	var enemy_level = player_level + difficulty_bonus + rarity_bonus
	
	# Восстанавливаем состояние генератора случайных чисел
	randomize()
	
	return {
		"name": enemy_name,
		"level": enemy_level,
		"rarity": rarity,
		"is_elite": is_elite
	}

func _get_random_enemy_from_pool_deterministic(_enemy_index: int) -> String:
	"""Выбирает случайного врага из пула локации детерминированно
	ВАЖНО: seed должен быть уже установлен перед вызовом этой функции!"""
	location_manager = get_node_or_null("/root/LocationManager")
	if not location_manager or not location_manager.current_location:
		return ""
	
	var current_location = location_manager.current_location
	if not current_location.enemy_pools or current_location.enemy_pools.is_empty():
		return ""
	
	# Вычисляем общий вес
	var total_weight = 0
	for pool in current_location.enemy_pools:
		if pool:
			total_weight += pool.spawn_weight
	
	if total_weight <= 0:
		return ""
	
	# Используем детерминированный выбор (seed уже установлен в вызывающей функции)
	var random_roll = randi() % total_weight
	
	var current_weight = 0
	for pool in current_location.enemy_pools:
		if pool:
			current_weight += pool.spawn_weight
			if random_roll < current_weight:
				return pool.enemy_scene
	
	# Fallback
	if current_location.enemy_pools.size() > 0:
		return current_location.enemy_pools[0].enemy_scene
	
	return ""

func _get_rarity_based_on_room_simulated(room_rarity: String, _enemy_index: int) -> String:
	"""Симулирует определение редкости врага на основе редкости комнаты (как в enemy_spawner)"""
	if room_rarity == "":
		room_rarity = "common"
	
	# Получаем приоритет редкости комнаты
	var room_priority = _get_rarity_priority_simulated(room_rarity)
	
	# Взвешенная система: в основном редкость комнаты, с небольшой вариативностью
	var roll = randf()
	var target_priority = room_priority
	
	if roll < 0.8:
		# 80% - точно редкость комнаты
		target_priority = room_priority
	else:
		# 20% - на 1 уровень ниже (для вариативности, но не реже комнаты)
		target_priority = max(1, room_priority - 1)
	
	# Преобразуем приоритет обратно в редкость
	var base_rarity = _get_rarity_from_priority_simulated(target_priority)
	
	# Проверяем шанс на элитного врага
	var player_manager = get_node_or_null("/root/PlayerManager")
	var elite_chance = 0.0
	if player_manager:
		var player_data = player_manager.get_player_data()
		if player_data and location_manager and location_manager.current_location:
			var current_location_id = location_manager.current_location.location_id
			var difficulty = player_data.get_selected_difficulty(current_location_id)
			match difficulty:
				1: elite_chance = 0.03
				2: elite_chance = 0.07
				3: elite_chance = 0.12
	
	if base_rarity in ["rare", "epic", "legendary"]:
		var elite_roll = randf()
		if elite_roll < elite_chance:
			# Проверяем, что элитный враг не будет реже комнаты
			var elite_rarity = "elite_" + base_rarity
			var elite_priority = _get_rarity_priority_simulated(elite_rarity)
			var base_rarity_priority = _get_rarity_priority_simulated(base_rarity)
			
			if base_rarity_priority == room_priority:
				if elite_priority <= room_priority + 1:
					return elite_rarity
			elif base_rarity_priority < room_priority:
				return base_rarity
			return base_rarity
	
	return base_rarity

func _get_rarity_priority_simulated(rarity: String) -> int:
	"""Возвращает приоритет редкости (чем выше, тем реже)"""
	match rarity.to_lower():
		"common": return 1
		"uncommon": return 2
		"rare": return 3
		"epic": return 4
		"legendary": return 5
		"mythic": return 6
		"boss": return 7
		"elite_rare": return 4
		"elite_epic": return 5
		"elite_legendary": return 6
		_: return 1

func _get_rarity_from_priority_simulated(priority: int) -> String:
	"""Преобразует приоритет обратно в редкость"""
	match priority:
		1: return "common"
		2: return "uncommon"
		3: return "rare"
		4: return "epic"
		5: return "legendary"
		6: return "mythic"
		7: return "boss"
		_: return "common"

func _get_difficulty_bonus(difficulty: int) -> int:
	"""Возвращает бонус к уровню от сложности"""
	match difficulty:
		1: return 0
		2: return 2
		3: return 5
		_: return 0

func _get_rarity_bonus(rarity: String) -> int:
	"""Возвращает бонус к уровню от редкости"""
	var base_rarity = rarity.to_lower()
	if base_rarity.begins_with("elite_"):
		base_rarity = base_rarity.substr(6)
	
	match base_rarity:
		"common": return 0
		"uncommon": return 1
		"rare": return 2
		"epic": return 3
		"legendary": return 4
		"mythic": return 6
		"boss": return 0
		_: return 0

func _get_random_rarity_weighted_simulated() -> String:
	"""Генерирует случайную редкость с учетом сложности локации (детерминированно)
	ВАЖНО: seed должен быть уже установлен перед вызовом этой функции!"""
	# Получаем текущую сложность
	var player_manager = get_node_or_null("/root/PlayerManager")
	var difficulty = 1
	if player_manager:
		var player_data = player_manager.get_player_data()
		if player_data and location_manager and location_manager.current_location:
			var current_location_id = location_manager.current_location.location_id
			difficulty = player_data.get_selected_difficulty(current_location_id)
	
	# Веса редкостей зависят от сложности
	var weights = {}
	
	match difficulty:
		1:  # Сложность I - в основном обычные враги
			weights = {
				"common": 45,
				"uncommon": 30,
				"rare": 15,
				"epic": 7,
				"legendary": 3
			}
		2:  # Сложность II - больше необычных и редких
			weights = {
				"common": 25,
				"uncommon": 35,
				"rare": 25,
				"epic": 10,
				"legendary": 5
			}
		3:  # Сложность III - много редких, эпических и легендарных
			weights = {
				"common": 10,
				"uncommon": 20,
				"rare": 30,
				"epic": 25,
				"legendary": 15
			}
		_:  # Fallback
			weights = {
				"common": 40,
				"uncommon": 30,
				"rare": 20,
				"epic": 7,
				"legendary": 3
			}
	
	# Шанс на элитного врага (накладывается на базовую редкость)
	var elite_chance = 0.0
	var elite_rarities = []  # Какие редкости могут быть элитными
	
	match difficulty:
		1:
			elite_chance = 0.05  # 5% шанс элитного
			elite_rarities = ["rare", "epic", "legendary"]  # Только rare+
		2:
			elite_chance = 0.20  # 20% шанс элитного
			elite_rarities = ["uncommon", "rare", "epic", "legendary"]  # Uncommon+
		3:
			elite_chance = 0.30  # 30% шанс элитного
			elite_rarities = ["uncommon", "rare", "epic", "legendary"]  # Uncommon+
	
	var total_weight = 0
	for weight in weights.values():
		total_weight += weight
	
	# Используем детерминированный выбор (seed уже установлен в вызывающей функции)
	var random_roll = randi() % total_weight
	var current_weight = 0
	var base_rarity = "common"
	
	for rarity in weights.keys():
		current_weight += weights[rarity]
		if random_roll < current_weight:
			base_rarity = rarity
			break
	
	# Проверяем, станет ли враг элитным
	if base_rarity in elite_rarities:
		var elite_roll = randf()  # Используем уже установленный seed
		if elite_roll < elite_chance:
			return "elite_" + base_rarity
	
	return base_rarity

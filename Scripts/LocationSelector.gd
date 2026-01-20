# res://Scripts/LocationSelector.gd
extends Control

@onready var location_list = $VBoxContainer/ScrollContainer/LocationList
@onready var btn_back = $VBoxContainer/HBoxContainer/Btn_Back
@onready var btn_refresh = $VBoxContainer/HBoxContainer/Btn_Refresh
@onready var background = $Background
@onready var vbox_container = $VBoxContainer

var location_manager
var location_selection_window: Window = null  # Окно выбора локации
var window_level_label: Label = null  # Ссылка на метку уровня в окне
var window_difficulty_info: Label = null  # Ссылка на информацию о сложности в окне
var window_buttons_container: HBoxContainer = null  # Ссылка на контейнер с кнопками сложности
var location_poi_sprites: Dictionary = {}  # Словарь с AnimatedSprite2D для точек интереса
var poi_configs: Dictionary = {}  # Конфигурация точек интереса (для обновления позиций)

func _ready():
	# Скрываем список карточек - теперь выбор по клику на изображении
	vbox_container.visible = false
	
	# Создаем кнопку "Назад" поверх фона
	var back_button = Button.new()
	back_button.text = "Назад в меню"
	back_button.position = Vector2(20, 20)
	back_button.z_index = 10
	back_button.pressed.connect(_on_back_pressed)
	add_child(back_button)
	
	# Подключаем сигналы
	btn_back.connect("pressed", Callable(self, "_on_back_pressed"))
	
	# Делаем фон кликабельным
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	background.gui_input.connect(_on_background_clicked)
	
	# Проверяем Overlay и делаем его прозрачным для кликов (чтобы не блокировал)
	var overlay = get_node_or_null("Overlay")
	if overlay:
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		print("DEBUG: Overlay настроен на игнорирование кликов")
	
	# Также обрабатываем клики на самом Control (если клик не попал в Background)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_background_clicked)
	
	# Создаем менеджер локаций
	_create_location_manager()
	
	# Создаем точки интереса (POI) на карте
	_create_location_pois()
	
	# Обновляем позиции POI при изменении размера окна
	get_viewport().size_changed.connect(_update_poi_positions)
	
	# Обрабатываем движение мыши для подсветки POI
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	print("DEBUG: LocationSelector готов, фон кликабелен")

func _create_location_manager():
	# Получаем LocationManager как Autoload
	location_manager = get_node_or_null("/root/LocationManager")
	if not location_manager:
		print("ОШИБКА: LocationManager не найден как Autoload!")
		return
	


func _on_background_clicked(event: InputEvent):
	"""Обработка клика по фону"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Используем глобальные координаты мыши для точности
		var global_mouse_pos = get_global_mouse_position()
		
		# Проверяем клик по POI (точкам интереса)
		var clicked_result = _get_location_at_poi_click(global_mouse_pos)
		
		# Проверяем, это клик на Колодец душ или на локацию
		if typeof(clicked_result) == TYPE_STRING and clicked_result == "soul_well":
			# Клик на Колодец душ - возвращаемся на экран подготовки
			_on_back_pressed()
		elif clicked_result != null and typeof(clicked_result) == TYPE_OBJECT:
			# Клик на локацию - показываем окно выбора
			_show_location_selection_window(clicked_result)
	
	# Обрабатываем движение мыши для подсветки POI
	if event is InputEventMouseMotion:
		_update_poi_highlight()

func _on_mouse_entered():
	"""Курсор вошел в область Control"""
	_update_poi_highlight()

func _on_mouse_exited():
	"""Курсор вышел из области Control"""
	_clear_poi_highlight()

func _update_poi_highlight():
	"""Обновляет подсветку POI при наведении курсора"""
	var global_mouse_pos = get_global_mouse_position()
	var hover_radius = 100.0  # Радиус наведения (в пикселях)
	
	# Проверяем каждую POI
	for poi_id in location_poi_sprites:
		var poi_sprite = location_poi_sprites[poi_id]
		if not poi_sprite or not is_instance_valid(poi_sprite):
			continue
		
		var poi_pos = poi_sprite.global_position
		var distance = global_mouse_pos.distance_to(poi_pos)
		
		if distance <= hover_radius:
			# Курсор рядом с POI
			if poi_id == "soul_well":
				# Колодец душ - голубая подсветка при наведении (кликабелен)
				poi_sprite.modulate = Color(0.2, 0.8, 1.0, 1.0)  # Голубой
			else:
				# Проверяем доступность локации
				var is_unlocked = _is_location_unlocked(poi_id)
				var is_coming_soon = poi_configs.get(poi_id, {}).get("coming_soon", false)
				
				if is_unlocked and not is_coming_soon:
					# Доступная локация - зеленый при наведении
					poi_sprite.modulate = Color(0.2, 1.0, 0.2, 1.0)
				elif is_coming_soon:
					# В разработке - остается красной
					poi_sprite.modulate = Color(1.0, 0.2, 0.2, 1.0)
				else:
					# Заблокированная - остается красной
					poi_sprite.modulate = Color(1.0, 0.2, 0.2, 1.0)
		else:
			# Курсор далеко - возвращаем базовый цвет
			_set_poi_base_color(poi_id, poi_sprite)

func _clear_poi_highlight():
	"""Убирает подсветку со всех POI"""
	for poi_id in location_poi_sprites:
		var poi_sprite = location_poi_sprites[poi_id]
		if not poi_sprite or not is_instance_valid(poi_sprite):
			continue
		
		_set_poi_base_color(poi_id, poi_sprite)

func _update_poi_colors():
	"""Обновляет цвета всех POI на основе доступности локаций"""
	for poi_id in location_poi_sprites:
		if poi_id == "soul_well":
			continue  # Колодец душ не меняет цвет
		
		var poi_sprite = location_poi_sprites[poi_id]
		if not poi_sprite or not is_instance_valid(poi_sprite):
			continue
		
		_set_poi_base_color(poi_id, poi_sprite)

func _set_poi_base_color(poi_id: String, poi_sprite: AnimatedSprite2D):
	"""Устанавливает базовый цвет POI на основе доступности"""
	if poi_id == "soul_well":
		poi_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Белый для колодца
		return
	
	var is_unlocked = _is_location_unlocked(poi_id)
	var is_coming_soon = poi_configs.get(poi_id, {}).get("coming_soon", false)
	
	if is_coming_soon:
		# В разработке - красный
		poi_sprite.modulate = Color(1.0, 0.2, 0.2, 1.0)
	elif is_unlocked:
		# Доступная локация - голубой
		poi_sprite.modulate = Color(0.3, 0.6, 1.0, 1.0)
	else:
		# Заблокированная локация - красный
		poi_sprite.modulate = Color(1.0, 0.2, 0.2, 1.0)

func _is_location_unlocked(location_id: String) -> bool:
	"""Проверяет, разблокирована ли локация"""
	if not location_manager:
		return false
	
	var location = location_manager.get_location(location_id)
	if not location:
		return false
	
	return location.is_unlocked



func _create_location_pois():
	"""Создает анимированные точки интереса на карте для каждой локации"""
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Маппинг локаций на пути к SpriteFrames ресурсам
	# НАСТРОЙКА ПОЗИЦИЙ: Измените значения ниже, чтобы переместить точки интереса на карте
	poi_configs = {
		"dungeon": {
			"sprite_frames_path": "res://Assets/Sprites/MapPOI/DungeonPOI.tres",
			"animation_name": "idle",
			"x_percent": 0.075,  # Горизонтальная позиция: 0.0 = слева, 1.0 = справа
			"y_offset_percent": 0.5,  # Вертикальная позиция: 0.0 = верх экрана, 1.0 = низ экрана
			"x_offset": 860.0,  # Смещение по X от x_percent (в пикселях, положительное = вправо)
			"y_offset": 40.0,  # Смещение по Y от y_offset_percent (в пикселях, положительное = вниз)
			"scale": Vector2(1.0, 1.0)  # Масштаб: Vector2(2.0, 2.0) = в 2 раза больше
		},
		"forest": {
			"sprite_frames_path": "res://Assets/Sprites/MapPOI/ForestPOI.tres",
			"animation_name": "idle",
			"x_percent": 0.375,  # Горизонтальная позиция (бывшая позиция dark_forest)
			"y_offset_percent": 0.5,
			"x_offset": 30.0,
			"y_offset": 300.0,
			"scale": Vector2(1.0, 1.0)
		},
		"cemetery": {
			"sprite_frames_path": "res://Assets/Sprites/MapPOI/CemeteryPOI.tres",
			"animation_name": "idle",
			"x_percent": 0.525,  # Горизонтальная позиция
			"y_offset_percent": 0.5,
			"x_offset": 420.0,
			"y_offset": 240.0,
			"scale": Vector2(1.0, 1.0)
		},
		"sinister_swamps": {  # Туманные болота
			"sprite_frames_path": "res://Assets/Sprites/MapPOI/SwampPOI.tres",
			"animation_name": "idle",
			"x_percent": 0.45,  # Горизонтальная позиция
			"y_offset_percent": 0.6,
			"x_offset": -450.0,
			"y_offset": 70.0,
			"scale": Vector2(1.0, 1.0)
		},
		"demon_lair": {  # Демоническое логово
			"sprite_frames_path": "res://Assets/Sprites/MapPOI/DemonCitadelPOI.tres",
			"animation_name": "idle",
			"x_percent": 0.85,  # Горизонтальная позиция
			"y_offset_percent": 0.5,
			"x_offset": -220.0,
			"y_offset": -180.0,
			"scale": Vector2(1.0, 1.0)
		},
		"mysterious_wastelands": {  # Древняя пещера (в разработке)
			"sprite_frames_path": "res://Assets/Sprites/MapPOI/CavePOI.tres",
			"animation_name": "idle",
			"x_percent": 0.65,  # Горизонтальная позиция
			"y_offset_percent": 0.5,
			"x_offset": 540.0,
			"y_offset": -80.0,
			"scale": Vector2(1.0, 1.0),
			"coming_soon": true
		},
		"volcanic_valley": {  # Вулканическая долина (в разработке)
			"sprite_frames_path": "res://Assets/Sprites/MapPOI/VolcanicPOI.tres",
			"animation_name": "idle",
			"x_percent": 0.75,  # Горизонтальная позиция
			"y_offset_percent": 0.55,
			"x_offset": 50.0,
			"y_offset": -80.0,
			"scale": Vector2(1.0, 1.0),
			"coming_soon": true
		},
	"dark_forest": {  # Гиблый лес
		"sprite_frames_path": "res://Assets/Sprites/MapPOI/DarkForestPOI.tres",
		"animation_name": "idle",
		"x_percent": 0.2,  # Горизонтальная позиция
		"y_offset_percent": 0.5,
		"x_offset": -180.0,
		"y_offset": 30.0,
		"scale": Vector2(1.0, 1.0)
	},
		"angel_halls": {  # Чертоги ангелов (в разработке)
			"sprite_frames_path": "res://Assets/Sprites/MapPOI/CelestialPOI.tres",
			"animation_name": "idle",
			"x_percent": 0.9,  # Горизонтальная позиция
			"y_offset_percent": 0.3,
			"x_offset": -1290.0,
			"y_offset": -100.0,
			"scale": Vector2(1.0, 1.0),
			"coming_soon": true
		},
		"soul_well": {  # Колодец душ - отдельная точка интереса
			"sprite_frames_path": "res://Assets/Sprites/MapPOI/SoulWellPOI.tres",
			"animation_name": "idle",
			"x_percent": 0.5,  # Горизонтальная позиция: 0.0 = слева, 1.0 = справа
			"y_offset_percent": 0.3,  # Вертикальная позиция: 0.0 = верх, 1.0 = низ
			"x_offset": -155.0,  # Смещение по X (в пикселях)
			"y_offset": 270.0,  # Смещение по Y (в пикселях)
			"scale": Vector2(1.0, 1.0)
		}
	}
	
	# Создаем POI для каждой локации
	for location_id in poi_configs:
		if location_id == "soul_well":
			# Колодец душ - отдельная точка, не привязанная к области клика
			var config = poi_configs[location_id]
			_create_poi_sprite("soul_well", config, viewport_size)
		else:
			# POI для локаций - используем конфигурацию напрямую
			var config = poi_configs[location_id]
			# Если x_percent не указан, используем центр экрана
			if not config.has("x_percent"):
				config["x_percent"] = 0.5
			_create_poi_sprite(location_id, config, viewport_size)
	
	# Обновляем цвета POI на основе доступности локаций
	_update_poi_colors()

func _create_poi_sprite(poi_id: String, config: Dictionary, viewport_size: Vector2):
	"""Создает AnimatedSprite2D для точки интереса"""
	# Загружаем SpriteFrames ресурс
	var sprite_frames_path = config.get("sprite_frames_path", "")
	if sprite_frames_path == "":
		print("WARNING: Путь к SpriteFrames не указан для POI: ", poi_id)
		return
	
	var sprite_frames = load(sprite_frames_path)
	if not sprite_frames:
		print("WARNING: Не удалось загрузить SpriteFrames для POI: ", poi_id, " по пути: ", sprite_frames_path)
		return
	
	# Создаем AnimatedSprite2D
	var poi_sprite = AnimatedSprite2D.new()
	poi_sprite.name = "POI_" + poi_id
	poi_sprite.sprite_frames = sprite_frames
	poi_sprite.scale = config.get("scale", Vector2(1.0, 1.0))
	poi_sprite.z_index = 3  # Поверх фона и подсветки, но под UI элементами
	# Примечание: AnimatedSprite2D не имеет mouse_filter (это свойство Control узлов)
	# AnimatedSprite2D по умолчанию не блокирует клики, так что это не нужно
	
	# Вычисляем позицию
	var x_percent = config.get("x_percent", 0.5)
	var y_offset_percent = config.get("y_offset_percent", 0.5)
	var x_offset = config.get("x_offset", 0.0)  # Смещение по X в пикселях
	var y_offset = config.get("y_offset", 0.0)  # Смещение по Y в пикселях
	
	var x_pos = x_percent * viewport_size.x + x_offset
	var y_pos = y_offset_percent * viewport_size.y + y_offset
	
	poi_sprite.position = Vector2(x_pos, y_pos)
	
	# Проигрываем анимацию
	var animation_name = config.get("animation_name", "idle")
	if poi_sprite.sprite_frames.has_animation(animation_name):
		poi_sprite.play(animation_name)
		print("DEBUG: Создана POI для ", poi_id, " в позиции (", x_pos, ", ", y_pos, ")")
	else:
		print("WARNING: Анимация '", animation_name, "' не найдена для POI: ", poi_id)
	
	# Добавляем в сцену
	add_child(poi_sprite)
	location_poi_sprites[poi_id] = poi_sprite

func _update_poi_positions():
	"""Обновляет позиции точек интереса при изменении размера окна"""
	if poi_configs.is_empty():
		return  # Конфигурация еще не загружена
	
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Обновляем позиции POI для локаций (центр области клика)
	for location_id in location_poi_sprites:
		if location_id == "soul_well":
			# Колодец душ - фиксированная позиция
			var poi_sprite = location_poi_sprites[location_id]
			var config = poi_configs.get("soul_well", {})
			var x_percent = config.get("x_percent", 0.5)
			var y_offset_percent = config.get("y_offset_percent", 0.3)
			var x_offset = config.get("x_offset", 0.0)
			var y_offset = config.get("y_offset", 0.0)
			poi_sprite.position = Vector2(
				x_percent * viewport_size.x + x_offset,
				y_offset_percent * viewport_size.y + y_offset
			)
		else:
			# POI для локаций - используем конфигурацию напрямую
			var poi_sprite = location_poi_sprites[location_id]
			var config = poi_configs.get(location_id, {})
			var x_percent = config.get("x_percent", 0.5)
			var y_offset_percent = config.get("y_offset_percent", 0.5)
			var x_offset = config.get("x_offset", 0.0)
			var y_offset = config.get("y_offset", 0.0)
			poi_sprite.position = Vector2(
				x_percent * viewport_size.x + x_offset,
				y_offset_percent * viewport_size.y + y_offset
			)

func _get_location_at_poi_click(mouse_pos: Vector2):
	"""Определяет локацию по клику рядом с точкой интереса (POI)"""
	if not location_manager:
		return null
	
	var click_radius = 100.0  # Радиус клика вокруг POI (в пикселях)
	
	# Проверяем каждую POI
	for poi_id in location_poi_sprites:
		var poi_sprite = location_poi_sprites[poi_id]
		if not poi_sprite or not is_instance_valid(poi_sprite):
			continue
		
		var poi_pos = poi_sprite.global_position
		var distance = mouse_pos.distance_to(poi_pos)
		
		if distance <= click_radius:
			# Нашли клик рядом с POI
			if poi_id == "soul_well":
				# Колодец душ - возвращаем специальный маркер
				print("DEBUG: ✅ Клик по Колодцу душ на расстоянии ", distance, " пикселей")
				return "soul_well"
			
			# Ищем локацию напрямую в locations (независимо от разблокировки)
			if location_manager.locations.has(poi_id):
				var location = location_manager.locations[poi_id]
				print("DEBUG: ✅ Клик по POI ", poi_id, " (", location.location_name, ") на расстоянии ", distance, " пикселей")
				return location
			else:
				print("DEBUG: ❌ Локация ", poi_id, " не найдена в location_manager.locations")
	
	return null

func _show_location_selection_window(location):
	"""Показывает красивое окно выбора локации с описанием и выбором сложности"""
	# Проверяем доступность локации
	var location_id = location.location_id if location else ""
	var is_coming_soon = poi_configs.get(location_id, {}).get("coming_soon", false)
	
	# Если локация в разработке
	if is_coming_soon:
		_show_coming_soon_message(location.location_name if location else "Неизвестная локация")
		return
	
	# Если локация заблокирована
	if not location.is_unlocked:
		_show_locked_location_message(location)
		return
	
	# Закрываем предыдущее окно, если есть
	if location_selection_window:
		location_selection_window.queue_free()
	
	# Создаем новое окно
	location_selection_window = Window.new()
	location_selection_window.title = ""
	location_selection_window.size = Vector2i(550, 650)
	location_selection_window.popup_window = true
	location_selection_window.unresizable = true
	location_selection_window.always_on_top = true
	location_selection_window.borderless = true  # Убираем стандартную рамку
	
	# Центрируем окно
	var viewport_size = get_viewport().get_visible_rect().size
	location_selection_window.position = Vector2i(
		(viewport_size.x - location_selection_window.size.x) / 2,
		(viewport_size.y - location_selection_window.size.y) / 2
	)
	
	# Создаем фон окна с красивой рамкой
	var window_bg = ColorRect.new()
	window_bg.color = Color(0.08, 0.08, 0.12, 0.98)  # Темный фон
	window_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.08, 0.08, 0.12, 0.98)
	bg_style.border_width_left = 3
	bg_style.border_width_top = 3
	bg_style.border_width_right = 3
	bg_style.border_width_bottom = 3
	bg_style.border_color = Color(0.6, 0.5, 0.3, 1.0)  # Золотистая рамка
	bg_style.corner_radius_top_left = 12
	bg_style.corner_radius_top_right = 12
	bg_style.corner_radius_bottom_right = 12
	bg_style.corner_radius_bottom_left = 12
	bg_style.shadow_color = Color(0, 0, 0, 0.8)
	bg_style.shadow_size = 8
	bg_style.shadow_offset = Vector2(0, 4)
	window_bg.add_theme_stylebox_override("panel", bg_style)
	location_selection_window.add_child(window_bg)
	
	# Создаем контейнер для содержимого с отступами
	var main_container = VBoxContainer.new()
	main_container.add_theme_constant_override("separation", 20)
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_container.add_theme_constant_override("margin_left", 30)
	main_container.add_theme_constant_override("margin_top", 30)
	main_container.add_theme_constant_override("margin_right", -30)
	main_container.add_theme_constant_override("margin_bottom", -30)
	location_selection_window.add_child(main_container)
	
	# Название локации с эффектом
	var title_label = Label.new()
	title_label.text = location.location_name
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4, 1.0))  # Золотой цвет
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title_label.add_theme_constant_override("shadow_offset_x", 2)
	title_label.add_theme_constant_override("shadow_offset_y", 2)
	title_label.add_theme_constant_override("outline_size", 2)
	title_label.add_theme_color_override("font_outline_color", Color(0.2, 0.15, 0.1, 1.0))
	main_container.add_child(title_label)
	
	# Декоративная линия под заголовком
	var title_line = ColorRect.new()
	title_line.custom_minimum_size = Vector2(0, 2)
	title_line.color = Color(0.6, 0.5, 0.3, 0.6)
	main_container.add_child(title_line)
	
	# Описание в красивом контейнере
	var desc_container = PanelContainer.new()
	var desc_style = StyleBoxFlat.new()
	desc_style.bg_color = Color(0.12, 0.12, 0.16, 0.8)
	desc_style.border_width_left = 1
	desc_style.border_width_top = 1
	desc_style.border_width_right = 1
	desc_style.border_width_bottom = 1
	desc_style.border_color = Color(0.4, 0.35, 0.25, 0.5)
	desc_style.corner_radius_top_left = 8
	desc_style.corner_radius_top_right = 8
	desc_style.corner_radius_bottom_right = 8
	desc_style.corner_radius_bottom_left = 8
	desc_container.add_theme_stylebox_override("panel", desc_style)
	desc_container.custom_minimum_size = Vector2(0, 100)
	main_container.add_child(desc_container)
	
	var desc_label = Label.new()
	desc_label.text = location.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 15)
	desc_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.8, 1.0))
	desc_label.add_theme_constant_override("margin_left", 15)
	desc_label.add_theme_constant_override("margin_top", 15)
	desc_label.add_theme_constant_override("margin_right", -15)
	desc_label.add_theme_constant_override("margin_bottom", -15)
	desc_container.add_child(desc_label)
	
	# Выбор сложности
	_add_difficulty_selector_to_window(main_container, location)
	
	# Информация об уровнях врагов в красивом контейнере
	var info_container = PanelContainer.new()
	var info_style = StyleBoxFlat.new()
	info_style.bg_color = Color(0.1, 0.15, 0.1, 0.6)
	info_style.border_width_left = 1
	info_style.border_width_top = 1
	info_style.border_width_right = 1
	info_style.border_width_bottom = 1
	info_style.border_color = Color(0.3, 0.5, 0.3, 0.5)
	info_style.corner_radius_top_left = 8
	info_style.corner_radius_top_right = 8
	info_style.corner_radius_bottom_right = 8
	info_style.corner_radius_bottom_left = 8
	info_container.add_theme_stylebox_override("panel", info_style)
	main_container.add_child(info_container)
	
	var level_info_container = VBoxContainer.new()
	level_info_container.add_theme_constant_override("separation", 8)
	level_info_container.add_theme_constant_override("margin_left", 15)
	level_info_container.add_theme_constant_override("margin_top", 12)
	level_info_container.add_theme_constant_override("margin_right", -15)
	level_info_container.add_theme_constant_override("margin_bottom", -12)
	info_container.add_child(level_info_container)
	
	var level_label = Label.new()
	var player_level = _get_player_level()
	var player_manager = get_node_or_null("/root/PlayerManager")
	var selected_difficulty = 1
	if player_manager:
		var player_data = player_manager.get_player_data()
		if player_data:
			selected_difficulty = player_data.get_selected_difficulty(location.location_id)
	
	var difficulty_bonus = _get_difficulty_level_bonus(selected_difficulty)
	var max_rarity_bonus = 6
	var min_level = player_level + difficulty_bonus
	var max_level = player_level + difficulty_bonus + max_rarity_bonus
	
	level_label.text = "⚔ Уровень врагов: %d - %d" % [min_level, max_level]
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 17)
	level_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7, 1.0))
	level_label.name = "LevelLabel"
	level_info_container.add_child(level_label)
	window_level_label = level_label  # Сохраняем ссылку
	
	# Информация о врагах (в зависимости от сложности)
	var enemies_label = Label.new()
	var enemy_types = _get_enemy_types_by_difficulty(selected_difficulty)
	enemies_label.text = "👹 Типы врагов: " + ", ".join(enemy_types)
	enemies_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemies_label.add_theme_font_size_override("font_size", 13)
	enemies_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.75, 1.0))
	enemies_label.name = "EnemiesLabel"  # Для обновления при смене сложности
	level_info_container.add_child(enemies_label)
	
	# Кнопки действий с красивым стилем
	var buttons_container = HBoxContainer.new()
	buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_container.add_theme_constant_override("separation", 15)
	main_container.add_child(buttons_container)
	
	# Кнопка "Войти" - главная, золотая
	var enter_btn = Button.new()
	enter_btn.text = "⚔ Войти"
	enter_btn.custom_minimum_size = Vector2(180, 55)
	enter_btn.add_theme_font_size_override("font_size", 20)
	enter_btn.pressed.connect(_on_enter_location.bind(location))
	
	var enter_btn_style_normal = StyleBoxFlat.new()
	enter_btn_style_normal.bg_color = Color(0.3, 0.25, 0.15, 1.0)
	enter_btn_style_normal.border_width_left = 2
	enter_btn_style_normal.border_width_top = 2
	enter_btn_style_normal.border_width_right = 2
	enter_btn_style_normal.border_width_bottom = 2
	enter_btn_style_normal.border_color = Color(0.8, 0.7, 0.4, 1.0)
	enter_btn_style_normal.corner_radius_top_left = 8
	enter_btn_style_normal.corner_radius_top_right = 8
	enter_btn_style_normal.corner_radius_bottom_right = 8
	enter_btn_style_normal.corner_radius_bottom_left = 8
	enter_btn.add_theme_stylebox_override("normal", enter_btn_style_normal)
	
	var enter_btn_style_hover = StyleBoxFlat.new()
	enter_btn_style_hover.bg_color = Color(0.4, 0.35, 0.2, 1.0)
	enter_btn_style_hover.border_width_left = 2
	enter_btn_style_hover.border_width_top = 2
	enter_btn_style_hover.border_width_right = 2
	enter_btn_style_hover.border_width_bottom = 2
	enter_btn_style_hover.border_color = Color(1.0, 0.9, 0.5, 1.0)
	enter_btn_style_hover.corner_radius_top_left = 8
	enter_btn_style_hover.corner_radius_top_right = 8
	enter_btn_style_hover.corner_radius_bottom_right = 8
	enter_btn_style_hover.corner_radius_bottom_left = 8
	enter_btn.add_theme_stylebox_override("hover", enter_btn_style_hover)
	
	var enter_btn_style_pressed = StyleBoxFlat.new()
	enter_btn_style_pressed.bg_color = Color(0.2, 0.18, 0.1, 1.0)
	enter_btn_style_pressed.border_width_left = 2
	enter_btn_style_pressed.border_width_top = 2
	enter_btn_style_pressed.border_width_right = 2
	enter_btn_style_pressed.border_width_bottom = 2
	enter_btn_style_pressed.border_color = Color(0.6, 0.5, 0.3, 1.0)
	enter_btn_style_pressed.corner_radius_top_left = 8
	enter_btn_style_pressed.corner_radius_top_right = 8
	enter_btn_style_pressed.corner_radius_bottom_right = 8
	enter_btn_style_pressed.corner_radius_bottom_left = 8
	enter_btn.add_theme_stylebox_override("pressed", enter_btn_style_pressed)
	
	enter_btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5, 1.0))
	enter_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.7, 1.0))
	buttons_container.add_child(enter_btn)
	
	# Кнопка "Отмена" - вторичная
	var cancel_btn = Button.new()
	cancel_btn.text = "✕ Отмена"
	cancel_btn.custom_minimum_size = Vector2(180, 55)
	cancel_btn.add_theme_font_size_override("font_size", 20)
	cancel_btn.pressed.connect(_on_cancel_location_selection)
	
	var cancel_btn_style_normal = StyleBoxFlat.new()
	cancel_btn_style_normal.bg_color = Color(0.2, 0.2, 0.2, 1.0)
	cancel_btn_style_normal.border_width_left = 2
	cancel_btn_style_normal.border_width_top = 2
	cancel_btn_style_normal.border_width_right = 2
	cancel_btn_style_normal.border_width_bottom = 2
	cancel_btn_style_normal.border_color = Color(0.5, 0.5, 0.5, 1.0)
	cancel_btn_style_normal.corner_radius_top_left = 8
	cancel_btn_style_normal.corner_radius_top_right = 8
	cancel_btn_style_normal.corner_radius_bottom_right = 8
	cancel_btn_style_normal.corner_radius_bottom_left = 8
	cancel_btn.add_theme_stylebox_override("normal", cancel_btn_style_normal)
	
	var cancel_btn_style_hover = StyleBoxFlat.new()
	cancel_btn_style_hover.bg_color = Color(0.3, 0.3, 0.3, 1.0)
	cancel_btn_style_hover.border_width_left = 2
	cancel_btn_style_hover.border_width_top = 2
	cancel_btn_style_hover.border_width_right = 2
	cancel_btn_style_hover.border_width_bottom = 2
	cancel_btn_style_hover.border_color = Color(0.7, 0.7, 0.7, 1.0)
	cancel_btn_style_hover.corner_radius_top_left = 8
	cancel_btn_style_hover.corner_radius_top_right = 8
	cancel_btn_style_hover.corner_radius_bottom_right = 8
	cancel_btn_style_hover.corner_radius_bottom_left = 8
	cancel_btn.add_theme_stylebox_override("hover", cancel_btn_style_hover)
	
	cancel_btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
	cancel_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	buttons_container.add_child(cancel_btn)
	
	# Добавляем окно к сцене
	add_child(location_selection_window)
	location_selection_window.popup()

func _add_difficulty_selector_to_window(container: VBoxContainer, location):
	"""Добавляет красивый выбор сложности в окно"""
	var player_manager = get_node_or_null("/root/PlayerManager")
	if not player_manager:
		return
	
	var player_data = player_manager.get_player_data()
	if not player_data:
		return
	
	player_data.initialize_location_difficulty(location.location_id)
	
	var unlocked_difficulty = player_data.get_unlocked_difficulty(location.location_id)
	var selected_difficulty = player_data.get_selected_difficulty(location.location_id)
	
	# Метка "Сложность:" с иконкой
	var difficulty_label = Label.new()
	difficulty_label.text = "⚡ Сложность:"
	difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	difficulty_label.add_theme_font_size_override("font_size", 18)
	difficulty_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6, 1.0))
	container.add_child(difficulty_label)
	
	# Контейнер для кнопок сложности
	var buttons_container = HBoxContainer.new()
	buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_container.add_theme_constant_override("separation", 12)
	container.add_child(buttons_container)
	
	# Создаем 3 кнопки (I, II, III) с красивым стилем
	for diff in range(1, 4):
		var btn = Button.new()
		btn.text = _get_roman_numeral(diff)
		btn.custom_minimum_size = Vector2(70, 60)
		btn.add_theme_font_size_override("font_size", 24)
		
		if diff > unlocked_difficulty:
			# Заблокированная сложность
			btn.disabled = true
			btn.text += "\n🔒"
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1))
			var locked_style = StyleBoxFlat.new()
			locked_style.bg_color = Color(0.15, 0.15, 0.15, 1.0)
			locked_style.border_width_left = 2
			locked_style.border_width_top = 2
			locked_style.border_width_right = 2
			locked_style.border_width_bottom = 2
			locked_style.border_color = Color(0.3, 0.3, 0.3, 1.0)
			locked_style.corner_radius_top_left = 8
			locked_style.corner_radius_top_right = 8
			locked_style.corner_radius_bottom_right = 8
			locked_style.corner_radius_bottom_left = 8
			btn.add_theme_stylebox_override("normal", locked_style)
		elif diff == selected_difficulty:
			# Выбранная сложность - золотая
			btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))
			var selected_style_normal = StyleBoxFlat.new()
			selected_style_normal.bg_color = Color(0.35, 0.28, 0.15, 1.0)
			selected_style_normal.border_width_left = 3
			selected_style_normal.border_width_top = 3
			selected_style_normal.border_width_right = 3
			selected_style_normal.border_width_bottom = 3
			selected_style_normal.border_color = Color(1.0, 0.85, 0.3, 1.0)
			selected_style_normal.corner_radius_top_left = 10
			selected_style_normal.corner_radius_top_right = 10
			selected_style_normal.corner_radius_bottom_right = 10
			selected_style_normal.corner_radius_bottom_left = 10
			btn.add_theme_stylebox_override("normal", selected_style_normal)
			
			var selected_style_hover = StyleBoxFlat.new()
			selected_style_hover.bg_color = Color(0.4, 0.32, 0.18, 1.0)
			selected_style_hover.border_width_left = 3
			selected_style_hover.border_width_top = 3
			selected_style_hover.border_width_right = 3
			selected_style_hover.border_width_bottom = 3
			selected_style_hover.border_color = Color(1.0, 0.95, 0.4, 1.0)
			selected_style_hover.corner_radius_top_left = 10
			selected_style_hover.corner_radius_top_right = 10
			selected_style_hover.corner_radius_bottom_right = 10
			selected_style_hover.corner_radius_bottom_left = 10
			btn.add_theme_stylebox_override("hover", selected_style_hover)
		else:
			# Доступная, но не выбранная
			btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.8, 1.0))
			var normal_style = StyleBoxFlat.new()
			normal_style.bg_color = Color(0.2, 0.2, 0.22, 1.0)
			normal_style.border_width_left = 2
			normal_style.border_width_top = 2
			normal_style.border_width_right = 2
			normal_style.border_width_bottom = 2
			normal_style.border_color = Color(0.5, 0.5, 0.5, 1.0)
			normal_style.corner_radius_top_left = 8
			normal_style.corner_radius_top_right = 8
			normal_style.corner_radius_bottom_right = 8
			normal_style.corner_radius_bottom_left = 8
			btn.add_theme_stylebox_override("normal", normal_style)
			
			var hover_style = StyleBoxFlat.new()
			hover_style.bg_color = Color(0.25, 0.25, 0.27, 1.0)
			hover_style.border_width_left = 2
			hover_style.border_width_top = 2
			hover_style.border_width_right = 2
			hover_style.border_width_bottom = 2
			hover_style.border_color = Color(0.7, 0.7, 0.7, 1.0)
			hover_style.corner_radius_top_left = 8
			hover_style.corner_radius_top_right = 8
			hover_style.corner_radius_bottom_right = 8
			hover_style.corner_radius_bottom_left = 8
			btn.add_theme_stylebox_override("hover", hover_style)
		
		btn.pressed.connect(_on_difficulty_selected_in_window.bind(location, diff))
		buttons_container.add_child(btn)
	
	window_buttons_container = buttons_container  # Сохраняем ссылку
	
	# Кнопка BOSS (разблокируется после победы над минибоссом на сложности III)
	var boss_unlocked = player_data.is_location_boss_unlocked(location.location_id)
	var selected_mode = player_data.get_selected_mode(location.location_id)
	
	var boss_btn = Button.new()
	boss_btn.text = "BOSS"
	boss_btn.custom_minimum_size = Vector2(100, 60)
	boss_btn.add_theme_font_size_override("font_size", 20)
	
	if not boss_unlocked:
		# Заблокированный босс
		boss_btn.disabled = true
		boss_btn.text += "\n🔒"
		boss_btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1))
		var locked_style = StyleBoxFlat.new()
		locked_style.bg_color = Color(0.15, 0.15, 0.15, 1.0)
		locked_style.border_width_left = 2
		locked_style.border_width_top = 2
		locked_style.border_width_right = 2
		locked_style.border_width_bottom = 2
		locked_style.border_color = Color(0.3, 0.3, 0.3, 1.0)
		locked_style.corner_radius_top_left = 8
		locked_style.corner_radius_top_right = 8
		locked_style.corner_radius_bottom_right = 8
		locked_style.corner_radius_bottom_left = 8
		boss_btn.add_theme_stylebox_override("normal", locked_style)
	elif selected_mode == "boss":
		# Выбранный режим босса - красный/золотой
		boss_btn.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3, 1.0))
		var selected_style_normal = StyleBoxFlat.new()
		selected_style_normal.bg_color = Color(0.4, 0.15, 0.15, 1.0)
		selected_style_normal.border_width_left = 3
		selected_style_normal.border_width_top = 3
		selected_style_normal.border_width_right = 3
		selected_style_normal.border_width_bottom = 3
		selected_style_normal.border_color = Color(1.0, 0.6, 0.2, 1.0)
		selected_style_normal.corner_radius_top_left = 10
		selected_style_normal.corner_radius_top_right = 10
		selected_style_normal.corner_radius_bottom_right = 10
		selected_style_normal.corner_radius_bottom_left = 10
		boss_btn.add_theme_stylebox_override("normal", selected_style_normal)
		
		var selected_style_hover = StyleBoxFlat.new()
		selected_style_hover.bg_color = Color(0.45, 0.18, 0.18, 1.0)
		selected_style_hover.border_width_left = 3
		selected_style_hover.border_width_top = 3
		selected_style_hover.border_width_right = 3
		selected_style_hover.border_width_bottom = 3
		selected_style_hover.border_color = Color(1.0, 0.7, 0.3, 1.0)
		selected_style_hover.corner_radius_top_left = 10
		selected_style_hover.corner_radius_top_right = 10
		selected_style_hover.corner_radius_bottom_right = 10
		selected_style_hover.corner_radius_bottom_left = 10
		boss_btn.add_theme_stylebox_override("hover", selected_style_hover)
	else:
		# Доступный, но не выбранный
		boss_btn.add_theme_color_override("font_color", Color(0.9, 0.7, 0.5, 1.0))
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(0.25, 0.15, 0.15, 1.0)
		normal_style.border_width_left = 2
		normal_style.border_width_top = 2
		normal_style.border_width_right = 2
		normal_style.border_width_bottom = 2
		normal_style.border_color = Color(0.7, 0.4, 0.2, 1.0)
		normal_style.corner_radius_top_left = 8
		normal_style.corner_radius_top_right = 8
		normal_style.corner_radius_bottom_right = 8
		normal_style.corner_radius_bottom_left = 8
		boss_btn.add_theme_stylebox_override("normal", normal_style)
		
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(0.3, 0.18, 0.18, 1.0)
		hover_style.border_width_left = 2
		hover_style.border_width_top = 2
		hover_style.border_width_right = 2
		hover_style.border_width_bottom = 2
		hover_style.border_color = Color(0.9, 0.5, 0.3, 1.0)
		hover_style.corner_radius_top_left = 8
		hover_style.corner_radius_top_right = 8
		hover_style.corner_radius_bottom_right = 8
		hover_style.corner_radius_bottom_left = 8
		boss_btn.add_theme_stylebox_override("hover", hover_style)
	
	boss_btn.pressed.connect(_on_boss_mode_selected_in_window.bind(location))
	buttons_container.add_child(boss_btn)
	
	# Информация о сложности в красивом стиле
	var info_label = Label.new()
	if selected_mode == "boss":
		info_label.text = "👑 РЕЖИМ БОССА\nОсобый босс локации с уникальными наградами"
	else:
		info_label.text = _get_difficulty_description(selected_difficulty)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.add_theme_font_size_override("font_size", 13)
	info_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.7, 1.0))
	info_label.name = "DifficultyInfo"
	container.add_child(info_label)
	window_difficulty_info = info_label  # Сохраняем ссылку

func _on_difficulty_selected_in_window(location, difficulty: int):
	"""Обработка выбора сложности в окне"""
	var player_manager = get_node_or_null("/root/PlayerManager")
	if not player_manager:
		return
	
	var player_data = player_manager.get_player_data()
	if not player_data:
		return
	
	# Переключаемся в обычный режим при выборе сложности
	player_data.set_selected_mode(location.location_id, "normal")
	player_data.set_selected_difficulty(location.location_id, difficulty)
	
	# Обновляем информацию об уровнях врагов
	if window_level_label:
		var player_level = _get_player_level()
		var difficulty_bonus = _get_difficulty_level_bonus(difficulty)
		var max_rarity_bonus = 6
		var min_level = player_level + difficulty_bonus
		var max_level = player_level + difficulty_bonus + max_rarity_bonus
		window_level_label.text = "Уровень врагов: %d - %d" % [min_level, max_level]
	
	# Обновляем описание сложности
	if window_difficulty_info:
		window_difficulty_info.text = _get_difficulty_description(difficulty)
	
	# Обновляем типы врагов
	if location_selection_window:
		var enemies_label = location_selection_window.find_child("EnemiesLabel", true, false)
		if enemies_label:
			var enemy_types = _get_enemy_types_by_difficulty(difficulty)
			enemies_label.text = "👹 Типы врагов: " + ", ".join(enemy_types)
	
	# Обновляем кнопки сложности и босса
	_update_difficulty_buttons_in_window(location, difficulty)
	_update_boss_button_in_window(location)

func _on_boss_mode_selected_in_window(location):
	"""Обработка выбора режима босса в окне"""
	var player_manager = get_node_or_null("/root/PlayerManager")
	if not player_manager:
		return
	
	var player_data = player_manager.get_player_data()
	if not player_data:
		return
	
	# Проверяем, разблокирован ли босс
	if not player_data.is_location_boss_unlocked(location.location_id):
		return
	
	# Переключаемся в режим босса
	player_data.set_selected_mode(location.location_id, "boss")
	
	# Обновляем информацию
	if window_level_label:
		window_level_label.text = "👑 БОСС ЛОКАЦИИ\nОсобый противник с уникальными наградами"
	
	# Обновляем описание
	if window_difficulty_info:
		window_difficulty_info.text = "👑 РЕЖИМ БОССА\nОсобый босс локации с уникальными наградами"
	
	# Обновляем типы врагов
	if location_selection_window:
		var enemies_label = location_selection_window.find_child("EnemiesLabel", true, false)
		if enemies_label:
			enemies_label.text = "👹 Противник: Босс локации"
	
	# Обновляем кнопки сложности и босса
	_update_difficulty_buttons_in_window(location, player_data.get_selected_difficulty(location.location_id))
	_update_boss_button_in_window(location)

func _update_boss_button_in_window(location):
	"""Обновляет состояние кнопки BOSS в окне"""
	if not window_buttons_container:
		return
	
	var player_manager = get_node_or_null("/root/PlayerManager")
	if not player_manager:
		return
	
	var player_data = player_manager.get_player_data()
	if not player_data:
		return
	
	var boss_unlocked = player_data.is_location_boss_unlocked(location.location_id)
	var selected_mode = player_data.get_selected_mode(location.location_id)
	
	# Ищем кнопку BOSS
	for child in window_buttons_container.get_children():
		if child.text.begins_with("BOSS"):
			var boss_btn = child
			
			# Обновляем состояние кнопки
			if not boss_unlocked:
				boss_btn.disabled = true
				boss_btn.text = "BOSS\n🔒"
				boss_btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1))
			elif selected_mode == "boss":
				boss_btn.disabled = false
				boss_btn.text = "BOSS"
				boss_btn.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3, 1.0))
			else:
				boss_btn.disabled = false
				boss_btn.text = "BOSS"
				boss_btn.add_theme_color_override("font_color", Color(0.9, 0.7, 0.5, 1.0))
			break

func _update_difficulty_buttons_in_window(location, selected_diff: int):
	"""Обновляет кнопки сложности в окне"""
	if not window_buttons_container:
		return
	
	var player_manager = get_node_or_null("/root/PlayerManager")
	if not player_manager:
		return
	
	var player_data = player_manager.get_player_data()
	if not player_data:
		return
	
	var unlocked_difficulty = player_data.get_unlocked_difficulty(location.location_id)
	
	var selected_mode = player_data.get_selected_mode(location.location_id)
	
	# Если выбран режим босса, делаем все кнопки сложности неактивными
	if selected_mode == "boss":
		for child in window_buttons_container.get_children():
			if child is Button and (child.text.contains("I") or child.text.contains("II") or child.text.contains("III")):
				# Очищаем старые стили
				child.remove_theme_stylebox_override("normal")
				child.remove_theme_color_override("font_color")
				# Делаем кнопки сложности неактивными при выборе босса
				child.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	else:
		# Обычный режим - обновляем кнопки сложности
		var btn_index = 0
		for child in window_buttons_container.get_children():
			if child is Button and (child.text.contains("I") or child.text.contains("II") or child.text.contains("III")):
				btn_index += 1
				var diff = btn_index
				
				# Очищаем старые стили
				child.remove_theme_stylebox_override("normal")
				child.remove_theme_color_override("font_color")
				
				if diff == selected_diff:
					child.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1))
					var stylebox = StyleBoxFlat.new()
					stylebox.bg_color = Color(0.3, 0.25, 0.1, 1.0)
					stylebox.border_width_left = 2
					stylebox.border_width_top = 2
					stylebox.border_width_right = 2
					stylebox.border_width_bottom = 2
					stylebox.border_color = Color(1.0, 0.8, 0.2, 1.0)
					child.add_theme_stylebox_override("normal", stylebox)
				elif diff > unlocked_difficulty:
					child.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1))
				else:
					child.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))

func _on_enter_location(location):
	"""Обработка нажатия кнопки 'Войти'"""
	# Закрываем окно
	if location_selection_window:
		location_selection_window.queue_free()
		location_selection_window = null
		window_level_label = null
		window_difficulty_info = null
		window_buttons_container = null
	
	# Выбираем локацию
	_on_location_selected(location)

func _on_cancel_location_selection():
	"""Обработка нажатия кнопки 'Отмена'"""
	if location_selection_window:
		location_selection_window.queue_free()
		location_selection_window = null
		window_level_label = null
		window_difficulty_info = null
		window_buttons_container = null

func _create_location_card(location):
	var card_container = VBoxContainer.new()
	card_container.add_theme_constant_override("separation", 10)
	
	# Заголовок локации
	var title_label = Label.new()
	title_label.text = location.location_name
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.4, 1))
	card_container.add_child(title_label)
	
	# Описание
	var desc_label = Label.new()
	desc_label.text = location.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 14)
	card_container.add_child(desc_label)
	
	# Кнопки выбора сложности
	_add_difficulty_selector(card_container, location)
	
	# Информация о уровнях врагов (зависит от уровня игрока и сложности)
	var level_label = Label.new()
	var player_level = _get_player_level()
	var player_manager = get_node_or_null("/root/PlayerManager")
	var selected_difficulty = 1
	if player_manager:
		var player_data = player_manager.get_player_data()
		if player_data:
			selected_difficulty = player_data.get_selected_difficulty(location.location_id)
	
	var difficulty_bonus = _get_difficulty_level_bonus(selected_difficulty)
	var max_rarity_bonus = 6  # Максимальный бонус от мифической редкости
	var min_level = player_level + difficulty_bonus
	var max_level = player_level + difficulty_bonus + max_rarity_bonus
	
	level_label.text = "Уровень врагов: %d - %d" % [min_level, max_level]
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 16)
	level_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6, 1))
	level_label.name = "LevelLabel"  # Для обновления при смене сложности
	card_container.add_child(level_label)
	
	# Информация о врагах
	var enemies_label = Label.new()
	var enemy_types = []
	for pool in location.enemy_pools:
		if pool.rarity != "common" or enemy_types.size() < 3:  # Показываем только редких или первых 3
			enemy_types.append(_get_rarity_display_name(pool.rarity))
	enemies_label.text = "Типы врагов: " + ", ".join(enemy_types)
	enemies_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemies_label.add_theme_font_size_override("font_size", 12)
	enemies_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	card_container.add_child(enemies_label)
	
	# Кнопка выбора
	var select_btn = Button.new()
	select_btn.text = "Выбрать локацию"
	select_btn.pressed.connect(_on_location_selected.bind(location))
	card_container.add_child(select_btn)
	
	# Разделитель
	var separator = HSeparator.new()
	card_container.add_child(separator)
	
	# Добавляем карточку в список
	location_list.add_child(card_container)

func _get_rarity_display_name(rarity: String) -> String:
	match rarity:
		"common":
			return "Обычные"
		"uncommon":
			return "Необычные"
		"rare":
			return "Редкие"
		"epic":
			return "Эпические"
		"legendary":
			return "Легендарные"
		"mythic":
			return "Мифические"
		_:
			return "Неизвестные"

func _get_player_level() -> int:
	"""Возвращает текущий уровень игрока"""
	var player_manager = get_node_or_null("/root/PlayerManager")
	if player_manager and player_manager.has_method("get_player_data"):
		var player_data = player_manager.get_player_data()
		if player_data:
			return player_data.level
	return 1

func _get_difficulty_level_bonus(difficulty: int) -> int:
	"""Возвращает бонус к уровню врагов от сложности"""
	match difficulty:
		1:
			return 0
		2:
			return 2
		3:
			return 5
		_:
			return 0

func _add_difficulty_selector(container: VBoxContainer, location):
	"""Добавляет кнопки выбора сложности"""
	var player_manager = get_node_or_null("/root/PlayerManager")
	if not player_manager:
		return
	
	var player_data = player_manager.get_player_data()
	if not player_data:
		return
	
	# Инициализируем сложность для локации если нужно
	player_data.initialize_location_difficulty(location.location_id)
	
	var unlocked_difficulty = player_data.get_unlocked_difficulty(location.location_id)
	var selected_difficulty = player_data.get_selected_difficulty(location.location_id)
	
	# Метка "Сложность:"
	var difficulty_label = Label.new()
	difficulty_label.text = "Сложность:"
	difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	difficulty_label.add_theme_font_size_override("font_size", 14)
	difficulty_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	container.add_child(difficulty_label)
	
	# Контейнер для кнопок сложности
	var buttons_container = HBoxContainer.new()
	buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_container.add_theme_constant_override("separation", 10)
	container.add_child(buttons_container)
	
	# Создаем 3 кнопки (I, II, III)
	for diff in range(1, 4):
		var btn = Button.new()
		btn.text = _get_roman_numeral(diff)
		btn.custom_minimum_size = Vector2(60, 40)
		btn.add_theme_font_size_override("font_size", 18)
		
		if diff > unlocked_difficulty:
			# Недоступная сложность
			btn.disabled = true
			btn.text += "\n🔒"
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1))
		elif diff == selected_difficulty:
			# Выбранная сложность
			btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1))
			var stylebox = StyleBoxFlat.new()
			stylebox.bg_color = Color(0.3, 0.25, 0.1, 1.0)
			stylebox.border_width_left = 2
			stylebox.border_width_top = 2
			stylebox.border_width_right = 2
			stylebox.border_width_bottom = 2
			stylebox.border_color = Color(1.0, 0.8, 0.2, 1.0)
			btn.add_theme_stylebox_override("normal", stylebox)
		else:
			# Доступная, но не выбранная
			btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
		
		btn.pressed.connect(_on_difficulty_selected.bind(location, diff, container))
		buttons_container.add_child(btn)
	
	# Информация о сложности
	var info_label = Label.new()
	info_label.text = _get_difficulty_description(selected_difficulty)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.add_theme_font_size_override("font_size", 11)
	info_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	info_label.name = "DifficultyInfo"
	container.add_child(info_label)

func _get_roman_numeral(number: int) -> String:
	"""Возвращает римскую цифру"""
	match number:
		1:
			return "I"
		2:
			return "II"
		3:
			return "III"
		_:
			return str(number)

func _get_difficulty_description(difficulty: int) -> String:
	"""Возвращает описание сложности"""
	match difficulty:
		1:
			return "Обычные, Необычные, Редкие враги"
		2:
			return "+2 уровня врагам • Эпические и Легендарные враги"
		3:
			return "+5 уровней врагам • Мифические враги"
		_:
			return ""

func _get_enemy_types_by_difficulty(difficulty: int) -> Array[String]:
	"""Возвращает список типов врагов в зависимости от сложности"""
	var types: Array[String] = []
	
	# Всегда есть на первой сложности
	types.append(_get_rarity_display_name("common"))
	types.append(_get_rarity_display_name("uncommon"))
	types.append(_get_rarity_display_name("rare"))
	
	# Вторая сложность добавляет эпических и легендарных
	if difficulty >= 2:
		types.append(_get_rarity_display_name("epic"))
		types.append(_get_rarity_display_name("legendary"))
	
	# Третья сложность добавляет мифических
	if difficulty >= 3:
		types.append(_get_rarity_display_name("mythic"))
	
	return types

func _on_difficulty_selected(location, difficulty: int, container: VBoxContainer):
	"""Обработка выбора сложности"""
	var player_manager = get_node_or_null("/root/PlayerManager")
	if not player_manager:
		return
	
	var player_data = player_manager.get_player_data()
	if not player_data:
		return
	
	# Устанавливаем выбранную сложность
	player_data.set_selected_difficulty(location.location_id, difficulty)
	
	# Обновляем отображение карточки
	_update_location_card(container, location, difficulty)

func _update_location_card(container: VBoxContainer, location, new_difficulty: int):
	"""Обновляет карточку локации после смены сложности"""
	# Обновляем информацию об уровнях врагов
	var level_label = container.get_node_or_null("LevelLabel")
	if level_label:
		var player_level = _get_player_level()
		var difficulty_bonus = _get_difficulty_level_bonus(new_difficulty)
		var max_rarity_bonus = 6
		var min_level = player_level + difficulty_bonus
		var max_level = player_level + difficulty_bonus + max_rarity_bonus
		level_label.text = "Уровень врагов: %d - %d" % [min_level, max_level]
	
	# Обновляем описание сложности
	var info_label = container.get_node_or_null("DifficultyInfo")
	if info_label:
		info_label.text = _get_difficulty_description(new_difficulty)
	
	# Перестраиваем кнопки сложности
	for child in container.get_children():
		if child is HBoxContainer:
			# Это контейнер с кнопками сложности
			_rebuild_difficulty_buttons(child, location, new_difficulty)
			break

func _rebuild_difficulty_buttons(buttons_container: HBoxContainer, location, selected_diff: int):
	"""Перестраивает кнопки сложности с новым выделением"""
	var player_manager = get_node_or_null("/root/PlayerManager")
	if not player_manager:
		return
	
	var player_data = player_manager.get_player_data()
	if not player_data:
		return
	
	var unlocked_difficulty = player_data.get_unlocked_difficulty(location.location_id)
	
	var btn_index = 0
	for child in buttons_container.get_children():
		if child is Button:
			btn_index += 1
			var diff = btn_index
			
			# Очищаем старые стили
			child.remove_theme_stylebox_override("normal")
			child.remove_theme_color_override("font_color")
			
			if diff == selected_diff:
				# Выбранная сложность
				child.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1))
				var stylebox = StyleBoxFlat.new()
				stylebox.bg_color = Color(0.3, 0.25, 0.1, 1.0)
				stylebox.border_width_left = 2
				stylebox.border_width_top = 2
				stylebox.border_width_right = 2
				stylebox.border_width_bottom = 2
				stylebox.border_color = Color(1.0, 0.8, 0.2, 1.0)
				child.add_theme_stylebox_override("normal", stylebox)
			elif diff > unlocked_difficulty:
				# Недоступная
				child.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1))
			else:
				# Доступная, но не выбранная
				child.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))

func _show_coming_soon_message(location_name: String):
	"""Показывает сообщение о локации в разработке"""
	var dialog = AcceptDialog.new()
	dialog.title = "Скоро будет доступно"
	dialog.dialog_text = """🔒 ЛОКАЦИЯ В РАЗРАБОТКЕ

%s

Эта локация будет доступна в релизной версии игры!

Следите за обновлениями.""" % location_name
	
	dialog.get_ok_button().text = "Понятно"
	dialog.min_size = Vector2(400, 250)
	
	add_child(dialog)
	dialog.popup_centered()

func _show_locked_location_message(location):
	"""Показывает сообщение о заблокированной локации"""
	if not location:
		return
	
	var required_location_name = ""
	if location.required_previous_location != "":
		var required_location = location_manager.get_location(location.required_previous_location)
		if required_location:
			required_location_name = required_location.location_name
	
	var dialog = AcceptDialog.new()
	dialog.title = "Локация заблокирована"
	
	if required_location_name != "":
		dialog.dialog_text = """🔒 ЛОКАЦИЯ НЕДОСТУПНА

%s

Для открытия этой локации необходимо победить босса локации:
"%s"

Вперед к приключениям!""" % [location.location_name, required_location_name]
	else:
		dialog.dialog_text = """🔒 ЛОКАЦИЯ НЕДОСТУПНА

%s

Для открытия этой локации необходимо пройти предыдущие локации.""" % location.location_name
	
	dialog.get_ok_button().text = "Понятно"
	dialog.min_size = Vector2(450, 300)
	
	# Стилизуем под dark fantasy
	dialog.add_theme_color_override("title_color", Color(1.0, 0.85, 0.4, 1.0))
	
	add_child(dialog)
	dialog.popup_centered()

func _on_location_selected(location):
	location_manager.set_current_location(location.location_id)
	
	# Меняем музыку в зависимости от локации
	_change_music_for_location(location.location_id)
	
	# Проверяем, является ли это тестовой ареной
	if location.location_id == "test_arena":
		# Переходим к тестовой арене
		SceneTransition.change_scene("res://Scenes/TestArena.tscn")
	else:
		# Переходим к выбору комнат
		SceneTransition.change_scene("res://Scenes/RoomSelector.tscn")

func _on_back_pressed():
	print("Возвращаемся к экрану подготовки персонажа...")
	
	# Осколки душ за забег уже перенесены в хранилище при завершении уровня
	# (в RoomSelector.gd при вызове _return_to_location_selector())
	
	# Возвращаем основную музыку главного меню
	_return_to_main_menu_music()
	
	# Переходим к экрану подготовки персонажа
	SceneTransition.change_scene("res://Scenes/UI/CharacterPreparation.tscn")

func _on_refresh_pressed():
	print("Обновляем список локаций...")
	# Обновление не требуется, так как список больше не используется

func _change_music_for_location(location_id: String):
	"""Меняет музыку в зависимости от выбранной локации"""
	var music_player = get_node_or_null("/root/MusicPlayer")
	if not music_player:
		print("MusicPlayer не найден")
		return
	
	match location_id:
		"dungeon":
			# Подземелье под городом - Action 4 Loop
			var dungeon_music = preload("res://Audio/Music/Background/Action 4 Loop.ogg")
			if dungeon_music:
				music_player.play_music(dungeon_music, true, true)  # fade_in=true, crossfade=true
		"forest", "mountain", "volcano", "void":
			# Остальные локации - Action 5 Loop
			var default_music = preload("res://Audio/Music/Background/Action 5 Loop.ogg")
			if default_music:
				music_player.play_music(default_music, true, true)  # fade_in=true, crossfade=true
		_:
			# Неизвестная локация - Action 5 Loop
			var default_music = preload("res://Audio/Music/Background/Action 5 Loop.ogg")
			if default_music:
				music_player.play_music(default_music, true, true)  # fade_in=true, crossfade=true

func _return_to_main_menu_music():
	"""Возвращает музыку главного меню"""
	var music_player = get_node_or_null("/root/MusicPlayer")
	if music_player:
		var main_menu_music = preload("res://Audio/Music/Background/Action 5 Loop.ogg")
		if main_menu_music:
			music_player.play_music(main_menu_music, true, true)  # fade_in=true, crossfade=true
	else:
		print("MusicPlayer не найден")

func _create_test_arena_manually():
	"""Создает тестовую арену вручную, если её нет в LocationManager"""
	print("Создаем тестовую арену вручную...")
	
	# Загружаем класс LocationData
	var LocationDataClass = preload("res://Scripts/LocationData.gd")
	var EnemyPool = preload("res://Scripts/LocationManagerAutoload.gd").EnemyPool
	
	# Создаем тестовую арену
	var test_arena = LocationDataClass.new()
	test_arena.location_id = "test_arena"
	test_arena.location_name = "Тестовая арена"
	test_arena.description = "Специальная арена для тестирования боев с любыми врагами. Здесь можно сражаться бесконечно и выбирать противников."
	test_arena.min_level = 1
	test_arena.max_level = 50
	test_arena.is_unlocked = true  # Всегда доступна
	test_arena.boss_enemy = "TestBoss"
	test_arena.exp_reward = 0  # Не даем опыт в тестовой арене
	test_arena.gold_reward = 0  # Не даем золото в тестовой арене
	
	# Добавляем всех врагов для тестирования
	test_arena.enemy_pools = [
		# Обычные враги
		EnemyPool.new("res://Scenes/Battle/Enemy_Rat.tscn", "common", 100, 1, 50),
		EnemyPool.new("res://Scenes/Battle/Enemy_Bat.tscn", "common", 100, 1, 50),
		EnemyPool.new("res://Scenes/Battle/Enemy_Slime.tscn", "common", 100, 1, 50),
		EnemyPool.new("res://Scenes/Battle/Enemy_RottenSlime.tscn", "common", 100, 1, 50),
		
		# Демоны
		EnemyPool.new("res://Scenes/Battle/Enemy_AlkaraDemon.tscn", "uncommon", 100, 1, 50),
		EnemyPool.new("res://Scenes/Battle/Enemy_CurseDemon.tscn", "uncommon", 100, 1, 50),
		EnemyPool.new("res://Scenes/Battle/Enemy_ExecutionerDemon.tscn", "rare", 100, 1, 50),
		EnemyPool.new("res://Scenes/Battle/Enemy_TharnokDemon.tscn", "rare", 100, 1, 50),
		
		# Гоблины
		EnemyPool.new("res://Scenes/Battle/Enemy_Goblin.tscn", "common", 100, 1, 50),
		EnemyPool.new("res://Scenes/Battle/Enemy_GoblinWarrior.tscn", "common", 100, 1, 50),
		EnemyPool.new("res://Scenes/Battle/Enemy_GoblinThief.tscn", "uncommon", 100, 1, 50),
		EnemyPool.new("res://Scenes/Battle/Enemy_GoblinMage.tscn", "uncommon", 100, 1, 50),
		
		# Боссы
		EnemyPool.new("res://Scenes/Battle/Enemy_DarkStalker.tscn", "epic", 100, 1, 50),
		EnemyPool.new("res://Scenes/Battle/Enemy_TharnokDemon.tscn", "legendary", 100, 1, 50)
	]
	
	# Добавляем в LocationManager
	location_manager.locations["test_arena"] = test_arena

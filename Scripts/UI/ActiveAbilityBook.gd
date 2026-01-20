# res://Scripts/UI/ActiveAbilityBook.gd
extends Control

## UI для просмотра прогресса изучения активных способностей

var current_filter = "all"

# Цвета для редкостей
var rarity_colors = {
	"common": Color(0.8, 0.8, 0.8),
	"uncommon": Color(0.3, 1, 0.3),
	"rare": Color(0.3, 0.5, 1),
	"epic": Color(0.7, 0.3, 1),
	"legendary": Color(1, 0.6, 0.1)
}

# Иконки типов урона
var damage_type_icons = {
	"physical": "⚔️",
	"magic": "✨",
	"poison": "☠️",
	"shadow": "🌑"
}

func _ready():
	_populate_ability_list()
	
	# Подключаемся к сигналам системы изучения
	if ActiveAbilityLearningSystem:
		ActiveAbilityLearningSystem.progress_updated.connect(_on_progress_updated)
		ActiveAbilityLearningSystem.ability_learned.connect(_on_ability_learned)

func _populate_ability_list():
	"""Заполняет список способностей"""
	var ability_list = $MarginContainer/VBoxContainer/ScrollContainer/AbilityList
	
	# Очищаем список
	for child in ability_list.get_children():
		child.queue_free()
	
	if not ActiveAbilityLearningSystem:
		return
	
	# Получаем все способности
	var all_abilities = ActiveAbilityLearningSystem.get_all_abilities()
	
	# Сортируем по редкости
	var sorted_abilities = []
	for rarity in ["common", "uncommon", "rare", "epic", "legendary"]:
		for ability_id in all_abilities:
			var progress_data = ActiveAbilityLearningSystem.get_ability_progress(ability_id)
			if progress_data["rarity"] == rarity:
				sorted_abilities.append(ability_id)
	
	# Создаем карточки способностей
	for ability_id in sorted_abilities:
		var progress_data = ActiveAbilityLearningSystem.get_ability_progress(ability_id)
		
		# Проверяем фильтр
		if current_filter != "all" and progress_data["rarity"] != current_filter:
			continue
		
		var ability_card = _create_ability_card(ability_id, progress_data)
		ability_list.add_child(ability_card)

func _create_ability_card(ability_id: String, progress_data: Dictionary) -> Control:
	"""Создаёт карточку способности"""
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 120)
	
	# Стиль карточки
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.8)
	style.border_color = rarity_colors.get(progress_data["rarity"], Color.WHITE)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	card.add_theme_stylebox_override("panel", style)
	
	# Контейнер содержимого
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	margin.add_child(vbox)
	
	# Заголовок (имя + редкость)
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	vbox.add_child(header)
	
	# Иконка типа урона
	var damage_icon = damage_type_icons.get(progress_data["damage_type"], "⚔️")
	var icon_label = Label.new()
	icon_label.text = damage_icon
	icon_label.add_theme_font_size_override("font_size", 32)
	header.add_child(icon_label)
	
	# Имя способности
	var name_label = Label.new()
	name_label.text = progress_data["ability_name"]
	name_label.add_theme_color_override("font_color", rarity_colors.get(progress_data["rarity"], Color.WHITE))
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	
	# Статус (изучена / доступна / в процессе)
	var status_label = Label.new()
	if progress_data["is_learned"]:
		status_label.text = "✅ Изучена"
		status_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
	elif progress_data["current_progress"] >= progress_data["required_progress"]:
		status_label.text = "🎓 Готова к изучению"
		status_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	else:
		status_label.text = "📚 В процессе"
		status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	status_label.add_theme_font_size_override("font_size", 20)
	header.add_child(status_label)
	
	# Описание
	var desc_label = Label.new()
	desc_label.text = progress_data["description"]
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	desc_label.add_theme_font_size_override("font_size", 18)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)
	
	# Прогресс-бар
	var progress_container = HBoxContainer.new()
	progress_container.add_theme_constant_override("separation", 10)
	vbox.add_child(progress_container)
	
	var progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(0, 30)
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar.max_value = progress_data["required_progress"]
	progress_bar.value = progress_data["current_progress"]
	progress_bar.show_percentage = false
	progress_container.add_child(progress_bar)
	
	# Кастомный стиль прогресс-бара
	var progress_style = StyleBoxFlat.new()
	progress_style.bg_color = rarity_colors.get(progress_data["rarity"], Color.WHITE)
	progress_bar.add_theme_stylebox_override("fill", progress_style)
	
	# Текст прогресса
	var progress_label = Label.new()
	progress_label.text = "%d / %d" % [progress_data["current_progress"], progress_data["required_progress"]]
	progress_label.add_theme_font_size_override("font_size", 20)
	progress_label.custom_minimum_size = Vector2(100, 0)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_container.add_child(progress_label)
	
	# Кнопка "Изучить" (только если готова)
	if not progress_data["is_learned"] and progress_data["current_progress"] >= progress_data["required_progress"]:
		var learn_button = Button.new()
		learn_button.text = "🎓 Изучить"
		learn_button.custom_minimum_size = Vector2(150, 40)
		learn_button.add_theme_font_size_override("font_size", 22)
		learn_button.pressed.connect(_on_learn_button_pressed.bind(ability_id))
		progress_container.add_child(learn_button)
	
	return card

func _on_filter_button_pressed(filter: String):
	"""Обработчик нажатия на кнопку фильтра"""
	current_filter = filter
	
	# Обновляем состояние кнопок
	var filter_container = $MarginContainer/VBoxContainer/FilterContainer
	for button in filter_container.get_children():
		if button is Button:
			button.button_pressed = false
	
	# Активируем нужную кнопку
	match filter:
		"all":
			$MarginContainer/VBoxContainer/FilterContainer/AllButton.button_pressed = true
		"common":
			$MarginContainer/VBoxContainer/FilterContainer/CommonButton.button_pressed = true
		"uncommon":
			$MarginContainer/VBoxContainer/FilterContainer/UncommonButton.button_pressed = true
		"rare":
			$MarginContainer/VBoxContainer/FilterContainer/RareButton.button_pressed = true
		"epic":
			$MarginContainer/VBoxContainer/FilterContainer/EpicButton.button_pressed = true
		"legendary":
			$MarginContainer/VBoxContainer/FilterContainer/LegendaryButton.button_pressed = true
	
	# Обновляем список
	_populate_ability_list()

func _on_learn_button_pressed(ability_id: String):
	"""Обработчик нажатия кнопки 'Изучить'"""
	if ActiveAbilityLearningSystem.learn_ability(ability_id):
		# Обновляем список
		_populate_ability_list()

func _on_close_button_pressed():
	"""Закрыть окно"""
	queue_free()

func _on_progress_updated(ability_id: String, current_progress: int, required_progress: int):
	"""Обработчик обновления прогресса"""
	# Обновляем список при обновлении прогресса
	_populate_ability_list()

func _on_ability_learned(ability_id: String, ability_name: String):
	"""Обработчик изучения способности"""
	# Показываем уведомление
	print("✨ Способность '%s' изучена!" % ability_name)
	
	# Обновляем список
	_populate_ability_list()

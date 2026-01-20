# res://Scripts/UI/AbilityLearningScreen.gd
extends Control

# UI элементы
@onready var close_button: Button = $MainPanel/VBoxContainer/Header/CloseButton
@onready var help_button: Button = $MainPanel/VBoxContainer/Header/HelpButton
@onready var abilities_container: VBoxContainer = $MainPanel/VBoxContainer/AbilitiesSection/AbilitiesScrollContainer/AbilitiesContainer
@onready var back_button: Button = $MainPanel/VBoxContainer/Footer/BackButton

# Фильтры
@onready var all_filter: Button = $MainPanel/VBoxContainer/FilterSection/FilterButtons/AllFilter
@onready var common_filter: Button = $MainPanel/VBoxContainer/FilterSection/FilterButtons/CommonFilter
@onready var uncommon_filter: Button = $MainPanel/VBoxContainer/FilterSection/FilterButtons/UncommonFilter
@onready var rare_filter: Button = $MainPanel/VBoxContainer/FilterSection/FilterButtons/RareFilter
@onready var epic_filter: Button = $MainPanel/VBoxContainer/FilterSection/FilterButtons/EpicFilter
@onready var legendary_filter: Button = $MainPanel/VBoxContainer/FilterSection/FilterButtons/LegendaryFilter
@onready var mythic_filter: Button = $MainPanel/VBoxContainer/FilterSection/FilterButtons/MythicFilter

# Данные
var ability_learning_system: Node
var passive_ability_manager: Node
var player_data: PlayerData
var current_filter: String = "all"
var current_tab: int = 0  # 0 = Обычные способности, 1 = Развитие души
var initial_tab_set: bool = false  # Флаг для установки начальной вкладки
var tab_container: TabContainer = null

# Цвета для редкости
var rarity_colors = {
	"common": Color.WHITE,
	"uncommon": Color.GREEN,
	"rare": Color.BLUE,
	"epic": Color.PURPLE,
	"legendary": Color.ORANGE,
	"mythic": Color.RED,
	"boss": Color(1.0, 0.0, 0.5)  # Ярко-малиновый для босс-способностей
}

# Статистика по редкости (общее количество способностей)
# Эти значения будут рассчитаны динамически в _ready()
var rarity_totals = {
	"common": 0,
	"uncommon": 0,
	"rare": 0,
	"epic": 0,
	"legendary": 0,
	"mythic": 0,
	"boss": 0
}

func _ready():
	# Подключаем сигналы
	close_button.pressed.connect(_on_close_button_pressed)
	help_button.pressed.connect(_on_help_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Подключаем фильтры
	all_filter.pressed.connect(_on_filter_pressed.bind("all"))
	common_filter.pressed.connect(_on_filter_pressed.bind("common"))
	uncommon_filter.pressed.connect(_on_filter_pressed.bind("uncommon"))
	rare_filter.pressed.connect(_on_filter_pressed.bind("rare"))
	epic_filter.pressed.connect(_on_filter_pressed.bind("epic"))
	legendary_filter.pressed.connect(_on_filter_pressed.bind("legendary"))
	mythic_filter.pressed.connect(_on_filter_pressed.bind("mythic"))
	
	# Получаем системы (теперь доступны как автозагрузки)
	ability_learning_system = get_node_or_null("/root/AbilityLearningSystem")
	passive_ability_manager = get_node_or_null("/root/PassiveAbilityManager")
	player_data = PlayerManager.get_player_data()
	
	# Инициализируем систему вкладок
	_setup_tab_system()
	
	# Рассчитываем реальное количество способностей по редкостям
	_calculate_rarity_totals()
	
	# Стилизуем кнопки фильтров редкости
	_style_rarity_filter_buttons()
	
	# Инициализируем UI
	_update_filter_buttons_with_progress()
	update_abilities_list()

func _calculate_rarity_totals():
	"""Рассчитывает реальное количество способностей по редкостям"""
	if not passive_ability_manager:
		print("⚠️ PassiveAbilityManager не найден, используем значения по умолчанию")
		return
	
	# Сбрасываем счетчики
	for rarity in rarity_totals.keys():
		rarity_totals[rarity] = 0
	
	# Подсчитываем способности по редкостям
	var all_abilities = passive_ability_manager.get_all_abilities()
	for ability in all_abilities:
		var rarity = ability.rarity
		if rarity in rarity_totals:
			rarity_totals[rarity] += 1
	
	# Выводим результаты в консоль для проверки
	print("📊 Реальное количество пассивных способностей по редкостям:")
	print("  Common: ", rarity_totals["common"])
	print("  Uncommon: ", rarity_totals["uncommon"])
	print("  Rare: ", rarity_totals["rare"])
	print("  Epic: ", rarity_totals["epic"])
	print("  Legendary: ", rarity_totals["legendary"])
	print("  Mythic: ", rarity_totals["mythic"])

func _update_filter_buttons_with_progress():
	"""Обновляет текст кнопок фильтров с отображением прогресса"""
	if not ability_learning_system:
		return
	
	var all_progress = ability_learning_system.get_all_progress()
	
	# Подсчитываем изученные способности по редкости
	var learned_by_rarity = {
		"common": 0,
		"uncommon": 0,
		"rare": 0,
		"epic": 0,
		"legendary": 0,
		"mythic": 0
	}
	
	# Проходим по всем способностям и подсчитываем статистику
	for ability_id in all_progress:
		var progress_data = all_progress[ability_id]
		var ability = passive_ability_manager.get_ability(ability_id)
		
		if ability:
			var rarity = ability.rarity
			if rarity in learned_by_rarity:
				# Если способность изучена, увеличиваем счетчик
				if progress_data.is_learned:
					learned_by_rarity[rarity] += 1
	
	# Обновляем текст кнопок фильтров
	common_filter.text = "Common " + str(learned_by_rarity["common"]) + "/" + str(rarity_totals["common"])
	uncommon_filter.text = "Uncommon " + str(learned_by_rarity["uncommon"]) + "/" + str(rarity_totals["uncommon"])
	rare_filter.text = "Rare " + str(learned_by_rarity["rare"]) + "/" + str(rarity_totals["rare"])
	epic_filter.text = "Epic " + str(learned_by_rarity["epic"]) + "/" + str(rarity_totals["epic"])
	legendary_filter.text = "Legendary " + str(learned_by_rarity["legendary"]) + "/" + str(rarity_totals["legendary"])
	mythic_filter.text = "Mythic " + str(learned_by_rarity["mythic"]) + "/" + str(rarity_totals["mythic"])

func update_abilities_list():
	"""Обновляет список способностей"""
	# Очищаем контейнер
	for child in abilities_container.get_children():
		child.queue_free()
	
	if not passive_ability_manager or not ability_learning_system:
		return
	
	# Получаем все способности
	var all_abilities = passive_ability_manager.get_all_abilities()
	var all_progress = ability_learning_system.get_all_progress()
	
	# Фильтруем способности по текущему фильтру и прогрессу
	var filtered_abilities = []
	for ability in all_abilities:
		# Фильтруем по вкладке
		var is_soul_ability = "soul" in ability.tags
		if current_tab == 0 and is_soul_ability:
			continue  # Вкладка "Обычные способности" - пропускаем способности души
		elif current_tab == 1 and not is_soul_ability:
			continue  # Вкладка "Развитие души" - пропускаем обычные способности
		
		# Проверяем фильтр по редкости (только для обычных способностей)
		if current_tab == 0 and current_filter != "all" and ability.rarity != current_filter:
			continue
		
		# Проверяем, есть ли прогресс изучения
		var progress_data = all_progress.get(ability.id, {})
		var current_progress = progress_data.get("current_progress", 0)
		var current_level = progress_data.get("current_level", 0)
		var is_learned = current_level > 0
		
		# Для способностей души показываем все (без ограничений по прогрессу)
		# Для обычных способностей - показываем только с прогрессом или изученные
		if current_tab == 1:
			filtered_abilities.append(ability)
		elif (current_progress > 0 or is_learned) and current_level < 3:
			filtered_abilities.append(ability)
	
	# Сортируем по редкости и названию
	filtered_abilities.sort_custom(_sort_abilities)
	
	# Создаем карточки способностей
	if filtered_abilities.size() == 0:
		# Показываем сообщение, если нет способностей с прогрессом
		var no_abilities_label = Label.new()
		if current_tab == 0:
			no_abilities_label.text = "Пока нет способностей с прогрессом изучения.\nПобедите врагов в бою, чтобы начать изучение!"
		else:
			no_abilities_label.text = "Способности развития души доступны для изучения."
		no_abilities_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_abilities_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		no_abilities_label.add_theme_color_override("font_color", Color.WHITE)
		abilities_container.add_child(no_abilities_label)
	else:
		# Для вкладки "Развитие души" группируем по категориям
		if current_tab == 1:
			_create_soul_development_categories(filtered_abilities, all_progress)
		else:
			for ability in filtered_abilities:
				_create_ability_card(ability, all_progress.get(ability.id, {}))

func _sort_abilities(a: PassiveAbility, b: PassiveAbility) -> bool:
	"""Сортирует способности по редкости и названию"""
	var rarity_order = ["common", "uncommon", "rare", "epic", "legendary", "mythic"]
	var a_rarity_index = rarity_order.find(a.rarity)
	var b_rarity_index = rarity_order.find(b.rarity)
	
	if a_rarity_index != b_rarity_index:
		return a_rarity_index < b_rarity_index
	
	return a.name < b.name

func _create_ability_card(ability: PassiveAbility, progress_data: Dictionary):
	"""Создает карточку способности"""
	var card_container = VBoxContainer.new()
	abilities_container.add_child(card_container)
	
	# Основной контейнер карточки
	var main_container = Panel.new()
	main_container.custom_minimum_size = Vector2(0, 100)
	
	# Проверяем, является ли это изученной способностью развития души
	var is_soul_ability_check = "soul" in ability.tags
	var current_level_check = progress_data.get("current_level", 0)
	
	# Визуальная индикация для изученных способностей развития души
	if is_soul_ability_check and current_level_check >= 1:
		# Создаем зеленоватый стиль для изученных способностей
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.2, 0.4, 0.2, 0.3)  # Зеленоватый оттенок
		style_box.border_color = Color(0.3, 0.6, 0.3, 0.8)  # Зеленая граница
		style_box.border_width_left = 2
		style_box.border_width_right = 2
		style_box.border_width_top = 2
		style_box.border_width_bottom = 2
		style_box.corner_radius_bottom_left = 8
		style_box.corner_radius_bottom_right = 8
		style_box.corner_radius_top_left = 8
		style_box.corner_radius_top_right = 8
		main_container.add_theme_stylebox_override("panel", style_box)
	
	card_container.add_child(main_container)
	
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 10)
	main_container.add_child(hbox)
	
	# Информация о способности
	var info_container = VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_container)
	
	# Название и редкость
	var name_label = Label.new()
	var current_level = progress_data.get("current_level", 0)
	var _is_learned = current_level > 0
	
	# Проверяем, является ли это способностью развития души
	var is_soul_ability = "soul" in ability.tags
	
	# Для способностей развития души не показываем уровень, для обычных - показываем
	var level_text = ""
	if not is_soul_ability:
		level_text = " (ур. " + str(current_level + 1) + ")" if current_level < 3 else ""
	
	# Для способностей развития души не показываем редкость в названии
	var rarity_text = ""
	if not is_soul_ability:
		rarity_text = " (" + ability.rarity.capitalize() + ")"
	
	name_label.text = ability.name + level_text + rarity_text
	name_label.add_theme_color_override("font_color", rarity_colors.get(ability.rarity, Color.WHITE))
	info_container.add_child(name_label)
	
	
	# Описание с учетом уровня
	var desc_label = Label.new()
	var ability_config = ability_learning_system.ability_learning_config.get(ability.id, {})
	var description = ability_config.get("description", ability.description)
	var level_values = ability_config.get("level_values", [])
	
	# Определяем уровень для отображения (следующий уровень для изучения или текущий максимальный)
	var display_level = current_level + 1 if current_level < 3 else 3
	var level_index = display_level - 1  # Индекс в массиве (0, 1, 2)
	
	# Определяем, нужно ли использовать проценты (проверяем наличие "X%" в описании - если "%" уже есть после X, не добавляем)
	var use_percent = "X%" in description
	
	# Если есть значения для уровней, показываем описание только для текущего/следующего уровня
	if level_values.size() > 0:
		# Получаем значение для отображаемого уровня
		var value_to_show = level_values[min(level_index, level_values.size() - 1)]
		
		# Форматируем значение
		var value_str = ""
		if value_to_show is float:
			if use_percent:
				# Если в описании уже есть "X%", не добавляем "%" - он уже есть в описании
				value_str = str(value_to_show)
			else:
				value_str = str(value_to_show)
		else:
			if use_percent:
				# Если в описании уже есть "X%", не добавляем "%" - он уже есть в описании
				value_str = str(int(value_to_show))
			else:
				value_str = str(int(value_to_show))
		
		# Заменяем плейсхолдер X на значение для текущего уровня
		description = description.replace("X", value_str)
		
		# Проверяем, есть ли вторичные значения (для способностей с двумя параметрами)
		var level_values_secondary = ability_config.get("level_values_secondary", [])
		if level_values_secondary.size() > 0:
			var secondary_value_to_show = level_values_secondary[min(level_index, level_values_secondary.size() - 1)]
			
			var secondary_value_str = ""
			# Проверяем оригинальное описание для определения формата Y (если "Y%" уже есть, не добавляем "%")
			var original_description = ability_config.get("description", ability.description)
			var secondary_use_percent = "Y%" in original_description
			
			if secondary_value_to_show is float:
				if secondary_use_percent:
					# Если в описании уже есть "Y%", не добавляем "%" - он уже есть в описании
					secondary_value_str = str(secondary_value_to_show)
				else:
					secondary_value_str = str(secondary_value_to_show)
			else:
				if secondary_use_percent:
					# Если в описании уже есть "Y%", не добавляем "%" - он уже есть в описании
					secondary_value_str = str(int(secondary_value_to_show))
				else:
					secondary_value_str = str(int(secondary_value_to_show))
			
			description = description.replace("Y", secondary_value_str)
	
	desc_label.text = description
	desc_label.add_theme_color_override("font_color", Color.WHITE)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_container.add_child(desc_label)
	
	# Определяем следующий уровень для изучения
	var next_level = current_level + 1 if current_level < 3 else 3
	var can_learn = ability_learning_system.can_learn_ability(ability.id, next_level)
	
	# Показываем информацию о прогрессе или стоимости
	var progress_info_label = Label.new()
	if current_level >= 3 or (is_soul_ability and current_level >= 1):
		# Максимальный уровень достигнут или способность души изучена
		progress_info_label.text = "✅ Изучено"
		progress_info_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))  # Ярко-зеленый
	else:
		if is_soul_ability:
			# Для способностей развития души показываем стоимость
			var cost_text = _get_soul_ability_cost(ability.rarity)
			progress_info_label.text = "Стоимость: " + cost_text
			progress_info_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
		else:
			# Для обычных способностей показываем прогресс
			progress_info_label.text = "Прогресс: " + str(int(can_learn.current_progress)) + " / " + str(int(can_learn.required_progress)) + " очков"
			progress_info_label.add_theme_color_override("font_color", Color.YELLOW)
	
	info_container.add_child(progress_info_label)
	
	# Кнопки
	var buttons_container = VBoxContainer.new()
	hbox.add_child(buttons_container)
	
	# Кнопка изучения
	var learn_button = Button.new()
	var _progress_value = progress_data.get("current_progress", 0)
	
	if current_level >= 3 or (is_soul_ability and current_level >= 1):
		# Максимальный уровень достигнут или способность души уже изучена
		learn_button.text = "Изучено"
		learn_button.disabled = true
	else:
		if is_soul_ability:
			# Для способностей развития души
			# Сначала проверяем, изучена ли предыдущая способность
			var previous_check = _check_previous_soul_ability_learned(ability.id)
			
			if not previous_check.can_learn:
				learn_button.text = previous_check.reason
				learn_button.disabled = true
			else:
				# Проверяем валюту
				var cost_text = _get_soul_ability_cost(ability.rarity)
				var has_enough = _check_soul_ability_cost(ability.rarity)
				
				if has_enough:
					learn_button.text = "Изучить (" + cost_text + ")"
					learn_button.disabled = false
				else:
					learn_button.text = "Недостаточно валюты"
					learn_button.disabled = true
		else:
			# Для обычных способностей
			if can_learn.can_learn:
				var cost = can_learn.required_soul_shards
				learn_button.text = "Купить ур. " + str(next_level) + " (" + str(cost) + " осколков)"
				learn_button.disabled = false
			else:
				# Проверяем причину недоступности
				if can_learn.reason == "Требуется изучить предыдущий уровень":
					# Предыдущий уровень не изучен
					learn_button.text = "Требуется изучить ур. " + str(next_level - 1)
					learn_button.disabled = true
				else:
					# Недостаточно прогресса
					var req_progress = can_learn.required_progress
					var curr_progress = can_learn.current_progress
					learn_button.text = "Недоступно (" + str(curr_progress) + "/" + str(req_progress) + ")"
					learn_button.disabled = true
	learn_button.custom_minimum_size = Vector2(200, 35)
	learn_button.add_theme_color_override("font_color", Color.WHITE)
	learn_button.pressed.connect(_on_learn_ability.bind(ability.id))
	buttons_container.add_child(learn_button)
	
	# Кнопка подробнее
	var details_button = Button.new()
	details_button.text = "Подробнее"
	details_button.custom_minimum_size = Vector2(120, 35)
	details_button.add_theme_color_override("font_color", Color.WHITE)
	details_button.pressed.connect(_on_show_details.bind(ability))
	buttons_container.add_child(details_button)
	
	# Устанавливаем цвет фона карточки в зависимости от статуса
	if current_level >= 3:
		main_container.add_theme_color_override("background_color", Color(0.2, 0.8, 0.2, 0.3))  # Зеленый фон (максимальный уровень)
	elif can_learn.can_learn:
		main_container.add_theme_color_override("background_color", Color(0.8, 0.8, 0.2, 0.3))  # Желтый фон (готово к покупке)
	elif can_learn.current_progress > 0:
		main_container.add_theme_color_override("background_color", Color(0.2, 0.2, 0.8, 0.3))  # Синий фон (в процессе)
	else:
		main_container.add_theme_color_override("background_color", Color(0.3, 0.3, 0.3, 0.3))  # Темный фон

func _on_filter_pressed(filter_type: String):
	"""Обработчик нажатия на фильтр"""
	# Сбрасываем все фильтры
	all_filter.button_pressed = false
	common_filter.button_pressed = false
	uncommon_filter.button_pressed = false
	rare_filter.button_pressed = false
	epic_filter.button_pressed = false
	legendary_filter.button_pressed = false
	mythic_filter.button_pressed = false
	
	# Устанавливаем активный фильтр
	current_filter = filter_type
	match filter_type:
		"all":
			all_filter.button_pressed = true
		"common":
			common_filter.button_pressed = true
		"uncommon":
			uncommon_filter.button_pressed = true
		"rare":
			rare_filter.button_pressed = true
		"epic":
			epic_filter.button_pressed = true
		"legendary":
			legendary_filter.button_pressed = true
		"mythic":
			mythic_filter.button_pressed = true
	
	# Обновляем список способностей
	update_abilities_list()

func _get_ability_cost(_rarity: String, level: int = 1) -> int:
	"""Возвращает стоимость изучения способности в зависимости от уровня"""
	match level:
		1:
			return 100
		2:
			return 1000
		3:
			return 10000
		_:
			return 100

func _on_learn_ability(ability_id: String):
	"""Покупает способность за прогресс + осколки душ (или только за валюту для способностей развития души)"""
	print("ID способности: ", ability_id)
	
	# Получаем информацию о способности
	var ability = passive_ability_manager.get_ability(ability_id)
	if not ability:
		return
	
	print("Способность найдена: ", ability.name, " (", ability.rarity, ")")
	
	# Проверяем, является ли это способностью развития души
	var is_soul_ability = "soul" in ability.tags
	
	if is_soul_ability:
		# Обрабатываем способность развития души
		_learn_soul_development_ability(ability_id, ability)
	else:
		# Обрабатываем обычную способность
		_learn_normal_ability(ability_id, ability)

func _learn_soul_development_ability(ability_id: String, ability: PassiveAbility):
	"""Изучает способность развития души за валюту"""
	# Проверяем, не изучена ли уже
	var progress_data = ability_learning_system.get_ability_progress(ability_id)
	var current_level = progress_data.get("current_level", 0)
	
	if current_level >= 1:
		_show_message_dialog("Уже изучено", "Эта способность уже изучена!")
		return
	
	# Проверяем, изучена ли предыдущая способность
	var previous_check = _check_previous_soul_ability_learned(ability_id)
	if not previous_check.can_learn:
		_show_message_dialog("Недоступно", previous_check.reason)
		return
	
	# Проверяем наличие валюты
	if not _check_soul_ability_cost(ability.rarity):
		_show_message_dialog("Недостаточно валюты", "Недостаточно валюты для изучения этой способности.\n\nТребуется: " + _get_soul_ability_cost(ability.rarity))
		return
	
	# Списываем валюту
	if _spend_soul_ability_cost(ability.rarity):
		# Изучаем способность в системе изучения
		ability_learning_system.set_ability_learned(ability_id)
		
		# Изучаем способность в PlayerData
		player_data.learn_passive_ability(ability_id)
		
		# Применяем бонус способности
		ability.execute_ability(player_data)
		
		# Сохраняем прогресс
		var player_manager = get_node_or_null("/root/PlayerManager")
		if player_manager:
			player_manager.save_game_data()
		
		# Показываем сообщение об успехе
		_show_message_dialog("Способность изучена!", "Способность '" + ability.name + "' успешно изучена!\n\nБонус применен.")
		
		# Обновляем UI
		update_abilities_list()
		_update_soul_shard_display_in_parent()
		
		print("✅ Способность развития души изучена: ", ability.name)
	else:
		_show_message_dialog("Ошибка", "Не удалось списать валюту. Попробуйте еще раз.")

func _learn_normal_ability(ability_id: String, _ability: PassiveAbility):
	"""Изучает обычную способность за прогресс + осколки душ"""
	# Получаем текущий прогресс
	var progress_data = ability_learning_system.get_ability_progress(ability_id)
	var current_level = progress_data.get("current_level", 0)
	var next_level = current_level + 1
	
	# Проверяем, можно ли изучить следующий уровень
	var can_learn = ability_learning_system.can_learn_ability(ability_id, next_level)
	
	if not can_learn.can_learn:
		print("Требуется: %d прогресса + %d осколков душ" % [can_learn.required_progress, can_learn.required_soul_shards])
		print("Есть: %d прогресса + %d осколков душ" % [can_learn.current_progress, can_learn.current_soul_shards])
		return
	
	# Изучаем способность
	var success = ability_learning_system.learn_ability(ability_id, next_level)
	if success:
		# Обновляем UI
		update_abilities_list()
		_update_soul_shard_display_in_parent()

func _show_message_dialog(title: String, message: String):
	"""Показывает диалог с сообщением"""
	var dialog = AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = message
	add_child(dialog)
	dialog.popup_centered()
	dialog.connect("confirmed", Callable(dialog, "queue_free"))

func _show_progress_insufficient_message(current: int, required: int):
	"""Показывает сообщение о недостаточном прогрессе изучения"""
	var dialog = AcceptDialog.new()
	dialog.title = "Прогресс изучения недостаточен"
	dialog.dialog_text = "Для покупки этой способности нужно достичь 100% прогресса изучения.\nТекущий прогресс: " + str(current) + "/" + str(required) + "\n\nПродолжайте побеждать врагов для увеличения прогресса!"
	add_child(dialog)
	dialog.popup_centered()
	dialog.connect("confirmed", Callable(dialog, "queue_free"))

func _show_insufficient_soul_shards_message(required: int, current: int):
	"""Показывает сообщение о недостатке осколков душ"""
	var dialog = AcceptDialog.new()
	dialog.title = "Недостаточно осколков душ"
	dialog.dialog_text = "Для покупки этой способности нужно " + str(required) + " осколков душ.\nУ вас есть: " + str(current) + " осколков."
	add_child(dialog)
	dialog.popup_centered()
	dialog.connect("confirmed", Callable(dialog, "queue_free"))

func _show_confirm_purchase_dialog(ability: PassiveAbility, cost: int):
	"""Показывает диалог подтверждения покупки"""
	var dialog = ConfirmationDialog.new()
	dialog.title = "Подтверждение покупки"
	dialog.dialog_text = "Купить способность '" + ability.name + "' за " + str(cost) + " осколков душ?\n\nСпособность будет мгновенно изучена и станет доступна для активации."
	add_child(dialog)
	dialog.popup_centered()
	
	dialog.connect("confirmed", Callable(self, "_confirm_ability_purchase").bind(ability.id, cost))
	dialog.connect("canceled", Callable(dialog, "queue_free"))

func _confirm_ability_purchase(ability_id: String, cost: int):
	"""Подтверждает покупку способности"""
	print("ID способности: ", ability_id)
	print("Стоимость: ", cost)
	
	# Списываем осколки душ
	var soul_shard_manager = get_node_or_null("/root/SoulShard")
	if not soul_shard_manager:
		print("ОШИБКА: SoulShardManager не найден!")
		return
	
	var current_shards = soul_shard_manager.get_soul_shards()
	print("Текущие осколки душ: ", current_shards)
	
	var success = soul_shard_manager.spend_soul_shards(cost)
	if success:
		print("Остаток осколков: ", soul_shard_manager.get_soul_shards())
	else:
		print("Попытка списать: ", cost, ", доступно: ", current_shards)
		return
	
	# Изучаем способность
	if ability_learning_system:
		var learn_success = ability_learning_system.learn_ability_instantly(ability_id)
		if learn_success:
			_update_filter_buttons_with_progress()
			update_abilities_list()
			print("✅ Способность изучена за осколки душ: ", ability_id)
			
			# Сохраняем игру
			var player_manager = get_node_or_null("/root/PlayerManager")
			if player_manager:
				player_manager.save_game_data()
				print("✅ Игра сохранена после изучения способности")
			
			# Обновляем отображение осколков душ в экране подготовки
			_update_soul_shard_display_in_parent()
		else:
			print("❌ ОШИБКА: не удалось изучить способность!")
	else:
		print("❌ ОШИБКА: AbilityLearningSystem не найден!")
	

func _update_soul_shard_display_in_parent():
	"""Обновляет отображение осколков душ в родительском экране подготовки"""
	print("Обновляем отображение осколков душ в экране подготовки...")
	
	# Ищем экран подготовки персонажа в дереве сцены
	var preparation_screen = get_tree().current_scene
	if preparation_screen and preparation_screen.has_method("_update_soul_shard_storage_display"):
		preparation_screen._update_soul_shard_storage_display()
		print("✅ Отображение осколков душ обновлено в экране подготовки")
	else:
		print("⚠️ Не удалось найти экран подготовки для обновления отображения осколков душ")

func _on_show_details(ability: PassiveAbility):
	"""Показывает детальную информацию о способности"""
	# Создаем диалоговое окно с подробной информацией
	var dialog = AcceptDialog.new()
	dialog.title = ability.name
	dialog.size = Vector2(500, 400)
	
	var container = VBoxContainer.new()
	dialog.add_child(container)
	
	# Название и редкость
	var name_label = Label.new()
	# Для способностей развития души не показываем редкость
	var is_soul_ability_detail = "soul" in ability.tags
	var rarity_text_detail = ""
	if not is_soul_ability_detail:
		rarity_text_detail = " (" + ability.rarity.capitalize() + ")"
	
	name_label.text = ability.name + rarity_text_detail
	name_label.add_theme_color_override("font_color", rarity_colors.get(ability.rarity, Color.WHITE))
	name_label.add_theme_font_size_override("font_size", 20)
	container.add_child(name_label)
	
	# Описание с учетом уровня
	var desc_label = Label.new()
	var ability_config = ability_learning_system.ability_learning_config.get(ability.id, {})
	var description = ability_config.get("description", ability.description)
	var level_values = ability_config.get("level_values", [])
	var progress_data = ability_learning_system.get_ability_progress(ability.id)
	var current_level = progress_data.get("current_level", 0)
	
	# Определяем уровень для отображения (следующий уровень для изучения или текущий максимальный)
	var display_level = current_level + 1 if current_level < 3 else 3
	var level_index = display_level - 1  # Индекс в массиве (0, 1, 2)
	
	# Определяем, нужно ли использовать проценты (проверяем наличие "X%" в описании - если "%" уже есть после X, не добавляем)
	var use_percent = "X%" in description
	
	# Если есть значения для уровней, показываем описание только для текущего/следующего уровня
	if level_values.size() > 0:
		# Получаем значение для отображаемого уровня
		var value_to_show = level_values[min(level_index, level_values.size() - 1)]
		
		# Форматируем значение
		var value_str = ""
		if value_to_show is float:
			if use_percent:
				# Если в описании уже есть "X%", не добавляем "%" - он уже есть в описании
				value_str = str(value_to_show)
			else:
				value_str = str(value_to_show)
		else:
			if use_percent:
				# Если в описании уже есть "X%", не добавляем "%" - он уже есть в описании
				value_str = str(int(value_to_show))
			else:
				value_str = str(int(value_to_show))
		
		# Заменяем плейсхолдер X на значение для текущего уровня
		description = description.replace("X", value_str)
		
		# Проверяем, есть ли вторичные значения (для способностей с двумя параметрами)
		var level_values_secondary = ability_config.get("level_values_secondary", [])
		if level_values_secondary.size() > 0:
			var secondary_value_to_show = level_values_secondary[min(level_index, level_values_secondary.size() - 1)]
			
			var secondary_value_str = ""
			# Проверяем оригинальное описание для определения формата Y (если "Y%" уже есть, не добавляем "%")
			var original_description = ability_config.get("description", ability.description)
			var secondary_use_percent = "Y%" in original_description
			
			if secondary_value_to_show is float:
				if secondary_use_percent:
					# Если в описании уже есть "Y%", не добавляем "%" - он уже есть в описании
					secondary_value_str = str(secondary_value_to_show)
				else:
					secondary_value_str = str(secondary_value_to_show)
			else:
				if secondary_use_percent:
					# Если в описании уже есть "Y%", не добавляем "%" - он уже есть в описании
					secondary_value_str = str(int(secondary_value_to_show))
				else:
					secondary_value_str = str(int(secondary_value_to_show))
			
			description = description.replace("Y", secondary_value_str)
	
	desc_label.text = description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(desc_label)
	
	# Дополнительная информация
	var info_label = Label.new()
	info_label.text = "Тип: " + _get_ability_type_name(ability.ability_type) + "\n"
	info_label.text += "Триггер: " + _get_trigger_type_name(ability.trigger_type) + "\n"
	info_label.text += "Значение: " + str(ability.value) + "\n"
	if ability.duration > 0:
		info_label.text += "Длительность: " + str(ability.duration) + " сек\n"
	if ability.cooldown > 0:
		info_label.text += "Перезарядка: " + str(ability.cooldown) + " сек\n"
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(info_label)
	
	# Статус изучения
	var status_label = Label.new()
	if progress_data.get("is_learned", false):
		status_label.text = "✅ Изучена"
		status_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		status_label.text = "❌ Не изучена"
		status_label.add_theme_color_override("font_color", Color.YELLOW)
	container.add_child(status_label)
	
	# Добавляем к сцене и показываем
	add_child(dialog)
	dialog.popup_centered()

func _get_ability_type_name(ability_type: int) -> String:
	"""Возвращает название типа способности"""
	match ability_type:
		PassiveAbility.AbilityType.DEFENSIVE:
			return "Защитная"
		PassiveAbility.AbilityType.OFFENSIVE:
			return "Атакующая"
		PassiveAbility.AbilityType.UTILITY:
			return "Утилитарная"
		PassiveAbility.AbilityType.SPECIAL:
			return "Особая"
		_:
			return "Неизвестная"

func _get_trigger_type_name(trigger_type: int) -> String:
	"""Возвращает название типа триггера"""
	match trigger_type:
		PassiveAbility.TriggerType.ON_ATTACK:
			return "При атаке"
		PassiveAbility.TriggerType.ON_DAMAGE_TAKEN:
			return "При получении урона"
		PassiveAbility.TriggerType.ON_TURN_START:
			return "В начале хода"
		PassiveAbility.TriggerType.ON_TURN_END:
			return "В конце хода"
		PassiveAbility.TriggerType.ON_DEATH:
			return "При смерти"
		PassiveAbility.TriggerType.PASSIVE:
			return "Постоянно активная"
		PassiveAbility.TriggerType.ON_CRIT:
			return "При критическом ударе"
		PassiveAbility.TriggerType.ON_HEAL:
			return "При лечении"
		_:
			return "Неизвестная"

func _get_soul_ability_cost(rarity: String) -> String:
	"""Возвращает текст стоимости способности развития души в зависимости от редкости"""
	match rarity:
		"common":
			return "50 ОД"
		"uncommon":
			return "100 ОД"
		"rare":
			return "150 ОД + 1 Сильная душа"
		"epic":
			return "200 ОД + 2 Сильные души"
		"legendary":
			return "300 ОД + 4 Великие души"
		"mythic":
			return "500 ОД + 8 Божественных душ"
		_:
			return "???"

func _check_previous_soul_ability_learned(ability_id: String) -> Dictionary:
	"""Проверяет, изучена ли предыдущая способность в цепочке развития души"""
	# Определяем тип способности и её номер
	var ability_type = ""
	var ability_number = 0
	
	if "soul_restoration_efficiency" in ability_id:
		ability_type = "soul_restoration_efficiency"
		ability_number = int(ability_id.replace("soul_restoration_efficiency_", ""))
	elif "soul_restoration_charges" in ability_id:
		ability_type = "soul_restoration_charges"
		ability_number = int(ability_id.replace("soul_restoration_charges_", ""))
	elif "soul_restoration_barrier" in ability_id:
		ability_type = "soul_restoration_barrier"
		ability_number = int(ability_id.replace("soul_restoration_barrier_", ""))
	elif "spiritual_power_upgrade" in ability_id:
		ability_type = "spiritual_power_upgrade"
		ability_number = int(ability_id.replace("spiritual_power_upgrade_", ""))
	elif "seer" in ability_id:
		ability_type = "seer"
		ability_number = int(ability_id.replace("seer_", ""))
	
	# Если тип способности не определен, считаем что она доступна (для независимых способностей)
	if ability_type == "":
		return {"can_learn": true, "reason": ""}
	
	# Если это первая способность в цепочке, она доступна
	if ability_number == 1:
		return {"can_learn": true, "reason": ""}
	
	# Способность "Видящий" доступна всегда (без ограничений по квестам)
	if ability_type != "seer":
		# Проверяем требования по квестам для остальных способностей
		var quest_check = _check_quest_requirements_for_level(ability_type, ability_number)
		if not quest_check.can_learn:
			return quest_check
	
	# Проверяем, изучена ли предыдущая способность
	var previous_ability_id = ability_type + "_" + str(ability_number - 1)
	var previous_progress = ability_learning_system.get_ability_progress(previous_ability_id)
	var previous_learned = previous_progress.get("current_level", 0) >= 1
	
	if not previous_learned:
		return {
			"can_learn": false,
			"reason": "Сначала изучите предыдущую способность"
		}
	
	return {"can_learn": true, "reason": ""}

func _check_quest_requirements_for_level(ability_type: String, ability_number: int) -> Dictionary:
	"""Проверяет требования по квестам для способностей разных уровней"""
	# Получаем данные игрока
	var player_manager = get_node_or_null("/root/PlayerManager")
	if not player_manager:
		return {"can_learn": true, "reason": ""}
	
	var player_data_obj = player_manager.get_player_data()
	if not player_data_obj:
		return {"can_learn": true, "reason": ""}
	
	# Для способностей 3-4 уровня требуется Кристалл познания
	if ability_number >= 3 and ability_number <= 4:
		if not player_data_obj.knowledge_crystal_delivered:
			return {
				"can_learn": false,
				"reason": "Требуется Кристалл познания"
			}
	
	# Для способностей 5-6 уровня требуется Филактерия
	if ability_number >= 5 and ability_number <= 6:
		# Для духовной мощи только 5 уровень требует Филактерию
		if ability_type == "spiritual_power_upgrade" and ability_number == 5:
			if not player_data_obj.phylactery_delivered:
				return {
					"can_learn": false,
					"reason": "Требуется Филактерия"
				}
		elif ability_type != "spiritual_power_upgrade":
			# Для остальных способностей (не духовная мощь) уровни 5-6 требуют Филактерию
			if not player_data_obj.phylactery_delivered:
				return {
					"can_learn": false,
					"reason": "Требуется Филактерия"
				}
	
	return {"can_learn": true, "reason": ""}

func _check_soul_ability_cost(rarity: String) -> bool:
	"""Проверяет, достаточно ли валюты для покупки способности"""
	var soul_shard_manager = get_node_or_null("/root/SoulShard")
	var strong_souls_manager = get_node_or_null("/root/StrongSouls")
	var great_souls_manager = get_node_or_null("/root/GreatSouls")
	var divine_souls_manager = get_node_or_null("/root/DivineSouls")
	
	if not soul_shard_manager:
		print("ОШИБКА: SoulShardManager не найден!")
		return false
	
	var current_shards = soul_shard_manager.get_soul_shards()
	print("Проверка валюты для редкости: ", rarity, " | Осколки душ: ", current_shards)
	
	match rarity:
		"common":
			var result = current_shards >= 50
			print("  Common: нужно 50, есть ", current_shards, " = ", result)
			return result
		"uncommon":
			var result = current_shards >= 100
			print("  Uncommon: нужно 100, есть ", current_shards, " = ", result)
			return result
		"rare":
			if not strong_souls_manager:
				print("  ОШИБКА: StrongSoulsManager не найден!")
				return false
			var strong_souls = strong_souls_manager.get_strong_souls()
			var result = current_shards >= 150 and strong_souls >= 1
			print("  Rare: нужно 150 ОД + 1 душа, есть ", current_shards, " ОД + ", strong_souls, " душ = ", result)
			return result
		"epic":
			if not strong_souls_manager:
				print("  ОШИБКА: StrongSoulsManager не найден!")
				return false
			var strong_souls = strong_souls_manager.get_strong_souls()
			var result = current_shards >= 200 and strong_souls >= 2
			print("  Epic: нужно 200 ОД + 2 души, есть ", current_shards, " ОД + ", strong_souls, " душ = ", result)
			return result
		"legendary":
			if not great_souls_manager:
				print("  ОШИБКА: GreatSoulsManager не найден!")
				return false
			var great_souls = great_souls_manager.get_great_souls()
			var result = current_shards >= 300 and great_souls >= 4
			print("  Legendary: нужно 300 ОД + 4 души, есть ", current_shards, " ОД + ", great_souls, " душ = ", result)
			return result
		"mythic":
			if not divine_souls_manager:
				print("  ОШИБКА: DivineSoulsManager не найден!")
				return false
			var divine_souls = divine_souls_manager.get_divine_souls()
			var result = current_shards >= 500 and divine_souls >= 8
			print("  Mythic: нужно 500 ОД + 8 душ, есть ", current_shards, " ОД + ", divine_souls, " душ = ", result)
			return result
		_:
			print("  ОШИБКА: Неизвестная редкость!")
			return false

func _spend_soul_ability_cost(rarity: String) -> bool:
	"""Списывает валюту за покупку способности. Возвращает true если успешно"""
	var soul_shard_manager = get_node_or_null("/root/SoulShard")
	var strong_souls_manager = get_node_or_null("/root/StrongSouls")
	var great_souls_manager = get_node_or_null("/root/GreatSouls")
	var divine_souls_manager = get_node_or_null("/root/DivineSouls")
	
	if not soul_shard_manager:
		return false
	
	match rarity:
		"common":
			return soul_shard_manager.spend_soul_shards(50)
		"uncommon":
			return soul_shard_manager.spend_soul_shards(100)
		"rare":
			if soul_shard_manager.spend_soul_shards(150) and strong_souls_manager and strong_souls_manager.spend_strong_souls(1):
				return true
			return false
		"epic":
			if soul_shard_manager.spend_soul_shards(200) and strong_souls_manager and strong_souls_manager.spend_strong_souls(2):
				return true
			return false
		"legendary":
			if soul_shard_manager.spend_soul_shards(300) and great_souls_manager and great_souls_manager.spend_great_souls(4):
				return true
			return false
		"mythic":
			if soul_shard_manager.spend_soul_shards(500) and divine_souls_manager and divine_souls_manager.spend_divine_souls(8):
				return true
			return false
		_:
			return false

func _create_soul_development_categories(abilities: Array, all_progress: Dictionary):
	"""Создает категории для способностей развития души"""
	# Разделяем способности по категориям
	var efficiency_abilities = []
	var charges_abilities = []
	var barrier_abilities = []
	var spiritual_power_abilities = []
	var seer_abilities = []
	
	for ability in abilities:
		if "efficiency" in ability.tags:
			efficiency_abilities.append(ability)
		elif "charges" in ability.tags:
			charges_abilities.append(ability)
		elif "barrier" in ability.tags:
			barrier_abilities.append(ability)
		elif "spiritual_power" in ability.tags:
			spiritual_power_abilities.append(ability)
		elif "seer" in ability.tags:
			seer_abilities.append(ability)
	
	# Создаем заголовок "Восстановление души"
	if efficiency_abilities.size() > 0 or charges_abilities.size() > 0 or barrier_abilities.size() > 0:
		var restoration_header = Label.new()
		restoration_header.text = "═══ ВОССТАНОВЛЕНИЕ ДУШИ ═══"
		restoration_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		restoration_header.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
		restoration_header.add_theme_font_size_override("font_size", 20)
		abilities_container.add_child(restoration_header)
		
		# Эффективность
		if efficiency_abilities.size() > 0:
			var eff_label = Label.new()
			eff_label.text = "▶ Эффективность восстановления"
			eff_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
			abilities_container.add_child(eff_label)
			
			for ability in efficiency_abilities:
				_create_ability_card(ability, all_progress.get(ability.id, {}))
		
		# Заряды
		if charges_abilities.size() > 0:
			var charges_label = Label.new()
			charges_label.text = "▶ Дополнительные заряды"
			charges_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
			abilities_container.add_child(charges_label)
			
			for ability in charges_abilities:
				_create_ability_card(ability, all_progress.get(ability.id, {}))
		
		# Барьер
		if barrier_abilities.size() > 0:
			var barrier_label = Label.new()
			barrier_label.text = "▶ Защитный барьер"
			barrier_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
			abilities_container.add_child(barrier_label)
			
			for ability in barrier_abilities:
				_create_ability_card(ability, all_progress.get(ability.id, {}))
		
		# Добавляем пустое пространство
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 20)
		abilities_container.add_child(spacer)
	
	# Создаем заголовок "Усиление души"
	if spiritual_power_abilities.size() > 0:
		var spiritual_header = Label.new()
		spiritual_header.text = "═══ УСИЛЕНИЕ ДУШИ ═══"
		spiritual_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		spiritual_header.add_theme_color_override("font_color", Color(0.8, 0.5, 1.0))
		spiritual_header.add_theme_font_size_override("font_size", 20)
		abilities_container.add_child(spiritual_header)
		
		var spiritual_label = Label.new()
		spiritual_label.text = "▶ Духовная мощь"
		spiritual_label.add_theme_color_override("font_color", Color(0.9, 0.7, 1.0))
		abilities_container.add_child(spiritual_label)
		
		for ability in spiritual_power_abilities:
			_create_ability_card(ability, all_progress.get(ability.id, {}))
	
	# Создаем заголовок "Видящий"
	if seer_abilities.size() > 0:
		# Добавляем пустое пространство
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 20)
		abilities_container.add_child(spacer)
		
		var seer_header = Label.new()
		seer_header.text = "═══ ВИДЯЩИЙ ═══"
		seer_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		seer_header.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
		seer_header.add_theme_font_size_override("font_size", 20)
		abilities_container.add_child(seer_header)
		
		var seer_label = Label.new()
		seer_label.text = "▶ Видящий"
		seer_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
		abilities_container.add_child(seer_label)
		
		# Сортируем способности "Видящий" по уровню (1, 2, 3)
		seer_abilities.sort_custom(func(a, b): return a.id < b.id)
		
		for ability in seer_abilities:
			_create_ability_card(ability, all_progress.get(ability.id, {}))

func _setup_tab_system():
	"""Инициализирует систему вкладок"""
	# Создаем TabContainer программно, если его нет
	var filter_section = get_node_or_null("MainPanel/VBoxContainer/FilterSection")
	if not filter_section:
		print("⚠️ FilterSection не найдена, вкладки не созданы")
		return
	
	# Создаем кнопки-вкладки вместо фильтров
	var filter_buttons = filter_section.get_node_or_null("FilterButtons")
	if filter_buttons:
		# Создаем две кнопки: "Обычные способности" и "Развитие души"
		var normal_abilities_btn = Button.new()
		normal_abilities_btn.text = "Обычные способности"
		normal_abilities_btn.custom_minimum_size = Vector2(200, 40)
		normal_abilities_btn.pressed.connect(_on_tab_changed.bind(0))
		
		# Стиль для кнопки "Обычные способности" - синий
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(0.2, 0.4, 0.6, 0.8)  # Синий
		normal_style.border_color = Color(0.3, 0.5, 0.7, 1.0)
		normal_style.border_width_left = 2
		normal_style.border_width_right = 2
		normal_style.border_width_top = 2
		normal_style.border_width_bottom = 2
		normal_style.corner_radius_top_left = 8
		normal_style.corner_radius_top_right = 8
		normal_style.corner_radius_bottom_left = 8
		normal_style.corner_radius_bottom_right = 8
		normal_abilities_btn.add_theme_stylebox_override("normal", normal_style)
		normal_abilities_btn.add_theme_stylebox_override("hover", normal_style)
		normal_abilities_btn.add_theme_stylebox_override("pressed", normal_style)
		normal_abilities_btn.add_theme_color_override("font_color", Color.WHITE)
		normal_abilities_btn.add_theme_font_size_override("font_size", 16)
		
		var soul_development_btn = Button.new()
		soul_development_btn.text = "Развитие души"
		soul_development_btn.custom_minimum_size = Vector2(200, 40)
		soul_development_btn.pressed.connect(_on_tab_changed.bind(1))
		
		# Стиль для кнопки "Развитие души" - фиолетовый/золотой
		var soul_style = StyleBoxFlat.new()
		soul_style.bg_color = Color(0.6, 0.3, 0.7, 0.8)  # Фиолетовый
		soul_style.border_color = Color(0.8, 0.6, 0.2, 1.0)  # Золотая граница
		soul_style.border_width_left = 2
		soul_style.border_width_right = 2
		soul_style.border_width_top = 2
		soul_style.border_width_bottom = 2
		soul_style.corner_radius_top_left = 8
		soul_style.corner_radius_top_right = 8
		soul_style.corner_radius_bottom_left = 8
		soul_style.corner_radius_bottom_right = 8
		soul_development_btn.add_theme_stylebox_override("normal", soul_style)
		soul_development_btn.add_theme_stylebox_override("hover", soul_style)
		soul_development_btn.add_theme_stylebox_override("pressed", soul_style)
		soul_development_btn.add_theme_color_override("font_color", Color.WHITE)
		soul_development_btn.add_theme_font_size_override("font_size", 16)
		
		# Очищаем существующие кнопки фильтров и добавляем новые
		# НЕ удаляем фильтры, просто добавляем вкладки в начало
		filter_buttons.add_child(normal_abilities_btn)
		filter_buttons.add_child(soul_development_btn)
		filter_buttons.move_child(normal_abilities_btn, 0)
		filter_buttons.move_child(soul_development_btn, 1)
		
		# Добавляем разделитель
		var separator = VSeparator.new()
		filter_buttons.add_child(separator)
		filter_buttons.move_child(separator, 2)

func _style_rarity_filter_buttons():
	"""Применяет цветовую стилизацию к кнопкам фильтров редкости"""
	# Словарь с цветами фона для каждой редкости
	var rarity_bg_colors = {
		"common": Color(0.5, 0.5, 0.5, 0.6),      # Серый
		"uncommon": Color(0.2, 0.6, 0.2, 0.6),    # Зеленый
		"rare": Color(0.2, 0.4, 0.8, 0.6),        # Синий
		"epic": Color(0.6, 0.2, 0.8, 0.6),        # Фиолетовый
		"legendary": Color(0.8, 0.5, 0.1, 0.6),   # Оранжевый
		"mythic": Color(0.8, 0.1, 0.1, 0.6)       # Красный
	}
	
	# Словарь с цветами рамки (более яркие версии)
	var rarity_border_colors = {
		"common": Color(0.8, 0.8, 0.8, 1.0),
		"uncommon": Color(0.3, 0.9, 0.3, 1.0),
		"rare": Color(0.3, 0.6, 1.0, 1.0),
		"epic": Color(0.8, 0.3, 1.0, 1.0),
		"legendary": Color(1.0, 0.7, 0.2, 1.0),
		"mythic": Color(1.0, 0.2, 0.2, 1.0)
	}
	
	# Стилизуем кнопку "Все" отдельно
	if all_filter:
		var all_style = StyleBoxFlat.new()
		all_style.bg_color = Color(0.3, 0.3, 0.4, 0.7)  # Темно-серый
		all_style.border_color = Color(0.6, 0.6, 0.7, 1.0)
		all_style.border_width_left = 2
		all_style.border_width_right = 2
		all_style.border_width_top = 2
		all_style.border_width_bottom = 2
		all_style.corner_radius_top_left = 6
		all_style.corner_radius_top_right = 6
		all_style.corner_radius_bottom_left = 6
		all_style.corner_radius_bottom_right = 6
		
		var all_hover_style = StyleBoxFlat.new()
		all_hover_style.bg_color = Color(0.4, 0.4, 0.5, 0.8)
		all_hover_style.border_color = Color(0.7, 0.7, 0.8, 1.0)
		all_hover_style.border_width_left = 3
		all_hover_style.border_width_right = 3
		all_hover_style.border_width_top = 3
		all_hover_style.border_width_bottom = 3
		all_hover_style.corner_radius_top_left = 6
		all_hover_style.corner_radius_top_right = 6
		all_hover_style.corner_radius_bottom_left = 6
		all_hover_style.corner_radius_bottom_right = 6
		
		all_filter.add_theme_stylebox_override("normal", all_style)
		all_filter.add_theme_stylebox_override("hover", all_hover_style)
		all_filter.add_theme_stylebox_override("pressed", all_hover_style)
		all_filter.add_theme_color_override("font_color", Color.WHITE)
		all_filter.add_theme_font_size_override("font_size", 14)
	
	# Применяем стили к каждой кнопке фильтра
	var filters = {
		"common": common_filter,
		"uncommon": uncommon_filter,
		"rare": rare_filter,
		"epic": epic_filter,
		"legendary": legendary_filter,
		"mythic": mythic_filter
	}
	
	for rarity in filters.keys():
		var btn = filters[rarity]
		if not btn:
			continue
		
		# Создаем стиль для нормального состояния
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = rarity_bg_colors[rarity]
		normal_style.border_color = rarity_border_colors[rarity]
		normal_style.border_width_left = 2
		normal_style.border_width_right = 2
		normal_style.border_width_top = 2
		normal_style.border_width_bottom = 2
		normal_style.corner_radius_top_left = 6
		normal_style.corner_radius_top_right = 6
		normal_style.corner_radius_bottom_left = 6
		normal_style.corner_radius_bottom_right = 6
		
		# Создаем стиль для наведения (более яркий)
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(
			rarity_bg_colors[rarity].r * 1.3,
			rarity_bg_colors[rarity].g * 1.3,
			rarity_bg_colors[rarity].b * 1.3,
			0.8
		)
		hover_style.border_color = rarity_border_colors[rarity]
		hover_style.border_width_left = 3
		hover_style.border_width_right = 3
		hover_style.border_width_top = 3
		hover_style.border_width_bottom = 3
		hover_style.corner_radius_top_left = 6
		hover_style.corner_radius_top_right = 6
		hover_style.corner_radius_bottom_left = 6
		hover_style.corner_radius_bottom_right = 6
		
		# Применяем стили
		btn.add_theme_stylebox_override("normal", normal_style)
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_stylebox_override("pressed", hover_style)
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_font_size_override("font_size", 14)

func set_initial_tab(tab_index: int):
	"""Устанавливает начальную вкладку при открытии экрана"""
	if not initial_tab_set:
		initial_tab_set = true
		# Используем call_deferred чтобы установить вкладку после полной инициализации
		call_deferred("_set_initial_tab_deferred", tab_index)

func _set_initial_tab_deferred(tab_index: int):
	"""Устанавливает начальную вкладку после полной инициализации"""
	current_tab = tab_index
	_on_tab_changed(tab_index)
	
	# Обновляем визуальное состояние кнопок вкладок
	var filter_buttons = get_node_or_null("MainPanel/VBoxContainer/FilterSection/FilterButtons")
	if filter_buttons:
		# Находим кнопки вкладок (первые две кнопки)
		if filter_buttons.get_child_count() >= 2:
			var normal_btn = filter_buttons.get_child(0)
			var soul_btn = filter_buttons.get_child(1)
			if normal_btn is Button and soul_btn is Button:
				normal_btn.button_pressed = (tab_index == 0)
				soul_btn.button_pressed = (tab_index == 1)

func _on_tab_changed(tab_index: int):
	"""Обрабатывает смену вкладки"""
	current_tab = tab_index
	
	# Скрываем/показываем фильтры в зависимости от вкладки
	var filter_buttons = get_node_or_null("MainPanel/VBoxContainer/FilterSection/FilterButtons")
	if filter_buttons:
		# Фильтры по редкости начинаются с индекса 3 (после двух вкладок и разделителя)
		for i in range(3, filter_buttons.get_child_count()):
			var filter_btn = filter_buttons.get_child(i)
			filter_btn.visible = (current_tab == 0)  # Показываем только для обычных способностей
	
	# Обновляем список способностей
	update_abilities_list()
	print("Переключена вкладка: ", "Обычные способности" if tab_index == 0 else "Развитие души")

func _on_close_button_pressed():
	"""Закрывает экран"""
	queue_free()

func _on_back_button_pressed():
	"""Возвращается назад"""
	queue_free()

func _on_help_button_pressed():
	"""Показывает окно справки о механиках изучения способностей"""
	# Воспроизводим звук
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_sound("page", -5.0)
	
	# Создаем окно справки
	var help_window = Window.new()
	help_window.title = "ℹ️ Справка - Изучение способностей"
	help_window.size = Vector2i(800, 600)
	help_window.unresizable = false
	help_window.always_on_top = true
	
	# Создаем контейнер
	var main_container = VBoxContainer.new()
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_container.add_theme_constant_override("separation", 10)
	help_window.add_child(main_container)
	
	# Создаем ScrollContainer для текста
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.add_child(scroll)
	
	# Создаем RichTextLabel с BBCode
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.fit_content = true
	scroll.add_child(label)
	
	# Текст справки с форматированием BBCode
	var help_text = """[center][b][font_size=24]📚 КАК РАБОТАЕТ ИЗУЧЕНИЕ СПОСОБНОСТЕЙ[/font_size][/b][/center]

[font_size=18][b]🎯 Основная механика:[/b][/font_size]

• Побеждайте врагов и получайте [color=gold]очки прогресса[/color] их способностей
• Накопите нужное количество очков для изучения уровня способности
• После изучения способность станет [color=green]доступна для активации[/color]

[font_size=18][b]⭐ Требования очков для уровней:[/b][/font_size]

• [color=green]Уровень 1[/color] → [color=gold]100 очков[/color] прогресса
• [color=yellow]Уровень 2[/color] → [color=gold]500 очков[/color] прогресса
• [color=red]Уровень 3[/color] → [color=gold]1000 очков[/color] прогресса

Каждый уровень делает способность [color=gold]значительно мощнее[/color]!

[font_size=18][b]📊 Получение очков прогресса:[/b][/font_size]

[b]Базовые очки за редкость:[/b]
• [color=gray]Common (Обычные)[/color] → [color=gold]10 очков[/color]
• [color=green]Uncommon (Необычные)[/color] → [color=gold]20 очков[/color]
• [color=blue]Rare (Редкие)[/color] → [color=gold]30 очков[/color]
• [color=purple]Epic (Эпические)[/color] → [color=gold]40 очков[/color]
• [color=orange]Legendary (Легендарные)[/color] → [color=gold]50 очков[/color]
• [color=red]Mythic (Мифические)[/color] → [color=gold]100 очков[/color]

[b]⚡ Элитные враги:[/b]
• Элитные враги дают [color=gold]×2 прогресса[/color]!
• Пример: [color=blue]Элитный Редкий[/color] враг → [color=gold]60 очков[/color] (30 × 2)

[font_size=18][b]🎨 Редкость способностей:[/b][/font_size]

• Более [color=red]редкие[/color] враги имеют более [color=gold]мощные[/color] способности
• [color=orange]Легендарные[/color] и [color=red]Мифические[/color] способности могут изменить стиль игры!
• Боссы имеют [color=purple]уникальные способности[/color], недоступные обычным врагам

[font_size=18][b]💡 Советы:[/b][/font_size]

✅ [color=green]Экспериментируйте[/color] с комбинациями разных способностей
✅ Некоторые способности [color=gold]синергируют[/color] друг с другом
✅ Старайтесь изучить способности [color=purple]редких врагов[/color] - они очень сильные
✅ Не забывайте [color=yellow]активировать[/color] изученные способности в меню
✅ У вас есть [color=red]ограниченное количество слотов[/color] для активных способностей

[center][color=gold]Удачи в изучении способностей![/color][/center]"""
	
	label.text = help_text
	
	# Добавляем кнопку закрытия
	var close_btn = Button.new()
	close_btn.text = "Закрыть"
	close_btn.custom_minimum_size = Vector2(120, 40)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func(): help_window.queue_free())
	main_container.add_child(close_btn)
	
	# Показываем окно
	add_child(help_window)
	help_window.popup_centered()
	help_window.close_requested.connect(func(): help_window.queue_free())
	
	print("ℹ️ Открыто окно справки")

func show_screen():
	"""Показывает экран"""
	visible = true
	_update_filter_buttons_with_progress()
	update_abilities_list()

func hide_screen():
	"""Скрывает экран"""
	visible = false

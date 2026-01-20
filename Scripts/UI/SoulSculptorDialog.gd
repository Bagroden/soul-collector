# res://Scripts/UI/SoulSculptorDialog.gd
extends Control

## Диалоговое окно для взаимодействия со Скульптором душ

signal passive_activation_requested
signal ability_learning_requested
signal dialog_closed

@onready var dialog_panel: Panel = null
@onready var title_label: Label = null
@onready var message_label: Label = null
@onready var options_container: VBoxContainer = null
@onready var close_button: Button = null

## Отображается ли сообщение (вместо меню)
var is_showing_message: bool = false

## Массив для хранения кнопок с анимацией
var animated_buttons: Array[Button] = []
var button_tweens: Array[Tween] = []

func _ready():
	print("💬 === Инициализация диалога Скульптора душ ===")
	_create_dialog_ui()
	
	# Скрываем диалог по умолчанию
	hide()

func _create_dialog_ui():
	"""Создает UI диалогового окна"""
	# Центрируем по экрану и поднимаем выше
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	offset_left = -350
	offset_top = -350
	offset_right = 350
	offset_bottom = 350
	
	# Главная панель
	dialog_panel = Panel.new()
	dialog_panel.name = "DialogPanel"
	dialog_panel.custom_minimum_size = Vector2(700, 700)
	
	# Создаем непрозрачный фон для панели
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)  # Темно-синий, почти непрозрачный (95%)
	panel_style.border_color = Color(0.6, 0.5, 0.3, 1.0)  # Золотистая рамка
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.shadow_size = 10
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	# Внутренние отступы, чтобы текст не прилипал к краям
	panel_style.content_margin_left = 20
	panel_style.content_margin_right = 20
	panel_style.content_margin_top = 20
	panel_style.content_margin_bottom = 20
	dialog_panel.add_theme_stylebox_override("panel", panel_style)
	
	add_child(dialog_panel)
	
	# Основной контейнер
	var main_vbox = VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.anchor_right = 1.0
	main_vbox.anchor_bottom = 1.0
	main_vbox.add_theme_constant_override("separation", 20)
	dialog_panel.add_child(main_vbox)
	
	# Заголовок
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "🗿 Скульптор душ"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))  # Золотистый
	main_vbox.add_child(title_label)
	
	# Разделитель
	var separator1 = HSeparator.new()
	main_vbox.add_child(separator1)
	
	# Сообщение (для текстовых диалогов)
	message_label = Label.new()
	message_label.name = "MessageLabel"
	message_label.custom_minimum_size = Vector2(650, 450)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 18)
	message_label.visible = false  # Скрыто по умолчанию
	main_vbox.add_child(message_label)
	
	# Контейнер для опций меню
	options_container = VBoxContainer.new()
	options_container.name = "OptionsContainer"
	options_container.add_theme_constant_override("separation", 15)
	main_vbox.add_child(options_container)
	
	# Разделитель
	var separator2 = HSeparator.new()
	main_vbox.add_child(separator2)
	
	# Кнопка закрытия
	close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "Закрыть"
	close_button.custom_minimum_size = Vector2(200, 50)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.pressed.connect(_on_close_button_pressed)
	main_vbox.add_child(close_button)
	
	print("✅ UI диалога создан")

func show_menu():
	"""Показывает главное меню диалога"""
	print("📋 Показываем меню Скульптора душ")
	
	# Получаем PlayerManager один раз для всей функции
	var player_manager = get_node_or_null("/root/PlayerManager")
	var player_data = null
	if player_manager:
		player_data = player_manager.get_player_data()
	
	# Проверяем, первое ли это посещение
	if player_data:
		# Если игрок встретил Скульптора, но еще не видел первый диалог - показываем приветствие
		if player_data.met_soul_sculptor and not player_data.seen_first_dialogue:
			player_data.seen_first_dialogue = true
			var first_meeting_text = """Приветствую тебя, путник. Я чувствую в тебе силу душ...

Я - Скульптор душ, мастер древнего искусства работы с духовной энергией.

Я могу помочь тебе научиться новым способностям, перенимая их у поверженных врагов.

Предлагаю сделку: ты поможешь мне, я помогу тебе. У тебя огромный потенциал и способности, которые могут быть нам полезными. Я могу помочь тебе стать сильнее, а я получу материал для оттачивания своего мастерства.

Но для этого мне нужен особый инструмент - Урна душ.

Много лет назад неудачливый вор украл её у меня и сгинул в подземельях под городом. Я чувствую, что артефакт все еще там. Верни его мне, и я смогу помочь тебе."""
			
			show_message(first_meeting_text)
			return
	
	is_showing_message = false
	
	# Останавливаем все анимации кнопок
	_stop_all_button_animations()
	
	# Скрываем сообщение
	message_label.visible = false
	
	# Очищаем опции
	for child in options_container.get_children():
		child.queue_free()
	
	# Показываем контейнер опций
	options_container.visible = true
	
	# Проверяем состояние артефактов для добавления специальных опций
	var show_urn_delivery = false
	var show_crystal_delivery = false
	var show_phylactery_delivery = false
	var show_ancient_skull_delivery = false
	var has_soul_urn_quest = false
	var has_knowledge_crystal_quest = false
	var has_phylactery_quest = false
	var has_ancient_skull_quest = false
	if player_data:
		# РЕТРОАКТИВНАЯ ВЫДАЧА НАГРАДЫ: Если урна доставлена, но награда не получена
		if player_data.soul_urn_delivered and not player_data.soul_urn_reward_received:
			print("🎁 РЕТРОАКТИВНАЯ НАГРАДА: Урна была доставлена ранее, но награда не была получена. Выдаем награду...")
			var strong_souls_manager = get_node_or_null("/root/StrongSouls")
			if strong_souls_manager:
				var souls_before = strong_souls_manager.get_strong_souls()
				strong_souls_manager.add_strong_souls(2)
				var souls_after = strong_souls_manager.get_strong_souls()
				print("✅ Ретроактивная награда выдана: +2 сильные души (было", souls_before, "стало", souls_after, ")")
				
			# Отмечаем, что награда получена
			player_data.soul_urn_reward_received = true
			
			# Сохраняем данные (используем существующий player_manager)
			if player_manager:
				player_manager.save_game_data()
				
				# Показываем сообщение игроку
				show_message("""Постой... Я кажется забыл выразить свою благодарность должным образом!

За возвращение Урны душ, прими от меня две Сильные души. Распорядись ими с умом.

(Вы получили: 2 × Сильная душа)""")
		
		show_urn_delivery = player_data.has_soul_urn and not player_data.soul_urn_delivered
		show_crystal_delivery = player_data.has_knowledge_crystal and not player_data.knowledge_crystal_delivered and player_data.soul_urn_delivered
		show_phylactery_delivery = player_data.has_phylactery and not player_data.phylactery_delivered and player_data.knowledge_crystal_delivered
		show_ancient_skull_delivery = player_data.has_ancient_skull and not player_data.ancient_skull_delivered
		# Проверяем доступные и активные квесты
		has_soul_urn_quest = player_data.is_quest_available("find_soul_urn") or player_data.is_quest_active("find_soul_urn")
		has_knowledge_crystal_quest = player_data.is_quest_available("find_knowledge_crystal") or player_data.is_quest_active("find_knowledge_crystal")
		has_phylactery_quest = player_data.is_quest_available("find_phylactery") or player_data.is_quest_active("find_phylactery")
		has_ancient_skull_quest = player_data.is_quest_available("find_ancient_skull") or player_data.is_quest_active("find_ancient_skull")
	
	# Создаем опции меню
	# Опция распределения характеристик с отображением свободных очков
	var stat_points_text = "📊 Распределить характеристики"
	if player_data:
		var points = player_data.stat_points
		if points > 0:
			stat_points_text += " • " + str(points)
		else:
			stat_points_text += " • 0"
	_create_menu_option_with_highlight(stat_points_text, _on_distribute_stats_pressed, player_data and player_data.stat_points > 0)
	
	# Опции, доступные только после доставки Урны душ
	if player_data and player_data.soul_urn_delivered:
		_create_menu_option("🌟 Развитие души", _on_soul_development_pressed)
		_create_menu_option("⚡ Активация способностей", _on_passive_activation_pressed)
		_create_menu_option("📚 Изучение способностей", _on_ability_learning_pressed)
	
	_create_menu_option("🔄 Сброс характеристик", _on_reset_stats_pressed)
	
	# Добавляем опции доставки артефактов если они у игрока (зеленым цветом)
	if show_urn_delivery:
		_create_menu_option_green("🏺 Доставить Урну душ", _on_deliver_urn_pressed)
	if show_crystal_delivery:
		_create_menu_option_green("💎 Доставить Кристалл познания", _on_deliver_crystal_pressed)
	if show_phylactery_delivery:
		_create_menu_option_green("💀 Доставить Филактерию", _on_deliver_phylactery_pressed)
	if show_ancient_skull_delivery:
		_create_menu_option_green("💀 Доставить Древний череп", _on_deliver_ancient_skull_pressed)
	
	# Добавляем опции для квестов (доступных или активных)
	if has_soul_urn_quest:
		var is_available = player_data and player_data.is_quest_available("find_soul_urn")
		_create_menu_option_with_highlight("📜 Квест: Урна душ", _on_soul_urn_quest_pressed, is_available)
	if has_knowledge_crystal_quest:
		var is_available = player_data and player_data.is_quest_available("find_knowledge_crystal")
		_create_menu_option_with_highlight("📜 Квест: Кристалл познания", _on_knowledge_crystal_quest_pressed, is_available)
	if has_phylactery_quest:
		var is_available = player_data and player_data.is_quest_available("find_phylactery")
		_create_menu_option_with_highlight("📜 Квест: Филактерия", _on_phylactery_quest_pressed, is_available)
	if has_ancient_skull_quest:
		var is_available = player_data and player_data.is_quest_available("find_ancient_skull")
		_create_menu_option_with_highlight("📜 Квест: Древний череп", _on_ancient_skull_quest_pressed, is_available)
	
	# Меняем текст кнопки
	close_button.text = "Закрыть"
	
	# Показываем диалог
	show()
	print("✅ Меню открыто")

func show_message(message: String):
	"""Показывает текстовое сообщение"""
	print("💬 Показываем сообщение: ", message)
	is_showing_message = true
	
	# Скрываем опции
	options_container.visible = false
	
	# Показываем сообщение
	message_label.text = message
	message_label.visible = true
	
	# Меняем текст кнопки на "Назад"
	close_button.text = "Назад"
	
	# Показываем диалог
	show()

func _create_menu_option(text: String, callback: Callable):
	"""Создает кнопку опции меню"""
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(500, 60)
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(callback)
	options_container.add_child(button)

func _create_menu_option_with_highlight(text: String, callback: Callable, highlight: bool):
	"""Создает кнопку опции меню с возможностью выделения"""
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(500, 60)
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(callback)
	
	# Если нужно выделить (квест доступен или есть свободные очки) - делаем золотым с анимацией
	if highlight:
		button.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))  # Золотой
		button.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.3))  # Светло-золотой при наведении
		button.add_theme_color_override("font_pressed_color", Color(0.9, 0.75, 0.0))  # Темно-золотой при нажатии
		
		# Добавляем кнопку в массив для анимации
		animated_buttons.append(button)
		
		# Создаем анимацию пульсации
		_create_button_pulse_animation(button)
	
	options_container.add_child(button)

func _create_menu_option_green(text: String, callback: Callable):
	"""Создает кнопку опции меню с зеленым выделением (для доставки квестовых предметов)"""
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(500, 60)
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(callback)
	
	# Зеленое выделение для опций доставки
	button.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))  # Яркий зеленый
	button.add_theme_color_override("font_hover_color", Color(0.3, 1.0, 0.4))  # Светло-зеленый при наведении
	button.add_theme_color_override("font_pressed_color", Color(0.1, 0.8, 0.2))  # Темно-зеленый при нажатии
	
	# Добавляем кнопку в массив для анимации
	animated_buttons.append(button)
	
	# Создаем анимацию пульсации
	_create_button_pulse_animation(button)
	
	options_container.add_child(button)

func _on_soul_development_pressed():
	"""Обработчик нажатия на 'Развитие души'"""
	print("🌟 Нажато: Развитие души")
	
	# Проверяем, есть ли у игрока Урна душ
	var player_manager = get_node_or_null("/root/PlayerManager")
	var has_soul_urn = false
	if player_manager:
		var player_data = player_manager.get_player_data()
		if player_data:
			has_soul_urn = player_data.soul_urn_delivered
	
	if not has_soul_urn:
		# Показываем сообщение о необходимости найти артефакт
		var message = """Приветствую тебя, путник.
		
Я чувствую в тебе силу душ... Я - Скульптор душ, мастер древнего искусства работы с духовной энергией.

Я могу помочь тебе научиться новым способностям, перенимая их у поверженных врагов. Но для этого мне нужен особый инструмент - Урна душ.

Много лет назад неудачливый вор украл её и сгинул в подземельях под городом. Я чувствую, что артефакт все еще там.

Верни его мне и я смогу помочь тебе."""
		show_message(message)
	else:
		# Если артефакт уже есть - открываем экран изучения способностей на вкладке "Развитие души"
		# Закрываем диалог
		hide()
		# Открываем экран изучения способностей с вкладкой "Развитие души"
		var char_prep = get_tree().current_scene
		if char_prep and char_prep.has_method("_on_ability_learning_button_pressed"):
			char_prep._on_ability_learning_button_pressed(1)  # 1 = Развитие души
		else:
			push_error("❌ Не удалось открыть экран изучения способностей")

func _on_passive_activation_pressed():
	"""Обработчик нажатия на 'Активация способностей'"""
	print("⚡ Нажато: Активация способностей")
	
	# Закрываем диалог и посылаем сигнал
	hide()
	passive_activation_requested.emit()

func _on_ability_learning_pressed():
	"""Обработчик нажатия на 'Изучение способностей'"""
	print("📚 Нажато: Изучение способностей")
	
	# Проверяем, доставлена ли Урна душ
	var player_manager = get_node_or_null("/root/PlayerManager")
	var has_soul_urn = false
	if player_manager:
		var player_data = player_manager.get_player_data()
		if player_data:
			has_soul_urn = player_data.soul_urn_delivered
	
	if not has_soul_urn:
		# Показываем сообщение о необходимости доставить артефакт
		var message = """Я вижу твое стремление к знаниям, но сначала мне нужна Урна душ.

Без этого древнего артефакта я не смогу помочь тебе изучить способности поверженных врагов.

Найди Урну душ в подземелье под городом, и я научу тебя перенимать силу врагов."""
		show_message(message)
	else:
		# Если артефакт доставлен - открываем экран изучения
		hide()
		ability_learning_requested.emit()

func _on_deliver_urn_pressed():
	"""Обработчик нажатия на 'Доставить Урну душ'"""
	print("🏺 Нажато: Доставить Урну душ")
	
	# Доставляем урну
	var player_manager = get_node_or_null("/root/PlayerManager")
	if not player_manager:
		print("❌ ОШИБКА: PlayerManager не найден!")
		return
	
	var player_data = player_manager.get_player_data()
	if not player_data:
		print("❌ ОШИБКА: PlayerData не найден!")
		return
	
	print("DEBUG: has_soul_urn =", player_data.has_soul_urn)
	print("DEBUG: soul_urn_delivered =", player_data.soul_urn_delivered)
	
	var delivery_success = player_data.deliver_soul_urn()
	print("DEBUG: deliver_soul_urn() вернул:", delivery_success)
	
	if delivery_success:
		# Выдаем награду: 2 сильные души
		var strong_souls_manager = get_node_or_null("/root/StrongSouls")
		if strong_souls_manager:
			var souls_before = strong_souls_manager.get_strong_souls()
			print("DEBUG: Сильные души ДО награды:", souls_before)
			
			strong_souls_manager.add_strong_souls(2)
			
			var souls_after = strong_souls_manager.get_strong_souls()
			print("DEBUG: Сильные души ПОСЛЕ награды:", souls_after)
			print("✅ Награда за квест: +2 сильные души (было", souls_before, "стало", souls_after, ")")
		else:
			print("❌ ОШИБКА: StrongSouls manager не найден!")
		
		# Сохраняем данные игрока
		player_manager.save_game_data()
		print("DEBUG: Данные игрока сохранены")
		
	# Показываем сообщение о разблокировке с упоминанием награды
	var message = """Превосходно! Урна душ... Я так долго её искал.

Теперь я могу помочь тебе. Это древний артефакт, способный хранить знания о способностях врагов.

С этого момента, побеждая врагов, ты будешь получать частицы их душ, которые я преобразую в знания об их способностях.

Также я могу научить тебя базовым техникам развития души.

В знак благодарности за возвращение артефакта, я дарю тебе две Сильные души. Распорядись ими с умом.

Приходи ко мне, когда накопишь достаточно осколков душ."""
	show_message(message)
	
	# Воспроизводим звук успеха
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_sound("page", -5.0)

func _on_deliver_crystal_pressed():
	"""Обработчик нажатия на 'Доставить Кристалл познания'"""
	print("💎 Нажато: Доставить Кристалл познания")
	
	# Доставляем кристалл
	var player_manager = get_node_or_null("/root/PlayerManager")
	if player_manager:
		var player_data = player_manager.get_player_data()
		if player_data and player_data.deliver_knowledge_crystal():
			# Сохраняем данные игрока
			player_manager.save_game_data()
			
			# Показываем сообщение о разблокировке
			var message = """Кристалл познания... Это позволит тебе изучать более сложные
способности врагов и глубже проникать в тайны развития души.

Теперь ты можешь изучать Epic и Legendary способности врагов, а также
освоить более продвинутые техники развития души.

Продолжай совершенствоваться."""
			show_message(message)
			
			# Воспроизводим звук успеха
			if has_node("/root/SoundManager"):
				get_node("/root/SoundManager").play_sound("page", -5.0)
			
			# После закрытия сообщения меню обновится автоматически через show_menu()

func _on_deliver_phylactery_pressed():
	"""Обработчик нажатия на 'Доставить Филактерию'"""
	print("💀 Нажато: Доставить Филактерию")
	
	# Доставляем филактерию
	var player_manager = get_node_or_null("/root/PlayerManager")
	if player_manager:
		var player_data = player_manager.get_player_data()
		if player_data and player_data.deliver_phylactery():
			# Сохраняем данные игрока
			player_manager.save_game_data()
			
			# Показываем сообщение о разблокировке
			var message = """Невероятно! Филактерия некроманта - редкий артефакт.

С помощью неё ты сможешь поглощать души более могущественных врагов!

Теперь ты можешь изучать Mythic способности врагов и освоить
величайшие тайны развития души.

Твоя сила растет с каждым шагом."""
			show_message(message)
			
			# Воспроизводим звук успеха
			if has_node("/root/SoundManager"):
				get_node("/root/SoundManager").play_sound("page", -5.0)

func _on_soul_urn_quest_pressed():
	"""Обработчик нажатия на квест 'Урна душ'"""
	print("📜 Нажато: Квест Урна душ")
	
	# Активируем квест, если он доступен
	var player_manager = get_node_or_null("/root/PlayerManager")
	if player_manager:
		var player_data = player_manager.get_player_data()
		if player_data and player_data.is_quest_available("find_soul_urn"):
			player_data.activate_quest("find_soul_urn")
	
	var message = """Много лет назад неудачливый вор украл у меня Урну душ
и сгинул в подземельях под городом.

Я чувствую, что артефакт все еще там.

Найди его и верни мне. С её помощью я смогу помочь тебе
научиться новым способностям, перенимая их у поверженных врагов."""
	
	show_message(message)

func _on_knowledge_crystal_quest_pressed():
	"""Обработчик нажатия на квест 'Кристалл познания'"""
	print("📜 Нажато: Квест Кристалл познания")
	
	# Активируем квест, если он доступен
	var player_manager = get_node_or_null("/root/PlayerManager")
	if player_manager:
		var player_data = player_manager.get_player_data()
		if player_data and player_data.is_quest_available("find_knowledge_crystal"):
			player_data.activate_quest("find_knowledge_crystal")
	
	var message = """Я чувствую мощную духовную энергию в Лесу гоблинов.

Там охраняется Кристалл познания - артефакт, усиливающий
способность впитывать знания врагов.

Найди его у Орка адепта забытых богов в Ритуальной поляне.
Этот артефакт позволит тебе изучать более сложные способности."""
	
	show_message(message)

func _on_phylactery_quest_pressed():
	"""Обработчик нажатия на квест 'Филактерия'"""
	print("📜 Нажато: Квест Филактерия")
	
	# Активируем квест, если он доступен
	var player_manager = get_node_or_null("/root/PlayerManager")
	if player_manager:
		var player_data = player_manager.get_player_data()
		if player_data and player_data.is_quest_available("find_phylactery"):
			player_data.activate_quest("find_phylactery")
	
	var message = """В Заброшенном кладбище появился любопытный скелет,
которого подпитывает не магия некроманта, а душа в филактерии!

Обычно некромант решивший отказаться от живой плоти в пользу
бессмертия сохраняет разум, но не всегда все идет по плану.

Закончи его бессмысленное существование, а филактерия нам с тобой
очень поможет. Найди его в Склепе некроманта."""
	
	show_message(message)

func _on_deliver_ancient_skull_pressed():
	"""Обработчик нажатия на 'Доставить Древний череп'"""
	print("💀 Нажато: Доставить Древний череп")
	
	# Доставляем древний череп
	var player_manager = get_node_or_null("/root/PlayerManager")
	if player_manager:
		var player_data = player_manager.get_player_data()
		if player_data and player_data.deliver_ancient_skull():
			# Сохраняем данные игрока
			player_manager.save_game_data()
			
			# Показываем сообщение о разблокировке
			var message = """Древний череп... Интересный артефакт.

Этот череп принадлежал могущественному магу, который
изучал тайны душ и магии.

Теперь он может помочь тебе в твоем пути."""
			show_message(message)
			
			# Воспроизводим звук успеха
			if has_node("/root/SoundManager"):
				get_node("/root/SoundManager").play_sound("page", -5.0)

func _on_ancient_skull_quest_pressed():
	"""Обработчик нажатия на квест 'Древний череп'"""
	print("📜 Нажато: Квест Древний череп")
	
	# Активируем квест, если он доступен
	var player_manager = get_node_or_null("/root/PlayerManager")
	if player_manager:
		var player_data = player_manager.get_player_data()
		if player_data and player_data.is_quest_available("find_ancient_skull"):
			player_data.activate_quest("find_ancient_skull")
	
	var message = """В Заброшенном кладбище можно найти Древний череп -
артефакт, принадлежавший могущественному магу.

Найди его у Древнего скелета в Склепе некроманта.
Этот артефакт может помочь тебе в изучении магии."""
	
	show_message(message)

func _on_distribute_stats_pressed():
	"""Обработчик нажатия на 'Распределить характеристики'"""
	print("📊 Нажато: Распределить характеристики")
	
	# Воспроизводим звук
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_sound("page", -5.0)
	
	# Скрываем диалог
	hide()
	
	# Загружаем сцену StatsScreen
	var stats_scene = preload("res://Scenes/StatsScreen.tscn")
	var stats_instance = stats_scene.instantiate()
	
	# Устанавливаем предыдущую сцену
	stats_instance.set_previous_scene("res://Scenes/UI/CharacterPreparation.tscn")
	
	# Устанавливаем z_index для отображения поверх всего
	stats_instance.z_index = 100
	
	# Добавляем к корневой сцене (CharacterPreparation)
	var root = get_tree().current_scene
	if root:
		root.add_child(stats_instance)
	else:
		push_error("❌ Не удалось найти корневую сцену")

func _on_reset_stats_pressed():
	"""Обработчик нажатия на 'Сброс характеристик'"""
	print("🔄 Нажато: Сброс характеристик")
	
	# Воспроизводим звук
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_sound("page", -5.0)
	
	# Показываем диалог подтверждения
	_show_reset_confirmation_dialog()

func _show_reset_confirmation_dialog():
	"""Показывает диалог подтверждения сброса характеристик"""
	var confirmation_dialog = ConfirmationDialog.new()
	confirmation_dialog.title = "Подтверждение сброса"
	confirmation_dialog.dialog_text = """⚠️ ВНИМАНИЕ!

Вы уверены, что хотите сбросить все характеристики к начальным значениям?

Все распределенные очки будут возвращены, и вам придется распределить их заново."""
	
	# Настраиваем кнопки
	confirmation_dialog.get_ok_button().text = "Да, сбросить"
	confirmation_dialog.get_cancel_button().text = "Отмена"
	
	# Стилизуем диалог в dark fantasy стиле
	confirmation_dialog.min_size = Vector2(500, 200)
	
	# Подключаем сигналы
	confirmation_dialog.confirmed.connect(_perform_reset_stats)
	confirmation_dialog.close_requested.connect(func(): confirmation_dialog.queue_free())
	confirmation_dialog.canceled.connect(func(): confirmation_dialog.queue_free())
	
	# Добавляем диалог в сцену
	add_child(confirmation_dialog)
	confirmation_dialog.popup_centered()

func _perform_reset_stats():
	"""Выполняет сброс характеристик после подтверждения"""
	var player_manager = get_node_or_null("/root/PlayerManager")
	if player_manager:
		var player_data = player_manager.get_player_data()
		if player_data:
			player_data.reset_stats_to_default()
			print("✅ Характеристики сброшены к дефолтным значениям!")
			
			# Воспроизводим звук успеха
			if has_node("/root/SoundManager"):
				get_node("/root/SoundManager").play_sound("page", -5.0)
			
			# Показываем сообщение об успехе
			var message = """Характеристики успешно сброшены к начальным значениям!

Все распределенные очки характеристик были возвращены.
Вы можете заново распределить их как пожелаете."""
			
			show_message(message)

func _on_close_button_pressed():
	"""Обработчик кнопки закрытия"""
	print("❌ Закрытие диалога")
	
	if is_showing_message:
		# Если показано сообщение - возвращаемся к меню
		show_menu()
	else:
		# Если показано меню - закрываем диалог
		_stop_all_button_animations()
		hide()
		dialog_closed.emit()

func _input(event: InputEvent):
	"""Закрытие диалога по ESC"""
	if visible and event.is_action_pressed("ui_cancel"):
		_on_close_button_pressed()
		get_viewport().set_input_as_handled()

func _create_button_pulse_animation(button: Button):
	"""Создает анимацию пульсации для кнопки"""
	if not button:
		return
	
	var tween = create_tween()
	tween.set_loops()  # Бесконечная анимация
	
	# Анимация размера шрифта (от 20 до 22 и обратно)
	tween.tween_method(
		func(font_size): button.add_theme_font_size_override("font_size", font_size),
		20,
		22,
		0.8
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_method(
		func(font_size): button.add_theme_font_size_override("font_size", font_size),
		22,
		20,
		0.8
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	button_tweens.append(tween)

func _stop_all_button_animations():
	"""Останавливает все анимации кнопок"""
	for tween in button_tweens:
		if tween and tween.is_valid():
			tween.kill()
	
	button_tweens.clear()
	animated_buttons.clear()

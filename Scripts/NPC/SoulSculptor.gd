# res://Scripts/NPC/SoulSculptor.gd
extends Node2D

## NPC "Скульптор душ" - открывает доступ к изучению пассивных и активных способностей

@onready var animated_sprite: AnimatedSprite2D = null

## Подсветка при наведении
var is_hovered: bool = false
var original_modulate: Color = Color.WHITE

## Доступен ли NPC для взаимодействия (будет настраиваться по прогрессу)
var is_unlocked: bool = false

## Границы области взаимодействия (для проверки курсора)
var interaction_rect: Rect2

## Диалоговое окно
var dialog: Control = null

## === СИСТЕМА ИНДИКАТОРОВ КВЕСТОВ ===
var quest_indicator: Label = null  # Иконка над головой (!, ?)
var glow_sprite: Sprite2D = null  # Пульсирующее свечение
var glow_tween: Tween = null  # Tween для анимации свечения

## Состояния индикатора квеста
enum QuestIndicatorState {
	NONE,  # Нет индикатора
	AVAILABLE,  # Квест доступен для взятия (желтый !)
	IN_PROGRESS,  # Квест взят, предмет не найден (серый ?)
	READY_TO_TURN_IN  # Предмет найден, можно сдать (зеленый !)
}

var current_indicator_state: QuestIndicatorState = QuestIndicatorState.NONE

func _ready():
	
	# Создаем AnimatedSprite2D
	animated_sprite = AnimatedSprite2D.new()
	animated_sprite.name = "AnimatedSprite"
	animated_sprite.scale = Vector2(3.0, 3.0)  # Увеличиваем в 3 раза
	add_child(animated_sprite)
	
	# Загружаем и настраиваем анимацию idle
	_setup_idle_animation()
	
	# Вычисляем область взаимодействия (центрированная относительно спрайта)
	# Размер спрайта * scale, центрируем относительно позиции NPC
	var interaction_size = Vector2(300, 450)  # 100x150 * 3 (scale)
	interaction_rect = Rect2(
		-interaction_size / 2,  # Центрируем относительно позиции
		interaction_size
	)
	
	# Сохраняем оригинальный цвет
	original_modulate = animated_sprite.modulate
	
	# Запускаем анимацию idle
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")
	else:
		push_error("❌ Анимация idle не найдена!")
	
	# Создаем систему индикаторов квестов
	_setup_quest_indicators()
	
	# Создаем диалоговое окно (отложенно, чтобы родитель успел инициализироваться)
	call_deferred("_create_dialog")
	

func _input(event: InputEvent):
	"""Обрабатываем события мыши вручную (т.к. Control блокирует Area2D)"""
	if event is InputEventMouse:
		var mouse_pos = get_global_mouse_position()
		# Проверяем попадание курсора в область NPC
		var local_rect = Rect2(global_position + interaction_rect.position, interaction_rect.size)
		var was_hovered = is_hovered
		is_hovered = local_rect.has_point(mouse_pos)
		
		# Если состояние изменилось - обновляем подсветку
		if is_hovered != was_hovered:
			if is_hovered:
				_on_mouse_entered()
			else:
				_on_mouse_exited()
		
		# Обработка клика
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and is_hovered:
				_on_npc_clicked()

func _setup_idle_animation():
	"""Настраивает анимацию idle из 4 кадров"""
	var sprite_frames = SpriteFrames.new()
	sprite_frames.add_animation("idle")
	sprite_frames.set_animation_loop("idle", true)
	sprite_frames.set_animation_speed("idle", 2.5)  # 2.5 FPS (в 2 раза медленнее)
	
	# Загружаем 4 кадра анимации (правильный путь с пробелами)
	for i in range(1, 5):
		var frame_path = "res://Assets/Sprites/NPC/Sculptor_of_Souls/Idle, 4 Frames/%d.png" % i
		var texture = load(frame_path)
		if texture:
			sprite_frames.add_frame("idle", texture)
		else:
			push_error("❌ Не удалось загрузить кадр: " + frame_path)
	
	animated_sprite.sprite_frames = sprite_frames

func _on_mouse_entered():
	"""Обработчик наведения курсора"""
	is_hovered = true
	_update_highlight()
	
	# Меняем курсор на указатель
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_mouse_exited():
	"""Обработчик ухода курсора"""
	is_hovered = false
	_update_highlight()
	
	# Возвращаем обычный курсор
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _update_highlight():
	"""Обновляет подсветку NPC при наведении"""
	if not animated_sprite:
		return
	
	if is_hovered:
		# Подсветка белым (усиленная яркость)
		var tween = create_tween()
		tween.tween_property(animated_sprite, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.2)
	else:
		# Возврат к оригинальному цвету
		var tween = create_tween()
		tween.tween_property(animated_sprite, "modulate", original_modulate, 0.2)

func _create_dialog():
	"""Создает диалоговое окно NPC"""
	
	var dialog_script = load("res://Scripts/UI/SoulSculptorDialog.gd")
	if not dialog_script:
		push_error("❌ Не удалось загрузить скрипт SoulSculptorDialog.gd")
		return
	
	dialog = Control.new()
	dialog.set_script(dialog_script)
	dialog.name = "SoulSculptorDialog"
	dialog.z_index = 100  # Поверх всего
	
	# Добавляем диалог к корневому узлу сцены (CharacterPreparation)
	var root = get_tree().current_scene
	if root:
		root.add_child(dialog)
		
		# Подключаем сигналы
		dialog.passive_activation_requested.connect(_on_passive_activation_requested)
		dialog.ability_learning_requested.connect(_on_ability_learning_requested)
		dialog.dialog_closed.connect(_on_dialog_closed)
	else:
		push_error("❌ Не удалось найти корневой узел сцены")

func _on_npc_clicked():
	"""Обработчик клика по NPC"""
	
	# Проверяем первое посещение (активирует квест если это первый раз)
	_check_first_meeting()
	
	if dialog:
		dialog.show_menu()
		
		# Воспроизводим звук (если есть SoundManager)
		if has_node("/root/SoundManager"):
			get_node("/root/SoundManager").play_sound("page", -5.0)
	else:
		push_error("❌ Диалог не создан!")

func _check_first_meeting() -> bool:
	"""Проверяет первую встречу со Скульптором и активирует квест. Возвращает true, если это первая встреча"""
	var player_manager = get_node_or_null("/root/PlayerManager")
	if not player_manager:
		return false
	
	var player_data = player_manager.get_player_data()
	if not player_data:
		return false
	
	# Если игрок еще не встречал Скульптора - активируем квест
	if not player_data.met_soul_sculptor:
		player_data.met_soul_sculptor = true
		player_data.add_quest("find_soul_urn")
		return true
	
	return false

func _on_passive_activation_requested():
	"""Обработчик запроса на открытие окна активации пассивных способностей"""
	
	# Получаем CharacterPreparation и вызываем его метод
	var char_prep = get_tree().current_scene
	if char_prep and char_prep.has_method("open_passive_abilities_window"):
		char_prep.open_passive_abilities_window()
	else:
		push_error("❌ Не удалось открыть окно активации способностей")

func _on_ability_learning_requested():
	"""Обработчик запроса на открытие экрана изучения способностей"""
	
	# Получаем CharacterPreparation и вызываем его метод
	var char_prep = get_tree().current_scene
	if char_prep and char_prep.has_method("_on_ability_learning_button_pressed"):
		char_prep._on_ability_learning_button_pressed()
	else:
		push_error("❌ Не удалось открыть экран изучения способностей")

func _on_dialog_closed():
	"""Обработчик закрытия диалога"""

func set_unlocked(unlocked: bool):
	"""Устанавливает доступность NPC"""
	is_unlocked = unlocked
	
	# Можно добавить визуальные изменения (например, сделать полупрозрачным если недоступен)
	if animated_sprite:
		if unlocked:
			animated_sprite.modulate.a = 1.0
		else:
			animated_sprite.modulate.a = 0.5  # Полупрозрачный если недоступен

func _exit_tree():
	"""Очистка при удалении из сцены"""
	# Возвращаем курсор к нормальному виду
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	
	# Останавливаем анимацию свечения
	if glow_tween:
		glow_tween.kill()

func _process(_delta: float):
	"""Обновляем состояние индикатора квеста каждый кадр"""
	_update_quest_indicator()

## === СИСТЕМА ИНДИКАТОРОВ КВЕСТОВ ===

func _setup_quest_indicators():
	"""Создает элементы для отображения индикаторов квестов"""
	
	# Создаем пульсирующее свечение
	glow_sprite = Sprite2D.new()
	glow_sprite.name = "GlowSprite"
	glow_sprite.z_index = -1  # Позади NPC
	glow_sprite.modulate = Color(1.0, 1.0, 0.0, 0.0)  # Желтый, полностью прозрачный
	add_child(glow_sprite)
	
	# Создаем текстуру свечения (круг)
	var glow_size = 200
	var glow_image = Image.create(glow_size, glow_size, false, Image.FORMAT_RGBA8)
	var center = Vector2(glow_size / 2.0, glow_size / 2.0)
	var radius = glow_size / 2.0
	
	for x in range(glow_size):
		for y in range(glow_size):
			var dist = center.distance_to(Vector2(x, y))
			if dist < radius:
				var alpha = 1.0 - (dist / radius)
				alpha = pow(alpha, 2)  # Плавное затухание к краям
				glow_image.set_pixel(x, y, Color(1, 1, 1, alpha))
	
	var glow_texture = ImageTexture.create_from_image(glow_image)
	glow_sprite.texture = glow_texture
	glow_sprite.scale = Vector2(1.5, 1.5)
	
	# Создаем иконку над головой (Label с эмодзи)
	quest_indicator = Label.new()
	quest_indicator.name = "QuestIndicator"
	quest_indicator.z_index = 20  # Поверх NPC
	quest_indicator.position = Vector2(-15, -250)  # Над головой
	quest_indicator.add_theme_font_size_override("font_size", 48)
	quest_indicator.visible = false
	add_child(quest_indicator)
	

func _update_quest_indicator():
	"""Обновляет состояние индикатора квеста в зависимости от прогресса игрока"""
	var player_manager = get_node_or_null("/root/PlayerManager")
	if not player_manager:
		return
	
	var player_data = player_manager.get_player_data()
	if not player_data:
		return
	
	var new_state = _determine_quest_state(player_data)
	
	# Обновляем индикатор только если состояние изменилось
	if new_state != current_indicator_state:
		current_indicator_state = new_state
		_apply_indicator_state(new_state)

func _determine_quest_state(player_data) -> QuestIndicatorState:
	"""Определяет текущее состояние квеста для отображения"""
	
	# Проверяем квест на Урну душ
	if not player_data.met_soul_sculptor:
		# Первая встреча - квест доступен
		return QuestIndicatorState.AVAILABLE
	
	if player_data.is_quest_active("find_soul_urn"):
		# Квест активен
		if player_data.has_soul_urn and not player_data.soul_urn_delivered:
			# Предмет найден, можно сдать
			return QuestIndicatorState.READY_TO_TURN_IN
		else:
			# Квест в процессе
			return QuestIndicatorState.IN_PROGRESS
	
	# Проверяем квест на Кристалл познания
	# Квест доступен только ПОСЛЕ победы над Гнилостным слизнем (босс делает квест доступным)
	if player_data.soul_urn_delivered and not player_data.knowledge_crystal_delivered:
		# Если кристалл найден, но не доставлен - готов к сдаче
		if player_data.has_knowledge_crystal:
			return QuestIndicatorState.READY_TO_TURN_IN
		# Если квест активирован, но кристалл еще не найден
		elif player_data.is_quest_active("find_knowledge_crystal"):
			return QuestIndicatorState.IN_PROGRESS
		# Если квест доступен для взятия (после убийства босса)
		elif player_data.is_quest_available("find_knowledge_crystal"):
			return QuestIndicatorState.AVAILABLE
	
	# Проверяем квест на Филактерию
	if player_data.knowledge_crystal_delivered and not player_data.phylactery_delivered:
		# Если филактерия найдена, но не доставлена - готов к сдаче
		if player_data.has_phylactery:
			return QuestIndicatorState.READY_TO_TURN_IN
		# Если квест активен, но филактерия еще не найдена
		elif player_data.is_quest_active("find_phylactery"):
			return QuestIndicatorState.IN_PROGRESS
		# Если квест доступен для взятия
		elif player_data.is_quest_available("find_phylactery"):
			return QuestIndicatorState.AVAILABLE
	
	# Проверяем квест на Древний череп
	if player_data.phylactery_delivered and not player_data.ancient_skull_delivered:
		# Если череп найден, но не доставлен - готов к сдаче
		if player_data.has_ancient_skull:
			return QuestIndicatorState.READY_TO_TURN_IN
		# Если квест активен, но череп еще не найден
		elif player_data.is_quest_active("find_ancient_skull"):
			return QuestIndicatorState.IN_PROGRESS
		# Если квест доступен для взятия
		elif player_data.is_quest_available("find_ancient_skull"):
			return QuestIndicatorState.AVAILABLE
	
	# Все квесты выполнены или нет доступных
	return QuestIndicatorState.NONE

func _apply_indicator_state(state: QuestIndicatorState):
	"""Применяет визуальное состояние индикатора"""
	if not quest_indicator or not glow_sprite:
		return
	
	match state:
		QuestIndicatorState.NONE:
			# Скрываем индикатор и свечение
			quest_indicator.visible = false
			_stop_glow_animation()
			
		QuestIndicatorState.AVAILABLE:
			# Желтый восклицательный знак + золотое свечение
			quest_indicator.text = "!"
			quest_indicator.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))  # Золотой
			quest_indicator.visible = true
			_start_glow_animation(Color(1.0, 0.85, 0.0, 0.3))  # Золотое свечение
			
		QuestIndicatorState.IN_PROGRESS:
			# Серый вопросительный знак, без свечения
			quest_indicator.text = "?"
			quest_indicator.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))  # Серый
			quest_indicator.visible = true
			_stop_glow_animation()
			
		QuestIndicatorState.READY_TO_TURN_IN:
			# Зеленый восклицательный знак + зеленое свечение
			quest_indicator.text = "!"
			quest_indicator.add_theme_color_override("font_color", Color(0.0, 1.0, 0.3))  # Яркий зеленый
			quest_indicator.visible = true
			_start_glow_animation(Color(0.0, 1.0, 0.3, 0.4))  # Зеленое свечение
	

func _start_glow_animation(glow_color: Color):
	"""Запускает анимацию пульсирующего свечения"""
	if not glow_sprite:
		return
	
	# Останавливаем предыдущую анимацию
	if glow_tween:
		glow_tween.kill()
	
	glow_sprite.visible = true
	glow_sprite.modulate = glow_color
	
	# Создаем бесконечную анимацию пульсации
	glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.set_trans(Tween.TRANS_SINE)
	glow_tween.set_ease(Tween.EASE_IN_OUT)
	
	# Пульсация альфа-канала от 0.2 до полной прозрачности цвета
	var color_min = Color(glow_color.r, glow_color.g, glow_color.b, glow_color.a * 0.3)
	var color_max = Color(glow_color.r, glow_color.g, glow_color.b, glow_color.a)
	
	glow_tween.tween_property(glow_sprite, "modulate", color_max, 1.0)
	glow_tween.tween_property(glow_sprite, "modulate", color_min, 1.0)

func _stop_glow_animation():
	"""Останавливает анимацию свечения"""
	if glow_tween:
		glow_tween.kill()
		glow_tween = null
	
	if glow_sprite:
		glow_sprite.visible = false

extends Control

# UI элементы
@onready var victory_panel: Panel = $VictoryPanel
@onready var title_label: Label = $VictoryPanel/VBoxContainer/TitleLabel
@onready var enemies_container: VBoxContainer = $VictoryPanel/VBoxContainer/EnemiesContainer
@onready var rewards_container: VBoxContainer = $VictoryPanel/VBoxContainer/RewardsContainer
@onready var ability_progress_container: VBoxContainer = $VictoryPanel/VBoxContainer/AbilityProgressContainer
@onready var continue_button: Button = $VictoryPanel/VBoxContainer/ContinueButton

# Данные о наградах
var victory_data: Dictionary = {}

func _ready():
	# Подключаем кнопку
	continue_button.pressed.connect(_on_continue_pressed)
	
	# Анимация появления
	_animate_appearance()

func setup_victory_data(data: Dictionary):
	"""Настраивает экран победы с полными данными"""
	victory_data = data
	
	# Используем call_deferred чтобы убедиться, что узел уже в дереве
	call_deferred("_setup_ui_elements")

func _setup_ui_elements():
	"""Настраивает UI элементы после добавления в дерево"""
	# Устанавливаем заголовок
	if title_label:
		title_label.text = "ПОБЕДА!"
	
	# Показываем информацию о врагах
	_setup_enemies_info()
	
	# Показываем награды
	_setup_rewards()
	
	# Показываем прогресс способностей
	_setup_ability_progress()
	
	# Анимация появления элементов
	call_deferred("_animate_rewards")

func setup_victory(enemy_name: String, enemy_level: int, enemy_rarity: String, exp_reward: int, soul_shards_reward: int, ability_progress: Array = []):
	"""Старый метод для совместимости - создает данные из параметров"""
	var data = {
		"enemies": [{
			"name": enemy_name,
			"level": enemy_level,
			"rarity": enemy_rarity
		}],
		"exp": exp_reward,
		"soul_shards": soul_shards_reward,
		"strong_souls": 0,
		"great_souls": 0,
		"divine_souls": 0,
		"ability_progress": ability_progress
	}
	setup_victory_data(data)

func _setup_enemies_info():
	"""Настраивает информацию о побежденных врагах"""
	# Очищаем контейнер
	for child in enemies_container.get_children():
		child.queue_free()
	
	if not victory_data.has("enemies") or victory_data.enemies.size() == 0:
		return
	
	var enemies = victory_data.enemies
	
	if enemies.size() == 1:
		# Один враг - показываем детально
		var enemy = enemies[0]
		var enemy_label = Label.new()
		enemy_label.text = enemy.name
		enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		enemy_label.add_theme_font_size_override("font_size", 24)
		enemy_label.add_theme_color_override("font_color", _get_rarity_color(enemy.rarity))
		enemies_container.add_child(enemy_label)
		
		var level_label = Label.new()
		level_label.text = "Уровень %d • %s" % [enemy.level, _get_rarity_display_name(enemy.rarity)]
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_label.add_theme_font_size_override("font_size", 16)
		level_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		enemies_container.add_child(level_label)
	else:
		# Несколько врагов
		var count_label = Label.new()
		count_label.text = "Побеждено врагов: %d" % enemies.size()
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_label.add_theme_font_size_override("font_size", 20)
		count_label.add_theme_color_override("font_color", Color.WHITE)
		enemies_container.add_child(count_label)
		
		for i in range(enemies.size()):
			var enemy = enemies[i]
			var enemy_label = Label.new()
			enemy_label.text = "%d. %s (ур. %d, %s)" % [i + 1, enemy.name, enemy.level, _get_rarity_display_name(enemy.rarity)]
			enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			enemy_label.add_theme_font_size_override("font_size", 16)
			enemy_label.add_theme_color_override("font_color", _get_rarity_color(enemy.rarity))
			enemies_container.add_child(enemy_label)

func _setup_rewards():
	"""Настраивает отображение наград"""
	# Очищаем контейнер
	for child in rewards_container.get_children():
		child.queue_free()
	
	# Заголовок
	var rewards_title = Label.new()
	rewards_title.text = "Награды:"
	rewards_title.add_theme_font_size_override("font_size", 20)
	rewards_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	rewards_container.add_child(rewards_title)
	
	# Опыт
	if victory_data.has("exp") and victory_data.exp > 0:
		var exp_item = _create_reward_item("Опыт", str(victory_data.exp), Color(0.4, 0.8, 1.0))
		rewards_container.add_child(exp_item)
	
	# Осколки душ
	if victory_data.has("soul_shards") and victory_data.soul_shards > 0:
		var shards_item = _create_reward_item("Осколки душ", str(victory_data.soul_shards), Color(1.0, 0.8, 0.2))
		rewards_container.add_child(shards_item)
	
	# Сильные души
	if victory_data.has("strong_souls") and victory_data.strong_souls > 0:
		var strong_item = _create_reward_item("Сильные души", str(victory_data.strong_souls), Color(0.2, 0.8, 0.4))
		rewards_container.add_child(strong_item)
	
	# Великие души
	if victory_data.has("great_souls") and victory_data.great_souls > 0:
		var great_item = _create_reward_item("Великие души", str(victory_data.great_souls), Color(0.6, 0.3, 0.9))
		rewards_container.add_child(great_item)
	
	# Божественные души
	if victory_data.has("divine_souls") and victory_data.divine_souls > 0:
		var divine_item = _create_reward_item("Божественные души", str(victory_data.divine_souls), Color(1.0, 0.5, 0.0))
		rewards_container.add_child(divine_item)

func _create_reward_item(label_text: String, value_text: String, color: Color) -> HBoxContainer:
	"""Создает элемент награды"""
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	
	var label = Label.new()
	label.text = label_text + ":"
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(label)
	
	var value = Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.add_theme_font_size_override("font_size", 18)
	value.add_theme_color_override("font_color", color)
	container.add_child(value)
	
	return container

func _setup_ability_progress():
	"""Настраивает отображение прогресса изучения способностей"""
	# Очищаем контейнер
	for child in ability_progress_container.get_children():
		child.queue_free()
	
	if not victory_data.has("ability_progress") or victory_data.ability_progress.size() == 0:
		ability_progress_container.visible = false
		return
	
	ability_progress_container.visible = true
	
	# Заголовок
	var progress_title = Label.new()
	progress_title.text = "Прогресс изучения способностей:"
	progress_title.add_theme_font_size_override("font_size", 18)
	progress_title.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	ability_progress_container.add_child(progress_title)
	
	# Список способностей
	for progress_data in victory_data.ability_progress:
		var ability_item = HBoxContainer.new()
		ability_item.add_theme_constant_override("separation", 10)
		
		var name_label = Label.new()
		name_label.text = "• " + progress_data.ability_name + ":"
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ability_item.add_child(name_label)
		
		var progress_label = Label.new()
		progress_label.text = "+%d очков" % progress_data.progress
		progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		progress_label.add_theme_font_size_override("font_size", 16)
		progress_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
		ability_item.add_child(progress_label)
		
		ability_progress_container.add_child(ability_item)

func _animate_appearance():
	"""Анимация появления экрана"""
	# Начинаем с прозрачного
	modulate.a = 0.0
	victory_panel.scale = Vector2(0.8, 0.8)
	
	# Анимация появления
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.4)
	tween.parallel().tween_property(victory_panel, "scale", Vector2(1.0, 1.0), 0.4)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

func _animate_rewards():
	"""Анимация появления наград"""
	await get_tree().create_timer(0.2).timeout
	
	# Анимируем элементы наград
	var reward_items = rewards_container.get_children()
	for i in range(reward_items.size()):
		if reward_items[i] is HBoxContainer:
			await get_tree().create_timer(i * 0.1).timeout
			var item = reward_items[i]
			var start_x = item.position.x
			item.modulate.a = 0.0
			item.position.x = start_x - 20
			
			var tween = create_tween()
			tween.parallel().tween_property(item, "modulate:a", 1.0, 0.3)
			tween.parallel().tween_property(item, "position:x", start_x, 0.3)
			tween.set_ease(Tween.EASE_OUT)
	
	# Анимируем прогресс способностей
	if ability_progress_container.visible:
		await get_tree().create_timer(0.3).timeout
		var progress_items = ability_progress_container.get_children()
		for i in range(progress_items.size()):
			if progress_items[i] is HBoxContainer:
				await get_tree().create_timer(i * 0.1).timeout
				var item = progress_items[i]
				var start_x = item.position.x
				item.modulate.a = 0.0
				item.position.x = start_x - 20
				
				var tween = create_tween()
				tween.parallel().tween_property(item, "modulate:a", 1.0, 0.3)
				tween.parallel().tween_property(item, "position:x", start_x, 0.3)
				tween.set_ease(Tween.EASE_OUT)

func _get_rarity_color(rarity: String) -> Color:
	"""Возвращает цвет для редкости"""
	match rarity.to_lower():
		"common":
			return Color.WHITE
		"uncommon":
			return Color(0.2, 0.8, 0.2)
		"rare":
			return Color(0.2, 0.4, 1.0)
		"epic":
			return Color(0.8, 0.2, 0.8)
		"legendary":
			return Color(1.0, 0.6, 0.0)
		"mythic", "mythical":
			return Color(1.0, 0.2, 0.2)
		_:
			if rarity.begins_with("elite_"):
				return Color(0.6, 0.3, 0.9)
			elif rarity == "boss":
				return Color(0.8, 0.5, 0.1)
			return Color.WHITE

func _get_rarity_display_name(rarity: String) -> String:
	"""Возвращает отображаемое имя редкости"""
	match rarity.to_lower():
		"common":
			return "Обычная"
		"uncommon":
			return "Необычная"
		"rare":
			return "Редкая"
		"epic":
			return "Эпическая"
		"legendary":
			return "Легендарная"
		"mythic", "mythical":
			return "Мифическая"
		_:
			if rarity.begins_with("elite_"):
				return "Элитная"
			elif rarity == "boss":
				return "Босс"
			return rarity.capitalize()

func _on_continue_pressed():
	"""Выполняет функционал кнопки Далее: сохраняет данные и переходит к выбору комнаты"""
	# Получаем battle_manager через родительский узел (VictoryScreen добавляется как дочерний узел battle_manager)
	var battle_manager = get_parent()
	if not battle_manager or not battle_manager.has_method("_save_player_data"):
		# Если не удалось найти через родителя, пробуем через current_scene
		battle_manager = get_tree().current_scene
	
	# Анимация исчезновения
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(victory_panel, "scale", Vector2(0.8, 0.8), 0.2)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)
	
	await tween.finished
	
	# Удаляем экран перед переходом
	queue_free()
	
	# Проверяем, находимся ли мы в тестовом режиме
	if battle_manager and "test_mode" in battle_manager:
		if battle_manager.test_mode:
			print("Тестовый режим: возвращаемся к выбору врага")
			# В тестовом режиме возвращаемся к выбору врага
			SceneTransition.change_scene("res://Scenes/TestArena.tscn")
			return
	
	# Сохраняем данные игрока
	if battle_manager and battle_manager.has_method("_save_player_data"):
		battle_manager._save_player_data()
	
	# Автоматически сохраняем игру
	var player_manager_node = get_node_or_null("/root/PlayerManager")
	if player_manager_node:
		player_manager_node.save_game_data()
	
	# Переходим к выбору комнат
	SceneTransition.change_scene("res://Scenes/RoomSelector.tscn")

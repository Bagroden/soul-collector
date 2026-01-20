# res://Scripts/TestArena.gd
extends Control

@onready var enemy_buttons = $MainContainer/ContentContainer/LeftPanel/EnemyList/EnemyButtons
@onready var rarity_buttons = $MainContainer/ContentContainer/LeftPanel/RarityButtons
@onready var level_spinbox = $MainContainer/ContentContainer/LeftPanel/LevelSelector/LevelSpinBox
@onready var start_battle_btn = $MainContainer/ContentContainer/RightPanel/BattleButtons/StartBattleBtn
@onready var heal_player_btn = $MainContainer/ContentContainer/RightPanel/BattleButtons/HealButtons/HealPlayerBtn
@onready var heal_enemy_btn = $MainContainer/ContentContainer/RightPanel/BattleButtons/HealButtons/HealEnemyBtn
@onready var reset_player_btn = $MainContainer/ContentContainer/RightPanel/BattleButtons/ResetButtons/ResetPlayerBtn
@onready var reset_enemy_btn = $MainContainer/ContentContainer/RightPanel/BattleButtons/ResetButtons/ResetEnemyBtn
@onready var back_btn = $MainContainer/BottomButtons/BackBtn
@onready var current_enemy_label = $MainContainer/BottomButtons/CurrentEnemyLabel

var selected_enemy_scene: String = ""
var selected_rarity: String = "common"
var selected_level: int = 1
var current_battle_scene: Node = null

# Список всех доступных врагов
var available_enemies = {
	# Обычные враги
	"Крыса": "res://Scenes/Battle/Enemy_Rat.tscn",
	"Летучая мышь": "res://Scenes/Battle/Enemy_Bat.tscn",
	"Слизень": "res://Scenes/Battle/Enemy_Slime.tscn",
	"Гнилой слизень": "res://Scenes/Battle/Enemy_RottenSlime.tscn",
	
	# Демоны
	"Демон Алкары": "res://Scenes/Battle/Enemy_AlkaraDemon.tscn",
	"Демон Проклятия": "res://Scenes/Battle/Enemy_CurseDemon.tscn",
	"Демон Палач": "res://Scenes/Battle/Enemy_ExecutionerDemon.tscn",
	"Демон Тарнок": "res://Scenes/Battle/Enemy_TharnokDemon.tscn",
	
	# Гоблины
	"Гоблин": "res://Scenes/Battle/Enemy_Goblin.tscn",
	"Гоблин воин": "res://Scenes/Battle/Enemy_GoblinWarrior.tscn",
	"Гоблин вор": "res://Scenes/Battle/Enemy_GoblinThief.tscn",
	"Гоблин колдун": "res://Scenes/Battle/Enemy_GoblinMage.tscn",
	
	# Боссы
	"Темный преследователь": "res://Scenes/Battle/Enemy_DarkStalker.tscn",
	"Демон Тарнок (легендарный)": "res://Scenes/Battle/Enemy_TharnokDemon.tscn"
}

# Цвета для редкости
var rarity_colors = {
	"common": Color(0.7, 0.7, 0.7, 1),      # Серый
	"uncommon": Color(0.2, 0.8, 0.2, 1),    # Зеленый
	"rare": Color(0.2, 0.4, 0.8, 1),        # Синий
	"epic": Color(0.6, 0.2, 0.8, 1),        # Фиолетовый
	"legendary": Color(0.8, 0.6, 0.2, 1)    # Золотой
}

func _ready():
	# Подключаем сигналы
	start_battle_btn.connect("pressed", Callable(self, "_on_start_battle_pressed"))
	heal_player_btn.connect("pressed", Callable(self, "_on_heal_player_pressed"))
	heal_enemy_btn.connect("pressed", Callable(self, "_on_heal_enemy_pressed"))
	reset_player_btn.connect("pressed", Callable(self, "_on_reset_player_pressed"))
	reset_enemy_btn.connect("pressed", Callable(self, "_on_reset_enemy_pressed"))
	back_btn.connect("pressed", Callable(self, "_on_back_pressed"))
	
	# Подключаем кнопки редкости
	for button in rarity_buttons.get_children():
		button.connect("pressed", Callable(self, "_on_rarity_selected").bind(button.text.to_lower()))
	
	# Подключаем спинбокс уровня
	if level_spinbox:
		level_spinbox.connect("value_changed", Callable(self, "_on_level_changed"))
		level_spinbox.min_value = 1
		level_spinbox.max_value = 50
		level_spinbox.value = 1
	
	# Инициализируем
	_create_enemy_buttons()
	_update_rarity_buttons()
	_update_current_enemy_display()

func _create_enemy_buttons():
	# Очищаем существующие кнопки
	for child in enemy_buttons.get_children():
		child.queue_free()
	
	# Создаем кнопки для каждого врага
	for enemy_name in available_enemies.keys():
		var button = Button.new()
		button.text = enemy_name
		button.custom_minimum_size = Vector2(0, 35)
		button.pressed.connect(_on_enemy_selected.bind(enemy_name))
		enemy_buttons.add_child(button)

func _update_rarity_buttons():
	# Обновляем цвета кнопок редкости
	for button in rarity_buttons.get_children():
		var rarity = button.text.to_lower()
		if rarity in rarity_colors:
			button.add_theme_color_override("font_color", rarity_colors[rarity])
			if rarity == selected_rarity:
				button.add_theme_color_override("font_pressed_color", Color.WHITE)
				button.add_theme_color_override("font_hover_color", Color.WHITE)

func _on_enemy_selected(enemy_name: String):
	selected_enemy_scene = available_enemies[enemy_name]
	_update_current_enemy_display()
	print("Выбран враг: ", enemy_name, " (", selected_rarity, ")")

func _on_rarity_selected(rarity: String):
	selected_rarity = rarity
	_update_rarity_buttons()
	_update_current_enemy_display()
	print("Выбрана редкость: ", rarity)

func _on_level_changed(level: int):
	selected_level = level
	_update_current_enemy_display()
	print("Выбран уровень: ", level)

func _update_current_enemy_display():
	if selected_enemy_scene != "":
		var enemy_name = ""
		for enemy_name_key in available_enemies.keys():
			if available_enemies[enemy_name_key] == selected_enemy_scene:
				enemy_name = enemy_name_key
				break
		
		var rarity_display = _get_rarity_display_name(selected_rarity)
		current_enemy_label.text = "Выбранный враг: " + enemy_name + " (" + rarity_display + ", ур. " + str(selected_level) + ")"
		start_battle_btn.disabled = false
	else:
		current_enemy_label.text = "Выбранный враг: Нет"
		start_battle_btn.disabled = true

func _get_rarity_display_name(rarity: String) -> String:
	match rarity:
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
		_:
			return "Неизвестный"

func _on_start_battle_pressed():
	if selected_enemy_scene == "":
		print("Ошибка: не выбран враг")
		return
	
	print("Начинаем тестовый бой с ", selected_enemy_scene, " (", selected_rarity, ")")
	
	# Устанавливаем глобальные переменные тестового режима ПЕРЕД созданием BattleManager
	_set_global_test_variables()
	
	# Загружаем сцену боя
	var battle_scene = preload("res://Scenes/Battle/BattleScene.tscn")
	var battle_instance = battle_scene.instantiate()
	
	# Добавляем как дочерний узел
	add_child(battle_instance)
	current_battle_scene = battle_instance
	
	# Ждем несколько кадров, чтобы BattleManager полностью инициализировался
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Настраиваем бой для тестирования
	_setup_test_battle(battle_instance)
	
	# Скрываем интерфейс арены
	$MainContainer.visible = false

func _setup_test_battle(battle_scene: Node):
	# Получаем battle_manager из сцены боя
	var battle_manager = battle_scene.get_node_or_null("BattleManager")
	if not battle_manager:
		print("Ошибка: BattleManager не найден в сцене боя")
		return
	
	print("BattleManager найден: ", battle_manager)
	print("BattleManager готов: ", battle_manager.is_ready())
	
	print("Выбранный враг: ", selected_enemy_scene)
	print("Выбранная редкость: ", selected_rarity)
	
	# Устанавливаем тестовый режим
	if battle_manager.has_method("set_test_mode"):
		battle_manager.set_test_mode(true)
		print("Тестовый режим установлен")
		# Проверяем, что режим действительно установлен
		if battle_manager.has_method("get") and battle_manager.get("test_mode"):
			print("✅ test_mode подтвержден: ", battle_manager.get("test_mode"))
		else:
			print("❌ test_mode НЕ установлен!")
	else:
		print("ОШИБКА: метод set_test_mode не найден!")
	
	# Устанавливаем выбранного врага
	if battle_manager.has_method("set_test_enemy"):
		battle_manager.set_test_enemy(selected_enemy_scene, selected_rarity)
		print("Тестовый враг установлен: ", selected_enemy_scene, " (", selected_rarity, ")")
		# Проверяем, что враг действительно установлен
		if battle_manager.has_method("get"):
			print("✅ test_enemy_scene подтвержден: ", battle_manager.get("test_enemy_scene"))
			print("✅ test_enemy_rarity подтвержден: ", battle_manager.get("test_enemy_rarity"))
		else:
			print("❌ test_enemy_scene НЕ установлен!")
	else:
		print("ОШИБКА: метод set_test_enemy не найден!")
	
	# Подключаемся к сигналам завершения боя
	if battle_manager.has_method("connect"):
		battle_manager.connect("battle_ended", Callable(self, "_on_battle_ended"))
		print("Сигнал battle_ended подключен")
	
	# Ждем несколько кадров, чтобы переменные точно установились
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Запускаем спавн тестового врага
	if battle_manager.has_method("spawn_enemy"):
		print("Запускаем спавн тестового врага...")
		battle_manager.spawn_enemy()
	else:
		print("ОШИБКА: метод spawn_enemy не найден!")
	

func _on_battle_ended(result: String):
	print("Бой завершен с результатом: ", result)
	
	# Удаляем сцену боя
	if current_battle_scene:
		current_battle_scene.queue_free()
		current_battle_scene = null
	
	# Показываем интерфейс арены
	$MainContainer.visible = true

func _on_heal_player_pressed():
	if not current_battle_scene:
		print("Нет активного боя для лечения игрока")
		return
	
	var battle_manager = current_battle_scene.get_node_or_null("BattleManager")
	if battle_manager and battle_manager.has_method("heal_player"):
		battle_manager.heal_player()
		print("Игрок вылечен")
	else:
		print("Не удалось вылечить игрока")

func _on_heal_enemy_pressed():
	if not current_battle_scene:
		print("Нет активного боя для лечения врага")
		return
	
	var battle_manager = current_battle_scene.get_node_or_null("BattleManager")
	if battle_manager and battle_manager.has_method("heal_enemy"):
		battle_manager.heal_enemy()
		print("Враг вылечен")
	else:
		print("Не удалось вылечить врага")

func _on_reset_player_pressed():
	if not current_battle_scene:
		print("Нет активного боя для сброса игрока")
		return
	
	var battle_manager = current_battle_scene.get_node_or_null("BattleManager")
	if battle_manager and battle_manager.has_method("reset_player"):
		battle_manager.reset_player()
		print("Игрок сброшен")
	else:
		print("Не удалось сбросить игрока")

func _on_reset_enemy_pressed():
	if not current_battle_scene:
		print("Нет активного боя для сброса врага")
		return
	
	var battle_manager = current_battle_scene.get_node_or_null("BattleManager")
	if battle_manager and battle_manager.has_method("reset_enemy"):
		battle_manager.reset_enemy()
		print("Враг сброшен")
	else:
		print("Не удалось сбросить врага")

func _set_global_test_variables():
	"""Устанавливает глобальные переменные тестового режима"""
	# Преобразуем редкость с русского на английский
	var english_rarity = _convert_rarity_to_english(selected_rarity)
	
	# Устанавливаем глобальные переменные, которые BattleManager будет читать в _ready()
	# Это нужно сделать ДО создания BattleManager
	# Используем глобальные переменные или синглтон
	if not has_node("/root/TestArenaGlobals"):
		var globals = Node.new()
		globals.name = "TestArenaGlobals"
		get_tree().root.add_child(globals)
		globals.set_script(preload("res://Scripts/TestArenaGlobals.gd"))
	
	var test_globals = get_node("/root/TestArenaGlobals")
	if test_globals:
		test_globals.test_mode = true
		test_globals.test_enemy_scene = selected_enemy_scene
		test_globals.test_enemy_rarity = english_rarity  # Используем английскую редкость
		test_globals.test_enemy_level = selected_level

func _convert_rarity_to_english(russian_rarity: String) -> String:
	"""Преобразует редкость с русского на английский"""
	match russian_rarity:
		"обычный":
			return "common"
		"необычный":
			return "uncommon"
		"редкий":
			return "rare"
		"эпический":
			return "epic"
		"легендарный":
			return "legendary"
		"элитный":
			return "elite"
		"босс":
			return "boss"
		_:
			print("❌ ОШИБКА: Неизвестная редкость: ", russian_rarity)
			return "common"  # Fallback к common

func _on_back_pressed():
	print("Возвращаемся к выбору локаций...")
	SceneTransition.change_scene("res://Scenes/LocationSelector.tscn")

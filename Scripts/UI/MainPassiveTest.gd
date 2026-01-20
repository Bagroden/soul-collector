# res://Scripts/UI/MainPassiveTest.gd
extends Control

var passive_window_scene = preload("res://Scenes/UI/PassiveAbilitiesWindow.tscn")
var battle_scene = preload("res://Scenes/Battle/BattleScene.tscn")
var passive_window: Control
var battle_scene_instance: Control

@onready var learn_button: Button = $VBoxContainer/LearnPassivesButton
@onready var open_window_button: Button = $VBoxContainer/OpenPassivesWindowButton
@onready var test_button: Button = $VBoxContainer/TestActivationButton
@onready var battle_button: Button = $VBoxContainer/StartBattleButton
@onready var info_label: Label = $VBoxContainer/InfoLabel
@onready var close_button: Button = $VBoxContainer/CloseButton

func _ready():
	# Подключаем сигналы
	learn_button.pressed.connect(_on_learn_button_pressed)
	open_window_button.pressed.connect(_on_open_window_button_pressed)
	test_button.pressed.connect(_on_test_button_pressed)
	battle_button.pressed.connect(_on_battle_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	
	# Обновляем информацию
	update_info()

func _on_learn_button_pressed():
	"""Изучаем базовые пассивные способности"""
	var player_data = PlayerManager.get_player_data()
	player_data.initialize_passive_system()
	
	# Изучаем базовые способности
	var abilities_to_learn = ["player_fortress", "player_strong", "player_wise", "player_vitality"]
	var learned_count = 0
	
	for ability_id in abilities_to_learn:
		var success = player_data.learn_passive_ability(ability_id)
		if success:
			learned_count += 1
			print("Изучена способность: ", ability_id)
		else:
			print("Ошибка изучения способности: ", ability_id)
	
	info_label.text = "Изучено способностей: " + str(learned_count) + " из " + str(abilities_to_learn.size())
	print("Изучение пассивных способностей завершено!")

func _on_open_window_button_pressed():
	"""Показываем окно пассивных способностей"""
	if not passive_window:
		passive_window = passive_window_scene.instantiate()
		add_child(passive_window)
	
	passive_window.show_window()
	info_label.text = "Окно пассивных способностей открыто"

func _on_test_button_pressed():
	"""Тестируем активацию/деактивацию пассивок"""
	var player_data = PlayerManager.get_player_data()
	
	# Показываем текущее состояние
	var learned_passives = player_data.get_learned_passives()
	var active_passives = player_data.get_active_passives()
	
	
	# Тестируем активацию
	var success = player_data.activate_passive_ability("player_fortress")
	print("Активация player_fortress: ", success)
	
	success = player_data.activate_passive_ability("player_strength")
	print("Активация player_strength: ", success)
	
	# Показываем активные способности
	active_passives = player_data.get_active_passives()
	print("Активные пассивки после активации: ", active_passives)
	
	# Тестируем деактивацию
	success = player_data.deactivate_passive_ability("player_fortress")
	print("Деактивация player_fortress: ", success)
	
	active_passives = player_data.get_active_passives()
	print("Активные пассивки после деактивации: ", active_passives)
	
	info_label.text = "Тест завершен. Активных способностей: " + str(active_passives.size())

func _on_battle_button_pressed():
	"""Запускаем бой для тестирования пассивных способностей"""
	if not battle_scene_instance:
		battle_scene_instance = battle_scene.instantiate()
		add_child(battle_scene_instance)
	
	info_label.text = "Бой запущен! Пассивные способности будут применены автоматически."

func _on_close_button_pressed():
	"""Закрываем тестовое окно"""
	queue_free()

func update_info():
	"""Обновляем информационную метку"""
	var player_data = PlayerManager.get_player_data()
	if player_data:
		var learned_count = player_data.get_learned_passives().size()
		var active_count = player_data.get_active_passives().size()
		info_label.text = "Изучено: " + str(learned_count) + ", Активно: " + str(active_count)
	else:
		info_label.text = "PlayerData не найден"

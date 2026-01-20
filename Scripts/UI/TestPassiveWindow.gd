# res://Scripts/UI/TestPassiveWindow.gd
extends Control

var passive_window_scene = preload("res://Scenes/UI/PassiveAbilitiesWindow.tscn")
var passive_window: Control

@onready var learn_button: Button = $VBoxContainer/LearnButton
@onready var show_passives_button: Button = $VBoxContainer/ShowPassivesButton
@onready var test_button: Button = $VBoxContainer/TestButton
@onready var close_button: Button = $VBoxContainer/CloseButton

func _ready():
	# Подключаем сигналы
	learn_button.pressed.connect(_on_learn_button_pressed)
	show_passives_button.pressed.connect(_on_show_passives_button_pressed)
	test_button.pressed.connect(_on_test_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)

func _on_learn_button_pressed():
	"""Изучаем базовые пассивные способности"""
	var player_data = PlayerManager.get_player_data()
	player_data.initialize_passive_system()
	
	# Изучаем базовые способности
	var abilities_to_learn = ["player_fortress", "player_strong", "player_wise", "player_vitality"]
	
	for ability_id in abilities_to_learn:
		var success = player_data.learn_passive_ability(ability_id)
		if success:
			print("Изучена способность: ", ability_id)
		else:
			print("Ошибка изучения способности: ", ability_id)
	
	print("Изучение пассивных способностей завершено!")

func _on_show_passives_button_pressed():
	"""Показываем окно пассивных способностей"""
	if not passive_window:
		passive_window = passive_window_scene.instantiate()
		add_child(passive_window)
	
	passive_window.show_window()

func _on_test_button_pressed():
	"""Тестируем активацию/деактивацию пассивок"""
	var player_data = PlayerManager.get_player_data()
	
	# Тестируем активацию
	var success = player_data.activate_passive_ability("player_fortress")
	print("Активация player_fortress: ", success)
	
	success = player_data.activate_passive_ability("player_strength")
	print("Активация player_strength: ", success)
	
	# Показываем активные способности
	var active_passives = player_data.get_active_passives()
	print("Активные пассивки: ", active_passives)
	
	# Тестируем деактивацию
	success = player_data.deactivate_passive_ability("player_fortress")
	print("Деактивация player_fortress: ", success)
	
	active_passives = player_data.get_active_passives()
	print("Активные пассивки после деактивации: ", active_passives)

func _on_close_button_pressed():
	"""Закрываем тестовое окно"""
	queue_free()

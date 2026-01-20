# res://Scripts/StatsScreen.gd
extends Control

# Переменная для отслеживания предыдущей сцены
var previous_scene: String = "res://Scenes/RoomSelector.tscn"

@onready var level_label = $VBoxContainer/LevelInfo/LevelLabel
@onready var exp_label = $VBoxContainer/LevelInfo/ExpLabel
@onready var stat_points_label = $VBoxContainer/LevelInfo/StatPointsLabel

# Шкала прогресса опыта (создается динамически)
var exp_progress_bar: ProgressBar = null

@onready var strength_label = $VBoxContainer/StatsContainer/Strength/ValueLabel
@onready var agility_label = $VBoxContainer/StatsContainer/Agility/ValueLabel
@onready var vitality_label = $VBoxContainer/StatsContainer/Vitality/ValueLabel
@onready var endurance_label = $VBoxContainer/StatsContainer/Endurance/ValueLabel
@onready var intelligence_label = $VBoxContainer/StatsContainer/Intelligence/ValueLabel
@onready var wisdom_label = $VBoxContainer/StatsContainer/Wisdom/ValueLabel

@onready var strength_btn = $VBoxContainer/StatsContainer/Strength/AddBtn
@onready var agility_btn = $VBoxContainer/StatsContainer/Agility/AddBtn
@onready var vitality_btn = $VBoxContainer/StatsContainer/Vitality/AddBtn
@onready var endurance_btn = $VBoxContainer/StatsContainer/Endurance/AddBtn
@onready var intelligence_btn = $VBoxContainer/StatsContainer/Intelligence/AddBtn
@onready var wisdom_btn = $VBoxContainer/StatsContainer/Wisdom/AddBtn

@onready var close_btn = $VBoxContainer/CloseBtn

# Подробная статистика
@onready var health_label = $VBoxContainer/DetailedStatsContainer/HealthStats/ValueLabel
@onready var mana_label = $VBoxContainer/DetailedStatsContainer/ManaStats/ValueLabel
@onready var stamina_label = $VBoxContainer/DetailedStatsContainer/StaminaStats/ValueLabel
@onready var hp_regen_label = $VBoxContainer/DetailedStatsContainer/RegenStats/HPRegen/ValueLabel
@onready var mp_regen_label = $VBoxContainer/DetailedStatsContainer/RegenStats/MPRegen/ValueLabel
@onready var sp_regen_label = $VBoxContainer/DetailedStatsContainer/RegenStats/SPRegen/ValueLabel
@onready var action_points_label = $VBoxContainer/DetailedStatsContainer/CombatStats/ActionPoints/ValueLabel
@onready var physical_damage_label = $VBoxContainer/DetailedStatsContainer/CombatStats/PhysicalDamage/ValueLabel
@onready var crit_chance_label = $VBoxContainer/DetailedStatsContainer/CombatStats/CritChance/ValueLabel
@onready var crit_damage_label = $VBoxContainer/DetailedStatsContainer/CombatStats/CritDamage/ValueLabel
@onready var dodge_chance_label = $VBoxContainer/DetailedStatsContainer/CombatStats/DodgeChance/ValueLabel
@onready var accuracy_label = $VBoxContainer/DetailedStatsContainer/CombatStats/Accuracy/ValueLabel
@onready var speed_label = $VBoxContainer/DetailedStatsContainer/CombatStats/Speed/ValueLabel
@onready var armor_label = $VBoxContainer/DetailedStatsContainer/DefenseStats/Armor/ValueLabel
@onready var magic_resist_label = $VBoxContainer/DetailedStatsContainer/DefenseStats/MagicResist/ValueLabel
@onready var magic_damage_label = $VBoxContainer/DetailedStatsContainer/MagicStats/MagicDamage/ValueLabel
@onready var magic_crit_chance_label = $VBoxContainer/DetailedStatsContainer/MagicStats/MagicCritChance/ValueLabel
@onready var magic_crit_damage_label = $VBoxContainer/DetailedStatsContainer/MagicStats/MagicCritDamage/ValueLabel

var player_manager: Node

func _ready():
	# Создаем шкалу прогресса опыта
	_create_exp_progress_bar()
	
	# Получаем менеджер игрока
	player_manager = get_node_or_null("/root/PlayerManager")
	if not player_manager:
		push_error("PlayerManager не найден!")
		return
	
	# Подключаем сигналы
	var player_data = player_manager.get_player_data()
	if player_data:
		player_data.connect("level_up", Callable(self, "_on_level_up"))
		player_data.connect("stat_points_changed", Callable(self, "_on_stat_points_changed"))
		player_data.connect("experience_changed", Callable(self, "_on_experience_changed"))
		player_data.connect("stats_updated", Callable(self, "_on_stats_updated"))
		# Подключаемся к сигналам изменения ресурсов для обновления отображения
		player_data.connect("health_changed", Callable(self, "_on_player_data_changed"))
		player_data.connect("mana_changed", Callable(self, "_on_player_data_changed"))
		player_data.connect("stamina_changed", Callable(self, "_on_player_data_changed"))
	
	# Подключаем кнопки
	strength_btn.connect("pressed", Callable(self, "_on_strength_pressed"))
	agility_btn.connect("pressed", Callable(self, "_on_agility_pressed"))
	vitality_btn.connect("pressed", Callable(self, "_on_vitality_pressed"))
	endurance_btn.connect("pressed", Callable(self, "_on_endurance_pressed"))
	intelligence_btn.connect("pressed", Callable(self, "_on_intelligence_pressed"))
	wisdom_btn.connect("pressed", Callable(self, "_on_wisdom_pressed"))
	close_btn.connect("pressed", Callable(self, "_on_close_pressed"))
	
	# Подключаем сигнал изменения видимости
	visibility_changed.connect(Callable(self, "_on_visibility_changed"))
	
	# Устанавливаем фокус для обработки клавиш
	set_process_input(true)
	
	update_display()

func _on_visibility_changed():
	"""Вызывается при изменении видимости экрана статистики"""
	if visible:
		# Принудительно обновляем отображение при показе экрана
		update_display()

func update_display():
	if not player_manager:
		return
	
	var player_data = player_manager.get_player_data()
	if not player_data:
		return
	
	# Обновляем информацию об уровне
	level_label.text = "Уровень: " + str(player_data.level)
	
	# Обновляем шкалу прогресса опыта
	var current_exp = player_data.experience
	var exp_to_next = player_data.get_exp_for_level(player_data.level + 1)
	exp_label.text = "Опыт: " + str(current_exp) + " / " + str(exp_to_next)
	
	if exp_progress_bar:
		exp_progress_bar.max_value = exp_to_next
		exp_progress_bar.value = current_exp
	
	stat_points_label.text = "Свободных очков: " + str(player_data.stat_points)
	
	# Выделяем свободные очки цветом и анимацией, если они есть
	if player_data.stat_points > 0:
		stat_points_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))  # Золотой
		_start_pulse_animation(stat_points_label)
	else:
		stat_points_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))  # Серый
		_stop_pulse_animation(stat_points_label)
	
	# Обновляем характеристики
	strength_label.text = str(player_data.strength)
	agility_label.text = str(player_data.agility)
	vitality_label.text = str(player_data.vitality)
	endurance_label.text = str(player_data.endurance)
	intelligence_label.text = str(player_data.intelligence)
	wisdom_label.text = str(player_data.wisdom)
	
	# Обновляем состояние кнопок
	var has_points = player_data.stat_points > 0
	strength_btn.disabled = not has_points
	agility_btn.disabled = not has_points
	vitality_btn.disabled = not has_points
	endurance_btn.disabled = not has_points
	intelligence_btn.disabled = not has_points
	wisdom_btn.disabled = not has_points
	
	# Обновляем подробную статистику
	update_detailed_stats(player_data)

func _on_strength_pressed():
	add_stat_point("strength")

func _on_agility_pressed():
	add_stat_point("agility")

func _on_vitality_pressed():
	add_stat_point("vitality")

func _on_endurance_pressed():
	add_stat_point("endurance")

func _on_intelligence_pressed():
	add_stat_point("intelligence")

func _on_wisdom_pressed():
	add_stat_point("wisdom")

func add_stat_point(stat_name: String):
	if not player_manager:
		return
	
	var player_data = player_manager.get_player_data()
	if not player_data:
		return
	
	print("StatsScreen: ДО добавления очка в ", stat_name, ":")
	print("  Base: STR=", player_data.base_strength, " AGI=", player_data.base_agility, " VIT=", player_data.base_vitality)
	print("  Final: STR=", player_data.strength, " AGI=", player_data.agility, " VIT=", player_data.vitality)
	
	if player_data.add_stat_point(stat_name):
		print("StatsScreen: ПОСЛЕ добавления очка в ", stat_name, ":")
		print("  Base: STR=", player_data.base_strength, " AGI=", player_data.base_agility, " VIT=", player_data.base_vitality)
		print("  Final: STR=", player_data.strength, " AGI=", player_data.agility, " VIT=", player_data.vitality)
		
		update_display()
		# Автоматически сохраняем игру после распределения очка
		player_manager.save_game_data()

func _on_level_up(new_level: int):
	update_display()
	print("Получен уровень ", new_level, "!")

func _on_stat_points_changed(_points: int):
	update_display()

func _on_experience_changed(_current_exp: int, _exp_to_next: int):
	update_display()

func _on_player_data_changed(_value1 = 0, _value2 = 0):
	# Обновляем отображение при любом изменении данных игрока
	update_display()

func _on_stats_updated():
	# Обновляем отображение при изменении статистики (например, при активации пассивных способностей)
	update_display()

func set_previous_scene(scene_path: String):
	"""Устанавливает предыдущую сцену для возврата"""
	previous_scene = scene_path
	print("Установлена предыдущая сцена: ", previous_scene)

func _input(event):
	"""Обрабатывает ввод пользователя"""
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_on_close_pressed()

func _on_close_pressed():
	# Останавливаем все анимации перед закрытием
	for label in pulse_tweens.keys():
		_stop_pulse_animation(label)
	
	# Возвращаемся к предыдущей сцене
	print("Возвращаемся к предыдущей сцене: ", previous_scene)
	get_tree().change_scene_to_file(previous_scene)

func update_detailed_stats(player_data):
	"""Обновляет отображение подробной статистики персонажа"""
	
	# Здоровье: Макс ОЗ = Базовое ОЗ + Бонус от характеристики Живучесть + бонус от пассивных способностей
	var max_hp = player_data.get_max_health()
	health_label.text = str(max_hp)
	health_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))  # Красный
	
	# Мана: Макс ОМ = Базовое значение ОМ + бонус от Мудрости + бонус от пассивных способностей
	var max_mp = player_data.get_max_mana()
	mana_label.text = str(max_mp)
	mana_label.add_theme_color_override("font_color", Color(0.3, 0.6, 1.0))  # Голубой
	
	# Выносливость: Макс ОВ = формула аналогично ОЗ и ОМ
	var max_sp = player_data.get_max_stamina()
	stamina_label.text = str(max_sp)
	stamina_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))  # Зеленый
	
	# Регенерация ОЗ: Сумарный реген ОЗ = Базовый реген ОЗ + реген от характеристик Живучести + Пассивные способности
	var hp_regen = player_data.get_hp_regeneration()
	hp_regen_label.text = str(hp_regen) + "/раунд"
	
	# Регенерация ОВ: Сумарный реген ОВ = Аналогично формуле для регена ОЗ
	var sp_regen = player_data.get_sp_regeneration()
	sp_regen_label.text = str(sp_regen) + "/раунд"
	
	# Регенерация ОМ: Суммарный реген ОМ = Аналогично формуле регена ОЗ
	var mp_regen = player_data.get_mp_regeneration()
	mp_regen_label.text = str(mp_regen) + "/раунд"
	
	# Очки действий: Количество базовых очков действий (по умолчанию 1)
	var action_points = player_data.get_action_points()
	action_points_label.text = str(action_points)
	
	# Бонус физического урона (зависит от силы): За каждое очко силы 1 бонус к физ урону + бонусы от пассивных способностей
	var phys_damage = player_data.get_physical_damage_bonus()
	physical_damage_label.text = "+" + str(phys_damage)
	
	# Шанс критической атаки: Базовый шанс крита + бонус от ловкости + от пассивных способностей
	var crit_chance = player_data.get_crit_chance()
	crit_chance_label.text = str(crit_chance) + "%"
	
	# Сила критической атаки: Базовая сила крита 1.5 + бонус от пассивных способностей
	var crit_damage = player_data.get_crit_damage_multiplier()
	crit_damage_label.text = str(int(crit_damage * 100)) + "%"
	
	# Уворот: Базовый шанс уворота 5% + бонусы от пассивных способностей
	var dodge_chance = player_data.get_dodge_chance()
	dodge_chance_label.text = str(dodge_chance) + "%"
	
	# Меткость: Базовая меткость 100% + бонусы от пассивных способностей
	var accuracy = player_data.get_accuracy()
	accuracy_label.text = str(accuracy) + "%"
	
	# Скорость: Базовое значение 0% + бонус от пассивных способностей
	var speed = player_data.get_speed_bonus()
	speed_label.text = str(speed) + "%"
	
	# Броня: Базовое значение 0 + бонус от пассивных способностей
	var armor = player_data.get_armor()
	armor_label.text = str(armor)
	
	# Магическое сопротивление: Базовое значение 0 + бонус от пассивных способностей
	var magic_resist = player_data.get_magic_resistance()
	magic_resist_label.text = str(magic_resist) + "%"
	
	# Усиление магического урона: Базовое значение 0 + бонус от интеллекта 1% за единицу + бонус от пассивных способностей
	var magic_damage = player_data.get_magic_damage_bonus()
	magic_damage_label.text = "+" + str(magic_damage) + "%"
	
	# Шанс магического крита: Базовый шанс 5% + бонус от интеллекта 1% за единицу + бонус от пассивных способностей
	var magic_crit_chance = player_data.get_magic_crit_chance()
	magic_crit_chance_label.text = str(magic_crit_chance) + "%"
	
	# Сила магического крита: Базовая сила 1.5 + бонус от пассивных способностей
	var magic_crit_damage = player_data.get_magic_crit_damage()
	magic_crit_damage_label.text = str(int(magic_crit_damage * 100)) + "%"

## === АНИМАЦИЯ ПУЛЬСАЦИИ ДЛЯ СВОБОДНЫХ ОЧКОВ ===

var pulse_tweens: Dictionary = {}  # Словарь активных анимаций {node: tween}

func _start_pulse_animation(label: Label):
	"""Запускает анимацию пульсации для метки"""
	# Останавливаем предыдущую анимацию, если она есть
	_stop_pulse_animation(label)
	
	# Создаем новую анимацию
	var tween = create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# Пульсация масштаба от 1.0 до 1.15 и обратно
	tween.tween_property(label, "scale", Vector2(1.15, 1.15), 0.8)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.8)
	
	# Сохраняем ссылку на tween
	pulse_tweens[label] = tween

func _stop_pulse_animation(label: Label):
	"""Останавливает анимацию пульсации для метки"""
	if label in pulse_tweens:
		var tween = pulse_tweens[label]
		if tween:
			tween.kill()
		pulse_tweens.erase(label)
	
	# Возвращаем нормальный масштаб
	label.scale = Vector2(1.0, 1.0)

func _create_exp_progress_bar():
	"""Создает шкалу прогресса опыта под меткой опыта"""
	# Находим родительский контейнер для метки опыта
	var level_info = get_node_or_null("VBoxContainer/LevelInfo")
	if not level_info:
		push_error("LevelInfo контейнер не найден!")
		return
	
	# Создаем ProgressBar
	exp_progress_bar = ProgressBar.new()
	exp_progress_bar.name = "ExpProgressBar"
	exp_progress_bar.custom_minimum_size = Vector2(400, 30)
	exp_progress_bar.show_percentage = false
	
	# Стилизация шкалы прогресса
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.2, 0.2, 0.25, 0.8)
	style_bg.corner_radius_top_left = 5
	style_bg.corner_radius_top_right = 5
	style_bg.corner_radius_bottom_left = 5
	style_bg.corner_radius_bottom_right = 5
	exp_progress_bar.add_theme_stylebox_override("background", style_bg)
	
	var style_fill = StyleBoxFlat.new()
	style_fill.bg_color = Color(0.3, 0.8, 1.0, 1.0)  # Голубой цвет опыта
	style_fill.corner_radius_top_left = 5
	style_fill.corner_radius_top_right = 5
	style_fill.corner_radius_bottom_left = 5
	style_fill.corner_radius_bottom_right = 5
	exp_progress_bar.add_theme_stylebox_override("fill", style_fill)
	
	# Добавляем ProgressBar после метки опыта
	var exp_label_index = exp_label.get_index()
	level_info.add_child(exp_progress_bar)
	level_info.move_child(exp_progress_bar, exp_label_index + 1)
	
	print("✅ Шкала прогресса опыта создана")

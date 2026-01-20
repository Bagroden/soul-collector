# res://Scripts/Battle/ui_controller.gd
extends Control

@onready var root_scene := get_parent()
@onready var player := root_scene.get_node("GameWorld/PlayerBody")

# === СИСТЕМА МНОЖЕСТВЕННЫХ ВРАГОВ ===
var enemies: Array[Node2D] = []  # Массив всех врагов
var selected_enemy_index: int = 0  # Индекс выбранного врага для подсветки (deprecated, используйте selected_enemy)
var selected_enemy: Node2D = null  # Ссылка на выбранного врага для подсветки

# Флаг для предотвращения одновременного обновления иконок статусов
var is_updating_status_icons: bool = false
var last_player_barrier_value: int = -1  # Отслеживаем значение барьера для принудительного обновления
# Переменная для отслеживания последнего состояния эффектов (чтобы не обновлять без изменений)
var last_player_effects_hash: int = 0
# Отслеживание эффектов и барьеров для врагов: {enemy_index: {"hash": int, "barrier": int}}
var last_enemy_effects: Dictionary = {}

# Обратная совместимость (deprecated, используйте enemies[0])
var enemy: Node2D:
	get:
		return enemies[0] if enemies.size() > 0 else null
	set(value):
		if enemies.size() == 0:
			enemies.append(value)
		else:
			enemies[0] = value

func _ready() -> void:
	# Подключаем кнопку атаки
	if has_node("Actions/Btn_Attack"):
		var btn = $Actions/Btn_Attack
		if not btn.is_connected("pressed", Callable(self, "_on_attack_pressed")):
			btn.connect("pressed", Callable(self, "_on_attack_pressed"))
	else:
		push_error("Btn_Attack not found at path: Actions/Btn_Attack")
	
	# Подключаем кнопку защиты
	if has_node("Actions/Btn_Defend"):
		var btn_defend = $Actions/Btn_Defend
		if not btn_defend.is_connected("pressed", Callable(self, "_on_defend_pressed")):
			btn_defend.connect("pressed", Callable(self, "_on_defend_pressed"))
	else:
		push_error("Btn_Defend not found at path: Actions/Btn_Defend")
	
	# Подключаем кнопку пассивных способностей врага
	if has_node("EnemyHUD/EnemyPassivesBtn"):
		var btn_passives = $EnemyHUD/EnemyPassivesBtn
		if not btn_passives.is_connected("pressed", Callable(self, "_on_enemy_passives_pressed")):
			btn_passives.connect("pressed", Callable(self, "_on_enemy_passives_pressed"))
	
	# Подключаем кнопку лога боя
	if has_node("Actions/Btn_BattleLog"):
		var btn_log = $Actions/Btn_BattleLog
		if not btn_log.is_connected("pressed", Callable(self, "_on_battle_log_pressed")):
			btn_log.connect("pressed", Callable(self, "_on_battle_log_pressed"))
	
	# Подключаем кнопку пассивных способностей игрока
	if has_node("Actions/Btn_Passives"):
		var btn_passives_player = $Actions/Btn_Passives
		if not btn_passives_player.is_connected("pressed", Callable(self, "_on_player_passives_pressed")):
			btn_passives_player.connect("pressed", Callable(self, "_on_player_passives_pressed"))
	
	# Создаем кнопки для активных способностей
	_create_ability_buttons()
	
	# Добавляем кнопку "Меню" в верхний левый угол если её нет
	if not has_node("Btn_Menu"):
		var btn_menu = Button.new()
		btn_menu.name = "Btn_Menu"
		btn_menu.text = "Меню"
		# Позиционируем в верхнем левом углу
		btn_menu.anchors_preset = Control.PRESET_TOP_LEFT
		btn_menu.offset_left = 20.0
		btn_menu.offset_top = 20.0
		btn_menu.offset_right = 120.0
		btn_menu.offset_bottom = 50.0
		add_child(btn_menu)
		btn_menu.connect("pressed", Callable(self, "_on_menu_pressed"))
	
	# Добавляем кнопку "Справка" рядом с "Меню" если её нет
	if not has_node("Btn_Help"):
		var btn_help = Button.new()
		btn_help.name = "Btn_Help"
		btn_help.text = "❓ Справка"
		# Позиционируем справа от кнопки "Меню"
		btn_help.anchors_preset = Control.PRESET_TOP_LEFT
		btn_help.offset_left = 130.0  # Справа от кнопки Меню
		btn_help.offset_top = 20.0
		btn_help.offset_right = 250.0
		btn_help.offset_bottom = 50.0
		add_child(btn_help)
		btn_help.connect("pressed", Callable(self, "_on_help_pressed"))
	
	# подписываемся на сигналы игрока для авто-обновления HUD
	if is_instance_valid(player):
		if not player.is_connected("attacked", Callable(self, "_on_entity_changed")):
			player.connect("attacked", Callable(self, "_on_entity_changed"))
		if not player.is_connected("died", Callable(self, "_on_entity_changed")):
			player.connect("died", Callable(self, "_on_entity_changed"))
	
	# Подписываемся на сигналы осколков душ
	var soul_shard_manager = get_node_or_null("/root/SoulShard")
	if soul_shard_manager:
		if not soul_shard_manager.is_connected("soul_shards_changed", Callable(self, "_on_soul_shards_changed")):
			soul_shard_manager.connect("soul_shards_changed", Callable(self, "_on_soul_shards_changed"))
		if not soul_shard_manager.is_connected("run_soul_shards_changed", Callable(self, "_on_run_soul_shards_changed")):
			soul_shard_manager.connect("run_soul_shards_changed", Callable(self, "_on_run_soul_shards_changed"))
	
	# Подписываемся на сигналы восстановления души
	var soul_restoration_manager = get_node_or_null("/root/SoulRestorationManager")
	if soul_restoration_manager:
		if not soul_restoration_manager.is_connected("charges_changed", Callable(self, "_on_soul_restoration_charges_changed")):
			soul_restoration_manager.connect("charges_changed", Callable(self, "_on_soul_restoration_charges_changed"))

func _process(_delta: float) -> void:
	# Проверяем, открыто ли главное меню
	var main_menu = get_node_or_null("MainMenu")
	if main_menu and main_menu.visible:
		# Меню открыто - скрываем UI элементы боя
		_hide_battle_ui()
	else:
		# Меню закрыто - показываем UI элементы боя
		_show_battle_ui()
		# Обновляем позицию иконок статусных эффектов (позиция обновляется каждый кадр, сами иконки - только при изменении эффектов)
		_update_player_status_icons_position()
		# Проверяем изменение барьера и принудительно обновляем иконки, если барьер изменился
		if is_instance_valid(player) and player.has_method("get_magic_barrier"):
			var current_barrier = player.get_magic_barrier()
			if current_barrier != last_player_barrier_value:
				last_player_barrier_value = current_barrier
				# Принудительно обновляем иконки статусов при изменении барьера
				_update_player_status_icons(player)
		
		# Обновляем позиции иконок статусов для врагов и проверяем изменения барьера
		for i in range(enemies.size()):
			var current_enemy = enemies[i]
			if is_instance_valid(current_enemy):
				_update_enemy_status_icons_position(current_enemy, i)
				# Проверяем изменение барьера у врага
				if current_enemy.has_method("get_magic_barrier"):
					var enemy_key = str(i)
					var last_data = last_enemy_effects.get(enemy_key, {})
					var last_barrier = last_data.get("barrier", -1)
					var current_barrier = current_enemy.get_magic_barrier()
					if current_barrier != last_barrier:
						# Принудительно обновляем иконки статусов при изменении барьера
						_update_enemy_status_icons(current_enemy, i)
		
		# Обновляем защитные характеристики каждый кадр для динамического отображения
		_update_defensive_stats_display()
		# Обновляем HP бар над врагом
		_update_enemy_overhead_ui()
	
	_update_ui()
	
	# Принудительно обновляем индикатор осколков за забег
	await get_tree().process_frame
	_update_run_soul_shards_display()

func set_enemy(enemy_node: Node2D) -> void:
	"""Устанавливает одного врага (обратная совместимость)"""
	enemy = enemy_node
	# подписываемся на сигналы врага
	if is_instance_valid(enemy):
		if not enemy.is_connected("attacked", Callable(self, "_on_entity_changed")):
			enemy.connect("attacked", Callable(self, "_on_entity_changed"))

func set_enemies(enemy_nodes: Array[Node2D]) -> void:
	"""Устанавливает массив врагов (новая система)"""
	enemies = enemy_nodes
	selected_enemy_index = 0
	# Подписываемся на сигналы всех врагов
	for enemy_node in enemies:
		if is_instance_valid(enemy_node):
			if not enemy_node.is_connected("attacked", Callable(self, "_on_entity_changed")):
				enemy_node.connect("attacked", Callable(self, "_on_entity_changed"))
		if not enemy.is_connected("died", Callable(self, "_on_entity_changed")):
			enemy.connect("died", Callable(self, "_on_entity_changed"))
	_update_ui()
	_update_effects_ui()


func _on_attack_pressed() -> void:
	if root_scene.has_method("player_attack"):
		root_scene.call("player_attack")
	else:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(player.attack_power)
		else:
			push_warning("Нет метода для нанесения урона у enemy.")
	_update_ui()

func _on_defend_pressed() -> void:
	if root_scene.has_method("player_defend"):
		root_scene.call("player_defend")
	else:
		push_warning("Нет метода player_defend в battle_manager.")
	_update_ui()


func _on_entity_changed(_a := 0) -> void:
	_update_ui()

func _update_ui() -> void:
	if not is_instance_valid(player):
		return

	# Скрываем имя игрока (больше не нужно)
	if has_node("PlayerHUD/PlayerName"):
		$PlayerHUD/PlayerName.visible = false
	
	# Индикатор очков действий (над полоской здоровья)
	_update_action_points_display()
	
	# Обновляем позицию иконок статусных эффектов над игроком
	_update_player_status_icons_position()
	
	# ОЗ (красный)
	if has_node("HealthBars/PlayerHP"):
		var settings_manager = get_node_or_null("/root/SettingsManager")
		var hp_bar = $HealthBars/PlayerHP
		
		if settings_manager and settings_manager.get_health_display_mode():
			# Отображение в процентах
			hp_bar.max_value = 100
			hp_bar.value = int((float(player.hp) / float(player.max_hp)) * 100)
			if hp_bar.has_method("set_display_mode"):
				hp_bar.set_display_mode("percentage")
		else:
			# Отображение в абсолютных значениях
			hp_bar.max_value = player.max_hp
			hp_bar.value = player.hp
			if hp_bar.has_method("set_display_mode"):
				hp_bar.set_display_mode("absolute")
		
		# Устанавливаем красный цвет для ОЗ
		hp_bar.modulate = Color(1.0, 0.3, 0.3, 1.0)  # Красный
		
		# Обновляем барьер игрока
		_update_player_barrier_display(hp_bar)
	
	# ОМ (голубой)
	if has_node("HealthBars/PlayerMP"):
		var settings_manager = get_node_or_null("/root/SettingsManager")
		var mp_bar = $HealthBars/PlayerMP
		
		if settings_manager and settings_manager.get_mana_display_mode():
			# Отображение в процентах
			mp_bar.max_value = 100
			mp_bar.value = int((float(player.mp) / float(player.max_mp)) * 100)
			if mp_bar.has_method("set_display_mode"):
				mp_bar.set_display_mode("percentage")
		else:
			# Отображение в абсолютных значениях
			mp_bar.max_value = player.max_mp
			mp_bar.value = player.mp
			if mp_bar.has_method("set_display_mode"):
				mp_bar.set_display_mode("absolute")
		
		# Устанавливаем голубой цвет для ОМ
		mp_bar.modulate = Color(0.3, 0.7, 1.0, 1.0)  # Голубой
	
	# Магический барьер (фиолетовый)
	if has_node("HealthBars/PlayerBarrier"):
		var barrier_bar = $HealthBars/PlayerBarrier
		barrier_bar.max_value = player.max_magic_barrier if player.max_magic_barrier > 0 else 1
		barrier_bar.value = player.magic_barrier
		# Устанавливаем фиолетовый цвет для барьера
		barrier_bar.modulate = Color(0.7, 0.3, 1.0, 1.0)  # Фиолетовый
		# Показываем/скрываем барьер в зависимости от наличия
		barrier_bar.visible = player.has_magic_barrier()
	
	# ОВ (светло-зеленый)
	if has_node("HealthBars/PlayerStamina"):
		var settings_manager = get_node_or_null("/root/SettingsManager")
		var stamina_bar = $HealthBars/PlayerStamina
		
		if settings_manager and settings_manager.get_stamina_display_mode():
			# Отображение в процентах
			stamina_bar.max_value = 100
			stamina_bar.value = int((float(player.stamina) / float(player.max_stamina)) * 100)
			if stamina_bar.has_method("set_display_mode"):
				stamina_bar.set_display_mode("percentage")
		else:
			# Отображение в абсолютных значениях
			stamina_bar.max_value = player.max_stamina
			stamina_bar.value = player.stamina
			if stamina_bar.has_method("set_display_mode"):
				stamina_bar.set_display_mode("absolute")
		
		# Устанавливаем светло-зеленый цвет для ОВ
		stamina_bar.modulate = Color(0.5, 1.0, 0.5, 1.0)  # Светло-зеленый
	
	# Магическое сопротивление и Броня
	_update_defensive_stats_display()
	
	# Осколки душ
	_update_soul_shards_display()
	_update_run_soul_shards_display()
	
	# Обновляем кнопки способностей
	_update_ability_buttons()
	
	# Обновляем барьеры врагов
	_update_enemies_barrier_display()

func _get_barrier_alpha(barrier_value: int) -> float:
	"""Вычисляет прозрачность барьера на основе его значения
	1-100: 90% прозрачность (alpha = 0.1)
	100-200: 80% прозрачность (alpha = 0.2)
	200-300: 70% прозрачность (alpha = 0.3)
	...
	1000+: непрозрачный (alpha = 1.0)
	"""
	if barrier_value <= 0:
		return 0.0
	if barrier_value >= 1000:
		return 1.0
	# Формула: alpha = 0.1 + floor((barrier_value - 1) / 100) * 0.1
	var alpha = 0.1 + floor((barrier_value - 1) / 100.0) * 0.1
	return min(1.0, alpha)

func _update_player_barrier_display(hp_bar: ProgressBar):
	"""Обновляет отображение барьера игрока поверх HP бара"""
	var barrier_value = player.get_magic_barrier() if player.has_method("get_magic_barrier") else 0
	
	# Получаем родительский контейнер HP бара (HealthBars)
	var health_bars_container = hp_bar.get_parent()
	if not health_bars_container:
		return
	
	# Получаем или создаем барьер-бар
	var barrier_bar = health_bars_container.get_node_or_null("PlayerBarrierOverlay")
	var barrier_label = health_bars_container.get_node_or_null("PlayerBarrierLabel")
	if not barrier_bar:
		# Создаем обычный ProgressBar для барьера (без текста)
		barrier_bar = ProgressBar.new()
		barrier_bar.name = "PlayerBarrierOverlay"
		barrier_bar.show_percentage = false  # Отключаем встроенное отображение процентов
		# Копируем размеры и позицию HP бара
		barrier_bar.size = hp_bar.size
		barrier_bar.position = hp_bar.position
		barrier_bar.anchors_preset = hp_bar.anchors_preset
		barrier_bar.anchor_left = hp_bar.anchor_left
		barrier_bar.anchor_top = hp_bar.anchor_top
		barrier_bar.anchor_right = hp_bar.anchor_right
		barrier_bar.anchor_bottom = hp_bar.anchor_bottom
		barrier_bar.offset_left = hp_bar.offset_left
		barrier_bar.offset_top = hp_bar.offset_top
		barrier_bar.offset_right = hp_bar.offset_right
		barrier_bar.offset_bottom = hp_bar.offset_bottom
		barrier_bar.z_index = hp_bar.z_index + 1  # Поверх HP бара
		barrier_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		health_bars_container.add_child(barrier_bar)
		
		# Создаем Label для отображения значения барьера
		barrier_label = Label.new()
		barrier_label.name = "PlayerBarrierLabel"
		barrier_label.size = hp_bar.size
		barrier_label.position = hp_bar.position
		barrier_label.anchors_preset = hp_bar.anchors_preset
		barrier_label.anchor_left = hp_bar.anchor_left
		barrier_label.anchor_top = hp_bar.anchor_top
		barrier_label.anchor_right = hp_bar.anchor_right
		barrier_label.anchor_bottom = hp_bar.anchor_bottom
		barrier_label.offset_left = hp_bar.offset_left
		barrier_label.offset_top = hp_bar.offset_top
		barrier_label.offset_right = hp_bar.offset_right
		barrier_label.offset_bottom = hp_bar.offset_bottom
		barrier_label.z_index = barrier_bar.z_index + 1  # Поверх барьер-бара
		barrier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		barrier_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		barrier_label.add_theme_font_size_override("font_size", 12)
		barrier_label.add_theme_color_override("font_color", Color.WHITE)
		barrier_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		barrier_label.add_theme_constant_override("shadow_offset_x", 1)
		barrier_label.add_theme_constant_override("shadow_offset_y", 1)
		barrier_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		health_bars_container.add_child(barrier_label)
	
	# Обновляем барьер-бар (всегда в абсолютных значениях)
	if barrier_value > 0:
		barrier_bar.visible = true
		if barrier_label:
			barrier_label.visible = true
		# Барьер всегда отображается в абсолютных значениях
		barrier_bar.max_value = player.max_hp
		barrier_bar.value = barrier_value
		# Обновляем текст Label - показываем только значение барьера
		if barrier_label:
			barrier_label.text = str(int(barrier_value))
		var alpha = _get_barrier_alpha(barrier_value)
		barrier_bar.modulate = Color(1.0, 1.0, 1.0, alpha)  # Белый с прозрачностью
	else:
		barrier_bar.visible = false
		if barrier_label:
			barrier_label.visible = false

func _update_enemies_barrier_display():
	"""Обновляет отображение барьеров для всех врагов"""
	for i in range(enemies.size()):
		var current_enemy = enemies[i]
		if not is_instance_valid(current_enemy):
			continue
		
		var container_name = "EnemyOverheadUI_" + str(i)
		var overhead_container = get_node_or_null(container_name)
		if not overhead_container:
			continue
		
		# Ищем HP контейнер
		var vbox = overhead_container.get_child(0) if overhead_container.get_child_count() > 0 else null
		if not vbox:
			continue
		
		# Ищем HP контейнер (обычно это второй или третий элемент после имени)
		var hp_container = null
		for child in vbox.get_children():
			if child is Control and child.get_child_count() > 0:
				var first_child = child.get_child(0)
				if first_child is ProgressBar and first_child.modulate == Color(1.0, 0.3, 0.3, 1.0):  # Красный HP бар
					hp_container = child
					break
		
		if not hp_container:
			continue
		
		# Получаем барьер-бар (он должен быть создан при создании UI)
		var barrier_bar = hp_container.get_node_or_null("BarrierBar")
		if not barrier_bar:
			continue
		
		# Обновляем барьер-бар
		var barrier_value = current_enemy.get_magic_barrier() if current_enemy.has_method("get_magic_barrier") else 0
		if barrier_value > 0:
			barrier_bar.visible = true
			barrier_bar.max_value = current_enemy.max_hp
			barrier_bar.value = barrier_value
			var alpha = _get_barrier_alpha(barrier_value)
			barrier_bar.modulate = Color(1.0, 1.0, 1.0, alpha)  # Белый с прозрачностью
		else:
			barrier_bar.visible = false

func _update_action_points_display():
	"""Обновляет отображение очков действий игрока над полоской здоровья"""
	if not is_instance_valid(player):
		return
	
	# Получаем или создаем индикатор ОД
	var ap_label = get_node_or_null("HealthBars/PlayerActionPoints")
	if not ap_label:
		# Создаем новый Label для ОД
		ap_label = Label.new()
		ap_label.name = "PlayerActionPoints"
		var health_bars = get_node_or_null("HealthBars")
		if health_bars:
			health_bars.add_child(ap_label)
		else:
			return
	
	# Получаем позицию полоски здоровья для позиционирования
	var player_hp_bar = get_node_or_null("HealthBars/PlayerHP")
	if player_hp_bar:
		# Позиционируем над полоской HP (на 25 пикселей выше)
		ap_label.position = player_hp_bar.position + Vector2(0, -25)
	else:
		# Fallback позиция
		ap_label.position = Vector2(20, -205)
	
	# Получаем текущее количество очков действий
	# action_points и max_action_points определены в body.gd
	var action_points = player.action_points
	var max_action_points = player.max_action_points
	
	# Форматируем текст: "ОД: X / Y" или просто "ОД: X" если максимум = 1
	if max_action_points > 1:
		ap_label.text = "ОД: " + str(action_points) + " / " + str(max_action_points)
	else:
		ap_label.text = "ОД: " + str(action_points)
	
	# Настраиваем стиль текста
	ap_label.add_theme_font_size_override("font_size", 16)
	ap_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))  # Желто-золотой цвет
	ap_label.add_theme_color_override("font_outline_color", Color.BLACK)
	ap_label.add_theme_constant_override("outline_size", 2)
	ap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ap_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Устанавливаем размер
	ap_label.custom_minimum_size = Vector2(260, 20)
	ap_label.size = Vector2(260, 20)
	
	# Делаем видимым
	ap_label.visible = true
	ap_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Enemy HUD (правый нижний угол)
	if is_instance_valid(enemy):
		# Отображаем редкость врага
		if has_node("EnemyHUD/EnemyRarity"):
			var rarity_text = _get_rarity_display_text(enemy.rarity)
			$EnemyHUD/EnemyRarity.text = rarity_text
			$EnemyHUD/EnemyRarity.modulate = _get_rarity_color(enemy.rarity)
		
		# Скрываем старый HUD врага (имя и редкость в углу)
		if has_node("EnemyHUD/EnemyName"):
			$EnemyHUD/EnemyName.visible = false
		if has_node("EnemyHUD/EnemyRarity"):
			$EnemyHUD/EnemyRarity.visible = false
		
		# Скрываем старые HP, MP и Stamina бары в углу
		if has_node("HealthBars/EnemyHP"):
			$HealthBars/EnemyHP.visible = false
		if has_node("HealthBars/EnemyMP"):
			$HealthBars/EnemyMP.visible = false
		if has_node("HealthBars/EnemyStamina"):
			$HealthBars/EnemyStamina.visible = false
		
		# Скрываем отображение активного умения врага
		if has_node("EnemyHUD/EnemyAbilities"):
			$EnemyHUD/EnemyAbilities.visible = false
	else:
		# Скрываем или очищаем HUD врага, если врага нет
		if has_node("EnemyHUD/EnemyRarity"):
			$EnemyHUD/EnemyRarity.text = ""
		if has_node("EnemyHUD/EnemyName"):
			$EnemyHUD/EnemyName.text = "Нет врага"
		if has_node("EnemyHUD/EnemyAbilities"):
			$EnemyHUD/EnemyAbilities.visible = false
		if has_node("EnemyHUD/EnemyHP"):
			$EnemyHUD/EnemyHP.max_value = 1
			$EnemyHUD/EnemyHP.value = 0
		if has_node("EnemyHUD/EnemyMP"):
			$EnemyHUD/EnemyMP.max_value = 1
			$EnemyHUD/EnemyMP.value = 0
		if has_node("EnemyHUD/EnemyStamina"):
			$EnemyHUD/EnemyStamina.max_value = 1
			$EnemyHUD/EnemyStamina.value = 0

	if is_instance_valid(enemy) and ((enemy.has_method("is_dead") and enemy.is_dead()) or enemy.hp <= 0):
		_show_message("Враг повержен!")
	
	# Обновляем эффекты
	_update_effects_ui()

func _on_menu_pressed() -> void:
	print("Открываем главное меню поверх боевой сцены...")
	# Загружаем главное меню как дочернюю сцену
	var main_menu_scene = preload("res://Scenes/MainMenu.tscn")
	var main_menu_instance = main_menu_scene.instantiate()
	main_menu_instance.name = "MainMenu"  # Устанавливаем имя для поиска
	
	# Показываем кнопку "Вернуться в бой" в главном меню
	var return_btn = main_menu_instance.get_node_or_null("Btn_ReturnToBattle")
	if return_btn:
		return_btn.visible = true
		print("Кнопка 'Вернуться в бой' показана")
	else:
		print("Кнопка 'Вернуться в бой' не найдена!")
	
	# Добавляем главное меню поверх боевой сцены
	add_child(main_menu_instance)


func _on_help_pressed() -> void:
	"""Показывает окно справки с полезной информацией для игрока"""
	print("Открываем справку...")
	
	# Создаем Window для справки
	var help_window = Window.new()
	help_window.title = "Справка по бою"
	help_window.size = Vector2i(700, 500)
	help_window.popup_window = true
	help_window.transient = true
	help_window.exclusive = false
	help_window.unresizable = false
	
	# Подключаем сигнал закрытия окна
	help_window.close_requested.connect(func():
		if SoundManager:
			SoundManager.play_sound("page", -5.0)
		help_window.queue_free()
	)
	
	# Создаем главный контейнер
	var main_container = VBoxContainer.new()
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_container.offset_left = 20
	main_container.offset_right = -20
	main_container.offset_top = 20
	main_container.offset_bottom = -20
	main_container.add_theme_constant_override("separation", 15)
	
	# Заголовок
	var title = RichTextLabel.new()
	title.bbcode_enabled = true
	title.fit_content = true
	title.scroll_active = false
	title.custom_minimum_size = Vector2(0, 50)
	title.text = "[center][color=#FFD700][b]📖 СПРАВКА ПО БОЕВОЙ СИСТЕМЕ[/b][/color][/center]"
	title.add_theme_font_size_override("bold_font_size", 24)
	main_container.add_child(title)
	
	# Создаем ScrollContainer для текста
	var scroll_container = ScrollContainer.new()
	scroll_container.custom_minimum_size = Vector2(0, 300)
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Текст справки
	var help_text = RichTextLabel.new()
	help_text.bbcode_enabled = true
	help_text.fit_content = true
	help_text.scroll_active = false
	help_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var help_content = """[color=#AADDFF][b]🎯 Изучение способностей врага:[/b][/color]
Для изучения способностей врага нажмите кнопку [color=#FFD700]"Умения врага"[/color]. 
Побеждая врагов, вы получаете прогресс изучения их пассивных способностей. После накопления достаточного прогресса способности можно изучить у Архитектора душ.

[color=#44FF88][b]❤️ Лечение в бою:[/b][/color]
Для лечения используйте способность [color=#FFD700]"Духовное восстановление"[/color]. 
Эта способность восстанавливает 35% от максимального здоровья, маны и выносливости.
• Заряды можно восстанавливать в [color=#88DDFF]комнатах отдыха[/color]
• Количество зарядов можно увеличить у [color=#88DDFF]Архитектора душ[/color] после выполнения первого квеста (Урна душ)

[color=#6699FF][b]🛡️ Защита:[/b][/color]
Защита уменьшает получаемый урон в раунде на [color=#FFD700]50%[/color], но забирает [color=#FF6666]одно очко действий[/color].
Используйте защиту перед сильными атаками врага или когда у вас мало здоровья.

[color=#FF8844][b]💀 Последствия поражения:[/b][/color]
Поражение имеет последствия:
• Вы теряете [color=#FF6666]половину осколков душ[/color] за текущий забег
• Прогресс локации [color=#FF6666]сбрасывается[/color] к началу
• Иногда лучше вернуться в Колодец душ с тем, что есть, чем рисковать всем в следующем бою

[color=#AA88FF][b]🎮 Управление:[/b][/color]
• Для смены цели атаки используйте клавиши [color=#FFD700]1, 2, 3[/color]
• Каждая цифра соответствует врагу слева направо
• Выбранная цель подсвечивается рамкой

[color=#FFAA44][b]💡 Полезные советы:[/b][/color]
• Изучайте пассивные способности врагов для получения преимущества
• Следите за очками действий (максимум 2 в раунд)
• Используйте комнаты отдыха для восстановления ресурсов
• Не забывайте про защиту в критических ситуациях
• Изучайте активные способности врагов, чтобы знать, чего ожидать"""
	
	help_text.text = help_content
	help_text.add_theme_font_size_override("normal_font_size", 15)
	help_text.add_theme_font_size_override("bold_font_size", 16)
	
	scroll_container.add_child(help_text)
	main_container.add_child(scroll_container)
	
	# Кнопка закрытия
	var close_button = Button.new()
	close_button.text = "Понятно"
	close_button.custom_minimum_size = Vector2(0, 45)
	close_button.add_theme_font_size_override("font_size", 16)
	
	# Стилизуем кнопку
	var button_normal = StyleBoxFlat.new()
	button_normal.bg_color = Color(0.2, 0.5, 0.8, 1.0)
	button_normal.corner_radius_top_left = 8
	button_normal.corner_radius_top_right = 8
	button_normal.corner_radius_bottom_left = 8
	button_normal.corner_radius_bottom_right = 8
	close_button.add_theme_stylebox_override("normal", button_normal)
	
	var button_hover = StyleBoxFlat.new()
	button_hover.bg_color = Color(0.3, 0.6, 1.0, 1.0)
	button_hover.corner_radius_top_left = 8
	button_hover.corner_radius_top_right = 8
	button_hover.corner_radius_bottom_left = 8
	button_hover.corner_radius_bottom_right = 8
	close_button.add_theme_stylebox_override("hover", button_hover)
	
	close_button.pressed.connect(func():
		if SoundManager:
			SoundManager.play_sound("page", -5.0)
		help_window.queue_free()
	)
	
	main_container.add_child(close_button)
	
	# Добавляем в окно
	help_window.add_child(main_container)
	add_child(help_window)
	
	# Центрируем окно
	await get_tree().process_frame
	var screen_size = DisplayServer.screen_get_size()
	var window_size = help_window.size
	help_window.position = Vector2i(
		(screen_size.x - window_size.x) / 2,
		(screen_size.y - window_size.y) / 2
	)
	
	help_window.show()

func _on_enemy_passives_pressed() -> void:
	_show_enemy_abilities()

func _show_enemy_abilities() -> void:
	"""Показывает окно с активными и пассивными способностями всех врагов"""
	if enemies.size() == 0:
		_show_message("Нет врагов для просмотра способностей")
		return
	
	# Если один враг - показываем простое окно
	if enemies.size() == 1:
		var current_enemy = enemies[0]
		if not is_instance_valid(current_enemy):
			_show_message("Нет врага для просмотра способностей")
			return
		_show_single_enemy_abilities(current_enemy)
	else:
		# Если несколько врагов - показываем окно с вкладками
		_show_multiple_enemies_abilities()

func _show_single_enemy_abilities(current_enemy: Node2D) -> void:
	"""Показывает способности одного врага"""
	var abilities_text = _get_enemy_abilities_text(current_enemy)
	
	# Создаем Window вместо AcceptDialog для поддержки RichTextLabel
	var dialog = Window.new()
	dialog.title = "Умения врага: " + current_enemy.display_name
	dialog.size = Vector2i(600, 500)
	dialog.unresizable = false
	dialog.transient = true
	dialog.exclusive = true
	
	# Создаем главный контейнер
	var main_container = VBoxContainer.new()
	main_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialog.add_child(main_container)
	
	# Создаем ScrollContainer
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(580, 420)
	main_container.add_child(scroll)
	
	# Создаем RichTextLabel с поддержкой BBCode
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.text = abilities_text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.fit_content = true
	scroll.add_child(label)
	
	# Добавляем кнопку закрытия
	var close_btn = Button.new()
	close_btn.text = "Закрыть"
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func(): dialog.queue_free())
	main_container.add_child(close_btn)
	
	# Показываем окно
	add_child(dialog)
	dialog.popup_centered()
	dialog.close_requested.connect(func(): dialog.queue_free())

func _show_multiple_enemies_abilities() -> void:
	"""Показывает способности нескольких врагов с вкладками"""
	# Создаем диалоговое окно
	var dialog = Window.new()
	dialog.title = "Умения врагов"
	dialog.size = Vector2i(600, 500)
	dialog.unresizable = false
	dialog.transient = true
	dialog.exclusive = true
	
	# Создаем главный контейнер
	var main_container = VBoxContainer.new()
	main_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialog.add_child(main_container)
	
	# Создаем TabContainer для вкладок врагов
	var tab_container = TabContainer.new()
	tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_container.custom_minimum_size = Vector2(580, 400)
	main_container.add_child(tab_container)
	
	# Добавляем вкладку для каждого врага
	for i in range(enemies.size()):
		var current_enemy = enemies[i]
		if not is_instance_valid(current_enemy):
			continue
		
		# Создаем ScrollContainer для вкладки
		var scroll = ScrollContainer.new()
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		# Создаем RichTextLabel для текста способностей
		var label = RichTextLabel.new()
		label.bbcode_enabled = true
		label.text = _get_enemy_abilities_text(current_enemy)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		label.fit_content = true
		
		scroll.add_child(label)
		tab_container.add_child(scroll)
		
		# ВАЖНО: Устанавливаем заголовок вкладки ПОСЛЕ добавления в TabContainer
		var tab_index = tab_container.get_tab_count() - 1
		tab_container.set_tab_title(tab_index, current_enemy.display_name)
	
	# Добавляем кнопку закрытия
	var close_btn = Button.new()
	close_btn.text = "Закрыть"
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func(): dialog.queue_free())
	main_container.add_child(close_btn)
	
	# Показываем окно
	add_child(dialog)
	dialog.popup_centered()
	dialog.close_requested.connect(func(): dialog.queue_free())

func _get_enemy_abilities_text(current_enemy: Node2D) -> String:
	"""Возвращает текст с активными и пассивными способностями врага"""
	var text = "[b]" + current_enemy.display_name + " (ур. " + str(current_enemy.level) + ")[/b]\n"
	text += "Редкость: " + _get_rarity_text(current_enemy.rarity) + "\n\n"
	
	# === АКТИВНАЯ СПОСОБНОСТЬ ===
	text += "[color=yellow][b]АКТИВНАЯ СПОСОБНОСТЬ:[/b][/color]\n\n"
	
	# Получаем активную способность из battle_manager
	var battle_manager = root_scene
	if battle_manager and battle_manager.has_method("get_enemy_ability_info"):
		var ability_info = battle_manager.get_enemy_ability_info(current_enemy.display_name)
		if ability_info:
			text += "• [b]" + ability_info.name + "[/b]\n"
			text += "  " + ability_info.description + "\n"
			text += "  Урон: " + str(ability_info.damage) + " | "
			text += "Кулдаун: " + str(ability_info.cooldown) + " ход.\n"
			if ability_info.has("cost_type"):
				text += "  Стоимость: " + str(ability_info.cost) + " " + ability_info.cost_type + "\n"
		else:
			text += "  Базовая атака\n"
	else:
		text += "  Информация недоступна\n"
	
	text += "\n"
	
	# === ПАССИВНЫЕ СПОСОБНОСТИ ===
	text += "[color=cyan][b]ПАССИВНЫЕ СПОСОБНОСТИ:[/b][/color]\n\n"
	
	# Проверяем, есть ли у врага массив пассивных способностей
	if not "passive_abilities" in current_enemy:
		text += "  [color=red]Ошибка: у врага нет поля passive_abilities[/color]\n"
		print("DEBUG: Враг ", current_enemy.display_name, " не имеет поля passive_abilities")
	else:
		var passives = current_enemy.passive_abilities
		if passives == null:
			text += "  [color=red]Ошибка: passive_abilities = null[/color]\n"
			print("DEBUG: passive_abilities = null для ", current_enemy.display_name)
		elif not passives is Array:
			text += "  [color=red]Ошибка: passive_abilities не массив[/color]\n"
			print("DEBUG: passive_abilities не массив для ", current_enemy.display_name, ", тип: ", typeof(passives))
		elif passives.size() == 0:
			text += "  Нет пассивных способностей\n"
			print("DEBUG: У врага ", current_enemy.display_name, " пустой массив passive_abilities")
		else:
			print("DEBUG: У врага ", current_enemy.display_name, " найдено ", passives.size(), " пассивных способностей")
			for ability in passives:
				if not is_instance_valid(ability):
					text += "  [color=red]• Невалидная способность[/color]\n"
					continue
				
				var ability_level = 1
				if "ability_levels" in current_enemy:
					ability_level = current_enemy.ability_levels.get(ability.id, 1)
				
				var detailed_description = _get_detailed_ability_description(ability, ability_level)
				
				text += "• [b]" + ability.name + "[/b] (ур. " + str(ability_level) + ")\n"
				text += "  " + detailed_description + "\n\n"
	
	return text

func _get_rarity_text(rarity: String) -> String:
	"""Возвращает текст редкости с цветом"""
	# Проверяем, является ли редкость элитной
	if rarity.begins_with("elite_"):
		var base_rarity = rarity.replace("elite_", "")  # Убираем "elite_"
		var base_rarity_text = ""
		var base_rarity_color = ""
		
		# Определяем текст и цвет базовой редкости
		match base_rarity:
			"rare":
				base_rarity_text = "Редкий"
				base_rarity_color = "blue"
			"epic":
				base_rarity_text = "Эпический"
				base_rarity_color = "purple"
			"legendary":
				base_rarity_text = "Легендарный"
				base_rarity_color = "orange"
			_:
				base_rarity_text = base_rarity.capitalize()
				base_rarity_color = "white"
		
		# Возвращаем форматированный текст: "Элитный" золотым + базовая редкость своим цветом
		return "[color=gold]Элитный[/color] [color=" + base_rarity_color + "]" + base_rarity_text + "[/color]"
	
	# Обычные редкости
	match rarity:
		"common":
			return "[color=gray]Обычный[/color]"
		"uncommon":
			return "[color=green]Необычный[/color]"
		"rare":
			return "[color=blue]Редкий[/color]"
		"epic":
			return "[color=purple]Эпический[/color]"
		"legendary":
			return "[color=orange]Легендарный[/color]"
		"mythic":
			return "[color=red]Мифический[/color]"
		"boss":
			return "[color=red]БОСС[/color]"
		_:
			return rarity

func _show_enemy_passives() -> void:
	"""УСТАРЕВШАЯ ФУНКЦИЯ - используйте _show_enemy_abilities()"""
	_show_enemy_abilities()

func _get_detailed_ability_description(ability: PassiveAbility, level: int) -> String:
	"""Возвращает детальное описание способности с реальными значениями для указанного уровня"""
	if not ability or level < 1:
		return ability.description if ability else "Неизвестная способность"
	
	# Получаем значение для указанного уровня
	var current_value = ability.get_value_for_level(level)
	
	# Если значение равно 0 и у способности нет level_values, пытаемся получить из AbilityLearningSystem
	if current_value == 0.0 and (ability.level_values.size() == 0 or ability.level_values[0] == 0.0):
		if AbilityLearningSystem and AbilityLearningSystem.ability_learning_config.has(ability.id):
			var config = AbilityLearningSystem.ability_learning_config[ability.id]
			if config.has("level_values") and config.level_values.size() > 0:
				var level_index = min(level - 1, config.level_values.size() - 1)
				if level_index >= 0:
					current_value = config.level_values[level_index]
	
	var description = ability.description
	
	# Заменяем плейсхолдеры на реальные значения
	description = description.replace("X", str(int(current_value)))
	description = description.replace("Y", str(int(current_value * 1.5)))  # Для вторичных значений
	
	# Специальная обработка для некоторых способностей
	match ability.id:
		"dodge":
			description = str(int(current_value)) + "% шанс увернуться от атаки"
		"speed":
			description = str(int(current_value)) + "% шанс дополнительного действия"
		"blood_flow":
			description = str(int(current_value)) + "% шанс вызвать кровотечение от физического урона"
		"agility":
			description = str(int(current_value)) + "% шанс контратаки при уклонении"
		"cornered":
			var hp_threshold = [20, 25, 30][level - 1]
			description = "+" + str(int(current_value)) + "% урон при HP < " + str(hp_threshold) + "%"
		"restlessness":
			var damage_reduction = [40, 35, 30][level - 1]
			description = str(int(current_value)) + "% шанс двойной атаки (-" + str(damage_reduction) + "% урон)"
		"infection":
			var duration = [3, 4, 5][level - 1]
			description = str(int(current_value)) + "% шанс заразить врага болезнью 10 урона в раунд за стак. Максимум 5 стаков (" + str(duration) + " раундов)"
		"sharp_claws":
			description = str(int(current_value)) + "% шанс нанести рану. Максимум 3 стака. (Снижение эффективности лечения на 20% за стак)"
		"blood_sucker":
			description = str(int(current_value)) + "% шанс вампиризма при атаке"
		"echolocation":
			description = "Игнорирует " + str(int(current_value)) + "% уворота противника"
		"silent_song":
			description = str(int(current_value)) + "% шанс снизить вероятность срабатывания магического урона"
		"alkara_vampirism":
			description = str(int(current_value)) + "% магического урона в HP"
		"curse":
			description = str(int(current_value)) + "% шанс проклясть врага при уроне. Проклятие снижает физическую и магическую защиту цели на 30%"
		"alkara_blood_ritual":
			var hp_cost = [10, 15, 20][level - 1]
			description = "-" + str(hp_cost) + " HP в ход, +" + str(int(current_value)) + "% урон"
		"alkara_soul_drain":
			description = "Увеличение получения осколков душ на " + str(int(current_value)) + "%"
		"alkara_demon_lord":
			description = "+" + str(int(current_value)) + "% эффективность демонических способностей"
		"curse_weakness":
			var strength_reduction = [20, 30, 45][level - 1]
			description = "Шанс 15%, -" + str(strength_reduction) + "% силы врага"
		"demon_mage":
			description = "+" + str(int(current_value)) + "% магический урон"
		"demon_vitality":
			description = "+" + str(int(current_value)) + " к живучести"
		"curse_cursed":
			description = "Получает " + str(int(current_value)) + " защиты и " + str(int(current_value)) + "% магической защиты при получении урона. Максимум 10 стаков, длительность бафа 5 раундов"
		"curse_master":
			description = "+" + str(int(current_value)) + "% эффективность проклятий"
		"executioner_rage":
			description = "+" + str(int(current_value)) + " силы за каждые 10% потерянного здоровья"
		"demonic_endurance":
			description = "+" + str(int(current_value)) + " выносливости за раунд"
		"executioner_judgment":
			description = str(int(current_value)) + "% шанс наложить дебаф - Наказание. Наказание - наносит 50 урона и оглушает врага через 2 раунда"
		"executioner_guillotine":
			var crit_bonus = [50, 80, 120][level - 1]
			description = "Критический удар наносит +" + str(crit_bonus) + "% урона"
		"executioner_final":
			var crit_chance = [20, 50, 100][level - 1]
			description = "Вместо смерти ОЗ фиксируется на 1 и наносит контратаку с +" + str(crit_chance) + "% шансом критического урона"
		"tharnok_shield":
			description = "Блокирует " + str(int(current_value)) + "% урона"
		"tharnok_armor":
			description = "+" + str(int(current_value)) + " защиты"
		"tharnok_guardian":
			description = "Отражает " + str(int(current_value)) + "% урона атакующему"
		"tharnok_mastery":
			description = "При получении урона получает стак 'Кровь демона'. Каждый стак дает " + str(int(current_value)) + "% регенерации здоровья на 3 раунда. Максимум 5 стаков"
		"ninja_shadow":
			description = str(int(current_value)) + "% шанс стать невидимым при атаке"
		"quick_strike":
			description = str(int(current_value)) + "% шанс что атака будет считаться ударом в спину. Урон в спину * 1.5"
		"ninja_lethality":
			description = "+" + str(int(current_value)) + "% урон от ударов в спину"
		"ninja_master":
			description = "+" + str(int(current_value)) + "% эффективность ниндзя способностей"
		"slime_armor":
			description = "Снижение получаемого урона на " + str(int(current_value)) + " ед"
		"acid_hits":
			description = "Разрушает " + str(int(current_value)) + " брони за удар"
		"slime_regeneration":
			var hp_percent = [1, 2, 4][level - 1]
			description = str(int(current_value)) + " + " + str(hp_percent) + "% от Максимума HP за раунд"
		"slime_vitality":
			description = "Увеличение здоровья на " + str(int(current_value)) + "%"
		"massive":
			description = "Увеличивает урон физических атак на " + str(int(current_value)) + "% от максимального здоровья"
		"rotten_aura":
			var hp_percent = [0.5, 0.7, 1.0][level - 1]
			description = "Каждый ход накладывает стак гнили на противника. Каждый стак гнили отнимает " + str(hp_percent) + "% хп за раунд. Максимум 5 стаков"
		"thief_agility":
			description = "+" + str(int(current_value)) + " к ловкости"
		"sneaky_strike":
			description = str(int(current_value)) + "% шанс при атаке игнорировать броню цели"
		"neurotoxin":
			description = "17% шанс при атаке наложить нейротоксин. Нейротоксин уменьшает меткость цели на " + str(int(current_value)) + "% за стак. Максимум 3 стака"
		"apprentice":
			description = "+" + str(int(current_value)) + " к запасу маны"
		"magic_resistance":
			description = "+" + str(int(current_value)) + "% сопротивление магии"
		"mana_absorption":
			description = str(int(current_value)) + "% от нанесенного магического или физического урона преобразуется в ману"
		"storm_shaman":
			description = "При нанесении любого магического урона есть шанс " + str(int(current_value)) + "% вызвать удар молнии. Удар молнии наносит магический урон = интеллект + мудрость"
		"magic_barrier":
			var multiplier = [1.5, 2.0, 2.5][level - 1]
			description = "Создает магический барьер, который поглощает урон и блокирует некоторые статусные эффекты. Барьер = Мудрость × " + str(multiplier)
	
	return description

func _show_passives_dialog(text: String) -> void:
	# Создаем диалоговое окно
	var dialog = AcceptDialog.new()
	dialog.title = "Пассивные способности врага"
	dialog.dialog_text = text
	dialog.size = Vector2(400, 300)
	
	# Добавляем к сцене
	add_child(dialog)
	
	# Показываем в центре экрана
	dialog.popup_centered()
	
	# Подключаем сигнал закрытия
	dialog.connect("confirmed", Callable(dialog, "queue_free"))
	dialog.connect("canceled", Callable(dialog, "queue_free"))

func _on_battle_log_pressed() -> void:
	_show_battle_log()

func _on_player_passives_pressed() -> void:
	_show_player_passives()

func _show_battle_log() -> void:
	# Получаем лог боя из battle_manager
	var battle_manager = root_scene
	if not battle_manager or not battle_manager.has_method("get_battle_log"):
		_show_message("Лог боя недоступен")
		return
	
	var battle_log = battle_manager.get_battle_log()
	if not battle_log:
		_show_message("Лог боя не найден")
		return
	
	# Получаем статистику и лог
	var stats = battle_log.get_battle_statistics()
	var log_text = battle_log.get_battle_log_text()
	
	# Создаем текст с статистикой и логом
	var full_text = "=== СТАТИСТИКА БОЯ ===\n\n"
	full_text += "Всего событий: " + str(stats.total_events) + "\n"
	full_text += "Атак: " + str(stats.damage_events) + "\n"
	full_text += "Лечения: " + str(stats.heal_events) + "\n"
	full_text += "Уворотов: " + str(stats.dodge_events) + "\n"
	full_text += "Пассивных способностей: " + str(stats.passive_ability_events) + "\n"
	full_text += "Урона от эффектов: " + str(stats.effect_damage_events) + "\n"
	full_text += "Общий урон: " + str(stats.total_damage_dealt) + "\n"
	full_text += "Общее лечение: " + str(stats.total_healing) + "\n"
	full_text += "Критических ударов: " + str(stats.critical_hits) + "\n"
	full_text += "Успешных пассивок: " + str(stats.successful_passives) + "\n\n"
	full_text += log_text
	
	# Показываем в диалоговом окне
	_show_battle_log_dialog(full_text)

func _show_battle_log_dialog(text: String) -> void:
	# Создаем диалоговое окно с прокруткой
	var dialog = AcceptDialog.new()
	dialog.title = "Лог боя"
	dialog.size = Vector2(600, 500)
	
	# Создаем ScrollContainer для длинного текста
	var scroll = ScrollContainer.new()
	scroll.size = Vector2(580, 450)
	
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	scroll.add_child(label)
	dialog.add_child(scroll)
	
	# Добавляем к сцене
	add_child(dialog)
	dialog.popup_centered()
	
	# Подключаем сигнал закрытия
	dialog.connect("confirmed", Callable(dialog, "queue_free"))
	dialog.connect("canceled", Callable(dialog, "queue_free"))

func _create_ability_buttons():
	"""Создает кнопки для активных способностей игрока"""
	# Проверяем, что контейнер Actions существует
	if not has_node("Actions"):
		print("ОШИБКА: Контейнер Actions не найден!")
		return
	
	# Создаем кнопки для способностей напрямую
	_create_spiritual_strike_button()
	_create_kinetic_strike_button()
	_create_soul_restoration_button()

func _create_spiritual_strike_button():
	"""Создает кнопку Спиритического удара"""
	# Проверяем, что кнопка еще не создана
	if has_node("Actions/Btn_SpiritualStrike"):
		return
	
	var btn = Button.new()
	btn.name = "Btn_SpiritualStrike"
	btn.text = "Спиритический удар"
	btn.tooltip_text = "Наносит урон по формуле: уровень * (сумма всех характеристик) / 5. Потребляет 15 маны.\nСтоимость: 15 ОМ"
	
	# Загружаем и устанавливаем иконку
	var icon_path = "res://Assets/Icons/Skills/Spirit_strike.png"
	if ResourceLoader.exists(icon_path):
		btn.icon = load(icon_path)
	
	# Подключаем сигнал
	btn.connect("pressed", Callable(self, "_on_ability_pressed").bind("spiritual_strike"))
	
	# Добавляем в Actions контейнер
	$Actions.add_child(btn)
	
	# Устанавливаем позицию и размер кнопки
	btn.position = Vector2(-800, -400)  # Верхняя кнопка
	btn.size = Vector2(180, 50)        # Увеличена высота для иконки

func _create_kinetic_strike_button():
	"""Создает кнопку Кинетического удара"""
	# Проверяем, что кнопка еще не создана
	if has_node("Actions/Btn_KineticStrike"):
		return
	
	var btn = Button.new()
	btn.name = "Btn_KineticStrike"
	btn.text = "Кинетический удар"
	btn.tooltip_text = "Наносит урон по формуле: уровень * сила. Потребляет 25 выносливости.\nСтоимость: 25 ОВ"
	
	# Загружаем и устанавливаем иконку
	var icon_path = "res://Assets/Icons/Skills/Keenetic_strike.png"
	if ResourceLoader.exists(icon_path):
		btn.icon = load(icon_path)
	
	# Подключаем сигнал
	btn.connect("pressed", Callable(self, "_on_ability_pressed").bind("kinetic_strike"))
	
	# Добавляем в Actions контейнер
	$Actions.add_child(btn)
	
	# Устанавливаем позицию и размер кнопки
	btn.position = Vector2(-800, -335)   # Увеличенное расстояние (было -350)
	btn.size = Vector2(180, 50)       # Увеличена высота для иконки

func _create_soul_restoration_button():
	"""Создает кнопку Восстановления души"""
	# Проверяем, что кнопка еще не создана
	if has_node("Actions/Btn_SoulRestoration"):
		return
	
	var btn = Button.new()
	btn.name = "Btn_SoulRestoration"
	btn.text = "Восстановление души"
	btn.tooltip_text = "Восстанавливает 35% от максимального ОЗ, ОМ и ОВ. Ограниченное количество зарядов на забег.\nЗаряды: 2 на забег"
	
	# Загружаем и устанавливаем иконку
	var icon_path = "res://Assets/Icons/Skills/SoulRestoration.png"
	if ResourceLoader.exists(icon_path):
		btn.icon = load(icon_path)
	
	# Подключаем сигнал
	btn.connect("pressed", Callable(self, "_on_ability_pressed").bind("soul_restoration"))
	
	# Добавляем в Actions контейнер
	$Actions.add_child(btn)
	
	# Устанавливаем позицию и размер кнопки
	btn.position = Vector2(-800, -270)   # Увеличенное расстояние (было -300)
	btn.size = Vector2(180, 50)         # Увеличена высота для иконки

func _update_ability_buttons():
	"""Обновляет состояние кнопок способностей"""
	# Обновляем кнопку Спиритического удара
	if has_node("Actions/Btn_SpiritualStrike"):
		var btn = $Actions/Btn_SpiritualStrike
		if player.mp >= 15:
			btn.disabled = false
			btn.modulate = Color.WHITE
		else:
			btn.disabled = true
			btn.modulate = Color.GRAY
	
	# Обновляем кнопку Кинетического удара
	if has_node("Actions/Btn_KineticStrike"):
		var btn = $Actions/Btn_KineticStrike
		if player.stamina >= 25:
			btn.disabled = false
			btn.modulate = Color.WHITE
		else:
			btn.disabled = true
			btn.modulate = Color.GRAY
	
	# Обновляем кнопку Восстановления души
	if has_node("Actions/Btn_SoulRestoration"):
		var btn = $Actions/Btn_SoulRestoration
		var soul_restoration_manager = get_node_or_null("/root/SoulRestorationManager")
		
		if soul_restoration_manager and soul_restoration_manager.can_use_charge():
			btn.disabled = false
			btn.modulate = Color.WHITE
			# Обновляем текст с количеством зарядов
			var current_charges = soul_restoration_manager.get_current_charges()
			var max_charges = soul_restoration_manager.get_max_charges()
			btn.text = "Восстановление души (%d/%d)" % [current_charges, max_charges]
		else:
			btn.disabled = true
			btn.modulate = Color.GRAY
			# Показываем, что заряды закончились
			var max_charges = soul_restoration_manager.get_max_charges() if soul_restoration_manager else 2
			btn.text = "Восстановление души (0/%d)" % [max_charges]

func _get_cost_text(ability: PlayerAbility) -> String:
	"""Возвращает текст стоимости способности"""
	var costs = []
	if ability.mp_cost > 0:
		costs.append(str(ability.mp_cost) + " ОМ")
	if ability.stamina_cost > 0:
		costs.append(str(ability.stamina_cost) + " ОВ")
	return ", ".join(costs) if costs.size() > 0 else "Бесплатно"

func _on_ability_pressed(ability_id: String):
	"""Обрабатывает нажатие на способность"""
	var battle_manager = root_scene
	if battle_manager and battle_manager.has_method("use_player_ability"):
		battle_manager.use_player_ability(ability_id)
	else:
		print("ОШИБКА: battle_manager не найден или не имеет метода use_player_ability")

func _get_rarity_display_text(rarity: String) -> String:
	# Проверяем элитных врагов
	if rarity.begins_with("elite_"):
		var base_rarity = rarity.replace("elite_", "")  # Убираем "elite_"
		match base_rarity:
			"rare":
				return "Элитный Редкий"
			"epic":
				return "Элитный Эпический"
			"legendary":
				return "Элитный Легендарный"
			_:
				return "Элитный"
	
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
		"mythic":
			return "Мифический"
		"boss":
			return "Босс"
		_:
			return "Неизвестный"

func _get_rarity_color(rarity: String) -> Color:
	# Для элитных врагов используем цвет базовой редкости (убираем "elite_")
	var base_rarity = rarity
	if rarity.begins_with("elite_"):
		base_rarity = rarity.replace("elite_", "")  # Убираем "elite_"
	
	match base_rarity:
		"common":
			return Color(0.8, 0.8, 0.8, 1.0)  # Серый
		"uncommon":
			return Color(0.0, 1.0, 0.0, 1.0)  # Зеленый
		"rare":
			return Color(0.0, 0.5, 1.0, 1.0)  # Синий
		"epic":
			return Color(0.8, 0.0, 1.0, 1.0)  # Фиолетовый
		"legendary":
			return Color(1.0, 0.5, 0.0, 1.0)  # Оранжевый
		"mythic":
			return Color(1.0, 0.0, 0.0, 1.0)  # Красный
		"boss":
			return Color(0.5, 0.0, 0.5, 1.0)  # Темно-фиолетовый
		_:
			return Color(1.0, 1.0, 1.0, 1.0)  # Белый

func _show_message(text: String) -> void:
	if has_node("MessageLog"):
		$MessageLog.text = text
	else:
		print(text)

func _update_effects_ui():
	# Обновляем отображение эффектов для игрока (иконки над персонажем)
	if is_instance_valid(player):
		_update_player_status_icons(player)
	
	# Обновляем отображение эффектов для врагов (иконки над персонажами)
	for i in range(enemies.size()):
		var current_enemy = enemies[i]
		if is_instance_valid(current_enemy):
			_update_enemy_status_icons(current_enemy, i)
	
	# Обновляем отображение эффектов для врага (текст в HUD) - для обратной совместимости
	if is_instance_valid(enemy):
		_update_character_effects_ui(enemy, "EnemyHUD")

func _update_character_effects_ui(character: Node, hud_path: String):
	if not character or not character.has_method("get") or not character.get("effects"):
		return
	
	var effects = character.get("effects")
	if not effects:
		effects = {}
	
	# Для игрока создаем иконки над персонажем, для врага - в HUD
	if hud_path == "PlayerHUD":
		# Игрок - используем иконки над персонажем (уже обработано в _update_effects_ui)
		pass
	else:
		_update_character_effects_ui_old(character, hud_path)

func _update_player_status_icons(character: Node):
	"""Обновляет иконки статусных эффектов над игроком"""
	if not character or not is_instance_valid(character):
		return
	
	# Предотвращаем одновременное обновление
	if is_updating_status_icons:
		return
	
	is_updating_status_icons = true
	
	# Получаем позицию игрока
	var player_visual = character.get_node_or_null("Visual")
	if not player_visual:
		is_updating_status_icons = false
		return
	
	# Вычисляем хеш текущих эффектов для проверки изменений
	# Включаем барьер в хеш, чтобы обновлять иконки при изменении барьера
	var barrier_value = 0
	if character.has_method("get_magic_barrier"):
		barrier_value = character.get_magic_barrier()
	var current_effects_hash = _get_effects_hash(character.effects, barrier_value)
	if current_effects_hash == last_player_effects_hash:
		# Эффекты не изменились, обновляем только позицию
		is_updating_status_icons = false
		_update_player_status_icons_position()
		return
	
	# Эффекты изменились, обновляем иконки
	last_player_effects_hash = current_effects_hash
	
	# Создаем или получаем контейнер для иконок над игроком
	var status_icons_container = get_node_or_null("PlayerStatusIcons")
	if not status_icons_container:
		status_icons_container = Control.new()
		status_icons_container.name = "PlayerStatusIcons"
		status_icons_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(status_icons_container)
		status_icons_container.z_index = 100
	
	# Очищаем старые иконки синхронно (собираем в массив, чтобы избежать проблем с изменением дерева)
	var children_to_remove = []
	for child in status_icons_container.get_children():
		children_to_remove.append(child)
	
	# Удаляем все дочерние узлы
	for child in children_to_remove:
		if is_instance_valid(child) and child.get_parent() == status_icons_container:
			status_icons_container.remove_child(child)
			child.queue_free()
	
	# Разделяем эффекты на бафы и дебафы (исключаем служебные эффекты)
	var buffs = []
	var debuffs = []
	var service_effects = ["dodge_block", "restlessness_attack", "tharnok_guardian_delay", "action_point_drain"]
	
	for effect_key in character.effects.keys():
		# Получаем базовый effect_id (без суффикса source_id)
		var effect = character.effects[effect_key]
		
		# Проверяем, что effect является словарем
		if not effect is Dictionary:
			print("ОШИБКА: Эффект '", effect_key, "' не является словарем в update_character_effects! Пропускаем...")
			continue
		
		var effect_id = effect.get("effect_id", "")
		# Если effect_id не указан в данных эффекта, используем ключ как fallback
		if effect_id == "":
			# Если effect_id не указан, пытаемся извлечь из ключа (формат: effect_id_source_id)
			if "_" in effect_key:
				var parts = effect_key.split("_")
				if parts.size() > 1:
					# Проверяем, является ли последняя часть числом (source_id)
					var last_part = parts[parts.size() - 1]
					if last_part.is_valid_int():
						effect_id = "_".join(parts.slice(0, parts.size() - 1))
					else:
						effect_id = effect_key
				else:
					effect_id = effect_key
			else:
				effect_id = effect_key
		
		# Пропускаем служебные эффекты
		if effect_id in service_effects:
			continue
		# Пропускаем эффекты без иконок
		if _get_effect_icon_path(effect_id) == "":
			continue
		if _is_buff(effect_id):
			buffs.append(effect_key)  # Используем effect_key для доступа к эффекту
		else:
			debuffs.append(effect_key)  # Используем effect_key для доступа к эффекту
	
	# Проверяем наличие барьера и добавляем его в список бафов, если он есть
	if character.has_method("get_magic_barrier"):
		barrier_value = character.get_magic_barrier()
		if barrier_value > 0:
			# Добавляем барьер в список бафов (используем специальный ключ)
			buffs.append("magic_barrier_virtual")
	
	# Если нет эффектов и нет барьера, скрываем контейнер
	if buffs.size() == 0 and debuffs.size() == 0:
		status_icons_container.visible = false
		is_updating_status_icons = false
		return
	
	status_icons_container.visible = true
	
	# Используем call_deferred для создания новых иконок после удаления старых
	# Создаем копию словаря эффектов, чтобы избежать проблем с изменением во время отложенного вызова
	var effects_copy = {}
	for key in character.effects.keys():
		var effect = character.effects[key]
		if effect is Dictionary:
			effects_copy[key] = effect.duplicate()
		else:
			print("ПРЕДУПРЕЖДЕНИЕ: Эффект '", key, "' не является словарем при копировании. Пропускаем...")
	call_deferred("_create_status_icons_deferred", status_icons_container, buffs, debuffs, effects_copy, character)

func _create_status_icons_deferred(status_icons_container: Control, buffs: Array, debuffs: Array, effects: Dictionary, character: Node):
	"""Создает иконки статусных эффектов (вызывается через call_deferred)"""
	if not is_instance_valid(status_icons_container):
		is_updating_status_icons = false
		return
	
	# Убеждаемся, что контейнер пуст (дополнительная проверка)
	for child in status_icons_container.get_children():
		status_icons_container.remove_child(child)
		child.queue_free()
	
	# Создаем контейнеры для бафов и дебафов
	var buffs_container = HBoxContainer.new()
	buffs_container.name = "BuffsContainer"
	buffs_container.add_theme_constant_override("separation", 5)
	
	var debuffs_container = HBoxContainer.new()
	debuffs_container.name = "DebuffsContainer"
	debuffs_container.add_theme_constant_override("separation", 5)
	
	# Создаем вертикальный контейнер для двух строк
	var main_container = VBoxContainer.new()
	main_container.name = "MainStatusContainer"
	main_container.add_theme_constant_override("separation", 5)
	
	# Добавляем контейнеры только если есть эффекты
	if buffs.size() > 0:
		main_container.add_child(buffs_container)
	if debuffs.size() > 0:
		main_container.add_child(debuffs_container)
	
	status_icons_container.add_child(main_container)
	
	# Добавляем иконки бафов
	for effect_key in buffs:
		# Специальная обработка для барьера
		if effect_key == "magic_barrier_virtual":
			if character.has_method("get_magic_barrier"):
				var barrier_value = character.get_magic_barrier()
				if barrier_value > 0:
					var barrier_effect = {
						"effect_id": "magic_barrier",
						"stacks": 1,
						"duration": 999.0,
						"barrier_value": barrier_value
					}
					var barrier_icon = _create_status_icon("magic_barrier", barrier_effect)
					if barrier_icon:
						buffs_container.add_child(barrier_icon)
			continue
		
		if effect_key in effects:
			var effect = effects[effect_key]
			var effect_id = effect.get("effect_id", "")
			# Если effect_id не указан в данных эффекта, используем ключ как fallback
			if effect_id == "":
				# Извлекаем базовый effect_id из ключа
				if "_" in effect_key:
					var parts = effect_key.split("_")
					if parts.size() > 1:
						var last_part = parts[parts.size() - 1]
						if last_part.is_valid_int():
							effect_id = "_".join(parts.slice(0, parts.size() - 1))
						else:
							effect_id = effect_key
					else:
						effect_id = effect_key
				else:
					effect_id = effect_key
			# Отладочный вывод для проверки effect_id
			if effect_id == "rage" or effect_id == "berserker_fury":
				print("DEBUG: Создаем иконку для эффекта: effect_key=", effect_key, ", effect_id=", effect_id, ", effect.get('effect_id')=", effect.get("effect_id", "NOT_FOUND"))
			var icon = _create_status_icon(effect_id, effect)
			if icon:
				buffs_container.add_child(icon)
	
	# Добавляем иконки дебафов
	for effect_key in debuffs:
		if effect_key in effects:
			var effect = effects[effect_key]
			var effect_id = effect.get("effect_id", effect_key)
			if effect_id == "":
				# Извлекаем базовый effect_id из ключа
				if "_" in effect_key:
					var parts = effect_key.split("_")
					if parts.size() > 1:
						var last_part = parts[parts.size() - 1]
						if last_part.is_valid_int():
							effect_id = "_".join(parts.slice(0, parts.size() - 1))
						else:
							effect_id = effect_key
					else:
						effect_id = effect_key
				else:
					effect_id = effect_key
			var icon = _create_status_icon(effect_id, effect)
			if icon:
				debuffs_container.add_child(icon)
	
	# Обновляем позицию контейнера
	_update_player_status_icons_position()
	
	# Снимаем флаг обновления
	is_updating_status_icons = false

func _update_player_status_icons_position():
	"""Обновляет позицию иконок статусных эффектов над игроком"""
	var status_icons_container = get_node_or_null("PlayerStatusIcons")
	if not status_icons_container or not status_icons_container.visible:
		return
	
	if not is_instance_valid(player):
		return
	
	var player_visual = player.get_node_or_null("Visual")
	if not player_visual:
		return
	
	var player_position = player_visual.global_position
	var icon_offset = Vector2(0, -80)  # Смещение вверх от центра персонажа
	
	# Устанавливаем позицию контейнера над игроком
	status_icons_container.global_position = player_position + icon_offset
	
	# Центрируем контейнер (используем call_deferred для правильного расчета размера)
	var main_container = status_icons_container.get_node_or_null("MainStatusContainer")
	if main_container:
		# Используем call_deferred без параметров, получаем контейнер внутри функции
		call_deferred("_center_status_icons")

func _update_enemy_status_icons(character: Node, enemy_index: int):
	"""Обновляет иконки статусных эффектов над врагом"""
	if not character or not is_instance_valid(character):
		return
	
	# Получаем позицию врага
	var enemy_visual = character.get_node_or_null("Visual")
	if not enemy_visual:
		return
	
	# Вычисляем хеш текущих эффектов для проверки изменений
	# Включаем барьер в хеш, чтобы обновлять иконки при изменении барьера
	var barrier_value = 0
	if character.has_method("get_magic_barrier"):
		barrier_value = character.get_magic_barrier()
	var current_effects_hash = _get_effects_hash(character.effects, barrier_value)
	
	# Проверяем, изменились ли эффекты
	var enemy_key = str(enemy_index)
	var last_data = last_enemy_effects.get(enemy_key, {})
	var last_hash = last_data.get("hash", -1)
	
	if current_effects_hash == last_hash:
		# Эффекты не изменились, обновляем только позицию
		_update_enemy_status_icons_position(character, enemy_index)
		return
	
	# Эффекты изменились, обновляем иконки
	last_enemy_effects[enemy_key] = {"hash": current_effects_hash, "barrier": barrier_value}
	
	# Создаем или получаем контейнер для иконок над врагом
	var status_icons_container_name = "EnemyStatusIcons_" + str(enemy_index)
	var status_icons_container = get_node_or_null(status_icons_container_name)
	if not status_icons_container:
		status_icons_container = Control.new()
		status_icons_container.name = status_icons_container_name
		status_icons_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(status_icons_container)
		status_icons_container.z_index = 100
	
	# Очищаем старые иконки синхронно
	var children_to_remove = []
	for child in status_icons_container.get_children():
		children_to_remove.append(child)
	
	for child in children_to_remove:
		if is_instance_valid(child) and child.get_parent() == status_icons_container:
			status_icons_container.remove_child(child)
			child.queue_free()
	
	# Разделяем эффекты на бафы и дебафы (исключаем служебные эффекты)
	var buffs = []
	var debuffs = []
	var service_effects = ["dodge_block", "restlessness_attack", "tharnok_guardian_delay", "action_point_drain"]
	
	for effect_key in character.effects.keys():
		# Получаем базовый effect_id (без суффикса source_id)
		var effect = character.effects[effect_key]
		
		# Проверяем, что effect является словарем
		if not effect is Dictionary:
			print("ОШИБКА: Эффект '", effect_key, "' не является словарем в update_status_icons! Пропускаем...")
			continue
		
		var effect_id = effect.get("effect_id", effect_key)
		if effect_id == "":
			# Если effect_id не указан, пытаемся извлечь из ключа
			if "_" in effect_key:
				var parts = effect_key.split("_")
				if parts.size() > 1:
					var last_part = parts[parts.size() - 1]
					if last_part.is_valid_int():
						effect_id = "_".join(parts.slice(0, parts.size() - 1))
					else:
						effect_id = effect_key
				else:
					effect_id = effect_key
			else:
				effect_id = effect_key
		
		# Пропускаем служебные эффекты
		if effect_id in service_effects:
			continue
		# Пропускаем эффекты без иконок
		if _get_effect_icon_path(effect_id) == "":
			continue
		if _is_buff(effect_id):
			buffs.append(effect_key)
		else:
			debuffs.append(effect_key)
	
	# Проверяем наличие барьера и добавляем его в список бафов, если он есть
	if character.has_method("get_magic_barrier"):
		barrier_value = character.get_magic_barrier()
		if barrier_value > 0:
			buffs.append("magic_barrier_virtual")
	
	# Если нет эффектов и нет барьера, скрываем контейнер
	if buffs.size() == 0 and debuffs.size() == 0:
		status_icons_container.visible = false
		return
	
	status_icons_container.visible = true
	
	# Используем call_deferred для создания новых иконок после удаления старых
	var effects_copy = {}
	for key in character.effects.keys():
		var effect = character.effects[key]
		if effect is Dictionary:
			effects_copy[key] = effect.duplicate()
		else:
			print("ПРЕДУПРЕЖДЕНИЕ: Эффект '", key, "' не является словарем при копировании. Пропускаем...")
	call_deferred("_create_status_icons_deferred", status_icons_container, buffs, debuffs, effects_copy, character)
	
	# Обновляем позицию контейнера
	_update_enemy_status_icons_position(character, enemy_index)

func _update_enemy_status_icons_position(character: Node, enemy_index: int):
	"""Обновляет позицию иконок статусных эффектов над врагом"""
	var status_icons_container_name = "EnemyStatusIcons_" + str(enemy_index)
	var status_icons_container = get_node_or_null(status_icons_container_name)
	if not status_icons_container or not status_icons_container.visible:
		return
	
	if not is_instance_valid(character):
		return
	
	var enemy_visual = character.get_node_or_null("Visual")
	if not enemy_visual:
		return
	
	var enemy_position = enemy_visual.global_position
	var icon_offset = Vector2(0, -120)  # Смещение вверх от центра персонажа (поднято на 40 пикселей выше)
	
	# Устанавливаем позицию контейнера над врагом
	status_icons_container.global_position = enemy_position + icon_offset

func _update_character_effects_ui_old(character: Node, hud_path: String):
	"""Старая функция для отображения эффектов врага в HUD (текстом)"""
	if not character or not character.has_method("get") or not character.get("effects"):
		return
	
	var effects = character.get("effects")
	if not effects:
		effects = {}
	
	# Создаем или обновляем контейнер для эффектов
	var effects_container = get_node_or_null(hud_path + "/EffectsContainer")
	if not effects_container:
		effects_container = VBoxContainer.new()
		effects_container.name = "EffectsContainer"
		get_node(hud_path).add_child(effects_container)
	
	# Очищаем старые эффекты
	for child in effects_container.get_children():
		child.queue_free()
	
	# Добавляем новые эффекты
	for effect_id in effects.keys():
		var effect = effects[effect_id]
		var stacks = effect.get("stacks", 1)
		var duration = effect.get("duration", 0)
		
		var effect_label = Label.new()
		effect_label.text = _get_effect_display_text(effect_id, stacks, duration)
		effect_label.modulate = _get_effect_color(effect_id)
		effects_container.add_child(effect_label)

func _is_buff(effect_id: String) -> bool:
	"""Определяет, является ли эффект бафом"""
	match effect_id:
		"defend", "stealth", "invisibility", "rage", "demon_blood", "guaranteed_dodge", "invulnerability", "final_judgment", "armor_ignore", "defense_buff", "corpse_eater", "magic_barrier", "berserk", "berserker_fury":
			return true
		_:
			return false

func _create_status_icon(effect_id: String, effect_data: Dictionary) -> Control:
	"""Создает иконку статусного эффекта"""
	var icon_path = _get_effect_icon_path(effect_id)
	if icon_path == "":
		print("DEBUG: Нет иконки для эффекта: ", effect_id)
		return null
	
	# Отладочный вывод для проверки пути к иконке
	if effect_id == "rage" or effect_id == "berserker_fury":
		print("DEBUG: _create_status_icon вызвана для effect_id=", effect_id, ", icon_path=", icon_path, ", effect_data=", effect_data)
	
	# Загружаем текстуру
	var texture = load(icon_path)
	if not texture:
		print("WARNING: Не удалось загрузить иконку для эффекта: ", effect_id, " по пути: ", icon_path)
		return null
	
	# Создаем контейнер для иконки
	var icon_container = Control.new()
	icon_container.custom_minimum_size = Vector2(32, 32)
	icon_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Создаем TextureRect для иконки
	var icon_rect = TextureRect.new()
	icon_rect.texture = texture
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.size = Vector2(32, 32)
	icon_rect.position = Vector2(0, 0)
	icon_container.add_child(icon_rect)
	
	# Проверяем, нет ли уже лейблов в контейнере (защита от дубликатов)
	var existing_stacks_label = icon_container.get_node_or_null("StacksLabel")
	var existing_duration_label = icon_container.get_node_or_null("DurationLabel")
	if existing_stacks_label:
		existing_stacks_label.queue_free()
	if existing_duration_label:
		existing_duration_label.queue_free()
	
	# Добавляем отображение стаков или специальных значений
	var stacks = effect_data.get("stacks", 1)
	# Эффекты, которые могут стакаться и должны показывать только стаки (не длительность)
	var stackable_effects = ["bleeding", "poison", "neurotoxin", "wound", "rotten", "demon_blood", "plague", "berserker_fury"]
	var should_show_stacks = effect_id in stackable_effects
	
	# Для барьера показываем значение барьера вместо стаков
	if effect_id == "magic_barrier":
		var barrier_value = effect_data.get("barrier_value", 0)
		if barrier_value > 0:
			var value_label = Label.new()
			value_label.name = "StacksLabel"
			value_label.text = str(int(barrier_value))
			value_label.add_theme_font_size_override("font_size", 12)
			value_label.add_theme_color_override("font_color", Color.WHITE)
			value_label.add_theme_color_override("font_outline_color", Color.BLACK)
			value_label.add_theme_constant_override("outline_size", 2)
			# Позиционируем в правом нижнем углу иконки
			value_label.position = Vector2(20, 20)
			value_label.size = Vector2(12, 12)
			value_label.z_index = 10
			icon_container.add_child(value_label)
	# Для коррозии брони показываем значение снижения брони вместо стаков
	elif effect_id == "corrosive_armor":
		var armor_reduction = effect_data.get("armor_reduction", 0)
		if armor_reduction > 0:
			var value_label = Label.new()
			value_label.name = "StacksLabel"
			value_label.text = str(int(armor_reduction))
			value_label.add_theme_font_size_override("font_size", 12)
			value_label.add_theme_color_override("font_color", Color.WHITE)
			value_label.add_theme_color_override("font_outline_color", Color.BLACK)
			value_label.add_theme_constant_override("outline_size", 2)
			# Позиционируем в правом нижнем углу иконки
			value_label.position = Vector2(20, 20)
			value_label.size = Vector2(12, 12)
			value_label.z_index = 10
			icon_container.add_child(value_label)
	# Для Выносливости орка (ork_vitality) показываем текущее снижение урона в процентах
	elif effect_id == "ork_vitality":
		# Вычисляем текущее снижение урона из эффекта
		var damage_reduction_percent = effect_data.get("damage_reduction_percent", 0.0)
		if damage_reduction_percent > 0:
			var value_label = Label.new()
			value_label.name = "StacksLabel"
			value_label.text = str(int(damage_reduction_percent)) + "%"
			value_label.add_theme_font_size_override("font_size", 11)
			value_label.add_theme_color_override("font_color", Color.WHITE)
			value_label.add_theme_color_override("font_outline_color", Color.BLACK)
			value_label.add_theme_constant_override("outline_size", 2)
			# Позиционируем в правом нижнем углу иконки
			value_label.position = Vector2(18, 20)
			value_label.size = Vector2(14, 12)
			value_label.z_index = 10
			icon_container.add_child(value_label)
	# Для Берсерка не показываем стаки (эффект либо есть, либо нет)
	elif effect_id == "berserk":
		# Не показываем стаки или значения, только иконку
		pass
	# Для стакающихся эффектов всегда показываем стаки (даже если стаки = 1)
	elif should_show_stacks:
		var stacks_label = Label.new()
		stacks_label.name = "StacksLabel"
		stacks_label.text = str(stacks)
		stacks_label.add_theme_font_size_override("font_size", 12)
		stacks_label.add_theme_color_override("font_color", Color.WHITE)
		stacks_label.add_theme_color_override("font_outline_color", Color.BLACK)
		stacks_label.add_theme_constant_override("outline_size", 2)
		# Позиционируем в правом нижнем углу иконки
		stacks_label.position = Vector2(20, 20)
		stacks_label.size = Vector2(12, 12)
		stacks_label.z_index = 10
		icon_container.add_child(stacks_label)
	# Для Ярости (rage) показываем длительность
	elif effect_id == "rage":
		var effect_duration = effect_data.get("duration", 0)
		if effect_duration > 0 and effect_duration < 999:
			var duration_label = Label.new()
			duration_label.name = "DurationLabel"
			duration_label.text = str(int(effect_duration))
			duration_label.add_theme_font_size_override("font_size", 10)
			duration_label.add_theme_color_override("font_color", Color.WHITE)
			duration_label.add_theme_color_override("font_outline_color", Color.BLACK)
			duration_label.add_theme_constant_override("outline_size", 2)
			# Позиционируем в нижней части иконки
			duration_label.position = Vector2(0, 20)
			duration_label.size = Vector2(32, 12)
			duration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			duration_label.z_index = 10
			icon_container.add_child(duration_label)
	# Для остальных эффектов показываем стаки только если их больше 1
	elif stacks > 1:
		var stacks_label = Label.new()
		stacks_label.name = "StacksLabel"  # Добавляем имя для отладки
		stacks_label.text = str(stacks)
		stacks_label.add_theme_font_size_override("font_size", 12)
		stacks_label.add_theme_color_override("font_color", Color.WHITE)
		stacks_label.add_theme_color_override("font_outline_color", Color.BLACK)
		stacks_label.add_theme_constant_override("outline_size", 2)
		# Позиционируем в правом нижнем углу иконки
		stacks_label.position = Vector2(20, 20)
		stacks_label.size = Vector2(12, 12)
		stacks_label.z_index = 10  # Убеждаемся, что лейбл поверх иконки
		icon_container.add_child(stacks_label)
	
	# Добавляем отображение длительности (только если эффект не стакается, нет стаков или стаки = 1, и не для коррозии брони, барьера, выносливости орка и берсерка)
	var duration = effect_data.get("duration", 0)
	if duration > 0 and not should_show_stacks and stacks <= 1 and effect_id != "corrosive_armor" and effect_id != "magic_barrier" and effect_id != "ork_vitality" and effect_id != "berserk":
		var duration_label = Label.new()
		duration_label.name = "DurationLabel"  # Добавляем имя для отладки
		duration_label.text = str(int(duration))
		duration_label.add_theme_font_size_override("font_size", 10)
		duration_label.add_theme_color_override("font_color", Color.WHITE)
		duration_label.add_theme_color_override("font_outline_color", Color.BLACK)
		duration_label.add_theme_constant_override("outline_size", 2)
		# Позиционируем в нижней части иконки
		duration_label.position = Vector2(0, 20)
		duration_label.size = Vector2(32, 12)
		duration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		duration_label.z_index = 10  # Убеждаемся, что лейбл поверх иконки
		icon_container.add_child(duration_label)
	
	# Добавляем tooltip с описанием эффекта
	var effect_tooltip = _get_effect_tooltip(effect_id, stacks, duration, effect_data)
	icon_container.tooltip_text = effect_tooltip
	
	return icon_container

func _get_effect_icon_path(effect_id: String) -> String:
	"""Возвращает путь к иконке эффекта"""
	var icon_name = ""
	match effect_id:
		"bleeding":
			icon_name = "Bleed"
		"poison":
			icon_name = "Poison"
		"stun":
			icon_name = "Stun"
		"paralysis":
			icon_name = "Paralysis"
		"curse":
			icon_name = "Curse"
		"wound":
			icon_name = "Wounds"
		"neurotoxin":
			icon_name = "Neurotoxin"
		"rotten":
			icon_name = "Rotten"
		"judgment":
			icon_name = "Judgment"
		"defend":
			icon_name = "Defend"
		"stealth", "invisibility":
			icon_name = "Invisibility"
		"rage":
			icon_name = "Rage"
		"demon_blood":
			icon_name = "Demon_blood"
		"corrosive_armor":
			icon_name = "Corrosive_armour"
		"guaranteed_dodge":
			icon_name = "Guaranteed_dodge"
		"invulnerability":
			icon_name = "Defend"  # Используем иконку защиты
		"final_judgment":
			icon_name = "Judgment"  # Используем иконку суда
		"corpse_eater":
			icon_name = "Corpse_eater"
		"magic_barrier":
			icon_name = "Barrier"
		"ork_vitality":
			icon_name = "Ork_vitality"  # Выносливость орка
		"berserk":
			icon_name = "Berserk"  # Берсерк
		"berserker_fury":
			icon_name = "Battle_frenzy"  # Боевое безумие
		_:
			return ""  # Нет иконки для этого эффекта
	
	if icon_name == "":
		return ""
	
	return "res://Assets/Icons/" + icon_name + ".png"

func _get_effect_tooltip(effect_id: String, stacks: int, duration: float, effect_data: Dictionary = {}) -> String:
	"""Возвращает текст подсказки для эффекта"""
	# Специальная обработка для барьера
	if effect_id == "magic_barrier":
		var barrier_value = effect_data.get("barrier_value", 0)
		return "Магический барьер: " + str(int(barrier_value)) + "\nПоглощает урон и блокирует некоторые статусные эффекты"
	
	var effect_name = _get_effect_display_name(effect_id)
	var duration_text = ""
	if duration > 0 and duration < 999:
		duration_text = " (" + str(int(duration)) + " ходов)"
	
	var stacks_text = ""
	if effect_id == "magic_barrier":
		# Для барьера показываем значение барьера
		var barrier_value = effect_data.get("barrier_value", 0)
		if barrier_value > 0:
			stacks_text = ": " + str(int(barrier_value))
	elif effect_id == "corrosive_armor":
		# Для коррозии брони показываем значение снижения брони
		var armor_reduction = effect_data.get("armor_reduction", 0)
		if armor_reduction > 0:
			stacks_text = ": -" + str(int(armor_reduction)) + " защиты"
	elif effect_id == "ork_vitality":
		# Для выносливости орка показываем текущее снижение урона
		var damage_reduction_percent = effect_data.get("damage_reduction_percent", 0.0)
		if damage_reduction_percent > 0:
			stacks_text = ": -" + str(int(damage_reduction_percent)) + "% урона"
	elif effect_id == "rage":
		# Для ярости показываем стаки (или длительность)
		if stacks > 1:
			stacks_text = " x" + str(stacks)
		elif duration > 0 and duration < 999:
			stacks_text = " (" + str(int(duration)) + " ходов)"
	elif stacks > 1:
		stacks_text = " x" + str(stacks)
	
	return effect_name + stacks_text + duration_text

func _get_effects_hash(effects: Dictionary, barrier_value: int = 0) -> int:
	"""Вычисляет хеш эффектов для проверки изменений"""
	var hash_string = ""
	var sorted_keys = effects.keys()
	sorted_keys.sort()
	for key in sorted_keys:
		var effect = effects[key]
		var stacks = effect.get("stacks", 1)
		var duration = int(effect.get("duration", 0))
		hash_string += key + ":" + str(stacks) + ":" + str(duration) + ";"
	# Добавляем барьер в хеш, чтобы обновлять иконки при изменении барьера
	hash_string += "barrier:" + str(barrier_value) + ";"
	return hash_string.hash()

func _center_status_icons():
	"""Центрирует контейнер с иконками статусных эффектов"""
	var status_icons_container = get_node_or_null("PlayerStatusIcons")
	if not status_icons_container:
		return
	var main_container = status_icons_container.get_node_or_null("MainStatusContainer")
	if not main_container or not is_instance_valid(main_container):
		return
	var container_width = main_container.size.x
	main_container.position = Vector2(-container_width / 2, 0)

func _get_effect_display_name(effect_id: String) -> String:
	"""Возвращает отображаемое имя эффекта"""
	match effect_id:
		"bleeding":
			return "Кровотечение"
		"poison":
			return "Яд"
		"stun":
			return "Оглушение"
		"paralysis":
			return "Паралич"
		"curse":
			return "Проклятие"
		"wound":
			return "Рана"
		"neurotoxin":
			return "Нейротоксин"
		"rotten":
			return "Гниль"
		"judgment":
			return "Суд палача"
		"defend":
			return "Защита"
		"stealth", "invisibility":
			return "Невидимость"
		"rage":
			return "Ярость"
		"demon_blood":
			return "Кровь демона"
		"corrosive_armor":
			return "Коррозия брони"
		"guaranteed_dodge":
			return "Гарантированный уворот"
		"invulnerability":
			return "Неуязвимость"
		"final_judgment":
			return "Последний приговор"
		"corpse_eater":
			return "Пожиратель трупов"
		"magic_barrier":
			return "Магический барьер"
		"ork_vitality":
			return "Выносливость орка"
		"berserk":
			return "Берсерк"
		"berserker_fury":
			return "Боевое безумие"
		_:
			return effect_id

func _get_effect_display_text(effect_id: String, stacks: int, duration: float) -> String:
	match effect_id:
		"bleeding":
			return "Кровотечение x" + str(stacks) + " (" + str(int(duration)) + " ходов)"
		"defend":
			return "Защита (" + str(int(duration)) + " ходов)"
		_:
			return effect_id + " (" + str(int(duration)) + " ходов)"

func _get_effect_color(effect_id: String) -> Color:
	match effect_id:
		"bleeding":
			return Color(1.0, 0.0, 0.0, 1.0)  # Красный
		"defend":
			return Color(0.0, 0.5, 1.0, 1.0)  # Синий
		_:
			return Color(1.0, 1.0, 1.0, 1.0)  # Белый

func _update_soul_shards_display():
	"""Обновляет отображение осколков душ"""
	var soul_shard_manager = get_node_or_null("/root/SoulShard")
	var soul_shards_label = get_node_or_null("PlayerHUD/SoulShardsLabel")
	
	if not soul_shard_manager:
		# Скрываем отображение осколков душ, если менеджер недоступен
		if soul_shards_label:
			soul_shards_label.visible = false
		return
	
	var soul_shards = soul_shard_manager.get_soul_shards()
	
	# Ищем или создаем элемент для отображения осколков душ
	if not soul_shards_label:
		# Создаем новый Label для осколков душ
		soul_shards_label = Label.new()
		soul_shards_label.name = "SoulShardsLabel"
		soul_shards_label.add_to_group("soul_shards_display")
		
		# Добавляем в PlayerHUD
		if has_node("PlayerHUD"):
			$PlayerHUD.add_child(soul_shards_label)
		else:
			# Если PlayerHUD нет, добавляем в корень
			add_child(soul_shards_label)
	
	# Устанавливаем текст и стиль
	soul_shards_label.text = "Осколки душ: %d" % soul_shards
	soul_shards_label.modulate = Color(0.8, 0.4, 1.0, 1.0)  # Фиолетовый цвет для осколков душ
	
	# Позиционируем в левом верхнем углу
	soul_shards_label.position = Vector2(10, 10)
	soul_shards_label.z_index = 100  # Поверх других элементов

func _on_soul_shards_changed(_new_amount: int):
	"""Обработчик изменения количества осколков душ"""
	_update_soul_shards_display()

func _update_run_soul_shards_display():
	"""Обновляет отображение осколков душ за забег"""
	var soul_shard_manager = get_node_or_null("/root/SoulShard")
	var run_soul_shards_indicator = get_node_or_null("RunSoulShardsIndicator")
	var run_soul_shards_label = get_node_or_null("RunSoulShardsIndicator/SoulShardsLabel")
	
	if not soul_shard_manager or not run_soul_shards_indicator:
		return
	
	var run_soul_shards = soul_shard_manager.get_run_soul_shards()
	
	# Обновляем текст
	if run_soul_shards_label:
		run_soul_shards_label.text = "Осколки за забег: %d" % run_soul_shards
	
	# Показываем индикатор всегда, но с разной прозрачностью
	if run_soul_shards > 0:
		run_soul_shards_indicator.visible = true
		run_soul_shards_indicator.modulate = Color(1, 1, 1, 1)
		# Анимация появления только при первом появлении осколков
		if not run_soul_shards_indicator.has_method("_animate_appearance"):
			_animate_soul_shards_indicator(run_soul_shards_indicator)
	else:
		# Делаем полупрозрачным вместо полного скрытия
		run_soul_shards_indicator.visible = true
		run_soul_shards_indicator.modulate = Color(1, 1, 1, 0.3)

func _on_run_soul_shards_changed(_new_amount: int):
	"""Обработчик изменения количества осколков душ за забег"""
	_update_run_soul_shards_display()

func _on_soul_restoration_changed(_new_charges: int, _max_charges: int) -> void:
	"""Обрабатывает изменение зарядов восстановления души"""
	_update_ui()

func _animate_soul_shards_indicator(indicator: Control):
	"""Анимирует появление индикатора осколков душ"""
	# Сохраняем текущую прозрачность
	var current_alpha = indicator.modulate.a
	
	# Анимация появления только если элемент был полупрозрачным
	if current_alpha < 0.8:
		var tween = create_tween()
		tween.tween_property(indicator, "modulate", Color(1, 1, 1, 1), 0.3)
		
		# Добавляем небольшое покачивание для привлечения внимания
		var original_scale = indicator.scale
		tween.parallel().tween_property(indicator, "scale", original_scale * 1.05, 0.2)
		tween.tween_property(indicator, "scale", original_scale, 0.1)

func _update_defensive_stats_display():
	"""Обновляет отображение защитных характеристик (Броня и Маг. сопр.) для игрока и врага"""
	_update_player_defensive_stats()
	if is_instance_valid(enemy):
		_update_enemy_defensive_stats()

func _update_player_defensive_stats():
	if not is_instance_valid(player):
		return
	
	# --- Магическое сопротивление ---
	var magic_resistance = player.magic_resistance
	var effective_resistance = magic_resistance
	if player.has_method("get_effective_magic_resistance"):
		effective_resistance = player.get_effective_magic_resistance()
	
	# --- Броня ---
	# Базовое значение защиты (для отображения)
	var defense = player.defense if "defense" in player else 0
	
	# Получаем эффективную защиту через централизованную функцию
	var effective_defense = 0
	if player.has_method("get_effective_defense"):
		effective_defense = player.get_effective_defense()
	else:
		# Fallback на старый способ, если метод не найден
		var defense_from_vitality = player.defense_from_vitality if "defense_from_vitality" in player else 0
		var armor_reduction = player.armor_reduction if "armor_reduction" in player else 0
		effective_defense = defense + defense_from_vitality - armor_reduction
	
	var is_armor_ignored = player.has_effect("armor_ignore") if player.has_method("has_effect") else false
	
	# Создаем контейнер под полосками здоровья игрока
	var stats_container_name = "PlayerDefensiveStats"
	var stats_container = get_node_or_null(stats_container_name)
	
	if not stats_container or not is_instance_valid(stats_container) or not stats_container.is_inside_tree():
		if stats_container and is_instance_valid(stats_container):
			stats_container.queue_free()
		
		stats_container = HBoxContainer.new()  # Горизонтальный контейнер для иконок в ряд
		stats_container.name = stats_container_name
		stats_container.add_theme_constant_override("separation", 10)  # Расстояние между иконками
		add_child(stats_container)
		stats_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stats_container.visible = true
		stats_container.z_index = 100
		
	# Позиционируем относительно полоски здоровья игрока
	var player_hp_bar = get_node_or_null("HealthBars/PlayerHP")
	if player_hp_bar:
		# Берем позицию полоски HP и смещаемся вниз и вправо
		stats_container.position = player_hp_bar.position + Vector2(320, 75)
	else:
		# Fallback если полоска не найдена
		stats_container.position = Vector2(330, 750)
		
	# Очищаем старые элементы
	for child in stats_container.get_children():
		stats_container.remove_child(child)
		child.queue_free()
	
	# === ИКОНКА БРОНИ (коричневый щит) ===
	var armor_container = _create_stat_icon(defense, effective_defense, is_armor_ignored, "armor")
	stats_container.add_child(armor_container)
	
	# === ИКОНКА МАГ. СОПРОТИВЛЕНИЯ (синий щит) ===
	var mr_container = _create_stat_icon(magic_resistance, effective_resistance, false, "magic_resist")
	stats_container.add_child(mr_container)

func _create_stat_icon(base_value: int, effective_value: int, is_ignored: bool, stat_type: String) -> Control:
	"""Создает иконку щита со значением внутри"""
	# Контейнер для наложения текста на иконку
	var container = Control.new()
	container.custom_minimum_size = Vector2(64, 64)  # Увеличенный размер для лучшей видимости
	
	# Загружаем иконку щита в зависимости от типа
	var shield_texture
	if stat_type == "armor":
		shield_texture = load("res://Assets/Sprites/Icons/Shield_Phys.png")
	else:  # magic_resist
		shield_texture = load("res://Assets/Sprites/Icons/Shield_Mage.png")
	
	# Создаем фон щита
	var shield_icon = TextureRect.new()
	shield_icon.texture = shield_texture
	shield_icon.custom_minimum_size = Vector2(64, 64)  # Увеличенный размер
	shield_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shield_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	shield_icon.anchors_preset = Control.PRESET_FULL_RECT
	shield_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(shield_icon)
	
	# Создаем текст СО значением ПОВЕРХ щита
	var value_label = Label.new()
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 22)  # Крупнее для читаемости
	value_label.add_theme_color_override("font_outline_color", Color.BLACK)
	value_label.add_theme_constant_override("outline_size", 4)
	
	# Определяем текст и цвет
	if is_ignored:
		value_label.text = "0"
		value_label.modulate = Color(1.0, 0.0, 0.0, 1.0)  # Красный
	elif effective_value != base_value:
		value_label.text = str(effective_value)
		value_label.modulate = Color(1.0, 0.5, 0.0, 1.0) if effective_value < base_value else Color(0.0, 1.0, 0.0, 1.0)
	else:
		value_label.text = str(base_value)
		value_label.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Белый
	
	# Центрируем текст в контейнере
	value_label.anchors_preset = Control.PRESET_FULL_RECT
	value_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	value_label.position = Vector2(0, 2)  # Небольшое смещение вниз для лучшего центрирования
	
	container.add_child(value_label)
	
	return container

func _update_enemy_defensive_stats():
	if not is_instance_valid(enemy):
		# Удаляем контейнер из корня если враг недоступен
		var container = get_node_or_null("EnemyDefensiveStats")
		if container:
			container.queue_free()
		return

	# --- Броня Врага ---
	# Базовое значение защиты (для отображения)
	var defense = enemy.defense if "defense" in enemy else 0
	
	# Получаем эффективную защиту через централизованную функцию
	var effective_defense = 0
	if enemy.has_method("get_effective_defense"):
		effective_defense = enemy.get_effective_defense()
	else:
		# Fallback на старый способ, если метод не найден
		var defense_from_vitality = enemy.defense_from_vitality if "defense_from_vitality" in enemy else 0
		var armor_reduction = enemy.armor_reduction if "armor_reduction" in enemy else 0
		effective_defense = defense + defense_from_vitality - armor_reduction
	
	var is_armor_ignored = enemy.has_effect("armor_ignore") if enemy.has_method("has_effect") else false
	
	# --- Маг. Сопр. Врага ---
	var magic_resistance = enemy.magic_resistance if "magic_resistance" in enemy else 0
	var effective_resistance = magic_resistance
	if enemy.has_method("get_effective_magic_resistance"):
		effective_resistance = enemy.get_effective_magic_resistance()

	# Создаем контейнер под полосками здоровья врага
	var stats_container_name = "EnemyDefensiveStats"
	var stats_container = get_node_or_null(stats_container_name)
	
	if not stats_container or not is_instance_valid(stats_container) or not stats_container.is_inside_tree():
		if stats_container and is_instance_valid(stats_container):
			stats_container.queue_free()
		
		stats_container = HBoxContainer.new()  # Горизонтальный контейнер
		stats_container.name = stats_container_name
		stats_container.add_theme_constant_override("separation", 10)
		add_child(stats_container)
		stats_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stats_container.visible = true
		stats_container.z_index = 100
		
	# Позиционируем относительно полоски здоровья врага
	var enemy_hp_bar = get_node_or_null("HealthBars/EnemyHP")
	if enemy_hp_bar:
		# Берем позицию полоски HP и смещаемся вниз и влево
		stats_container.position = enemy_hp_bar.position + Vector2(-200, 75)
	else:
		# Fallback если полоска не найдена
		stats_container.position = Vector2(950, 750)
		
	# Очищаем старые элементы
	for child in stats_container.get_children():
		stats_container.remove_child(child)
		child.queue_free()
	
	# === ИКОНКА БРОНИ (коричневый щит) ===
	var armor_container = _create_stat_icon(defense, effective_defense, is_armor_ignored, "armor")
	stats_container.add_child(armor_container)
	
	# === ИКОНКА МАГ. СОПРОТИВЛЕНИЯ (синий щит) ===
	var mr_container = _create_stat_icon(magic_resistance, effective_resistance, false, "magic_resist")
	stats_container.add_child(mr_container)

func _get_or_create_hud_label_deprecated(_hud_name: String, _label_name: String) -> Label:
	# DEPRECATED
	return null

func _update_magic_resistance_display_deprecated():
	# DEPRECATED: Replaced by _update_defensive_stats_display
	pass


func _update_enemy_ability_display():
	"""Обновляет отображение способности врага"""
	if not is_instance_valid(enemy):
		# Очищаем отображение способностей
		if has_node("EnemyHUD/EnemyAbilities"):
			$EnemyHUD/EnemyAbilities.text = ""
		return
	
	# Получаем способность врага
	var battle_manager = root_scene
	if not battle_manager or not battle_manager.has_method("get_enemy_ability"):
		return
	
	var enemy_ability = battle_manager.get_enemy_ability(enemy.display_name)
	if not enemy_ability:
		# Очищаем отображение способностей
		if has_node("EnemyHUD/EnemyAbilities"):
			$EnemyHUD/EnemyAbilities.text = ""
		return
	
	# Используем элемент EnemyAbilities из сцены
	if has_node("EnemyHUD/EnemyAbilities"):
		var ability_label = $EnemyHUD/EnemyAbilities
		
		# Проверяем, может ли враг использовать способность
		var can_use = enemy_ability.can_use(enemy)
		var cost_text = ""
		if enemy_ability.mp_cost > 0:
			cost_text += "ОМ: %d" % enemy_ability.mp_cost
		if enemy_ability.stamina_cost > 0:
			if cost_text != "":
				cost_text += ", "
			cost_text += "ОВ: %d" % enemy_ability.stamina_cost
		
		# Устанавливаем текст и стиль
		if can_use:
			ability_label.text = "%s (%s)" % [enemy_ability.name, cost_text]
			ability_label.modulate = Color(0.0, 1.0, 0.0, 1.0)  # Зеленый цвет
		else:
			ability_label.text = "%s (недоступно)" % enemy_ability.name
			ability_label.modulate = Color(1.0, 0.5, 0.0, 1.0)  # Оранжевый цвет

func _show_player_passives() -> void:
	"""Показывает окно пассивных способностей игрока"""
	# Временно используем простое диалоговое окно
	# TODO: Восстановить загрузку полноценного окна когда проблема будет решена
	print("Используем простое диалоговое окно для пассивных способностей")
	_show_simple_passives_dialog()

func _on_passive_window_closed() -> void:
	"""Обрабатывает закрытие окна пассивных способностей"""
	print("Окно пассивных способностей закрыто")

func _show_simple_passives_dialog() -> void:
	"""Показывает простое диалоговое окно с пассивными способностями"""
	# Получаем данные игрока
	var player_manager = get_node_or_null("/root/PlayerManager")
	if not player_manager:
		_show_message("PlayerManager не найден")
		return
	
	var player_data = player_manager.get_player_data()
	if not player_data:
		_show_message("Данные игрока не найдены")
		return
	
	# Инициализируем систему пассивных способностей
	player_data.initialize_passive_system()
	
	# Изучаем базовые способности если еще не изучены
	var learned_passives = player_data.get_learned_passives()
	if learned_passives.size() == 0:
		var abilities_to_learn = ["player_fortress", "player_strong", "player_wise", "player_vitality"]
		for ability_id in abilities_to_learn:
			player_data.learn_passive_ability(ability_id)
		print("Базовые способности изучены!")
	
	# Получаем активные способности
	var active_passives = player_data.get_active_passives()
	
	# Создаем текст с информацией
	var dialog_text = "=== ПАССИВНЫЕ СПОСОБНОСТИ ИГРОКА ===\n\n"
	dialog_text += "Изученных способностей: " + str(learned_passives.size()) + "\n"
	dialog_text += "Активных способностей: " + str(active_passives.size()) + "\n\n"
	
	if active_passives.size() > 0:
		dialog_text += "Активные способности:\n"
		for passive_id in active_passives:
			var ability = player_data.get_passive_ability_info(passive_id)
			if ability:
				# Получаем уровень способности у игрока
				var ability_level = player_data.get_passive_ability_level(passive_id)
				var detailed_description = _get_detailed_ability_description(ability, ability_level)
				
				dialog_text += "• " + ability.name + " (ур. " + str(ability_level) + ") - " + detailed_description + "\n"
	else:
		dialog_text += "Нет активных способностей.\n"
		dialog_text += "Используйте главное меню для управления способностями.\n"
	
	dialog_text += "\n=== УПРАВЛЕНИЕ ===\n"
	dialog_text += "Для управления пассивными способностями:\n"
	dialog_text += "1. Вернитесь в главное меню\n"
	dialog_text += "2. Нажмите 'Пассивные способности'\n"
	dialog_text += "3. Активируйте нужные способности\n"
	
	# Создаем диалоговое окно
	var dialog = AcceptDialog.new()
	dialog.title = "Пассивные способности игрока"
	dialog.size = Vector2(500, 400)
	
	# Создаем основной контейнер
	var main_container = VBoxContainer.new()
	main_container.add_theme_constant_override("separation", 10)
	dialog.add_child(main_container)
	
	# Добавляем заголовок
	var title_label = Label.new()
	title_label.text = "Активные пассивные способности"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 16)
	main_container.add_child(title_label)
	
	# Добавляем информацию
	var info_label = Label.new()
	info_label.text = "Активно: " + str(active_passives.size()) + " из " + str(learned_passives.size())
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(info_label)
	
	# Добавляем разделитель
	var separator = HSeparator.new()
	main_container.add_child(separator)
	
	# Добавляем текст с активными способностями
	var text_label = Label.new()
	text_label.text = dialog_text
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.add_child(text_label)
	
	# Добавляем к сцене
	add_child(dialog)
	
	# Показываем в центре экрана
	dialog.popup_centered()
	
	# Подключаем сигнал закрытия
	dialog.connect("confirmed", Callable(dialog, "queue_free"))
	dialog.connect("canceled", Callable(dialog, "queue_free"))

func _update_enemy_overhead_ui():
	"""Обновляет UI над ВСЕМИ врагами (имя, HP бар)"""
	# Обновляем UI для каждого врага
	for i in range(enemies.size()):
		var current_enemy = enemies[i]
		if not is_instance_valid(current_enemy):
			# Удаляем UI если враг недоступен
			var overhead_container = get_node_or_null("EnemyOverheadUI_" + str(i))
			if overhead_container:
				overhead_container.queue_free()
			continue
		
		# Создаем UI для этого врага
		_create_enemy_overhead_ui(current_enemy, i)
	
	# Удаляем UI для врагов, которых больше нет
	for i in range(enemies.size(), 3):  # Максимум 3 врага
		var overhead_container = get_node_or_null("EnemyOverheadUI_" + str(i))
		if overhead_container:
			overhead_container.queue_free()

func _create_enemy_overhead_ui(current_enemy: Node2D, index: int):
	"""Создает UI над конкретным врагом"""
	var container_name = "EnemyOverheadUI_" + str(index)
	
	# Получаем или создаем контейнер для UI над врагом
	var overhead_container = get_node_or_null(container_name)
	if not overhead_container or not is_instance_valid(overhead_container) or not overhead_container.is_inside_tree():
		if overhead_container and is_instance_valid(overhead_container):
			overhead_container.queue_free()
		
		overhead_container = Control.new()
		overhead_container.name = container_name
		overhead_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overhead_container.z_index = 10  # Уменьшено с 100, чтобы имена врагов были позади окна победы
		add_child(overhead_container)
	
	# Позиционируем контейнер над врагом
	var enemy_position = current_enemy.global_position
	overhead_container.position = enemy_position + Vector2(-100, -150)  # Смещение вверх и по центру
	
	# Очищаем старые элементы
	for child in overhead_container.get_children():
		overhead_container.remove_child(child)
		child.queue_free()
	
	# === ВЕРТИКАЛЬНЫЙ КОНТЕЙНЕР ===
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	overhead_container.add_child(vbox)
	
	# === ЗОЛОТАЯ ЗВЕЗДА ДЛЯ ЭЛИТНЫХ ВРАГОВ ===
	if current_enemy.rarity.begins_with("elite_"):
		var star_label = Label.new()
		star_label.text = "⭐"  # Золотая звезда
		star_label.add_theme_font_size_override("font_size", 32)  # Увеличено с 20 до 32
		star_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0, 1.0))  # Золотой цвет
		star_label.add_theme_color_override("font_outline_color", Color.BLACK)
		star_label.add_theme_constant_override("outline_size", 3)  # Увеличена обводка с 2 до 3
		star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		# Добавляем тень для большей заметности
		star_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
		star_label.add_theme_constant_override("shadow_offset_x", 2)
		star_label.add_theme_constant_override("shadow_offset_y", 2)
		vbox.add_child(star_label)
	
	# === ИМЯ (БЕЗ РЕДКОСТИ) ===
	var name_label = Label.new()
	name_label.text = str(current_enemy.display_name) + " (ур. " + str(current_enemy.level) + ")"
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", _get_rarity_color(current_enemy.rarity))
	name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	name_label.add_theme_constant_override("outline_size", 2)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)
	
	# === HP БАР С ТЕКСТОМ ВНУТРИ ===
	# Контейнер для HP бара с наложенным текстом
	var hp_container = Control.new()
	hp_container.custom_minimum_size = Vector2(200, 25)
	vbox.add_child(hp_container)
	
	# HP бар
	var hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(200, 25)
	hp_bar.size = Vector2(200, 25)
	hp_bar.max_value = current_enemy.max_hp
	hp_bar.value = current_enemy.hp
	hp_bar.show_percentage = false
	hp_bar.modulate = Color(1.0, 0.3, 0.3, 1.0)  # Красный цвет
	hp_container.add_child(hp_bar)
	
	# Барьер-бар (белый полупрозрачный, поверх HP бара)
	var barrier_bar = ProgressBar.new()
	barrier_bar.name = "BarrierBar"
	barrier_bar.custom_minimum_size = Vector2(200, 25)
	barrier_bar.size = Vector2(200, 25)
	barrier_bar.max_value = current_enemy.max_hp
	barrier_bar.value = 0
	barrier_bar.show_percentage = false
	barrier_bar.z_index = hp_bar.z_index + 1  # Поверх HP бара
	barrier_bar.visible = false
	hp_container.add_child(barrier_bar)
	
	# Текст HP поверх бара (поверх барьера тоже)
	var hp_text = Label.new()
	var settings_manager = get_node_or_null("/root/SettingsManager")
	if settings_manager and settings_manager.get_health_display_mode():
		# Процентное отображение
		var hp_percent = int((float(current_enemy.hp) / float(current_enemy.max_hp)) * 100)
		hp_text.text = str(hp_percent) + "%"
	else:
		# Абсолютное отображение
		hp_text.text = str(current_enemy.hp) + " / " + str(current_enemy.max_hp)
	
	hp_text.add_theme_font_size_override("font_size", 14)
	hp_text.add_theme_color_override("font_color", Color.WHITE)
	hp_text.add_theme_color_override("font_outline_color", Color.BLACK)
	hp_text.add_theme_constant_override("outline_size", 2)
	hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_text.size = Vector2(200, 25)
	hp_text.position = Vector2(0, 0)
	hp_text.z_index = barrier_bar.z_index + 1  # Поверх барьера
	hp_container.add_child(hp_text)
	
	# === ИНДИКАТОР ВЫБОРА ЦЕЛИ ===
	# Показываем стрелку над выбранным врагом (проверяем по ссылке, а не по индексу)
	if selected_enemy and is_instance_valid(selected_enemy) and current_enemy == selected_enemy and current_enemy.hp > 0:
		var arrow_label = Label.new()
		arrow_label.text = "▼"  # Стрелка вниз
		arrow_label.add_theme_font_size_override("font_size", 24)
		arrow_label.add_theme_color_override("font_color", Color.YELLOW)
		arrow_label.add_theme_color_override("font_outline_color", Color.BLACK)
		arrow_label.add_theme_constant_override("outline_size", 2)
		arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(arrow_label)
		vbox.move_child(arrow_label, 0)  # Перемещаем в начало (над именем)

func highlight_selected_target(target_index: int):
	"""Подсвечивает выбранную цель (deprecated - используйте highlight_selected_target_enemy)"""
	selected_enemy_index = target_index
	# UI обновится автоматически в _process()

func highlight_selected_target_enemy(target_enemy: Node2D):
	"""Подсвечивает выбранную цель по ссылке на врага"""
	selected_enemy = target_enemy
	# Обновляем индекс для обратной совместимости
	if target_enemy and is_instance_valid(target_enemy):
		var found_index = enemies.find(target_enemy)
		if found_index != -1:
			selected_enemy_index = found_index
	# UI обновится автоматически в _process()

func _hide_battle_ui():
	"""Скрывает все UI элементы боя (HP бары врагов, индикаторы брони и т.д.)"""
	# Скрываем HP бары над врагами
	for i in range(3):  # Максимум 3 врага
		var overhead_container = get_node_or_null("EnemyOverheadUI_" + str(i))
		if overhead_container and is_instance_valid(overhead_container):
			overhead_container.visible = false
	
	# Скрываем индикаторы брони и магического сопротивления игрока
	var player_stats = get_node_or_null("PlayerDefensiveStats")
	if player_stats and is_instance_valid(player_stats):
		player_stats.visible = false
	
	# Скрываем индикаторы брони и магического сопротивления врага
	var enemy_stats = get_node_or_null("EnemyDefensiveStats")
	if enemy_stats and is_instance_valid(enemy_stats):
		enemy_stats.visible = false
	
	# Скрываем основные HP/MP/Stamina бары игрока (если они есть)
	var health_bars = get_node_or_null("HealthBars")
	if health_bars and is_instance_valid(health_bars):
		health_bars.visible = false
	
	# Скрываем индикатор очков действий
	var ap_label = get_node_or_null("HealthBars/PlayerActionPoints")
	if ap_label and is_instance_valid(ap_label):
		ap_label.visible = false
	
	# Скрываем PlayerHUD (если есть)
	var player_hud = get_node_or_null("PlayerHUD")
	if player_hud and is_instance_valid(player_hud):
		player_hud.visible = false
	
	# Скрываем EnemyHUD (если есть)
	var enemy_hud = get_node_or_null("EnemyHUD")
	if enemy_hud and is_instance_valid(enemy_hud):
		enemy_hud.visible = false

func _show_battle_ui():
	"""Показывает все UI элементы боя"""
	# Показываем HP бары над врагами
	for i in range(3):  # Максимум 3 врага
		var overhead_container = get_node_or_null("EnemyOverheadUI_" + str(i))
		if overhead_container and is_instance_valid(overhead_container):
			overhead_container.visible = true
	
	# Показываем индикаторы брони и магического сопротивления игрока
	var player_stats = get_node_or_null("PlayerDefensiveStats")
	if player_stats and is_instance_valid(player_stats):
		player_stats.visible = true
	
	# Показываем индикаторы брони и магического сопротивления врага
	var enemy_stats = get_node_or_null("EnemyDefensiveStats")
	if enemy_stats and is_instance_valid(enemy_stats):
		enemy_stats.visible = true
	
	# Показываем основные HP/MP/Stamina бары игрока (если они есть)
	var health_bars = get_node_or_null("HealthBars")
	if health_bars and is_instance_valid(health_bars):
		health_bars.visible = true
	
	# Показываем индикатор очков действий
	var ap_label = get_node_or_null("HealthBars/PlayerActionPoints")
	if ap_label and is_instance_valid(ap_label):
		ap_label.visible = true
	
	# Показываем PlayerHUD (если есть)
	var player_hud = get_node_or_null("PlayerHUD")
	if player_hud and is_instance_valid(player_hud):
		player_hud.visible = true
	
	# Показываем EnemyHUD (если есть)
	var enemy_hud = get_node_or_null("EnemyHUD")
	if enemy_hud and is_instance_valid(enemy_hud):
		enemy_hud.visible = true

# scripts/battle/battle_manager.gd
extends Control

# Импортируем класс PassiveAbility для использования его типов
const PassiveAbilityClass = preload("res://Scripts/PassiveAbilities/PassiveAbility.gd")
# Загружаем сцены снарядов для визуальных эффектов
const MagicArrowProjectileScene = preload("res://Scenes/Battle/MagicArrowProjectile.tscn")
const SpiritualStrikeProjectileScene = preload("res://Scenes/Battle/SpiritualStrikeProjectile.tscn")

@onready var player_node = $GameWorld/PlayerBody
@onready var enemy_spawner = $GameWorld/EnemySpawner
@onready var enemy_container = $GameWorld/EnemyContainer
@onready var ui = $UI
@onready var camera = $GameWorld/Camera2D

# === СИСТЕМА МНОЖЕСТВЕННЫХ ВРАГОВ ===
var enemy_nodes: Array[Node2D] = []  # Массив всех врагов в бою
var current_enemy_turn_index: int = 0  # Индекс врага, который сейчас ходит
var enemies_acted_count: int = 0  # Количество врагов, которые уже сходили в текущей фазе
var selected_target_index: int = 0  # Индекс выбранной цели для атаки игрока
var selected_target_enemy: Node2D = null  # Ссылка на выбранного врага (для сохранения между раундами)

# Обратная совместимость (deprecated, используйте enemy_nodes[0])
var enemy_node: Node2D:
	get:
		return enemy_nodes[0] if enemy_nodes.size() > 0 else null
	set(value):
		if enemy_nodes.size() == 0:
			enemy_nodes.append(value)
		else:
			enemy_nodes[0] = value

var player_manager: Node
var battle_log: BattleLog
var player_abilities: PlayerAbilities
var soul_shard_manager: Node
var soul_particle_manager  # SoulParticleManager (без типизации для Godot 4.5)
var enemy_abilities: EnemyAbilities
var ability_animation_manager: AbilityAnimationManager  # Менеджер анимаций способностей
var ability_effect_manager: AbilityEffectManager  # Универсальный менеджер эффектов способностей
var current_round: int = 0 # текущий раунд
var round_phase: String = "player" # фаза раунда: "player" или "enemy"

signal battle_ended(victory: bool)

var state: String = "player_turn" # player_turn / enemy_turn / waiting
var message_timer: Timer

func _ready():
	# Получаем менеджер игрока (теперь он должен быть автозагрузкой)
	player_manager = get_node_or_null("/root/PlayerManager")
	if not player_manager:
		print("ОШИБКА: PlayerManager не найден! Убедитесь, что он настроен как автозагрузка.")
		return
	
	# Получаем менеджер осколков душ (опционально)
	soul_shard_manager = get_node_or_null("/root/SoulShard")
	if not soul_shard_manager:
		print("ПРЕДУПРЕЖДЕНИЕ: SoulShard не найден! Осколки душ будут недоступны.")
		# Не прерываем выполнение, продолжаем без системы осколков душ
	
	# Добавляем PlayerBody в группу "player" для синхронизации
	player_node.add_to_group("player")
	
	# Синхронизируем характеристики из инспектора в глобальный менеджер
	_sync_inspector_to_global()
	
	# Синхронизируем данные игрока
	_sync_player_data()
	
	# Инициализируем менеджер всплывающих цифр урона
	_initialize_damage_number_manager()
	
	# Инициализируем менеджер частиц душ (динамическая загрузка для Godot 4.5)
	var soul_particle_script = load("res://Scripts/Battle/SoulParticleManager.gd")
	soul_particle_manager = Node.new()
	soul_particle_manager.set_script(soul_particle_script)
	soul_particle_manager.name = "SoulParticleManager"
	add_child(soul_particle_manager)
	
	# Устанавливаем правильное позиционирование для игрока
	var player_visual = player_node.get_node_or_null("Visual")
	if player_visual:
		player_visual.offset = Vector2(0, 0)  # Без смещения
	
	# Инициализируем пассивные способности
	_initialize_passive_abilities()
	
	# Пересчитываем бонусы восстановления души перед боем
	var soul_restoration_manager = get_node_or_null("/root/SoulRestorationManager")
	if soul_restoration_manager:
		soul_restoration_manager.recalculate_bonuses_from_learned_abilities()
	
	# Создаем таймер для сообщений
	message_timer = Timer.new()
	message_timer.wait_time = 2.0  # 2 секунды отображения
	message_timer.one_shot = true
	add_child(message_timer)
	
	# Инициализируем лог боя
	battle_log = BattleLog.new()
	add_child(battle_log)
	battle_log.start_battle()
	
	# Инициализируем менеджер анимаций способностей
	ability_animation_manager = AbilityAnimationManager.new()
	add_child(ability_animation_manager)
	
	# Инициализируем универсальный менеджер эффектов способностей
	ability_effect_manager = AbilityEffectManager.new()
	add_child(ability_effect_manager)
	# Передаем ссылку на менеджер анимаций
	ability_effect_manager.set_animation_manager(ability_animation_manager)
	
	# Инициализируем способности врагов
	enemy_abilities = EnemyAbilities.new()
	
	# Инициализируем способности игрока
	player_abilities = PlayerAbilities.new()
	player_abilities._initialize_abilities()  # Принудительно инициализируем
	
	# Проверяем глобальные переменные тестового режима
	_check_global_test_variables()
	
	# Спавним врага в зависимости от режима
	if test_mode:
		print("Тестовый режим: спавним тестового врага...")
		spawn_enemy()
	else:
		spawn_enemy()
	
	# подключаем сигналы
	player_node.connect("died", Callable(self, "_on_player_died"))
	player_node.connect("attacked", Callable(self, "_on_player_attacked"))
	
	# Активируем пассивные способности в начале боя
	_activate_passive_abilities()
	
	# Начинаем первый раунд
	start_new_round()
	
	_set_player_turn()
	
	# Инициализируем боевую музыку
	_initialize_battle_music()
	
	# Инициализируем UI слотов способностей
	_initialize_ability_slots_ui()
	
	# Счетчик осколков душ за забег сбрасывается только в начале нового забега
	# (в MainMenu.gd при нажатии "Новая игра")

func _input(event: InputEvent):
	"""Обрабатывает ввод для переключения целей"""
	# Переключение целей только во время хода игрока
	if state != "player_turn":
		return
	
	# Проверяем, есть ли несколько врагов
	if get_alive_enemy_count() <= 1:
		return
	
	# Q или стрелка влево - предыдущая цель
	if event.is_action_pressed("ui_left") or (event is InputEventKey and event.pressed and event.keycode == KEY_Q):
		select_previous_target()
		get_viewport().set_input_as_handled()
	
	# E или стрелка вправо - следующая цель
	elif event.is_action_pressed("ui_right") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		select_next_target()
		get_viewport().set_input_as_handled()
	
	# Цифры 1-3 для быстрого выбора цели по позиции (1 = ближайший, 2 = второй, 3 = третий)
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				select_target_by_position(1)  # Ближайший враг
				get_viewport().set_input_as_handled()
			KEY_2:
				select_target_by_position(2)  # Второй враг
				get_viewport().set_input_as_handled()
			KEY_3:
				select_target_by_position(3)  # Третий враг
				get_viewport().set_input_as_handled()

func _activate_passive_abilities():
	"""Активирует пассивные способности в начале боя"""
	# Активируем пассивные способности игрока
	if player_node:
		player_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.PASSIVE, null, {})
	
	# Активируем пассивные способности ВСЕХ врагов
	for enemy in enemy_nodes:
		if is_instance_valid(enemy):
			enemy.trigger_passive_abilities(PassiveAbilityClass.TriggerType.PASSIVE, null, {})

func start_new_round():
	"""Начинает новый раунд"""
	current_round += 1
	round_phase = "player"
	
	# Сбрасываем счетчики раунда для игрока
	if player_node and player_node.has_method("reset_round_counters"):
		player_node.reset_round_counters(current_round)
		
	# Сбрасываем счетчики раунда для ВСЕХ врагов
	for enemy in enemy_nodes:
		if is_instance_valid(enemy) and enemy.has_method("reset_round_counters"):
			enemy.reset_round_counters(current_round)
	
	# Уменьшаем кулдауны изученных способностей
	if AbilitySlotManager:
		AbilitySlotManager.reduce_cooldowns()
		_update_ability_slots_ui()
	
	# Снимаем эффект защиты в начале нового раунда
	if player_node and player_node.has_effect("defend"):
		player_node.remove_effect("defend")
	
	# Логируем начало раунда
	if battle_log:
		battle_log.next_round()
	

func spawn_enemy():
	"""Спавнит одного врага (обратная совместимость)"""
	# Определяем количество врагов на основе сложности
	var enemy_count = _determine_enemy_count()
	spawn_enemies(enemy_count)

func spawn_enemies(count: int = 1):
	"""Спавнит несколько врагов (новая система)"""
	# Синхронизируем данные игрока перед каждым боем
	if player_node:
		_sync_player_data()
	else:
		print("ОШИБКА: player_node не найден!")
	
	# Удаляем старых врагов если есть
	for old_enemy in enemy_nodes:
		if is_instance_valid(old_enemy):
			old_enemy.queue_free()
	enemy_nodes.clear()
	
	# Получаем споты для врагов
	var spots = [
		enemy_container.get_node_or_null("EnemySpot1"),
		enemy_container.get_node_or_null("EnemySpot2"),
		enemy_container.get_node_or_null("EnemySpot3")
	]
	
	# Проверяем, находимся ли мы в тестовом режиме
	if test_mode and test_enemy_scene != "":
		_spawn_test_enemy()
		if enemy_nodes.size() == 0:
			return
	else:
		# Обычный режим - спавним врагов
		if not enemy_spawner:
			print("ОШИБКА: enemy_spawner не найден!")
			return
		
		# Ограничиваем количество врагов до 3
		count = mini(count, 3)
		
		# Получаем PassiveAbilityManager для добавления пассивок
		var passive_manager = get_node_or_null("/root/PassiveAbilityManager")
		
		# Спавним врагов
		# Элитные враги теперь появляются случайно через логику в enemy_spawner
		# Используем детерминированный индекс для одинакового результата
		for i in range(count):
			var enemy = enemy_spawner.spawn_random_enemy(false, i)
			if not enemy:
				print("ОШИБКА: Не удалось создать врага #" + str(i + 1))
				continue
			
			# Добавляем врага в контейнер
			enemy_container.add_child(enemy)
			enemy_nodes.append(enemy)
			
			# Подключаем сигналы врага
			enemy.connect("died", Callable(self, "_on_enemy_died"))
			enemy.connect("attacked", Callable(self, "_on_enemy_attacked"))
			
			# === ДОБАВЛЯЕМ ПАССИВНЫЕ СПОСОБНОСТИ ===
			if passive_manager:
				_add_enemy_passives(enemy, passive_manager)
			
			# Применяем элитные бонусы если враг элитный
			if enemy.has_method("apply_elite_bonuses"):
				enemy.apply_elite_bonuses()
			
			# Восстанавливаем HP/MP/Stamina до полных значений после применения пассивных способностей
			enemy.hp = enemy.max_hp
			enemy.mp = enemy.max_mp
			enemy.stamina = enemy.max_stamina
			
			# Позиционируем врага
			if spots[i]:
				enemy.position = spots[i].position
				
				# Специальная позиция для крысы - она выше других спрайтов
				if enemy.display_name == "Крыса":
					enemy.position.y += 50  # Опускаем крысу ниже
			else:
				# Fallback позиции
				enemy.position = Vector2(1200 + i * 200, 730)
			
			# Устанавливаем масштаб врага
			# Орки уменьшены на 20% (3 * 0.8 = 2.4)
			if enemy.display_name.begins_with("Орк"):
				enemy.scale = Vector2(2.4, 2.4)
			else:
				enemy.scale = Vector2(3, 3)
			
			# Поворачиваем врага лицом к игроку (отражаем по горизонтали)
			var enemy_visual = enemy.get_node_or_null("Visual")
			if enemy_visual:
				enemy_visual.flip_h = true  # Отражаем спрайт по горизонтали
		
		# После спавна всех врагов, проигрываем анимации выкапывания одновременно для скелетов
		var skeleton_visuals = []
		for enemy in enemy_nodes:
			var enemy_visual = enemy.get_node_or_null("Visual")
			if enemy_visual:
				var enemy_name = enemy.display_name if "display_name" in enemy else ""
				if enemy_name in ["Скелет Арбалетчик", "Скелет Мечник", "Элитный Скелет"]:
					if enemy_visual.has_method("has_animation") and enemy_visual.has_animation("dig_out"):
						# Останавливаем текущую анимацию (если есть)
						if enemy_visual.has_method("stop"):
							enemy_visual.stop()
						# Добавляем в список для одновременного запуска
						skeleton_visuals.append(enemy_visual)
		
		# Запускаем анимации выкапывания одновременно для всех скелетов
		if skeleton_visuals.size() > 0:
			# Запускаем все анимации одновременно
			for visual in skeleton_visuals:
				if visual.has_method("play"):
					visual.play("dig_out")
			
			# Ждем завершения анимации (все должны завершиться примерно одновременно)
			if skeleton_visuals.size() > 0:
				await skeleton_visuals[0].animation_finished
			
			# Переключаем всех скелетов на idle одновременно
			for visual in skeleton_visuals:
				if visual.has_method("play_idle"):
					visual.play_idle()
				elif visual.has_method("play"):
					visual.play("idle")
	
	# Инициализируем выбор первой цели (только при спавне, не между раундами!)
	selected_target_index = 0
	if enemy_nodes.size() > 0:
		selected_target_enemy = enemy_nodes[0]  # Устанавливаем первого врага как цель
	else:
		selected_target_enemy = null
	current_enemy_turn_index = -1  # Начнем с -1, чтобы первый вызов get_next_enemy_for_turn() вернул индекс 0
	enemies_acted_count = 0  # Сбрасываем счетчик сходивших врагов
	
	# Обновляем редкость и описание комнаты на основе самого редкого врага
	_update_room_rarity_and_description()
	
	# Обновляем UI контроллер с массивом врагов
	if ui.has_method("set_enemies"):
		ui.set_enemies(enemy_nodes)
	elif ui.has_method("set_enemy") and enemy_nodes.size() > 0:
		# Fallback для обратной совместимости
		ui.set_enemy(enemy_nodes[0])
	
	# Обновляем подсветку выбранной цели
	if selected_target_enemy and ui.has_method("highlight_selected_target_enemy"):
		ui.highlight_selected_target_enemy(selected_target_enemy)
	elif ui.has_method("highlight_selected_target"):
		ui.highlight_selected_target(selected_target_index)

func _determine_enemy_count() -> int:
	"""Определяет количество врагов на основе сложности локации"""
	var player_data = player_manager.get_player_data() if player_manager else null
	if not player_data:
		return 1  # По умолчанию 1 враг
	
	# Получаем текущую локацию и сложность
	var location_manager = get_node_or_null("/root/LocationManager")
	if not location_manager or not location_manager.current_location:
		return 1
	
	var current_location_id = location_manager.current_location.location_id
	var difficulty = player_data.get_selected_difficulty(current_location_id)
	
	# Проверяем, это босс-комната
	var room_generator = get_node_or_null("/root/RoomGenerator")
	var current_room = null
	if room_generator:
		current_room = room_generator.get_current_room()
	
	var is_boss_room = false
	if current_room and current_room.room_type == RoomData.RoomType.BOSS:
		is_boss_room = true
	
	# Боссы
	if is_boss_room:
		match difficulty:
			1: return 1  # Босс один
			2: return 2  # Босс + 1 спутник
			3: return 3  # Босс + 2 спутника
			_: return 1
	
	# Обычные комнаты - используем детерминированный seed на основе названия комнаты
	# ТОЧНО ТАКОЙ ЖЕ seed, как в RoomSelector._get_enemy_count_for_room()
	
	if current_room:
		# Используем детерминированный seed на основе названия комнаты
		var seed_value = current_room.room_name.hash()  # Используем hash названия комнаты как seed
		seed(seed_value)
	
	var count = 1
	match difficulty:
		1:  # Легко: 70% - 1 враг, 30% - 2 врага
			count = 2 if randf() < 0.3 else 1
		2:  # Средне: 20% - 1, 60% - 2, 20% - 3
			var roll = randf()
			if roll < 0.2:
				count = 1
			elif roll < 0.8:
				count = 2
			else:
				count = 3
		3:  # Сложно: 10% - 1, 20% - 2, 70% - 3
			var roll = randf()
			if roll < 0.1:
				count = 1
			elif roll < 0.3:
				count = 2
			else:
				count = 3
		_:
			count = 1
	
	# Восстанавливаем состояние генератора случайных чисел
	if current_room:
		randomize()
	
	return count

func _update_room_rarity_and_description():
	"""Обновляет редкость и описание комнаты на основе самого редкого врага"""
	if enemy_nodes.size() == 0:
		return
	
	# Получаем RoomGenerator
	var room_generator = get_node_or_null("/root/RoomGenerator")
	if not room_generator:
		return
	
	var current_room = room_generator.get_current_room()
	if not current_room:
		return
	
	# Для босс-комнат НЕ обновляем редкость (она уже задана)
	if current_room.room_type == RoomData.RoomType.BOSS:
		return
	
	# Находим самого редкого врага
	var rarest_enemy = _get_rarest_enemy()
	if not rarest_enemy:
		return
	
	var rarest_rarity = rarest_enemy.rarity
	
	# Обновляем редкость комнаты
	current_room.enemy_rarity = rarest_rarity
	
	# Обновляем название комнаты
	if room_generator.has_method("_get_battle_room_name"):
		current_room.room_name = room_generator._get_battle_room_name(rarest_rarity)
	
	# Обновляем описание комнаты
	if room_generator.has_method("_get_battle_room_description_with_rarity"):
		current_room.description = room_generator._get_battle_room_description_with_rarity(rarest_rarity)
	else:
		# Fallback описание
		var rarity_name = _get_rarity_display_name(rarest_rarity)
		if rarest_rarity.begins_with("elite_"):
			current_room.description = "Здесь обитает " + rarity_name + " Элитный враг! Будьте осторожны!"
		else:
			current_room.description = "Здесь обитает " + rarity_name + " враг."

func _get_rarest_enemy() -> Node2D:
	"""Возвращает самого редкого врага из массива enemy_nodes"""
	if enemy_nodes.size() == 0:
		return null
	
	var rarest_enemy = enemy_nodes[0]
	var highest_priority = _get_rarity_priority(rarest_enemy.rarity)
	
	for enemy in enemy_nodes:
		if not is_instance_valid(enemy):
			continue
		
		var priority = _get_rarity_priority(enemy.rarity)
		if priority > highest_priority:
			highest_priority = priority
			rarest_enemy = enemy
	
	return rarest_enemy

func _get_rarity_priority(rarity: String) -> int:
	"""Возвращает приоритет редкости (чем выше, тем реже)"""
	match rarity.to_lower():
		"common":
			return 1
		"uncommon":
			return 2
		"rare":
			return 3
		"epic":
			return 4
		"legendary":
			return 5
		"mythic":
			return 6
		"boss":
			return 7
		"elite_rare":
			return 4  # Элитный rare = между epic и legendary
		"elite_epic":
			return 5  # Элитный epic = между legendary и mythic
		"elite_legendary":
			return 6  # Элитный legendary = между mythic и boss
		_:
			return 0

func _get_rarity_display_name(rarity: String) -> String:
	"""Возвращает отображаемое имя редкости"""
	match rarity.to_lower():
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
		"elite_rare":
			return "Элитный Редкий"
		"elite_epic":
			return "Элитный Эпический"
		"elite_legendary":
			return "Элитный Легендарный"
		_:
			return "Неизвестный"

func _sync_inspector_to_global():
	# НЕ синхронизируем из инспектора в глобальный менеджер!
	# Глобальный менеджер - это источник истины, а не инспектор
	
	# Проверяем, что глобальный менеджер существует
	if not player_manager:
		print("ОШИБКА: player_manager не найден!")
		return
	
	if not player_manager.has_method("get_player_data"):
		print("ОШИБКА: player_manager не имеет метода get_player_data!")
		return
	
	var player_data = player_manager.get_player_data()
	if not player_data:
		print("ОШИБКА: player_data не найден!")
		return
	

func _sync_player_data():
	# Синхронизируем данные из глобального менеджера в локальный узел игрока
	if not player_manager:
		print("ОШИБКА: player_manager не найден!")
		return
	
	if not player_manager.has_method("get_player_data"):
		print("ОШИБКА: player_manager не имеет метода get_player_data!")
		return
	
	var player_data = player_manager.get_player_data()
	if not player_data:
		print("ОШИБКА: player_data не найден!")
		return
	if not player_node:
		print("ОШИБКА: player_node не найден!")
		return
	
	# Синхронизируем активные пассивные способности с бонусами
	player_data.sync_active_passives_with_bonuses()
	
	# Проверяем активные пассивные способности
	# active_passives больше не используется после удаления отладки
	
	# Синхронизируем характеристики из глобального менеджера в локальный узел
	player_node.strength = player_data.strength
	player_node.agility = player_data.agility
	player_node.vitality = player_data.vitality
	player_node.endurance = player_data.endurance
	player_node.intelligence = player_data.intelligence
	player_node.wisdom = player_data.wisdom
	player_node.level = player_data.level
	
	# Пересчитываем бонусы
	player_node.calculate_stat_bonuses()
	player_node.apply_stat_bonuses()
	
	# Синхронизируем максимальные значения из PlayerData
	player_node.max_hp = player_data.max_hp
	player_node.max_mp = player_data.max_mp
	player_node.max_stamina = player_data.max_stamina
	
	# Применяем активные пассивные способности игрока ПОСЛЕ синхронизации max_hp
	_apply_player_passive_abilities()
	
	# Синхронизируем текущие ресурсы из PlayerData
	# Если это первый бой в забеге (run_soul_shards == 0), восстанавливаем до максимума
	var is_first_battle = false
	if soul_shard_manager:
		is_first_battle = (soul_shard_manager.get_run_soul_shards() == 0)
	
	if is_first_battle:
		# Первый бой в забеге - восстанавливаем до максимума
		player_node.hp = player_node.max_hp
		player_node.mp = player_node.max_mp
		player_node.stamina = player_node.max_stamina
	else:
		# Не первый бой - используем сохраненные значения, но не превышаем максимум
		player_node.hp = min(player_data.current_hp, player_node.max_hp)
		player_node.mp = min(player_data.current_mp, player_node.max_mp)
		player_node.stamina = min(player_data.current_stamina, player_node.max_stamina)

func _save_player_data():
	# Сохраняем данные из локального узла в глобальный менеджер
	if not player_manager:
		print("ОШИБКА: player_manager не найден в _save_player_data!")
		return
	
	if not player_manager.has_method("get_player_data"):
		print("ОШИБКА: player_manager не имеет метода get_player_data в _save_player_data!")
		return
	
	var player_data = player_manager.get_player_data()
	if player_data:
		
		player_data.current_hp = player_node.hp
		player_data.current_mp = player_node.mp
		player_data.current_stamina = player_node.stamina
		player_data.max_hp = player_node.max_hp
		player_data.max_mp = player_node.max_mp
		player_data.max_stamina = player_node.max_stamina
		
		# Сохраняем характеристики
		player_data.strength = player_node.strength
		player_data.agility = player_node.agility
		player_data.vitality = player_node.vitality
		player_data.endurance = player_node.endurance
		player_data.intelligence = player_node.intelligence
		player_data.wisdom = player_node.wisdom
		
		player_manager.save_player_state()

func _initialize_damage_number_manager():
	"""Инициализирует менеджер всплывающих цифр урона"""
	# Создаем DamageNumberManager как дочерний узел
	var damage_manager = Node2D.new()
	damage_manager.name = "DamageNumberManager"
	
	# Загружаем и применяем скрипт
	var script = load("res://Scripts/UI/DamageNumberManager.gd")
	if script:
		damage_manager.set_script(script)
	else:
		print("ОШИБКА: Не удалось загрузить DamageNumberManager.gd")
		return
	
	add_child(damage_manager)

func _set_player_turn():
	state = "player_turn"
	
	# ВАЖНО: Сбрасываем счетчик сходивших врагов при переходе к ходу игрока
	# Это гарантирует, что в следующей фазе врагов все смогут походить
	if round_phase == "enemy":
		enemies_acted_count = 0
		current_enemy_turn_index = -1
	
	# Если это первый ход игрока в новом раунде, начинаем новый раунд
	if current_round == 0 or round_phase == "enemy":
		start_new_round()
	
	round_phase = "player"
	
	# Сбрасываем очки действий в начале хода (только если это новый раунд)
	if not player_node.has_action_points():
		player_node.reset_action_points()
		
		# Проверяем паралич ПЕРЕД другими эффектами
		if player_node.has_effect("paralysis"):
			var ap_reduction = 1
			player_node.action_points = max(0, player_node.action_points - ap_reduction)
			
			if player_node.action_points == 0:
				# Если у игрока не осталось ОД, он пропускает ход
				_show_message("Вы парализованы и пропускаете ход!", 2.0)
				# Удаляем эффект паралича (срабатывает один раз)
				player_node.remove_effect("paralysis")
				await get_tree().create_timer(1.0).timeout
				_set_enemy_turn()
				return
			else:
				_show_message("Вы парализованы! Потеряно 1 очко действий!", 2.0)
				# Удаляем эффект паралича (срабатывает один раз)
				player_node.remove_effect("paralysis")
		
	# Проверяем эффект отнятия ОД
	if player_node.has_effect("action_point_drain"):
		var drain_effect = player_node.effects.get("action_point_drain", {})
		if drain_effect is Dictionary:
			var ap_reduction = drain_effect.get("ap_reduction", 1)
			player_node.action_points = max(0, player_node.action_points - ap_reduction)
			battle_log.log_event("action_point_reduced", "", player_node.display_name, ap_reduction, "Эффект отнятия ОД: у игрока " + str(player_node.action_points) + " ОД вместо обычных!")
			_show_message("У ВАС ТОЛЬКО " + str(player_node.action_points) + " ОЧКО ДЕЙСТВИЙ!", 2.0)
			# Удаляем эффект после применения
			player_node.remove_effect("action_point_drain")
	
	# ✅ ПРОВЕРЯЕМ ОГЛУШЕНИЕ ДО process_effects(), чтобы эффект не успел удалиться!
	if player_node.has_effect("stun"):
		print("🚫 ОГЛУШЕНИЕ АКТИВНО: Игрок пропускает ход!")
		_show_message("Игрок оглушен и пропускает ход!")
		# Обрабатываем эффекты (это удалит stun после 1 хода)
		player_node.process_effects()
		await get_tree().create_timer(1.0).timeout
		_set_enemy_turn()
		return
	
	# Регенерация ресурсов игрока (работает во время боя)
	player_node.regenerate_resources()
	# Обрабатываем эффекты игрока
	player_node.process_effects()
	
	# Активируем способности начала хода игрока для КАЖДОГО врага
	# (важно для способностей типа "Гнилостная аура", которые должны действовать на всех врагов)
	for i in range(enemy_nodes.size()):
		var current_enemy = enemy_nodes[i]
		if is_instance_valid(current_enemy) and not current_enemy.is_dead():
			var context = {"turn_start": true}
			player_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_TURN_START, current_enemy, context)
	
	_show_message("Твой ход")

func _set_enemy_turn():
	"""Начинает фазу хода врагов (все враги ходят по очереди)"""
	state = "enemy_turn"
	round_phase = "enemy"
	
	# Проверяем, есть ли живые враги
	if are_all_enemies_dead():
		_set_player_turn()
		return
	
	# ВАЖНО: Если это ПЕРВЫЙ вызов в новом раунде (enemies_acted_count уже равен get_alive_enemy_count()),
	# значит все враги сходили в предыдущем раунде, и нужно начать заново
	if enemies_acted_count >= get_alive_enemy_count():
		# Все враги уже сходили - сбрасываем счетчик для нового раунда
		enemies_acted_count = 0
		current_enemy_turn_index = -1
		_set_player_turn()
		return
	
	# Получаем следующего врага для хода
	var current_enemy = get_next_enemy_for_turn()
	if not current_enemy:
		# Все враги мертвы или нет врагов
		enemies_acted_count = 0
		current_enemy_turn_index = -1
		_set_player_turn()
		return
	
	# Увеличиваем счетчик сходивших врагов
	enemies_acted_count += 1
	
	# Обрабатываем эффекты текущего врага
	if current_enemy and not current_enemy.is_dead():
		# Сбрасываем очки действий в начале хода
		if not current_enemy.has_action_points():
			current_enemy.reset_action_points()
		
		# Проверяем паралич ПЕРЕД регенерацией ресурсов
		if current_enemy.has_effect("paralysis"):
			# Паралич забирает одно очко действий
			var ap_reduction = 1
			current_enemy.action_points = max(0, current_enemy.action_points - ap_reduction)
			
			if current_enemy.action_points == 0:
				# Если у врага не осталось ОД, он пропускает ход
				_show_message(current_enemy.display_name + " парализован и пропускает ход!")
				# Удаляем эффект паралича (срабатывает один раз)
				current_enemy.remove_effect("paralysis")
				await get_tree().create_timer(1.0).timeout
				await _process_next_enemy_turn()
				return
			else:
				_show_message(current_enemy.display_name + " парализован! Потеряно 1 очко действий!")
				# Удаляем эффект паралича (срабатывает один раз)
				current_enemy.remove_effect("paralysis")
		
		# Регенерация ресурсов врага
		current_enemy.regenerate_resources()
		current_enemy.process_effects()
		
		# ВАЖНО: Проверяем, не умер ли враг от эффектов!
		if current_enemy.is_dead():
			_show_message(current_enemy.display_name + " погиб от эффектов!")
			await get_tree().create_timer(1.0).timeout
			# Переходим к следующему врагу или игроку
			await _process_next_enemy_turn()
			return
		
		# Проверяем оглушение врага
		if current_enemy.has_effect("stun"):
			_show_message(current_enemy.display_name + " оглушен и пропускает ход!")
			await get_tree().create_timer(1.0).timeout
			# Переходим к следующему врагу или игроку
			await _process_next_enemy_turn()
			return
	
	# Активируем пассивные способности врага в начале хода
	if current_enemy and not current_enemy.is_dead():
		# Сбрасываем дополнительное действие
		if current_enemy.has_method("set_extra_action"):
			current_enemy.set_extra_action(false)
		
		# Активируем способности начала хода
		var context = {"turn_start": true, "round_number": current_round}
		current_enemy.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_TURN_START, player_node, context)
	
	# Сбрасываем счетчики урона за раунд ПОСЛЕ срабатывания способностей
	if player_node and player_node.has_method("reset_damage_this_round"):
		player_node.reset_damage_this_round()
	if current_enemy and current_enemy.has_method("reset_damage_this_round"):
		current_enemy.reset_damage_this_round()
	
	_show_message("Ход: " + current_enemy.display_name)
	# Короткая задержка, затем сделать ход врага
	await get_tree().create_timer(0.5).timeout
	
	# Временно устанавливаем текущего врага в enemy_nodes[0] для совместимости с _enemy_action()
	var enemy_index = enemy_nodes.find(current_enemy)
	if enemy_index != -1 and enemy_index != 0:
		# Меняем местами текущего врага с первым в массиве
		var temp = enemy_nodes[0]
		enemy_nodes[0] = enemy_nodes[enemy_index]
		enemy_nodes[enemy_index] = temp
	
	# Вызываем действие врага
	await _enemy_action()

func _process_next_enemy_turn():
	"""Обрабатывает ход следующего врага или переходит к ходу игрока"""
	# Переходим к следующему врагу
	await get_tree().create_timer(0.3).timeout
	_set_enemy_turn()

func player_attack():
	if state != "player_turn":
		return
	
	# Проверяем, есть ли очки действий
	if not player_node.has_action_points():
		_show_message("Нет очков действий!")
		return
	
	# Получаем текущую цель
	var target = get_current_target()
	if not target:
		_show_message("Нет доступных целей!", 1.0)
		return
	
	# Проверяем возможность удара в спину
	var is_backstab = _check_backstab_chance(player_node)
	
	# Расчёт урона с учётом характеристик
	# Базовая атака использует новую систему физического урона
	var damage: int
	if player_node.has_method("get_physical_damage"):
		damage = player_node.get_physical_damage()
	else:
		# Fallback для старой системы
		damage = player_node.strength + player_node.agility
	var is_crit: bool = player_node.is_critical_hit()
	
	# Применяем модификатор удара в спину
	if is_backstab:
		var backstab_multiplier = 1.5  # Базовый множитель
		
		# Проверяем способность "Летальность"
		for ability in player_node.passive_abilities:
			if ability.id == "ninja_lethality":
				backstab_multiplier += 1.0  # +100% урона в спину
				break
		
		damage = int(damage * backstab_multiplier)
	
	# Проверяем проклятие - снижает наносимый урон
	if player_node.has_effect("curse"):
		var curse_effect = player_node.effects.get("curse", {})
		if curse_effect is Dictionary:
			var damage_reduction = curse_effect.get("damage_reduction", 0.0)
			if damage_reduction > 0:
				damage = int(damage * (1.0 - damage_reduction))
	
	if is_crit:
		damage = player_node.get_crit_damage()
		_show_message("КРИТИЧЕСКИЙ УДАР! УРОН: %d" % damage, 2.0)
	else:
		_show_message("Урон: %d" % damage, 1.5)  # Уменьшили время
	
	# Проверяем попадание с учетом меткости и уворота ПЕРЕД применением пассивных способностей
	if not _calculate_hit_chance(player_node, target, "main_attack", "Базовая атака"):
		print("Игрок промахнулся!")
		# Показываем всплывающую цифру промаха
		DamageNumberManager.show_damage_on_character(target, 0, false, true, false, "physical")
		_show_message("Промах!", 1.0)
		# Переходим к ходу врага
		await get_tree().create_timer(0.5).timeout
		_set_enemy_turn()
		return
	
	# Активируем пассивные способности игрока при атаке (только при попадании)
	var context_attack = {"damage": damage, "target": target, "is_backstab": is_backstab, "damage_type": "physical"}
	player_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, target, context_attack)
	
	# Сохраняем информацию об атаке для логирования
	var attack_type = "Обычная атака"
	if is_backstab:
		attack_type = "Удар в спину"
	player_node.set_last_attack_info(damage, "physical", is_crit, attack_type)
	
	# Сохраняем HP цели до нанесения урона для вычисления фактического урона
	var target_old_hp = target.hp
	
	# Наносим урон выбранной цели
	target.take_damage(damage, "physical")
	
	# Вычисляем фактический урон после вычета брони
	var actual_damage = target_old_hp - target.hp
	
	# Показываем всплывающую цифру фактического урона
	DamageNumberManager.show_damage_on_character(target, actual_damage, is_crit, false, false, "physical")
	
	# Тряска камеры при критическом ударе игрока
	if is_crit and camera and camera.has_method("shake"):
		camera.shake(0.3, 15.0)  # 0.3 сек, сила 15 пикселей
	
	# Активируем пассивные способности врага ПОСЛЕ нанесения урона
	# Передаем фактический урон в контексте для правильного расчета отражения
	var context_damage = {"damage": actual_damage, "target": target}
	target.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_DAMAGE_TAKEN, player_node, context_damage)
	
	# Проверяем отражение урона (Страж Тарнока)
	_handle_damage_reflection(target, player_node)
	
	# Проверяем дополнительные атаки от пассивных способностей игрока
	_check_extra_attacks(player_node, target, "physical")
	
	# Получаем фактический урон из сигнала attacked
	# Это будет обработано в _on_enemy_attacked
	
	# Проигрываем анимацию атаки параллельно (не ждем)
	var visual = player_node.get_node_or_null("Visual")
	if visual and visual.has_method("play_attack"):
		visual.play_attack()
	
	# Тратим очко действий
	player_node.spend_action_point()
	
	# Проверяем, есть ли еще очки действий
	if player_node.has_action_points():
		_show_message("У вас есть еще одно действие!")
		# Короткая задержка перед следующим действием
		await get_tree().create_timer(0.3).timeout
		# Остаемся в ходу игрока
		return
	else:
		# Короткая задержка перед ходом врага
		await get_tree().create_timer(0.3).timeout
		_set_enemy_turn()

func player_defend():
	"""Обрабатывает действие защиты игрока"""
	if state != "player_turn":
		return
	
	# Проверяем, есть ли очки действий
	if not player_node.has_action_points():
		_show_message("Нет очков действий!")
		return
	
	# Активируем защиту - добавляем эффект на 1 раунд
	player_node.add_effect("defend", 1.0, 1, {"damage_reduction": 0.5})
	
	# Показываем сообщение
	_show_message("Игрок принимает защитную стойку! Урон уменьшен на 50%", 2.0)
	
	# Логируем действие защиты
	battle_log.log_passive_ability("Игрок", "Защита", true, "принимает защитную стойку!")
	
	# Тратим очко действий
	player_node.spend_action_point()
	
	# Защита всегда заканчивает ход игрока
	await get_tree().create_timer(0.5).timeout
	_set_enemy_turn()

func _apply_rarity_damage_bonus(damage: int, rarity: String) -> int:
	"""Применяет бонус редкости к урону"""
	# Проверяем элитных врагов
	if rarity.begins_with("elite_"):
		var base_rarity = rarity.substr(6)
		match base_rarity:
			"rare":
				return int(damage * 1.35)  # Элитный редкий: 35% бонус
			"epic":
				return int(damage * 1.45)  # Элитный эпический: 45% бонус
			"legendary":
				return int(damage * 1.55)  # Элитный легендарный: 55% бонус
	
	match rarity:
		"uncommon":
			return int(damage * 1.1)  # 10% бонус
		"rare":
			return int(damage * 1.2)  # 20% бонус
		"epic":
			return int(damage * 1.3)  # 30% бонус
		"legendary":
			return int(damage * 1.5)  # 50% бонус
		"boss":
			return int(damage * 1.6)  # 60% бонус
		"mythic":
			return int(damage * 2.0)  # 100% бонус
		_:
			return damage

func _enemy_action():
	if not enemy_node:
		# Враг не найден - переходим к следующему ходу
		if get_alive_enemy_count() > 1:
			await _process_next_enemy_turn()
		else:
			_set_player_turn()
		return
	
	if enemy_node.is_dead():
		# Враг мертв - переходим к следующему ходу
		if get_alive_enemy_count() > 1:
			await _process_next_enemy_turn()
		else:
			_set_player_turn()
		return
	
	if player_node.is_dead():
		# Игрок мертв - заканчиваем бой
		return
	
	# Проверяем, невидим ли игрок
	if player_node.has_effect("stealth"):
		# Пропускаем ход врага
		await get_tree().create_timer(0.5).timeout
		# В режиме множественных врагов переходим к следующему врагу
		if get_alive_enemy_count() > 1:
			await _process_next_enemy_turn()
		else:
			_set_player_turn()
		return
	
	# Уменьшаем кулдауны всех способностей в начале хода врага
	if enemy_node.has_method("reduce_ability_cooldowns"):
		enemy_node.reduce_ability_cooldowns()
	
	# Получаем способность врага
	var enemy_ability = enemy_abilities.get_ability_for_enemy(enemy_node.display_name)
	var damage: int
	var is_crit: bool
	var damage_type: String = "physical"  # Инициализируем как физический урон
	var ability_used: bool = false
	
	# Проверяем, может ли враг использовать способность (есть ресурсы и нет кулдауна)
	var ability_on_cooldown = enemy_node.has_method("is_ability_on_cooldown") and enemy_node.is_ability_on_cooldown(enemy_ability.id)
	
	# Враг использует способность, если есть ресурсы и способность НЕ на кулдауне
	if enemy_ability.can_use(enemy_node) and not ability_on_cooldown:
		# Сохраняем количество маны до использования способности (для ancestral_wisdom)
		var enemy_mana_before = enemy_node.mp if "mp" in enemy_node else 0
		
		# Используем способность
		var result = enemy_ability.use_ability(enemy_node, player_node)
		if result.get("success", false):
			damage = result.get("damage", 0)
			is_crit = result.get("is_crit", false)
			damage_type = result.get("damage_type", "physical")
			ability_used = true
			
			# Вычисляем потраченную ману (для ancestral_wisdom)
			var enemy_mana_after = enemy_node.mp if "mp" in enemy_node else 0
			var enemy_mana_spent = enemy_mana_before - enemy_mana_after
			
			# Активируем пассивные способности врага при использовании способности (ON_ABILITY_USE)
			if enemy_mana_spent > 0 or enemy_ability.stamina_cost > 0:
				var context_ability_use = {
					"ability_id": enemy_ability.id,
					"ability_name": enemy_ability.name,
					"mana_spent": enemy_mana_spent,
					"stamina_spent": enemy_ability.stamina_cost if enemy_ability.stamina_cost > 0 else 0,
					"damage_type": damage_type
				}
				enemy_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ABILITY_USE, player_node, context_ability_use)
			
			# Применяем бонус редкости к урону от способности
			damage = _apply_rarity_damage_bonus(damage, enemy_node.rarity)
			
			# Пассивные способности врага при атаке будут активированы позже
			
			# Активируем пассивные способности игрока ПЕРЕД получением урона
			var context = {"damage": damage, "target": player_node}
			player_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_DAMAGE_TAKEN, enemy_node, context)
			
			# Проверяем попадание с учетом меткости и уворота
			var enemy_ability_name = enemy_ability.name if enemy_ability else "Неизвестная способность"
			
			# Для многоударных способностей не проверяем общий уворот - каждый удар проверяется отдельно
			if not result.get("double_strike", false) and not result.get("executioner_strike", false) and not result.get("crushing_strike", false) and not result.get("crushing_hammer", false) and not result.get("magic_arrows", false) and not result.get("tombstone", false):
				# Для одноударных способностей и массовых атак проигрываем анимацию атаки ДО проверки попадания
				var visual_node = enemy_node.get_node_or_null("Visual")
				if visual_node:
					# Для rat_bite всегда используем стандартную атаку (эффект проигрывается на цели)
					var ability_id = _get_ability_id_from_result(result)
					if ability_id == "rat_bite":
						# Крыса проигрывает стандартную атаку
						if visual_node.has_method("play_attack"):
							visual_node.play_attack()
					elif ability_id != "" and ability_animation_manager and ability_animation_manager.has_animation_for_ability(ability_id):
						# Для других способностей используем специальную анимацию (если есть)
						ability_animation_manager.play_ability_animation(visual_node, ability_id)
					elif visual_node.has_method("play_attack"):
						# Используем стандартную анимацию атаки
						visual_node.play_attack()
				
				if not _calculate_hit_chance(enemy_node, player_node, "main_attack", enemy_ability_name):
					# Показываем всплывающую цифру промаха
					DamageNumberManager.show_damage_on_character(player_node, 0, false, true, false, damage_type)
					
					_show_message("Враг промахнулся!", 1.0)
					
					# НЕ переходим к ходу игрока - враг завершает свой ход
					await get_tree().create_timer(0.5).timeout
					
					# Проверяем дополнительное действие врага
					if not player_node.is_dead() and enemy_node.has_method("check_extra_action"):
						if enemy_node.check_extra_action():
							await get_tree().create_timer(0.5).timeout
							# Повторяем атаку врага
							await _enemy_action()
							return
					
					# Переходим к следующему врагу или игроку
					if get_alive_enemy_count() > 1:
						await _process_next_enemy_turn()
					else:
						_set_player_turn()
					return
				
				# Попадание успешно - проигрываем эффект способности на цели
				var ability_id_for_effect = enemy_ability.id if enemy_ability else ""
				
				if ability_id_for_effect != "" and ability_effect_manager:
					# Задержка для синхронизации с анимацией атаки (момент удара)
					await get_tree().create_timer(0.35).timeout
					ability_effect_manager.play_ability_effect_on_target(player_node, ability_id_for_effect, Vector2.ZERO, Vector2(2, 2), 100)
					# Устанавливаем флаг, что эффект уже проигран
					result["effect_played"] = true
			
			# Сохраняем информацию о критическом ударе для логирования
			enemy_node.last_attack_was_crit = is_crit
			enemy_node.last_attack_damage_type = damage_type
			
			# Наносим урон только если уворот не сработал
			# Для одноударных способностей урон уже нанесен в специальных блоках выше
			# Проверяем, обработана ли способность в специальных блоках
			var special_ability_handled = false
			
			if result.get("double_strike", false) or result.get("executioner_strike", false) or result.get("poison_strike", false) or result.get("magic_arrows", false) or result.get("rat_bite", false) or result.get("crossbow_shot", false) or result.get("slashing_strike", false) or result.get("tombstone", false) or result.get("rending_claws", false) or result.get("bat_swoop", false) or result.get("rotten_blast", false) or result.get("acid_blast", false) or result.get("crushing_strike", false) or result.get("dark_blast", false) or result.get("curse_blast", false) or result.get("crushing_hammer", false):
				special_ability_handled = true
			
			if result.get("double_strike", false):
				var first_hit_damage = result.get("first_hit_damage", 0)
				var second_hit_damage = result.get("second_hit_damage", 0)
				var first_hit_crit = result.get("first_hit_crit", false)
				var second_hit_crit = result.get("second_hit_crit", false)
				
				# Запускаем специальную анимацию "Двойного удара"
				var visual_node = enemy_node.get_node_or_null("Visual")
				if visual_node:
					# Проверяем наличие анимации
					if visual_node.sprite_frames and visual_node.sprite_frames.has_animation("Double_strike"):
						if visual_node.has_method("play_animation"):
							visual_node.play_animation("Double_strike")
						else:
							visual_node.play("Double_strike")
							# Вернемся к idle после завершения
							await visual_node.animation_finished
							visual_node.play_idle()
					else:
						# Fallback: используем стандартную атаку, если специальная анимация не найдена
						visual_node.play_attack()
				
				# Первый удар - проверяем уворот
				if _calculate_hit_chance(enemy_node, player_node, "double_strike_1", "Двойной удар (1-й удар)"):
					# Ждем момента удара в анимации атаки (примерно середина анимации)
					await get_tree().create_timer(0.35).timeout
					
					# ОДНОВРЕМЕННО: звук, эффект, урон и цифра урона
					# Звук первого удара
					if SoundManager:
						SoundManager.play_sound("sword_attack1", -5.0)
					
					# Проигрываем эффект способности на цели используя универсальный менеджер
					if ability_effect_manager:
						ability_effect_manager.play_ability_effect_on_target(player_node, "double_strike", Vector2.ZERO, Vector2(2, 2), 100)
					
					# Наносим урон и показываем цифру
					var player_old_hp = player_node.hp
					player_node.take_damage(first_hit_damage, damage_type)
					var actual_first_damage = player_old_hp - player_node.hp
					
					# Показываем всплывающую цифру фактического урона с учетом крита первого удара (только если попадание!)
					DamageNumberManager.show_damage_on_character(player_node, actual_first_damage, first_hit_crit, false, false, damage_type)
					
					# Тряска камеры при критическом ударе
					if first_hit_crit and camera and camera.has_method("shake"):
						camera.shake(0.25, 12.0)  # Меньше для первого удара
					
					# Активируем пассивные способности врага после первого удара
					var context_attack_1 = {"damage": first_hit_damage, "target": player_node, "ability_used": true, "is_critical": first_hit_crit, "hit_number": 1, "damage_type": damage_type}
					enemy_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, player_node, context_attack_1)
					# Проверяем дополнительные атаки после первого удара
					_check_extra_attacks(enemy_node, player_node, damage_type)
				else:
					# Показываем всплывающую цифру промаха
					DamageNumberManager.show_damage_on_character(player_node, 0, false, true, false, damage_type)
				
				await get_tree().create_timer(0.3).timeout  # Небольшая задержка между ударами
				
				# Второй удар - проверяем уворот
				if _calculate_hit_chance(enemy_node, player_node, "double_strike_2", "Двойной удар (2-й удар)"):
					# Ждем момента удара в анимации атаки (примерно середина анимации)
					await get_tree().create_timer(0.35).timeout
					
					# ОДНОВРЕМЕННО: звук, эффект, урон и цифра урона
					# Звук второго удара
					if SoundManager:
						SoundManager.play_sound("sword_attack1", -5.0)
					
					# Проигрываем эффект способности на цели используя универсальный менеджер
					if ability_effect_manager:
						ability_effect_manager.play_ability_effect_on_target(player_node, "double_strike", Vector2.ZERO, Vector2(2, 2), 100)
					
					# Наносим урон и показываем цифру
					var player_old_hp = player_node.hp
					player_node.take_damage(second_hit_damage, damage_type)
					var actual_second_damage = player_old_hp - player_node.hp
					
					# Показываем всплывающую цифру фактического урона с учетом крита второго удара (только если попадание!)
					DamageNumberManager.show_damage_on_character(player_node, actual_second_damage, second_hit_crit, false, false, damage_type)
					
					# Тряска камеры при критическом ударе
					if second_hit_crit and camera and camera.has_method("shake"):
						camera.shake(0.25, 12.0)  # Меньше для второго удара
					
					# Активируем пассивные способности врага после второго удара
					var context_attack_2 = {"damage": second_hit_damage, "target": player_node, "ability_used": true, "is_critical": second_hit_crit, "hit_number": 2, "damage_type": damage_type}
					enemy_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, player_node, context_attack_2)
					# Проверяем дополнительные атаки после второго удара
					_check_extra_attacks(enemy_node, player_node, damage_type)
				else:
					# Показываем всплывающую цифру промаха
					DamageNumberManager.show_damage_on_character(player_node, 0, false, true, false, damage_type)
			elif result.get("executioner_strike", false):
				# Специальная обработка для "Удара палача" - два удара (рубящий и колющий)
				var first_hit_damage = result.get("first_hit_damage", 0)
				var second_hit_damage = result.get("second_hit_damage", 0)
				var first_hit_crit = result.get("first_hit_crit", false)
				var second_hit_crit = result.get("second_hit_crit", false)
				
				# Запускаем специальную анимацию "Удара палача"
				var visual_node = enemy_node.get_node_or_null("Visual")
				if visual_node:
					# Проверяем наличие анимации
					if visual_node.sprite_frames and visual_node.sprite_frames.has_animation("Executioner_strike"):
						if visual_node.has_method("play_animation"):
							visual_node.play_animation("Executioner_strike")
						else:
							visual_node.play("Executioner_strike")
							# Вернемся к idle после завершения
							await visual_node.animation_finished
							visual_node.play_idle()
					else:
						# Fallback: используем стандартную атаку, если специальная анимация не найдена
						visual_node.play_attack()
				
				# Первый удар (рубящий) - проверяем уворот
				if _calculate_hit_chance(enemy_node, player_node, "executioner_strike_1", "Удар палача (рубящий)"):
					# Запускаем звук первого удара с задержкой (асинхронно)
					_play_delayed_sound("sword_attack3", 0.5, -5.0)
					
					var player_old_hp = player_node.hp
					player_node.take_damage(first_hit_damage, damage_type)
					var actual_first_damage = player_old_hp - player_node.hp
					
					# Показываем всплывающую цифру фактического урона с учетом крита первого удара (только если попадание!)
					DamageNumberManager.show_damage_on_character(player_node, actual_first_damage, first_hit_crit, false, false, damage_type)
					
					# Тряска камеры при критическом ударе
					if first_hit_crit and camera and camera.has_method("shake"):
						camera.shake(0.25, 12.0)  # Меньше для первого удара
					
					# Активируем пассивные способности врага после первого удара
					var context_attack_1 = {"damage": first_hit_damage, "target": player_node, "ability_used": true, "is_critical": first_hit_crit, "hit_number": 1, "damage_type": damage_type}
					enemy_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, player_node, context_attack_1)
					# Проверяем дополнительные атаки после первого удара
					_check_extra_attacks(enemy_node, player_node, damage_type)
				else:
					# Показываем всплывающую цифру промаха
					DamageNumberManager.show_damage_on_character(player_node, 0, false, true, false, damage_type)
				
				await get_tree().create_timer(0.5).timeout  # Задержка между ударами (0.5 сек)
				
				# Второй удар (колющий) - проверяем уворот
				if _calculate_hit_chance(enemy_node, player_node, "executioner_strike_2", "Удар палача (колющий)"):
					# Запускаем звук второго удара с задержкой (асинхронно)
					_play_delayed_sound("sword_attack4", 1.0, -5.0)
					
					var player_old_hp = player_node.hp
					player_node.take_damage(second_hit_damage, damage_type)
					var actual_second_damage = player_old_hp - player_node.hp
					
					# Показываем всплывающую цифру фактического урона с учетом крита второго удара (только если попадание!)
					DamageNumberManager.show_damage_on_character(player_node, actual_second_damage, second_hit_crit, false, false, damage_type)
					
					# Тряска камеры при критическом ударе
					if second_hit_crit and camera and camera.has_method("shake"):
						camera.shake(0.25, 12.0)  # Меньше для второго удара
					
					# Активируем пассивные способности врага после второго удара
					var context_attack_2 = {"damage": second_hit_damage, "target": player_node, "ability_used": true, "is_critical": second_hit_crit, "hit_number": 2, "damage_type": damage_type}
					enemy_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, player_node, context_attack_2)
					# Проверяем дополнительные атаки после второго удара
					_check_extra_attacks(enemy_node, player_node, damage_type)
				else:
					# Показываем всплывающую цифру промаха
					DamageNumberManager.show_damage_on_character(player_node, 0, false, true, false, damage_type)
			elif result.get("poison_strike", false):
				# Гоблин Вор проигрывает стандартную атаку (уже проиграна в общем блоке)
				# Проигрываем эффект только если он не был проигран в общем блоке
				if not result.get("effect_played", false):
					# Ждем момента удара в анимации атаки (примерно середина анимации)
					await get_tree().create_timer(0.35).timeout
					
					# Проигрываем эффект способности на цели используя универсальный менеджер
					if ability_effect_manager:
						ability_effect_manager.play_ability_effect_on_target(player_node, "poison_strike", Vector2.ZERO, Vector2(2, 2), 100)
						
						# Вычисляем длительность анимации для синхронизации урона
						if ability_effect_manager.ability_effect_spriteframes:
							var anim_name = ability_animation_manager.get_animation_for_ability("poison_strike")
							if anim_name != "" and ability_effect_manager.ability_effect_spriteframes.has_animation(anim_name):
								var anim_speed = ability_effect_manager.ability_effect_spriteframes.get_animation_speed(anim_name)
								var anim_frames = ability_effect_manager.ability_effect_spriteframes.get_frame_count(anim_name)
								var anim_duration = anim_frames / anim_speed if anim_speed > 0 else 0.5
								var hit_moment = anim_duration * 0.5  # Середина анимации
								await get_tree().create_timer(hit_moment).timeout
							else:
								await get_tree().create_timer(0.25).timeout  # Fallback задержка
						else:
							await get_tree().create_timer(0.25).timeout  # Fallback задержка
				else:
					# Эффект уже проигран, просто ждем
					await get_tree().create_timer(0.0).timeout
				
				# Специальная обработка для "Ядовитого удара"
				var player_old_hp = player_node.hp
				player_node.take_damage(damage, damage_type)
				var actual_damage = player_old_hp - player_node.hp
				
				# Показываем всплывающую цифру фактического урона
				DamageNumberManager.show_damage_on_character(player_node, actual_damage, is_crit, false, false, damage_type)
				
				# Тряска камеры при критическом ударе врага
				if is_crit and camera and camera.has_method("shake"):
					camera.shake(0.3, 15.0)
				
				# Накладываем стаки яда на игрока
				var stacks_to_add = result.get("poison_stacks", 2)
				var current_stacks = 0
				
				if player_node.has_effect("poison"):
					var existing_effect = player_node.effects.get("poison", {})
					if existing_effect is Dictionary:
						current_stacks = existing_effect.get("stacks", 1)
				
				# Добавляем стаки (максимум 3)
				for i in range(stacks_to_add):
					if current_stacks < 3:
						player_node.add_effect("poison", 5.0, 1, {"damage_per_turn": 10})
						current_stacks += 1
					else:
						break
				
				# Логируем результат
				if current_stacks >= 3:
					battle_log.log_event("poison_max", enemy_node.display_name, player_node.display_name, 3, "Яд достиг максимума! 3 стака (10 урона за ход каждый)")
				else:
					battle_log.log_event("poison_applied", enemy_node.display_name, player_node.display_name, current_stacks, "Наложено " + str(stacks_to_add) + " стака яда! Всего стаков: " + str(current_stacks) + " из 3")
				
				# Активируем пассивные способности врага при атаке
				var context_attack = {"damage": damage, "target": player_node, "ability_used": true, "is_critical": is_crit, "damage_type": damage_type}
				enemy_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, player_node, context_attack)
			elif result.get("magic_arrows", false):
				# Специальная обработка для "Магических стрел"
				var arrows_count = result.get("arrows_count", 1)
				var arrow_damage = result.get("arrow_damage", 0)
				var _critical_hits = result.get("critical_hits", 0)
				var total_arrow_damage = 0
				
				# Запускаем анимацию атаки врага
				var visual_node = enemy_node.get_node_or_null("Visual")
				if visual_node and visual_node.has_method("play_attack"):
					visual_node.play_attack()
				
				# Ждём момента взмаха посоха (примерно середина анимации атаки)
				await get_tree().create_timer(0.4).timeout
				
				# Создаём визуальные снаряды для каждой стрелы
				_spawn_magic_arrow_projectiles(enemy_node, player_node, arrows_count)
				
				# Каждая стрела наносит урон отдельно с задержкой
				for i in range(arrows_count):
					# Задержка для полета снаряда до игрока (первая стрела + задержки между следующими)
					if i == 0:
						# Первая стрела: только время полета (~0.5 сек)
						await get_tree().create_timer(0.5).timeout
					else:
						# Следующие стрелы: интервал между созданием (0.6 сек)
						await get_tree().create_timer(0.6).timeout
					
					# Проверяем уворот для каждой стрелы
					if _calculate_hit_chance(enemy_node, player_node, "magic_arrow_" + str(i+1), "Магическая стрела " + str(i+1)):
						var player_old_hp = player_node.hp
						player_node.take_damage(arrow_damage, damage_type)
						var actual_arrow_damage = player_old_hp - player_node.hp
						total_arrow_damage += actual_arrow_damage
						
						# Показываем всплывающую цифру фактического урона
						DamageNumberManager.show_damage_on_character(player_node, actual_arrow_damage, false, false, false, damage_type)
						
						# Активируем пассивные способности врага после каждой стрелы
						var context_arrow = {"damage": arrow_damage, "target": player_node, "ability_used": true, "is_critical": false, "hit_number": i+1, "damage_type": damage_type}
						enemy_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, player_node, context_arrow)
					else:
						# Показываем всплывающую цифру промаха
						DamageNumberManager.show_damage_on_character(player_node, 0, false, true, false, damage_type)
				
				# Обновляем damage для правильного отображения в сообщении
				damage = total_arrow_damage
			elif result.get("rat_bite", false):
				# Крыса проигрывает стандартную атаку (уже проиграна в общем блоке)
				# Ждем момента удара в анимации атаки крысы (примерно середина анимации)
				# Анимация атаки крысы: 7 кадров, скорость 8.0, момент удара ~0.3-0.4 сек
				
				# Проигрываем эффект только если он не был проигран в общем блоке
				if not result.get("effect_played", false):
					await get_tree().create_timer(0.35).timeout
					
					# Проигрываем эффект способности на цели используя универсальный менеджер
					if ability_effect_manager:
						ability_effect_manager.play_ability_effect_on_target(player_node, "rat_bite", Vector2.ZERO, Vector2(2, 2), 100)
				else:
					# Эффект уже проигран, просто ждем
					await get_tree().create_timer(0.0).timeout
				
				var player_old_hp = player_node.hp
				player_node.take_damage(damage, damage_type)
				var actual_damage = player_old_hp - player_node.hp
				DamageNumberManager.show_damage_on_character(player_node, actual_damage, is_crit, false, false, damage_type)
				if is_crit and camera and camera.has_method("shake"):
					camera.shake(0.3, 15.0)
				if result.get("apply_bleeding", false):
					var source_id = enemy_node.get_instance_id()
					player_node.add_effect("bleeding", 3.0, 1, {"damage_per_turn": 5, "source_id": source_id})
					battle_log.log_event("bleeding_applied", enemy_node.display_name, player_node.display_name, 5, "Игрок начинает кровоточить! 5 урона за ход")
				var context_attack = {"damage": damage, "target": player_node, "ability_used": true, "is_critical": is_crit, "damage_type": damage_type}
				enemy_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, player_node, context_attack)
			elif result.get("crossbow_shot", false):
				# Скелет Арбалетчик проигрывает стандартную атаку (уже проиграна в общем блоке)
				# Ждем момента удара в анимации атаки (примерно середина анимации)
				
				# Проигрываем эффект только если он не был проигран в общем блоке
				if not result.get("effect_played", false):
					await get_tree().create_timer(0.35).timeout
					
					# Проигрываем эффект способности на цели используя универсальный менеджер
					if ability_effect_manager:
						ability_effect_manager.play_ability_effect_on_target(player_node, "crossbow_shot", Vector2.ZERO, Vector2(2, 2), 100)
				else:
					# Эффект уже проигран, просто ждем
					await get_tree().create_timer(0.0).timeout
				
				var player_old_hp = player_node.hp
				player_node.take_damage(damage, damage_type)
				var actual_damage = player_old_hp - player_node.hp
				DamageNumberManager.show_damage_on_character(player_node, actual_damage, is_crit, false, false, damage_type)
				if is_crit and camera and camera.has_method("shake"):
					camera.shake(0.3, 15.0)
				var context_attack = {"damage": damage, "target": player_node, "ability_used": true, "is_critical": is_crit, "damage_type": damage_type}
				enemy_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, player_node, context_attack)
			elif result.get("slashing_strike", false):
				# Скелет Мечник проигрывает стандартную атаку (уже проиграна в общем блоке)
				# Ждем момента удара в анимации атаки (примерно середина анимации)
				
				# Проигрываем эффект только если он не был проигран в общем блоке
				if not result.get("effect_played", false):
					await get_tree().create_timer(0.35).timeout
					
					# Проигрываем эффект способности на цели используя универсальный менеджер
					if ability_effect_manager:
						ability_effect_manager.play_ability_effect_on_target(player_node, "slashing_strike", Vector2.ZERO, Vector2(2, 2), 100)
				else:
					# Эффект уже проигран, просто ждем
					await get_tree().create_timer(0.0).timeout
				
				var player_old_hp = player_node.hp
				player_node.take_damage(damage, damage_type)
				var actual_damage = player_old_hp - player_node.hp
				DamageNumberManager.show_damage_on_character(player_node, actual_damage, is_crit, false, false, damage_type)
				if is_crit and camera and camera.has_method("shake"):
					camera.shake(0.3, 15.0)
				if result.get("apply_bleeding", false):
					var bleed_damage = result.get("bleed_damage", 3)
					var source_id = enemy_node.get_instance_id()
					player_node.add_effect("bleeding", 3.0, 1, {"damage_per_turn": bleed_damage, "source_id": source_id})
					battle_log.log_event("bleeding_applied", enemy_node.display_name, player_node.display_name, bleed_damage, "Игрок начинает кровоточить! " + str(bleed_damage) + " урона за ход")
				var context_attack = {"damage": damage, "target": player_node, "ability_used": true, "is_critical": is_crit, "damage_type": damage_type}
				enemy_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, player_node, context_attack)
			elif result.get("tombstone", false):
				# Массовая магическая атака "Надгробие"
				# Проигрываем анимацию каста
				var visual_node = enemy_node.get_node_or_null("Visual")
				if visual_node:
					if visual_node.has_method("play_animation") and visual_node.has_method("has_animation"):
						if visual_node.has_animation("tombstone_cast"):
							visual_node.play_animation("tombstone_cast")
						else:
							if visual_node.has_method("play_attack"):
								visual_node.play_attack()
					elif visual_node.has_method("play_attack"):
						visual_node.play_attack()
				
				# Ждем момента каста
				await get_tree().create_timer(0.4).timeout
				
				# Проигрываем эффект способности на цели используя универсальный менеджер (с увеличенным масштабом)
				if ability_effect_manager:
					ability_effect_manager.play_ability_effect_on_target(player_node, "tombstone", Vector2.ZERO, Vector2(3, 3), 100)  # Масштаб 3x вместо 2x для большего эффекта
					
					# Вычисляем длительность анимации для синхронизации урона
					if ability_effect_manager.ability_effect_spriteframes:
						var anim_name = ability_animation_manager.get_animation_for_ability("tombstone")
						if anim_name != "" and ability_effect_manager.ability_effect_spriteframes.has_animation(anim_name):
							var anim_speed = ability_effect_manager.ability_effect_spriteframes.get_animation_speed(anim_name)
							var anim_frames = ability_effect_manager.ability_effect_spriteframes.get_frame_count(anim_name)
							var anim_duration = anim_frames / anim_speed if anim_speed > 0 else 0.6
							var hit_moment = anim_duration * 0.5  # Середина анимации
							await get_tree().create_timer(hit_moment).timeout
						else:
							await get_tree().create_timer(0.3).timeout  # Fallback задержка
					else:
						await get_tree().create_timer(0.3).timeout  # Fallback задержка
				
				# Массовая атака наносит урон всем противникам (в данном случае только игроку)
				var targets = [player_node]  # Пока только игрок
				
				for target in targets:
					if target and is_instance_valid(target) and not target.is_dead():
						# Проверяем попадание для каждого противника отдельно
						if _calculate_hit_chance(enemy_node, target, "tombstone", "Надгробие"):
							var target_old_hp = target.hp
							target.take_damage(damage, damage_type)
							var actual_damage = target_old_hp - target.hp
							
							# Показываем урон
							DamageNumberManager.show_damage_on_character(target, actual_damage, is_crit, false, false, damage_type)
							
							if is_crit and camera and camera.has_method("shake"):
								camera.shake(0.3, 15.0)
							
							# Проверяем шанс паралича (30%)
							var paralysis_chance = result.get("paralysis_chance", 0.30)
							if randf() < paralysis_chance:
								target.add_effect("paralysis", 1.0, 1, {})
								battle_log.log_event("paralysis_applied", enemy_node.display_name, target.display_name, 0, target.display_name + " парализован!")
								_show_message(target.display_name + " парализован!", 1.5)
							
							# Активируем пассивные способности цели при получении урона
							var context_damage = {"damage": actual_damage, "target": target}
							target.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_DAMAGE_TAKEN, enemy_node, context_damage)
						else:
							# Промах
							DamageNumberManager.show_damage_on_character(target, 0, false, true, false, damage_type)
							_show_message(target.display_name + " увернулся от Надгробия!", 1.0)
			
				# Активируем пассивные способности врага при атаке
				var context_attack = {"damage": damage, "target": player_node, "ability_used": true, "is_critical": is_crit, "damage_type": damage_type}
				enemy_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, player_node, context_attack)
			elif result.get("rending_claws", false):
				# Гуль проигрывает стандартную атаку (уже проиграна в общем блоке)
				# Ждем момента удара в анимации атаки (примерно середина анимации)
				
				# Проигрываем эффект только если он не был проигран в общем блоке
				if not result.get("effect_played", false):
					await get_tree().create_timer(0.35).timeout
					
					# Проигрываем эффект способности на цели используя универсальный менеджер
					if ability_effect_manager:
						ability_effect_manager.play_ability_effect_on_target(player_node, "rending_claws", Vector2.ZERO, Vector2(2, 2), 100)
				else:
					# Эффект уже проигран, просто ждем
					await get_tree().create_timer(0.0).timeout
				
				var player_old_hp = player_node.hp
				player_node.take_damage(damage, damage_type)
				var actual_damage = player_old_hp - player_node.hp
				DamageNumberManager.show_damage_on_character(player_node, actual_damage, is_crit, false, false, damage_type)
				
				if is_crit and camera and camera.has_method("shake"):
					camera.shake(0.3, 15.0)
				
				if result.get("lifesteal_percent", 0.0) > 0.0 and actual_damage > 0:
					var lifesteal_percent = result.get("lifesteal_percent", 0.25)
					var heal_amount = int(actual_damage * lifesteal_percent)
					var old_hp = enemy_node.hp
					enemy_node.hp = min(enemy_node.hp + heal_amount, enemy_node.max_hp)
					var actual_heal = enemy_node.hp - old_hp
					
					if actual_heal > 0:
						battle_log.log_event("lifesteal", enemy_node.display_name, player_node.display_name, actual_heal, enemy_node.display_name + " восстанавливает " + str(actual_heal) + " ОЗ вампиризмом!")
						DamageNumberManager.show_damage_on_character(enemy_node, actual_heal, false, false, true, "heal")
						if ui and ui.has_method("_update_ui"):
							ui._update_ui()
				
				if result.get("apply_bleeding", false):
					var source_id = enemy_node.get_instance_id()
					player_node.add_effect("bleeding", 3.0, 1, {"damage_per_turn": 5, "source_id": source_id})
					battle_log.log_event("bleeding_applied", enemy_node.display_name, player_node.display_name, 5, "Игрок начинает кровоточить! 5 урона за ход")
				
				var context_attack_claws = {"damage": actual_damage, "target": player_node, "ability_used": true, "is_critical": is_crit, "damage_type": damage_type}
				enemy_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, player_node, context_attack_claws)
			elif result.get("bat_swoop", false):
				# Летучая мышь проигрывает стандартную атаку (уже проиграна в общем блоке)
				# Ждем момента удара в анимации атаки (примерно середина анимации)
				
				# Проигрываем эффект только если он не был проигран в общем блоке
				if not result.get("effect_played", false):
					await get_tree().create_timer(0.35).timeout
					
					# Проигрываем эффект способности на цели используя универсальный менеджер
					if ability_effect_manager:
						ability_effect_manager.play_ability_effect_on_target(player_node, "bat_swoop", Vector2.ZERO, Vector2(2, 2), 100)
				else:
					# Эффект уже проигран, просто ждем
					await get_tree().create_timer(0.0).timeout
				
				var player_old_hp = player_node.hp
				player_node.take_damage(damage, damage_type)
				var actual_damage = player_old_hp - player_node.hp
				DamageNumberManager.show_damage_on_character(player_node, actual_damage, is_crit, false, false, damage_type)
				if is_crit and camera and camera.has_method("shake"):
					camera.shake(0.3, 15.0)
				
				# Проверяем оглушение от Пикирования (30% шанс)
				if result.get("apply_stun", false):
					print("🦇 ПИКИРОВАНИЕ: Оглушение сработало! (30% шанс)")
					player_node.add_effect("stun", 1.0, 0, {})
					battle_log.log_event("stun_applied", enemy_node.display_name, player_node.display_name, 1, "Игрок оглушен! Пропускает следующий ход")
					_show_message("ОГЛУШЕНИЕ! Вы пропустите следующий ход!", 2.0)
				else:
					print("🦇 ПИКИРОВАНИЕ: Оглушение не сработало (30% шанс)")
				
				var context_attack = {"damage": damage, "target": player_node, "ability_used": true, "is_critical": is_crit, "damage_type": damage_type}
				enemy_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, player_node, context_attack)
			elif result.get("rotten_blast", false):
				var player_old_hp = player_node.hp
				player_node.take_damage(damage, damage_type)
				var actual_damage = player_old_hp - player_node.hp
				DamageNumberManager.show_damage_on_character(player_node, actual_damage, is_crit, false, false, damage_type)
				if is_crit and camera and camera.has_method("shake"):
					camera.shake(0.3, 15.0)
				if result.get("trigger_rotten_aura", false):
					var has_rotten_aura = false
					for passive in enemy_node.passive_abilities:
						if passive.id == "rotten_aura":
							has_rotten_aura = true
							var aura_context = {
								"ability_level": enemy_node.ability_levels.get("rotten_aura", 1),
								"round_number": current_round
							}
							var aura_result = passive.execute_ability(enemy_node, player_node, aura_context)
							if aura_result.get("success", false):
								var aura_damage = aura_result.get("damage", 0)
								battle_log.log_event("rotten_aura_triggered", enemy_node.display_name, player_node.display_name, aura_damage, aura_result.get("message", "Гнилостная аура активирована!"))
								DamageNumberManager.show_damage_on_character(player_node, aura_damage, false, false, false, "magic")
							break
					if not has_rotten_aura:
						print("ПРЕДУПРЕЖДЕНИЕ: Гнилой слизень использовал 'Гнилостный взрыв', но у него нет пассивки 'rotten_aura'!")
				var context_attack = {"damage": damage, "target": player_node, "ability_used": true, "is_critical": is_crit, "damage_type": damage_type}
				enemy_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, player_node, context_attack)
			elif result.get("acid_blast", false):
				# Слизень проигрывает стандартную атаку (уже проиграна в общем блоке)
				# Проигрываем звук кислотного взрыва
				if SoundManager:
					SoundManager.play_sound("acid_blast", -5.0)
				
				# Проигрываем эффект только если он не был проигран в общем блоке
				if not result.get("effect_played", false):
					# Ждем момента удара в анимации атаки (примерно середина анимации)
					await get_tree().create_timer(0.35).timeout
					
					# Проигрываем эффект способности на цели используя универсальный менеджер
					if ability_effect_manager:
						ability_effect_manager.play_ability_effect_on_target(player_node, "acid_blast", Vector2.ZERO, Vector2(2, 2), 100)
				else:
					# Эффект уже проигран, просто ждем
					await get_tree().create_timer(0.0).timeout
				
				var player_old_hp = player_node.hp
				player_node.take_damage(damage, damage_type)
				var actual_damage = player_old_hp - player_node.hp
				DamageNumberManager.show_damage_on_character(player_node, actual_damage, is_crit, false, false, damage_type)
				if is_crit and camera and camera.has_method("shake"):
					camera.shake(0.3, 15.0)
				var armor_reduction_value = result.get("reduce_armor", 5)
				# Используем reduce_armor для единой логики обновления эффекта коррозии брони
				if player_node.has_method("reduce_armor"):
					player_node.reduce_armor(armor_reduction_value)
				else:
					player_node.armor_reduction += armor_reduction_value
				battle_log.log_event("armor_reduced", enemy_node.display_name, player_node.display_name, armor_reduction_value, "Броня игрока снижена на " + str(armor_reduction_value) + "! Общее снижение брони: " + str(player_node.armor_reduction))
				var context_attack = {"damage": damage, "target": player_node, "ability_used": true, "is_critical": is_crit, "damage_type": damage_type}
				enemy_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, player_node, context_attack)
			elif result.get("crushing_strike", false):
				# Проигрываем анимацию attack_alt для сокрушающего удара
				var visual_node = enemy_node.get_node_or_null("Visual")
				if visual_node:
					if ability_animation_manager and ability_animation_manager.has_animation_for_ability("tharnok_crushing_strike"):
						ability_animation_manager.play_ability_animation(visual_node, "tharnok_crushing_strike")
					elif visual_node.sprite_frames and visual_node.sprite_frames.has_animation("attack_alt"):
						if visual_node.has_method("play_animation"):
							visual_node.play_animation("attack_alt")
						else:
							visual_node.play("attack_alt")
					elif visual_node.has_method("play_attack"):
						visual_node.play_attack()
				
				var first_hit_damage = result.get("first_hit_damage", 0)
				var second_hit_damage = result.get("second_hit_damage", 0)
				var first_hit_crit = result.get("first_hit_crit", false)
				var second_hit_crit = result.get("second_hit_crit", false)
				if _calculate_hit_chance(enemy_node, player_node, "crushing_strike_1", "Сокрушающий удар (обычный)"):
					var player_old_hp = player_node.hp
					player_node.take_damage(first_hit_damage, damage_type)
					var actual_first_damage = player_old_hp - player_node.hp
					DamageNumberManager.show_damage_on_character(player_node, actual_first_damage, first_hit_crit, false, false, damage_type)
					if first_hit_crit and camera and camera.has_method("shake"):
						camera.shake(0.25, 12.0)
					var context_attack_1 = {"damage": first_hit_damage, "target": player_node, "ability_used": true, "is_critical": first_hit_crit, "hit_number": 1, "damage_type": damage_type}
					enemy_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, player_node, context_attack_1)
					_check_extra_attacks(enemy_node, player_node, damage_type)
				else:
					DamageNumberManager.show_damage_on_character(player_node, 0, false, true, false, damage_type)
				await get_tree().create_timer(1.0).timeout
				if _calculate_hit_chance(enemy_node, player_node, "crushing_strike_2", "Сокрушающий удар (усиленный)"):
					var player_old_hp = player_node.hp
					player_node.take_damage(second_hit_damage, damage_type)
					var actual_second_damage = player_old_hp - player_node.hp
					DamageNumberManager.show_damage_on_character(player_node, actual_second_damage, second_hit_crit, false, false, damage_type)
					if second_hit_crit and camera and camera.has_method("shake"):
						camera.shake(0.25, 12.0)
					if result.get("apply_stun", false):
						player_node.add_effect("stun", 1.0, 0, {})
						battle_log.log_event("stun_applied", enemy_node.display_name, player_node.display_name, 1, "Игрок оглушен! Пропускает следующий ход")
						_show_message("ОГЛУШЕНИЕ! Вы пропустите следующий ход!", 2.0)
					var context_attack_2 = {"damage": second_hit_damage, "target": player_node, "ability_used": true, "is_critical": second_hit_crit, "hit_number": 2, "damage_type": damage_type}
					enemy_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, player_node, context_attack_2)
					_check_extra_attacks(enemy_node, player_node, damage_type)
				else:
					DamageNumberManager.show_damage_on_character(player_node, 0, false, true, false, damage_type)
			elif result.get("dark_blast", false):
				var player_old_hp = player_node.hp
				player_node.take_damage(damage, damage_type)
				var actual_damage = player_old_hp - player_node.hp
				DamageNumberManager.show_damage_on_character(player_node, actual_damage, is_crit, false, false, damage_type)
				if is_crit and camera and camera.has_method("shake"):
					camera.shake(0.3, 15.0)
				if result.get("lifesteal", false) and actual_damage > 0:
					var heal_amount = int(actual_damage * 0.5)
					var old_hp = enemy_node.hp
					enemy_node.hp = min(enemy_node.hp + heal_amount, enemy_node.max_hp)
					var actual_heal = enemy_node.hp - old_hp
					if actual_heal > 0:
						battle_log.log_event("lifesteal", enemy_node.display_name, player_node.display_name, actual_heal, enemy_node.display_name + " восстанавливает " + str(actual_heal) + " ОЗ вампиризмом!")
						DamageNumberManager.show_damage_on_character(enemy_node, actual_heal, false, false, true, "heal")
						if ui and ui.has_method("_update_ui"):
							ui._update_ui()
				var context_attack = {"damage": actual_damage, "target": player_node, "ability_used": true, "is_critical": is_crit, "damage_type": damage_type}
				enemy_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, player_node, context_attack)
			elif result.get("curse_blast", false):
				var player_old_hp = player_node.hp
				player_node.take_damage(damage, damage_type)
				var actual_damage = player_old_hp - player_node.hp
				DamageNumberManager.show_damage_on_character(player_node, actual_damage, is_crit, false, false, damage_type)
				if is_crit and camera and camera.has_method("shake"):
					camera.shake(0.3, 15.0)
				if result.get("apply_curse", false):
					if player_node.has_effect("curse"):
						player_node.remove_effect("curse")
						battle_log.log_event("curse_refreshed", enemy_node.display_name, player_node.display_name, 3, "Проклятие обновлено! Длительность сброшена")
					player_node.add_effect("curse", 3.0, 0, {"damage_reduction": 0.20})
					battle_log.log_event("curse_applied", enemy_node.display_name, player_node.display_name, 3, "Игрок проклят! Урон снижен на 20% на 3 хода")
					_show_message("ПРОКЛЯТИЕ! Урон снижен на 20%!", 2.0)
				var context_attack = {"damage": damage, "target": player_node, "ability_used": true, "is_critical": is_crit, "damage_type": damage_type}
				enemy_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, player_node, context_attack)
			elif result.get("shadow_spikes", false):
				# Теневые шипы - анимация аналогично кислотному взрыву
				# Проигрываем звук теней
				if SoundManager:
					SoundManager.play_sound("magic_arrow", -5.0)
				
				# Проигрываем эффект только если он не был проигран в общем блоке
				if not result.get("effect_played", false):
					# Ждем момента удара в анимации атаки
					await get_tree().create_timer(0.35).timeout
					
					# Проигрываем эффект способности на цели используя универсальный менеджер
					if ability_effect_manager:
						ability_effect_manager.play_ability_effect_on_target(player_node, "shadow_spikes", Vector2.ZERO, Vector2(2, 2), 100)
				else:
					# Эффект уже проигран, просто ждем
					await get_tree().create_timer(0.0).timeout
				
				# Наносим урон
				var player_old_hp = player_node.hp
				player_node.take_damage(damage, damage_type)
				var actual_damage = player_old_hp - player_node.hp
				
				# Если удар был из невидимости - показываем особое сообщение
				var from_stealth = result.get("from_stealth", false)
				if from_stealth:
					battle_log.log_event("shadow_spikes_stealth", enemy_node.display_name, player_node.display_name, actual_damage, "💀 " + enemy_node.display_name + " наносит АВТОКРИТ из невидимости!")
					_show_message("💀 АВТОКРИТ ИЗ ТЕНЕЙ!", 2.0)
				
				DamageNumberManager.show_damage_on_character(player_node, actual_damage, is_crit, false, false, damage_type)
				if is_crit and camera and camera.has_method("shake"):
					camera.shake(0.4, 18.0)  # Более сильная тряска для автокрита
				
				var context_attack = {"damage": damage, "target": player_node, "ability_used": true, "is_critical": is_crit, "damage_type": damage_type, "from_stealth": from_stealth}
				enemy_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, player_node, context_attack)
			elif result.get("armor_strike", false):
				# Удар брони (Скелет лорд)
				# Воспроизводим звук удара
				if SoundManager:
					SoundManager.play_sound("sword_hit", -5.0)
				
				# Наносим урон
				var player_old_hp = player_node.hp
				player_node.take_damage(damage, damage_type)
				var actual_damage = player_old_hp - player_node.hp
				DamageNumberManager.show_damage_on_character(player_node, actual_damage, is_crit, false, false, damage_type)
				if is_crit and camera and camera.has_method("shake"):
					camera.shake(0.4, 18.0)
				
				# Снижаем броню игрока на 6 единиц
				var armor_reduction_value = result.get("armor_reduction", 6)
				if player_node.has_method("reduce_armor"):
					player_node.reduce_armor(armor_reduction_value)
				else:
					player_node.armor_reduction += armor_reduction_value
				battle_log.log_event("armor_reduced", enemy_node.display_name, player_node.display_name, armor_reduction_value, "⚔️ Удар брони! Броня игрока снижена на " + str(armor_reduction_value) + "! Общее снижение: " + str(player_node.armor_reduction))
				_show_message("⚔️ УДАР БРОНИ! Ваша защита ослаблена на " + str(armor_reduction_value) + "!", 2.0)
				
				# Триггер для пассивной способности "Поглотитель брони"
				# Враги с этой пассивкой получат защиту за снижение брони игрока
				for enemy in get_alive_enemies():
					if is_instance_valid(enemy):
						# Проверяем, есть ли у врага пассивка "Поглотитель брони"
						for passive in enemy.passive_abilities:
							if passive.id == "armor_absorber":
								var absorber_context = {
									"trigger": "armor_reduced",
									"armor_reduced": armor_reduction_value,
									"ability_level": enemy.ability_levels.get("armor_absorber", 1)
								}
								var absorber_result = passive.trigger(enemy, player_node, absorber_context)
								if absorber_result.get("success", false):
									var armor_gained = absorber_result.get("armor_gained", 0)
									battle_log.log_event("armor_absorbed", enemy.display_name, player_node.display_name, armor_gained, enemy.display_name + " поглощает " + str(armor_gained) + " защиты!")
								break
				
				var context_attack = {"damage": damage, "target": player_node, "ability_used": true, "is_critical": is_crit, "damage_type": damage_type}
				enemy_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, player_node, context_attack)
			elif result.get("crushing_hammer", false):
				var first_hit_damage = result.get("first_hit_damage", 0)
				var second_hit_damage = result.get("second_hit_damage", 0)
				var first_hit_crit = result.get("first_hit_crit", false)
				var second_hit_crit = result.get("second_hit_crit", false)
				var visual_node = enemy_node.get_node_or_null("Visual")
				if visual_node:
					if visual_node.sprite_frames and visual_node.sprite_frames.has_animation("Crushing_hammer"):
						if visual_node.has_method("play_animation"):
							visual_node.play_animation("Crushing_hammer")
						else:
							visual_node.play("Crushing_hammer")
							await visual_node.animation_finished
							visual_node.play_idle()
					else:
						visual_node.play_attack()
				if _calculate_hit_chance(enemy_node, player_node, "crushing_hammer_1", "Сокрушительный молот (1-й удар)"):
					# Ждем момента удара в анимации атаки
					await get_tree().create_timer(0.35).timeout
					
					# Звук первого удара
					if SoundManager:
						SoundManager.play_sound("sword_attack1", -5.0)
					
					# Проигрываем эффект способности на цели используя универсальный менеджер (первый удар)
					if ability_effect_manager:
						ability_effect_manager.play_ability_effect_on_target(player_node, "crushing_hammer", Vector2.ZERO, Vector2(2, 2), 100)
					
					# Наносим урон и показываем цифру
					var player_old_hp = player_node.hp
					player_node.take_damage(first_hit_damage, damage_type)
					var actual_first_damage = player_old_hp - player_node.hp
					DamageNumberManager.show_damage_on_character(player_node, actual_first_damage, first_hit_crit, false, false, damage_type)
					if first_hit_crit and camera and camera.has_method("shake"):
						camera.shake(0.25, 12.0)
					var context_attack_hammer_1 = {"damage": first_hit_damage, "target": player_node, "ability_used": true, "is_critical": first_hit_crit, "hit_number": 1, "damage_type": damage_type}
					enemy_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, player_node, context_attack_hammer_1)
				else:
					DamageNumberManager.show_damage_on_character(player_node, 0, false, true, false, damage_type)
				await get_tree().create_timer(0.4).timeout
				if _calculate_hit_chance(enemy_node, player_node, "crushing_hammer_2", "Сокрушительный молот (2-й удар)"):
					# Ждем момента удара в анимации атаки
					await get_tree().create_timer(0.35).timeout
					
					# Звук второго удара
					if SoundManager:
						SoundManager.play_sound("sword_attack1", -5.0)
					
					# Проигрываем эффект способности на цели используя универсальный менеджер (второй удар)
					if ability_effect_manager:
						ability_effect_manager.play_ability_effect_on_target(player_node, "crushing_hammer", Vector2.ZERO, Vector2(2, 2), 100)
					
					# Наносим урон и показываем цифру
					var player_old_hp = player_node.hp
					player_node.take_damage(second_hit_damage, damage_type)
					var actual_second_damage = player_old_hp - player_node.hp
					DamageNumberManager.show_damage_on_character(player_node, actual_second_damage, second_hit_crit, false, false, damage_type)
					if second_hit_crit and camera and camera.has_method("shake"):
						camera.shake(0.25, 12.0)
					if result.get("apply_stun", false):
						player_node.add_effect("stun", 1.0, 0, {})
						battle_log.log_event("stun_applied", enemy_node.display_name, player_node.display_name, 1, "Игрок оглушен на 1 ход!")
						_show_message("ОГЛУШЕНИЕ!", 2.0)
					var context_attack_hammer_2 = {"damage": second_hit_damage, "target": player_node, "ability_used": true, "is_critical": second_hit_crit, "hit_number": 2, "damage_type": damage_type}
					enemy_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, player_node, context_attack_hammer_2)
				else:
					DamageNumberManager.show_damage_on_character(player_node, 0, false, true, false, damage_type)
			elif not special_ability_handled:
				# Обработка способностей без специальных флагов (только если не обработано выше)
				# Получаем ID способности для проигрывания эффекта
				var ability_id = enemy_ability.id if enemy_ability else ""
				
				# Проигрываем эффект способности на цели, если он есть и еще не проигран
				if ability_id != "" and ability_effect_manager and not result.get("effect_played", false):
					# Задержка для синхронизации с анимацией атаки (момент удара)
					await get_tree().create_timer(0.35).timeout
					ability_effect_manager.play_ability_effect_on_target(player_node, ability_id, Vector2.ZERO, Vector2(2, 2), 100)
				
				var player_old_hp = player_node.hp
				player_node.take_damage(damage, damage_type)
				var actual_damage = player_old_hp - player_node.hp
				DamageNumberManager.show_damage_on_character(player_node, actual_damage, is_crit, false, false, damage_type)
				if is_crit and camera and camera.has_method("shake"):
					camera.shake(0.3, 15.0)
				var context_attack = {"damage": damage, "target": player_node, "ability_used": true, "is_critical": is_crit, "damage_type": damage_type}
				enemy_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, player_node, context_attack)
			
			# Устанавливаем кулдаун для способности после использования
			if enemy_ability.cooldown > 0 and enemy_node.has_method("set_ability_cooldown"):
				enemy_node.set_ability_cooldown(enemy_ability.id, enemy_ability.cooldown)
			
			# Показываем сообщение о способности
			if is_crit:
				var damage_type_text = "МАГИЧЕСКИЙ" if damage_type == "magic" else "ФИЗИЧЕСКИЙ"
				_show_message("ВРАГ ИСПОЛЬЗОВАЛ %s! КРИТИЧЕСКИЙ %s УРОН: %d" % [enemy_ability.name, damage_type_text, damage], 2.0)
			else:
				var damage_type_text = "магический" if damage_type == "magic" else "физический"
				_show_message("Враг использовал %s! %s урон: %d" % [enemy_ability.name, damage_type_text, damage], 1.5)
			
			# Логируем урон от способности врага
			# Для многоударных способностей (Двойной удар, Магические стрелы) нужно рассчитать реальный урон
			var actual_damage_from_ability = damage
			if result.get("double_strike", false):
				# Для Двойного удара берем РЕАЛЬНЫЙ урон после брони из счетчика урона за раунд
				if "damage_taken_this_round" in player_node:
					actual_damage_from_ability = player_node.damage_taken_this_round
				else:
					# Fallback: если счетчика нет, берем сумму урона до брони (не идеально, но лучше чем 0)
					var first_dmg = result.get("first_hit_damage", 0)
					var second_dmg = result.get("second_hit_damage", 0)
					actual_damage_from_ability = first_dmg + second_dmg
			
			battle_log.log_damage(enemy_node.display_name, player_node.display_name, actual_damage_from_ability, is_crit, damage_type, enemy_node.level, player_node.level, player_node.hp, player_node.max_hp, enemy_ability.name)
			
	# Если способность не использована, делаем базовую атаку
	if not ability_used:
		# Определяем урон базовой атаки (для бойцов: сила + ловкость, для магов: интеллект + мудрость)
		if enemy_node.has_method("get_base_attack_damage"):
			damage = enemy_node.get_base_attack_damage()
		else:
			# Fallback для старой системы
			damage = enemy_node.strength + enemy_node.agility
		
		# Применяем бонус редкости к урону
		damage = _apply_rarity_damage_bonus(damage, enemy_node.rarity)
		is_crit = enemy_node.is_critical_hit()
		
		# Определяем тип урона базовой атаки (физический для бойцов, магический для магов)
		var is_mage = enemy_node.intelligence >= enemy_node.agility and enemy_node.intelligence >= enemy_node.strength
		damage_type = "magic" if is_mage else "physical"
		
		if is_crit:
			# Используем новую функцию для применения критического множителя
			damage = enemy_node.apply_crit_multiplier(damage)
			var damage_type_text = "МАГИЧЕСКИЙ" if damage_type == "magic" else "ФИЗИЧЕСКИЙ"
			# Показываем сообщение о базовой атаке с указанием кулдауна (если способность на кулдауне)
			if ability_on_cooldown:
				_show_message("СПОСОБНОСТЬ НА ПЕРЕЗАРЯДКЕ! ВРАГ НАНЁС КРИТИЧЕСКИЙ %s УДАР! УРОН: %d" % [damage_type_text, damage], 2.0)
			else:
				_show_message("ВРАГ НАНЁС КРИТИЧЕСКИЙ %s УДАР! УРОН: %d" % [damage_type_text, damage], 2.0)
		else:
			var damage_type_text = "магический" if damage_type == "magic" else "физический"
			# Показываем сообщение о базовой атаке с указанием кулдауна (если способность на кулдауне)
			if ability_on_cooldown:
				_show_message("Способность на перезарядке! Враг нанёс %s урон: %d" % [damage_type_text, damage], 1.5)
			else:
				_show_message("Враг нанёс %s урон: %d" % [damage_type_text, damage], 1.5)
		
		# Пассивные способности врага будут активированы после нанесения урона
		
		# Активируем пассивные способности игрока ПЕРЕД получением урона
		var context = {"damage": damage, "target": player_node}
		player_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_DAMAGE_TAKEN, enemy_node, context)
		
		# Проверяем попадание с учетом меткости и уворота
		if not _calculate_hit_chance(enemy_node, player_node, "main_attack", "Базовая атака"):
			# Показываем всплывающую цифру промаха
			DamageNumberManager.show_damage_on_character(player_node, 0, false, true, false, damage_type)
			_show_message("Враг промахнулся!", 1.0)
			
			# НЕ переходим к ходу игрока - враг завершает свой ход
			await get_tree().create_timer(0.5).timeout
			
			# Проверяем дополнительное действие врага
			if not player_node.is_dead() and enemy_node.has_method("check_extra_action"):
				if enemy_node.check_extra_action():
					await get_tree().create_timer(0.5).timeout
					# Повторяем атаку врага
					await _enemy_action()
					return
			
			# Переходим к следующему врагу или игроку
			if get_alive_enemy_count() > 1:
				await _process_next_enemy_turn()
			else:
				_set_player_turn()
			return
		
		# Сохраняем информацию о критическом ударе для логирования
		enemy_node.last_attack_was_crit = is_crit
		enemy_node.last_attack_damage_type = damage_type
		
		# Запускаем анимацию атаки ДО нанесения урона
		var enemy_visual = enemy_node.get_node_or_null("Visual")
		if enemy_visual and enemy_visual.has_method("play_attack"):
			enemy_visual.play_attack()
		
		# Задержка для синхронизации с анимацией атаки (момент удара)
		await get_tree().create_timer(0.3).timeout
		
		# Проигрываем звук в момент попадания
		# Сначала проверяем конкретных врагов (независимо от типа урона)
		if enemy_node.display_name == "Слизень":
			# Используем SoundManager для звука базовой атаки слизня
			if SoundManager:
				SoundManager.play_sound("slime_attack", -5.0)
		elif damage_type == "magic":
			var audio_player = AudioStreamPlayer.new()
			audio_player.stream = load("res://Audio/Sounds/magic_attack1.wav")
			audio_player.volume_db = 0.0
			audio_player.bus = "Master"
			add_child(audio_player)
			audio_player.play()
			audio_player.finished.connect(func(): audio_player.queue_free())
		elif damage_type == "physical" and enemy_node.display_name == "Крыса":
			var audio_player = AudioStreamPlayer.new()
			audio_player.stream = load("res://Audio/Sounds/rat_attack1.wav")
			audio_player.volume_db = -10.0
			audio_player.bus = "Master"
			add_child(audio_player)
			audio_player.play()
			audio_player.finished.connect(func(): audio_player.queue_free())
		elif damage_type == "physical" and enemy_node.display_name == "Гоблин Вор":
			var audio_player = AudioStreamPlayer.new()
			audio_player.stream = load("res://Audio/Sounds/sword_attack1.wav")
			audio_player.volume_db = -5.0
			audio_player.bus = "Master"
			add_child(audio_player)
			audio_player.play()
			audio_player.finished.connect(func(): audio_player.queue_free())
		elif damage_type == "physical" and enemy_node.display_name == "ExecutionerDemon":
			var audio_player = AudioStreamPlayer.new()
			audio_player.stream = load("res://Audio/Sounds/sword_attack3.wav")
			audio_player.volume_db = -5.0
			audio_player.bus = "Master"
			add_child(audio_player)
			audio_player.play()
			audio_player.finished.connect(func(): audio_player.queue_free())
		elif damage_type == "physical" and enemy_node.display_name == "Гоблин Воин":
			var audio_player = AudioStreamPlayer.new()
			audio_player.stream = load("res://Audio/Sounds/sword_attack1.wav")
			audio_player.volume_db = -5.0
			audio_player.bus = "Master"
			add_child(audio_player)
			audio_player.play()
			audio_player.finished.connect(func(): audio_player.queue_free())
		
		# Сохраняем HP игрока до нанесения урона для вычисления фактического урона
		var player_old_hp = player_node.hp
		
		# Наносим урон синхронно со звуком попадания
		player_node.take_damage(damage, damage_type)
		
		# Вычисляем фактический урон после вычета брони
		var actual_damage = player_old_hp - player_node.hp
		
		# Показываем всплывающую цифру фактического урона от базовой атаки врага (только для базовых атак!)
		DamageNumberManager.show_damage_on_character(player_node, actual_damage, is_crit, false, false, damage_type)
		
		# Логируем урон от базовой атаки врага
		battle_log.log_damage(enemy_node.display_name, player_node.display_name, actual_damage, is_crit, damage_type, enemy_node.level, player_node.level, player_node.hp, player_node.max_hp, "Базовая атака")
		
		# Тряска камеры при критическом ударе врага
		if is_crit and camera and camera.has_method("shake"):
			camera.shake(0.3, 15.0)
		
		# Активируем пассивные способности врага при атаке (только один раз)
		var context_attack = {"damage": damage, "target": player_node, "ability_used": false, "is_critical": is_crit, "damage_type": damage_type}
		enemy_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, player_node, context_attack)
	else:
		# Если способность была использована, сохраняем информацию о критическом ударе
		enemy_node.last_attack_was_crit = is_crit
		enemy_node.last_attack_damage_type = damage_type
	
	# Анимация уже проиграна либо для базовой атаки, либо для способности
	# (специальная анимация проигрывается в обработке способности)
	
	# Проверяем дополнительные атаки от пассивных способностей СРАЗУ после основной атаки
	# (важно делать это ДО проверки очков действий, чтобы пассивки типа "Суетливость" сработали)
	_check_extra_attacks(enemy_node, player_node, "physical")
	
	# Тратим очко действий врага
	if enemy_node.has_method("spend_action_point"):
		enemy_node.spend_action_point()
	
	# Проверяем, есть ли еще очки действий у врага
	if enemy_node.has_method("has_action_points") and enemy_node.has_action_points():
		await get_tree().create_timer(0.5).timeout
		# Повторяем действие врага
		await _enemy_action()
		return
	
	# Враг завершил все свои действия - переходим к следующему врагу или игроку
	if not player_node.is_dead():
		# В режиме множественных врагов переходим к следующему врагу
		if get_alive_enemy_count() > 1:
			await _process_next_enemy_turn()
		else:
			_set_player_turn()
	

func _handle_damage_reflection(target: Node, _attacker: Node):
	"""Обрабатывает отражение урона (Страж Тарнока)"""
	if not target or not target.has_method("get_pending_reflected_damage"):
		return
	
	var reflected_info = target.get_pending_reflected_damage()
	if reflected_info.is_empty():
		return
	
	var reflected_damage = reflected_info.get("damage", 0)
	var reflected_target = reflected_info.get("target", null)
	if reflected_damage > 0 and reflected_target and is_instance_valid(reflected_target):
		# Наносим отраженный урон атакующему
		var reflected_target_old_hp = reflected_target.hp
		reflected_target.take_damage(reflected_damage, "physical")
		var actual_reflected_damage = reflected_target_old_hp - reflected_target.hp
		
		if actual_reflected_damage > 0:
			# Показываем всплывающую цифру отраженного урона
			DamageNumberManager.show_damage_on_character(reflected_target, actual_reflected_damage, false, false, false, "physical")
			
			# Логируем отражение урона
			if battle_log:
				battle_log.log_event("damage_reflected", target.display_name, reflected_target.display_name, actual_reflected_damage, target.display_name + " отражает " + str(actual_reflected_damage) + " урона!")
		
		# Очищаем информацию об отраженном уроне
		target.clear_pending_reflected_damage()

func _check_extra_attacks(attacker: Node, target: Node, damage_type: String):
	"""Проверяет дополнительные атаки от пассивных способностей"""
	# Проверяем, есть ли эффект "quick_strike" у атакующего
	if attacker.has_effect("quick_strike"):
		# Дополнительная атака использует новую систему физического урона
		var extra_damage: int
		if attacker.has_method("get_physical_damage"):
			extra_damage = attacker.get_physical_damage()
		else:
			# Fallback для старой системы
			extra_damage = attacker.strength + attacker.agility
		var is_crit = attacker.is_critical_hit()
		
		if is_crit:
			extra_damage = attacker.apply_crit_multiplier(extra_damage)
		
		# Проверяем уворот для дополнительной атаки
		if _calculate_hit_chance(attacker, target, "quick_strike", "Быстрый удар"):
			# Сохраняем HP цели до нанесения урона
			var target_old_hp = target.hp
			
			# Наносим дополнительный урон
			target.take_damage(extra_damage, damage_type)
			
			# Вычисляем фактический урон
			var actual_damage = target_old_hp - target.hp
			
			# Активируем пассивные способности цели ПОСЛЕ нанесения урона с фактическим уроном
			var context = {"damage": actual_damage, "target": target}
			target.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_DAMAGE_TAKEN, attacker, context)
			
			# Проверяем отражение урона
			_handle_damage_reflection(target, attacker)
			
			# Логируем дополнительную атаку
			battle_log.log_damage(attacker.display_name, target.display_name, extra_damage, is_crit, damage_type, attacker.level, target.level, target.hp, target.max_hp)
		
		# Убираем эффект после использования
		attacker.remove_effect("quick_strike")
	
	# Проверяем, есть ли эффект "restlessness_attack" у атакующего
	if attacker.has_effect("restlessness_attack"):
		# Суетливая атака с уменьшенным уроном
		var effect = attacker.effects.get("restlessness_attack", {})
		if effect is Dictionary:
			var damage_reduction = effect.get("damage_reduction", 0.4)
			
			# Дополнительная атака использует базовый урон врага с уменьшением
			# Получаем базовый физический урон врага БЕЗ бонусов
			var base_damage: int
			if attacker.has_method("get_base_physical_damage"):
				base_damage = attacker.get_base_physical_damage()
			else:
				# Fallback для старой системы - только характеристики без бонусов
				base_damage = attacker.strength + attacker.agility
			
			# Применяем уменьшение урона (например, -40%)
			# damage_reduction уже в процентах (0.4 = 40%), поэтому не делим на 100
			var extra_damage = int(base_damage * (1.0 - damage_reduction))
			
			# Применяем те же модификаторы, что и для обычной атаки
			# (броня, сопротивление и т.д. будут применены в take_damage)
			var is_crit = attacker.is_critical_hit()
			
			if is_crit:
				extra_damage = int(attacker.apply_crit_multiplier(extra_damage))
			
			# Показываем сообщение о срабатывании Суетливости
			_show_message(attacker.display_name + " использует Суетливость! (урон -" + str(int(damage_reduction * 100)) + "%)", 1.5)
			
			# Проверяем уворот для дополнительной атаки
			if _calculate_hit_chance(attacker, target, "restlessness", "Суетливая атака"):
				# Сохраняем HP цели до нанесения урона
				var target_old_hp = target.hp
				
				# Активируем пассивные способности цели перед получением дополнительного урона
				var context = {"damage": extra_damage, "target": target}
				target.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_DAMAGE_TAKEN, attacker, context)
				
				# Наносим дополнительный урон
				target.take_damage(extra_damage, damage_type)
				
				# Вычисляем фактический урон
				var actual_damage = target_old_hp - target.hp
				
				# Показываем всплывающую цифру урона от Суетливой атаки
				DamageNumberManager.show_damage_on_character(target, actual_damage, is_crit, false, false, damage_type)
				
				# Логируем урон в боевой лог
				battle_log.log_damage(attacker.display_name, target.display_name, actual_damage, is_crit, damage_type, attacker.level, target.level, target.hp, target.max_hp, "Суетливая атака")
			else:
				# Показываем всплывающую цифру промаха
				DamageNumberManager.show_damage_on_character(target, 0, false, true, false, damage_type)
				# Логируем промах в боевой лог
				battle_log.log_event("miss", attacker.display_name, target.display_name, 0, "промахнулся с Суетливой атакой")
			
			# Убираем эффект после использования
			attacker.remove_effect("restlessness_attack")

func _on_enemy_died():
	"""Вызывается когда ОДИН враг умирает - проигрываем анимации сразу, награды только когда все мертвы"""
	# Находим врага, который только что умер (hp <= 0 и еще не обработан)
	var dead_enemy = null
	for enemy in enemy_nodes:
		if is_instance_valid(enemy) and enemy.hp <= 0:
			# Проверяем, не обработан ли уже этот враг
			if not enemy.get_meta("death_processed", false):
				dead_enemy = enemy
				break
	
	# Если не нашли врага, который только что умер, проверяем, все ли враги мертвы
	if not dead_enemy:
		if are_all_enemies_dead():
			_handle_victory()
		return
	
	# Помечаем врага как обработанного
	dead_enemy.set_meta("death_processed", true)
	
	# СРАЗУ проигрываем анимацию смерти для этого врага
	var enemy_visual = dead_enemy.get_node_or_null("Visual")
	if enemy_visual and enemy_visual.has_method("play_die"):
		enemy_visual.play_die()
	
	# СРАЗУ запускаем анимацию поглощения частиц душ для этого врага
	if soul_particle_manager and player_node:
		var enemy_position = dead_enemy.global_position
		var enemy_rarity = dead_enemy.rarity
		var enemy_level = dead_enemy.level
		soul_particle_manager.spawn_soul_particles(enemy_position, player_node, enemy_rarity, enemy_level)
	
	# Если выбранный враг умер, выбираем другого живого врага
	if selected_target_enemy == dead_enemy:
		var alive = get_alive_enemies()
		if alive.size() > 0:
			selected_target_enemy = alive[0]
			selected_target_index = 0
			if ui.has_method("highlight_selected_target_enemy"):
				ui.highlight_selected_target_enemy(selected_target_enemy)
			elif ui.has_method("highlight_selected_target"):
				ui.highlight_selected_target(selected_target_index)
		else:
			selected_target_enemy = null
			selected_target_index = 0
	
	# Проверяем, все ли враги мертвы
	if not are_all_enemies_dead():
		print("Враг умер, но остались живые враги. Бой продолжается...")
		return
	
	# ВСЕ враги мертвы - обрабатываем награды и победу
	_handle_victory()

func _handle_victory():
	"""Обрабатывает победу: награды, прогресс способностей, сообщения"""
	# Сбрасываем кулдауны после победы
	if AbilitySlotManager:
		AbilitySlotManager.reset_cooldowns()
	
	# Собираем прогресс способностей от ВСЕХ врагов
	var ability_progress = []
	
	# Собираем информацию о наградах ДО их начисления
	var rewards_info = _collect_rewards_info()
	
	# Обрабатываем каждого мертвого врага (награды)
	for dead_enemy in enemy_nodes:
		if not is_instance_valid(dead_enemy):
			continue
		
		# Проверяем, был ли враг элитным для двойного прогресса
		var is_elite = dead_enemy.rarity.begins_with("elite_")
		if is_elite:
			# Временно устанавливаем enemy_node для совместимости с _apply_elite_rewards()
			var old_enemy_elite = enemy_node
			if enemy_nodes.size() > 0:
				enemy_nodes[0] = dead_enemy
			var elite_progress = _apply_elite_rewards()
			ability_progress.append_array(elite_progress)
			if old_enemy_elite and enemy_nodes.size() > 0:
				enemy_nodes[0] = old_enemy_elite
		
		# Рассчитываем и добавляем осколки душ за этого врага
		var old_enemy = enemy_node
		if enemy_nodes.size() > 0:
			enemy_nodes[0] = dead_enemy
		_calculate_and_award_soul_shards()
		if old_enemy and enemy_nodes.size() > 0:
			enemy_nodes[0] = old_enemy
		
		# Проверяем, выпадает ли артефакт с этого врага
		var old_enemy2 = enemy_node
		if enemy_nodes.size() > 0:
			enemy_nodes[0] = dead_enemy
		_check_and_give_artifact()
		if old_enemy2 and enemy_nodes.size() > 0:
			enemy_nodes[0] = old_enemy2
	
	# Проверяем, был ли это босс, и разблокируем следующую сложность
	_check_and_unlock_next_difficulty()
	
	# Сохраняем информацию о побежденных врагах и получаем прогресс способностей
	var normal_progress = await _save_battle_result()
	ability_progress.append_array(normal_progress)
	
	# Добавляем опыт игроку
	if player_manager and rewards_info.has("exp"):
		player_manager.player_data.add_experience(rewards_info.exp)
	
	# Показываем красивый экран победы с наградами
	_show_victory_screen(ability_progress, rewards_info)

func _collect_rewards_info() -> Dictionary:
	"""Собирает информацию о наградах до их начисления"""
	if enemy_nodes.size() == 0 or not player_manager:
		return {}
	
	var enemies_data = []
	var total_exp = 0
	var total_soul_shards = 0
	var total_strong_souls = 0
	var total_great_souls = 0
	var total_divine_souls = 0
	
	# Обрабатываем каждого врага
	for dead_enemy in enemy_nodes:
		if not is_instance_valid(dead_enemy):
			continue
		
		var enemy_data = {
			"name": dead_enemy.display_name,
			"level": dead_enemy.level,
			"rarity": dead_enemy.rarity
		}
		enemies_data.append(enemy_data)
		
		# Подсчитываем опыт
		var exp_reward = player_manager.player_data.calculate_battle_exp(dead_enemy.level)
		total_exp += exp_reward
		
		# Подсчитываем осколки душ
		if soul_shard_manager:
			var shards = soul_shard_manager.calculate_soul_shards_for_enemy(dead_enemy.level, dead_enemy.rarity)
			total_soul_shards += shards
		
		# Подсчитываем специальные валюты
		var enemy_rarity = dead_enemy.rarity.to_lower()
		if enemy_rarity.begins_with("elite_"):
			total_strong_souls += 1
		elif enemy_rarity == "boss":
			total_great_souls += 1
		elif enemy_rarity == "mythic" or enemy_rarity == "mythical":
			total_divine_souls += 1
	
	return {
		"enemies": enemies_data,
		"exp": total_exp,
		"soul_shards": total_soul_shards,
		"strong_souls": total_strong_souls,
		"great_souls": total_great_souls,
		"divine_souls": total_divine_souls
	}

func _show_victory_screen(ability_progress: Array, rewards_info: Dictionary):
	"""Показывает красивый экран победы с полной информацией о наградах"""
	
	if rewards_info.is_empty():
		print("ОШИБКА: Нет информации о наградах!")
		# Вместо показа кнопки "Далее", выполняем переход напрямую
		# (это не должно происходить в нормальной игре, но на случай ошибки)
		_on_next_pressed()
		return
	
	# Формируем данные для экрана победы
	var victory_data = {
		"enemies": rewards_info.get("enemies", []),
		"exp": rewards_info.get("exp", 0),
		"soul_shards": rewards_info.get("soul_shards", 0),
		"strong_souls": rewards_info.get("strong_souls", 0),
		"great_souls": rewards_info.get("great_souls", 0),
		"divine_souls": rewards_info.get("divine_souls", 0),
		"ability_progress": ability_progress
	}
	
	# Задержка перед появлением экрана победы
	await get_tree().create_timer(1.5).timeout
	
	# Загружаем и показываем экран победы
	var victory_scene = preload("res://Scenes/UI/VictoryScreen.tscn")
	var victory_instance = victory_scene.instantiate()
	# Устанавливаем высокий z_index, чтобы экран победы был поверх имен врагов
	victory_instance.z_index = 200
	add_child(victory_instance)
	# Настраиваем данные после добавления в дерево
	victory_instance.setup_victory_data(victory_data)

func _on_player_died():
	# проигрываем анимацию смерти
	var visual = player_node.get_node_or_null("Visual")
	if visual and visual.has_method("play_die"):
		visual.play_die()
	
	# Игрок теряет половину осколков душ за забег
	if soul_shard_manager:
		var lost_amount = soul_shard_manager.lose_half_run_soul_shards()
		if lost_amount > 0:
			_show_message("Потеряно осколков душ: %d" % lost_amount, 3.0)
		
		# Переносим оставшиеся осколки душ в хранилище (Колодец душ)
		var deposited_amount = soul_shard_manager.deposit_run_soul_shards()
		if deposited_amount > 0:
			_show_message("Осколки душ перенесены в Колодец душ: %d" % deposited_amount, 3.0)
	
	# Ждем немного, чтобы анимация смерти успела проиграться
	await get_tree().create_timer(2.0).timeout
	
	# Показываем экран поражения
	_show_defeat_screen()
	
	# Отправляем сигнал о поражении
	emit_signal("battle_ended", false)


func _on_player_attacked(amount):
	# ВАЖНО: НЕ логируем урон здесь!
	# Урон от атак логируется в _enemy_action()
	# Урон от эффектов логируется в process_effects()
	# Эта функция вызывается при ЛЮБОМ уроне (включая яд), 
	# поэтому логирование здесь приводит к дублированию и ошибкам в логе
	
	# Воспроизводим звук получения урона игроком
	if SoundManager and amount > 0:
		SoundManager.play_sound("Hit1", -5.0)
	
	# Визуальный эффект получения урона (белая вспышка)
	if player_node and amount > 0:
		_flash_white(player_node)
	
	# Сообщение об уроне показываем только если это НЕ урон от эффекта
	# (урон от эффектов показывается в process_effects)
	# Проверяем, идет ли ход врага (тогда это атака)
	if state == "enemy_turn":
		# Получаем исходный урон из контекста атаки (от врага)
		var original_damage = 0
		if enemy_node and enemy_node.has_method("get_last_attack_damage"):
			original_damage = enemy_node.get_last_attack_damage()
		
		# Показываем сообщение с информацией о блокированном уроне
		if original_damage > 0 and original_damage > amount:
			var blocked_damage = original_damage - amount
			_show_message("Ты получил %d урона (заблокировано %d броней)" % [amount, blocked_damage], 2.0)
		else:
			_show_message("Ты получил %d урона" % amount, 2.0)

func _handle_healing_ability(result: Dictionary, _ability: PlayerAbility):
	"""Обрабатывает лечебные способности"""
	var heal_amount = result.get("heal_amount", 0)
	var _mp_restore = result.get("mp_restore", 0)
	var _stamina_restore = result.get("stamina_restore", 0)
	var message = result.get("message", "Восстановление!")
	
	# Показываем сообщение
	_show_message(message, 2.0)
	
	# Логируем восстановление в боевой лог
	if battle_log:
		battle_log.log_heal(player_node.display_name, player_node.display_name, heal_amount, player_node.hp, player_node.max_hp)
	
	# Обновляем UI
	if ui and ui.has_method("_update_ui"):
		ui._update_ui()

func _on_enemy_attacked(amount):
	# Визуальный эффект получения урона (белая вспышка)
	# Используем enemy_node, так как сигнал приходит от конкретного врага
	# Но нужно найти правильного врага из enemy_nodes
	var attacked_enemy = null
	# Ищем врага, который недавно получил урон (HP уменьшился)
	for enemy in enemy_nodes:
		if is_instance_valid(enemy) and enemy.hp < enemy.max_hp:
			# Проверяем, что это не игрок
			if enemy.display_name != "Player" and enemy.display_name != "Игрок":
				attacked_enemy = enemy
				break
	
	# Если не нашли, используем enemy_node как fallback
	if not attacked_enemy:
		attacked_enemy = enemy_node
	
	if attacked_enemy and amount > 0:
		_flash_white(attacked_enemy)
		# Анимация hurt теперь вызывается автоматически в take_damage в body.gd
	
	# Получаем исходный урон из контекста атаки (от игрока)
	var original_damage = 0
	if player_node and player_node.has_method("get_last_attack_damage"):
		original_damage = player_node.get_last_attack_damage()
	
	# Проверяем, не используется ли способность игрока
	if state == "player_turn" and player_node.using_ability:
		# Это способность, логируем фактический урон с учетом сопротивлений и барьеров
		var ability_name = ""
		if player_node.has_method("get_current_ability_name"):
			ability_name = player_node.get_current_ability_name()
		
		# Определяем тип урона и критический удар
		var ability_damage_type = "physical"
		var ability_is_crit = false
		if player_node.has_method("get_last_attack_damage_type"):
			ability_damage_type = player_node.get_last_attack_damage_type()
		if player_node.has_method("get_last_attack_was_crit"):
			ability_is_crit = player_node.get_last_attack_was_crit()
		
		# Логируем фактический урон от способности
		battle_log.log_damage(player_node.display_name, enemy_node.display_name, amount, ability_is_crit, ability_damage_type, player_node.level, enemy_node.level, enemy_node.hp, enemy_node.max_hp, ability_name)
		
		# Показываем сообщение с информацией о блокированном уроне
		if original_damage > 0 and original_damage > amount:
			var blocked_damage = original_damage - amount
			if ability_is_crit:
				_show_message("КРИТИЧЕСКИЙ УДАР! Враг получил %d урона (заблокировано %d сопротивлением)" % [amount, blocked_damage], 2.0)
			else:
				_show_message("Враг получил %d урона (заблокировано %d сопротивлением)" % [amount, blocked_damage], 2.0)
		else:
			if ability_is_crit:
				_show_message("КРИТИЧЕСКИЙ УДАР! Враг получил %d урона" % amount, 2.0)
			else:
				_show_message("Враг получил %d урона" % amount, 2.0)
		
		# Сбрасываем флаг использования способности
		player_node.using_ability = false
		return
	
	# Проверяем, не является ли это уроном от эффекта (кровотечение, яд и т.д.)
	# Урон от эффектов не должен логироваться как "Обычная атака"
	if state == "enemy_turn" and enemy_node.has_method("is_processing_effects") and enemy_node.is_processing_effects():
		# Это урон от эффекта, не логируем здесь - логирование происходит в _log_effect_damage
		return
	
	# Это обычная атака, логируем фактический урон с учетом сопротивлений и барьеров
	var attack_ability_name = ""
	if player_node.has_method("get_current_ability_name"):
		attack_ability_name = player_node.get_current_ability_name()
	
	# Определяем тип урона и критический удар
	var damage_type = "physical"
	var is_crit = false
	if player_node.has_method("get_last_attack_damage_type"):
		damage_type = player_node.get_last_attack_damage_type()
	if player_node.has_method("get_last_attack_was_crit"):
		is_crit = player_node.get_last_attack_was_crit()
	
	# Логируем фактический урон от обычной атаки
	battle_log.log_damage(player_node.display_name, enemy_node.display_name, amount, is_crit, damage_type, player_node.level, enemy_node.level, enemy_node.hp, enemy_node.max_hp, attack_ability_name)
	
	# Сбрасываем тип атаки после логирования
	if enemy_node.has_method("set_last_attack_type"):
		enemy_node.set_last_attack_type("normal")
	
	# Показываем сообщение с информацией о блокированном уроне
	if original_damage > 0 and original_damage > amount:
		var blocked_damage = original_damage - amount
		if is_crit:
			_show_message("КРИТИЧЕСКИЙ УДАР! Враг получил %d урона (заблокировано %d сопротивлением)" % [amount, blocked_damage], 2.0)
		else:
			_show_message("Враг получил %d урона (заблокировано %d сопротивлением)" % [amount, blocked_damage], 2.0)
	else:
		if is_crit:
			_show_message("КРИТИЧЕСКИЙ УДАР! Враг получил %d урона" % amount, 2.0)
		else:
			_show_message("Враг получил %d урона" % amount, 2.0)


func _show_message(text: String, duration: float = 2.0) -> void:
	var lbl = $UI/MessageLog
	if lbl:
		lbl.text = text
		print("Сообщение: ", text)
	
	# Устанавливаем таймер для автоматического очищения сообщения
	if message_timer:
		# Останавливаем предыдущий таймер
		message_timer.stop()
		
		# Отключаем все сигналы timeout
		if message_timer.is_connected("timeout", Callable(self, "_clear_message")):
			message_timer.disconnect("timeout", Callable(self, "_clear_message"))
		
		message_timer.wait_time = duration
		message_timer.start()
		message_timer.connect("timeout", Callable(self, "_clear_message"), CONNECT_ONE_SHOT)




func _clear_message():
	var lbl = $UI/MessageLog
	if lbl:
		lbl.text = ""


func _show_next_button():
	# Создаем кнопку "Далее" если её нет
	if not ui.has_node("Btn_Next"):
		var next_btn = Button.new()
		next_btn.name = "Btn_Next"
		next_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		next_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		# Позиционируем кнопку в центре экрана
		next_btn.anchor_left = 0.5
		next_btn.anchor_right = 0.5
		next_btn.anchor_top = 0.5
		next_btn.anchor_bottom = 0.5
		next_btn.offset_left = -100
		next_btn.offset_right = 100
		next_btn.offset_top = -25
		next_btn.offset_bottom = 25
		ui.add_child(next_btn)
		next_btn.connect("pressed", Callable(self, "_on_next_pressed"))
	
	# Показываем кнопку с правильным текстом
	var btn = ui.get_node("Btn_Next")
	if btn:
		# Устанавливаем текст в зависимости от режима
		if test_mode:
			btn.text = "Выбрать другого врага"
		else:
			btn.text = "Далее →"
		btn.visible = true
	else:
		print("ОШИБКА: Кнопка 'Далее' не найдена!")

func _save_battle_result() -> Array:
	# Сохраняем информацию о побежденных врагах в глобальный менеджер
	var battle_result = get_node_or_null("/root/BattleResult")
	if not battle_result:
		# Создаем менеджер если его нет
		var script = load("res://Scripts/BattleResult.gd")
		battle_result = Node.new()
		battle_result.set_script(script)
		battle_result.name = "BattleResult"
		get_tree().root.add_child(battle_result)
		await get_tree().process_frame
	
	var progress_gained = []
	
	# Сохраняем данные о каждом враге
	for dead_enemy in enemy_nodes:
		if not is_instance_valid(dead_enemy):
			continue
		
		battle_result.set_battle_result(dead_enemy.level, dead_enemy.rarity, true)
		
		# Временно устанавливаем enemy_node для совместимости
		var old_enemy = enemy_node
		if enemy_nodes.size() > 0:
			enemy_nodes[0] = dead_enemy
		
		# Добавляем прогресс изучения пассивных способностей от этого врага
		var enemy_progress = await _add_ability_learning_progress()
		progress_gained.append_array(enemy_progress)
		
		# Добавляем прогресс изучения активных способностей от этого врага
		_add_active_ability_learning_progress()
		
		# Восстанавливаем
		if old_enemy and enemy_nodes.size() > 0:
			enemy_nodes[0] = old_enemy
	
	return progress_gained

func _add_ability_learning_progress() -> Array:
	"""Добавляет прогресс изучения способностей после победы над врагом. Возвращает список полученного прогресса."""
	var ability_learning_system = get_node_or_null("/root/AbilityLearningSystem")
	var progress_gained = []
	
	# Если система не найдена, создаем её
	if not ability_learning_system:
		print("AbilityLearningSystem не найден, создаем систему...")
		var system_script = preload("res://Scripts/Systems/AbilityLearningSystem.gd")
		ability_learning_system = Node.new()
		ability_learning_system.set_script(system_script)
		ability_learning_system.name = "AbilityLearningSystem"
		get_tree().root.add_child(ability_learning_system)
		await get_tree().process_frame
		print("AbilityLearningSystem создан и добавлен в сцену")
	
	if enemy_node:
		# Определяем тип врага по его имени
		var enemy_type = "rat"  # По умолчанию крыса
		if "rat" in enemy_node.name.to_lower():
			enemy_type = "rat"
		elif "bat" in enemy_node.name.to_lower() or "мыш" in enemy_node.display_name.to_lower():
			enemy_type = "Летучая мышь"
		elif "rotten" in enemy_node.name.to_lower() or "гнил" in enemy_node.display_name.to_lower():
			enemy_type = "гнилой_слизень"
		elif "slime" in enemy_node.name.to_lower() or "слиз" in enemy_node.display_name.to_lower():
			enemy_type = "слизень"
		elif "goblin" in enemy_node.name.to_lower() or "гоблин" in enemy_node.display_name.to_lower():
			# Определяем подтип гоблина
			if "вор" in enemy_node.display_name.to_lower() or "thief" in enemy_node.name.to_lower():
				enemy_type = "гоблин_вор"
			elif "колдун" in enemy_node.display_name.to_lower() or "mage" in enemy_node.name.to_lower():
				enemy_type = "гоблин_колдун"
			elif "воин" in enemy_node.display_name.to_lower() or "warrior" in enemy_node.name.to_lower():
				enemy_type = "гоблин_воин"
			else:
				enemy_type = "гоблин"
		elif "skeleton" in enemy_node.name.to_lower() or "скелет" in enemy_node.display_name.to_lower():
			# Определяем подтип скелета
			if "арбалет" in enemy_node.display_name.to_lower() or "crossbow" in enemy_node.name.to_lower():
				enemy_type = "Скелет Арбалетчик"
			elif "меч" in enemy_node.display_name.to_lower() or "sword" in enemy_node.name.to_lower():
				enemy_type = "Скелет Мечник"
			elif "элит" in enemy_node.display_name.to_lower() or "elite" in enemy_node.name.to_lower():
				enemy_type = "Элитный Скелет"
			else:
				enemy_type = "Скелет"
		elif "ghoul" in enemy_node.name.to_lower() or "гуль" in enemy_node.display_name.to_lower():
			enemy_type = "Гуль"
		elif "orc" in enemy_node.name.to_lower() or "орк" in enemy_node.display_name.to_lower():
			# Определяем подтип орка
			if "лучник" in enemy_node.display_name.to_lower() or "archer" in enemy_node.name.to_lower():
				enemy_type = "Орк лучник"
			elif "убийца" in enemy_node.display_name.to_lower() or "assassin" in enemy_node.name.to_lower():
				enemy_type = "Орк убийца"
			elif "берсерк" in enemy_node.display_name.to_lower() or "berserker" in enemy_node.name.to_lower():
				enemy_type = "Орк берсерк"
			elif "шаман" in enemy_node.display_name.to_lower() or "shaman" in enemy_node.name.to_lower():
				enemy_type = "Орк шаман"
			else:
				enemy_type = "Орк"
		elif "alkara" in enemy_node.name.to_lower() or "алкара" in enemy_node.display_name.to_lower():
			enemy_type = "AlkaraDemon"
		elif "curse" in enemy_node.name.to_lower() or "проклят" in enemy_node.display_name.to_lower():
			enemy_type = "CurseDemon"
		elif "executioner" in enemy_node.name.to_lower() or "палач" in enemy_node.display_name.to_lower():
			enemy_type = "ExecutionerDemon"
		elif "tharnok" in enemy_node.name.to_lower() or "тарнок" in enemy_node.display_name.to_lower():
			enemy_type = "TharnokDemon"
		elif "dark" in enemy_node.name.to_lower() or "тёмный" in enemy_node.display_name.to_lower() or "шатун" in enemy_node.display_name.to_lower():
			enemy_type = "Тёмный шатун"
		
		# Получаем редкость врага
		var enemy_rarity = enemy_node.rarity.to_lower()
		
		# Добавляем прогресс изучения и получаем список полученного прогресса
		progress_gained = ability_learning_system.add_progress(enemy_type, enemy_rarity)
	
	return progress_gained

func _add_active_ability_learning_progress() -> void:
	"""Добавляет прогресс изучения активных способностей после победы над врагом"""
	var active_ability_system = get_node_or_null("/root/ActiveAbilityLearningSystem")
	
	if not active_ability_system:
		print("ActiveAbilityLearningSystem не найден!")
		return
	
	if not enemy_node:
		return
	
	# Маппинг типов врагов на enemy_type в конфигурации
	var enemy_type_map = {
		"rat": "rat",
		"крыса": "rat",
		"слизень": "slime",
		"slime": "slime",
		"гнилой слизень": "rotten_slime",
		"rotten slime": "rotten_slime",
		"летучая мышь": "bat",
		"bat": "bat",
		"гоблин воин": "goblin_warrior",
		"goblin warrior": "goblin_warrior",
		"гоблин вор": "goblin_thief",
		"goblin thief": "goblin_thief",
		"гоблин колдун": "goblin_mage",
		"goblin mage": "goblin_mage",
		"скелет арбалетчик": "skeleton_crossbowman",
		"skeleton crossbowman": "skeleton_crossbowman",
		"скелет мечник": "skeleton_swordsman",
		"skeleton swordsman": "skeleton_swordsman",
		"гуль": "ghoul",
		"ghoul": "ghoul",
		"элитный скелет": "elite_skeleton",
		"elite skeleton": "elite_skeleton",
		"орк лучник": "orc_archer",
		"orc archer": "orc_archer",
		"орк убийца": "orc_assassin",
		"orc assassin": "orc_assassin",
		"орк берсерк": "orc_berserker",
		"orc berserker": "orc_berserker",
		"орк шаман": "orc_shaman",
		"orc shaman": "orc_shaman",
		"тёмный шатун": "dark_stalker",
		"dark stalker": "dark_stalker",
		"демон алкара": "alkara_demon",
		"alkara demon": "alkara_demon",
		"демон проклятия": "curse_demon",
		"curse demon": "curse_demon",
		"демон палач": "executioner_demon",
		"executioner demon": "executioner_demon",
		"демон тарнок": "tharnok_demon",
		"tharnok demon": "tharnok_demon",
		"скелет лорд": "skeleton_lord",
		"skeleton lord": "skeleton_lord"
	}
	
	# Определяем enemy_type по display_name или name
	var enemy_display_name_lower = enemy_node.display_name.to_lower()
	var enemy_name_lower = enemy_node.name.to_lower()
	
	var mapped_enemy_type = ""
	
	# Проверяем по display_name
	if enemy_type_map.has(enemy_display_name_lower):
		mapped_enemy_type = enemy_type_map[enemy_display_name_lower]
	else:
		# Проверяем по частичному совпадению
		for key in enemy_type_map:
			if key in enemy_display_name_lower or key in enemy_name_lower:
				mapped_enemy_type = enemy_type_map[key]
				break
	
	if mapped_enemy_type == "":
		return
	
	# Получаем редкость врага
	var enemy_rarity = enemy_node.rarity.to_lower()
	
	# Добавляем прогресс изучения
	active_ability_system.add_progress(mapped_enemy_type, enemy_rarity)

func use_player_ability(ability_id: String):
	"""Использует активную способность игрока"""
	
	if state != "player_turn":
		print("ОШИБКА: Не ход игрока, текущее состояние: ", state)
		return
	
	# Проверяем, не используется ли уже способность (защита от множественных нажатий)
	if player_node.using_ability:
		return
	
	# Проверяем, есть ли очки действий
	if not player_node.has_action_points():
		_show_message("Нет очков действий!")
		return
	
	# Проверяем, что player_abilities инициализирован
	if not player_abilities:
		print("ОШИБКА: player_abilities не инициализирован!")
		_show_message("Способности не инициализированы!")
		return
	
	# Получаем способность
	var ability = player_abilities.get_ability(ability_id)
	if not ability:
		print("ОШИБКА: Способность не найдена: ", ability_id)
		print("Доступные способности: ", player_abilities.get_all_abilities().size())
		_show_message("Способность не найдена!")
		return
	
	# Проверяем, может ли игрок использовать способность
	if not ability.can_use(player_node):
		_show_message("Недостаточно ресурсов для использования способности!")
		return
	
	# Тратим очко действий СРАЗУ, чтобы предотвратить множественное использование
	player_node.spend_action_point()
	
	# Устанавливаем флаг использования способности
	player_node.using_ability = true
	
	# Получаем текущую цель
	var target = get_current_target()
	if not target:
		_show_message("Нет доступных целей!", 1.0)
		player_node.using_ability = false
		return
	
	# Сохраняем количество маны до использования способности (для ancestral_wisdom)
	var mana_before = player_node.mp if "mp" in player_node else 0
	
	# Используем способность на выбранную цель
	var result = ability.use_ability(player_node, target)
	if result.get("success", false):
		var damage = result.get("damage", 0)
		var is_crit = result.get("is_crit", false)
		var damage_type = result.get("damage_type", "physical")
		
		# Вычисляем потраченную ману (для ancestral_wisdom)
		var mana_after = player_node.mp if "mp" in player_node else 0
		var mana_spent = mana_before - mana_after
		
		# Активируем пассивные способности при использовании способности (ON_ABILITY_USE)
		if mana_spent > 0 or ability.stamina_cost > 0:
			var context_ability_use = {
				"ability_id": ability_id,
				"ability_name": ability.name,
				"mana_spent": mana_spent,
				"stamina_spent": ability.stamina_cost if ability.stamina_cost > 0 else 0,
				"damage_type": damage_type
			}
			player_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ABILITY_USE, target, context_ability_use)
		
		# Проверяем проклятие - снижает наносимый урон (для всех атакующих способностей)
		if player_node.has_effect("curse") and damage_type != "heal":
			var curse_effect = player_node.effects.get("curse", {})
			if curse_effect is Dictionary:
				var damage_reduction = curse_effect.get("damage_reduction", 0.0)
				if damage_reduction > 0:
					damage = int(damage * (1.0 - damage_reduction))
				# Обновляем урон в результате для дальнейших обработок
				result["damage"] = damage
		
		# Специальная обработка для лечебных способностей
		if damage_type == "heal":
			_handle_healing_ability(result, ability)
			# Сбрасываем флаг использования способности
			player_node.using_ability = false
			# Переходим к ходу врага
			await get_tree().create_timer(0.5).timeout
			_set_enemy_turn()
			return
		
		# Проверяем попадание с учетом меткости и уворота ПЕРЕД применением пассивных способностей
		var ability_name = ability.name if ability else "Неизвестная способность"
		
		# Специальная обработка для "Спиритического удара"
		if ability_id == "spiritual_strike":
			# Запускаем анимацию каста игрока
			var visual_node_player = player_node.get_node_or_null("Visual")
			if visual_node_player:
				# Пробуем проиграть анимацию player_cast, если она есть
				if visual_node_player.has_method("play_animation") and visual_node_player.has_method("has_animation"):
					if visual_node_player.has_animation("player_cast"):
						visual_node_player.play_animation("player_cast")
					else:
						# Fallback на стандартную атаку, если анимация не найдена
						print("Анимация 'player_cast' не найдена, используем стандартную атаку")
						if visual_node_player.has_method("play_attack"):
							visual_node_player.play_attack()
				elif visual_node_player.has_method("play_attack"):
					visual_node_player.play_attack()
			
			# Ждём момента каста (середина анимации)
			await get_tree().create_timer(0.3).timeout
			
			# Создаём визуальный снаряд (используем target, а не enemy_node!)
			_spawn_spiritual_strike_projectile(player_node, target)
			
			# Ждём пока снаряд долетит
			await get_tree().create_timer(0.4).timeout
			
			# Проигрываем анимацию эффекта на цели (враге)
			# Используем SpriteFrames игрока для эффекта
			var player_visual = player_node.get_node_or_null("Visual")
			if player_visual:
				if player_visual.sprite_frames != null:
					if player_visual.sprite_frames.has_animation("spiritual_strike_anim"):
						# Вычисляем длительность анимации для синхронизации урона
						var anim_speed = player_visual.sprite_frames.get_animation_speed("spiritual_strike_anim")
						var anim_frames = player_visual.sprite_frames.get_frame_count("spiritual_strike_anim")
						var anim_duration = anim_frames / anim_speed if anim_speed > 0 else 0.5
						var hit_moment = anim_duration * 0.5
						
						# Получаем позицию цели для размещения эффекта
						var target_visual = target.get_node_or_null("Visual")
						var effect_position = target.global_position
						if target_visual:
							effect_position = target_visual.global_position
						
						# Создаем временный узел для эффекта на цели
						# Добавляем в GameWorld, чтобы эффект был поверх всех элементов
						var temp_effect = AnimatedSprite2D.new()
						temp_effect.name = "TempSpiritualStrikeEffect"
						temp_effect.sprite_frames = player_visual.sprite_frames  # Используем SpriteFrames игрока
						temp_effect.z_index = 100  # Поверх всех визуальных элементов
						temp_effect.scale = Vector2(3.0, 3.0)  # Увеличиваем эффект в 3 раза
						temp_effect.global_position = effect_position
						
						# Добавляем в GameWorld, чтобы эффект был виден поверх всего
						var game_world = get_node_or_null("GameWorld")
						if game_world:
							game_world.add_child(temp_effect)
						else:
							target.add_child(temp_effect)
						
						# Показываем узел эффектов и проигрываем анимацию
						temp_effect.visible = true
						if temp_effect.has_method("play_animation"):
							temp_effect.play_animation("spiritual_strike_anim")
						else:
							temp_effect.play("spiritual_strike_anim")
						
						# Ждем момента удара (середина анимации)
						await get_tree().create_timer(hit_moment).timeout
						
						# Сохраняем HP цели до нанесения урона для вычисления фактического урона
						var target_old_hp = target.hp
						
						# Наносим урон (используем target, а не enemy_node!)
						target.take_damage(damage, damage_type)
						
						# Вычисляем фактический урон после вычета брони
						var actual_damage = target_old_hp - target.hp
						
						# Показываем всплывающую цифру фактического урона
						DamageNumberManager.show_damage_on_character(target, actual_damage, is_crit, false, false, damage_type)
						
						# Тряска камеры при критическом ударе игрока
						if is_crit and camera and camera.has_method("shake"):
							camera.shake(0.3, 15.0)
						
						# Ждем завершения оставшейся части анимации и удаляем временный узел
						await temp_effect.animation_finished
						temp_effect.queue_free()
						
						# Показываем сообщение
						if is_crit:
							_show_message("КРИТИЧЕСКИЙ УДАР! УРОН: %d" % damage, 2.0)
						else:
							_show_message("Урон: %d" % damage, 1.5)
						
						# Активируем пассивные способности игрока при атаке (для Шамана бурь и других)
						var context_attack = {"damage": damage, "target": target, "ability_used": true, "is_critical": is_crit, "damage_type": damage_type}
						player_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, target, context_attack)
						
						# Активируем пассивные способности врага при получении урона
						var context_damage = {"damage": actual_damage, "target": target}
						target.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_DAMAGE_TAKEN, player_node, context_damage)
						# Проверяем отражение урона
						_handle_damage_reflection(target, player_node)
					else:
						# Fallback: наносим урон без анимации эффекта
						var target_old_hp = target.hp
						target.take_damage(damage, damage_type)
						var actual_damage = target_old_hp - target.hp
						DamageNumberManager.show_damage_on_character(target, actual_damage, is_crit, false, false, damage_type)
						if is_crit and camera and camera.has_method("shake"):
							camera.shake(0.3, 15.0)
						if is_crit:
							_show_message("КРИТИЧЕСКИЙ УДАР! УРОН: %d" % damage, 2.0)
						else:
							_show_message("Урон: %d" % damage, 1.5)
						var context_attack = {"damage": damage, "target": target, "ability_used": true, "is_critical": is_crit, "damage_type": damage_type}
						player_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, target, context_attack)
						var context_damage = {"damage": actual_damage, "target": target}
						target.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_DAMAGE_TAKEN, player_node, context_damage)
						# Проверяем отражение урона
						_handle_damage_reflection(target, player_node)
				else:
					# Fallback: наносим урон без анимации эффекта
					var target_old_hp = target.hp
					target.take_damage(damage, damage_type)
					var actual_damage = target_old_hp - target.hp
					DamageNumberManager.show_damage_on_character(target, actual_damage, is_crit, false, false, damage_type)
					if is_crit and camera and camera.has_method("shake"):
						camera.shake(0.3, 15.0)
					if is_crit:
						_show_message("КРИТИЧЕСКИЙ УДАР! УРОН: %d" % damage, 2.0)
					else:
						_show_message("Урон: %d" % damage, 1.5)
					var context_attack = {"damage": damage, "target": target, "ability_used": true, "is_critical": is_crit, "damage_type": damage_type}
					player_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, target, context_attack)
					var context_damage = {"damage": actual_damage, "target": target}
					target.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_DAMAGE_TAKEN, player_node, context_damage)
					# Проверяем отражение урона
					_handle_damage_reflection(target, player_node)
					# Проверяем отражение урона
					_handle_damage_reflection(target, player_node)
			else:
				# Fallback: наносим урон без анимации эффекта
				var target_old_hp = target.hp
				target.take_damage(damage, damage_type)
				var actual_damage = target_old_hp - target.hp
				DamageNumberManager.show_damage_on_character(target, actual_damage, is_crit, false, false, damage_type)
				if is_crit and camera and camera.has_method("shake"):
					camera.shake(0.3, 15.0)
				if is_crit:
					_show_message("КРИТИЧЕСКИЙ УДАР! УРОН: %d" % damage, 2.0)
				else:
					_show_message("Урон: %d" % damage, 1.5)
				var context_attack = {"damage": damage, "target": target, "ability_used": true, "is_critical": is_crit, "damage_type": damage_type}
				player_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, target, context_attack)
				var context_damage = {"damage": actual_damage, "target": target}
				target.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_DAMAGE_TAKEN, player_node, context_damage)
				# Проверяем отражение урона
				_handle_damage_reflection(target, player_node)
			
			# Проверяем дополнительные атаки от пассивных способностей игрока
			_check_extra_attacks(player_node, target, damage_type)
		
		# Специальная обработка для "Магических стрел" игрока
		elif ability_id == "magic_arrows":
			var arrows_count = result.get("arrows_count", 1)
			var arrow_damage = result.get("arrow_damage", 0)
			
			# Проверяем проклятие для урона каждой стрелы
			if player_node.has_effect("curse"):
				var curse_effect = player_node.effects.get("curse", {})
				if curse_effect is Dictionary:
					var damage_reduction = curse_effect.get("damage_reduction", 0.0)
					if damage_reduction > 0:
						arrow_damage = int(arrow_damage * (1.0 - damage_reduction))
			
			var total_arrow_damage = 0
			
			# Запускаем анимацию атаки игрока
			var visual_node_player = player_node.get_node_or_null("Visual")
			if visual_node_player and visual_node_player.has_method("play_attack"):
				visual_node_player.play_attack()
			
			# Ждём момента взмаха (середина анимации атаки)
			await get_tree().create_timer(0.4).timeout
			
			# Создаём визуальные снаряды для каждой стрелы (используем target, а не enemy_node!)
			_spawn_magic_arrow_projectiles(player_node, target, arrows_count)
			
			# Каждая стрела наносит урон отдельно с задержкой
			for i in range(arrows_count):
				# Задержка между стрелами
				if i > 0:
					await get_tree().create_timer(0.60).timeout
				
				# Проверяем уворот для каждой стрелы
				if _calculate_hit_chance(player_node, target, "magic_arrow_" + str(i+1), "Магическая стрела " + str(i+1)):
					var target_old_hp = target.hp
					target.take_damage(arrow_damage, damage_type)
					var actual_arrow_damage = target_old_hp - target.hp
					total_arrow_damage += actual_arrow_damage
					
					# Показываем всплывающую цифру фактического урона
					DamageNumberManager.show_damage_on_character(target, actual_arrow_damage, false, false, false, damage_type)
					
					# Активируем пассивные способности игрока после каждой стрелы
					var context_arrow = {"damage": arrow_damage, "target": target, "ability_used": true, "is_critical": false, "hit_number": i+1, "damage_type": damage_type}
					player_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, target, context_arrow)
				else:
					# Показываем всплывающую цифру промаха
					DamageNumberManager.show_damage_on_character(target, 0, false, true, false, damage_type)
			
			# Обновляем damage для правильного отображения в сообщении
			damage = total_arrow_damage
			
			# Сохраняем информацию об атаке для логирования
			player_node.set_last_attack_info(damage, damage_type, is_crit, ability.name)
			
			# Тряска камеры при критическом ударе игрока
			if is_crit and camera and camera.has_method("shake"):
				camera.shake(0.3, 15.0)
			
			# Показываем сообщение
			if is_crit:
				_show_message("КРИТИЧЕСКИЙ УДАР! Выпущено %d магических стрел! УРОН: %d" % [arrows_count, damage], 2.0)
			else:
				_show_message("Выпущено %d магических стрел! Урон: %d" % [arrows_count, damage], 2.0)
		elif ability_id == "kinetic_strike":
			# Специальная обработка для "Кинетического удара"
			var kinetic_actual_damage = 0  # Объявляем переменную для отслеживания фактического урона
			
			# Проверяем попадание
			if not _calculate_hit_chance(player_node, target, "main_attack", ability_name):
				DamageNumberManager.show_damage_on_character(target, 0, false, true, false, damage_type)
				_show_message("Промах!", 1.0)
				player_node.using_ability = false
				await get_tree().create_timer(0.5).timeout
				_set_enemy_turn()
				return
			
			# Анимация атаки игрока
			var visual_node_player = player_node.get_node_or_null("Visual")
			if visual_node_player and visual_node_player.has_method("play_attack"):
				visual_node_player.play_attack()
			
			# Воспроизводим звук
			if SoundManager:
				SoundManager.play_sound("sword_hit", -5.0)
			
			# Ждем момента удара в анимации атаки
			await get_tree().create_timer(0.35).timeout
			
			# Проигрываем анимацию эффекта на цели (враге)
			# Используем SpriteFrames игрока для эффекта, так как эффект одинаковый для всех врагов
			var player_visual = player_node.get_node_or_null("Visual")
			print("⚡ Проверяем анимацию kinetic_strike_anim")
			if player_visual:
				if player_visual.sprite_frames != null:
					if player_visual.sprite_frames.has_animation("kinetic_strike_anim"):
						print("⚡ Проигрываем анимацию эффекта 'kinetic_strike_anim' на цели")
						
						# Вычисляем длительность анимации для синхронизации урона
						var anim_speed = player_visual.sprite_frames.get_animation_speed("kinetic_strike_anim")
						var anim_frames = player_visual.sprite_frames.get_frame_count("kinetic_strike_anim")
						var anim_duration = anim_frames / anim_speed if anim_speed > 0 else 0.5
						var hit_moment = anim_duration * 0.5  # Середина анимации
						
						# Получаем позицию цели для размещения эффекта
						var target_visual = target.get_node_or_null("Visual")
						var effect_position = target.global_position
						if target_visual:
							effect_position = target_visual.global_position
						
						# Создаем временный узел для эффекта на цели
						var temp_effect = AnimatedSprite2D.new()
						temp_effect.name = "TempKineticStrikeEffect"
						temp_effect.sprite_frames = player_visual.sprite_frames  # Используем SpriteFrames игрока
						temp_effect.z_index = 100  # Поверх всех визуальных элементов
						temp_effect.scale = Vector2(3.0, 3.0)  # Увеличиваем эффект в 3 раза
						temp_effect.global_position = effect_position
						
						# Добавляем в GameWorld, а не к врагу, чтобы эффект был виден поверх всего
						var game_world = get_node_or_null("GameWorld")
						if game_world:
							game_world.add_child(temp_effect)
							print("⚡ Эффект добавлен в GameWorld")
						else:
							target.add_child(temp_effect)
							print("⚡ Эффект добавлен к врагу (GameWorld не найден)")
						
						# Показываем узел эффектов
						temp_effect.visible = true
						
						# Проигрываем анимацию эффекта
						if temp_effect.has_method("play"):
							temp_effect.play("kinetic_strike_anim")
							print("⚡ Анимация запущена через play()")
						
						# Ждем момента удара (середина анимации)
						await get_tree().create_timer(hit_moment).timeout
						
						# Наносим урон в момент удара
						var target_old_hp = target.hp
						target.take_damage(damage, damage_type)
						kinetic_actual_damage = target_old_hp - target.hp
						
						# Показываем урон
						DamageNumberManager.show_damage_on_character(target, kinetic_actual_damage, is_crit, false, false, damage_type)
						
						# Тряска камеры
						if is_crit and camera and camera.has_method("shake"):
							camera.shake(0.4, 18.0)
						
						# Ждем завершения анимации
						await get_tree().create_timer(anim_duration - hit_moment).timeout
						
						# Удаляем временный эффект
						temp_effect.queue_free()
						print("⚡ Временный эффект удален")
					else:
						print("⚠️ Анимация 'kinetic_strike_anim' не найдена в SpriteFrames игрока")
						# Fallback: сразу наносим урон без анимации
						var target_old_hp = target.hp
						target.take_damage(damage, damage_type)
						kinetic_actual_damage = target_old_hp - target.hp
						DamageNumberManager.show_damage_on_character(target, kinetic_actual_damage, is_crit, false, false, damage_type)
						if is_crit and camera and camera.has_method("shake"):
							camera.shake(0.4, 18.0)
				else:
					print("⚠️ sprite_frames игрока = null")
			else:
				print("⚠️ Visual игрока не найден")
			
			# Активируем пассивные способности игрока
			var kinetic_context = {"damage": damage, "target": target, "ability_used": true, "damage_type": damage_type}
			player_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, target, kinetic_context)
			
			# Сохраняем информацию об атаке
			player_node.set_last_attack_info(damage, damage_type, is_crit, ability.name)
			
			# Показываем сообщение
			if is_crit:
				_show_message("⚡ КИНЕТИЧЕСКИЙ КРИТИЧЕСКИЙ УДАР! УРОН: %d" % damage, 2.0)
			else:
				_show_message("⚡ Кинетический удар! Урон: %d" % damage, 1.5)
			
			# Активируем пассивные способности врага (урон уже нанесен выше)
			var kinetic_context_damage = {"damage": kinetic_actual_damage, "target": target}
			target.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_DAMAGE_TAKEN, player_node, kinetic_context_damage)
			_handle_damage_reflection(target, player_node)
		else:
			# Обычная способность - проверяем попадание (используем target, а не enemy_node!)
			if not _calculate_hit_chance(player_node, target, "main_attack", ability_name):
				# Показываем всплывающую цифру промаха
				DamageNumberManager.show_damage_on_character(target, 0, false, true, false, damage_type)
				
				_show_message("Промах!", 1.0)
				# Сбрасываем флаг использования способности
				player_node.using_ability = false
				# Переходим к ходу врага
				await get_tree().create_timer(0.5).timeout
				_set_enemy_turn()
				return
			
			# Активируем пассивные способности игрока при использовании способности (только при попадании)
			var context = {"damage": damage, "target": target, "ability_used": true, "damage_type": damage_type}
			player_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, target, context)
			
			# Сохраняем информацию об атаке для логирования
			player_node.set_last_attack_info(damage, damage_type, is_crit, ability.name)
			
			# Сохраняем HP цели до нанесения урона для вычисления фактического урона
			var target_old_hp = target.hp
			
			# Наносим урон
			target.take_damage(damage, damage_type)
			
			# Вычисляем фактический урон после вычета брони
			var actual_damage = target_old_hp - target.hp
			
			# Показываем всплывающую цифру фактического урона
			DamageNumberManager.show_damage_on_character(target, actual_damage, is_crit, false, false, damage_type)
			
			# Тряска камеры при критическом ударе игрока
			if is_crit and camera and camera.has_method("shake"):
				camera.shake(0.3, 15.0)
			
			# Показываем сообщение
			if is_crit:
				_show_message("КРИТИЧЕСКИЙ УДАР! УРОН: %d" % damage, 2.0)
			else:
				_show_message("Урон: %d" % damage, 1.5)
			
			# Активируем пассивные способности врага при получении урона (только после нанесения урона)
			# Используем фактический урон для правильного расчета отражения
			var context_damage = {"damage": actual_damage, "target": target}
			target.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_DAMAGE_TAKEN, player_node, context_damage)
			# Проверяем отражение урона
			_handle_damage_reflection(target, player_node)
			
			# Проверяем дополнительные атаки от пассивных способностей игрока
			_check_extra_attacks(player_node, target, damage_type)
		
		# Очко действий уже потрачено в начале функции
		
		# Проверяем, есть ли еще очки действий
		if player_node.has_action_points():
			_show_message("У вас есть еще одно действие!")
			# Короткая задержка перед следующим действием
			await get_tree().create_timer(0.3).timeout
			# Остаемся в ходу игрока
			player_node.using_ability = false
			return
		else:
			# Переходим к ходу врага
			await get_tree().create_timer(0.3).timeout
			_set_enemy_turn()
	else:
		_show_message("Способность не сработала!")
	
	# Сбрасываем флаг использования способности
	player_node.using_ability = false

func _on_next_pressed():
	# Скрываем кнопку
	var btn = $UI.get_node_or_null("Btn_Next")
	if btn:
		btn.visible = false
	
	# Проверяем, находимся ли мы в тестовом режиме
	if test_mode:
		print("Тестовый режим: возвращаемся к выбору врага")
		# В тестовом режиме возвращаемся к выбору врага
		SceneTransition.change_scene("res://Scenes/TestArena.tscn")
		return
	
	# Осколки душ за забег переносятся в хранилище только при завершении всего уровня
	# (при возврате к экрану подготовки персонажа)
	
	# Сохраняем данные игрока
	_save_player_data()
	
	# Автоматически сохраняем игру
	var player_manager_node = get_node_or_null("/root/PlayerManager")
	if player_manager_node:
		player_manager_node.save_game_data()
	
	# Переходим к выбору комнат
	SceneTransition.change_scene("res://Scenes/RoomSelector.tscn")

func _initialize_passive_abilities():
	# Инициализируем пассивные способности для игрока и врагов
	var passive_manager = get_node_or_null("/root/PassiveAbilityManager")
	if not passive_manager:
		# Создаем менеджер пассивных способностей
		var script = load("res://Scripts/PassiveAbilities/PassiveAbilityManager.gd")
		passive_manager = Node.new()
		passive_manager.set_script(script)
		passive_manager.name = "PassiveAbilityManager"
		get_tree().root.add_child(passive_manager)
		await get_tree().process_frame
	
	# Добавляем пассивные способности игроку
	_add_player_passives(passive_manager)

func _add_player_passives(_manager):
	# Пассивные способности игрока управляются через PlayerData
	# и применяются в _apply_player_passive_abilities()
	# Здесь ничего не добавляем - все контролируется игроком через менеджер
	pass

func _add_enemy_passives(enemy, manager):
	# Добавляем пассивные способности врагу в зависимости от его имени и редкости
	manager.add_passives_to_character(enemy, enemy.display_name, enemy.rarity)
	
	# После добавления пассивных способностей обновляем HP до максимума
	# Это нужно, потому что пассивные способности могут увеличить max_hp
	enemy.hp = enemy.max_hp
	enemy.mp = enemy.max_mp
	enemy.stamina = enemy.max_stamina

func get_battle_log() -> BattleLog:
	return battle_log

func get_enemy_ability(enemy_name: String) -> EnemyAbility:
	"""Возвращает способность для указанного врага"""
	if enemy_abilities:
		return enemy_abilities.get_ability_for_enemy(enemy_name)
	return null

func get_enemy_ability_info(enemy_name: String) -> Dictionary:
	"""Возвращает информацию о способности врага для UI"""
	var ability = get_enemy_ability(enemy_name)
	if not ability:
		return {}
	
	var info = {
		"name": ability.name,
		"description": ability.description,
		"damage": ability.base_damage,
		"cooldown": ability.cooldown,
		"cost": ability.mp_cost if ability.mp_cost > 0 else ability.stamina_cost,
		"cost_type": "МП" if ability.mp_cost > 0 else "Выносливости"
	}
	
	return info

func _calculate_and_award_soul_shards():
	"""Рассчитывает и награждает осколками душ за победу над врагом"""
	if not soul_shard_manager:
		print("ПРЕДУПРЕЖДЕНИЕ: SoulShards недоступен, осколки душ не начислены.")
		return
	
	if not enemy_node:
		print("ОШИБКА: enemy_node не найден!")
		return
	
	# Получаем данные врага
	var enemy_level = enemy_node.level
	var enemy_rarity = enemy_node.rarity
	
	# Рассчитываем осколки душ
	var soul_shards_earned = soul_shard_manager.calculate_soul_shards_for_enemy(enemy_level, enemy_rarity)
	
	# Добавляем осколки душ
	soul_shard_manager.add_soul_shards(soul_shards_earned)
	
	# Награждаем новыми валютами в зависимости от редкости врага
	_award_special_currencies(enemy_rarity)
	
	# Показываем сообщение о получении осколков душ
	var rarity_name = get_rarity_display_name(enemy_rarity)
	_show_message("Получено осколков душ: %d (Уровень %d, %s)" % [soul_shards_earned, enemy_level, rarity_name], 3.0)

func _award_special_currencies(enemy_rarity: String):
	"""Награждает специальными валютами в зависимости от редкости врага"""
	# Проверяем элитных врагов
	if enemy_rarity.to_lower().begins_with("elite_"):
		# Элитные враги дают сильные души
		var strong_souls_manager = get_node_or_null("/root/StrongSouls")
		if strong_souls_manager:
			strong_souls_manager.add_strong_souls(1)
			_show_message("Получена Сильная душа!", 2.0)
			print("Награда: 1 Сильная душа за победу над элитным врагом")
		return
	
	match enemy_rarity.to_lower():
		"boss":
			# Боссы дают великие души
			var great_souls_manager = get_node_or_null("/root/GreatSouls")
			if great_souls_manager:
				great_souls_manager.add_great_souls(1)
				_show_message("Получена Великая душа!", 2.0)
				print("Награда: 1 Великая душа за победу над боссом")
		"mythic":
			# Мифические враги дают божественные души
			var divine_souls_manager = get_node_or_null("/root/DivineSouls")
			if divine_souls_manager:
				divine_souls_manager.add_divine_souls(1)
				_show_message("Получена Божественная душа!", 2.0)
				print("Награда: 1 Божественная душа за победу над мифическим врагом")

func _get_ability_id_from_result(result: Dictionary) -> String:
	"""Определяет ID способности из результата использования способности врага"""
	# Проверяем флаги способностей в порядке приоритета
	if result.get("rat_bite", false):
		return "rat_bite"
	elif result.get("poison_strike", false):
		return "poison_strike"
	elif result.get("crossbow_shot", false):
		return "crossbow_shot"
	elif result.get("slashing_strike", false):
		return "slashing_strike"
	elif result.get("tombstone", false):
		return "tombstone"
	elif result.get("rending_claws", false):
		return "rending_claws"
	elif result.get("bat_swoop", false):
		return "bat_swoop"
	elif result.get("rotten_blast", false):
		return "rotten_blast"
	elif result.get("acid_blast", false):
		return "acid_blast"
	elif result.get("dark_blast", false):
		return "dark_blast"
	elif result.get("curse_blast", false):
		return "curse_blast"
	# Если способность не найдена, возвращаем пустую строку
	return ""

func get_rarity_display_name(rarity: String) -> String:
	"""Возвращает отображаемое имя редкости"""
	# Проверяем элитных врагов
	if rarity.to_lower().begins_with("elite_"):
		var base_rarity = rarity.to_lower().substr(6)
		match base_rarity:
			"rare":
				return "Элитная Редкая"
			"epic":
				return "Элитная Эпическая"
			"legendary":
				return "Элитная Легендарная"
			_:
				return "Элитная"
	
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
		"mythical":
			return "Мифическая"
		_:
			return "Неизвестная"

func _check_backstab_chance(attacker: Node) -> bool:
	"""Проверяет шанс удара в спину на основе пассивных способностей атакующего"""
	# Базовый шанс удара в спину (можно настроить)
	var base_backstab_chance = 0.0
	
	# Проверяем пассивные способности атакующего
	for ability in attacker.passive_abilities:
		if ability.id == "ninja_assassinate" or ability.id == "ninja_shadow_strike":
			# Ниндзя способности дают шанс удара в спину
			base_backstab_chance += ability.value / 100.0
	
	# Дополнительные способности для ударов в спину
	if attacker.has_method("get_backstab_chance"):
		base_backstab_chance += attacker.get_backstab_chance()
	
	# Проверяем шанс
	return randf() < base_backstab_chance

func _spawn_magic_arrow_projectiles(from_character: Node2D, to_character: Node2D, arrows_count: int):
	"""Создаёт визуальные снаряды магических стрел"""
	if not MagicArrowProjectileScene:
		print("ПРЕДУПРЕЖДЕНИЕ: Сцена MagicArrowProjectile не загружена!")
		return
	
	# Получаем позиции персонажей
	var from_pos = from_character.global_position
	var to_pos = to_character.global_position
	
	# Если у персонажа есть визуальный компонент, используем его позицию
	if from_character.has_node("Visual"):
		from_pos = from_character.get_node("Visual").global_position
	if to_character.has_node("Visual"):
		to_pos = to_character.get_node("Visual").global_position
	
	# Смещение для точки вылета (из посоха над головой)
	# Для врагов (справа) смещаем влево-вверх
	# Для игрока (слева) смещаем вправо-вверх
	var is_enemy = from_character.global_position.x > to_character.global_position.x
	if is_enemy:
		# Враг стреляет слева от себя, вверху (из посоха)
		from_pos += Vector2(-30, -80)  # -30 влево, -80 вверх
	else:
		# Игрок стреляет справа от себя, вверху
		from_pos += Vector2(30, -80)  # +30 вправо, -80 вверх
	
	# Создаём снаряды последовательно с задержкой
	for i in range(arrows_count):
		var arrow = MagicArrowProjectileScene.instantiate()
		
		# Добавляем снаряд в игровой мир (не в персонажа, чтобы избежать проблем с позиционированием)
		$GameWorld.add_child(arrow)
		
		# Настраиваем параметры полёта (без задержки в самом снаряде)
		arrow.setup(from_pos, to_pos, 0)
		
		# Ждём перед созданием следующей стрелы (синхронизируем с нанесением урона)
		if i < arrows_count - 1:
			await get_tree().create_timer(0.6).timeout

func _spawn_spiritual_strike_projectile(from_character: Node2D, to_character: Node2D):
	"""Создаёт визуальный снаряд Спиритического удара"""
	if not SpiritualStrikeProjectileScene:
		print("ПРЕДУПРЕЖДЕНИЕ: Сцена SpiritualStrikeProjectile не загружена!")
		return
	
	# Получаем позиции персонажей
	var from_pos = from_character.global_position
	var to_pos = to_character.global_position
	
	# Если у персонажа есть визуальный компонент, используем его позицию
	if from_character.has_node("Visual"):
		from_pos = from_character.get_node("Visual").global_position
	if to_character.has_node("Visual"):
		to_pos = to_character.get_node("Visual").global_position
	
	# Смещение для точки вылета (из центра тела, чуть выше)
	# Спиритический удар - духовная энергия от игрока
	from_pos += Vector2(0, -50)  # Центр, чуть выше
	
	# Создаём снаряд
	var projectile = SpiritualStrikeProjectileScene.instantiate()
	$GameWorld.add_child(projectile)
	projectile.setup(from_pos, to_pos, 0)

func _calculate_hit_chance(attacker: Node, target: Node, context: String = "", attack_name: String = "") -> bool:
	"""Рассчитывает шанс попадания с учетом меткости атакующего и уворота цели"""
	# Получаем меткость атакующего
	var attacker_accuracy = 100  # Базовая меткость
	if attacker.has_method("get_accuracy"):
		attacker_accuracy = attacker.get_accuracy()
	
	# Получаем шанс уворота цели
	var target_dodge = 0  # Базовый уворот
	if target.has_method("get_dodge_chance"):
		target_dodge = target.get_dodge_chance()
	
	# Рассчитываем итоговый шанс попадания
	var hit_chance = attacker_accuracy - target_dodge
	
	# Минимальный шанс попадания 5% (если меткость очень низкая)
	hit_chance = max(5, hit_chance)
	
	# Максимальный шанс попадания 100% (если меткость превышает уворот)
	hit_chance = min(100, hit_chance)
	
	# Проверяем попадание
	var hit_success = randf() * 100 < hit_chance
	
	# Логируем результат проверки уворота только если у цели есть уворот И он сработал
	if target_dodge > 0 and not hit_success:
		# Логируем уворот для основных атак, для каждого удара "Двойного удара" и для каждой "Магической стрелы"
		if context == "" or context == "main_attack" or context == "double_strike_1" or context == "double_strike_2" or context.begins_with("magic_arrow_"):
			# Успешный уворот
			var dodge_message = target.display_name + " увернулся"
			if attack_name != "":
				dodge_message += " от " + attack_name
			dodge_message += "!"
			battle_log.log_passive_ability(target.display_name, "Уворот", true, dodge_message)
	
	return hit_success

func _apply_player_passive_abilities():
	"""Применяет активные пассивные способности игрока"""
	if not player_manager:
		return
	
	var player_data = player_manager.get_player_data()
	if not player_data:
		return
	
	# Инициализируем систему пассивных способностей если нужно
	player_data.initialize_passive_system()
	
	# Получаем активные пассивные способности
	var active_passives = player_data.get_active_passives()
	
	# Применяем каждую активную способность
	for ability_id in active_passives:
		var ability = player_data.get_passive_ability_info(ability_id)
		if ability:
			# Получаем уровень способности
			var ability_level = AbilityLearningSystem.get_ability_level(ability_id)
			# Добавляем способность к игроку с уровнем
			player_node.add_passive_ability(ability, ability_level)

func _initialize_battle_music():
	"""Инициализирует боевую музыку в зависимости от текущей локации"""
	var music_player = get_node_or_null("/root/MusicPlayer")
	if not music_player:
		print("MusicPlayer не найден в автозагрузках")
		return
	
	# Получаем текущую локацию
	var location_manager = get_node_or_null("/root/LocationManager")
	var current_location_id = "dungeon"  # По умолчанию
	
	if location_manager:
		current_location_id = location_manager.get_current_location_id()
	
	# Выбираем музыку в зависимости от локации
	var battle_music: AudioStream
	
	match current_location_id:
		"dungeon":
			# Подземелье под городом - Action 4 Loop
			battle_music = preload("res://Audio/Music/Background/Action 4 Loop.ogg")
		"forest", "mountain", "volcano", "void":
			# Остальные локации - Action 5 Loop
			battle_music = preload("res://Audio/Music/Background/Action 5 Loop.ogg")
		_:
			# Неизвестная локация - Action 5 Loop
			battle_music = preload("res://Audio/Music/Background/Action 5 Loop.ogg")
	
	if battle_music:
		music_player.play_music(battle_music, true, true)  # fade_in=true, crossfade=true
	else:
		print("Музыкальный файл не найден")

func _initialize_ability_slots_ui():
	"""Инициализирует UI для слотов активных способностей"""
	if not AbilitySlotManager:
		return
	
	# Создаем контейнер для слотов способностей
	var slots_container = HBoxContainer.new()
	slots_container.name = "AbilitySlotsContainer"
	slots_container.add_theme_constant_override("separation", 15)
	
	# Позиционируем внизу по центру экрана
	slots_container.anchor_left = 0.5
	slots_container.anchor_right = 0.5
	slots_container.anchor_top = 1.0
	slots_container.anchor_bottom = 1.0
	slots_container.offset_left = -350  # Центрируем (4 кнопки * ~175px)
	slots_container.offset_right = 350
	slots_container.offset_top = -120  # Отступ снизу
	slots_container.offset_bottom = -20
	slots_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	slots_container.grow_vertical = Control.GROW_DIRECTION_BEGIN
	
	ui.add_child(slots_container)
	
	# Создаем 4 слота
	for slot_index in range(4):
		var slot_button = _create_ability_slot_button(slot_index)
		slots_container.add_child(slot_button)
	
	# Обновляем кнопки при изменении слотов
	if AbilitySlotManager.slots_updated.is_connected(_update_ability_slots_ui):
		AbilitySlotManager.slots_updated.disconnect(_update_ability_slots_ui)
	AbilitySlotManager.slots_updated.connect(_update_ability_slots_ui)
	
	# Первоначальное обновление
	_update_ability_slots_ui()

func _create_ability_slot_button(slot_index: int) -> Button:
	"""Создаёт кнопку слота способности"""
	var button = Button.new()
	button.name = "AbilitySlot_%d" % slot_index
	button.custom_minimum_size = Vector2(160, 90)
	
	# Стиль кнопки
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.3, 0.9)
	style.border_color = Color(0.5, 0.5, 0.6)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	button.add_theme_stylebox_override("normal", style)
	
	# Настройка текста
	button.add_theme_font_size_override("font_size", 18)
	button.text = "[%d]\nПусто" % (slot_index + 1)
	
	# Подключаем сигнал
	button.pressed.connect(_on_ability_slot_pressed.bind(slot_index))
	
	return button

func _update_ability_slots_ui():
	"""Обновляет отображение слотов способностей"""
	if not AbilitySlotManager:
		return
	
	var slots_container = ui.get_node_or_null("AbilitySlotsContainer")
	if not slots_container:
		return
	
	# Обновляем каждую кнопку
	for slot_index in range(4):
		var button = slots_container.get_node_or_null("AbilitySlot_%d" % slot_index)
		if not button:
			continue
		
		var slot_info = AbilitySlotManager.get_slot_info(slot_index)
		
		if slot_info["is_empty"]:
			# Пустой слот
			button.text = "[%d]\nПусто" % (slot_index + 1)
			button.disabled = true
			button.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		else:
			# Занятый слот
			var ability_name = slot_info["ability_name"]
			var cooldown = slot_info["cooldown"]
			
			if cooldown > 0:
				# На кулдауне
				button.text = "[%d] %s\n⏱️ %d" % [slot_index + 1, ability_name, cooldown]
				button.disabled = true
				button.add_theme_color_override("font_color", Color(0.7, 0.5, 0.5))
			else:
				# Доступна к использованию
				button.text = "[%d]\n%s" % [slot_index + 1, ability_name]
				button.disabled = false
				button.add_theme_color_override("font_color", Color(1, 1, 1))

func _on_ability_slot_pressed(slot_index: int):
	"""Обработчик нажатия на слот способности"""
	if not AbilitySlotManager:
		return
	
	var slot_info = AbilitySlotManager.get_slot_info(slot_index)
	
	if slot_info["is_empty"]:
		_show_message("Слот пуст! Установите способность в Книге способностей", 2.0)
		return
	
	if slot_info["is_on_cooldown"]:
		_show_message("Способность на перезарядке! Осталось: %d раунд(ов)" % slot_info["cooldown"], 2.0)
		return
	
	# Используем способность
	_use_learned_ability(slot_info["ability_id"], slot_index)

func _use_learned_ability(ability_id: String, slot_index: int):
	"""Использует изученную активную способность врага"""
	
	if state != "player_turn":
		_show_message("Не ваш ход!", 1.5)
		return
	
	# Проверяем очки действий
	if not player_node.has_action_points():
		_show_message("Нет очков действий!", 1.5)
		return
	
	# Получаем цель
	var target = get_current_target()
	if not target or not is_instance_valid(target):
		_show_message("Нет доступных целей!", 1.5)
		return
	
	# Получаем данные способности из enemy_abilities
	if not enemy_abilities:
		push_error("enemy_abilities не инициализирован!")
		return
	
	var ability = enemy_abilities.get_ability_by_id(ability_id)
	if not ability:
		push_error("Способность '%s' не найдена в EnemyAbilities!" % ability_id)
		return
	
	# Проверяем ресурсы
	if ability.mp_cost > 0 and player_node.mp < ability.mp_cost:
		_show_message("Недостаточно маны! Требуется: %d" % ability.mp_cost, 2.0)
		return
	
	if ability.stamina_cost > 0 and player_node.stamina < ability.stamina_cost:
		_show_message("Недостаточно выносливости! Требуется: %d" % ability.stamina_cost, 2.0)
		return
	
	# Тратим ресурсы
	if ability.mp_cost > 0:
		player_node.mp -= ability.mp_cost
	if ability.stamina_cost > 0:
		player_node.stamina -= ability.stamina_cost
	
	# Тратим очко действий
	player_node.spend_action_point()
	
	# Вычисляем урон на основе формулы способности врага
	var damage = _calculate_learned_ability_damage(ability, player_node)
	
	# Проверяем крит
	var is_crit = player_node.is_critical_hit()
	if is_crit:
		damage = int(damage * 1.5)  # Критический урон x1.5
	
	# Применяем урон к цели
	if damage > 0:
		var damage_result = target.take_damage(damage, ability.damage_type)
		
		# take_damage может вернуть словарь или число
		var actual_damage = damage_result
		if damage_result is Dictionary:
			actual_damage = damage_result.get("damage", damage)
		
		# Показываем сообщение
		var crit_text = " (КРИТ!)" if is_crit else ""
		_show_message("Вы использовали " + ability.name + "! Урон: " + str(int(actual_damage)) + crit_text, 2.0)
		
		# Проигрываем анимацию способности
		if ability_effect_manager:
			ability_effect_manager.play_ability_effect_on_target(
				target,
				ability_id
			)
	
	# Устанавливаем кулдаун
	if ability.cooldown > 0:
		AbilitySlotManager.set_cooldown(ability_id, ability.cooldown - 1)  # -1 т.к. текущий раунд уже считается
	
	# Обновляем UI слотов
	_update_ability_slots_ui()
	
	# Проверяем смерть врага и победу
	if target.hp <= 0:
		# Враг умер, проверяем всех врагов
		var all_dead = true
		for enemy in enemy_nodes:
			if is_instance_valid(enemy) and enemy.hp > 0:
				all_dead = false
				break
		
		if all_dead:
			_handle_victory()
			return
	
	# Переходим к ходу врага
	await get_tree().create_timer(0.5).timeout
	_set_enemy_turn()

func _calculate_learned_ability_damage(ability: EnemyAbility, caster: Node2D) -> int:
	"""Вычисляет урон изученной способности на основе характеристик игрока"""
	
	var base_damage = 0
	var P = caster.get("P") if caster.has_method("get") else 0
	
	# Формулы урона для каждой способности (из EnemyAbilities.gd)
	match ability.id:
		"rat_bite":
			# Урон = сила + ловкость * 1.5
			base_damage = caster.strength + int(caster.agility * 1.5)
		
		"slime_acid_blast", "rotten_slime_blast":
			# Урон = сила + живучесть
			base_damage = caster.strength + caster.vitality
			if ability.id == "rotten_slime_blast":
				base_damage = int((caster.strength + caster.vitality) / 2.0) + P
		
		"bat_swoop":
			# Урон = сила + ловкость * 1.5
			base_damage = caster.strength + int(caster.agility * 1.5)
		
		"double_strike":
			# Два удара = (сила + ловкость) / 1.5 * 2
			base_damage = int((caster.strength + caster.agility) / 1.5) * 2
		
		"poison_strike":
			# Урон = ловкость * 2.5
			base_damage = int(caster.agility * 2.5)
		
		"magic_arrows":
			# Количество стрел = 1 + интеллект / 15, урон каждой = интеллект
			var arrow_count = 1 + int(caster.intelligence / 15)
			base_damage = caster.intelligence * arrow_count
		
		"crossbow_shot":
			# Урон = сила + ловкость * 1.8
			base_damage = caster.strength + int(caster.agility * 1.8)
		
		"slashing_strike":
			# Урон = сила + ловкость * 1.2
			base_damage = caster.strength + int(caster.agility * 1.2)
		
		"tombstone":
			# Урон = интеллект * 1.5 + мудрость
			base_damage = int(caster.intelligence * 1.5) + caster.wisdom
		
		"crushing_hammer":
			# Два удара молотом
			var hit1 = int(caster.strength * 1.5) + caster.vitality
			var hit2 = int(caster.strength * 2.0) + int(caster.vitality * 1.3)
			base_damage = hit1 + hit2
		
		"orc_arrow_shot":
			# Урон = сила + ловкость * 1.6
			base_damage = caster.strength + int(caster.agility * 1.6)
		
		"orc_backstab":
			# Урон = (сила + ловкость) * 2.0
			base_damage = int((caster.strength + caster.agility) * 2.0)
		
		"orc_berserker_strike":
			# Урон = (сила * 2.0 + живучесть)
			base_damage = int(caster.strength * 2.0) + caster.vitality
		
		"orc_spirit_blast":
			# Урон = интеллект * 2.0 + мудрость * 1.5
			base_damage = int(caster.intelligence * 2.0) + int(caster.wisdom * 1.5)
		
		"shadow_spikes":
			# Урон = (ловкость + интеллект) * 2
			base_damage = int((caster.agility + caster.intelligence) * 2)
		
		"alkara_dark_blast":
			# Урон = интеллект * 2.5
			base_damage = int(caster.intelligence * 2.5)
		
		"curse_blast":
			# Урон = интеллект + мудрость * 1.3
			base_damage = caster.intelligence + int(caster.wisdom * 1.3)
		
		"executioner_strike":
			# Два удара = (сила + ловкость * 1.5) * 2
			base_damage = (caster.strength + int(caster.agility * 1.5)) * 2
		
		"tharnok_crushing_strike":
			# Два удара
			var first_hit = caster.strength + caster.vitality
			var second_hit = caster.strength + int(caster.vitality * 1.7)
			base_damage = first_hit + second_hit
		
		"armor_strike":
			# Урон = (сила + живучесть) + P + защита × 2
			var defense = caster.get("defense") if caster.has_method("get") else 0
			base_damage = caster.strength + caster.vitality + P + (defense * 2)
		
		_:
			# Базовый урон для неизвестных способностей
			base_damage = caster.strength + caster.intelligence
	
	return max(base_damage, 1)  # Минимум 1 урон

func _show_defeat_screen():
	"""Показывает экран поражения"""
	print("Показываем экран поражения...")
	
	# Загружаем сцену экрана поражения
	var defeat_screen_scene = preload("res://Scenes/UI/DefeatScreen.tscn")
	var defeat_screen = defeat_screen_scene.instantiate()
	
	# Добавляем экран поражения как дочерний узел
	add_child(defeat_screen)
	
	# Подключаем сигнал закрытия экрана поражения
	defeat_screen.connect("defeat_screen_closed", Callable(self, "_on_defeat_screen_closed"))

func _apply_elite_rewards() -> Array:
	"""Применяет двойной прогресс пассивных способностей за победу над элитным врагом. Возвращает список полученного прогресса."""
	var progress_gained = []
	
	# Получаем систему изучения способностей
	var ability_learning_system = get_node_or_null("/root/AbilityLearningSystem")
	if not ability_learning_system:
		print("ОШИБКА: AbilityLearningSystem не найден!")
		return progress_gained
	
	# Получаем пассивные способности врага
	var enemy_passives = []
	if enemy_node and enemy_node.passive_abilities:
		for passive in enemy_node.passive_abilities:
			if passive and passive.name:
				enemy_passives.append(passive.name)
	
	# Применяем двойной прогресс (200%) для каждой пассивной способности врага
	for passive_name in enemy_passives:
		# Элитные враги дают двойной прогресс (200 очков) вместо обычных 100 очков
		var progress_data = ability_learning_system.add_progress_for_ability(passive_name, 200)
		if not progress_data.is_empty():
			progress_gained.append(progress_data)
	
	return progress_gained

func _on_defeat_screen_closed():
	"""Обрабатывает закрытие экрана поражения"""
	print("Экран поражения закрыт")
	# Дополнительная логика при необходимости

# ===== МЕТОДЫ ДЛЯ ТЕСТОВОГО РЕЖИМА =====

var test_mode: bool = false
var test_enemy_scene: String = ""
var test_enemy_rarity: String = "common"
var test_enemy_level: int = 1

func set_test_mode(enabled: bool):
	"""Включает или выключает тестовый режим"""
	test_mode = enabled

func set_test_enemy(enemy_scene: String, rarity: String):
	"""Устанавливает врага для тестового боя"""
	test_enemy_scene = enemy_scene
	test_enemy_rarity = rarity

func heal_player():
	"""Полностью восстанавливает здоровье игрока"""
	if player_node:
		player_node.hp = player_node.max_hp
		player_node.mp = player_node.max_mp
		player_node.endurance = player_node.max_endurance
		print("Игрок полностью восстановлен")
		if ui and ui.has_method("_update_ui"):
			ui._update_ui()

func heal_enemy():
	"""Полностью восстанавливает здоровье врага"""
	if enemy_node:
		enemy_node.hp = enemy_node.max_hp
		enemy_node.mp = enemy_node.max_mp
		enemy_node.endurance = enemy_node.max_endurance
		print("Враг полностью восстановлен")
		if ui and ui.has_method("_update_ui"):
			ui._update_ui()

func reset_player():
	"""Сбрасывает игрока к начальному состоянию"""
	if player_node:
		# Восстанавливаем все характеристики
		player_node.hp = player_node.max_hp
		player_node.mp = player_node.max_mp
		player_node.endurance = player_node.max_endurance
		
		# Убираем все эффекты
		if player_node.has_method("clear_all_effects"):
			player_node.clear_all_effects()
		
		print("Игрок сброшен к начальному состоянию")
		if ui and ui.has_method("_update_ui"):
			ui._update_ui()

func reset_enemy():
	"""Сбрасывает врага к начальному состоянию"""
	if enemy_node:
		# Восстанавливаем все характеристики
		enemy_node.hp = enemy_node.max_hp
		enemy_node.mp = enemy_node.max_mp
		enemy_node.endurance = enemy_node.max_endurance
		
		# Убираем все эффекты
		if enemy_node.has_method("clear_all_effects"):
			enemy_node.clear_all_effects()
		
		print("Враг сброшен к начальному состоянию")
		if ui and ui.has_method("_update_ui"):
			ui._update_ui()

func _check_global_test_variables():
	"""Проверяет глобальные переменные тестового режима"""
	var test_globals = get_node_or_null("/root/TestArenaGlobals")
	if test_globals and test_globals.test_mode:
		# Устанавливаем переменные из глобальных
		test_mode = test_globals.test_mode
		test_enemy_scene = test_globals.test_enemy_scene
		test_enemy_rarity = test_globals.test_enemy_rarity
		test_enemy_level = test_globals.test_enemy_level
		
		# Сбрасываем глобальные переменные после использования
		test_globals.reset()

func _spawn_test_enemy():
	"""Спавнит тестового врага"""
	if not test_mode or test_enemy_scene == "":
		return
	
	# Загружаем сцену врага
	var enemy_scene = load(test_enemy_scene)
	if not enemy_scene:
		return
	
	# Создаем экземпляр врага
	enemy_node = enemy_scene.instantiate()
	if not enemy_node:
		return
	
	# Устанавливаем редкость и уровень
	enemy_node.rarity = test_enemy_rarity
	enemy_node.level = test_enemy_level
	
	# Применяем бонусы редкости к характеристикам (как в enemy_spawner.gd)
	_apply_rarity_bonuses_to_enemy(enemy_node, test_enemy_rarity)
	
	# Добавляем в контейнер
	enemy_container.add_child(enemy_node)
	
	# Инициализируем врага
	if enemy_node.has_method("_ready"):
		enemy_node._ready()
	
	if ui and ui.has_method("_update_ui"):
		ui._update_ui()

func _apply_rarity_bonuses_to_enemy(enemy: Node, rarity: String):
	"""Применяет бонусы редкости к характеристикам врага (как в enemy_spawner.gd)"""
	# Применяем бонусы редкости к характеристикам (копируем логику из enemy_spawner.gd)
	if not enemy.has_method("set_rarity"):
		# Если у врага нет метода set_rarity, добавляем базовые бонусы к max_hp
		match rarity:
			"uncommon":
				enemy.max_hp = int(enemy.max_hp * 1.2)
				enemy.max_mp = int(enemy.max_mp * 1.2)
				enemy.max_stamina = int(enemy.max_stamina * 1.2)
			"rare":
				enemy.max_hp = int(enemy.max_hp * 1.4)  # 40% бонус
				enemy.max_mp = int(enemy.max_mp * 1.4)
				enemy.max_stamina = int(enemy.max_stamina * 1.4)
			"epic":
				enemy.max_hp = int(enemy.max_hp * 1.6)  # 60% бонус
				enemy.max_mp = int(enemy.max_mp * 1.6)
				enemy.max_stamina = int(enemy.max_stamina * 1.6)
			"elite_rare":
				enemy.max_hp = int(enemy.max_hp * 1.4 * 1.25)  # 40% от rare + 25% элитный бонус = 75%
				enemy.max_mp = int(enemy.max_mp * 1.4 * 1.25)
				enemy.max_stamina = int(enemy.max_stamina * 1.4 * 1.25)
			"elite_epic":
				enemy.max_hp = int(enemy.max_hp * 1.6 * 1.25)  # 60% от epic + 25% элитный бонус = 100%
				enemy.max_mp = int(enemy.max_mp * 1.6 * 1.25)
				enemy.max_stamina = int(enemy.max_stamina * 1.6 * 1.25)
			"elite_legendary":
				enemy.max_hp = int(enemy.max_hp * 1.8 * 1.25)  # 80% от legendary + 25% элитный бонус = 125%
				enemy.max_mp = int(enemy.max_mp * 1.8 * 1.25)
				enemy.max_stamina = int(enemy.max_stamina * 1.8 * 1.25)
			"legendary":
				enemy.max_hp = int(enemy.max_hp * 1.8)  # 80% бонус
				enemy.max_mp = int(enemy.max_mp * 1.8)
				enemy.max_stamina = int(enemy.max_stamina * 1.8)
			"boss":
				enemy.max_hp = int(enemy.max_hp * 2.0)  # 100% бонус
				enemy.max_mp = int(enemy.max_mp * 2.0)
				enemy.max_stamina = int(enemy.max_stamina * 2.0)
			"mythic":
				enemy.max_hp = int(enemy.max_hp * 2.5)  # 150% бонус
				enemy.max_mp = int(enemy.max_mp * 2.5)
				enemy.max_stamina = int(enemy.max_stamina * 2.5)
	
	# Обновляем текущее ХП и другие ресурсы на максимум
	enemy.hp = enemy.max_hp
	enemy.mp = enemy.max_mp
	enemy.stamina = enemy.max_stamina

func _play_delayed_sound(sound_name: String, delay: float, volume_db: float = 0.0):
	"""Воспроизводит звук с задержкой (асинхронно, не блокируя выполнение)"""
	# Создаем таймер для задержки
	await get_tree().create_timer(delay).timeout
	
	# Воспроизводим звук через SoundManager
	if SoundManager:
		SoundManager.play_sound(sound_name, volume_db)

func _flash_white(character: Node):
	"""Создает эффект белой вспышки при получении урона"""
	# Ищем визуальный узел (AnimatedSprite2D или Sprite2D)
	var visual_node = null
	if character.has_node("Visual"):
		visual_node = character.get_node("Visual")
	elif character is AnimatedSprite2D or character is Sprite2D:
		visual_node = character
	
	if not visual_node:
		return
	
	# Сохраняем оригинальный цвет
	var original_modulate = visual_node.modulate
	
	# Создаем Tween для анимации вспышки
	var tween = create_tween()
	
	# Моментально делаем ЯРКО белым (увеличено для более яркого эффекта)
	tween.tween_property(visual_node, "modulate", Color(5.0, 5.0, 5.0, 1.0), 0.0)
	# Плавно возвращаем к оригинальному цвету
	tween.tween_property(visual_node, "modulate", original_modulate, 0.15)

func _check_and_give_artifact():
	"""Проверяет и выдает артефакт если это нужный враг"""
	if not enemy_node or not player_manager:
		return
	
	var player_data = player_manager.get_player_data()
	if not player_data:
		return
	
	# Получаем свойства врага (они всегда есть у врагов)
	var enemy_name = enemy_node.get("display_name") if enemy_node.get("display_name") != null else ""
	var enemy_rarity = enemy_node.get("rarity") if enemy_node.get("rarity") != null else ""
	
	# Проверяем, является ли этот враг носителем артефакта
	# Урна душ - у редкого Слизня (Rare Slime)
	if (enemy_name == "Слизень" or enemy_name == "Slime") and enemy_rarity == "rare":
		if not player_data.has_soul_urn:
			player_data.give_soul_urn()
			_show_message("🏺 Вы нашли Урну душ среди останков слизня!\nОтнесите её Скульптору душ.", 5.0)
	
	# Добавляем квест на Кристалл познания после победы над Гнилостным слизнем
	elif enemy_name == "Гнилой слизень" or enemy_name == "Rotten Slime" or enemy_name == "Гнилостный слизень":
		if not player_data.has_knowledge_crystal:
			if not player_data.is_quest_available("find_knowledge_crystal") and not player_data.is_quest_active("find_knowledge_crystal"):
				player_data.make_quest_available("find_knowledge_crystal")
				_show_message("📜 Новый квест доступен!\nВернитесь к Скульптору душ, чтобы узнать больше.", 5.0)
	
	# Кристалл познания - у "Орка культиста" в Тёмном лесу
	elif enemy_name == "Орк культист" or enemy_name == "Orc Cultist" or ((enemy_name == "Орк шаман" or enemy_name == "Orc Shaman") and enemy_rarity == "epic"):
		# Получаем текущую локацию
		var location_manager = get_node_or_null("/root/LocationManager")
		var current_location_id = ""
		if location_manager and location_manager.current_location:
			current_location_id = location_manager.current_location.location_id
		
		if current_location_id == "forest" and not player_data.has_knowledge_crystal:
			player_data.give_knowledge_crystal()
			_show_message("💎 Ты нашел Кристалл познания!\nДревний артефакт пульсирует духовной энергией.\nОтнесите его Скульптору душ.", 5.0)
	
	# Добавляем квест на Филактерию после победы над Тёмным шатуном
	elif enemy_name == "Тёмный шатун" or enemy_name == "Dark Stalker":
		if not player_data.has_phylactery:
			if not player_data.is_quest_available("find_phylactery") and not player_data.is_quest_active("find_phylactery"):
				player_data.make_quest_available("find_phylactery")
				# Показываем сообщение только если кристалл уже доставлен (чтобы игрок знал, что может взять квест)
				if player_data.knowledge_crystal_delivered:
					_show_message("📜 Новый квест доступен!\nВернитесь к Скульптору душ, чтобы узнать больше.", 5.0)
	
	# Филактерия - у "Древнего скелета" или "Элитного скелета" в Заброшенном кладбище
	elif enemy_name == "Древний скелет" or enemy_name == "Ancient Skeleton" or ((enemy_name == "Элитный скелет" or enemy_name == "Элитный Скелет" or enemy_name == "Elite Skeleton") and enemy_rarity == "legendary"):
		# Получаем текущую локацию
		var location_manager = get_node_or_null("/root/LocationManager")
		var current_location_id = ""
		if location_manager and location_manager.current_location:
			current_location_id = location_manager.current_location.location_id
		
		# Проверяем локацию - Филактерия доступна только в Заброшенном кладбище
		if current_location_id == "cemetery":  # Заброшенное кладбище
			if not player_data.has_phylactery and player_data.knowledge_crystal_delivered:
				player_data.give_phylactery()
				_show_message("💀 Филактерия в ваших руках!\nВы чувствуете душу запечатанную внутри!\nОтнесите её Скульптору душ.", 5.0)

func _check_and_unlock_next_difficulty():
	"""Проверяет, был ли побежден босс, и разблокирует следующую сложность"""
	if not player_manager or enemy_nodes.size() == 0:
		return
	
	var player_data = player_manager.get_player_data()
	if not player_data:
		return
	
	# Ищем босса среди врагов
	var has_boss = false
	for dead_enemy in enemy_nodes:
		if not is_instance_valid(dead_enemy):
			continue
		
		var enemy_rarity = dead_enemy.get("rarity") if dead_enemy.get("rarity") != null else ""
		if enemy_rarity == "boss":
			has_boss = true
			break
	
	# Если босса не было, выходим
	if not has_boss:
		return
	
	# Получаем текущую локацию
	var location_manager = get_node_or_null("/root/LocationManager")
	if not location_manager or not location_manager.current_location:
		return
	
	var current_location_id = location_manager.current_location.location_id
	var current_difficulty = player_data.get_selected_difficulty(current_location_id)
	var max_unlocked = player_data.get_unlocked_difficulty(current_location_id)
	
	# Если текущая сложность равна максимально разблокированной, разблокируем следующую
	if current_difficulty == max_unlocked and max_unlocked < 3:
		player_data.unlock_next_difficulty(current_location_id)
		
		# Показываем сообщение об разблокировке
		var difficulty_names = ["", "I", "II", "III"]
		var next_diff = max_unlocked + 1
		_show_message("🎯 НОВАЯ СЛОЖНОСТЬ РАЗБЛОКИРОВАНА!\n\nСложность " + difficulty_names[next_diff] + " теперь доступна для этой локации!", 5.0)
	
	# Если побежден минибосс на сложности III, разблокируем босса локации
	if current_difficulty == 3 and max_unlocked == 3 and not player_data.is_location_boss_unlocked(current_location_id):
		player_data.unlock_location_boss(current_location_id)
		_show_message("👑 БОСС ЛОКАЦИИ РАЗБЛОКИРОВАН!\n\nТеперь доступен босс этой локации с особыми наградами!", 5.0)
	
	# Разблокирование следующей локации теперь происходит в RoomSelector._on_location_completed()

# ============================================================================
# СИСТЕМА МНОЖЕСТВЕННЫХ ВРАГОВ - Вспомогательные функции
# ============================================================================

func get_alive_enemies() -> Array[Node2D]:
	"""Возвращает массив живых врагов"""
	var alive: Array[Node2D] = []
	for enemy in enemy_nodes:
		if is_instance_valid(enemy) and enemy.hp > 0:
			alive.append(enemy)
	return alive

func get_enemy_count() -> int:
	"""Возвращает количество врагов в бою"""
	return enemy_nodes.size()

func get_alive_enemy_count() -> int:
	"""Возвращает количество живых врагов"""
	return get_alive_enemies().size()

func get_current_target() -> Node2D:
	"""Возвращает текущую выбранную цель для атаки игрока"""
	var alive = get_alive_enemies()
	if alive.size() == 0:
		selected_target_enemy = null
		return null
	
	# Если есть сохраненная ссылка на врага, проверяем, жив ли он
	# ВАЖНО: Проверяем напрямую, без поиска в массиве, чтобы не терять выбранного врага
	if selected_target_enemy and is_instance_valid(selected_target_enemy) and selected_target_enemy.hp > 0:
		# Проверяем, что враг действительно в массиве живых (для безопасности)
		var found_index = alive.find(selected_target_enemy)
		if found_index != -1:
			selected_target_index = found_index
		# ВСЕГДА возвращаем выбранного врага, если он жив, даже если не найден в массиве
		# (это может произойти, если массив создается заново, но враг тот же)
		# Обновляем подсветку
		if ui.has_method("highlight_selected_target_enemy"):
			ui.highlight_selected_target_enemy(selected_target_enemy)
		return selected_target_enemy
	
	# Если сохраненный враг мертв или не найден, выбираем первого живого врага
	if alive.size() > 0:
		print("WARNING: Выбранный враг не найден или мертв, выбираем первого живого врага")
		selected_target_index = 0
		selected_target_enemy = alive[0]
		# Обновляем подсветку
		if ui.has_method("highlight_selected_target_enemy"):
			ui.highlight_selected_target_enemy(selected_target_enemy)
		return selected_target_enemy
	
	selected_target_enemy = null
	return null

func select_next_target():
	"""Переключает цель на следующего живого врага"""
	var alive = get_alive_enemies()
	if alive.size() <= 1:
		return
	
	# Обновляем индекс на основе текущего выбранного врага
	if selected_target_enemy and is_instance_valid(selected_target_enemy):
		var found_index = alive.find(selected_target_enemy)
		if found_index != -1:
			selected_target_index = found_index
	
	selected_target_index = (selected_target_index + 1) % alive.size()
	selected_target_enemy = alive[selected_target_index]
	_show_message("Цель: " + alive[selected_target_index].display_name, 1.0)
	if ui.has_method("highlight_selected_target_enemy"):
		ui.highlight_selected_target_enemy(selected_target_enemy)
	else:
		ui.highlight_selected_target(selected_target_index)

func select_previous_target():
	"""Переключает цель на предыдущего живого врага"""
	var alive = get_alive_enemies()
	if alive.size() <= 1:
		return
	
	# Обновляем индекс на основе текущего выбранного врага
	if selected_target_enemy and is_instance_valid(selected_target_enemy):
		var found_index = alive.find(selected_target_enemy)
		if found_index != -1:
			selected_target_index = found_index
	
	selected_target_index = (selected_target_index - 1 + alive.size()) % alive.size()
	selected_target_enemy = alive[selected_target_index]
	_show_message("Цель: " + alive[selected_target_index].display_name, 1.0)
	if ui.has_method("highlight_selected_target_enemy"):
		ui.highlight_selected_target_enemy(selected_target_enemy)
	else:
		ui.highlight_selected_target(selected_target_index)

func select_target_by_index(index: int):
	"""Выбирает цель по индексу в массиве живых врагов"""
	var alive = get_alive_enemies()
	if index < 0 or index >= alive.size():
		return
	
	selected_target_index = index
	selected_target_enemy = alive[selected_target_index]
	_show_message("Цель: " + alive[selected_target_index].display_name, 1.0)
	if ui.has_method("highlight_selected_target_enemy"):
		ui.highlight_selected_target_enemy(selected_target_enemy)
	else:
		ui.highlight_selected_target(selected_target_index)

func get_enemies_sorted_by_distance() -> Array[Node2D]:
	"""Возвращает массив живых врагов, отсортированных по расстоянию до игрока (ближайший первый)"""
	var alive = get_alive_enemies()
	if not player_node or alive.size() == 0:
		return alive
	
	# Сортируем врагов по X координате (враги справа от игрока, меньший X = ближе)
	var enemies_with_x = []
	
	for enemy in alive:
		if not is_instance_valid(enemy):
			continue
		# Используем X координату для определения порядка (меньший X = ближе к игроку)
		var enemy_x = enemy.global_position.x
		enemies_with_x.append({"enemy": enemy, "x": enemy_x})
	
	# Сортируем по X координате (меньший X = ближе к игроку = первый)
	enemies_with_x.sort_custom(func(a, b): return a.x < b.x)
	
	# Возвращаем только врагов (явно указываем тип массива)
	var sorted_enemies: Array[Node2D] = []
	for item in enemies_with_x:
		sorted_enemies.append(item.enemy)
	
	return sorted_enemies

func select_target_by_position(target_position: int):
	"""Выбирает цель по позиции относительно игрока (1 = ближайший, 2 = второй, 3 = третий)"""
	var sorted_enemies = get_enemies_sorted_by_distance()
	if sorted_enemies.size() == 0:
		return
	
	# Позиция должна быть от 1 до 3, но индексы массива от 0
	var target_index = target_position - 1
	if target_index < 0 or target_index >= sorted_enemies.size():
		return
	
	var target_enemy = sorted_enemies[target_index]
	
	# Обновляем выбранного врага
	selected_target_enemy = target_enemy
	
	# Обновляем индекс в массиве живых врагов для совместимости
	var alive = get_alive_enemies()
	var found_index = alive.find(target_enemy)
	if found_index != -1:
		selected_target_index = found_index
	
	_show_message("Цель: " + target_enemy.display_name, 1.0)
	if ui.has_method("highlight_selected_target_enemy"):
		ui.highlight_selected_target_enemy(selected_target_enemy)
	else:
		ui.highlight_selected_target(selected_target_index)

func get_next_enemy_for_turn() -> Node2D:
	"""Возвращает следующего врага, который должен сходить"""
	var alive = get_alive_enemies()
	if alive.size() == 0:
		return null
	
	# Ищем следующего живого врага начиная с current_enemy_turn_index
	for _i in range(enemy_nodes.size()):
		current_enemy_turn_index = (current_enemy_turn_index + 1) % enemy_nodes.size()
		var enemy = enemy_nodes[current_enemy_turn_index]
		if is_instance_valid(enemy) and enemy.hp > 0:
			return enemy
	
	return null

func are_all_enemies_dead() -> bool:
	"""Проверяет, все ли враги мертвы"""
	return get_alive_enemy_count() == 0

## Вспомогательная функция для проигрывания эффекта способности на цели
## Использует универсальный AbilityEffectManager
func play_ability_effect_on_target(target: Node2D, ability_id: String, delay: float = 0.35) -> void:
	if not ability_effect_manager:
		print("Предупреждение: ability_effect_manager не инициализирован")
		return
	
	if delay > 0:
		await get_tree().create_timer(delay).timeout
	
	ability_effect_manager.play_ability_effect_on_target(target, ability_id)

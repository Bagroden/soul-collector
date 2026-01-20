extends Sprite2D
class_name SoulParticle

## Частица души, которая вылетает из врага и притягивается к игроку

# Параметры движения
var velocity: Vector2 = Vector2.ZERO
var acceleration: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO

# Фазы анимации
enum Phase { FLYING_UP, ATTRACTED, ABSORBED }
var current_phase: Phase = Phase.FLYING_UP

# Таймеры
var phase_timer: float = 0.0
var lifetime: float = 0.0

# Параметры анимации
var fly_up_duration: float = 0.8  # Время полета вверх
var attraction_strength: float = 800.0  # Сила притяжения
var rotation_speed: float = 0.0  # Скорость вращения

# Параметры параболической траектории
var curve_direction: Vector2 = Vector2.ZERO  # Направление изгиба траектории
var curve_strength: float = 0.0  # Сила изгиба (случайная для каждой частицы)
var wobble_frequency: float = 0.0  # Частота колебаний
var wobble_amplitude: float = 0.0  # Амплитуда колебаний

# Ссылки
var player_node: Node2D = null

func _ready() -> void:
	# Устанавливаем начальные параметры
	modulate.a = 0.0  # Начинаем невидимыми
	scale = Vector2(0.5, 0.5)  # Начальный размер
	
	# Плавное появление
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)

func setup(start_pos: Vector2, player: Node2D, rarity: String) -> void:
	## Настройка частицы с начальными параметрами
	global_position = start_pos
	player_node = player
	
	# Загружаем спрайт в зависимости от редкости
	var sprite_path = _get_sprite_path(rarity)
	texture = load(sprite_path)
	
	# Случайная начальная скорость (вверх и в стороны)
	var angle = randf_range(-PI * 0.6, -PI * 0.4)  # Примерно вверх
	var speed = randf_range(150.0, 300.0)
	velocity = Vector2(cos(angle), sin(angle)) * speed
	
	# Добавляем случайное боковое смещение
	velocity.x += randf_range(-100.0, 100.0)
	
	# Случайная скорость вращения
	rotation_speed = randf_range(-3.0, 3.0)
	
	# Случайная длительность фазы полета
	fly_up_duration = randf_range(0.6, 1.0)
	
	# Инициализируем параметры параболической траектории
	_initialize_curve_parameters()

func _initialize_curve_parameters() -> void:
	## Инициализирует параметры для параболической хаотичной траектории
	# Случайное направление изгиба (перпендикулярно направлению к игроку)
	var random_angle = randf() * TAU  # Случайный угол
	curve_direction = Vector2(cos(random_angle), sin(random_angle))
	
	# Сила изгиба (насколько сильно искривляется траектория)
	curve_strength = randf_range(100.0, 300.0)
	
	# Параметры волнообразного движения
	wobble_frequency = randf_range(2.0, 5.0)  # Частота колебаний
	wobble_amplitude = randf_range(20.0, 60.0)  # Амплитуда колебаний

func _get_sprite_path(rarity: String) -> String:
	## Возвращает путь к спрайту в зависимости от редкости
	match rarity.to_lower():
		"common":
			return "res://Assets/Sprites/Soul/Soul_fr_common.png"
		"uncommon":
			return "res://Assets/Sprites/Soul/Soul_fr_uncommon.png"
		"rare":
			return "res://Assets/Sprites/Soul/Soul_fr_rare.png"
		"epic":
			return "res://Assets/Sprites/Soul/Soul_fr_epic.png"
		"legendary":
			return "res://Assets/Sprites/Soul/Soul_fr_legendary.png"
		"mythic":
			return "res://Assets/Sprites/Soul/Soul_fr_mythic.png"
		_:
			return "res://Assets/Sprites/Soul/Soul_fr_common.png"

func _process(delta: float) -> void:
	lifetime += delta
	phase_timer += delta
	
	match current_phase:
		Phase.FLYING_UP:
			_process_flying_up(delta)
		Phase.ATTRACTED:
			_process_attracted(delta)
		Phase.ABSORBED:
			_process_absorbed(delta)
	
	# Применяем движение
	global_position += velocity * delta
	rotation += rotation_speed * delta

func _process_flying_up(delta: float) -> void:
	## Фаза полета вверх с хаотичным движением
	# Гравитация и сопротивление воздуха
	velocity.y += 50.0 * delta  # Небольшая гравитация
	velocity *= 0.98  # Сопротивление воздуха
	
	# Хаотичное колебание
	var wobble = sin(lifetime * 5.0) * 30.0
	velocity.x += wobble * delta
	
	# Переход к следующей фазе
	if phase_timer >= fly_up_duration:
		current_phase = Phase.ATTRACTED
		phase_timer = 0.0
		
		# Устанавливаем целевую позицию (центр игрока)
		if player_node:
			target_position = player_node.global_position

func _process_attracted(delta: float) -> void:
	## Фаза притяжения к игроку с параболической хаотичной траекторией
	if not player_node:
		queue_free()
		return
	
	# Обновляем целевую позицию
	target_position = player_node.global_position
	
	# Вектор к игроку и расстояние
	var direction = (target_position - global_position).normalized()
	var distance = global_position.distance_to(target_position)
	
	# === 1. ОСНОВНАЯ СИЛА ПРИТЯЖЕНИЯ (параболическая) ===
	var attraction_force = direction * attraction_strength
	var distance_multiplier = 1.0 + (1.0 - min(distance / 200.0, 1.0)) * 3.0
	var main_force = attraction_force * distance_multiplier
	
	# === 2. ПЕРПЕНДИКУЛЯРНАЯ СИЛА (создает изгиб траектории) ===
	# Вектор перпендикулярный направлению к игроку
	var perpendicular = Vector2(-direction.y, direction.x)
	# Сила изгиба уменьшается по мере приближения к цели
	var curve_fade = min(distance / 150.0, 1.0)  # Плавное уменьшение
	var curve_force = perpendicular * curve_strength * curve_fade
	# Направление изгиба зависит от curve_direction
	var curve_sign = sign(curve_direction.dot(perpendicular))
	curve_force *= curve_sign
	
	# === 3. ВОЛНООБРАЗНЫЕ КОЛЕБАНИЯ (хаотичность) ===
	# Синусоидальные колебания перпендикулярно направлению
	var wobble_offset = sin(phase_timer * wobble_frequency) * wobble_amplitude
	# Амплитуда уменьшается при приближении
	var wobble_fade = min(distance / 100.0, 1.0)
	var wobble_force = perpendicular * wobble_offset * wobble_fade
	
	# === 4. ДОПОЛНИТЕЛЬНЫЕ ХАОТИЧНЫЕ "ТОЛЧКИ" ===
	# Случайные небольшие отклонения для непредсказуемости
	var random_push = Vector2(
		sin(lifetime * 7.3) * 15.0,
		cos(lifetime * 5.7) * 15.0
	)
	
	# === СУММИРУЕМ ВСЕ СИЛЫ ===
	acceleration = main_force + curve_force + wobble_force + random_push
	
	# Применяем ускорение
	velocity += acceleration * delta
	velocity = velocity.limit_length(1000.0)  # Максимальная скорость
	
	# Увеличиваем скорость вращения при приближении
	rotation_speed += delta * 5.0
	
	# === ПРОВЕРКА ДОСТИЖЕНИЯ ЦЕЛИ ===
	var should_start_absorption = false
	
	# Условие 1: Расстояние меньше порога (близко к центру спрайта)
	if distance < 80.0:
		should_start_absorption = true
	
	# Условие 2: Частица очень близко И движется от игрока (признак "проскока")
	if distance < 100.0:
		var velocity_to_target = velocity.dot(direction)
		if velocity_to_target < 0:  # Движется от цели
			should_start_absorption = true
	
	# Условие 3: Таймаут - слишком долго в фазе притяжения
	if phase_timer > 4.0:  # Увеличен до 4 сек из-за более сложной траектории
		should_start_absorption = true
	
	if should_start_absorption:
		current_phase = Phase.ABSORBED
		phase_timer = 0.0

func _process_absorbed(delta: float) -> void:
	## Фаза поглощения игроком - всасывание в центр с исчезновением
	if not player_node:
		queue_free()
		return
	
	# Продолжаем двигаться к центру игрока во время исчезновения
	var direction = (player_node.global_position - global_position).normalized()
	var distance = global_position.distance_to(player_node.global_position)
	
	# Ускоренное движение к центру (эффект всасывания)
	var absorption_speed = 400.0
	velocity = direction * absorption_speed
	
	# Плавное исчезновение
	modulate.a -= delta * 5.0
	
	# Уменьшение размера (быстрее чем исчезновение)
	scale -= Vector2.ONE * delta * 4.0
	
	# Ускоряем вращение при всасывании
	rotation_speed += delta * 10.0
	
	# Удаляем частицу при полном исчезновении ИЛИ достижении центра
	if modulate.a <= 0.0 or scale.x <= 0.1 or distance < 10.0:
		queue_free()


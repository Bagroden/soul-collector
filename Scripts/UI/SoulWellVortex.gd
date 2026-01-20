# res://Scripts/UI/SoulWellVortex.gd
extends Node2D

## Менеджер вихря частиц душ для Колодца Душ на экране подготовки
## Создает эффект крутящихся по спирали частиц, поднимающихся из центра экрана

## Спрайты и веса редкостей (больше вес = чаще появляются)
const RARITY_DATA = {
	"Common": {
		"path": "res://Assets/Sprites/Soul/Soul_fr_common.png",
		"weight": 50,  # Белые - больше всего
		"scale_min": 0.45,
		"scale_max": 0.7,
		"is_special": false
	},
	"Uncommon": {
		"path": "res://Assets/Sprites/Soul/Soul_fr_uncommon.png",
		"weight": 30,  # Зеленые - чуть меньше
		"scale_min": 0.5,
		"scale_max": 0.75,
		"is_special": false
	},
	"Rare": {
		"path": "res://Assets/Sprites/Soul/Soul_fr_rare.png",
		"weight": 15,  # Голубые - меньше
		"scale_min": 0.55,
		"scale_max": 0.85,
		"is_special": false
	},
	"Epic": {
		"path": "res://Assets/Sprites/Soul/Soul_fr_epic.png",
		"weight": 8,  # Фиолетовые - еще меньше
		"scale_min": 0.65,
		"scale_max": 0.95,
		"is_special": false
	},
	"Legendary": {
		"path": "res://Assets/Sprites/Soul/Soul_fr_legendary.png",
		"weight": 4,  # Оранжевые - мало
		"scale_min": 0.75,
		"scale_max": 1.05,
		"is_special": false
	},
	"Mythic": {
		"path": "res://Assets/Sprites/Soul/Soul_fr_mythic.png",
		"weight": 1,  # Красные - очень редко
		"scale_min": 0.85,
		"scale_max": 1.2,
		"is_special": false
	},
	"Strong": {
		"path": "res://Assets/Sprites/Soul/Strong_soul.png",
		"weight": 0,  # Не участвует в рандоме, спавнится отдельно
		"scale_min": 0.5,  # Уменьшено в 2 раза
		"scale_max": 0.65,  # Уменьшено в 2 раза
		"is_special": true
	},
	"Great": {
		"path": "res://Assets/Sprites/Soul/Great_soul.png",
		"weight": 0,  # Не участвует в рандоме, спавнится отдельно
		"scale_min": 0.6,  # Уменьшено в 2 раза
		"scale_max": 0.75,  # Уменьшено в 2 раза
		"is_special": true
	},
	"Divine": {
		"path": "res://Assets/Sprites/Soul/Divine_soul.png",
		"weight": 0,  # Не участвует в рандоме, спавнится отдельно
		"scale_min": 0.7,  # Уменьшено в 2 раза
		"scale_max": 0.9,  # Уменьшено в 2 раза
		"is_special": true
	}
}

## Таблица соответствия осколков душ и количества частиц в вихре
const SOUL_SHARDS_TO_PARTICLES = [
	{"min": 0, "max": 49, "particles": 30},  # Минимальный вихрь (если есть специальные души)
	{"min": 50, "max": 500, "particles": 30},
	{"min": 501, "max": 2000, "particles": 60},
	{"min": 2001, "max": 5000, "particles": 90},
	{"min": 5001, "max": 8000, "particles": 120},
	{"min": 8001, "max": 10000, "particles": 150},
	{"min": 10001, "max": 15000, "particles": 180},
	{"min": 15001, "max": 20000, "particles": 210},
	{"min": 20001, "max": 25000, "particles": 240},
	{"min": 25001, "max": 30000, "particles": 270},
	{"min": 30001, "max": 999999, "particles": 300}
]

## Параметры вихря
const SPAWN_INTERVAL = 0.08  # Интервал между спавном частиц (секунды) - чаще для плотности
const PARTICLES_PER_SPAWN = 3  # Количество частиц за один спавн - больше для плотности
const VORTEX_RADIUS_MIN = 100.0  # Минимальный радиус спирали (низ вихря - шире)
const VORTEX_RADIUS_MAX = 225.0  # Максимальный радиус спирали (верх вихря)
const RISE_SPEED = 60.0  # Скорость подъема вверх (пикселей/сек)
const ROTATION_SPEED = 0.7  # Скорость вращения (радиан/сек, замедлено на 30%)
const VORTEX_HEIGHT = 600.0  # Высота вихря (пикселей) - сжато на треть
const FADE_IN_TIME = 1.0  # Время плавного появления частицы при инициализации

## Центральная точка колодца (относительно экрана)
var well_center: Vector2

## Счетчик угла для спирали
var spiral_angle: float = 0.0

## Флаг инициализации (для плавного появления при запуске)
var initialization_time: float = 0.0
var is_initializing: bool = true

## Целевое количество частиц в вихре (на основе осколков душ)
var target_particle_count: int = 0

## Целевое количество специальных душ в вихре
var special_souls_target = {
	"Strong": 0,
	"Great": 0,
	"Divine": 0
}

func _ready() -> void:
	## Инициализация менеджера вихря
	# Устанавливаем центр колодца (центр экрана)
	var viewport_size = get_viewport_rect().size
	well_center = viewport_size / 2.0
	
	# Рассчитываем целевое количество частиц
	_update_target_particle_count()
	
	# Создаем ВСЕ частицы сразу
	_create_all_particles()
	
	# Устанавливаем позицию менеджера
	global_position = Vector2.ZERO

func _process(delta: float) -> void:
	## Обрабатываем плавное появление при инициализации
	if is_initializing:
		initialization_time += delta
		if initialization_time >= FADE_IN_TIME:
			is_initializing = false

func _create_all_particles() -> void:
	## Создает все частицы вихря сразу при инициализации
	print("🌪️ Создаем вихрь из ", target_particle_count, " частиц...")
	
	# Создаем массив типов душ для равномерного распределения
	var soul_types = []
	
	# Добавляем специальные души
	for i in range(special_souls_target["Divine"]):
		soul_types.append("Divine")
	for i in range(special_souls_target["Great"]):
		soul_types.append("Great")
	for i in range(special_souls_target["Strong"]):
		soul_types.append("Strong")
	
	# Добавляем обычные души (заполняем остаток)
	var base_souls_count = target_particle_count - soul_types.size()
	for i in range(base_souls_count):
		soul_types.append(_get_weighted_rarity())
	
	# ПЕРЕМЕШИВАЕМ массив для равномерного распределения
	soul_types.shuffle()
	
	# Подсчитываем каждый тип для диагностики
	var type_counts = {
		"Common": 0,
		"Uncommon": 0,
		"Rare": 0,
		"Epic": 0,
		"Legendary": 0,
		"Mythic": 0,
		"Strong": 0,
		"Great": 0,
		"Divine": 0
	}
	for soul_type in soul_types:
		if soul_type in type_counts:
			type_counts[soul_type] += 1
	
	print("📊 Создаем души: ", soul_types.size())
	print("  └─ Обычные (всего ", base_souls_count, "): Common=", type_counts["Common"], " Uncommon=", type_counts["Uncommon"], " Rare=", type_counts["Rare"], " Epic=", type_counts["Epic"], " Legendary=", type_counts["Legendary"], " Mythic=", type_counts["Mythic"])
	print("  └─ Специальные: Strong=", type_counts["Strong"], " Great=", type_counts["Great"], " Divine=", type_counts["Divine"])
	
	# Создаем частицы с заранее определенными типами
	for i in range(target_particle_count):
		_create_vortex_particle_at_position(i, soul_types[i])

func _get_weighted_rarity() -> String:
	## Возвращает случайную редкость с учетом весов (только обычные души)
	## Специальные души (с весом 0 или is_special = true) игнорируются
	
	# Вычисляем общий вес (только не-специальные души)
	var total_weight = 0
	for rarity in RARITY_DATA:
		if not RARITY_DATA[rarity].get("is_special", false):
			total_weight += RARITY_DATA[rarity]["weight"]
	
	# Случайное число от 0 до total_weight
	var random_value = randf_range(0, total_weight)
	
	# Выбираем редкость на основе весов (только не-специальные души)
	var current_weight = 0
	for rarity in RARITY_DATA:
		if not RARITY_DATA[rarity].get("is_special", false):
			current_weight += RARITY_DATA[rarity]["weight"]
			if random_value <= current_weight:
				return rarity
	
	# На всякий случай возвращаем Common
	return "Common"

func _create_vortex_particle_at_position(index: int, rarity: String) -> void:
	## Создает одну частицу вихря на определенной высоте с заданным типом
	var particle = Sprite2D.new()
	
	# Получаем информацию о редкости
	var rarity_info = RARITY_DATA[rarity]
	
	# Загружаем спрайт
	var sprite_path = rarity_info["path"]
	var texture = load(sprite_path)
	if not texture:
		push_error("Не удалось загрузить текстуру частицы: " + sprite_path)
		particle.queue_free()
		return
	particle.texture = texture
	
	# Размер зависит от редкости
	var scale_value = randf_range(rarity_info["scale_min"], rarity_info["scale_max"])
	particle.scale = Vector2(scale_value, scale_value)
	
	# Добавляем на сцену
	add_child(particle)
	
	# Инициализируем параметры движения
	var start_angle = (index / float(target_particle_count)) * TAU * 3.0  # Распределяем по спирали
	var radius_speed = randf_range(0.8, 1.2)
	
	# ФИКСИРОВАННАЯ высота - частица будет крутиться на этой высоте
	var fixed_height = (index / float(target_particle_count)) * VORTEX_HEIGHT
	
	# Создаем данные для частицы
	particle.set_meta("fixed_height", fixed_height)  # Фиксированная высота (НЕ меняется)
	particle.set_meta("time", 0.0)  # Просто время для вращения
	particle.set_meta("start_angle", start_angle)
	particle.set_meta("radius_speed", radius_speed)
	particle.set_meta("rotation_offset", randf_range(0.0, TAU))
	particle.set_meta("initial_scale", scale_value)
	
	# Сохраняем тип души для отслеживания специальных душ
	if rarity in ["Strong", "Great", "Divine"]:
		particle.set_meta("soul_type", rarity)

func _physics_process(delta: float) -> void:
	## Обновляем позиции всех частиц
	for child in get_children():
		if child is Sprite2D:
			_update_particle(child, delta)

func _update_particle(particle: Sprite2D, delta: float) -> void:
	## Обновляет позицию и состояние одной частицы (просто крутится на месте)
	# Получаем данные частицы
	var fixed_height = particle.get_meta("fixed_height", 0.0)  # ФИКСИРОВАННАЯ высота
	var time = particle.get_meta("time", 0.0)
	var start_angle = particle.get_meta("start_angle", 0.0)
	var radius_speed = particle.get_meta("radius_speed", 1.0)
	var rotation_offset = particle.get_meta("rotation_offset", 0.0)
	var initial_scale = particle.get_meta("initial_scale", 1.0)
	
	# Обновляем время (только для вращения)
	time += delta
	particle.set_meta("time", time)
	
	# Вычисляем прогресс от 0 (низ) до 1 (верх) на основе ФИКСИРОВАННОЙ высоты
	var progress = fixed_height / VORTEX_HEIGHT
	
	# Вычисляем текущий угол (вращение по спирали)
	var current_angle = start_angle + (ROTATION_SPEED * time) + rotation_offset
	
	# Вычисляем радиус (трапеция: расширяется от низа к верху)
	var radius: float
	# Линейное увеличение радиуса от низа (узкий) к верху (широкий)
	radius = lerp(VORTEX_RADIUS_MIN, VORTEX_RADIUS_MAX, progress)
	
	radius *= radius_speed
	
	# Вычисляем финальную позицию (спираль)
	var spiral_offset = Vector2(
		cos(current_angle) * radius,
		sin(current_angle) * radius * 0.3  # Сплющиваем по Y для эффекта перспективы
	)
	
	# Применяем смещение: +40 вправо, ФИКСИРОВАННАЯ высота от низа вихря
	particle.global_position = well_center + Vector2(40, 170) + Vector2(0, -fixed_height) + spiral_offset
	
	# Вращение частицы вокруг своей оси
	particle.rotation = current_angle * 0.5
	
	# Плавное появление только при инициализации всего вихря
	var base_alpha = 1.0
	if is_initializing:
		var fade_progress = initialization_time / FADE_IN_TIME
		base_alpha = lerp(0.0, 1.0, fade_progress)
	
	# Применяем прозрачность и размер
	particle.modulate.a = base_alpha
	particle.scale = Vector2(initial_scale, initial_scale)
	
	# Добавляем легкое мерцание (только после инициализации)
	if not is_initializing:
		var flicker = sin(fixed_height * 0.1 + time) * 0.1 + 0.9
		particle.modulate.a *= flicker

func _update_target_particle_count() -> void:
	## Обновляет целевое количество частиц на основе осколков душ
	var soul_shards = 0
	
	# Получаем количество осколков душ из SoulShard (автозагрузка)
	if has_node("/root/SoulShard"):
		var soul_shards_manager = get_node("/root/SoulShard")
		soul_shards = soul_shards_manager.get_soul_shards()
		print("🔮 Осколков душ у игрока: ", soul_shards)
	else:
		print("⚠️ ОШИБКА: Автозагрузка SoulShard не найдена!")
	
	# Определяем количество частиц по таблице
	target_particle_count = 0
	for tier in SOUL_SHARDS_TO_PARTICLES:
		if soul_shards >= tier["min"] and soul_shards <= tier["max"]:
			target_particle_count = tier["particles"]
			print("📊 Базовых частиц: ", target_particle_count, " (уровень: ", tier["min"], "-", tier["max"], ")")
			break
	
	# Обнуляем счетчики специальных душ
	special_souls_target["Strong"] = 0
	special_souls_target["Great"] = 0
	special_souls_target["Divine"] = 0
	
	# Получаем количество специальных душ
	var base_particle_count = target_particle_count  # Запоминаем базовое количество
	
	# Получаем счетчики специальных душ у игрока
	var strong_count = 0
	var great_count = 0
	var divine_count = 0
	
	if has_node("/root/StrongSouls"):
		var strong_souls_manager = get_node("/root/StrongSouls")
		strong_count = strong_souls_manager.get_strong_souls()
	
	if has_node("/root/GreatSouls"):
		var great_souls_manager = get_node("/root/GreatSouls")
		great_count = great_souls_manager.get_great_souls()
	
	if has_node("/root/DivineSouls"):
		var divine_souls_manager = get_node("/root/DivineSouls")
		divine_count = divine_souls_manager.get_divine_souls()
	
	# Рассчитываем количество специальных душ для вихря
	# Специальные души ограничиваем пропорционально базовому количеству
	if strong_count > 0:
		special_souls_target["Strong"] = min(strong_count, max(int(base_particle_count * 0.2), 1))
	if great_count > 0:
		special_souls_target["Great"] = min(great_count, max(int(base_particle_count * 0.15), 1))
	if divine_count > 0:
		special_souls_target["Divine"] = min(divine_count, max(int(base_particle_count * 0.1), 1))
	
	# Увеличиваем целевое количество частиц с учетом специальных душ
	target_particle_count += special_souls_target["Strong"]
	target_particle_count += special_souls_target["Great"]
	target_particle_count += special_souls_target["Divine"]
	
	print("✨ Итого частиц в вихре: ", target_particle_count, " (обычные + Strong:", special_souls_target["Strong"], " + Great:", special_souls_target["Great"], " + Divine:", special_souls_target["Divine"], ")")

func _get_next_soul_type() -> String:
	## Определяет следующий тип души для спавна
	## Считает текущие души в сцене и решает нужна ли специальная душа
	
	# Подсчитываем текущее количество каждого типа специальных душ
	var current_special_souls = {
		"Strong": 0,
		"Great": 0,
		"Divine": 0
	}
	
	for child in get_children():
		if child is Sprite2D:
			var soul_type = child.get_meta("soul_type", "")
			if soul_type in current_special_souls:
				current_special_souls[soul_type] += 1
	
	# Проверяем приоритет: Divine → Great → Strong → Обычные
	# Если текущее количество меньше целевого - спавним специальную душу
	
	if current_special_souls["Divine"] < special_souls_target["Divine"]:
		return "Divine"
	
	if current_special_souls["Great"] < special_souls_target["Great"]:
		return "Great"
	
	if current_special_souls["Strong"] < special_souls_target["Strong"]:
		return "Strong"
	
	# Все специальные души на месте, спавним обычную
	return _get_weighted_rarity()

func cleanup() -> void:
	## Очищает все частицы
	for child in get_children():
		if child is Sprite2D:
			child.queue_free()


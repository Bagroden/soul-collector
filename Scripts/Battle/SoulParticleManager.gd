extends Node
class_name SoulParticleManager

## Менеджер для создания и управления частицами душ

# Количество частиц по редкости
const PARTICLE_COUNTS = {
	"Common": {"min": 3, "max": 5},
	"Uncommon": {"min": 5, "max": 8},
	"Rare": {"min": 8, "max": 12},
	"Epic": {"min": 12, "max": 15},
	"Legendary": {"min": 15, "max": 18},
	"Mythic": {"min": 18, "max": 25}
}

# Ссылка на контейнер для частиц
var particle_container: Node2D = null

func _ready() -> void:
	# Создаем контейнер для частиц, если его нет
	if not particle_container:
		particle_container = Node2D.new()
		particle_container.name = "SoulParticles"
		add_child(particle_container)

func spawn_soul_particles(enemy_position: Vector2, player_node: Node2D, enemy_rarity: String, enemy_level: int) -> void:
	## Создает частицы душ, вылетающие из врага
	if not player_node:
		print("Ошибка: нет ссылки на игрока для частиц душ")
		return
	
	# Определяем количество частиц
	var particle_count = _calculate_particle_count(enemy_rarity, enemy_level)
	
	print("Создаем %d частиц души (редкость: %s, уровень: %d)" % [particle_count, enemy_rarity, enemy_level])
	
	# Создаем частицы с небольшой задержкой между ними
	for i in range(particle_count):
		# Задержка для создания эффекта "взрыва" душ
		await get_tree().create_timer(randf_range(0.0, 0.15)).timeout
		_create_particle(enemy_position, player_node, enemy_rarity)

func _calculate_particle_count(rarity: String, level: int) -> int:
	## Вычисляет количество частиц на основе редкости и уровня
	var counts = PARTICLE_COUNTS.get(rarity, PARTICLE_COUNTS["Common"])
	var base_count = randi_range(counts["min"], counts["max"])
	
	# Добавляем бонус за уровень (1 частица на каждые 3 уровня)
	var level_bonus = floori(level / 3.0)
	
	return base_count + level_bonus

func _create_particle(position: Vector2, player: Node2D, rarity: String) -> void:
	## Создает одну частицу души
	# Создаем Sprite2D и устанавливаем скрипт
	var particle = Sprite2D.new()
	var script = load("res://Scripts/Battle/SoulParticle.gd")
	particle.set_script(script)
	
	# Добавляем в контейнер или в текущую сцену
	if particle_container:
		particle_container.add_child(particle)
	else:
		add_child(particle)
	
	# Добавляем случайное смещение от центра врага
	var offset = Vector2(randf_range(-30.0, 30.0), randf_range(-20.0, 20.0))
	var start_position = position + offset
	
	# Настраиваем частицу
	particle.setup(start_position, player, rarity)

func clear_all_particles() -> void:
	## Удаляет все активные частицы (для очистки)
	if particle_container:
		for child in particle_container.get_children():
			child.queue_free()

func get_active_particle_count() -> int:
	## Возвращает количество активных частиц
	if particle_container:
		return particle_container.get_child_count()
	return 0

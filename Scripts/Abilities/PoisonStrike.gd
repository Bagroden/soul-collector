# res://Scripts/Abilities/PoisonStrike.gd
extends PlayerAbility

func _init():
	id = "poison_strike"
	name = "Ядовитый удар"
	description = "Наносит ядовитый урон, который игнорирует защиту и магическое сопротивление. Урон: уровень * интеллект."
	mp_cost = 0
	stamina_cost = 20
	cooldown = 0
	damage_type = "poison"

func calculate_damage(owner: Node, _target: Node) -> int:
	"""Рассчитывает урон Ядовитого удара"""
	# Получаем уровень игрока
	var player_level = 1  # По умолчанию уровень 1
	if owner.has_method("get_level"):
		player_level = owner.get_level()
	elif "level" in owner:
		player_level = owner.level
	
	# Получаем интеллект игрока
	var intelligence = 0
	if "intelligence" in owner:
		intelligence = owner.intelligence
	
	# Базовая формула: уровень * интеллект
	var base_damage = int(player_level * intelligence)
	
	# Добавляем бонусы к ядовитому урону
	var total_damage = base_damage
	if owner.has_method("get_poison_damage"):
		# Если у владельца есть метод get_poison_damage, используем его
		total_damage = owner.get_poison_damage()
	else:
		# Иначе используем базовый урон (ядовитый урон не получает бонусы от физических способностей)
		pass
	
	return total_damage

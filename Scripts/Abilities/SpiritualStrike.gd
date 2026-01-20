# res://Scripts/Abilities/SpiritualStrike.gd
extends PlayerAbility

func _init():
	id = "spiritual_strike"
	name = "Спиритический удар"
	description = "Наносит урон равный сумме всех характеристик. Потребляет 15 маны."
	mp_cost = 15
	stamina_cost = 0
	cooldown = 0
	damage_type = "magic"

func use_ability(owner: Node, target: Node) -> Dictionary:
	"""Использует Спиритический удар с звуковым эффектом"""
	# Воспроизводим звук Спиритического удара
	if SoundManager:
		SoundManager.play_sound("magic2", -5.0)
	
	# Вызываем базовый метод
	return super.use_ability(owner, target)

func calculate_damage(owner: Node, _target: Node) -> int:
	"""Рассчитывает урон Спиритического удара"""
	# Получаем уровень игрока (не используется в текущей формуле)
	var _player_level = 1  # По умолчанию уровень 1
	if owner.has_method("get_level"):
		_player_level = owner.get_level()
	elif "level" in owner:
		_player_level = owner.level
	
	# Суммируем все характеристики
	var total_stats = 0
	if "strength" in owner:
		total_stats += owner.strength
	if "agility" in owner:
		total_stats += owner.agility
	if "vitality" in owner:
		total_stats += owner.vitality
	if "endurance" in owner:
		total_stats += owner.endurance
	if "intelligence" in owner:
		total_stats += owner.intelligence
	if "wisdom" in owner:
		total_stats += owner.wisdom
	
	# Формула: сумма всех характеристик * (1 + бонус от интеллекта к магическому урону)
	var base_damage = total_stats
	
	# Применяем бонус магического урона от интеллекта (1 интеллект = +1% магического урона)
	var magic_damage_bonus = 0.0
	if "magic_damage_bonus" in owner:
		magic_damage_bonus = owner.magic_damage_bonus
	
	var damage = int(base_damage * (1.0 + magic_damage_bonus))
	
	return damage

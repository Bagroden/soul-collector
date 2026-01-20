# res://Scripts/Abilities/KineticStrike.gd
extends PlayerAbility

func _init():
	id = "kinetic_strike"
	name = "Кинетический удар"
	description = "Наносит урон по формуле: (Сила + Ловкость + Живучесть) × 2.5 + P. Потребляет 25 выносливости."
	mp_cost = 0
	stamina_cost = 25
	cooldown = 0
	damage_type = "physical"

func calculate_damage(owner: Node, _target: Node) -> int:
	"""Рассчитывает урон Кинетического удара"""
	# Получаем характеристики игрока
	var strength = 0
	var agility = 0
	var vitality = 0
	
	if "strength" in owner:
		strength = owner.strength
	if "agility" in owner:
		agility = owner.agility
	if "vitality" in owner:
		vitality = owner.vitality
	
	# Формула: (Сила + Ловкость + Живучесть) × 2.5 + P
	var base_damage = (strength + agility + vitality) * 2.5
	
	# Добавляем переменную P (physical_damage_bonus)
	if owner.has_method("get_physical_damage_bonus"):
		base_damage += owner.get_physical_damage_bonus()
	elif "physical_damage_bonus" in owner:
		base_damage += owner.physical_damage_bonus
	
	return int(base_damage)

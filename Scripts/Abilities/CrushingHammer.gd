# res://Scripts/Abilities/CrushingHammer.gd
extends Node

var id: String = "crushing_hammer"
var name: String = "Сокрушительный молот"
var description: String = "Два мощных удара молотом - размашистый и добивающий"
var stamina_cost: int = 60
var damage_type: String = "physical"
var cooldown: int = 3

func execute_ability(owner: Node, target: Node = null) -> Dictionary:
	if not target:
		return {"success": false, "message": "Нет цели для удара"}
	
	# Проверяем, достаточно ли выносливости
	if owner.current_stamina < stamina_cost:
		return {"success": false, "message": "Недостаточно выносливости для сокрушительного молота"}
	
	# Тратим выносливость
	owner.current_stamina -= stamina_cost
	
	# Воспроизводим звук удара молотом
	if SoundManager:
		SoundManager.play_sound("hammer_strike", -6.0)
	
	return {
		"success": true,
		"message": owner.display_name + " замахивается сокрушительным молотом!",
		"is_multi_hit": true,
		"ability": "crushing_hammer",
		"stamina_cost": stamina_cost,
		"cooldown": cooldown,
		"hits": [
			{
				"damage_formula": "first_strike",  # Сила * 1.5 + живучесть
				"delay": 0.0,
				"message": "РАЗМАШИСТЫЙ УДАР"
			},
			{
				"damage_formula": "finishing_strike",  # Сила * 2.0 + живучесть * 1.3
				"delay": 0.8,
				"stun_chance": 25.0,
				"message": "ДОБИВАЮЩИЙ УДАР"
			}
		]
	}

func calculate_hit_damage(owner: Node, hit_type: String) -> int:
	"""Рассчитывает урон для конкретного удара"""
	var base_damage = 0
	
	if hit_type == "first_strike":
		# Первый удар: сила * 1.5 + живучесть
		base_damage = (owner.strength * 1.5) + owner.vitality
	elif hit_type == "finishing_strike":
		# Второй удар: сила * 2.0 + живучесть * 1.3
		base_damage = (owner.strength * 2.0) + (owner.vitality * 1.3)
	
	return int(base_damage)

func apply_armor_reduction(target: Node):
	"""Применяет снижение брони на 5 единиц на 2 хода"""
	if target:
		var current_reduction = target.get_meta("crushing_hammer_armor_reduction", 0)
		target.set_meta("crushing_hammer_armor_reduction", current_reduction + 5)
		target.set_meta("crushing_hammer_armor_reduction_duration", 2)


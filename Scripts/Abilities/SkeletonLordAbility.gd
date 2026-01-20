# res://Scripts/Abilities/SkeletonLordAbility.gd
extends Node

class_name SkeletonLordAbility

var id: String = "armor_strike"
var name: String = "Удар брони"
var description: String = "Наносит урон, равный (сила + живучесть) + P + текущая защита × 2. Снижает защиту цели на 6 до конца боя."
var stamina_cost: int = 35  # Стоимость выносливости

func execute_ability(owner: Node, target: Node = null) -> Dictionary:
	if not target:
		return {"success": false, "message": "Нет цели для удара брони"}
	
	# Проверяем, достаточно ли выносливости
	if owner.current_stamina < stamina_cost:
		return {"success": false, "message": "Недостаточно выносливости"}
	
	# Получаем характеристики владельца
	var strength_val = 0
	var vitality_val = 0
	var current_defense = 0
	
	if "strength" in owner:
		strength_val = owner.strength
	if "vitality" in owner:
		vitality_val = owner.vitality
	if "defense" in owner:
		current_defense = owner.defense
	
	# Получаем бонус физического урона (P)
	var physical_bonus = 0
	if owner.has_method("get_physical_damage_bonus"):
		physical_bonus = owner.get_physical_damage_bonus()
	elif "physical_damage_bonus" in owner:
		physical_bonus = owner.physical_damage_bonus
	
	# Рассчитываем урон: (сила + живучесть) + P + текущая защита * 2
	var damage = strength_val + vitality_val + physical_bonus + (current_defense * 2)
	
	# Проверяем критический удар
	var is_crit = false
	if owner.has_method("get_crit_chance"):
		var crit_chance = owner.get_crit_chance()
		is_crit = randf() < (crit_chance / 100.0)
	
	if is_crit:
		damage = int(damage * 1.5)  # Критический урон
	
	return {
		"success": true,
		"damage": damage,
		"is_crit": is_crit,
		"damage_type": "physical",
		"message": owner.display_name + " использует Удар брони!",
		"armor_strike": true,  # Флаг для battle_manager
		"armor_reduction": 6  # Снижение брони на 6 единиц
	}


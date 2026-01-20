# res://Scripts/Abilities/DoubleStrike.gd
extends Ability

func _init():
	id = "double_strike"
	name = "Двойной удар"
	description = "Наносит два быстрых удара нанося урон два раза. Урон каждого удара (Сила + ловкость)/1.5"
	cooldown = 0  # Нет перезарядки
	mana_cost = 0  # Не требует маны
	stamina_cost = 30  # Требует 30 ОВ
	damage_type = "physical"  # Физический урон

func execute_ability(owner: Node, target: Node = null, _context: Dictionary = {}) -> Dictionary:
	if not target:
		return {"success": false, "message": "Нет цели для атаки"}
	
	# Проверяем, достаточно ли выносливости
	if owner.has_method("get_stamina"):
		var current_stamina = owner.get_stamina()
		if current_stamina < stamina_cost:
			return {"success": false, "message": "Недостаточно выносливости для использования способности"}
		
		# Тратим выносливость
		if owner.has_method("spend_stamina"):
			owner.spend_stamina(stamina_cost)
	
	# Получаем характеристики владельца
	var strength = owner.strength if "strength" in owner else 0
	var agility = owner.agility if "agility" in owner else 0
	
	# Получаем бонус физического урона (P)
	var physical_bonus = 0
	if owner.has_method("get_physical_damage_bonus"):
		physical_bonus = owner.get_physical_damage_bonus()
	elif "physical_damage_bonus" in owner:
		physical_bonus = owner.physical_damage_bonus
	
	# Вычисляем базовый урон по формуле способности (с учетом P)
	# (Сила + Ловкость + P) / 1.5
	var base_damage = int((strength + agility + physical_bonus) / 1.5)
	
	# Применяем бонус "Боец" к итоговому урону
	var fighter_bonus = 0
	if owner.has_method("get_passive_abilities"):
		var passive_abilities = owner.get_passive_abilities()
		for ability in passive_abilities:
			if ability.id == "fighter":
				var ability_level = 1
				if owner.has_method("get_ability_level"):
					ability_level = owner.get_ability_level(ability.id)
				var fighter_percentage = ability.get_value_for_level(ability_level)
				fighter_bonus = int(base_damage * (fighter_percentage / 100.0))
				break
	
	var damage_per_hit = base_damage + fighter_bonus
	
	
	# Наносим первый удар
	var first_hit_result = target.take_damage(damage_per_hit, damage_type) if target.has_method("take_damage") else false
	
	# Наносим второй удар
	var second_hit_result = target.take_damage(damage_per_hit, damage_type) if target.has_method("take_damage") else false
	
	var total_damage = damage_per_hit * 2
	
	return {
		"success": true,
		"message": "Двойной удар - " + owner.display_name + " наносит два быстрых удара! Урон: " + str(total_damage) + " (" + str(damage_per_hit) + " x2)",
		"damage": total_damage,
		"damage_per_hit": damage_per_hit,
		"hits": 2,
		"damage_type": damage_type
	}

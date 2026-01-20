# res://Scripts/Abilities/EnemyPoisonStrike.gd
extends EnemyAbility

func _init():
	id = "poison_strike"
	name = "Ядовитый удар"
	description = "Наносит ядовитый урон = Ловкость * 2.5. Также накладывает стак яда. Каждый стак яда наносит 10 ядовитого урона. Максимум 3 стака."
	damage_type = "poison"
	base_damage = 0
	stamina_cost = 25

func use_ability(owner: Node, target: Node) -> Dictionary:
	"""Использует способность"""
	if not can_use(owner):
		return {"success": false, "message": "Недостаточно ресурсов для использования способности"}
	
	# Тратим ресурсы
	if mp_cost > 0:
		owner.mp = max(0, owner.mp - mp_cost)
	if stamina_cost > 0:
		owner.stamina = max(0, owner.stamina - stamina_cost)
	
	# Получаем ловкость владельца
	var agility = owner.agility if "agility" in owner else 0
	
	# Рассчитываем урон: ловкость * 2.5
	var damage = int(agility * 2.5)
	
	# Проверяем критический удар
	var is_crit = randf() < (get_crit_chance(owner) / 100.0)
	
	if is_crit:
		damage = int(damage * 1.5)  # Критический урон
	
	# Накладываем стак яда на цель
	var poison_applied = false
	if target and target.has_method("add_effect"):
		# Проверяем, есть ли уже яд
		if target.has_effect("poison"):
			var existing_effect = target.effects["poison"]
			var current_stacks = existing_effect.get("stacks", 1)
			
			# Увеличиваем стаки (максимум 3)
			if current_stacks < 3:
				target.add_effect("poison", 5.0, current_stacks + 1, {"damage_per_turn": 10})
				poison_applied = true
		else:
			# Накладываем первый стак яда
			target.add_effect("poison", 5.0, 1, {"damage_per_turn": 10})
			poison_applied = true
	
	return {
		"success": true,
		"damage": damage,
		"is_crit": is_crit,
		"damage_type": damage_type,
		"message": owner.display_name + " использует " + name + "!",
		"poison_applied": poison_applied
	}

# res://Scripts/Abilities/SlimeAbility.gd
extends Node

var id: String = "slime_acid_blast"
var name: String = "Кислотный взрыв"
var description: String = "Мощная кислотная атака с шансом отравления"
var stamina_cost: int = 30
var damage_type: String = "physical"

func execute_ability(owner: Node, target: Node = null) -> Dictionary:
	if not target:
		return {"success": false, "message": "Нет цели для кислотного взрыва"}
	
	# Проверяем, достаточно ли выносливости
	if owner.current_stamina < stamina_cost:
		return {"success": false, "message": "Недостаточно выносливости для кислотного взрыва"}
	
	# Тратим выносливость
	owner.current_stamina -= stamina_cost
	
	# Рассчитываем урон: сила + витальность (слизень использует живучесть для атаки)
	var damage = owner.strength + owner.vitality
	
	# Наносим урон цели
	if target.has_method("take_damage"):
		var actual_damage = target.take_damage(damage, damage_type)
		
		# Шанс отравления (20%)
		var poison_chance = 20.0
		var poison_applied = false
		if randf() * 100 < poison_chance:
			poison_applied = true
			# Здесь можно добавить логику отравления
		
		var message = owner.display_name + " выпускает кислотный взрыв на " + target.display_name + " на " + str(actual_damage) + " урона!"
		if poison_applied:
			message += " Цель отравлена!"
		
		return {
			"success": true,
			"message": message,
			"damage": actual_damage,
			"stamina_cost": stamina_cost,
			"ability": "slime_acid_blast",
			"poison_applied": poison_applied
		}
	
	return {"success": false, "message": "Цель не может получить урон"}

# res://Scripts/Abilities/RatBite.gd
extends Node

var id: String = "rat_bite"
var name: String = "Крысиный укус"
var description: String = "Быстрая атака с уроном равным силе + ловкость"
var stamina_cost: int = 25
var damage_type: String = "physical"

func execute_ability(owner: Node, target: Node = null) -> Dictionary:
	if not target:
		return {"success": false, "message": "Нет цели для укуса"}
	
	# Проверяем, достаточно ли выносливости
	if owner.current_stamina < stamina_cost:
		return {"success": false, "message": "Недостаточно выносливости для крысиного укуса"}
	
	# Тратим выносливость
	owner.current_stamina -= stamina_cost
	
	# Рассчитываем урон: сила + ловкость + бонус физического урона
	var physical_bonus = 0
	if owner.has_method("get_physical_damage_bonus"):
		physical_bonus = owner.get_physical_damage_bonus()
	elif "physical_damage_bonus" in owner:
		physical_bonus = owner.physical_damage_bonus
		
	# Формула: (Сила + Ловкость + P) * 1.5
	var base_damage = owner.strength + owner.agility + physical_bonus
	var damage = int(base_damage * 1.5)
	
	# Воспроизводим звук укуса
	if SoundManager:
		SoundManager.play_sound("rat_bite", -10.0)  # Громкость -10 dB
	
	# Наносим урон цели
	if target.has_method("take_damage"):
		var actual_damage = target.take_damage(damage)
		
		return {
			"success": true,
			"message": owner.display_name + " кусает " + target.display_name + " на " + str(actual_damage) + " урона!",
			"damage": actual_damage,
			"stamina_cost": stamina_cost,
			"ability": "rat_bite"
		}
	
	return {"success": false, "message": "Цель не может получить урон"}

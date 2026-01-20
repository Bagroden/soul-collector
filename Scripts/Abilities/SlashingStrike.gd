# res://Scripts/Abilities/SlashingStrike.gd
extends Node

var id: String = "slashing_strike"
var name: String = "Рубящий удар"
var description: String = "Быстрая атака мечом с возможностью контратаки при блокировании"
var stamina_cost: int = 35
var damage_type: String = "physical"
var cooldown: int = 1

func execute_ability(owner: Node, target: Node = null) -> Dictionary:
	if not target:
		return {"success": false, "message": "Нет цели для удара"}
	
	# Проверяем, достаточно ли выносливости
	if owner.current_stamina < stamina_cost:
		return {"success": false, "message": "Недостаточно выносливости для рубящего удара"}
	
	# Тратим выносливость
	owner.current_stamina -= stamina_cost
	
	# Рассчитываем урон: сила + ловкость * 1.2 + P
	var physical_bonus = 0
	if owner.has_method("get_physical_damage_bonus"):
		physical_bonus = owner.get_physical_damage_bonus()
	elif "physical_damage_bonus" in owner:
		physical_bonus = owner.physical_damage_bonus
		
	var base_damage = owner.strength + (owner.agility * 1.2) + physical_bonus
	
	# Проверяем стаки "Танца смерти" (пассивка)
	var dance_stacks = owner.get_meta("death_dance_stacks", 0)
	var dance_bonus = 0.0
	if dance_stacks > 0:
		# Каждый стак дает +10-25% урона (зависит от уровня)
		dance_bonus = dance_stacks * 15.0  # Средний бонус
	
	# Применяем бонус от танца
	var damage = base_damage * (1.0 + dance_bonus / 100.0)
	
	# Добавляем стак "Танца смерти" после атаки
	if dance_stacks < 3:
		owner.set_meta("death_dance_stacks", dance_stacks + 1)
		owner.set_meta("death_dance_duration", 3)
	
	# Воспроизводим звук удара мечом
	if SoundManager:
		SoundManager.play_sound("sword_slash", -8.0)
	
	# Наносим урон цели
	if target.has_method("take_damage"):
		var actual_damage = target.take_damage(int(damage), damage_type)
		
		return {
			"success": true,
			"message": owner.display_name + " наносит рубящий удар по " + target.display_name + " на " + str(actual_damage) + " урона!",
			"damage": actual_damage,
			"stamina_cost": stamina_cost,
			"ability": "slashing_strike",
			"cooldown": cooldown
		}
	
	return {"success": false, "message": "Цель не может получить урон"}


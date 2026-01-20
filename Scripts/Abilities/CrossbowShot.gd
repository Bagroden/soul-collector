# res://Scripts/Abilities/CrossbowShot.gd
extends Node

var id: String = "crossbow_shot"
var name: String = "Арбалетный выстрел"
var description: String = "Точный выстрел из арбалета с высоким уроном и шансом крита"
var stamina_cost: int = 40
var damage_type: String = "physical"
var cooldown: int = 2

func execute_ability(owner: Node, target: Node = null) -> Dictionary:
	if not target:
		return {"success": false, "message": "Нет цели для выстрела"}
	
	# Проверяем, достаточно ли выносливости
	if owner.current_stamina < stamina_cost:
		return {"success": false, "message": "Недостаточно выносливости для арбалетного выстрела"}
	
	# Тратим выносливость
	owner.current_stamina -= stamina_cost
	
	# Рассчитываем урон: сила + ловкость * 1.8
	var base_damage = owner.strength + (owner.agility * 1.8)
	
	# Бонус крита +15%
	var crit_bonus = 15.0
	
	# Проверяем накопленную концентрацию (пассивка "Нежить фокус")
	var focus_stacks = owner.get_meta("undead_focus_stacks", 0)
	var focus_bonus = 0.0
	if focus_stacks > 0:
		# Предполагаем, что каждый стак дает +5-12% урона (зависит от уровня)
		focus_bonus = focus_stacks * 8.0  # Средний бонус
	
	# Применяем бонус от концентрации
	var damage = base_damage * (1.0 + focus_bonus / 100.0)
	
	# Воспроизводим звук выстрела
	if SoundManager:
		SoundManager.play_sound("crossbow_shot", -8.0)
	
	# Наносим урон цели
	if target.has_method("take_damage"):
		var actual_damage = target.take_damage(int(damage), damage_type)
		
		return {
			"success": true,
			"message": owner.display_name + " выпускает болт в " + target.display_name + " на " + str(actual_damage) + " урона!",
			"damage": actual_damage,
			"stamina_cost": stamina_cost,
			"ability": "crossbow_shot",
			"crit_bonus": crit_bonus,
			"cooldown": cooldown
		}
	
	return {"success": false, "message": "Цель не может получить урон"}


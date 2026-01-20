# res://Scripts/Abilities/RendingClaws.gd
extends Node

var id: String = "rending_claws"
var name: String = "Разрывающие когти"
var description: String = "Атака когтями с шансом наложить кровотечение и вампиризмом"
var stamina_cost: int = 30
var damage_type: String = "physical"
var cooldown: int = 2

func execute_ability(owner: Node, target: Node = null) -> Dictionary:
	if not target:
		return {"success": false, "message": "Нет цели для атаки"}
	
	# Проверяем, достаточно ли выносливости
	if owner.current_stamina < stamina_cost:
		return {"success": false, "message": "Недостаточно выносливости для атаки когтями"}
	
	# Тратим выносливость
	owner.current_stamina -= stamina_cost
	
	# Рассчитываем урон: сила * 1.5 + живучесть + P
	var physical_bonus = 0
	if owner.has_method("get_physical_damage_bonus"):
		physical_bonus = owner.get_physical_damage_bonus()
	elif "physical_damage_bonus" in owner:
		physical_bonus = owner.physical_damage_bonus
		
	var base_damage = (owner.strength * 1.5) + owner.vitality + physical_bonus
	
	# Проверяем бонус от "Пожирателя трупов"
	var corpse_eater_duration = owner.get_meta("corpse_eater_duration", 0)
	var corpse_eater_bonus = 0.0
	if corpse_eater_duration > 0:
		corpse_eater_bonus = owner.get_meta("corpse_eater_damage_bonus", 0.0)
	
	# Применяем бонус
	var damage = base_damage * (1.0 + corpse_eater_bonus / 100.0)
	
	# Воспроизводим звук атаки когтями
	if SoundManager:
		SoundManager.play_sound("claw_attack", -8.0)
	
	# Наносим урон цели
	if target.has_method("take_damage"):
		var actual_damage = target.take_damage(int(damage), damage_type)
		
		# Вампиризм 30%
		var vampirism_heal = int(actual_damage * 0.3)
		if vampirism_heal > 0 and owner.has_method("heal"):
			var old_hp = owner.hp
			owner.heal(vampirism_heal)
			var actual_heal = owner.hp - old_hp
			
			# Показываем зеленую цифру лечения
			var battle_manager = owner.get_node_or_null("/root/BattleScene")
			if battle_manager and battle_manager.has_method("get_damage_number_manager"):
				var damage_number_manager = battle_manager.get_damage_number_manager()
				if damage_number_manager:
					damage_number_manager.show_damage_on_character(owner, actual_heal, false, Color(0, 1, 0))
		
		# 40% шанс наложить кровотечение
		var bleeding_chance = 40.0
		var roll = randf() * 100.0
		var bleeding_applied = false
		
		if roll <= bleeding_chance:
			# Накладываем кровотечение (2% от макс HP за ход, 3 хода)
			if target.has_method("apply_status_effect"):
				target.apply_status_effect("bleeding", 3, 2.0)
				bleeding_applied = true
		
		var message = owner.display_name + " разрывает когтями " + target.display_name + " на " + str(actual_damage) + " урона!"
		if vampirism_heal > 0:
			message += " (Восстановлено " + str(vampirism_heal) + " HP)"
		if bleeding_applied:
			message += " [КРОВОТЕЧЕНИЕ]"
		
		return {
			"success": true,
			"message": message,
			"damage": actual_damage,
			"vampirism_heal": vampirism_heal,
			"bleeding_applied": bleeding_applied,
			"stamina_cost": stamina_cost,
			"ability": "rending_claws",
			"cooldown": cooldown
		}
	
	return {"success": false, "message": "Цель не может получить урон"}


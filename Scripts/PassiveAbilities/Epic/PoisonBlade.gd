# res://Scripts/PassiveAbilities/Common/PoisonBlade.gd
extends PassiveAbility

func _init():
	id = "poison_blade"
	name = "Отравленный клинок"
	description = "Шанс наложить яд при атаке"
	rarity = "common"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	# Значения для каждого уровня: % шанс наложить яд
	level_values = [25.0, 35.0, 50.0]  # 25%/35%/50% шанс
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var proc_chance = get_value_for_level(current_level)
	
	var roll = randf() * 100.0
	
	if roll <= proc_chance and target:
		# Накладываем яд на цель
		if target.has_method("add_effect"):
			var poison_stacks = 1
			var poison_duration = 3.0
			
			# Проверяем, есть ли уже яд
			if target.has_effect("poison"):
				var existing_poison = target.get_effect("poison")
				var current_stacks = existing_poison.get("stacks", 0)
				poison_stacks = min(current_stacks + 1, 3)  # Максимум 3 стака
			
			target.add_effect("poison", poison_duration, poison_stacks, {"damage_per_turn": 10})
			
			return {
				"success": true,
				"message": target.display_name + " отравлен!",
				"effect": "poison",
				"stacks": poison_stacks
			}
	
	return {"success": false}


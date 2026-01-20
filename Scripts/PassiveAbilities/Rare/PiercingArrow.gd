# res://Scripts/PassiveAbilities/Rare/PiercingArrow.gd
extends PassiveAbility

func _init():
	id = "piercing_arrow"
	name = "Пробивающая стрела"
	description = "Шанс игнорировать часть защиты цели"
	rarity = "rare"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	# Значения для каждого уровня: % игнорирования защиты
	level_values = [35.0, 55.0, 75.0]  # 35%/55%/75% игнорирования защиты
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var armor_ignore_percent = get_value_for_level(current_level)
	
	# 30% шанс срабатывания
	var proc_chance = 30.0
	var roll = randf() * 100.0
	
	if roll <= proc_chance and target:
		# Отмечаем, что следующая атака игнорирует часть брони
		if not owner.has_meta("piercing_arrow_active"):
			owner.set_meta("piercing_arrow_active", true)
			owner.set_meta("piercing_arrow_ignore_percent", armor_ignore_percent)
			
			return {
				"success": true,
				"message": owner.display_name + " готовит пробивающую стрелу!",
				"armor_ignore": armor_ignore_percent,
				"effect": "piercing_arrow"
			}
	
	return {"success": false}


# res://Scripts/PassiveAbilities/Rare/PiercingBolt.gd
extends PassiveAbility

func _init():
	id = "piercing_bolt"
	name = "Пробивающий болт"
	description = "Шанс игнорировать часть защиты цели"
	rarity = "rare"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	# Значения для каждого уровня: % игнорирования защиты
	level_values = [30.0, 50.0, 70.0]  # 30%/50%/70% игнорирования защиты
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var armor_ignore_percent = get_value_for_level(current_level)
	
	# 25% шанс срабатывания
	var proc_chance = 25.0
	var roll = randf() * 100.0
	
	if roll <= proc_chance and target:
		# Отмечаем, что следующая атака игнорирует часть брони
		if not owner.has_meta("piercing_bolt_active"):
			owner.set_meta("piercing_bolt_active", true)
			owner.set_meta("piercing_bolt_ignore_percent", armor_ignore_percent)
			
			return {
				"success": true,
				"message": owner.display_name + " готовит пробивающий болт!",
				"armor_ignore": armor_ignore_percent,
				"effect": "piercing_bolt"
			}
	
	return {"success": false}


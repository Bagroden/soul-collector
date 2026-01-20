# res://Scripts/PassiveAbilities/Common/GhoulFeast.gd
extends PassiveAbility

func _init():
	id = "ghoul_feast"
	name = "Пир гуля"
	description = "Восстанавливает HP при нанесении урона (вампиризм)"
	rarity = "common"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	# Значения для каждого уровня: % вампиризма
	level_values = [15.0, 25.0, 40.0]  # 15%/25%/40% вампиризм
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var vampirism_percent = get_value_for_level(current_level)
	
	# Получаем нанесенный урон из контекста
	var dealt_damage = _context.get("damage_dealt", 0)
	
	if dealt_damage > 0:
		# Рассчитываем исцеление
		var heal_amount = int(dealt_damage * vampirism_percent / 100.0)
		
		if heal_amount > 0 and owner.has_method("heal"):
			var old_hp = owner.hp
			owner.heal(heal_amount)
			var actual_heal = owner.hp - old_hp
			
			return {
				"success": true,
				"message": owner.display_name + " восстанавливает " + str(actual_heal) + " HP через вампиризм!",
				"heal_amount": actual_heal,
				"vampirism_percent": vampirism_percent,
				"effect": "ghoul_feast"
			}
	
	return {"success": false}


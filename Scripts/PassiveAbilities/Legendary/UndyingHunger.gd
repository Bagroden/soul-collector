# res://Scripts/PassiveAbilities/Legendary/UndyingHunger.gd
extends PassiveAbility

func _init():
	id = "undying_hunger"
	name = "Неугасимый голод"
	description = "При получении смертельного урона восстанавливает HP. Срабатывает один раз за бой."
	rarity = "legendary"
	ability_type = AbilityType.SPECIAL
	trigger_type = TriggerType.ON_DEATH
	# Значения для каждого уровня: % восстановления HP
	level_values = [25.0, 40.0, 60.0]  # 25%/40%/60% от макс HP
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var heal_percent = get_value_for_level(current_level)
	
	# Проверяем, не использовалась ли способность в этом бою
	var already_used = owner.get_meta("undying_hunger_used", false)
	
	if not already_used and owner.hp <= 0:
		# Рассчитываем исцеление
		var heal_amount = int(owner.max_hp * heal_percent / 100.0)
		
		# Восстанавливаем HP
		owner.hp = heal_amount
		owner.set_meta("undying_hunger_used", true)
		
		return {
			"success": true,
			"message": owner.display_name + " отказывается умирать! Неугасимый голод восстанавливает " + str(heal_amount) + " HP!",
			"heal_amount": heal_amount,
			"revived": true,
			"effect": "undying_hunger"
		}
	
	return {"success": false}


# res://Scripts/PassiveAbilities/Uncommon/HeavyStrike.gd
extends PassiveAbility

func _init():
	id = "heavy_strike"
	name = "Тяжелый удар"
	description = "Шанс нанести дополнительный урон и снизить защиту цели"
	rarity = "uncommon"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	# Бонус урона для каждого уровня
	level_values = [30.0, 50.0, 75.0]
	value = 30.0  # Значение по умолчанию (1 уровень)

# Снижение защиты для каждого уровня
var armor_debuffs = [3, 5, 8]
# Длительность для каждого уровня
var durations = [2, 3, 4]

func execute_ability(owner: Node, target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var damage_bonus = get_value_for_level(current_level)
	var armor_debuff = armor_debuffs[current_level - 1]
	var debuff_duration = durations[current_level - 1]
	
	# 25% шанс срабатывания
	var proc_chance = 25.0
	var roll = randf() * 100.0
	
	if roll <= proc_chance and target:
		# Сохраняем бонус урона для этой атаки
		owner.set_meta("heavy_strike_damage_bonus", damage_bonus)
		
		# Применяем дебафф защиты к цели
		if target:
			target.set_meta("heavy_strike_armor_debuff", armor_debuff)
			target.set_meta("heavy_strike_duration", debuff_duration)
			
			return {
				"success": true,
				"message": owner.display_name + " наносит Тяжелый удар! (+" + str(int(damage_bonus)) + "% урон, -" + str(armor_debuff) + " защиты на " + str(debuff_duration) + " раунда)",
				"damage_bonus": damage_bonus,
				"armor_debuff": armor_debuff,
				"duration": debuff_duration,
				"effect": "heavy_strike"
			}
	
	return {"success": false}

# res://Scripts/PassiveAbilities/Uncommon/RottingClaws.gd
extends PassiveAbility

func _init():
	id = "rotting_claws"
	name = "Гнилые когти"
	description = "Шанс наложить дебаф 'Трупный яд' на противника. Трупный яд снижает меткость и скорость цели. Максимум 3 стака."
	rarity = "uncommon"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	# Шанс срабатывания для каждого уровня
	level_values = [30.0, 40.0, 50.0]
	value = 30.0  # Значение по умолчанию (1 уровень, шанс)

# Дебаффы для каждого уровня
var accuracy_debuffs = [5.0, 8.0, 12.0]
var speed_debuffs = [5.0, 8.0, 12.0]
var durations = [3, 4, 5]

func execute_ability(_owner: Node, target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var proc_chance = get_value_for_level(current_level)
	var accuracy_debuff = accuracy_debuffs[current_level - 1]
	var speed_debuff = speed_debuffs[current_level - 1]
	var poison_duration = durations[current_level - 1]
	
	# Проверяем шанс срабатывания
	var roll = randf() * 100.0
	
	if roll <= proc_chance and target:
		# Получаем текущее количество стаков
		var corpse_poison_stacks = target.get_meta("corpse_poison_stacks", 0)
		
		# Максимум 3 стака
		if corpse_poison_stacks < 3:
			corpse_poison_stacks += 1
			target.set_meta("corpse_poison_stacks", corpse_poison_stacks)
			target.set_meta("corpse_poison_duration", poison_duration)
			target.set_meta("corpse_poison_accuracy_debuff", accuracy_debuff)
			target.set_meta("corpse_poison_speed_debuff", speed_debuff)
			
			var total_accuracy_debuff = accuracy_debuff * corpse_poison_stacks
			var total_speed_debuff = speed_debuff * corpse_poison_stacks
			
			return {
				"success": true,
				"message": target.display_name + " заражен Трупным ядом! (Стак " + str(corpse_poison_stacks) + "/3, -" + str(int(total_accuracy_debuff)) + "% меткость, -" + str(int(total_speed_debuff)) + "% скорость)",
				"poison_stacks": corpse_poison_stacks,
				"accuracy_debuff": total_accuracy_debuff,
				"speed_debuff": total_speed_debuff,
				"duration": poison_duration,
				"effect": "rotting_claws"
			}
		else:
			# Обновляем длительность
			target.set_meta("corpse_poison_duration", poison_duration)
			return {
				"success": true,
				"message": target.display_name + " страдает от максимального Трупного яда! (3/3 стака)",
				"poison_stacks": 3
			}
	
	return {"success": false}

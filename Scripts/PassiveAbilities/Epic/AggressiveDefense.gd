# res://Scripts/PassiveAbilities/Epic/AggressiveDefense.gd
extends PassiveAbility

func _init():
	id = "aggressive_defense"
	name = "Агрессивная защита"
	description = "После успешного парирования или блокирования получает стак 'Импульса' на 3 раунда. Каждый стак увеличивает скорость и шанс крита. Максимум 5 стаков."
	rarity = "epic"
	ability_type = AbilityType.UTILITY
	trigger_type = TriggerType.ON_DAMAGE_TAKEN
	# Бонус скорости за стак (одинаковый для всех уровней)
	level_values = [5.0, 5.0, 5.0]
	value = 5.0  # Значение по умолчанию (1 уровень)

# Бонус крита за стак (одинаковый для всех уровней)
var crit_per_stack = 3.0

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var speed_per_stack = get_value_for_level(current_level)
	# crit_per_stack уже определен выше
	
	# Проверяем, был ли блок
	var was_blocked = owner.get_meta("bone_parry_triggered", false)
	
	if was_blocked:
		# Получаем текущее количество стаков
		var impulse_stacks = owner.get_meta("impulse_stacks", 0)
		var impulse_duration = 3  # 3 раунда
		
		# Максимум 5 стаков
		if impulse_stacks < 5:
			impulse_stacks += 1
			owner.set_meta("impulse_stacks", impulse_stacks)
			owner.set_meta("impulse_duration", impulse_duration)
			
			var total_speed = speed_per_stack * impulse_stacks
			var total_crit = crit_per_stack * impulse_stacks
			
			return {
				"success": true,
				"message": owner.display_name + " получает Импульс! (Стак " + str(impulse_stacks) + "/5, +" + str(int(total_speed)) + "% скорость, +" + str(int(total_crit)) + "% крит)",
				"impulse_stacks": impulse_stacks,
				"speed_bonus": total_speed,
				"crit_bonus": total_crit,
				"effect": "aggressive_defense"
			}
		else:
			# Обновляем длительность на максимальных стаках
			owner.set_meta("impulse_duration", impulse_duration)
			return {
				"success": true,
				"message": owner.display_name + " поддерживает максимальный Импульс! (5/5 стаков)",
				"impulse_stacks": 5
			}
	
	return {"success": false}

func get_stat_modifier(stat_name: String, current_level: int, owner: Node = null) -> float:
	if owner:
		var impulse_stacks = owner.get_meta("impulse_stacks", 0)
		
		if stat_name == "speed":
			return get_value_for_level(current_level) * impulse_stacks
		elif stat_name == "crit_chance":
			return crit_per_stack * impulse_stacks
	return 0.0


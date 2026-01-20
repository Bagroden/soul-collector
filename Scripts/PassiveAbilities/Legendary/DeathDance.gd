# res://Scripts/PassiveAbilities/Legendary/DeathDance.gd
extends PassiveAbility

func _init():
	id = "death_dance"
	name = "Танец смерти"
	description = "После каждой атаки получает стак 'Танца' на 3 раунда. Каждый стак увеличивает урон и шанс уворота. Максимум 3 стака."
	rarity = "legendary"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	# Бонус урона за стак для каждого уровня
	level_values = [10.0, 15.0, 25.0]
	value = 10.0  # Значение по умолчанию (1 уровень)

# Бонус уворота за стак для каждого уровня
var dodge_bonuses = [5.0, 8.0, 12.0]

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var damage_per_stack = get_value_for_level(current_level)
	var dodge_per_stack = dodge_bonuses[current_level - 1]
	
	# Получаем текущее количество стаков танца
	var dance_stacks = owner.get_meta("death_dance_stacks", 0)
	var dance_duration = 3  # 3 раунда
	
	# Максимум 3 стака
	if dance_stacks < 3:
		dance_stacks += 1
		owner.set_meta("death_dance_stacks", dance_stacks)
		owner.set_meta("death_dance_duration", dance_duration)
		
		var total_damage = damage_per_stack * dance_stacks
		var total_dodge = dodge_per_stack * dance_stacks
		
		return {
			"success": true,
			"message": owner.display_name + " входит в Танец смерти! (Стак " + str(dance_stacks) + "/3, +" + str(int(total_damage)) + "% урон, +" + str(int(total_dodge)) + "% уворот)",
			"dance_stacks": dance_stacks,
			"damage_bonus": total_damage,
			"dodge_bonus": total_dodge,
			"effect": "death_dance"
		}
	else:
		# Обновляем длительность на максимальных стаках
		owner.set_meta("death_dance_duration", dance_duration)
		return {
			"success": true,
			"message": owner.display_name + " танцует на грани жизни и смерти! (3/3 стака)",
			"dance_stacks": 3
		}

func get_stat_modifier(stat_name: String, current_level: int, owner: Node = null) -> float:
	if owner:
		var dance_stacks = owner.get_meta("death_dance_stacks", 0)
		
		if stat_name == "damage_percent":
			return get_value_for_level(current_level) * dance_stacks
		elif stat_name == "dodge_chance":
			return dodge_bonuses[current_level - 1] * dance_stacks
	return 0.0


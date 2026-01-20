# res://Scripts/PassiveAbilities/Epic/PlagueCarrier.gd
extends PassiveAbility

func _init():
	id = "plague_carrier"
	name = "Носитель чумы"
	description = "Накладывает стак 'Чумы' на противника каждый ход. Чума снижает максимальное HP на 2% за стак. Максимум 5 стаков."
	rarity = "epic"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_TURN_START
	# Значения для каждого уровня: % снижения макс HP за стак
	level_values = [2.0, 3.0, 5.0]  # 2%/3%/5% за стак
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var hp_reduction_per_stack = get_value_for_level(current_level)
	
	# Получаем цель из контекста (игрок в бою)
	var battle_manager = owner.get_node_or_null("/root/BattleScene")
	if battle_manager:
		var player = battle_manager.get_node_or_null("Player")
		if player:
			# Получаем текущее количество стаков чумы
			var plague_stacks = player.get_meta("plague_stacks", 0)
			
			# Максимум 5 стаков
			if plague_stacks < 5:
				plague_stacks += 1
				player.set_meta("plague_stacks", plague_stacks)
				player.set_meta("plague_hp_reduction_per_stack", hp_reduction_per_stack)
				
				var total_hp_reduction = hp_reduction_per_stack * plague_stacks
				
				return {
					"success": true,
					"message": player.display_name + " заражен Чумой! (Стак " + str(plague_stacks) + "/5, -" + str(int(total_hp_reduction)) + "% макс. HP)",
					"plague_stacks": plague_stacks,
					"hp_reduction": total_hp_reduction,
					"effect": "plague_carrier"
				}
			else:
				return {
					"success": true,
					"message": player.display_name + " страдает от максимальной Чумы! (5/5 стаков)",
					"plague_stacks": 5
				}
	
	return {"success": false}

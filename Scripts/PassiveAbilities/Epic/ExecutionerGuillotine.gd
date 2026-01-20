# res://Scripts/PassiveAbilities/Epic/ExecutionerGuillotine.gd
extends PassiveAbility

var critical_multiplier: float = 3.0

func _init():
	id = "executioner_guillotine"
	name = "Гильотина палача"
	description = "Увеличивает критический урон в 3 раза"
	rarity = "epic"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.PASSIVE  # Постоянная способность
	value = 3.0  # Множитель критического урона

func execute_ability(_owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Гильотина - постоянная способность, не срабатывает как отдельная
	# Все параметры помечены как неиспользуемые с префиксом _
	return {"success": false, "message": "Гильотина - постоянная способность"}

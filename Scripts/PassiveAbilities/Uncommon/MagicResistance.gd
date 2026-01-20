# res://Scripts/PassiveAbilities/Uncommon/MagicResistance.gd
extends PassiveAbility

func _init():
	id = "magic_resistance"
	name = "Сопротивление магии"
	description = "Получает X% сопротивление магии"
	rarity = "uncommon"
	ability_type = AbilityType.DEFENSIVE
	trigger_type = TriggerType.PASSIVE
	level_values = [7.0, 15.0, 25.0]  # Процент сопротивления магии

func execute_ability(_owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	"""Увеличивает процентное сопротивление магии владельца"""
	if not _owner or not "magic_resistance_percent" in _owner:
		return {"success": false, "message": "Нет владельца или магического сопротивления"}
	
	var ability_level = _owner.ability_levels.get(id, 1)
	var resistance_percentage = get_value_for_level(ability_level)
	
	# Увеличиваем процентное сопротивление магии
	_owner.magic_resistance_percent += resistance_percentage
	
	return {
		"success": true,
		"resistance_percentage": resistance_percentage,
		"message": _owner.display_name + " получает +" + str(resistance_percentage) + "% сопротивление магии!"
	}

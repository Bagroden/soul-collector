# res://Scripts/PassiveAbilities/Common/Apprentice.gd
extends PassiveAbility

func _init():
	id = "apprentice"
	name = "Ученик"
	description = "Получает X к запасу маны"
	rarity = "common"
	ability_type = AbilityType.UTILITY
	trigger_type = TriggerType.PASSIVE
	level_values = [30.0, 60.0, 100.0]  # Бонус к мане

func execute_ability(_owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	"""Увеличивает максимальную ману владельца"""
	if not _owner or not "max_mp" in _owner:
		return {"success": false, "message": "Нет владельца или маны"}
	
	var ability_level = _owner.ability_levels.get(id, 1)
	var mana_bonus = int(get_value_for_level(ability_level))
	
	# Увеличиваем максимальную ману
	_owner.max_mp += mana_bonus
	# Восстанавливаем ману до максимума
	_owner.mp = _owner.max_mp
	
	return {
		"success": true,
		"mana_bonus": mana_bonus,
		"message": _owner.display_name + " получает +" + str(mana_bonus) + " к мане!"
	}

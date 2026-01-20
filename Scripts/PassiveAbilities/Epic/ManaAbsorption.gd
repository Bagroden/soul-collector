# res://Scripts/PassiveAbilities/Epic/ManaAbsorption.gd
extends PassiveAbility

func _init():
	id = "mana_absorption"
	name = "Поглощение маны"
	description = "X% от нанесенного магического или физического урона преобразуется в ману"
	rarity = "epic"
	ability_type = AbilityType.UTILITY
	trigger_type = TriggerType.ON_ATTACK
	level_values = [5.0, 10.0, 15.0]  # Процент поглощения урона в ману

func execute_ability(_owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	"""Преобразует часть нанесенного урона в ману"""
	if not _owner or not "mp" in _owner or not "max_mp" in _owner:
		return {"success": false, "message": "Нет владельца или маны"}
	
	var ability_level = _owner.ability_levels.get(id, 1)
	var absorption_percentage = get_value_for_level(ability_level)
	
	# Получаем нанесенный урон из контекста
	var damage = _context.get("damage", 0)
	
	if damage <= 0:
		return {"success": false, "message": "Нет урона для поглощения"}
	
	# Рассчитываем количество маны для восстановления
	var mana_restored = int(damage * (absorption_percentage / 100.0))
	
	# Восстанавливаем ману
	_owner.mp = min(_owner.mp + mana_restored, _owner.max_mp)
	
	return {
		"success": true,
		"mana_restored": mana_restored,
		"message": _owner.display_name + " поглощает " + str(mana_restored) + " маны из нанесенного урона!"
	}

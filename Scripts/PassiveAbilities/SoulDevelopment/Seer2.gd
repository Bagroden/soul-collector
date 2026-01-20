# res://Scripts/PassiveAbilities/SoulDevelopment/Seer2.gd
extends PassiveAbility

func _init():
	id = "seer_2"
	name = "Видящий II"
	description = "Позволяет видеть редкость комнаты и количество врагов."
	rarity = "uncommon"
	ability_type = AbilityType.UTILITY
	trigger_type = TriggerType.PASSIVE
	value = 2.0  # Уровень способности
	level_values = [2.0]
	tags = ["soul", "seer", "utility", "vision"]

func execute_ability(_owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	"""Способность пассивная, не требует выполнения"""
	return {
		"success": true,
		"message": "Видящий II активирован - видно редкость комнаты и количество врагов"
	}


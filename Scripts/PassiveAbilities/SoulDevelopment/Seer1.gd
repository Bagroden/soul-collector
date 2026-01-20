# res://Scripts/PassiveAbilities/SoulDevelopment/Seer1.gd
extends PassiveAbility

func _init():
	id = "seer_1"
	name = "Видящий I"
	description = "Позволяет видеть количество врагов в комнате."
	rarity = "common"
	ability_type = AbilityType.UTILITY
	trigger_type = TriggerType.PASSIVE
	value = 1.0  # Уровень способности
	level_values = [1.0]
	tags = ["soul", "seer", "utility", "vision"]

func execute_ability(_owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	"""Способность пассивная, не требует выполнения"""
	return {
		"success": true,
		"message": "Видящий I активирован - видно количество врагов в комнате"
	}


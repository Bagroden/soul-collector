# res://Scripts/PassiveAbilities/SoulDevelopment/Seer3.gd
extends PassiveAbility

func _init():
	id = "seer_3"
	name = "Видящий III"
	description = "Позволяет видеть редкость комнаты, редкость врагов, уровень врагов, имена врагов и элитность."
	rarity = "rare"
	ability_type = AbilityType.UTILITY
	trigger_type = TriggerType.PASSIVE
	value = 3.0  # Уровень способности
	level_values = [3.0]
	tags = ["soul", "seer", "utility", "vision"]

func execute_ability(_owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	"""Способность пассивная, не требует выполнения"""
	return {
		"success": true,
		"message": "Видящий III активирован - видна полная информация о врагах в комнате"
	}


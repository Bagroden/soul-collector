# res://Scripts/PassiveAbilities/SoulDevelopment/RestorationEfficiency1.gd
extends PassiveAbility

func _init():
	id = "soul_restoration_efficiency_1"
	name = "Восстановление души: Эффективность I"
	description = "Увеличивает процент восстановления души до 40%."
	rarity = "common"
	ability_type = AbilityType.UTILITY
	trigger_type = TriggerType.PASSIVE
	value = 5.0  # +5% к базовым 35%
	level_values = [5.0]
	tags = ["soul", "restoration", "efficiency", "utility"]

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	"""Применяет улучшение эффективности восстановления души"""
	var soul_restoration_manager = owner.get_node_or_null("/root/SoulRestorationManager")
	if not soul_restoration_manager:
		return {"success": false, "message": "SoulRestorationManager не найден"}
	
	# Добавляем улучшение эффективности (+5% к базовым 35% = 40%)
	soul_restoration_manager.add_soul_upgrade("efficiency", 0.05)
	
	return {
		"success": true,
		"message": "Эффективность восстановления души увеличена до 40%",
		"efficiency_bonus": 0.05
	}


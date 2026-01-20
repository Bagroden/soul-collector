# res://Scripts/PassiveAbilities/SoulDevelopment/RestorationEfficiency2.gd
extends PassiveAbility

func _init():
	id = "soul_restoration_efficiency_2"
	name = "Восстановление души: Эффективность II"
	description = "Увеличивает процент восстановления души до 45%."
	rarity = "uncommon"
	ability_type = AbilityType.UTILITY
	trigger_type = TriggerType.PASSIVE
	value = 10.0  # +10% к базовым 35%
	level_values = [10.0]
	tags = ["soul", "restoration", "efficiency", "utility"]

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	"""Применяет улучшение эффективности восстановления души"""
	var soul_restoration_manager = owner.get_node_or_null("/root/SoulRestorationManager")
	if not soul_restoration_manager:
		return {"success": false, "message": "SoulRestorationManager не найден"}
	
	# Добавляем улучшение эффективности (+10% к базовым 35% = 45%)
	soul_restoration_manager.add_soul_upgrade("efficiency", 0.10)
	
	return {
		"success": true,
		"message": "Эффективность восстановления души увеличена до 45%",
		"efficiency_bonus": 0.10
	}


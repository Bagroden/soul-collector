# res://Scripts/PassiveAbilities/SoulDevelopment/RestorationEfficiency5.gd
extends PassiveAbility

func _init():
	id = "soul_restoration_efficiency_5"
	name = "Восстановление души: Эффективность V"
	description = "Увеличивает процент восстановления души до 80%."
	rarity = "legendary"
	ability_type = AbilityType.UTILITY
	trigger_type = TriggerType.PASSIVE
	value = 45.0  # +45% к базовым 35%
	level_values = [45.0]
	tags = ["soul", "restoration", "efficiency", "utility"]

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	"""Применяет улучшение эффективности восстановления души"""
	var soul_restoration_manager = owner.get_node_or_null("/root/SoulRestorationManager")
	if not soul_restoration_manager:
		return {"success": false, "message": "SoulRestorationManager не найден"}
	
	# Добавляем улучшение эффективности (+45% к базовым 35% = 80%)
	soul_restoration_manager.add_soul_upgrade("efficiency", 0.45)
	
	return {
		"success": true,
		"message": "Эффективность восстановления души увеличена до 80%",
		"efficiency_bonus": 0.45
	}


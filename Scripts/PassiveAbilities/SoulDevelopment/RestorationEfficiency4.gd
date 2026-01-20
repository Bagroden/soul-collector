# res://Scripts/PassiveAbilities/SoulDevelopment/RestorationEfficiency4.gd
extends PassiveAbility

func _init():
	id = "soul_restoration_efficiency_4"
	name = "Восстановление души: Эффективность IV"
	description = "Увеличивает процент восстановления души до 65%."
	rarity = "epic"
	ability_type = AbilityType.UTILITY
	trigger_type = TriggerType.PASSIVE
	value = 30.0  # +30% к базовым 35%
	level_values = [30.0]
	tags = ["soul", "restoration", "efficiency", "utility"]

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	"""Применяет улучшение эффективности восстановления души"""
	var soul_restoration_manager = owner.get_node_or_null("/root/SoulRestorationManager")
	if not soul_restoration_manager:
		return {"success": false, "message": "SoulRestorationManager не найден"}
	
	# Добавляем улучшение эффективности (+30% к базовым 35% = 65%)
	soul_restoration_manager.add_soul_upgrade("efficiency", 0.30)
	
	return {
		"success": true,
		"message": "Эффективность восстановления души увеличена до 65%",
		"efficiency_bonus": 0.30
	}


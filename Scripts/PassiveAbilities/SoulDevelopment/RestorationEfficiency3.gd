# res://Scripts/PassiveAbilities/SoulDevelopment/RestorationEfficiency3.gd
extends PassiveAbility

func _init():
	id = "soul_restoration_efficiency_3"
	name = "Восстановление души: Эффективность III"
	description = "Увеличивает процент восстановления души до 55%."
	rarity = "rare"
	ability_type = AbilityType.UTILITY
	trigger_type = TriggerType.PASSIVE
	value = 20.0  # +20% к базовым 35%
	level_values = [20.0]
	tags = ["soul", "restoration", "efficiency", "utility"]

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	"""Применяет улучшение эффективности восстановления души"""
	var soul_restoration_manager = owner.get_node_or_null("/root/SoulRestorationManager")
	if not soul_restoration_manager:
		return {"success": false, "message": "SoulRestorationManager не найден"}
	
	# Добавляем улучшение эффективности (+20% к базовым 35% = 55%)
	soul_restoration_manager.add_soul_upgrade("efficiency", 0.20)
	
	return {
		"success": true,
		"message": "Эффективность восстановления души увеличена до 55%",
		"efficiency_bonus": 0.20
	}


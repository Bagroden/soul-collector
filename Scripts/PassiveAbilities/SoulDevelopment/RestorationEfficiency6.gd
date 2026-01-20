# res://Scripts/PassiveAbilities/SoulDevelopment/RestorationEfficiency6.gd
extends PassiveAbility

func _init():
	id = "soul_restoration_efficiency_6"
	name = "Восстановление души: Эффективность VI"
	description = "Увеличивает процент восстановления души до 100%."
	rarity = "mythic"
	ability_type = AbilityType.UTILITY
	trigger_type = TriggerType.PASSIVE
	value = 65.0  # +65% к базовым 35%
	level_values = [65.0]
	tags = ["soul", "restoration", "efficiency", "utility"]

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	"""Применяет улучшение эффективности восстановления души"""
	var soul_restoration_manager = owner.get_node_or_null("/root/SoulRestorationManager")
	if not soul_restoration_manager:
		return {"success": false, "message": "SoulRestorationManager не найден"}
	
	# Добавляем улучшение эффективности (+65% к базовым 35% = 100%)
	soul_restoration_manager.add_soul_upgrade("efficiency", 0.65)
	
	return {
		"success": true,
		"message": "Эффективность восстановления души увеличена до 100%",
		"efficiency_bonus": 0.65
	}


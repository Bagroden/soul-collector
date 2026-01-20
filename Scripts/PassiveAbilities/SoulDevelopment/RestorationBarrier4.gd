# res://Scripts/PassiveAbilities/SoulDevelopment/RestorationBarrier4.gd
extends PassiveAbility

func _init():
	id = "soul_restoration_barrier_4"
	name = "Восстановление души: Защитный барьер IV"
	description = "При использовании восстановления души дарует 160 магического барьера. Если барьер уже есть, добавляет к текущему."
	rarity = "epic"
	ability_type = AbilityType.DEFENSIVE
	trigger_type = TriggerType.PASSIVE
	value = 160.0
	level_values = [160.0]
	tags = ["soul", "restoration", "barrier", "defensive"]

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	"""Добавляет бонус барьера при восстановлении души"""
	var soul_restoration_manager = owner.get_node_or_null("/root/SoulRestorationManager")
	if not soul_restoration_manager:
		return {"success": false, "message": "SoulRestorationManager не найден"}
	
	# Добавляем бонус барьера
	soul_restoration_manager.add_soul_upgrade("barrier", 160)
	
	return {
		"success": true,
		"message": "При восстановлении души теперь дается 160 барьера",
		"barrier_bonus": 160
	}


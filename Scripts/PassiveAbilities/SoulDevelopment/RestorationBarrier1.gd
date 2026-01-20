# res://Scripts/PassiveAbilities/SoulDevelopment/RestorationBarrier1.gd
extends PassiveAbility

func _init():
	id = "soul_restoration_barrier_1"
	name = "Восстановление души: Защитный барьер I"
	description = "При использовании восстановления души дарует 40 магического барьера. Если барьер уже есть, добавляет к текущему."
	rarity = "common"
	ability_type = AbilityType.DEFENSIVE
	trigger_type = TriggerType.PASSIVE
	value = 40.0
	level_values = [40.0]
	tags = ["soul", "restoration", "barrier", "defensive"]

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	"""Добавляет бонус барьера при восстановлении души"""
	var soul_restoration_manager = owner.get_node_or_null("/root/SoulRestorationManager")
	if not soul_restoration_manager:
		return {"success": false, "message": "SoulRestorationManager не найден"}
	
	# Добавляем бонус барьера
	soul_restoration_manager.add_soul_upgrade("barrier", 40)
	
	return {
		"success": true,
		"message": "При восстановлении души теперь дается 40 барьера",
		"barrier_bonus": 40
	}


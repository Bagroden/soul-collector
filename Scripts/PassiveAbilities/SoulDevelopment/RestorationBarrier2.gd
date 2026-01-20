# res://Scripts/PassiveAbilities/SoulDevelopment/RestorationBarrier2.gd
extends PassiveAbility

func _init():
	id = "soul_restoration_barrier_2"
	name = "Восстановление души: Защитный барьер II"
	description = "При использовании восстановления души дарует 80 магического барьера. Если барьер уже есть, добавляет к текущему."
	rarity = "uncommon"
	ability_type = AbilityType.DEFENSIVE
	trigger_type = TriggerType.PASSIVE
	value = 80.0
	level_values = [80.0]
	tags = ["soul", "restoration", "barrier", "defensive"]

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	"""Добавляет бонус барьера при восстановлении души"""
	var soul_restoration_manager = owner.get_node_or_null("/root/SoulRestorationManager")
	if not soul_restoration_manager:
		return {"success": false, "message": "SoulRestorationManager не найден"}
	
	# Добавляем бонус барьера
	soul_restoration_manager.add_soul_upgrade("barrier", 80)
	
	return {
		"success": true,
		"message": "При восстановлении души теперь дается 80 барьера",
		"barrier_bonus": 80
	}


# res://Scripts/PassiveAbilities/SoulDevelopment/RestorationCharges5.gd
extends PassiveAbility

func _init():
	id = "soul_restoration_charges_5"
	name = "Восстановление души: Дополнительный заряд V"
	description = "Увеличивает количество зарядов восстановления души на 1."
	rarity = "legendary"
	ability_type = AbilityType.UTILITY
	trigger_type = TriggerType.PASSIVE
	value = 1.0
	level_values = [1.0]
	tags = ["soul", "restoration", "charges", "utility"]

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	"""Добавляет дополнительный заряд восстановления души"""
	var soul_restoration_manager = owner.get_node_or_null("/root/SoulRestorationManager")
	if not soul_restoration_manager:
		return {"success": false, "message": "SoulRestorationManager не найден"}
	
	# Добавляем +1 заряд
	soul_restoration_manager.add_soul_upgrade("charges", 1)
	
	return {
		"success": true,
		"message": "Добавлен дополнительный заряд восстановления души",
		"charges_bonus": 1
	}


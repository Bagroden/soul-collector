# res://Scripts/PassiveAbilities/SoulDevelopment/SpiritualPower2.gd
extends PassiveAbility

func _init():
	id = "spiritual_power_upgrade_2"
	name = "Духовная мощь II"
	description = "Увеличивает максимальную духовную мощь на 2."
	rarity = "uncommon"
	ability_type = AbilityType.UTILITY
	trigger_type = TriggerType.PASSIVE
	value = 2.0
	level_values = [2.0]
	tags = ["soul", "spiritual_power", "utility"]

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	"""Применяет улучшение к духовной мощи"""
	var player_data = null
	if owner.has_method("get_player_data"):
		player_data = owner.get_player_data()
	elif owner.get_class() == "PlayerData":
		player_data = owner
	else:
		var player_manager = owner.get_node_or_null("/root/PlayerManager")
		if player_manager and player_manager.has_method("get_player_data"):
			player_data = player_manager.get_player_data()
	
	if not player_data:
		return {"success": false, "message": "PlayerData не найден"}
	
	# Увеличиваем максимальную духовную мощь
	player_data.max_spiritual_power += 2
	player_data.spiritual_power += 2
	
	return {
		"success": true,
		"message": "Духовная мощь увеличена на 2",
		"spiritual_power_bonus": 2
	}


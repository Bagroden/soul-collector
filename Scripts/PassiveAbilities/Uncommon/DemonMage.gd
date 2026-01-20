# res://Scripts/PassiveAbilities/Uncommon/DemonMage.gd
extends PassiveAbility

func _init():
	id = "demon_mage"
	name = "Демон колдун"
	description = "Увеличение мудрости и интеллекта на 15"
	rarity = "uncommon"
	ability_type = AbilityType.UTILITY
	trigger_type = TriggerType.PASSIVE
	value = 15.0  # +15 к мудрости и интеллекту

func execute_ability(_owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Постоянный эффект - не срабатывает как отдельная способность
	# Все параметры помечены как неиспользуемые с префиксом _
	return {"success": false, "message": "Демон колдун - постоянная способность"}

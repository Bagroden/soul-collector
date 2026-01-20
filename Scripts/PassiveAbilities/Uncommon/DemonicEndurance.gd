# res://Scripts/PassiveAbilities/Uncommon/DemonicEndurance.gd
extends PassiveAbility

var endurance_restore: int = 15  # Восстановление выносливости за раунд

func _init():
	id = "demonic_endurance"
	name = "Демоническая выносливость"
	description = "Восстановление 15 выносливости за раунд"
	rarity = "uncommon"
	ability_type = AbilityType.UTILITY
	trigger_type = TriggerType.PASSIVE
	value = 15.0  # 15 выносливости за раунд

func execute_ability(_owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Постоянный эффект - не срабатывает как отдельная способность
	# Все параметры помечены как неиспользуемые с префиксом _
	return {"success": false, "message": "Демоническая выносливость - постоянная способность"}

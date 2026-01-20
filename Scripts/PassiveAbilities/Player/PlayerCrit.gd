# res://Scripts/PassiveAbilities/Player/PlayerVitality.gd
extends PassiveAbility

func _init():
	id = "player_vitality"
	name = "Живучесть"
	description = "Увеличивает максимальное здоровье на 50 единиц"
	rarity = "epic"
	ability_type = AbilityType.DEFENSIVE
	trigger_type = TriggerType.PASSIVE
	value = 50.0  # +50 HP
	tags = ["player_ability"]

func execute_ability(_owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Статическая способность - не логируется
	return {"success": false, "message": ""}

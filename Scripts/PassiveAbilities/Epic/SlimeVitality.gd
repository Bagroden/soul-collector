# res://Scripts/PassiveAbilities/Epic/AcidExplosion.gd
extends PassiveAbility

func _init():
	id = "slime_vitality"
	name = "Живучесть слизня"
	description = "Увеличивает здоровье слизня"
	rarity = "epic"
	ability_type = AbilityType.DEFENSIVE
	trigger_type = TriggerType.PASSIVE
	value = 20.0  # Увеличение здоровья на 20%
	level_values = [20.0, 35.0, 50.0]  # Увеличение здоровья на 20%/35%/50%

func execute_ability(_owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Живучесть слизня - статическая способность, эффект применяется в _apply_passive_effects()
	# Возвращаем пустое сообщение, чтобы не логировать
	return {"success": false, "message": ""}

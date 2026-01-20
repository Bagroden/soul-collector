# res://Scripts/PassiveAbilities/Epic/NinjaShadow.gd
extends PassiveAbility

var stealth_duration: float = 2.0

func _init():
	id = "ninja_shadow"
	name = "Тень ниндзя"
	description = "30% шанс стать невидимым на 2 хода"
	rarity = "epic"
	ability_type = AbilityType.DEFENSIVE
	trigger_type = TriggerType.ON_DAMAGE_TAKEN
	value = 30.0  # 30% шанс

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Проверяем шанс невидимости
	if randf() < (value / 100.0):
		# Накладываем эффект невидимости на себя
		if owner.has_method("add_effect"):
			owner.add_effect("stealth", stealth_duration, 1)
		
		return {
			"success": true,
			"message": owner.display_name + " исчезает в тени!",
			"effect": "stealth",
			"duration": stealth_duration,
			"stacks": 1
		}
	
	return {"success": false, "message": "Тень не сработала"}

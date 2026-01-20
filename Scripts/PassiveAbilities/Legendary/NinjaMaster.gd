# res://Scripts/PassiveAbilities/Legendary/NinjaMaster.gd
extends PassiveAbility

var guaranteed_dodge_duration: float = 1.0  # 1 ход гарантированного уворота

func _init():
	id = "ninja_master"
	name = "Мастер ниндзя"
	description = "После удара в спину врага получает шанс гарантированно увернуться от одной атаки"
	rarity = "legendary"
	ability_type = AbilityType.DEFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	value = 100.0  # 100% шанс после удара в спину

func execute_ability(owner: Node, _target: Node = null, context: Dictionary = {}) -> Dictionary:
	# Проверяем, был ли удар в спину
	var is_backstab = context.get("is_backstab", false)
	
	if is_backstab:
		# Накладываем эффект гарантированного уворота
		if owner.has_method("add_effect"):
			owner.add_effect("guaranteed_dodge", guaranteed_dodge_duration, 1)
		
		return {
			"success": true,
			"message": owner.display_name + " готов к увороту после удара в спину!",
			"effect": "guaranteed_dodge",
			"duration": guaranteed_dodge_duration,
			"stacks": 1
		}
	
	return {"success": false, "message": "Мастер ниндзя не активирован"}
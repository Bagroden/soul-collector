# res://Scripts/PassiveAbilities/Uncommon/AcidTrail.gd
extends PassiveAbility

func _init():
	id = "acid_hits"
	name = "Кислотные удары"
	description = "35% шанс при физических атаках разрушить броню врага"
	rarity = "uncommon"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	value = 1.0  # Разрушает 1 брони за удар
	level_values = [1.0, 2.0, 4.0]  # Разрушает 1/2/4 брони за удар

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Проверяем, что урон физический
	var damage_type = _context.get("damage_type", "physical")
	if damage_type != "physical":
		return {"success": false, "message": "Кислотные удары срабатывают только от физического урона"}
	
	# Проверяем шанс срабатывания (35%)
	if randf() > 0.35:
		return {"success": false, "message": ""}
	
	# Получаем текущий уровень способности из контекста
	var current_level = _context.get("ability_level", 1)
	var reduction_value = get_value_for_level(current_level)
	
	# Разрушаем броню цели
	if _target and _target.has_method("reduce_armor"):
		_target.reduce_armor(reduction_value)
		
		return {
			"success": true,
			"message": owner.display_name + " разрушает " + str(int(reduction_value)) + " брони кислотными ударами!",
			"armor_reduction": reduction_value,
			"effect": "acid_hits"
		}
	
	return {"success": false, "message": "Кислотные удары не сработали"}

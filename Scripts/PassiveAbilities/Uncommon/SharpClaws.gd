# res://Scripts/PassiveAbilities/Uncommon/SharpClaws.gd
extends PassiveAbility

func _init():
	id = "sharp_claws"
	name = "Острые когти"
	description = "Шанс нанести рану. Максимум 3 стака. (Снижение эффективности лечения на 20% за стак)"
	rarity = "uncommon"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	value = 15.0  # 15% шанс раны (уровень 1)
	level_values = [15.0, 25.0, 40.0]  # 15%/25%/40% шанс раны

func execute_ability(owner: Node, target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Проверяем, что урон физический
	var damage_type = _context.get("damage_type", "physical")
	if damage_type != "physical":
		return {"success": false, "message": "Острые когти срабатывают только от физического урона"}
	
	# Получаем текущий уровень способности из контекста
	var current_level = _context.get("ability_level", 1)
	var wound_chance = get_value_for_level(current_level)
	
	# Проверяем шанс нанесения раны
	if randf() < (wound_chance / 100.0):
		# Рана нанесена
		if target and target.has_method("add_effect"):
			# Рана снижает эффективность лечения на 20% за стак (максимум 3 стака)
			target.add_effect("wound", 3.0, 1, {"healing_reduction": 20.0})
		
		return {
			"success": true,
			"message": owner.display_name + " наносит рану " + target.display_name + "!",
			"effect": "wound"
		}
	
	return {"success": false, "message": "Рана не нанесена"}

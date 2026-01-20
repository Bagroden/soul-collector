# Scripts/PassiveAbilities/Player/PlayerRatVitality.gd
extends PassiveAbility

func _init():
	id = "player_rat_vitality"
	name = "Крысиная живучесть"
	description = "Восстанавливает HP в начале хода"
	rarity = "common"
	ability_type = AbilityType.DEFENSIVE
	trigger_type = TriggerType.ON_TURN_START
	# Значения для каждого уровня
	level_values = [5.0, 8.0, 12.0]  # 5/8/12 HP за раунд
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var heal_amount = int(get_value_for_level(current_level))
	
	# Проверяем, что у владельца есть метод для регенерации HP
	if owner.has_method("heal"):
		owner.heal(heal_amount)
		
		return {
			"success": true,
			"message": owner.display_name + " восстанавливает " + str(heal_amount) + " HP благодаря крысиной живучести!",
			"heal_amount": heal_amount,
			"effect": "rat_vitality_regen"
		}
	
	return {"success": false, "message": "Крысиная живучесть не сработала"}

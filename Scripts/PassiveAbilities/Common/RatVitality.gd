# res://Scripts/PassiveAbilities/Common/RatVitality.gd
extends PassiveAbility

func _init():
	id = "rat_vitality"
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
		var old_hp = owner.hp
		owner.heal(heal_amount)
		var actual_heal = owner.hp - old_hp
		
		# Логируем с учетом фактического восстановления
		var battle_manager = owner.get_node_or_null("/root/BattleScene")
		if battle_manager and battle_manager.has_method("get_battle_log"):
			var battle_log = battle_manager.get_battle_log()
			if battle_log:
				battle_log.log_heal(owner.display_name, owner.display_name, actual_heal, owner.hp, owner.max_hp)
		
		return {
			"success": true,
			"message": owner.display_name + " восстанавливает " + str(actual_heal) + " HP благодаря крысиной живучести!",
			"heal_amount": actual_heal,
			"effect": "rat_vitality_regen"
		}
	
	return {"success": false, "message": "Крысиная живучесть не сработала"}

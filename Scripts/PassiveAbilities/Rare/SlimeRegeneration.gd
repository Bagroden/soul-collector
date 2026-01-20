# res://Scripts/PassiveAbilities/Rare/SlimeRegeneration.gd
extends PassiveAbility

func _init():
	id = "slime_regeneration"
	name = "Регенерация слизи"
	description = "Восстанавливает HP благодаря регенеративным свойствам слизи"
	rarity = "rare"
	ability_type = AbilityType.DEFENSIVE
	trigger_type = TriggerType.ON_TURN_START
	value = 4.0  # 4 + 1% от Максимума HP за раунд
	level_values = [4.0, 9.0, 15.0]  # 4+1%/9+2%/15+4% от Максимума HP за раунд

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Не срабатываем если владелец мертв
	if owner.has_method("is_dead") and owner.is_dead():
		return {"success": false, "message": "Регенерация слизи не сработала - владелец мертв"}
	
	# Не срабатываем если у владельца полное здоровье
	var current_hp = owner.hp if "hp" in owner else 0
	var max_hp = owner.max_hp if "max_hp" in owner else 0
	if current_hp >= max_hp:
		return {"success": false, "message": "Регенерация слизи не сработала - полное здоровье"}
	
	# Восстанавливаем HP: 4 + 1% от максимального HP
	if owner.has_method("heal"):
		var heal_amount = value + (max_hp * 0.01)  # 4 + 1% от макс HP
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
			"message": owner.display_name + " восстанавливает " + str(actual_heal) + " HP благодаря регенерации слизи!",
			"heal_amount": actual_heal,
			"effect": "slime_regeneration"
		}
	
	return {"success": false, "message": "Регенерация слизи не сработала"}

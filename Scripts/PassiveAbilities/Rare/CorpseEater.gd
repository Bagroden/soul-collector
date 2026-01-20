# res://Scripts/PassiveAbilities/Rare/CorpseEater.gd
extends PassiveAbility

func _init():
	id = "corpse_eater"
	name = "Пожиратель трупов"
	description = "При убийстве врага восстанавливает HP и временно увеличивает урон на 3 раунда"
	rarity = "rare"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.PASSIVE  # Срабатывает при убийстве (проверяется в battle_manager)
	# Восстановление HP для каждого уровня
	level_values = [15.0, 25.0, 40.0]
	value = 15.0  # Значение по умолчанию (1 уровень)

# Бонус урона для каждого уровня (совпадает с восстановлением HP)
var damage_bonuses = [15.0, 25.0, 40.0]

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var heal_percent = get_value_for_level(current_level)
	var damage_bonus = damage_bonuses[current_level - 1]
	
	# Рассчитываем исцеление
	var heal_amount = int(owner.max_hp * heal_percent / 100.0)
	
	if owner.has_method("heal"):
		var old_hp = owner.hp
		owner.heal(heal_amount)
		var actual_heal = owner.hp - old_hp
		
		# Применяем бафф урона на 3 раунда
		owner.set_meta("corpse_eater_damage_bonus", damage_bonus)
		owner.set_meta("corpse_eater_duration", 3)
		
		return {
			"success": true,
			"message": owner.display_name + " пирует трупом! (+" + str(actual_heal) + " HP, +" + str(int(damage_bonus)) + "% урон на 3 раунда)",
			"heal_amount": actual_heal,
			"damage_bonus": damage_bonus,
			"duration": 3,
			"effect": "corpse_eater"
		}
	
	return {"success": false}

func get_stat_modifier(stat_name: String, _current_level: int, owner: Node = null) -> float:
	if stat_name == "damage_percent" and owner:
		var buff_duration = owner.get_meta("corpse_eater_duration", 0)
		if buff_duration > 0:
			return owner.get_meta("corpse_eater_damage_bonus", 0.0)
	return 0.0

# res://Scripts/PassiveAbilities/Common/Relentless.gd
extends PassiveAbility

func _init():
	id = "relentless"
	name = "Неумолимый"
	description = "При атаке игнорирует часть брони цели. Чем ниже HP элитного скелета, тем больше брони игнорируется."
	rarity = "common"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	# Базовое игнорирование брони для каждого уровня
	level_values = [10.0, 15.0, 20.0]
	value = 10.0  # Значение по умолчанию (1 уровень)

# Бонус за каждые 20% потерянного HP
var hp_loss_bonuses = [5.0, 8.0, 12.0]

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var base_armor_ignore = get_value_for_level(current_level)
	var bonus_per_20_percent_hp_lost = hp_loss_bonuses[current_level - 1]
	
	# Рассчитываем потерянный HP
	var hp_percent = (float(owner.hp) / float(owner.max_hp)) * 100.0
	var hp_lost_percent = 100.0 - hp_percent
	
	# Рассчитываем количество 20% интервалов потерянного HP
	var hp_intervals = int(hp_lost_percent / 20.0)
	
	# Итоговое игнорирование брони
	var total_armor_ignore = base_armor_ignore + (bonus_per_20_percent_hp_lost * hp_intervals)
	
	# Сохраняем для использования в расчете урона
	owner.set_meta("relentless_armor_ignore", total_armor_ignore)
	
	return {
		"success": true,
		"message": owner.display_name + " неумолим! (Игнорирует " + str(int(total_armor_ignore)) + "% брони)",
		"armor_ignore": total_armor_ignore,
		"hp_intervals": hp_intervals,
		"effect": "relentless"
	}


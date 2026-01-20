# res://Scripts/PassiveAbilities/Common/OrcTotem.gd
extends PassiveAbility

func _init():
	id = "orc_totem"
	name = "Природный маг"
	description = "Увеличивает магический урон. Увеличивает стоимость магических способностей."
	rarity = "common"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.PASSIVE
	# Значения для каждого уровня: % увеличения магического урона
	level_values = [25.0, 50.0, 100.0]  # +25%/50%/100% магический урон
	# Вторичные значения: % увеличения стоимости магических способностей
	level_values_secondary = [50.0, 100.0, 200.0]  # +50%/+100%/+200% стоимость заклинаний
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var magic_damage_bonus = get_value_for_level(current_level)
	var mana_cost_increase = level_values_secondary[current_level - 1]
	
	# Отмечаем, что способность активна
	if not owner.has_meta("orc_totem_active"):
		owner.set_meta("orc_totem_active", true)
		owner.set_meta("orc_totem_magic_damage_bonus", magic_damage_bonus)
		owner.set_meta("orc_totem_mana_cost_increase", mana_cost_increase)
	
	# Эта способность пассивная и применяется через get_stat_modifier
	return {
		"success": true,
		"message": owner.display_name + " имеет усиленный магический урон",
		"stat_modifier": "magic_damage",
		"value": magic_damage_bonus,
		"mana_cost_increase": mana_cost_increase
	}

func get_stat_modifier(stat_name: String, current_level: int) -> float:
	if stat_name == "magic_damage":
		return get_value_for_level(current_level)
	return 0.0

func get_mana_cost_modifier(current_level: int) -> float:
	"""Возвращает множитель увеличения стоимости магических способностей"""
	if current_level > 0 and current_level <= level_values_secondary.size():
		return level_values_secondary[current_level - 1] / 100.0  # Конвертируем процент в множитель
	return 0.0

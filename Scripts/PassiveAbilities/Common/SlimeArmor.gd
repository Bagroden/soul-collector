# res://Scripts/PassiveAbilities/Common/SlimeArmor.gd
extends PassiveAbility

func _init():
	id = "slime_armor"
	name = "Слизистая броня"
	description = "Снижает входящий урон благодаря слизистой оболочке"
	rarity = "common"
	ability_type = AbilityType.DEFENSIVE
	trigger_type = TriggerType.PASSIVE
	# Значения для каждого уровня
	level_values = [3.0, 6.0, 10.0]  # снижение урона на 3/6/10 ед
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(_owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("level", 1)
	var damage_reduction = get_value_for_level(current_level)
	
	# Слизистая броня - это постоянный эффект, который применяется в _apply_passive_effects
	# Здесь ничего не делаем, чтобы избежать накопления эффекта
	return {
		"success": true,
		"message": "",  # Сообщение не показываем, так как это постоянный эффект
		"damage_reduction": damage_reduction,
		"effect": "slime_armor"
	}

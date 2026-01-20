# res://Scripts/PassiveAbilities/Common/ThiefAgility.gd
extends PassiveAbility

func _init():
	id = "thief_agility"                              # ⚠️ ВАЖНО: Уникальный ID
	name = "Ловкость вора"                            # ⚠️ ВАЖНО: Отображаемое имя
	description = "Увеличивает ловкость на X"
	rarity = "common"                                 # ⚠️ ВАЖНО: Редкость способности
	ability_type = AbilityType.OFFENSIVE              # ⚠️ ВАЖНО: Тип способности
	trigger_type = TriggerType.PASSIVE                # ⚠️ ВАЖНО: Когда срабатывает
	# Значения для каждого уровня
	level_values = [5.0, 10.0, 15.0]  # +5/+10/+15 к ловкости
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", _context.get("level", 1))
	var current_value = get_value_for_level(current_level)
	
	# Ловкость вора - постоянная способность, эффект применяется в _apply_passive_effects
	# Здесь просто возвращаем информацию о способности
	return {
		"success": true,
		"message": "Ловкость вора - " + owner.display_name + " получает +" + str(int(current_value)) + " к ловкости!",
		"effect": "thief_agility_bonus"
	}

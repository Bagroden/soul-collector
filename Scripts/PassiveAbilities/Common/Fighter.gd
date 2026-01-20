# res://Scripts/PassiveAbilities/Common/Fighter.gd
extends PassiveAbility

func _init():
	id = "fighter"                              # ⚠️ ВАЖНО: Уникальный ID
	name = "Боец"                              # ⚠️ ВАЖНО: Отображаемое имя
	description = "Увеличивает физический урон на X%"
	rarity = "common"                          # ⚠️ ВАЖНО: Редкость способности
	ability_type = AbilityType.OFFENSIVE       # ⚠️ ВАЖНО: Тип способности
	trigger_type = TriggerType.PASSIVE         # ⚠️ ВАЖНО: Когда срабатывает
	# Значения для каждого уровня
	level_values = [10.0, 20.0, 30.0]  # 10%/20%/30% увеличение урона
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", _context.get("level", 1))
	var current_value = get_value_for_level(current_level)
	
	# Боец - постоянная способность, эффект применяется в _apply_passive_effects
	# Здесь просто возвращаем информацию о способности
	return {
		"success": true,
		"message": "Боец - " + owner.display_name + " получает +" + str(current_value) + "% к физическому урону!",
		"effect": "fighter_bonus"
	}

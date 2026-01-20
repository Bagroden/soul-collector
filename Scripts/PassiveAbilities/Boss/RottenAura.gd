# res://Scripts/PassiveAbilities/Boss/RottenAura.gd
extends PassiveAbility

func _init():
	id = "rotten_aura"                        # ⚠️ ВАЖНО: Уникальный ID
	name = "Гнилостная аура"                # ⚠️ ВАЖНО: Отображаемое имя
	description = "Каждый ход накладывает 1 стак Гнили на противника. Гниль наносит урон в конце каждого раунда в зависимости от количества стаков (максимум 5 стаков). Гниль не имеет ограничений по длительности."
	rarity = "boss"                          # ⚠️ ВАЖНО: Редкость способности (изменено на boss)
	ability_type = AbilityType.OFFENSIVE       # ⚠️ ВАЖНО: Тип способности
	trigger_type = TriggerType.ON_TURN_START   # ⚠️ ВАЖНО: Когда срабатывает
	# Значения для каждого уровня
	level_values = [0.5, 0.7, 1.0]  # 0.5%/0.7%/1.0% HP за раунд за стак
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", _context.get("level", 1))
	
	# Получаем процент урона за стак для текущего уровня
	var damage_percent = get_value_for_level(current_level)  # 0.5%/0.7%/1.0% за стак
	
	# Применяем эффект "rotten" на цель (1 стак каждый ход, без ограничений по длительности)
	if _target and _target.has_method("add_effect"):
		_target.add_effect("rotten", 999.0, 1, {"damage_percent": damage_percent})
		return {
			"success": true,
			"message": owner.display_name + " накладывает Гниль на " + _target.display_name + "!",
			"effect": "rotten",
			"damage_percent": damage_percent
		}
	
	return {"success": false, "message": "Гнилостная аура не сработала"}

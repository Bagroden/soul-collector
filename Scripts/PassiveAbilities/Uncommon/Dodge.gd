# res://Scripts/PassiveAbilities/Common/Dodge.gd
extends PassiveAbility

func _init():
	id = "dodge"
	name = "Уворот"
	description = "Шанс увернуться от атаки"
	rarity = "uncommon"
	ability_type = AbilityType.DEFENSIVE
	trigger_type = TriggerType.ON_DAMAGE_TAKEN
	# Значения для каждого уровня
	level_values = [10.0, 17.0, 30.0]  # 10%/17%/30% шанс уворота
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, context: Dictionary = {}) -> Dictionary:
	var damage_amount = context.get("damage", 0)
	
	# Получаем текущий уровень способности
	var current_level = context.get("level", 1)
	var dodge_chance = get_value_for_level(current_level)
	
	# Проверяем шанс уворота
	if randf() < (dodge_chance / 100.0):
		# Уворот успешен - урон не наносится
		return {
			"success": true,
			"message": "Уворот - " + owner.display_name + " увернулся от атаки!",
			"damage_blocked": damage_amount,
			"effect": "dodge"
		}
	
	return {"success": false, "message": "Уворот не сработал"}

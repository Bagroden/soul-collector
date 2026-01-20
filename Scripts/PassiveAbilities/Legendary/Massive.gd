# res://Scripts/PassiveAbilities/Legendary/SlimeKing.gd
extends PassiveAbility

func _init():
	id = "massive"
	name = "Массивный"
	description = "Усиливает силу атак от максимального здоровья. Формула добавочного урона = количество ОЗ * на уровень пассивки 0.02/0.04/0.06"
	rarity = "legendary"
	ability_type = AbilityType.SPECIAL
	trigger_type = TriggerType.PASSIVE
	value = 2.0  # увеличивает урон физических атак на 2% от максимального здоровья
	level_values = [2.0, 4.0, 6.0]  # увеличивает урон физических атак на 2%/4%/6% от максимального здоровья

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Увеличиваем урон физических атак на процент от максимального здоровья
	if owner.has_method("get_max_hp") and owner.has_method("add_physical_damage_bonus"):
		var max_hp = owner.get_max_hp()
		var ability_level = _context.get("ability_level", 1)
		
		# Получаем правильный процент в зависимости от уровня
		var percentage = 0.02  # 2% по умолчанию
		match ability_level:
			1:
				percentage = 0.02  # 2%
			2:
				percentage = 0.04  # 4%
			3:
				percentage = 0.06  # 6%
		
		var damage_bonus = int(max_hp * percentage)
		owner.add_physical_damage_bonus(damage_bonus)
		
		return {
			"success": true,
			"message": owner.display_name + " получает +" + str(damage_bonus) + " урона от массивности (ур. " + str(ability_level) + ")!",
			"damage_bonus": damage_bonus,
			"effect": "massive"
		}
	
	return {"success": false, "message": "Массивность не сработала"}

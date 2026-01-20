# res://Scripts/PassiveAbilities/Epic/Stealth.gd
extends PassiveAbility

func _init():
	id = "stealth"
	name = "Скрытность"
	description = "Шанс стать невидимым при атаке. Невидимость не дает выбрать вас целью атаки. Первая атака из невидимости прерывает невидимость и считается атакой в спину. (Все атаки в спину имеют модификатор урона x1.5, пассивка Удар в спину может увеличить этот множитель)"
	rarity = "epic"
	ability_type = AbilityType.UTILITY
	trigger_type = TriggerType.ON_ATTACK
	# Значения для каждого уровня: % шанс невидимости
	level_values = [15.0, 25.0, 40.0]  # 15%/25%/40% шанс
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var proc_chance = get_value_for_level(current_level)
	
	var roll = randf() * 100.0
	
	if roll <= proc_chance:
		# Накладываем эффект невидимости
		if owner.has_method("add_effect"):
			owner.add_effect("invisibility", 2.0, 1, {})
			
			return {
				"success": true,
				"message": owner.display_name + " скрывается в тени!",
				"effect": "invisibility"
			}
	
	return {"success": false}

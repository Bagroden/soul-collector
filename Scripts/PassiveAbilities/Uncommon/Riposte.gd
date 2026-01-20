# res://Scripts/PassiveAbilities/Uncommon/Riposte.gd
extends PassiveAbility

func _init():
	id = "riposte"
	name = "Ответный удар"
	description = "При блокировании урона шанс контратаковать. Урон контратаки = сила + ловкость"
	rarity = "uncommon"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_DAMAGE_TAKEN
	# Значения для каждого уровня: шанс контратаки
	level_values = [25.0, 40.0, 60.0]  # 25%/40%/60% шанс
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var riposte_chance = get_value_for_level(current_level)
	
	# Проверяем, был ли блок
	var was_blocked = owner.get_meta("bone_parry_triggered", false)
	
	# Проверяем, не является ли входящая атака контратакой (защита от бесконечного цикла)
	if owner.has_meta("incoming_attack_is_counter") and owner.get_meta("incoming_attack_is_counter"):
		return {"success": false}
	
	if was_blocked and target:
		# Сбрасываем флаг блока
		owner.set_meta("bone_parry_triggered", false)
		
		# Проверяем шанс контратаки
		var roll = randf() * 100.0
		
		if roll <= riposte_chance:
			# Рассчитываем урон контратаки
			var counter_damage = owner.strength + owner.agility
			
			if target.has_method("take_damage"):
				# Помечаем атаку как контратаку, чтобы избежать бесконечного цикла
				target.set_meta("incoming_attack_is_counter", true)
				var actual_damage = target.take_damage(counter_damage, "physical")
				target.set_meta("incoming_attack_is_counter", false)
				
				return {
					"success": true,
					"message": owner.display_name + " контратакует " + target.display_name + " на " + str(actual_damage) + " урона!",
					"damage": actual_damage,
					"target": target,
					"effect": "riposte"
				}
	
	return {"success": false}


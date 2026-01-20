# res://Scripts/PassiveAbilities/Common/BoneParry.gd
extends PassiveAbility

func _init():
	id = "bone_parry"
	name = "Костяное парирование"
	description = "Шанс заблокировать часть входящего урона"
	rarity = "common"
	ability_type = AbilityType.DEFENSIVE
	trigger_type = TriggerType.ON_DAMAGE_TAKEN
	# Значения шансов для каждого уровня
	level_values = [20.0, 25.0, 30.0]  # Шанс блокировки
	value = 20.0  # Значение по умолчанию (1 уровень)

# Проценты блокировки для каждого уровня
var block_percents = [30.0, 40.0, 50.0]

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var block_chance = get_value_for_level(current_level)
	var block_percent = block_percents[current_level - 1]
	
	# Проверяем шанс блокирования
	var roll = randf() * 100.0
	
	if roll <= block_chance:
		var incoming_damage = _context.get("damage", 0)
		var blocked_damage = int(incoming_damage * block_percent / 100.0)
		
		# Сохраняем информацию о блокировке
		owner.set_meta("bone_parry_blocked", blocked_damage)
		owner.set_meta("bone_parry_triggered", true)
		
		return {
			"success": true,
			"message": owner.display_name + " парирует атаку! (Заблокировано " + str(blocked_damage) + " урона)",
			"blocked_damage": blocked_damage,
			"block_percent": block_percent,
			"effect": "bone_parry"
		}
	
	return {"success": false}

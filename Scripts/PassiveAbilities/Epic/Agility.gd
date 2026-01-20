# res://Scripts/PassiveAbilities/Rare/Agility.gd
extends PassiveAbility

func _init():
	id = "agility"
	name = "Изворотливость"
	description = "При уклонении шанс контратаки (Урон контратаки = сила + ловкость)"
	rarity = "epic"
	ability_type = AbilityType.UTILITY
	trigger_type = TriggerType.ON_DODGE
	# Значения для каждого уровня
	level_values = [20.0, 30.0, 45.0]  # 20%/30%/45% шанс контратаки
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Проверяем, есть ли цель для контратаки
	if not target:
		return {"success": false, "message": "Нет цели для контратаки"}
	
	# Получаем текущий уровень способности
	var current_level = _context.get("level", 1)
	var counter_chance = get_value_for_level(current_level)
	
	# Проверяем шанс контратаки при уклонении
	if randf() < (counter_chance / 100.0):
		# Рассчитываем урон контратаки: сила + ловкость
		var counter_attack_damage = owner.strength + owner.agility
		
		# НЕ наносим урон сразу - это будет сделано в battle_manager после логирования способности
		return {
			"success": true,
			"message": "Изворотливость - " + owner.display_name + " готов к контратаке!",
			"counter_attack_damage": counter_attack_damage,
			"effect": "agility_counter_attack"
		}
	
	# Если контратака не сработала, НЕ показываем сообщение об уклонении
	# Изворотливость НЕ дает уклонение, только шанс на контратаку
	return {
		"success": false,
		"message": "",
		"effect": "agility_no_counter"
	}

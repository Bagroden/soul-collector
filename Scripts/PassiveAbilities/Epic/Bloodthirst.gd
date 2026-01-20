# res://Scripts/PassiveAbilities/Epic/Bloodthirst.gd
extends PassiveAbility

func _init():
	id = "ork_vitality"
	name = "Выносливость орка"
	description = "Снижение всего получаемого урона за каждый процент потерянного здоровья"
	rarity = "epic"
	ability_type = AbilityType.DEFENSIVE
	trigger_type = TriggerType.ON_DAMAGE_TAKEN
	# Значения для каждого уровня: % снижения урона за 1% потерянного здоровья
	level_values = [0.1, 0.2, 0.3]  # 0.1%/0.2%/0.3% снижение урона за 1% потерянного HP
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Выносливость орка - снижение урона рассчитывается динамически в take_damage
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var reduction_per_hp_percent = get_value_for_level(current_level)  # 0.1/0.2/0.3
	
	# Вычисляем текущее снижение урона
	if owner and owner.has_method("get_magic_barrier"):  # Проверяем что это body
		var hp_lost_percent = 100.0 - ((float(owner.hp) / float(owner.max_hp)) * 100.0)
		var damage_reduction_percent = reduction_per_hp_percent * hp_lost_percent
		
		# Добавляем или обновляем эффект для визуального отображения
		if owner.has_method("add_effect"):
			if owner.has_effect("ork_vitality"):
				# Обновляем существующий эффект
				var effect = owner.effects["ork_vitality"]
				effect["damage_reduction_percent"] = damage_reduction_percent
				effect["reduction_per_hp_percent"] = reduction_per_hp_percent
			else:
				# Создаем новый эффект
				owner.add_effect("ork_vitality", 999.0, 1, {
					"damage_reduction_percent": damage_reduction_percent,
					"reduction_per_hp_percent": reduction_per_hp_percent
				})
	
	return {"success": true, "effect": "ork_vitality"}

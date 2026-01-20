# res://Scripts/PassiveAbilities/Legendary/BerserkerRampage.gd
extends PassiveAbility

func _init():
	id = "berserk"
	name = "Берсерк"
	description = "Огромный урон при критическом состоянии. Активируется при получении урона, если HP < 20%."
	rarity = "legendary"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_DAMAGE_TAKEN
	# Значения для каждого уровня: множитель урона и порог HP
	# 1 уровень: x1.7 урон при HP < 10%
	# 2 уровень: x2.2 урон при HP < 15%
	# 3 уровень: x2.7 урон при HP < 20%
	level_values = [1.7, 2.2, 2.7]  # Множитель урона
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var rampage_multiplier = get_value_for_level(current_level)
	
	# Пороги HP для каждого уровня
	var hp_thresholds = [10.0, 15.0, 20.0]  # 10%/15%/20%
	var hp_threshold = hp_thresholds[current_level - 1] if current_level <= hp_thresholds.size() else 20.0
	
	# Проверяем HP владельца
	if owner:
		var hp_percent = (float(owner.hp) / float(owner.max_hp)) * 100.0
		
		# Если HP меньше порога, активируем берсерк
		if hp_percent <= hp_threshold:
			# Отмечаем, что берсерк активен (используем мета-данные для логики урона)
			if not owner.has_meta("berserk_active"):
				owner.set_meta("berserk_active", true)
				owner.set_meta("berserk_multiplier", rampage_multiplier)
			
			# Добавляем эффект для визуального отображения (без длительности, пока HP ниже порога)
			if owner.has_method("add_effect") and not owner.has_effect("berserk"):
				owner.add_effect("berserk", 999.0, 1, {
					"damage_multiplier": rampage_multiplier,
					"hp_threshold": hp_threshold
				})
			elif owner.has_effect("berserk"):
				# Обновляем множитель в эффекте
				var effect = owner.effects["berserk"]
				effect["damage_multiplier"] = rampage_multiplier
				effect["hp_threshold"] = hp_threshold
			
			return {
				"success": true,
				"message": owner.display_name + " впадает в берсерк!",
				"damage_multiplier": rampage_multiplier,
				"effect": "berserk"
			}
		else:
			# Если HP больше порога, деактивируем берсерк
			if owner.has_meta("berserk_active"):
				owner.remove_meta("berserk_active")
				owner.remove_meta("berserk_multiplier")
			# Удаляем эффект для визуального отображения
			if owner.has_method("remove_effect") and owner.has_effect("berserk"):
				owner.remove_effect("berserk")
	
	return {"success": false}


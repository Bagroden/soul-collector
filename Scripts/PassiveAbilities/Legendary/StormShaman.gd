# res://Scripts/PassiveAbilities/Legendary/StormShaman.gd
extends PassiveAbility

func _init():
	id = "storm_shaman"
	name = "Шаман бурь"
	description = "При нанесении любого магического урона есть шанс X% вызвать удар молнии. Удар молнии наносит магический урон = интеллект + мудрость"
	rarity = "legendary"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	level_values = [5.0, 10.0, 15.0]  # Шанс вызова молнии

func execute_ability(_owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	"""Проверяет шанс вызова молнии при магической атаке"""
	if not _owner or not _target or not "intelligence" in _owner or not "wisdom" in _owner:
		return {"success": false, "message": "Нет владельца, цели или характеристик"}
	
	# Проверяем, что это магическая атака
	var damage_type = _context.get("damage_type", "physical")
	if damage_type != "magic":
		return {"success": false, "message": "Не магическая атака"}
	
	var ability_level = _owner.ability_levels.get(id, 1)
	var lightning_chance = get_value_for_level(ability_level)
	var roll = randf() * 100.0
	
	# Проверяем шанс молнии
	if roll < lightning_chance:
		# Рассчитываем урон молнии
		var lightning_damage = _owner.intelligence + _owner.wisdom
		
		# Создаем визуальный эффект молнии
		_spawn_lightning_effect(_target)
		
		# Наносим урон молнии
		_target.take_damage(lightning_damage, "magic")
		
		# Показываем всплывающую цифру урона от молнии
		if DamageNumberManager.instance:
			DamageNumberManager.show_damage_on_character(_target, lightning_damage, false, false, false, "magic")
		
		return {
			"success": true,
			"lightning_damage": lightning_damage,
			"message": _owner.display_name + " вызывает удар молнии! Урон: " + str(lightning_damage)
		}
	
	return {"success": false, "message": "Молния не сработала"}

func _spawn_lightning_effect(target: Node):
	"""Создает визуальный эффект молнии над целью"""
	print("🌩️ Создание эффекта молнии...")
	
	# Загружаем сцену эффекта молнии
	var lightning_scene = load("res://Scenes/Effects/LightningEffect.tscn")
	if not lightning_scene:
		print("⚠️ Не удалось загрузить сцену LightningEffect")
		return
	
	print("✅ Сцена молнии загружена")
	
	# Создаем экземпляр эффекта
	var lightning_effect = lightning_scene.instantiate()
	print("✅ Экземпляр молнии создан: ", lightning_effect)
	
	# Получаем менеджер боя
	var battle_manager = target.get_node_or_null("/root/BattleScene")
	if not battle_manager:
		print("⚠️ Не удалось найти BattleManager через /root/BattleScene")
		# Пробуем найти через родителя цели
		var current = target
		while current:
			if current.name == "BattleManager" or "battle" in current.name.to_lower():
				battle_manager = current
				print("✅ Найден BattleManager через родителя: ", battle_manager.name)
				break
			current = current.get_parent()
		
		if not battle_manager:
			print("⚠️ BattleManager не найден вообще, используем get_tree().root")
			battle_manager = target.get_tree().root.get_node_or_null("BattleScene")
			if not battle_manager:
				print("❌ Не удалось найти место для размещения эффекта")
				lightning_effect.queue_free()
				return
	
	print("✅ BattleManager найден: ", battle_manager.name)
	
	# Добавляем эффект в сцену боя
	battle_manager.add_child(lightning_effect)
	print("✅ Эффект добавлен в сцену боя")
	
	# Настраиваем позицию эффекта над целью
	var target_pos = target.global_position
	print("📍 Позиция цели: ", target_pos)
	
	if lightning_effect.has_method("setup"):
		lightning_effect.setup(target_pos)
		print("✅ Вызван метод setup() эффекта")
	else:
		lightning_effect.global_position = target_pos + Vector2(0, -100)
		print("⚠️ Метод setup() не найден, установлена позиция напрямую: ", lightning_effect.global_position)

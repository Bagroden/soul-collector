# res://Scripts/PassiveAbilities/Rare/MagicBarrier.gd
extends PassiveAbility

func _init():
	id = "magic_barrier"
	name = "Магический барьер"
	description = "Создает магический барьер, который поглощает урон и блокирует некоторые статусные эффекты. Барьер = Мудрость * X"
	rarity = "rare"
	ability_type = AbilityType.DEFENSIVE
	trigger_type = TriggerType.PASSIVE
	level_values = [1.5, 2.0, 2.5]  # Множитель для мудрости

func execute_ability(_owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	"""Создает магический барьер на основе мудрости владельца"""
	if not _owner or not "wisdom" in _owner:
		return {"success": false, "message": "Нет владельца или мудрости"}
	
	var wisdom = _owner.wisdom
	var ability_level = _owner.ability_levels.get(id, 1)
	var multiplier = get_value_for_level(ability_level)
	
	# Рассчитываем количество барьера
	var barrier_amount = int(wisdom * multiplier)
	
	# Устанавливаем максимальный барьер
	_owner.max_magic_barrier = barrier_amount
	
	# Добавляем барьер
	_owner.add_magic_barrier(barrier_amount)
	
	return {
		"success": true,
		"barrier_amount": barrier_amount,
		"message": _owner.display_name + " создает магический барьер (" + str(barrier_amount) + ")!"
	}

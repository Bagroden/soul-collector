# res://Scripts/Abilities/SoulRestoration.gd
extends PlayerAbility

func _init():
	id = "soul_restoration"
	name = "Восстановление души"
	description = "Восстанавливает 35% от максимального ОЗ, ОМ и ОВ. Имеет ограниченное количество зарядов на забег."
	mp_cost = 0
	stamina_cost = 0
	cooldown = 0
	damage_type = "heal"  # Специальный тип для лечения

func calculate_damage(owner: Node, _target: Node) -> int:
	"""Рассчитывает количество восстановления"""
	# Восстанавливаем 35% от максимальных значений
	var hp_restore = int(owner.max_hp * 0.35)
	var mp_restore = int(owner.max_mp * 0.35)
	var stamina_restore = int(owner.max_stamina * 0.35)
	
	# Возвращаем общее количество восстановления для логирования
	return hp_restore + mp_restore + stamina_restore

func use_ability(owner: Node, _target: Node) -> Dictionary:
	"""Использует способность восстановления души"""
	if not can_use(owner):
		return {"success": false, "message": "Недостаточно зарядов для использования способности"}
	
	# Проверяем, есть ли заряды через owner (который является Node)
	var soul_restoration_manager = owner.get_node_or_null("/root/SoulRestorationManager")
	if not soul_restoration_manager:
		return {"success": false, "message": "Система восстановления души недоступна"}
	
	if not soul_restoration_manager.can_use_charge():
		return {"success": false, "message": "Недостаточно зарядов восстановления души"}
	
	# Тратим заряд
	soul_restoration_manager.use_charge()
	
	# Получаем процент восстановления из менеджера
	var restoration_percentage = soul_restoration_manager.get_restoration_percentage()
	
	# Рассчитываем восстановление
	var hp_restore = int(owner.max_hp * restoration_percentage)
	var mp_restore = int(owner.max_mp * restoration_percentage)
	var stamina_restore = int(owner.max_stamina * restoration_percentage)
	
	# Восстанавливаем ресурсы
	owner.hp = min(owner.max_hp, owner.hp + hp_restore)
	owner.mp = min(owner.max_mp, owner.mp + mp_restore)
	owner.stamina = min(owner.max_stamina, owner.stamina + stamina_restore)
	
	# Получаем бонус барьера из менеджера и применяем его
	var barrier_bonus = soul_restoration_manager.get_barrier_bonus()
	if barrier_bonus > 0 and owner.has_method("add_magic_barrier"):
		owner.add_magic_barrier(barrier_bonus)
	
	# Обновляем UI
	if owner.has_method("update_ui"):
		owner.update_ui()
	
	return {
		"success": true,
		"heal_amount": hp_restore,
		"mp_restore": mp_restore,
		"stamina_restore": stamina_restore,
		"barrier_added": barrier_bonus,
		"message": owner.display_name + " восстанавливает силы души!",
		"damage_type": "heal"
	}

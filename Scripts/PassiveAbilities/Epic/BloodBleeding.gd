# res://Scripts/PassiveAbilities/Epic/BloodBleeding.gd
extends PassiveAbility

func _init():
	id = "blood_bleeding"
	name = "Кровотечение"
	description = "25% шанс вызвать кровотечение при атаке"
	rarity = "epic"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	value = 25.0  # 25% шанс кровотечения
	duration = 3.0  # Кровотечение длится 3 хода

func execute_ability(_owner: Node, target: Node = null, _context: Dictionary = {}) -> Dictionary:
	if not target:
		return {"success": false, "message": "Нет цели для кровотечения"}
	
	# Проверяем шанс кровотечения
	if randf() < (value / 100.0):
		# Применяем эффект кровотечения с 1 стаком
		if target.has_method("add_effect"):
			var source_id = _owner.get_instance_id() if _owner else 0
			target.add_effect("bleeding", duration, 1, {"source_id": source_id})
		
		return {
			"success": true,
			"message": target.display_name + " сильно истекает кровью!",
			"effect": "bleeding",
			"duration": duration,
			"stacks": 1
		}
	
	return {"success": false, "message": "Кровотечение не вызвано"}

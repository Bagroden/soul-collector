# res://Scripts/PassiveAbilities/Rare/Backstab.gd
extends PassiveAbility

func _init():
	id = "backstab"
	name = "Удар в спину"
	description = "Увеличенный урон при атаке сзади"
	rarity = "rare"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	# Значения для каждого уровня: множитель урона при ударе в спину
	# Базовый множитель удара в спину x1.5, эта способность увеличивает его
	level_values = [0.5, 1.2, 2.0]  # +0.5/+1.2/+2.0 к базовому x1.5 = x2.0/x2.7/x3.5 урон
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var backstab_bonus = get_value_for_level(current_level)
	
	# Базовый множитель удара в спину x1.5, эта способность добавляет бонус
	# Итоговый множитель = 1.5 + backstab_bonus
	var total_multiplier = 1.5 + backstab_bonus
	
	# Проверяем, является ли это ударом в спину (если владелец невидим)
	var is_backstab = false
	if owner and owner.has_effect("invisibility"):
		is_backstab = true
		# Первая атака из невидимости прерывает невидимость
		if owner.has_method("remove_effect"):
			owner.remove_effect("invisibility")
	
	if is_backstab:
		# Отмечаем, что следующая атака будет ударом в спину
		if not owner.has_meta("backstab_active"):
			owner.set_meta("backstab_active", true)
			owner.set_meta("backstab_multiplier", total_multiplier)
			
			return {
				"success": true,
				"message": owner.display_name + " наносит удар в спину!",
				"damage_multiplier": total_multiplier,
				"effect": "backstab"
			}
	
	return {"success": false}

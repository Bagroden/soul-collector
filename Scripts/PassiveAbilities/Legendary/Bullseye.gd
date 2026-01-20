# res://Scripts/PassiveAbilities/Legendary/Bullseye.gd
extends PassiveAbility

func _init():
	id = "bullseye"
	name = "Попадание в яблочко"
	description = "Критические удары наносят огромный дополнительный урон"
	rarity = "legendary"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_CRIT
	# Значения для каждого уровня: % дополнительного урона от крита
	level_values = [80.0, 120.0, 180.0]  # +80%/120%/180% урона от крита
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Получаем текущий уровень способности
	var current_level = _context.get("ability_level", 1)
	var crit_damage_bonus = get_value_for_level(current_level)
	
	# Отмечаем, что следующий крит будет усилен
	if not owner.has_meta("bullseye_active"):
		owner.set_meta("bullseye_active", true)
		owner.set_meta("bullseye_damage_bonus", crit_damage_bonus)
		
		return {
			"success": true,
			"message": owner.display_name + " целится в яблочко!",
			"crit_damage_bonus": crit_damage_bonus,
			"effect": "bullseye"
		}
	
	return {"success": false}

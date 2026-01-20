# res://Scripts/PassiveAbilities/Epic/Echolocation.gd
extends PassiveAbility

func _init():
	id = "echolocation"
	name = "Эхолокация"
	description = "Способность видеть противников в невидимости"
	rarity = "epic"
	ability_type = AbilityType.UTILITY
	trigger_type = TriggerType.PASSIVE
	value = 1.0  # Постоянный эффект

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Эхолокация - постоянная способность, но логируется только при нейтрализации невидимости
	if owner.has_method("add_true_sight"):
		owner.add_true_sight()
	
	# Проверяем, есть ли в контексте информация о нейтрализации невидимости
	if _context.get("neutralize_invisibility", false):
		return {
			"success": true,
			"message": owner.display_name + " нейтрализует невидимость врага!",
			"effect": "true_sight"
		}
	
	# Если невидимости нет, не логируем
	return {
		"success": false,
		"message": "",
		"effect": "true_sight"
	}

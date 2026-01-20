# res://Scripts/PassiveAbilities/Common/OrcRage.gd
extends PassiveAbility

func _init():
	id = "orc_rage"
	name = "Сила орка"
	description = "Постоянное увеличение силы"
	rarity = "common"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.PASSIVE
	# Значения для каждого уровня: +сила
	level_values = [10.0, 20.0, 30.0]  # +10/+20/+30 силы
	value = level_values[0]  # Значение по умолчанию (1 уровень)

func execute_ability(_owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Постоянное увеличение силы - применяется автоматически при добавлении способности
	# Этот метод вызывается при инициализации, но бонус применяется в _apply_passive_effects
	return {"success": true}

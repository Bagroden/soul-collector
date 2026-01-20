# res://Scripts/PassiveAbilities/Common/CurseWeakness.gd
extends PassiveAbility

var weakness_duration: float = 3.0
var strength_reduction: float = 0.3  # 30% снижение силы

func _init():
	id = "curse_weakness"
	name = "Проклятие слабости"
	description = "Снижение силы врага на 30%"
	rarity = "common"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	value = 25.0  # 25% шанс

func execute_ability(owner: Node, target: Node = null, _context: Dictionary = {}) -> Dictionary:
	if not target:
		return {"success": false, "message": "Нет цели для проклятия слабости"}
	
	# Проверяем шанс проклятия
	if randf() < (value / 100.0):
		# Снижаем силу врага на 30%
		var original_strength = target.strength
		var reduced_strength = int(original_strength * (1.0 - strength_reduction))
		target.strength = reduced_strength
		
		# Накладываем эффект слабости для отслеживания
		if target.has_method("add_effect"):
			target.add_effect("weakness", weakness_duration, 1, {"strength_reduction": strength_reduction, "original_strength": original_strength})
		
		return {
			"success": true,
			"message": owner.display_name + " проклинает " + target.display_name + " слабостью! Сила снижена на 30%",
			"effect": "weakness",
			"duration": weakness_duration,
			"strength_reduction": strength_reduction,
			"original_strength": original_strength,
			"new_strength": reduced_strength
		}
	
	return {"success": false, "message": "Проклятие слабости не сработало"}

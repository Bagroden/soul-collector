# res://Scripts/PassiveAbilities/Uncommon/CurseMagic.gd
extends PassiveAbility

var curse_duration: float = 3.0  # Проклятие длится 3 хода

func _init():
	id = "curse_magic"
	name = "Проклятая магия"
	description = "15% шанс наложить проклятие на врага"
	rarity = "uncommon"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	value = 15.0  # 15% шанс проклятия

func execute_ability(owner: Node, target: Node = null, _context: Dictionary = {}) -> Dictionary:
	if not target:
		return {"success": false, "message": "Нет цели для проклятия"}
	
	# Проверяем шанс проклятия
	if randf() < (value / 100.0):
		# Накладываем проклятие на цель с эффектом снижения магического сопротивления
		if target.has_method("add_effect"):
			target.add_effect("curse", curse_duration, 1, {"resistance_reduction": 0.5})  # Снижает сопротивление на 50%
		
		return {
			"success": true,
			"message": owner.display_name + " проклинает " + target.display_name + "! Магическое сопротивление снижено!",
			"effect": "curse",
			"duration": curse_duration,
			"stacks": 1
		}
	
	return {"success": false, "message": "Проклятие не сработало"}

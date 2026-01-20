# res://Scripts/PassiveAbilities/Rare/ExecutionerJudgment.gd
extends PassiveAbility

var judgment_duration: float = 2.0
var hp_percentage_damage: float = 0.2  # 20% от максимального HP
var stun_duration: float = 1.0  # 1 ход оглушения

func _init():
	id = "executioner_judgment"
	name = "Суд палача"
	description = "30% шанс наложить метку суда, которая взрывается через 2 хода, снимая 20% от максимального здоровья врага и оглушая на один ход"
	rarity = "rare"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	value = 30.0  # 30% шанс

func execute_ability(owner: Node, target: Node = null, _context: Dictionary = {}) -> Dictionary:
	if not target:
		return {"success": false, "message": "Нет цели для суда"}
	
	# Проверяем шанс суда
	if randf() < (value / 100.0):
		if target.has_method("add_effect"):
			# Передаем параметры в эффект
			var effect_data = {
				"hp_damage_percentage": hp_percentage_damage,
				"stun_duration": stun_duration
			}
			target.add_effect("judgment", judgment_duration, 1, effect_data)
		
		return {
			"success": true,
			"message": owner.display_name + " выносит приговор " + target.display_name + "!",
			"effect": "judgment",
			"duration": judgment_duration,
			"hp_damage_percentage": hp_percentage_damage,
			"stun_duration": stun_duration,
			"stacks": 1
		}
	
	return {"success": false, "message": "Суд не сработал"}

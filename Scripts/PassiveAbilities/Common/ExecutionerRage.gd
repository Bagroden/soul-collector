# res://Scripts/PassiveAbilities/Common/ExecutionerRage.gd
extends PassiveAbility

var damage_bonus: float = 0.5  # 50% бонус

func _init():
	id = "executioner_rage"
	name = "Ярость палача"
	description = "Урон увеличивается на 50% при низком HP владельца (меньше 20%)"
	rarity = "common"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	value = 50.0  # 50% бонус к урону

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Проверяем HP владельца способности (если меньше 20%)
	var owner_hp_percentage = float(owner.hp) / float(owner.max_hp)
	if owner_hp_percentage < 0.2:  # Меньше 20% HP
		var base_damage = _context.get("damage", 0)
		var bonus_damage = int(base_damage * damage_bonus)
		
		return {
			"success": true,
			"message": owner.display_name + " впадает в ярость! (+" + str(bonus_damage) + " урона)",
			"bonus_damage": bonus_damage,
			"effect": "executioner_rage"
		}
	
	return {"success": false, "message": "Ярость не активирована (владелец слишком здоров: " + str(int(owner_hp_percentage * 100)) + "%)"}

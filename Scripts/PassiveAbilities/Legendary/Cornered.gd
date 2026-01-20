# res://Scripts/PassiveAbilities/Legendary/Cornered.gd
extends PassiveAbility

func _init():
	id = "cornered"
	name = "Загнанный в угол"
	description = "При падении здоровья ниже 30%, увеличение урона на 50%"
	rarity = "legendary"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.PASSIVE
	value = 50.0  # 50% увеличение урона
	duration = 0.0  # Постоянный эффект

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Проверяем, что здоровье ниже 30%
	var health_percentage = float(owner.hp) / float(owner.max_hp)
	if health_percentage <= 0.3:
		# Применяем бонус к урону через систему временных бонусов
		if owner.has_method("add_stat_bonus"):
			# Добавляем бонус к урону на 1 раунд (постоянно, пока HP < 30%)
			owner.add_stat_bonus("damage_bonus", value, 1.0)  # 50% бонус на 1 раунд
			
			return {
				"success": true,
				"message": owner.display_name + " загнан в угол и становится опаснее!",
				"damage_bonus": value,
				"effect": "cornered"
			}
	
	return {"success": false, "message": ""}

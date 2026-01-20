# Scripts/PassiveAbilities/Player/PlayerCornered.gd
extends PassiveAbility

func _init():
	id = "player_cornered"
	name = "Загнанный в угол"
	description = "При здоровье менее 20% получает +50% к урону и +25% к скорости атаки"
	rarity = "legendary"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_TURN_START
	value = 50.0  # 50% бонус урона

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Проверяем, что у владельца критически низкое здоровье (менее 20%)
	var health_percentage = float(owner.current_hp) / float(owner.max_hp)
	if health_percentage < 0.2:
		# Применяем бонусы
		owner.bonus_damage += int(owner.get_total_damage() * (value / 100.0))
		# Увеличиваем скорость атаки (если есть такой параметр)
		if owner.has_method("set_attack_speed"):
			owner.set_attack_speed(1.25)  # +25% к скорости атаки
		
		return {
			"success": true,
			"message": owner.display_name + " загнан в угол и получает бонусы к урону и скорости!",
			"damage_bonus": int(owner.get_total_damage() * (value / 100.0)),
			"effect": "cornered_bonus"
		}
	
	return {"success": false, "message": "Загнанный в угол не активирован - здоровье слишком высокое"}

# res://Scripts/PassiveAbilities/Rare/AlkaraBloodRitual.gd
extends PassiveAbility

func _init():
	id = "alkara_blood_ritual"
	name = "Кровавый ритуал Алкары"
	description = "Жертвует HP для усиления атак"
	rarity = "rare"
	ability_type = AbilityType.SPECIAL
	trigger_type = TriggerType.ON_TURN_START
	value = 30.0  # +30% урон

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	if not owner or not owner.has_method("take_damage") or not owner.has_method("add_stat_bonus"):
		return {"success": false, "message": "Владелец не поддерживает кровавый ритуал"}
	
	# Фиксированные значения для 1 уровня (как указано в документации)
	var hp_cost: int = 10
	var damage_bonus: float = 30.0  # +30% урон
	
	# Жертвуем HP
	owner.take_damage(hp_cost, "physical")  # физический урон
	
	# Показываем всплывающую цифру урона от ритуала
	if DamageNumberManager.instance:
		DamageNumberManager.show_damage_on_character(owner, hp_cost, false, false, false, "bleeding")
	
	# Добавляем бонус к урону на один раунд
	owner.add_stat_bonus("damage_bonus", damage_bonus, 1.0)  # 1.0 = на 1 раунд
	
	return {
		"success": true,
		"message": owner.display_name + " жертвует " + str(hp_cost) + " HP и получает +" + str(int(damage_bonus)) + "% к урону!",
		"hp_cost": hp_cost,
		"damage_bonus": damage_bonus
	}

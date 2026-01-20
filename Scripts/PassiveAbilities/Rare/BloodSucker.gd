# res://Scripts/PassiveAbilities/Rare/BloodSucker.gd
extends PassiveAbility

func _init():
	id = "blood_sucker"
	name = "Кровосос"
	description = "Физический урон с шансом 20% восстанавливает 10% от нанесенного урона в виде здоровья. Если на цели есть кровотечение, шанс увеличивается на 10% за стак"
	rarity = "rare"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	value = 20.0  # 20% шанс вампиризма

func execute_ability(owner: Node, target: Node = null, context: Dictionary = {}) -> Dictionary:
	# Проверяем, что урон физический
	var damage_type = context.get("damage_type", "physical")
	if damage_type != "physical":
		return {"success": false, "message": "Кровосос срабатывает только от физического урона"}
	
	var damage_amount = context.get("damage", 0)
	var lifesteal_chance = value
	
	# Проверяем, есть ли у цели кровотечение
	if target and target.has_method("has_effect"):
		var bleeding_stacks = target.get_effect_stacks("bleeding")
		if bleeding_stacks > 0:
			lifesteal_chance += bleeding_stacks * 10.0  # +10% за каждый стак кровотечения
	
	var roll = randf() * 100.0
	
	# Проверяем шанс вампиризма
	if roll < lifesteal_chance:
		# Вампиризм сработал
		var heal_amount = int(damage_amount * 0.1)  # 10% от урона
		
		if owner.has_method("heal"):
			owner.heal(heal_amount)
		else:
			print("ОШИБКА: У владельца нет метода heal!")
		
		return {
			"success": true,
			"message": owner.display_name + " восстанавливает " + str(heal_amount) + " здоровья!",
			"effect": "life_steal",
			"heal_amount": heal_amount
		}
	
	return {"success": false, "message": "Вампиризм не сработал"}

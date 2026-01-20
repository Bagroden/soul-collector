# res://Scripts/PassiveAbilities/Uncommon/AlkaraVampirism.gd
extends PassiveAbility

var heal_percentage: float = 0.25  # 25% от урона

func _init():
	id = "alkara_vampirism"
	name = "Вампиризм Алкары"
	description = "Восстанавливает HP при магических атаках"
	rarity = "uncommon"
	ability_type = AbilityType.OFFENSIVE
	trigger_type = TriggerType.ON_ATTACK
	value = 25.0  # 25% от урона восстанавливается

func execute_ability(owner: Node, target: Node = null, context: Dictionary = {}) -> Dictionary:
	if not target:
		return {"success": false, "message": "Нет цели для вампиризма"}
	
	# Проверяем, что это магическая атака
	var is_magic_attack = context.get("is_magic", false)
	if not is_magic_attack:
		return {"success": false, "message": "Вампиризм работает только с магическими атаками"}
	
	var damage = context.get("damage", 0)
	var heal_amount = int(damage * heal_percentage)
	
	if heal_amount > 0:
		# Восстанавливаем HP владельцу
		if owner.has_method("heal"):
			owner.heal(heal_amount)
		
		return {
			"success": true,
			"message": owner.display_name + " поглощает жизненную силу! (+" + str(heal_amount) + " HP)",
			"heal_amount": heal_amount,
			"effect": "alkara_vampirism"
		}
	
	return {"success": false, "message": "Вампиризм не сработал"}

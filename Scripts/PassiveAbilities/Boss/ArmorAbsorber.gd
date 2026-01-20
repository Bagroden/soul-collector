# res://Scripts/PassiveAbilities/Boss/ArmorAbsorber.gd
extends PassiveAbility

class_name ArmorAbsorberPassive

# Значения для разных уровней (защита за 3 единицы снижения брони врага)
var armor_gain_per_level = [1, 2, 3]  # 1/2/3 защиты за каждые 3 сниженные единицы

func _init():
	id = "armor_absorber"
	name = "Поглотитель брони"
	description = "Получает X защиты за каждые 3 сниженные единицы брони врага"
	rarity = "boss"
	ability_type = AbilityType.DEFENSIVE
	trigger_type = TriggerType.PASSIVE  # Срабатывает всегда, проверяем контекст внутри
	value = 1.0
	level_values = [1.0, 2.0, 3.0]  # Значения для уровней 1-3

func get_value_for_level(level: int) -> float:
	if level < 1 or level > 3:
		return 0.0
	return float(armor_gain_per_level[level - 1])

func trigger(owner: Node, _target: Node = null, context: Dictionary = {}) -> Dictionary:
	"""Срабатывает когда враг теряет броню"""
	var event_trigger = context.get("trigger", "")
	var level = context.get("ability_level", 1)
	
	# Эта способность срабатывает только при снижении брони врага
	if event_trigger != "armor_reduced":
		return {"success": false, "message": ""}
	
	# Получаем количество сниженной брони
	var armor_reduced = context.get("armor_reduced", 0)
	if armor_reduced <= 0:
		return {"success": false, "message": ""}
	
	# Вычисляем сколько защиты получает владелец
	# За каждые 3 единицы сниженной брони врага -> получает 1/2/3 защиты (в зависимости от уровня)
	var armor_stacks = int(armor_reduced / 3.0)
	if armor_stacks <= 0:
		return {"success": false, "message": ""}
	
	var armor_per_stack = armor_gain_per_level[level - 1]
	var total_armor_gain = armor_stacks * armor_per_stack
	
	# Добавляем защиту владельцу
	if owner.has_method("add_temporary_defense"):
		owner.add_temporary_defense(total_armor_gain)
	else:
		# Fallback: добавляем напрямую
		owner.defense += total_armor_gain
	
	var message = owner.display_name + " поглощает " + str(total_armor_gain) + " защиты!"
	
	return {
		"success": true,
		"message": message,
		"armor_gained": total_armor_gain
	}

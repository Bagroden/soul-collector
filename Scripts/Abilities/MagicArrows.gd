# res://Scripts/Abilities/MagicArrows.gd
extends PlayerAbility

func _init():
	id = "magic_arrows"
	name = "Магические стрелы"
	description = "Выпускает 1+1 за каждые 15 интеллекта количество стрел. Каждая магическая стрела наносит магический урон = интеллекту."
	cooldown = 0
	mp_cost = 30
	stamina_cost = 0
	damage_type = "magic"

func use_ability(owner: Node, _target: Node = null) -> Dictionary:
	"""Выпускает магические стрелы"""
	if not owner or not "intelligence" in owner:
		return {"success": false, "message": "Нет владельца или интеллекта"}
	
	# Рассчитываем количество стрел: 1 + 1 за каждые 15 интеллекта
	var intelligence = owner.intelligence
	var arrows_count = 1 + int(intelligence / 15)
	
	# Рассчитываем базовый урон от одной стрелы = интеллект
	var base_arrow_damage = intelligence
	
	# Применяем бонус магического урона от интеллекта (1 интеллект = +1% магического урона)
	var magic_damage_bonus = 0.0
	if "magic_damage_bonus" in owner:
		magic_damage_bonus = owner.magic_damage_bonus
	
	var arrow_damage = int(base_arrow_damage * (1.0 + magic_damage_bonus))
	
	# Проверяем критический удар для каждой стрелы
	var total_damage = 0
	var critical_hits = 0
	
	# Определяем шанс критического удара для магического урона
	var crit_chance = 0.0
	if owner.has_method("get_magic_crit_chance"):
		crit_chance = owner.get_magic_crit_chance() / 100.0
	elif "intelligence" in owner:
		var magic_crit = 5 + owner.intelligence  # Базовая формула
		crit_chance = magic_crit / 100.0
	else:
		crit_chance = owner.crit_chance / 100.0 if "crit_chance" in owner else 0.05
	
	for i in range(arrows_count):
		var is_crit = randf() < crit_chance
		var damage = arrow_damage
		
		if is_crit:
			damage = int(damage * 1.5)  # Критический урон
			critical_hits += 1
		
		total_damage += damage
	
	return {
		"success": true,
		"damage": total_damage,
		"is_crit": critical_hits > 0,
		"damage_type": damage_type,
		"message": owner.display_name + " выпускает " + str(arrows_count) + " магических стрел!",
		"magic_arrows": true,  # Флаг для battle_manager
		"arrows_count": arrows_count,
		"arrow_damage": arrow_damage,
		"critical_hits": critical_hits
	}

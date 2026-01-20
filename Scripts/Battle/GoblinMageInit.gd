# res://Scripts/Battle/GoblinMageInit.gd
extends Node2D

# Скрипт инициализации для Гоблина колдуна
func _ready():
	# Настраиваем пассивные способности
	passive_abilities = []
	ability_levels = {}
	
	# Добавляем пассивные способности
	var apprentice_ability = load("res://Scripts/PassiveAbilities/Common/Apprentice.gd").new()
	passive_abilities.append(apprentice_ability)
	ability_levels["apprentice"] = 2  # 2 уровень = +60 к мане
	
	var magic_resistance_ability = load("res://Scripts/PassiveAbilities/Uncommon/MagicResistance.gd").new()
	passive_abilities.append(magic_resistance_ability)
	ability_levels["magic_resistance"] = 2  # 2 уровень = 15% сопротивление магии
	
	var magic_barrier_ability = load("res://Scripts/PassiveAbilities/Rare/MagicBarrier.gd").new()
	passive_abilities.append(magic_barrier_ability)
	ability_levels["magic_barrier"] = 2  # 2 уровень = мудрость * 2.0
	
	var mana_absorption_ability = load("res://Scripts/PassiveAbilities/Uncommon/ManaAbsorption.gd").new()
	passive_abilities.append(mana_absorption_ability)
	ability_levels["mana_absorption"] = 2  # 2 уровень = 10% поглощение маны
	
	var storm_shaman_ability = load("res://Scripts/PassiveAbilities/Rare/StormShaman.gd").new()
	passive_abilities.append(storm_shaman_ability)
	ability_levels["storm_shaman"] = 2  # 2 уровень = 10% шанс молнии
	
	# Применяем пассивные способности через execute_ability
	for ability in passive_abilities:
		ability.execute_ability(self)

# res://Scripts/Abilities/PlayerAbilities.gd
extends Node
class_name PlayerAbilities

var abilities: Dictionary = {}

func _ready():
	_initialize_abilities()

func _initialize_abilities():
	# СПИРИТИЧЕСКИЙ УДАР - магическая способность
	var spiritual_strike = load("res://Scripts/Abilities/SpiritualStrike.gd").new()
	abilities["spiritual_strike"] = spiritual_strike
	
	# КИНЕТИЧЕСКИЙ УДАР - физическая способность
	var kinetic_strike = load("res://Scripts/Abilities/KineticStrike.gd").new()
	abilities["kinetic_strike"] = kinetic_strike
	
	# ВОССТАНОВЛЕНИЕ ДУШИ - лечебная способность
	var soul_restoration = load("res://Scripts/Abilities/SoulRestoration.gd").new()
	abilities["soul_restoration"] = soul_restoration

func get_ability(ability_id: String) -> PlayerAbility:
	"""Получает способность по ID"""
	return abilities.get(ability_id, null)

func get_all_abilities() -> Array[PlayerAbility]:
	"""Получает все доступные способности"""
	var ability_list: Array[PlayerAbility] = []
	for ability in abilities.values():
		ability_list.append(ability)
	return ability_list

func get_available_abilities(character: Node) -> Array[PlayerAbility]:
	"""Получает способности, которые можно использовать"""
	var available: Array[PlayerAbility] = []
	for ability in abilities.values():
		if ability.can_use(character):
			available.append(ability)
	return available

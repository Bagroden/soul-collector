# res://Scripts/PassiveAbilities/Legendary/SilentSong.gd
extends PassiveAbility

func _init():
	id = "silent_song"
	name = "Песнь безмолвия"
	description = "Мышь испускает неслышимые ультразвуки, нарушающие концентрацию врагов. Все заклинания противников имеют шанс 25% не сработать"
	rarity = "legendary"
	ability_type = AbilityType.SPECIAL
	trigger_type = TriggerType.PASSIVE
	value = 25.0  # 25% шанс провала заклинаний

func execute_ability(owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Песнь безмолвия - постоянная способность
	if owner.has_method("add_spell_failure_chance"):
		owner.add_spell_failure_chance(value)
	
	return {
		"success": true,
		"message": owner.display_name + " испускает ультразвуки, нарушающие концентрацию врагов!",
		"effect": "spell_failure"
	}

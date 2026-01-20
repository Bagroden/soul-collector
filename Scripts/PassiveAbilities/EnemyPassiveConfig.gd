# res://Scripts/PassiveAbilities/EnemyPassiveConfig.gd
extends Resource
class_name EnemyPassiveConfig

# Конфигурация пассивных способностей для каждого врага
var enemy_passives: Dictionary = {}

func _init():
	_initialize_enemy_passives()

func _initialize_enemy_passives():
	# КРЫСА - уникальные способности: живучесть + базовые
	enemy_passives["Крыса"] = {
		"common": ["rat_vitality"] as Array[String],
		"uncommon": ["rat_vitality", "dodge"] as Array[String],
		"rare": ["rat_vitality", "dodge", "blood_flow"] as Array[String],
		"epic": ["rat_vitality", "dodge", "blood_flow", "agility"] as Array[String],
		"legendary": ["rat_vitality", "dodge", "blood_flow", "agility", "cornered"] as Array[String]
	}
	
	# МЫШЬ - УДАЛЕНА ИЗ ИГРЫ
	
	# ДЕМОН АЛКАРЫ - полный набор из 5 уникальных способностей
	enemy_passives["AlkaraDemon"] = {
		"common": ["alkara_vampirism"] as Array[String],
		"uncommon": ["alkara_vampirism", "curse_magic"] as Array[String],
		"rare": ["alkara_vampirism", "curse_magic", "alkara_blood_ritual"] as Array[String],
		"epic": ["alkara_vampirism", "curse_magic", "alkara_blood_ritual", "alkara_soul_drain"] as Array[String],
		"legendary": ["alkara_vampirism", "curse_magic", "alkara_blood_ritual", "alkara_soul_drain", "alkara_demon_lord"] as Array[String]
	}
	
	# ДЕМОН ПРОКЛЯТИЯ - полный набор из 5 уникальных способностей
	enemy_passives["CurseDemon"] = {
		"common": ["curse_weakness"] as Array[String],
		"uncommon": ["curse_weakness", "curse_magic"] as Array[String],
		"rare": ["curse_weakness", "curse_magic", "demon_mage"] as Array[String],
		"epic": ["curse_weakness", "curse_magic", "demon_mage", "curse_cursed"] as Array[String],
		"legendary": ["curse_weakness", "curse_magic", "demon_mage", "curse_cursed", "curse_master"] as Array[String]
	}
	
	# ДЕМОН ПАЛАЧ - полный набор из 5 уникальных способностей
	enemy_passives["ExecutionerDemon"] = {
		"common": ["executioner_rage"] as Array[String],
		"uncommon": ["executioner_rage", "demonic_endurance"] as Array[String],
		"rare": ["executioner_rage", "demonic_endurance", "executioner_judgment"] as Array[String],
		"epic": ["executioner_rage", "demonic_endurance", "executioner_guillotine", "executioner_judgment"] as Array[String],
		"legendary": ["executioner_rage", "demonic_endurance", "executioner_guillotine", "executioner_judgment", "executioner_final"] as Array[String]
	}
	
	# ДЕМОН ТАРНОК - полный набор из 5 уникальных способностей
	enemy_passives["TharnokDemon"] = {
		"common": ["tharnok_shield"] as Array[String],
		"uncommon": ["tharnok_shield", "tharnok_armor"] as Array[String],
		"rare": ["tharnok_shield", "tharnok_armor", "demon_vitality"] as Array[String],
		"epic": ["tharnok_shield", "tharnok_armor", "demon_vitality", "tharnok_guardian"] as Array[String],
		"legendary": ["tharnok_shield", "tharnok_armor", "demon_vitality", "tharnok_guardian", "tharnok_mastery"] as Array[String]
	}
	
	# ЖЕЛТЫЙ НИНДЗЯ - УДАЛЕН ИЗ ИГРЫ
	
	# ЛЕТУЧАЯ МЫШЬ - полный набор из 5 уникальных способностей
	enemy_passives["Летучая мышь"] = {
		"common": ["speed"] as Array[String],
		"uncommon": ["speed", "sharp_claws"] as Array[String],
		"rare": ["speed", "sharp_claws", "blood_sucker"] as Array[String],
		"epic": ["speed", "sharp_claws", "blood_sucker", "echolocation"] as Array[String],
		"legendary": ["speed", "sharp_claws", "blood_sucker", "echolocation", "silent_song"] as Array[String]
	}
	
	# СЛИЗЕНЬ - полный набор из 5 уникальных способностей
	enemy_passives["Слизень"] = {
		"common": ["slime_armor"] as Array[String],
		"uncommon": ["slime_armor", "acid_hits"] as Array[String],
		"rare": ["slime_armor", "acid_hits", "slime_regeneration"] as Array[String],
		"epic": ["slime_armor", "acid_hits", "slime_regeneration", "slime_vitality"] as Array[String],
		"legendary": ["slime_armor", "acid_hits", "slime_regeneration", "slime_vitality", "massive"] as Array[String]
	}
	
	# ГНИЛОЙ СЛИЗЕНЬ - босс с теми же способностями что у легендарного слизня + уникальная способность
	enemy_passives["Гнилой слизень"] = {
		"common": ["slime_armor"] as Array[String],
		"uncommon": ["slime_armor", "acid_hits"] as Array[String],
		"rare": ["slime_armor", "acid_hits", "slime_regeneration"] as Array[String],
		"epic": ["slime_armor", "acid_hits", "slime_regeneration", "slime_vitality"] as Array[String],
		"legendary": ["slime_armor", "acid_hits", "slime_regeneration", "slime_vitality", "massive"] as Array[String],
		"boss": ["slime_armor", "acid_hits", "slime_regeneration", "slime_vitality", "massive", "rotten_aura"] as Array[String]
	}
	
	enemy_passives["Тёмный шатун"] = {
		"common": ["shadow_strike"] as Array[String],
		"uncommon": ["shadow_strike", "stealth"] as Array[String],
		"rare": ["shadow_strike", "stealth", "shadow_aura"] as Array[String],
		"epic": ["shadow_strike", "stealth", "shadow_aura", "agility"] as Array[String],
		"legendary": ["shadow_strike", "stealth", "shadow_aura", "agility", "dodge"] as Array[String],
		"boss": ["shadow_strike", "stealth", "shadow_aura", "agility", "dodge", "sharp_claws"] as Array[String]
	}
	
	enemy_passives["Гоблин Воин"] = {
		"common": ["fighter"] as Array[String],
		"uncommon": ["fighter", "restlessness"] as Array[String],
		"rare": ["fighter", "restlessness", "blood_flow"] as Array[String],
		"epic": ["fighter", "restlessness", "blood_flow", "rage"] as Array[String],
		"legendary": ["fighter", "restlessness", "blood_flow", "rage", "revenge"] as Array[String],
		"boss": ["fighter", "restlessness", "blood_flow", "rage", "revenge", "dodge"] as Array[String]
	}
	
	# ГОБЛИН ВОР - уникальные способности: ловкость вора + базовые
	enemy_passives["Гоблин Вор"] = {
		"common": ["thief_agility"] as Array[String],
		"uncommon": ["thief_agility", "dodge"] as Array[String],
		"rare": ["thief_agility", "dodge", "sneaky_strike"] as Array[String],
		"epic": ["thief_agility", "dodge", "sneaky_strike", "neurotoxin"] as Array[String],
		"legendary": ["thief_agility", "dodge", "sneaky_strike", "neurotoxin", "agility"] as Array[String],
		"boss": ["thief_agility", "dodge", "sneaky_strike", "neurotoxin", "agility"] as Array[String]
	}
	
	# ГОБЛИН КОЛДУН - магические способности
	enemy_passives["Гоблин колдун"] = {
		"common": ["apprentice"] as Array[String],
		"uncommon": ["apprentice", "magic_resistance"] as Array[String],
		"rare": ["apprentice", "magic_resistance", "magic_barrier"] as Array[String],
		"epic": ["apprentice", "magic_resistance", "magic_barrier", "mana_absorption"] as Array[String],
		"legendary": ["apprentice", "magic_resistance", "magic_barrier", "mana_absorption", "storm_shaman"] as Array[String],
		"boss": ["apprentice", "magic_resistance", "magic_barrier", "mana_absorption", "storm_shaman"] as Array[String]
	}
	
	# ЗАГЛУШКА - базовые способности
	enemy_passives["Заглушка"] = {
		"common": ["dodge"] as Array[String],
		"uncommon": ["dodge", "quick_strike"] as Array[String],
		"rare": ["dodge", "quick_strike", "blood_flow"] as Array[String],
		"epic": ["dodge", "quick_strike", "blood_flow", "agility"] as Array[String],
		"legendary": ["dodge", "quick_strike", "blood_flow", "agility", "cornered"] as Array[String]
	}
	
	# СКЕЛЕТ АРБАЛЕТЧИК - снайпер с высоким уроном
	enemy_passives["Скелет Арбалетчик"] = {
		"common": ["bone_precision"] as Array[String],
		"uncommon": ["bone_precision", "deadeye"] as Array[String],
		"rare": ["bone_precision", "deadeye", "piercing_bolt"] as Array[String],
		"epic": ["bone_precision", "deadeye", "piercing_bolt", "undead_focus"] as Array[String],
		"legendary": ["bone_precision", "deadeye", "piercing_bolt", "undead_focus", "headshot"] as Array[String]
	}
	
	# СКЕЛЕТ МЕЧНИК - контратакующий дуэлянт
	enemy_passives["Скелет Мечник"] = {
		"common": ["bone_parry"] as Array[String],
		"uncommon": ["bone_parry", "riposte"] as Array[String],
		"rare": ["bone_parry", "riposte", "blade_mastery"] as Array[String],
		"epic": ["bone_parry", "riposte", "blade_mastery", "aggressive_defense"] as Array[String],
		"legendary": ["bone_parry", "riposte", "blade_mastery", "aggressive_defense", "death_dance"] as Array[String]
	}
	
	# ГУЛЬ - вампир-регенератор
	enemy_passives["Гуль"] = {
		"common": ["ghoul_feast"] as Array[String],
		"uncommon": ["ghoul_feast", "rotting_claws"] as Array[String],
		"rare": ["ghoul_feast", "rotting_claws", "corpse_eater"] as Array[String],
		"epic": ["ghoul_feast", "rotting_claws", "corpse_eater", "plague_carrier"] as Array[String],
		"legendary": ["ghoul_feast", "rotting_claws", "corpse_eater", "plague_carrier", "undying_hunger"] as Array[String]
	}
	
	# ЭЛИТНЫЙ СКЕЛЕТ - неумолимый танк
	enemy_passives["Элитный Скелет"] = {
		"common": ["relentless"] as Array[String],
		"uncommon": ["relentless", "heavy_strike"] as Array[String],
		"rare": ["relentless", "heavy_strike", "enchanted_bones"] as Array[String],
		"epic": ["relentless", "heavy_strike", "enchanted_bones", "shatter_bones"] as Array[String],
		"legendary": ["relentless", "heavy_strike", "enchanted_bones", "shatter_bones", "undead_champion"] as Array[String]
	}
	
	# ОРК ЛУЧНИК - дальний боец
	enemy_passives["Орк лучник"] = {
		"common": ["orc_marksmanship"] as Array[String],
		"uncommon": ["orc_marksmanship", "deadeye"] as Array[String],
		"rare": ["orc_marksmanship", "deadeye", "piercing_arrow"] as Array[String],
		"epic": ["orc_marksmanship", "deadeye", "piercing_arrow", "rapid_fire"] as Array[String],
		"legendary": ["orc_marksmanship", "deadeye", "piercing_arrow", "rapid_fire", "bullseye"] as Array[String]
	}
	
	# ОРК УБИЙЦА - скрытный боец
	enemy_passives["Орк убийца"] = {
		"common": ["poison_blade"] as Array[String],
		"uncommon": ["poison_blade", "dodge"] as Array[String],
		"rare": ["poison_blade", "dodge", "backstab"] as Array[String],
		"epic": ["poison_blade", "dodge", "backstab", "stealth"] as Array[String],
		"legendary": ["poison_blade", "dodge", "backstab", "stealth", "assassinate"] as Array[String]
	}
	
	# ОРК БЕРСЕРК - агрессивный боец
	enemy_passives["Орк берсерк"] = {
		"common": ["orc_rage"] as Array[String],
		"uncommon": ["orc_rage", "rage"] as Array[String],
		"rare": ["orc_rage", "rage", "berserker_fury"] as Array[String],
		"epic": ["orc_rage", "rage", "berserker_fury", "ork_vitality"] as Array[String],
		"legendary": ["orc_rage", "rage", "berserker_fury", "ork_vitality", "berserk"] as Array[String]
	}
	
	# ОРК ШАМАН - магический боец
	enemy_passives["Орк шаман"] = {
		"common": ["orc_totem"] as Array[String],
		"uncommon": ["orc_totem", "magic_resistance"] as Array[String],
		"rare": ["orc_totem", "magic_resistance", "spirit_guard"] as Array[String],
		"epic": ["orc_totem", "magic_resistance", "spirit_guard", "ancestral_wisdom"] as Array[String],
		"legendary": ["orc_totem", "magic_resistance", "spirit_guard", "ancestral_wisdom", "shaman_mastery"] as Array[String]
	}
	
	# СКЕЛЕТ ЛОРД - босс кладбища с базовыми способностями элитного скелета + уникальная способность
	enemy_passives["Скелет лорд"] = {
		"common": ["relentless"] as Array[String],
		"uncommon": ["relentless", "heavy_strike"] as Array[String],
		"rare": ["relentless", "heavy_strike", "enchanted_bones"] as Array[String],
		"epic": ["relentless", "heavy_strike", "enchanted_bones", "shatter_bones"] as Array[String],
		"legendary": ["relentless", "heavy_strike", "enchanted_bones", "shatter_bones", "undead_champion"] as Array[String],
		"boss": ["relentless", "heavy_strike", "enchanted_bones", "shatter_bones", "undead_champion", "armor_absorber"] as Array[String]
	}

func get_passives_for_enemy(enemy_name: String, rarity: String) -> Array[String]:
	# Возвращаем список пассивных способностей для конкретного врага и редкости
	if enemy_name in enemy_passives:
		if rarity in enemy_passives[enemy_name]:
			return enemy_passives[enemy_name][rarity]
		else:
			return []
	else:
		return []


func add_enemy_passives(enemy_name: String, rarity: String, passives: Array[String]):
	# Добавляем пассивные способности для врага
	if not enemy_name in enemy_passives:
		enemy_passives[enemy_name] = {}
	
	enemy_passives[enemy_name][rarity] = passives
	print("Добавлены пассивные способности для ", enemy_name, " (", rarity, "): ", passives)

func get_all_enemy_names() -> Array[String]:
	# Возвращаем список всех врагов с конфигурацией
	return enemy_passives.keys()

func get_rarities_for_enemy(enemy_name: String) -> Array[String]:
	# Возвращаем список редкостей для конкретного врага
	if enemy_name in enemy_passives:
		return enemy_passives[enemy_name].keys()
	return []

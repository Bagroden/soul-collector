# res://Scripts/PassiveAbilities/PassiveAbilityManager.gd
extends Node

var abilities: Dictionary = {}
var active_effects: Dictionary = {}
var enemy_config: EnemyPassiveConfig

signal ability_triggered(ability_id: String, owner: Node, target: Node)
signal effect_applied(effect_id: String, target: Node)
signal effect_removed(effect_id: String, target: Node)

func _ready():
	# Инициализируем конфигурацию врагов
	enemy_config = EnemyPassiveConfig.new()
	_initialize_abilities()

func _initialize_abilities():
	# Загружаем все пассивные способности
	_load_common_abilities()
	_load_uncommon_abilities()
	_load_rare_abilities()
	_load_epic_abilities()
	_load_legendary_abilities()
	_load_mythic_abilities()
	_load_boss_abilities()
	_load_player_abilities()
	_load_soul_development_abilities()

func _load_common_abilities():
	# Обычные способности
	var quick_strike = load("res://Scripts/PassiveAbilities/Common/QuickStrike.gd").new()
	abilities["quick_strike"] = quick_strike
	
	# Уникальные способности врагов
	var rat_bite = load("res://Scripts/PassiveAbilities/Common/RatBite.gd").new()
	abilities["rat_bite"] = rat_bite
	
	var restlessness = load("res://Scripts/PassiveAbilities/Common/Restlessness.gd").new()
	abilities["restlessness"] = restlessness
	
	# Гоблин Воин
	var fighter = load("res://Scripts/PassiveAbilities/Common/Fighter.gd").new()
	abilities["fighter"] = fighter
	
	# Гоблин Вор
	var thief_agility = load("res://Scripts/PassiveAbilities/Common/ThiefAgility.gd").new()
	abilities["thief_agility"] = thief_agility
	
	# Подлый удар (Rare)
	var sneaky_strike = load("res://Scripts/PassiveAbilities/Rare/SneakyStrike.gd").new()
	abilities["sneaky_strike"] = sneaky_strike
	
	# Ученик
	var apprentice = load("res://Scripts/PassiveAbilities/Common/Apprentice.gd").new()
	abilities["apprentice"] = apprentice
	
	var speed = load("res://Scripts/PassiveAbilities/Common/Speed.gd").new()
	abilities["speed"] = speed
	
	# Крысиная живучесть
	var rat_vitality = load("res://Scripts/PassiveAbilities/Common/RatVitality.gd").new()
	abilities["rat_vitality"] = rat_vitality
	
	# Проклятие слабости
	var curse_weakness = load("res://Scripts/PassiveAbilities/Common/CurseWeakness.gd").new()
	abilities["curse_weakness"] = curse_weakness
	
	# ExecutionerDemon
	var executioner_rage = load("res://Scripts/PassiveAbilities/Common/ExecutionerRage.gd").new()
	abilities["executioner_rage"] = executioner_rage
	
	# Слизень - Слизистая броня
	var slime_armor = load("res://Scripts/PassiveAbilities/Common/SlimeArmor.gd").new()
	abilities["slime_armor"] = slime_armor

	# Скелет Арбалетчик - Костяная точность
	var bone_precision = load("res://Scripts/PassiveAbilities/Common/BonePrecision.gd").new()
	abilities["bone_precision"] = bone_precision
	
	# Скелет Мечник - Костяное парирование
	var bone_parry = load("res://Scripts/PassiveAbilities/Common/BoneParry.gd").new()
	abilities["bone_parry"] = bone_parry
	
	# Гуль - Пир гуля
	var ghoul_feast = load("res://Scripts/PassiveAbilities/Common/GhoulFeast.gd").new()
	abilities["ghoul_feast"] = ghoul_feast
	
	# Элитный Скелет - Неумолимый
	var relentless = load("res://Scripts/PassiveAbilities/Common/Relentless.gd").new()
	abilities["relentless"] = relentless
	
	# Орк лучник - Точность орка
	var orc_marksmanship = load("res://Scripts/PassiveAbilities/Common/OrcMarksmanship.gd").new()
	abilities["orc_marksmanship"] = orc_marksmanship
	
	# Орк убийца - Отравленный клинок (перемещен из Epic в Common)
	var poison_blade = load("res://Scripts/PassiveAbilities/Common/PoisonBlade.gd").new()
	abilities["poison_blade"] = poison_blade
	
	# Орк берсерк - Сила орка
	var orc_rage = load("res://Scripts/PassiveAbilities/Common/OrcRage.gd").new()
	abilities["orc_rage"] = orc_rage
	
	# Орк шаман - Тотем орка
	var orc_totem = load("res://Scripts/PassiveAbilities/Common/OrcTotem.gd").new()
	abilities["orc_totem"] = orc_totem

func _load_uncommon_abilities():
	# Необычные способности
	var dodge = load("res://Scripts/PassiveAbilities/Uncommon/Dodge.gd").new()
	abilities["dodge"] = dodge
	
	var blood_flow = load("res://Scripts/PassiveAbilities/Uncommon/BloodFlow.gd").new()
	abilities["blood_flow"] = blood_flow
	
	# Уникальные способности врагов
	var alkara_vampirism = load("res://Scripts/PassiveAbilities/Uncommon/AlkaraVampirism.gd").new()
	abilities["alkara_vampirism"] = alkara_vampirism
	
	var curse_magic = load("res://Scripts/PassiveAbilities/Uncommon/CurseMagic.gd").new()
	abilities["curse_magic"] = curse_magic
	
	# Мышь
	var mouse_nimble = load("res://Scripts/PassiveAbilities/Uncommon/MouseNimble.gd").new()
	abilities["mouse_nimble"] = mouse_nimble
	
	# Летучая мышь
	var sharp_claws = load("res://Scripts/PassiveAbilities/Uncommon/SharpClaws.gd").new()
	abilities["sharp_claws"] = sharp_claws
	
	# Слизень - Кислотный след
	var acid_hits = load("res://Scripts/PassiveAbilities/Uncommon/AcidHits.gd").new()
	abilities["acid_hits"] = acid_hits
	
	# CurseDemon
	var demon_mage = load("res://Scripts/PassiveAbilities/Uncommon/DemonMage.gd").new()
	abilities["demon_mage"] = demon_mage
	
	# Гоблин Вор - Подлый удар (перемещен в Rare)
	# var sneaky_strike = load("res://Scripts/PassiveAbilities/Uncommon/SneakyStrike.gd").new()
	# abilities["sneaky_strike"] = sneaky_strike
	
	# Сопротивление магии
	var magic_resistance = load("res://Scripts/PassiveAbilities/Uncommon/MagicResistance.gd").new()
	abilities["magic_resistance"] = magic_resistance
	
	# Поглощение маны (перемещено в Epic)
	# var mana_absorption = load("res://Scripts/PassiveAbilities/Uncommon/ManaAbsorption.gd").new()
	# abilities["mana_absorption"] = mana_absorption
	
	# ExecutionerDemon
	var demonic_endurance = load("res://Scripts/PassiveAbilities/Uncommon/DemonicEndurance.gd").new()
	abilities["demonic_endurance"] = demonic_endurance
	
	# Скелет Арбалетчик - Мертвый глаз
	var deadeye = load("res://Scripts/PassiveAbilities/Uncommon/Deadeye.gd").new()
	abilities["deadeye"] = deadeye
	
	# Скелет Мечник - Ответный удар
	var riposte = load("res://Scripts/PassiveAbilities/Uncommon/Riposte.gd").new()
	abilities["riposte"] = riposte
	
	# Гуль - Гнилые когти
	var rotting_claws = load("res://Scripts/PassiveAbilities/Uncommon/RottingClaws.gd").new()
	abilities["rotting_claws"] = rotting_claws
	
	# Элитный Скелет - Тяжелый удар
	var heavy_strike = load("res://Scripts/PassiveAbilities/Uncommon/HeavyStrike.gd").new()
	abilities["heavy_strike"] = heavy_strike
	
	# Орк лучник использует deadeye (уже загружен выше)
	# Орк убийца использует dodge (уже загружен выше)
	# Орк берсерк использует rage (загружается ниже в Epic, но это общая способность)
	# Орк шаман использует magic_resistance (уже загружен выше)

func _load_rare_abilities():
	# Редкие способности
	
	var tharnok_shield = load("res://Scripts/PassiveAbilities/Rare/TharnokShield.gd").new()
	abilities["tharnok_shield"] = tharnok_shield
	
	# Гоблин Воин
	var revenge = load("res://Scripts/PassiveAbilities/Rare/Revenge.gd").new()
	abilities["revenge"] = revenge
	
	# Магический барьер
	var magic_barrier = load("res://Scripts/PassiveAbilities/Rare/MagicBarrier.gd").new()
	abilities["magic_barrier"] = magic_barrier
	
	# Шаман бурь (перемещен в Legendary)
	# var storm_shaman = load("res://Scripts/PassiveAbilities/Rare/StormShaman.gd").new()
	# abilities["storm_shaman"] = storm_shaman
	
	# Летучая мышь
	var blood_sucker = load("res://Scripts/PassiveAbilities/Rare/BloodSucker.gd").new()
	abilities["blood_sucker"] = blood_sucker
	
	# Мышь
	var infection = load("res://Scripts/PassiveAbilities/Rare/Infection.gd").new()
	abilities["infection"] = infection
	
	# Слизень - Регенерация слизи
	var slime_regeneration = load("res://Scripts/PassiveAbilities/Rare/SlimeRegeneration.gd").new()
	abilities["slime_regeneration"] = slime_regeneration
	
	# Гоблин Вор - Нейротоксин (перемещен в Legendary)
	# var neurotoxin = load("res://Scripts/PassiveAbilities/Rare/Neurotoxin.gd").new()
	# abilities["neurotoxin"] = neurotoxin
	
	# AlkaraDemon
	var alkara_blood_ritual = load("res://Scripts/PassiveAbilities/Rare/AlkaraBloodRitual.gd").new()
	abilities["alkara_blood_ritual"] = alkara_blood_ritual
	
	
	
	# TharnokDemon
	var tharnok_armor = load("res://Scripts/PassiveAbilities/Rare/TharnokArmor.gd").new()
	abilities["tharnok_armor"] = tharnok_armor
	
	# YellowNinja
	var ninja_assassinate = load("res://Scripts/PassiveAbilities/Rare/NinjaAssassinate.gd").new()
	abilities["ninja_assassinate"] = ninja_assassinate
	
	# Скелет Арбалетчик - Пробивающий болт
	var piercing_bolt = load("res://Scripts/PassiveAbilities/Rare/PiercingBolt.gd").new()
	abilities["piercing_bolt"] = piercing_bolt
	
	# Скелет Мечник - Мастерство клинка
	var blade_mastery = load("res://Scripts/PassiveAbilities/Rare/BladeMastery.gd").new()
	abilities["blade_mastery"] = blade_mastery
	
	# Гуль - Пожиратель трупов
	var corpse_eater = load("res://Scripts/PassiveAbilities/Rare/CorpseEater.gd").new()
	abilities["corpse_eater"] = corpse_eater
	
	# Элитный Скелет - Зачарованные кости
	var enchanted_bones = load("res://Scripts/PassiveAbilities/Rare/EnchantedBones.gd").new()
	abilities["enchanted_bones"] = enchanted_bones
	
	# Орк лучник - Пробивающая стрела
	var piercing_arrow = load("res://Scripts/PassiveAbilities/Rare/PiercingArrow.gd").new()
	abilities["piercing_arrow"] = piercing_arrow
	
	# Орк убийца - Удар в спину
	var backstab = load("res://Scripts/PassiveAbilities/Rare/Backstab.gd").new()
	abilities["backstab"] = backstab
	
	# Орк берсерк - Боевое безумие
	var berserker_fury = load("res://Scripts/PassiveAbilities/Rare/BerserkerFury.gd").new()
	abilities["berserker_fury"] = berserker_fury
	
	# Орк шаман - Духовный страж
	var spirit_guard = load("res://Scripts/PassiveAbilities/Rare/SpiritGuard.gd").new()
	abilities["spirit_guard"] = spirit_guard

func _load_epic_abilities():
	# Эпические способности
	var life_steal = load("res://Scripts/PassiveAbilities/Epic/LifeSteal.gd").new()
	abilities["life_steal"] = life_steal
	
	var blood_bleeding = load("res://Scripts/PassiveAbilities/Epic/BloodBleeding.gd").new()
	abilities["blood_bleeding"] = blood_bleeding
	
	var agility = load("res://Scripts/PassiveAbilities/Epic/Agility.gd").new()
	abilities["agility"] = agility
	
	# Гоблин Воин и Орк берсерк - Ярость (uncommon способность, но используется в epic конфигурации)
	var rage = load("res://Scripts/PassiveAbilities/Uncommon/Rage.gd").new()
	abilities["rage"] = rage
	
	# Уникальные способности врагов
	var ninja_shadow = load("res://Scripts/PassiveAbilities/Epic/NinjaShadow.gd").new()
	abilities["ninja_shadow"] = ninja_shadow
	
	# Слизень - Кислотный взрыв
	var slime_vitality = load("res://Scripts/PassiveAbilities/Epic/SlimeVitality.gd").new()
	abilities["slime_vitality"] = slime_vitality
	
	# Поглощение маны (Epic)
	var mana_absorption = load("res://Scripts/PassiveAbilities/Epic/ManaAbsorption.gd").new()
	abilities["mana_absorption"] = mana_absorption
	
	var ninja_shadow_strike = load("res://Scripts/PassiveAbilities/Epic/NinjaShadowStrike.gd").new()
	abilities["ninja_shadow_strike"] = ninja_shadow_strike
	
	# Мышь
	var mouse_pack = load("res://Scripts/PassiveAbilities/Epic/MousePack.gd").new()
	abilities["mouse_pack"] = mouse_pack
	
	# Летучая мышь
	var echolocation = load("res://Scripts/PassiveAbilities/Epic/Echolocation.gd").new()
	abilities["echolocation"] = echolocation
	
	# AlkaraDemon
	var alkara_soul_drain = load("res://Scripts/PassiveAbilities/Epic/AlkaraSoulDrain.gd").new()
	abilities["alkara_soul_drain"] = alkara_soul_drain
	
	# CurseDemon
	var curse_cursed = load("res://Scripts/PassiveAbilities/Epic/CurseCursed.gd").new()
	abilities["curse_cursed"] = curse_cursed
	
	# ExecutionerDemon
	var executioner_judgment = load("res://Scripts/PassiveAbilities/Rare/ExecutionerJudgment.gd").new()
	abilities["executioner_judgment"] = executioner_judgment
	
	
	# TharnokDemon
	var demon_vitality = load("res://Scripts/PassiveAbilities/Epic/DemonVitality.gd").new()
	abilities["demon_vitality"] = demon_vitality
	
	# YellowNinja
	var ninja_lethality = load("res://Scripts/PassiveAbilities/Epic/NinjaLethality.gd").new()
	abilities["ninja_lethality"] = ninja_lethality
	
	# Слизень - Слизистый король
	var massive = load("res://Scripts/PassiveAbilities/Legendary/Massive.gd").new()
	abilities["massive"] = massive
	
	# Скелет Арбалетчик - Нежить фокус
	var undead_focus = load("res://Scripts/PassiveAbilities/Epic/UndeadFocus.gd").new()
	abilities["undead_focus"] = undead_focus
	
	# Скелет Мечник - Агрессивная защита
	var aggressive_defense = load("res://Scripts/PassiveAbilities/Epic/AggressiveDefense.gd").new()
	abilities["aggressive_defense"] = aggressive_defense
	
	# Гуль - Носитель чумы
	var plague_carrier = load("res://Scripts/PassiveAbilities/Epic/PlagueCarrier.gd").new()
	abilities["plague_carrier"] = plague_carrier
	
	# Элитный Скелет - Раздробление костей
	var shatter_bones = load("res://Scripts/PassiveAbilities/Epic/ShatterBones.gd").new()
	abilities["shatter_bones"] = shatter_bones
	
	# Орк лучник - Быстрая стрельба
	var rapid_fire = load("res://Scripts/PassiveAbilities/Epic/RapidFire.gd").new()
	abilities["rapid_fire"] = rapid_fire
	
	# Орк убийца - Скрытность (Epic версия)
	var stealth = load("res://Scripts/PassiveAbilities/Epic/Stealth.gd").new()
	abilities["stealth"] = stealth
	
	# Орк берсерк - Выносливость орка
	var ork_vitality = load("res://Scripts/PassiveAbilities/Epic/Bloodthirst.gd").new()
	abilities["ork_vitality"] = ork_vitality
	
	# Орк шаман - Мудрость предков
	var ancestral_wisdom = load("res://Scripts/PassiveAbilities/Epic/AncestralWisdom.gd").new()
	abilities["ancestral_wisdom"] = ancestral_wisdom

func _load_legendary_abilities():
	# Легендарные способности
	var cornered = load("res://Scripts/PassiveAbilities/Legendary/Cornered.gd").new()
	abilities["cornered"] = cornered
	
	# Уникальные способности врагов
	# Мышь
	var mouse_king = load("res://Scripts/PassiveAbilities/Legendary/MouseKing.gd").new()
	abilities["mouse_king"] = mouse_king
	
	# Летучая мышь
	var silent_song = load("res://Scripts/PassiveAbilities/Legendary/SilentSong.gd").new()
	abilities["silent_song"] = silent_song
	
	# AlkaraDemon
	var alkara_demon_lord = load("res://Scripts/PassiveAbilities/Legendary/AlkaraDemonLord.gd").new()
	abilities["alkara_demon_lord"] = alkara_demon_lord
	
	# CurseDemon
	var curse_master = load("res://Scripts/PassiveAbilities/Legendary/CurseMaster.gd").new()
	abilities["curse_master"] = curse_master
	
	# ExecutionerDemon
	var executioner_final = load("res://Scripts/PassiveAbilities/Legendary/ExecutionerFinal.gd").new()
	abilities["executioner_final"] = executioner_final
	
	# TharnokDemon
	var tharnok_guardian = load("res://Scripts/PassiveAbilities/Legendary/TharnokGuardian.gd").new()
	abilities["tharnok_guardian"] = tharnok_guardian
	
	# Гоблин Колдун - Шаман бурь (легендарная способность)
	var storm_shaman = load("res://Scripts/PassiveAbilities/Legendary/StormShaman.gd").new()
	abilities["storm_shaman"] = storm_shaman
	
	# Гоблин Вор - Нейротоксин (легендарная способность)
	var neurotoxin = load("res://Scripts/PassiveAbilities/Legendary/Neurotoxin.gd").new()
	abilities["neurotoxin"] = neurotoxin
	
	var tharnok_mastery = load("res://Scripts/PassiveAbilities/Legendary/TharnokMastery.gd").new()
	abilities["tharnok_mastery"] = tharnok_mastery
	
	# YellowNinja
	var ninja_master = load("res://Scripts/PassiveAbilities/Legendary/NinjaMaster.gd").new()
	abilities["ninja_master"] = ninja_master
	
	# Скелет Арбалетчик - Выстрел в голову
	var headshot = load("res://Scripts/PassiveAbilities/Legendary/Headshot.gd").new()
	abilities["headshot"] = headshot
	
	# Скелет Мечник - Танец смерти
	var death_dance = load("res://Scripts/PassiveAbilities/Legendary/DeathDance.gd").new()
	abilities["death_dance"] = death_dance
	
	# Гуль - Неугасимый голод
	var undying_hunger = load("res://Scripts/PassiveAbilities/Legendary/UndyingHunger.gd").new()
	abilities["undying_hunger"] = undying_hunger
	
	# Элитный Скелет - Чемпион нежити
	var undead_champion = load("res://Scripts/PassiveAbilities/Legendary/UndeadChampion.gd").new()
	abilities["undead_champion"] = undead_champion
	
	# Орк лучник - Попадание в яблочко
	var bullseye = load("res://Scripts/PassiveAbilities/Legendary/Bullseye.gd").new()
	abilities["bullseye"] = bullseye
	
	# Орк убийца - Убийство
	var assassinate = load("res://Scripts/PassiveAbilities/Legendary/Assassinate.gd").new()
	abilities["assassinate"] = assassinate
	
	# Орк берсерк - Берсерк
	var berserk = load("res://Scripts/PassiveAbilities/Legendary/BerserkerRampage.gd").new()
	abilities["berserk"] = berserk
	
	# Орк шаман - Мастерство шамана
	var shaman_mastery = load("res://Scripts/PassiveAbilities/Legendary/ShamanMastery.gd").new()
	abilities["shaman_mastery"] = shaman_mastery

func _load_mythic_abilities():
	# Мифические способности
	pass

func _load_boss_abilities():
	# Способности боссов
	# Гнилой слизень
	var rotten_aura = load("res://Scripts/PassiveAbilities/Boss/RottenAura.gd").new()
	abilities["rotten_aura"] = rotten_aura
	
	# Тёмный шатун
	var shadow_strike = load("res://Scripts/PassiveAbilities/Boss/ShadowStrike.gd").new()
	abilities["shadow_strike"] = shadow_strike
	
	var shadow_aura = load("res://Scripts/PassiveAbilities/Boss/ShadowAura.gd").new()
	abilities["shadow_aura"] = shadow_aura
	
	var stealth = load("res://Scripts/PassiveAbilities/Boss/Stealth.gd").new()
	abilities["stealth"] = stealth
	
	# Скелет лорд
	var armor_absorber = load("res://Scripts/PassiveAbilities/Boss/ArmorAbsorber.gd").new()
	abilities["armor_absorber"] = armor_absorber

func get_ability(ability_id: String) -> PassiveAbility:
	return abilities.get(ability_id, null)

func get_abilities_by_rarity(rarity: String) -> Array[PassiveAbility]:
	var result: Array[PassiveAbility] = []
	for ability in abilities.values():
		if ability.rarity == rarity:
			result.append(ability)
	return result

func get_abilities_by_type(ability_type: PassiveAbility.AbilityType) -> Array[PassiveAbility]:
	var result: Array[PassiveAbility] = []
	for ability in abilities.values():
		if ability.ability_type == ability_type:
			result.append(ability)
	return result

func trigger_ability(ability_id: String, character: Node, target: Node = null, context: Dictionary = {}) -> Dictionary:
	var ability = get_ability(ability_id)
	if not ability:
		return {"success": false, "message": "Ability not found"}
	
	var result = ability.trigger(character, target, context)
	if result.get("success", false):
		emit_signal("ability_triggered", ability_id, character, target)
	
	return result

func apply_effect(effect_id: String, target: Node, duration: float = 0.0) -> void:
	if not target.has_method("add_effect"):
		print("Target doesn't support effects")
		return
	
	target.add_effect(effect_id, duration)
	active_effects[effect_id] = target
	emit_signal("effect_applied", effect_id, target)

func remove_effect(effect_id: String) -> void:
	if effect_id in active_effects:
		var target = active_effects[effect_id]
		if is_instance_valid(target) and target.has_method("remove_effect"):
			target.remove_effect(effect_id)
		active_effects.erase(effect_id)
		emit_signal("effect_removed", effect_id, target)

func get_random_ability_for_rarity(rarity: String) -> PassiveAbility:
	var available_abilities = get_abilities_by_rarity(rarity)
	if available_abilities.is_empty():
		return null
	
	return available_abilities[randi() % available_abilities.size()]

func get_weighted_random_ability(rarity: String) -> PassiveAbility:
	var weights = {
		"common": 50,
		"uncommon": 25,
		"rare": 15,
		"epic": 8,
		"legendary": 2
	}
	
	var total_weight = weights.get(rarity, 0)
	if total_weight == 0:
		return null
	
	var random_roll = randi() % total_weight
	var current_weight = 0
	
	for ability in abilities.values():
		if ability.rarity == rarity:
			current_weight += 1
			if random_roll < current_weight:
				return ability
	
	return null

func get_passives_for_enemy(enemy_name: String, rarity: String) -> Array[PassiveAbility]:
	# Получаем пассивные способности для конкретного врага и редкости
	var passive_ids = enemy_config.get_passives_for_enemy(enemy_name, rarity)
	var result: Array[PassiveAbility] = []
	
	for passive_id in passive_ids:
		var ability = get_ability(passive_id)
		if ability:
			result.append(ability)
		else:
			print("ОШИБКА: Не найдена пассивная способность: ", passive_id)
	
	return result

func add_passives_to_character(character: Node, enemy_name: String, rarity: String):
	# Добавляем пассивные способности персонажу
	
	# Проверяем, является ли враг элитным
	var is_elite = rarity.begins_with("elite_")
	var base_rarity = rarity
	
	if is_elite:
		# Извлекаем базовую редкость (rare, epic или legendary)
		base_rarity = rarity.substr(6)  # Убираем "elite_"
		print("DEBUG: Элитный враг обнаружен! Базовая редкость: ", base_rarity)
	
	var passives = get_passives_for_enemy(enemy_name, base_rarity)
	
	for passive in passives:
		if character.has_method("add_passive_ability"):
			# Определяем уровень способности на основе уровня врага
			var enemy_level = character.level if "level" in character else 1
			var ability_level = _get_ability_level_for_enemy_level(enemy_level, rarity)
			character.add_passive_ability(passive, ability_level)
		else:
			print("ОШИБКА: Персонаж не имеет метода add_passive_ability")
	
	# Если враг элитный, добавляем дополнительные случайные пассивки
	if is_elite:
		var num_extra_passives = randi() % 2 + 1  # 1 или 2
		print("DEBUG: Добавляем ", num_extra_passives, " дополнительных пассивных способностей")
		
		for i in range(num_extra_passives):
			var extra_passive = _get_random_passive_from_other_enemies(enemy_name)
			if extra_passive and character.has_method("add_passive_ability"):
				var enemy_level = character.level if "level" in character else 1
				var ability_level = _get_ability_level_for_enemy_level(enemy_level, rarity)
				character.add_passive_ability(extra_passive, ability_level)
				print("DEBUG: Добавлена дополнительная способность: ", extra_passive.name)

func _get_random_passive_from_other_enemies(exclude_enemy_name: String) -> PassiveAbility:
	"""Получает случайную пассивную способность от других врагов (не боссов и не текущего врага)"""
	
	# Получаем все пассивки врагов
	var all_enemy_passives = []
	
	for enemy_name in enemy_config.enemy_passives.keys():
		# Пропускаем текущего врага и боссов
		if enemy_name == exclude_enemy_name:
			continue
		
		# Пропускаем боссов (проверяем наличие редкости "boss")
		var enemy_data = enemy_config.enemy_passives[enemy_name]
		if "boss" in enemy_data and not enemy_data["boss"].is_empty():
			# Это босс, пропускаем
			continue
		
		# Собираем все уникальные пассивки этого врага
		for rarity_key in enemy_data.keys():
			if rarity_key != "boss":  # Не берем пассивки уровня босса
				var passives_list = enemy_data[rarity_key]
				for passive_id in passives_list:
					if passive_id not in all_enemy_passives:
						all_enemy_passives.append(passive_id)
	
	# Выбираем случайную пассивку
	if all_enemy_passives.is_empty():
		print("ПРЕДУПРЕЖДЕНИЕ: Нет доступных пассивных способностей для выбора")
		return null
	
	var random_passive_id = all_enemy_passives[randi() % all_enemy_passives.size()]
	return get_ability(random_passive_id)

func _get_ability_level_for_enemy_level(enemy_level: int, rarity: String) -> int:
	"""Определяет уровень способности на основе уровня врага согласно документации"""
	# Минибоссы, боссы и мифические враги всегда имеют максимальный уровень (3)
	if rarity in ["boss", "mythic"]:
		return 3
	
	# Определяем уровень способности на основе уровня врага
	if enemy_level <= 10:
		# 1-10 уровень: обычно 1 уровень пассивок, редко 2, никогда 3
		# 80% шанс на уровень 1, 20% на уровень 2
		var rand = randi() % 100
		return 2 if rand < 20 else 1
	elif enemy_level <= 20:
		# 11-20 уровень: обычно 2 уровень пассивок, реже 1 или 3
		# 20% шанс на уровень 1, 60% на уровень 2, 20% на уровень 3
		var rand = randi() % 100
		if rand < 20:
			return 1
		elif rand < 80:
			return 2
		else:
			return 3
	elif enemy_level <= 30:
		# 21-30 уровень: обычно 3 уровень пассивок, реже 2, никогда 1
		# 25% шанс на уровень 2, 75% на уровень 3
		var rand = randi() % 100
		return 2 if rand < 25 else 3
	else:
		# 31-50 уровень: обычно 3 уровень пассивок, все реже 2
		# 10% шанс на уровень 2, 90% на уровень 3
		var rand = randi() % 100
		return 2 if rand < 10 else 3

func _load_player_abilities():
	"""Загружаем пассивные способности для игрока"""
	
	# Пассивные способности игрока
	
	# Крысиная живучесть (rat_vitality) - уже загружена в _load_common_abilities()
	
	# Новые способности, изученные от врагов
	# Кровоток (blood_flow) - используется оригинальная способность врага
	
	# Изворотливость (agility) - используется оригинальная способность врага
	
	# Загнанный в угол (player_cornered)
	var player_cornered = load("res://Scripts/PassiveAbilities/Player/PlayerCornered.gd").new()
	abilities["player_cornered"] = player_cornered
	
	# Крысиная живучесть (player_rat_vitality) - изучена от крыс
	var player_rat_vitality = load("res://Scripts/PassiveAbilities/Player/PlayerRatVitality.gd").new()
	abilities["player_rat_vitality"] = player_rat_vitality

func _load_soul_development_abilities():
	"""Загружает способности развития души"""
	# Улучшения эффективности восстановления души (6 уровней)
	var rest_eff_1 = load("res://Scripts/PassiveAbilities/SoulDevelopment/RestorationEfficiency1.gd").new()
	abilities["soul_restoration_efficiency_1"] = rest_eff_1
	
	var rest_eff_2 = load("res://Scripts/PassiveAbilities/SoulDevelopment/RestorationEfficiency2.gd").new()
	abilities["soul_restoration_efficiency_2"] = rest_eff_2
	
	var rest_eff_3 = load("res://Scripts/PassiveAbilities/SoulDevelopment/RestorationEfficiency3.gd").new()
	abilities["soul_restoration_efficiency_3"] = rest_eff_3
	
	var rest_eff_4 = load("res://Scripts/PassiveAbilities/SoulDevelopment/RestorationEfficiency4.gd").new()
	abilities["soul_restoration_efficiency_4"] = rest_eff_4
	
	var rest_eff_5 = load("res://Scripts/PassiveAbilities/SoulDevelopment/RestorationEfficiency5.gd").new()
	abilities["soul_restoration_efficiency_5"] = rest_eff_5
	
	var rest_eff_6 = load("res://Scripts/PassiveAbilities/SoulDevelopment/RestorationEfficiency6.gd").new()
	abilities["soul_restoration_efficiency_6"] = rest_eff_6
	
	# Улучшения зарядов восстановления души (6 уровней)
	var rest_charges_1 = load("res://Scripts/PassiveAbilities/SoulDevelopment/RestorationCharges1.gd").new()
	abilities["soul_restoration_charges_1"] = rest_charges_1
	
	var rest_charges_2 = load("res://Scripts/PassiveAbilities/SoulDevelopment/RestorationCharges2.gd").new()
	abilities["soul_restoration_charges_2"] = rest_charges_2
	
	var rest_charges_3 = load("res://Scripts/PassiveAbilities/SoulDevelopment/RestorationCharges3.gd").new()
	abilities["soul_restoration_charges_3"] = rest_charges_3
	
	var rest_charges_4 = load("res://Scripts/PassiveAbilities/SoulDevelopment/RestorationCharges4.gd").new()
	abilities["soul_restoration_charges_4"] = rest_charges_4
	
	var rest_charges_5 = load("res://Scripts/PassiveAbilities/SoulDevelopment/RestorationCharges5.gd").new()
	abilities["soul_restoration_charges_5"] = rest_charges_5
	
	var rest_charges_6 = load("res://Scripts/PassiveAbilities/SoulDevelopment/RestorationCharges6.gd").new()
	abilities["soul_restoration_charges_6"] = rest_charges_6
	
	# Улучшения барьера при восстановлении души (6 уровней)
	var rest_barrier_1 = load("res://Scripts/PassiveAbilities/SoulDevelopment/RestorationBarrier1.gd").new()
	abilities["soul_restoration_barrier_1"] = rest_barrier_1
	
	var rest_barrier_2 = load("res://Scripts/PassiveAbilities/SoulDevelopment/RestorationBarrier2.gd").new()
	abilities["soul_restoration_barrier_2"] = rest_barrier_2
	
	var rest_barrier_3 = load("res://Scripts/PassiveAbilities/SoulDevelopment/RestorationBarrier3.gd").new()
	abilities["soul_restoration_barrier_3"] = rest_barrier_3
	
	var rest_barrier_4 = load("res://Scripts/PassiveAbilities/SoulDevelopment/RestorationBarrier4.gd").new()
	abilities["soul_restoration_barrier_4"] = rest_barrier_4
	
	var rest_barrier_5 = load("res://Scripts/PassiveAbilities/SoulDevelopment/RestorationBarrier5.gd").new()
	abilities["soul_restoration_barrier_5"] = rest_barrier_5
	
	var rest_barrier_6 = load("res://Scripts/PassiveAbilities/SoulDevelopment/RestorationBarrier6.gd").new()
	abilities["soul_restoration_barrier_6"] = rest_barrier_6
	
	# Улучшения духовной мощи (5 уровней)
	var spiritual_power_1 = load("res://Scripts/PassiveAbilities/SoulDevelopment/SpiritualPower1.gd").new()
	abilities["spiritual_power_upgrade_1"] = spiritual_power_1
	
	var spiritual_power_2 = load("res://Scripts/PassiveAbilities/SoulDevelopment/SpiritualPower2.gd").new()
	abilities["spiritual_power_upgrade_2"] = spiritual_power_2
	
	var spiritual_power_3 = load("res://Scripts/PassiveAbilities/SoulDevelopment/SpiritualPower3.gd").new()
	abilities["spiritual_power_upgrade_3"] = spiritual_power_3
	
	var spiritual_power_4 = load("res://Scripts/PassiveAbilities/SoulDevelopment/SpiritualPower4.gd").new()
	abilities["spiritual_power_upgrade_4"] = spiritual_power_4
	
	var spiritual_power_5 = load("res://Scripts/PassiveAbilities/SoulDevelopment/SpiritualPower5.gd").new()
	abilities["spiritual_power_upgrade_5"] = spiritual_power_5
	
	# Способность "Видящий" (3 уровня)
	var seer_1 = load("res://Scripts/PassiveAbilities/SoulDevelopment/Seer1.gd").new()
	abilities["seer_1"] = seer_1
	
	var seer_2 = load("res://Scripts/PassiveAbilities/SoulDevelopment/Seer2.gd").new()
	abilities["seer_2"] = seer_2
	
	var seer_3 = load("res://Scripts/PassiveAbilities/SoulDevelopment/Seer3.gd").new()
	abilities["seer_3"] = seer_3

func get_all_abilities() -> Array[PassiveAbility]:
	"""Возвращает все доступные пассивные способности"""
	var result: Array[PassiveAbility] = []
	for ability in abilities.values():
		result.append(ability)
	return result

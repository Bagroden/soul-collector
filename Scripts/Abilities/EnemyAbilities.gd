# res://Scripts/Abilities/EnemyAbilities.gd
extends Node
class_name EnemyAbilities

# Словарь способностей для каждого типа врага
var enemy_abilities: Dictionary = {}

func _init():
	_initialize_abilities()

func _initialize_abilities():
	# КРЫСА - физическая способность
	var rat_ability = EnemyAbility.new()
	rat_ability.id = "rat_bite"
	rat_ability.name = "Крысиный укус"
	rat_ability.description = "Быстрая атака с шансом кровотечения. Урон = сила + ловкость * 1.5. 50% шанс кровотечения."
	rat_ability.damage_type = "physical"
	rat_ability.base_damage = 0  # Урон рассчитывается динамически
	rat_ability.stamina_cost = 35
	rat_ability.cooldown = 2  # Перезарядка 1 ход (cooldown = 2 означает пропустить 1 ход врага)
	rat_ability.crit_chance_bonus = 0.0
	rat_ability.damage_multiplier = 1.0
	enemy_abilities["Крыса"] = rat_ability
	
	# МЫШЬ - физическая способность
	var mouse_ability = EnemyAbility.new()
	mouse_ability.id = "mouse_swarm"
	mouse_ability.name = "Мышиная стая"
	mouse_ability.description = "Быстрая атака с шансом двойного удара"
	mouse_ability.damage_type = "physical"
	mouse_ability.base_damage = 6
	mouse_ability.stamina_cost = 20
	mouse_ability.crit_chance_bonus = 15.0
	mouse_ability.damage_multiplier = 1.0
	enemy_abilities["Мышь"] = mouse_ability
	
	# АЛКАР ДЕМОН - магическая способность
	var alkara_ability = EnemyAbility.new()
	alkara_ability.id = "alkara_dark_blast"
	alkara_ability.name = "Темный взрыв"
	alkara_ability.description = "Мощная магическая атака с вампиризмом. Урон = интеллект * 2.5. Восстанавливает 50% нанесенного урона."
	alkara_ability.damage_type = "magic"
	alkara_ability.base_damage = 0  # Урон рассчитывается динамически
	alkara_ability.mp_cost = 75
	alkara_ability.cooldown = 4  # Перезарядка 3 хода (cooldown = 4 означает пропустить 3 хода врага)
	alkara_ability.crit_chance_bonus = 5.0
	alkara_ability.damage_multiplier = 1.0
	enemy_abilities["AlkaraDemon"] = alkara_ability
	
	# ДЕМОН ПРОКЛЯТИЯ - магическая способность
	var curse_ability = EnemyAbility.new()
	curse_ability.id = "curse_blast"
	curse_ability.name = "Проклятый взрыв"
	curse_ability.description = "Магическая атака с шансом проклятия. Урон = интеллект + мудрость * 1.3. 30% шанс проклятия."
	curse_ability.damage_type = "magic"
	curse_ability.base_damage = 0  # Урон рассчитывается динамически
	curse_ability.mp_cost = 50
	curse_ability.cooldown = 3  # Перезарядка 2 хода (cooldown = 3 означает пропустить 2 хода врага)
	curse_ability.crit_chance_bonus = 0.0
	curse_ability.damage_multiplier = 1.0
	enemy_abilities["CurseDemon"] = curse_ability
	
	# СЛИЗЕНЬ - физическая способность
	var slime_ability = EnemyAbility.new()
	slime_ability.id = "slime_acid_blast"
	slime_ability.name = "Кислотный взрыв"
	slime_ability.description = "Мощная кислотная атака. Урон = сила + живучесть. Снижает броню цели на 5."
	slime_ability.damage_type = "physical"
	slime_ability.base_damage = 0  # Урон рассчитывается динамически
	slime_ability.stamina_cost = 30
	slime_ability.cooldown = 4  # Перезарядка 3 хода (cooldown = 4 означает пропустить 3 хода врага)
	slime_ability.crit_chance_bonus = 0.0
	slime_ability.damage_multiplier = 1.0
	enemy_abilities["Слизень"] = slime_ability
	
	# ГНИЛОЙ СЛИЗЕНЬ - физическая способность
	var rotten_slime_ability = EnemyAbility.new()
	rotten_slime_ability.id = "rotten_slime_blast"
	rotten_slime_ability.name = "Гнилостный взрыв"
	rotten_slime_ability.description = "Мощная атака с гнилью. Урон = (сила + живучесть) / 2 + P. Вызывает внеочередное срабатывание гнилостной ауры."
	rotten_slime_ability.damage_type = "physical"
	rotten_slime_ability.base_damage = 0  # Урон рассчитывается динамически
	rotten_slime_ability.stamina_cost = 30
	rotten_slime_ability.cooldown = 4  # Перезарядка 3 хода (cooldown = 4 означает пропустить 3 хода врага)
	rotten_slime_ability.crit_chance_bonus = 0.0
	rotten_slime_ability.damage_multiplier = 1.0
	enemy_abilities["Гнилой слизень"] = rotten_slime_ability
	
	# ДЕМОН ПАЛАЧ - физическая способность (два удара)
	var executioner_ability = EnemyAbility.new()
	executioner_ability.id = "executioner_strike"
	executioner_ability.name = "Удар палача"
	executioner_ability.description = "Два разрушительных удара - рубящий и колющий. Урон каждого удара = сила + ловкость * 1.5. +20% к шансу крита для каждого удара. Каждый удар проверяется отдельно на уворот."
	executioner_ability.damage_type = "physical"
	executioner_ability.base_damage = 0  # Урон рассчитывается динамически
	executioner_ability.stamina_cost = 70
	executioner_ability.cooldown = 5  # Перезарядка 4 хода (cooldown = 5 означает пропустить 4 хода врага)
	executioner_ability.crit_chance_bonus = 20.0
	executioner_ability.damage_multiplier = 1.0
	enemy_abilities["ExecutionerDemon"] = executioner_ability
	
	# ДЕМОН ТАРНОК - физическая способность (два удара)
	var tharnok_ability = EnemyAbility.new()
	tharnok_ability.id = "tharnok_crushing_strike"
	tharnok_ability.name = "Сокрушающий удар"
	tharnok_ability.description = "Два сокрушающих удара - обычный и усиленный. Первый удар = сила + живучесть. Второй удар = сила + живучесть * 1.7. 30% шанс оглушить на втором ударе. Каждый удар проверяется отдельно на уворот."
	tharnok_ability.damage_type = "physical"
	tharnok_ability.base_damage = 0  # Урон рассчитывается динамически
	tharnok_ability.stamina_cost = 50
	tharnok_ability.cooldown = 4  # Перезарядка 3 хода (cooldown = 4 означает пропустить 3 хода врага)
	tharnok_ability.crit_chance_bonus = 0.0
	tharnok_ability.damage_multiplier = 1.0
	enemy_abilities["TharnokDemon"] = tharnok_ability
	
	# ЖЕЛТЫЙ НИНДЗЯ - физическая способность
	var ninja_ability = EnemyAbility.new()
	ninja_ability.id = "ninja_shadow_strike"
	ninja_ability.name = "Удар из тени"
	ninja_ability.description = "Быстрая атака с шансом критического удара"
	ninja_ability.damage_type = "physical"
	ninja_ability.base_damage = 14
	ninja_ability.stamina_cost = 25
	ninja_ability.crit_chance_bonus = 25.0
	ninja_ability.damage_multiplier = 1.3
	# YellowNinja - УДАЛЕН ИЗ ИГРЫ
	
	# Гоблин - УДАЛЕН ИЗ ИГРЫ
	
	# ЛЕТУЧАЯ МЫШЬ - физическая способность
	var bat_ability = EnemyAbility.new()
	bat_ability.id = "bat_swoop"
	bat_ability.name = "Пикирование"
	bat_ability.description = "Быстрая атака с шансом оглушения. Урон = сила + ловкость * 1.5. 30% шанс оглушения."
	bat_ability.damage_type = "physical"
	bat_ability.base_damage = 0  # Урон рассчитывается динамически
	bat_ability.stamina_cost = 35
	bat_ability.cooldown = 5  # Перезарядка 4 хода (cooldown = 5 означает пропустить 4 хода врага)
	bat_ability.crit_chance_bonus = 25.0
	bat_ability.damage_multiplier = 1.0
	enemy_abilities["Летучая мышь"] = bat_ability
	
	# ГОБЛИН ВОИН - двойной удар
	var goblin_warrior_ability = EnemyAbility.new()
	goblin_warrior_ability.id = "double_strike"
	goblin_warrior_ability.name = "Двойной удар"
	goblin_warrior_ability.description = "Наносит два быстрых удара. Урон каждого удара = (сила + ловкость) / 1.5. Каждый удар проверяется отдельно на уворот."
	goblin_warrior_ability.damage_type = "physical"
	goblin_warrior_ability.base_damage = 0  # Урон рассчитывается динамически
	goblin_warrior_ability.stamina_cost = 30
	goblin_warrior_ability.cooldown = 3  # Перезарядка 2 хода (cooldown = 3 означает пропустить 2 хода врага)
	goblin_warrior_ability.crit_chance_bonus = 0.0
	goblin_warrior_ability.damage_multiplier = 1.0
	goblin_warrior_ability.is_multi_hit = true
	goblin_warrior_ability.hit_count = 2
	enemy_abilities["Гоблин Воин"] = goblin_warrior_ability
	
	# Дракон - УДАЛЕН ИЗ ИГРЫ
	
	# ГОБЛИН ВОР - ядовитая способность
	var goblin_thief_ability = EnemyAbility.new()
	goblin_thief_ability.id = "poison_strike"
	goblin_thief_ability.name = "Ядовитый удар"
	goblin_thief_ability.description = "Наносит ядовитый урон = ловкость * 2.5. Накладывает 2 стака яда. Каждый стак яда наносит 10 урона за раунд. Максимум 3 стака."
	goblin_thief_ability.damage_type = "poison"
	goblin_thief_ability.base_damage = 0  # Урон рассчитывается динамически
	goblin_thief_ability.stamina_cost = 25
	goblin_thief_ability.cooldown = 2  # Перезарядка 1 ход (cooldown = 2 означает пропустить 1 ход врага)
	goblin_thief_ability.crit_chance_bonus = 0.0
	goblin_thief_ability.damage_multiplier = 1.0
	enemy_abilities["Гоблин Вор"] = goblin_thief_ability
	
	# ГОБЛИН КОЛДУН - магическая способность
	var goblin_mage_ability = EnemyAbility.new()
	goblin_mage_ability.id = "magic_arrows"
	goblin_mage_ability.name = "Магические стрелы"
	goblin_mage_ability.description = "Выпускает магические стрелы. Количество = 1 + интеллект / 15. Урон каждой стрелы = интеллект. Каждая стрела проверяется отдельно на уворот."
	goblin_mage_ability.damage_type = "magic"
	goblin_mage_ability.base_damage = 0  # Урон рассчитывается динамически
	goblin_mage_ability.mp_cost = 30
	goblin_mage_ability.stamina_cost = 0
	goblin_mage_ability.cooldown = 2  # Перезарядка 1 ход (cooldown = 2 означает пропустить 1 ход врага)
	goblin_mage_ability.crit_chance_bonus = 0.0
	goblin_mage_ability.damage_multiplier = 1.0
	enemy_abilities["Гоблин колдун"] = goblin_mage_ability
	
	# СКЕЛЕТ АРБАЛЕТЧИК - дальняя физическая атака
	var skeleton_crossbowman_ability = EnemyAbility.new()
	skeleton_crossbowman_ability.id = "crossbow_shot"
	skeleton_crossbowman_ability.name = "Арбалетный выстрел"
	skeleton_crossbowman_ability.description = "Точный выстрел из арбалета. Урон = сила + ловкость * 1.8. +15% к шансу крита."
	skeleton_crossbowman_ability.damage_type = "physical"
	skeleton_crossbowman_ability.base_damage = 0  # Урон рассчитывается динамически
	skeleton_crossbowman_ability.stamina_cost = 40
	skeleton_crossbowman_ability.cooldown = 3  # Перезарядка 2 хода
	skeleton_crossbowman_ability.crit_chance_bonus = 15.0
	skeleton_crossbowman_ability.damage_multiplier = 1.0
	enemy_abilities["Скелет Арбалетчик"] = skeleton_crossbowman_ability
	
	# СКЕЛЕТ МЕЧНИК - быстрая физическая атака
	var skeleton_swordsman_ability = EnemyAbility.new()
	skeleton_swordsman_ability.id = "slashing_strike"
	skeleton_swordsman_ability.name = "Рубящий удар"
	skeleton_swordsman_ability.description = "Быстрая атака мечом. Урон = сила + ловкость * 1.2. Накапливает стаки 'Танца смерти'."
	skeleton_swordsman_ability.damage_type = "physical"
	skeleton_swordsman_ability.base_damage = 0  # Урон рассчитывается динамически
	skeleton_swordsman_ability.stamina_cost = 35
	skeleton_swordsman_ability.cooldown = 2  # Перезарядка 1 ход
	skeleton_swordsman_ability.crit_chance_bonus = 0.0
	skeleton_swordsman_ability.damage_multiplier = 1.0
	enemy_abilities["Скелет Мечник"] = skeleton_swordsman_ability
	
	# ГУЛЬ - массовая магическая атака "Надгробие"
	var ghoul_ability = EnemyAbility.new()
	ghoul_ability.id = "tombstone"
	ghoul_ability.name = "Надгробие"
	ghoul_ability.description = "Массовая магическая атака, наносящая средний урон всем противникам. 30% шанс наложить Паралич (забирает 1 ОД в начале хода)."
	ghoul_ability.damage_type = "magic"
	ghoul_ability.base_damage = 0  # Урон рассчитывается динамически
	ghoul_ability.mp_cost = 40
	ghoul_ability.stamina_cost = 0
	ghoul_ability.cooldown = 3  # Перезарядка 2 хода
	ghoul_ability.crit_chance_bonus = 5.0
	ghoul_ability.damage_multiplier = 1.0
	ghoul_ability.is_multi_hit = false  # Массовая атака обрабатывается отдельно
	enemy_abilities["Гуль"] = ghoul_ability
	
	# ЭЛИТНЫЙ СКЕЛЕТ - два мощных удара молотом
	var elite_skeleton_ability = EnemyAbility.new()
	elite_skeleton_ability.id = "crushing_hammer"
	elite_skeleton_ability.name = "Сокрушительный молот"
	elite_skeleton_ability.description = "Два удара молотом. Первый удар = сила * 1.5 + живучесть. Второй удар = сила * 2.0 + живучесть * 1.3. 25% шанс оглушения на втором ударе. Снижает броню на 5."
	elite_skeleton_ability.damage_type = "physical"
	elite_skeleton_ability.base_damage = 0  # Урон рассчитывается динамически
	elite_skeleton_ability.stamina_cost = 60
	elite_skeleton_ability.cooldown = 4  # Перезарядка 3 хода
	elite_skeleton_ability.crit_chance_bonus = 5.0
	elite_skeleton_ability.damage_multiplier = 1.0
	elite_skeleton_ability.is_multi_hit = true
	elite_skeleton_ability.hit_count = 2
	enemy_abilities["Элитный Скелет"] = elite_skeleton_ability
	
	# ЗАГЛУШКА - базовая способность
	var placeholder_ability = EnemyAbility.new()
	placeholder_ability.id = "basic_attack"
	placeholder_ability.name = "Базовая атака"
	placeholder_ability.description = "Обычная физическая атака"
	placeholder_ability.damage_type = "physical"
	placeholder_ability.base_damage = 10
	placeholder_ability.stamina_cost = 10
	placeholder_ability.crit_chance_bonus = 5.0
	placeholder_ability.damage_multiplier = 1.0
	enemy_abilities["Заглушка"] = placeholder_ability
	
	# ОРК ЛУЧНИК - дальняя физическая атака
	var orc_archer_ability = EnemyAbility.new()
	orc_archer_ability.id = "orc_arrow_shot"
	orc_archer_ability.name = "Точный выстрел"
	orc_archer_ability.description = "Точный выстрел из лука. Урон = сила + ловкость * 1.6. +20% к шансу крита."
	orc_archer_ability.damage_type = "physical"
	orc_archer_ability.base_damage = 0  # Урон рассчитывается динамически
	orc_archer_ability.stamina_cost = 35
	orc_archer_ability.cooldown = 3  # Перезарядка 2 хода
	orc_archer_ability.crit_chance_bonus = 20.0
	orc_archer_ability.damage_multiplier = 1.0
	enemy_abilities["Орк лучник"] = orc_archer_ability
	
	# ОРК УБИЙЦА - скрытая атака
	var orc_assassin_ability = EnemyAbility.new()
	orc_assassin_ability.id = "orc_backstab"
	orc_assassin_ability.name = "Удар в спину"
	orc_assassin_ability.description = "Скрытая атака с увеличенным уроном. Урон = (сила + ловкость) * 2.0. 40% шанс наложить яд."
	orc_assassin_ability.damage_type = "physical"
	orc_assassin_ability.base_damage = 0  # Урон рассчитывается динамически
	orc_assassin_ability.stamina_cost = 40
	orc_assassin_ability.cooldown = 4  # Перезарядка 3 хода
	orc_assassin_ability.crit_chance_bonus = 15.0
	orc_assassin_ability.damage_multiplier = 1.0
	enemy_abilities["Орк убийца"] = orc_assassin_ability
	
	# ОРК БЕРСЕРК - мощная атака с яростью
	var orc_berserker_ability = EnemyAbility.new()
	orc_berserker_ability.id = "orc_berserker_strike"
	orc_berserker_ability.name = "Яростный удар"
	orc_berserker_ability.description = "Мощная атака с яростью. Урон = (сила * 2.0 + живучесть) * (1.0 + бонус от низкого HP). Урон увеличивается при низком HP."
	orc_berserker_ability.damage_type = "physical"
	orc_berserker_ability.base_damage = 0  # Урон рассчитывается динамически
	orc_berserker_ability.stamina_cost = 50
	orc_berserker_ability.cooldown = 4  # Перезарядка 3 хода
	orc_berserker_ability.crit_chance_bonus = 10.0
	orc_berserker_ability.damage_multiplier = 1.0
	enemy_abilities["Орк берсерк"] = orc_berserker_ability
	
	# ОРК ШАМАН - магическая атака
	var orc_shaman_ability = EnemyAbility.new()
	orc_shaman_ability.id = "orc_spirit_blast"
	orc_shaman_ability.name = "Духовный взрыв"
	orc_shaman_ability.description = "Магическая атака духов. Урон = интеллект * 2.0 + мудрость * 1.5. 25% шанс наложить дебафф на меткость."
	orc_shaman_ability.damage_type = "magic"
	orc_shaman_ability.base_damage = 0  # Урон рассчитывается динамически
	orc_shaman_ability.mp_cost = 45
	orc_shaman_ability.cooldown = 3  # Перезарядка 2 хода
	orc_shaman_ability.crit_chance_bonus = 8.0
	orc_shaman_ability.damage_multiplier = 1.0
	enemy_abilities["Орк шаман"] = orc_shaman_ability
	
	# ТЁМНЫЙ ШАТУН - гибридная атака (физика + магия)
	var dark_stalker_ability = EnemyAbility.new()
	dark_stalker_ability.id = "shadow_spikes"
	dark_stalker_ability.name = "Теневые шипы"
	dark_stalker_ability.description = "Выпускает шипы из тени. Урон = (ловкость + интеллект) * 2. Если в невидимости - автокрит!"
	dark_stalker_ability.damage_type = "shadow"  # Теневой урон (гибрид физики и магии)
	dark_stalker_ability.base_damage = 0  # Урон рассчитывается динамически
	dark_stalker_ability.stamina_cost = 45  # Средняя стоимость
	dark_stalker_ability.cooldown = 4  # Перезарядка 3 хода (cooldown = 4 означает пропустить 3 хода врага)
	dark_stalker_ability.crit_chance_bonus = 0.0  # Без бонуса, т.к. есть автокрит от невидимости
	dark_stalker_ability.damage_multiplier = 1.0
	enemy_abilities["Тёмный шатун"] = dark_stalker_ability
	
	# СКЕЛЕТ ЛОРД - физическая способность босса
	var skeleton_lord_ability = EnemyAbility.new()
	skeleton_lord_ability.id = "armor_strike"
	skeleton_lord_ability.name = "Удар брони"
	skeleton_lord_ability.description = "Наносит урон = (сила + живучесть) + P + текущая защита × 2. Снижает защиту цели на 6 до конца боя."
	skeleton_lord_ability.damage_type = "physical"
	skeleton_lord_ability.base_damage = 0  # Урон рассчитывается динамически
	skeleton_lord_ability.stamina_cost = 35
	skeleton_lord_ability.cooldown = 4  # Перезарядка 3 хода
	skeleton_lord_ability.crit_chance_bonus = 0.0
	skeleton_lord_ability.damage_multiplier = 1.0
	enemy_abilities["Скелет лорд"] = skeleton_lord_ability

func get_ability_for_enemy(enemy_name: String) -> EnemyAbility:
	"""Возвращает способность для указанного врага"""
	return enemy_abilities.get(enemy_name, enemy_abilities["Заглушка"])

func has_ability(enemy_name: String) -> bool:
	"""Проверяет, есть ли способность у врага"""
	return enemy_name in enemy_abilities

func get_ability_by_id(ability_id: String) -> EnemyAbility:
	"""Возвращает способность по её ID"""
	for enemy_name in enemy_abilities:
		var ability = enemy_abilities[enemy_name]
		if ability.id == ability_id:
			return ability
	
	# Если не найдена, возвращаем заглушку
	return enemy_abilities.get("Заглушка", null)
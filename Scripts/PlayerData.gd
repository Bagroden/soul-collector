# res://Scripts/PlayerData.gd
class_name PlayerData
extends Node

# Импортируем класс PassiveAbility для использования его типов
const PassiveAbilityClass = preload("res://Scripts/PassiveAbilities/PassiveAbility.gd")


# Player state
var max_hp: int = 100
var current_hp: int = 100
var max_mp: int = 100
var current_mp: int = 100
var max_stamina: int = 100
var current_stamina: int = 100

# Base stats (default values for level 1)
var base_strength: int = 5
var base_agility: int = 5
var base_vitality: int = 5
var base_endurance: int = 5
var base_intelligence: int = 5
var base_wisdom: int = 5
var base_accuracy: int = 100  # Base accuracy (100% = 100)

# Bonuses from passive abilities
var passive_strength_bonus: int = 0
var passive_agility_bonus: int = 0
var passive_vitality_bonus: int = 0
var passive_endurance_bonus: int = 0
var passive_intelligence_bonus: int = 0
var passive_wisdom_bonus: int = 0
var passive_accuracy_bonus: int = 0  # Accuracy bonus from passive abilities
var passive_hp_bonus: int = 0  # HP bonus from passive abilities
var passive_dodge_bonus: float = 0.0  # Dodge bonus from passive abilities
var passive_defense_bonus: int = 0  # Defense bonus from passive abilities
var passive_magic_resistance_bonus: int = 0  # Magic resistance bonus from passive abilities

# Flag for tracking ability usage (to avoid duplicate logging)
var using_ability: bool = false

# Action points system
var action_points: int = 1 # action points (default 1)
var max_action_points: int = 1 # maximum action points

# Final stats (base + bonuses)
var strength: int = 5
var agility: int = 5
var vitality: int = 5
var endurance: int = 5
var intelligence: int = 5
var wisdom: int = 5
var accuracy: int = 100  # Final accuracy (100% = 100)

# Calculated stats
var dodge_chance: float = 0.05  # Базовый шанс уворота 5%

# Additional parameters
var level: int = 1
var experience: int = 0
var gold: int = 0
var soul_level: int = 1
var passive_abilities: Array = []

# Spiritual power system (for passive ability activation)
var spiritual_power: int = 5  # Current spiritual power (5 + level - 1)
var max_spiritual_power: int = 5  # Maximum spiritual power
var used_spiritual_power: int = 0  # Spiritual power used by active passives

# Passive abilities system
var learned_passives: Array[String] = []  # Learned passive abilities
var active_passives: Array[String] = []    # Active passive abilities
var passive_ability_manager: Node

# Level system
var stat_points: int = 20  # Free stat points
var base_hp: int = 100    # Base HP without level bonuses
var base_mp: int = 100    # Base MP without level bonuses
var base_stamina: int = 100  # Base stamina without level bonuses

# Stat bonuses
var bonus_damage: int = 0
var physical_damage_bonus: int = 0  # Общий бонус к физическому урону (P)
var massive_damage_bonus: int = 0  # Бонус урона от способности "Массивный"
var crit_chance: float = 0.0
var hp_regen: int = 0
var stamina_regen: int = 0
var magic_damage_bonus: float = 0.0
var magic_crit_chance: float = 0.0
var mp_regen: int = 0
var defense_from_vitality: int = 0  # Бонус защиты от живучести (1 защита за каждые 3 единицы живучести)

# Meta-progression system (Quests and Artifacts)
var met_soul_sculptor: bool = false  # Встретил ли игрок Скульптора душ
var seen_first_dialogue: bool = false  # Видел ли игрок первый приветственный диалог
var has_soul_urn: bool = false  # Есть ли Урна душ
var soul_urn_delivered: bool = false  # Доставлена ли Урна душ Скульптору
var soul_urn_reward_received: bool = false  # Получена ли награда за доставку Урны душ
var has_knowledge_crystal: bool = false  # Есть ли Кристалл познания
var knowledge_crystal_delivered: bool = false  # Доставлен ли Кристалл познания Скульптору
var has_phylactery: bool = false  # Есть ли Филактерия некроманта
var phylactery_delivered: bool = false  # Доставлена ли Филактерия Скульптору
var has_ancient_skull: bool = false  # Есть ли Древний череп
var ancient_skull_delivered: bool = false  # Доставлен ли Древний череп Скульптору

# Ограничения изучения способностей
var max_passive_level: int = 0  # 0-3 (0=ничего, 1=до Rare, 2=до Legendary, 3=все)
var max_soul_development_level: int = 0  # 0-6 (количество доступных уровней развития души)

# Квесты
var available_quests: Array[String] = []  # Список доступных квестов (можно взять)
var active_quests: Array[String] = []  # Список активных квестов (уже взяты)
var completed_quests: Array[String] = []  # Список завершенных квестов

# Система сложностей локаций
var unlocked_difficulties: Dictionary = {}  # {location_id: max_difficulty} (1-3)
var selected_difficulty: Dictionary = {}  # {location_id: current_difficulty} (1-3)
var unlocked_location_bosses: Dictionary = {}  # {location_id: true/false} - разблокирован ли босс локации
var selected_mode: Dictionary = {}  # {location_id: "normal"/"boss"} - выбранный режим (обычный или босс)

signal health_changed(current_hp: int, max_hp: int)
signal mana_changed(current_mp: int, max_mp: int)
signal stamina_changed(current_stamina: int, max_stamina: int)
signal level_up(new_level: int)
signal stat_points_changed(points: int)
signal stats_updated()  # Сигнал об обновлении статистики
signal experience_changed(current_exp: int, exp_to_next: int)
signal spiritual_power_changed(current: int, max_power: int, used: int)

func _ready():
	# Initialize passive ability arrays if they are empty
	if learned_passives == null:
		learned_passives = []
	if active_passives == null:
		active_passives = []
	
	# Инициализируем духовную мощь
	_update_spiritual_power()
	
	calculate_stat_bonuses()
	apply_stat_bonuses()

# Spiritual Power System
func _update_spiritual_power():
	"""Обновляет максимальную духовную мощь на основе уровня"""
	# 5 базовой мощи + (уровень - 1)
	var base_spiritual_power = 5 + (level - 1)
	
	# Добавляем бонус от пассивок "Развития души"
	# Бонус будет применен через SoulRestorationManager.recalculate_bonuses_from_learned_abilities()
	# Здесь мы только устанавливаем базовое значение, если бонус еще не применен
	if max_spiritual_power < base_spiritual_power:
		max_spiritual_power = base_spiritual_power
	
	# Пересчитываем использованную мощь
	_recalculate_used_spiritual_power()
	
	emit_signal("spiritual_power_changed", spiritual_power, max_spiritual_power, used_spiritual_power)

func _recalculate_used_spiritual_power():
	"""Пересчитывает использованную духовную мощь на основе активных способностей"""
	used_spiritual_power = 0
	
	# Получаем менеджер пассивных способностей
	if not passive_ability_manager:
		passive_ability_manager = get_node_or_null("/root/PassiveAbilityManager")
	
	if not passive_ability_manager:
		return
	
	# Подсчитываем стоимость всех активных способностей
	for ability_id in active_passives:
		var ability = passive_ability_manager.get_ability(ability_id)
		if ability:
			used_spiritual_power += get_spiritual_power_cost(ability.rarity)
	
	# Обновляем доступную духовную мощь
	spiritual_power = max_spiritual_power - used_spiritual_power

func get_spiritual_power_cost(rarity: String) -> int:
	"""Возвращает стоимость духовной мощи для редкости способности"""
	match rarity:
		"common":
			return 3
		"uncommon":
			return 5
		"rare":
			return 7
		"epic":
			return 9
		"legendary":
			return 12
		"mythic":
			return 15
		"boss":
			return 20  # Босс-способности очень дорогие!
		_:
			return 3  # По умолчанию как common

func can_activate_passive(ability_id: String) -> Dictionary:
	"""Проверяет, можно ли активировать пассивную способность"""
	var result = {
		"can_activate": false,
		"reason": ""
	}
	
	# Проверяем, изучена ли способность
	if ability_id not in learned_passives:
		result.reason = "Способность не изучена"
		return result
	
	# Проверяем, не активирована ли уже
	if ability_id in active_passives:
		result.reason = "Способность уже активирована"
		return result
	
	# Получаем способность
	if not passive_ability_manager:
		passive_ability_manager = get_node_or_null("/root/PassiveAbilityManager")
	
	if not passive_ability_manager:
		result.reason = "Менеджер способностей не найден"
		return result
	
	var ability = passive_ability_manager.get_ability(ability_id)
	if not ability:
		result.reason = "Способность не найдена"
		return result
	
	# Проверяем достаточно ли духовной мощи
	var cost = get_spiritual_power_cost(ability.rarity)
	if spiritual_power < cost:
		result.reason = "Недостаточно духовной мощи (%d/%d)" % [spiritual_power, cost]
		return result
	
	result.can_activate = true
	return result

func calculate_stat_bonuses():
	# Strength: 1 strength = 1 damage
	bonus_damage = strength
	
	# Agility: 1 agility = 1% crit chance
	crit_chance = float(agility) / 100.0
	
	# Vitality: 1 vitality = 10 HP, every 10 = 1 HP regen, every 3 = 1 defense
	# Use base vitality + passive ability bonuses
	var total_vitality = base_vitality + passive_vitality_bonus
	hp_regen = int(float(total_vitality) / 10.0)
	defense_from_vitality = int(float(vitality) / 3.0)
	
	# Endurance: 1 endurance = 5 stamina, every 3 = 1 stamina regen
	stamina_regen = int(float(endurance) / 3.0)
	
	# Intelligence: 1 intelligence = 1% magic damage and 1% magic crit
	magic_damage_bonus = float(intelligence) / 100.0
	magic_crit_chance = float(intelligence) / 100.0
	
	# Accuracy: базовая меткость 100% + бонусы от пассивных способностей
	accuracy = base_accuracy + passive_accuracy_bonus
	
	# Dodge: базовый шанс 5% + бонусы от пассивных способностей
	dodge_chance = 0.05 + passive_dodge_bonus  # Базовый шанс уворота 5% + бонусы
	
	# Wisdom: 1 wisdom = 10 MP, every 5 = 1 MP regen
	# Use base wisdom + passive ability bonuses
	var total_wisdom = base_wisdom + passive_wisdom_bonus
	mp_regen = int(float(total_wisdom) / 5.0)

func apply_stat_bonuses():
	# Применяем бонусы к базовым характеристикам + бонусы от уровня + бонусы от пассивных способностей
	
	# Для HP используем базовую витальность + бонусы от пассивных способностей отдельно
	var total_vitality = base_vitality + passive_vitality_bonus
	max_hp = base_hp + (total_vitality * 10) + (level * 10) + passive_hp_bonus
	
	# Для MP используем базовую мудрость + бонусы от пассивных способностей отдельно
	var total_wisdom = base_wisdom + passive_wisdom_bonus
	max_mp = base_mp + (total_wisdom * 10) + (level * 10)
	max_stamina = base_stamina + (endurance * 5) + (level * 10)
	
	# Обновляем текущие значения (только если они больше максимума)
	if current_hp > max_hp:
		current_hp = max_hp
	if current_mp > max_mp:
		current_mp = max_mp
	if current_stamina > max_stamina:
		current_stamina = max_stamina

func take_damage(amount: int):
	var final_damage = max(0, amount)
	current_hp = max(0, current_hp - final_damage)
	emit_signal("health_changed", current_hp, max_hp)
	return final_damage

func heal(amount: int):
	var heal_amount = min(amount, max_hp - current_hp)
	current_hp = min(max_hp, current_hp + heal_amount)
	emit_signal("health_changed", current_hp, max_hp)
	return heal_amount

func use_mana(amount: int) -> bool:
	if current_mp >= amount:
		current_mp -= amount
		emit_signal("mana_changed", current_mp, max_mp)
		return true
	return false

func restore_mana(amount: int):
	var restore_amount = min(amount, max_mp - current_mp)
	current_mp = min(max_mp, current_mp + restore_amount)
	emit_signal("mana_changed", current_mp, max_mp)
	return restore_amount

func use_stamina(amount: int) -> bool:
	if current_stamina >= amount:
		current_stamina -= amount
		emit_signal("stamina_changed", current_stamina, max_stamina)
		return true
	return false

func restore_stamina(amount: int):
	var restore_amount = min(amount, max_stamina - current_stamina)
	current_stamina = min(max_stamina, current_stamina + restore_amount)
	emit_signal("stamina_changed", current_stamina, max_stamina)
	return restore_amount

func regenerate_resources():
	# Не регенерируем ресурсы если игрок мертв
	if is_dead():
		return
		
	# Регенерация ХП
	if current_hp < max_hp and hp_regen > 0:
		var old_hp = current_hp
		heal(hp_regen)
		var actual_heal = current_hp - old_hp
		if actual_heal > 0:
			_log_regeneration("hp", actual_heal)
	
	# Регенерация МП
	if current_mp < max_mp and mp_regen > 0:
		var old_mp = current_mp
		restore_mana(mp_regen)
		var actual_restore = current_mp - old_mp
		if actual_restore > 0:
			_log_regeneration("mp", actual_restore)
	
	# Регенерация выносливости
	if current_stamina < max_stamina and stamina_regen > 0:
		var old_stamina = current_stamina
		restore_stamina(stamina_regen)
		var actual_restore = current_stamina - old_stamina
		if actual_restore > 0:
			_log_regeneration("stamina", actual_restore)

func _log_regeneration(resource_type: String, amount: int):
	# Ищем battle_log в сцене
	var battle_log = get_node_or_null("/root/BattleScene/BattleLog")
	if not battle_log:
		# Пробуем найти через battle_manager
		var battle_manager = get_node_or_null("/root/BattleScene")
		if battle_manager and battle_manager.has_method("get") and battle_manager.get("battle_log"):
			battle_log = battle_manager.battle_log
	
	if battle_log and battle_log.has_method("log_regeneration"):
		# Передаем информацию о текущем значении ресурса
		var current_value = 0
		var max_value = 0
		match resource_type:
			"hp":
				current_value = current_hp
				max_value = max_hp
			"mp":
				current_value = current_mp
				max_value = max_mp
			"stamina":
				current_value = current_stamina
				max_value = max_stamina
		
		battle_log.log_regeneration("Player", resource_type, amount, current_value, max_value)

func is_dead() -> bool:
	return current_hp <= 0

# Методы для работы с очками действий
func add_action_point():
	"""Добавляет очко действий"""
	action_points += 1
	max_action_points = max(max_action_points, action_points)
	print("Player получает очко действий! Всего: ", action_points)

func spend_action_point() -> bool:
	"""Тратит очко действий, возвращает true если успешно"""
	if action_points > 0:
		action_points -= 1
		print("Player тратит очко действий. Осталось: ", action_points)
		return true
	return false

func reset_action_points():
	"""Сбрасывает очки действий в начале раунда"""
	action_points = 1
	max_action_points = 1
	print("Player очки действий сброшены: ", action_points)

func has_action_points() -> bool:
	"""Проверяет, есть ли очки действий"""
	return action_points > 0

func get_total_damage() -> int:
	# Используем базовый урон из характеристик + бонус от силы
	var base_damage = 10 + (level * 2)  # Базовый урон + бонус от уровня
	var total_damage = base_damage + bonus_damage
	return total_damage

func get_crit_damage() -> int:
	return int(get_total_damage() * 1.5)

func is_critical_hit() -> bool:
	return randf() < crit_chance

func is_magic_critical_hit() -> bool:
	return randf() < magic_crit_chance

func get_magic_damage(base_damage: int) -> int:
	var damage = base_damage
	damage = int(damage * (1.0 + magic_damage_bonus))
	if is_magic_critical_hit():
		damage = int(damage * 1.5)
	return damage

func add_experience(amount: int):
	experience += amount
	
	# Испускаем сигнал об изменении опыта
	emit_signal("experience_changed", experience, get_exp_to_next_level())
	
	# Проверяем повышение уровня
	check_level_up()

func check_level_up():
	var exp_needed = get_exp_for_level(level + 1)
	if experience >= exp_needed:
		_level_up()

func get_exp_for_level(target_level: int) -> int:
	# Формула: 1000 * (уровень - 1) * уровень = опыт для достижения уровня
	# Уровень 1: 0 опыта
	# Уровень 2: 1000 * 1 * 2 = 2000 опыта
	# Уровень 3: 1000 * 2 * 3 = 6000 опыта (но нужно 5000, корректируем)
	# Уровень 4: 1000 * 3 * 4 = 12000 опыта (но нужно 9000, корректируем)
	# Уровень 5: 1000 * 4 * 5 = 20000 опыта (но нужно 14000, корректируем)
	# Уровень 6: 1000 * 5 * 6 = 30000 опыта (но нужно 20000, корректируем)
	
	# Правильная формула на основе ваших данных:
	# Уровень 2: 2000 = 1000 * 1 * 2
	# Уровень 3: 5000 = 1000 * 2 * 2.5
	# Уровень 4: 9000 = 1000 * 3 * 3
	# Уровень 5: 14000 = 1000 * 4 * 3.5
	# Уровень 6: 20000 = 1000 * 5 * 4
	
	# Общая формула: 1000 * (уровень - 1) * (уровень + 1) / 2
	# Но это не дает точные значения, поэтому используем точную формулу:
	
	match target_level:
		1:
			return 0
		2:
			return 2000
		3:
			return 5000
		4:
			return 9000
		5:
			return 14000
		6:
			return 20000
		_:
			# Анализируем паттерн разностей:
			# Уровень 1→2: 2000 опыта
			# Уровень 2→3: 3000 опыта (5000-2000)
			# Уровень 3→4: 4000 опыта (9000-5000)
			# Уровень 4→5: 5000 опыта (14000-9000)
			# Уровень 5→6: 6000 опыта (20000-14000)
			# Паттерн: 2000, 3000, 4000, 5000, 6000...
			# Это арифметическая прогрессия: a_n = 2000 + (n-1) * 1000 = 1000 * (n + 1)
			# Сумма: S_n = n * (a_1 + a_n) / 2 = n * (2000 + 1000*(n+1)) / 2
			# S_n = n * (2000 + 1000n + 1000) / 2 = n * (3000 + 1000n) / 2 = 500 * n * (3 + n)
			# Но это для n-1 уровня, поэтому: 500 * (target_level - 1) * (target_level + 2)
			return 500 * (target_level - 1) * (target_level + 2)

func _level_up():
	level += 1
	stat_points += 5  # Получаем 5 очков характеристик
	
	# Увеличиваем базовые ресурсы на 10
	base_hp += 10
	base_mp += 10
	base_stamina += 10
	
	# Увеличиваем духовную мощь (+1 за уровень)
	_update_spiritual_power()
	
	# Пересчитываем бонусы
	calculate_stat_bonuses()
	apply_stat_bonuses()
	
	# Восстанавливаем ресурсы до максимума при повышении уровня
	current_hp = max_hp
	current_mp = max_mp
	current_stamina = max_stamina
	
	emit_signal("level_up", level)
	emit_signal("stat_points_changed", stat_points)
	
	
	# Проверяем, можно ли повыситься еще раз
	check_level_up()

func add_stat_point(stat_name: String) -> bool:
	if stat_points <= 0:
		return false
	
	match stat_name:
		"strength":
			base_strength += 1
		"agility":
			base_agility += 1
		"vitality":
			base_vitality += 1
		"endurance":
			base_endurance += 1
		"intelligence":
			base_intelligence += 1
		"wisdom":
			base_wisdom += 1
		"accuracy":
			base_accuracy += 1
		_:
			return false
	
	stat_points -= 1
	
	# Пересчитываем итоговые характеристики
	recalculate_stats()
	
	calculate_stat_bonuses()
	apply_stat_bonuses()
	emit_signal("stat_points_changed", stat_points)
	return true

func get_exp_to_next_level() -> int:
	var exp_needed = get_exp_for_level(level + 1)
	return exp_needed - experience

func calculate_battle_exp(enemy_level: int) -> int:
	# Базовый опыт: 100 * уровень врага
	var base_exp = 100 * enemy_level
	
	# Модификатор разницы уровней
	var level_diff = enemy_level - level
	var modifier = 1.0
	
	if level_diff < 0:
		# Враг ниже уровнем - уменьшаем опыт на 10% за каждый уровень разницы
		modifier = 1.0 + (level_diff * 0.1)
	else:
		# Враг выше уровнем - увеличиваем опыт на 10% за каждый уровень разницы
		modifier = 1.0 + (level_diff * 0.1)
	
	# Минимальный модификатор 0.1 (10% от базового опыта)
	modifier = max(0.1, modifier)
	
	# Проверяем бонус к опыту от "Мастерства Тарнока"
	var exp_bonus = 0.0
	# TODO: Добавить проверку пассивных способностей игрока
	# if has_passive_ability("tharnok_mastery"):
	#     exp_bonus = 0.5  # +50% к опыту
	
	# Применяем бонус к опыту
	if exp_bonus > 0:
		modifier += exp_bonus
	
	var final_exp = int(base_exp * modifier)
	return final_exp

func add_gold(amount: int):
	gold += amount

# === СИСТЕМА ПАССИВНЫХ СПОСОБНОСТЕЙ ===

func initialize_passive_system():
	"""Инициализация системы пассивных способностей"""
	if not passive_ability_manager:
		var script = load("res://Scripts/PassiveAbilities/PassiveAbilityManager.gd")
		passive_ability_manager = Node.new()
		passive_ability_manager.set_script(script)
		add_child(passive_ability_manager)
	
	# Синхронизируем изученные способности из системы изучения
	_sync_learned_abilities_from_learning_system()
	
	# НЕ применяем бонусы здесь - они применяются только при изучении
	# и загружаются из сохранений через SoulRestorationManager

func learn_passive_ability(ability_id: String) -> bool:
	"""Изучить новую пассивную способность"""
	# Инициализируем массив если он null
	if learned_passives == null:
		learned_passives = []
	
	if ability_id in learned_passives:
		return false
	
	learned_passives.append(ability_id)
	return true

func activate_passive_ability(ability_id: String) -> bool:
	"""Активировать пассивную способность"""
	# Инициализируем массивы если они null
	if learned_passives == null:
		learned_passives = []
	if active_passives == null:
		active_passives = []
	
	# Проверяем, можно ли активировать способность
	var check_result = can_activate_passive(ability_id)
	if not check_result.can_activate:
		print("❌ Невозможно активировать способность: ", check_result.reason)
		return false
	
	active_passives.append(ability_id)
	
	# Применяем бонус от способности
	_apply_single_passive_bonus(ability_id)
	
	# Обновляем духовную мощь
	_recalculate_used_spiritual_power()
	emit_signal("spiritual_power_changed", spiritual_power, max_spiritual_power, used_spiritual_power)
	
	# Способности с типом PASSIVE обрабатываются через _apply_single_passive_bonus
	# Дополнительная активация не требуется
	
	# Уведомляем об обновлении статистики
	emit_signal("stats_updated")
	
	return true

func deactivate_passive_ability(ability_id: String) -> bool:
	"""Деактивировать пассивную способность"""
	# Инициализируем массив если он null
	if active_passives == null:
		active_passives = []
	
	if ability_id not in active_passives:
		return false
	
	active_passives.erase(ability_id)
	
	# Удаляем бонус от способности
	_remove_single_passive_bonus(ability_id)
	
	# Обновляем духовную мощь
	_recalculate_used_spiritual_power()
	emit_signal("spiritual_power_changed", spiritual_power, max_spiritual_power, used_spiritual_power)
	
	# Уведомляем об обновлении статистики
	emit_signal("stats_updated")
	
	return true

func toggle_passive_ability(ability_id: String) -> bool:
	"""Переключить состояние пассивной способности"""
	if ability_id in active_passives:
		return deactivate_passive_ability(ability_id)
	else:
		return activate_passive_ability(ability_id)

func has_learned_passive(ability_id: String) -> bool:
	"""Проверить, изучена ли пассивная способность"""
	if learned_passives == null:
		learned_passives = []
	return ability_id in learned_passives

func has_active_passive(ability_id: String) -> bool:
	"""Проверить, активна ли пассивная способность"""
	if active_passives == null:
		active_passives = []
	return ability_id in active_passives

func get_learned_passives() -> Array[String]:
	"""Получить список изученных пассивных способностей"""
	if learned_passives == null:
		learned_passives = []
	return learned_passives

func get_active_passives() -> Array[String]:
	"""Получить список активных пассивных способностей"""
	if active_passives == null:
		active_passives = []
	return active_passives

func get_passive_ability_info(ability_id: String) -> PassiveAbility:
	"""Получить информацию о пассивной способности"""
	if not passive_ability_manager:
		initialize_passive_system()
	
	return passive_ability_manager.get_ability(ability_id)

func get_passive_ability_level(_ability_id: String) -> int:
	"""Получить уровень пассивной способности игрока"""
	# Для игрока все способности имеют уровень 1 (базовый уровень)
	# В будущем можно добавить систему уровней для игрока
	return 1

func get_available_passives_for_ui() -> Array[Dictionary]:
	"""Получить список пассивных способностей для отображения в UI"""
	var result: Array[Dictionary] = []
	
	if not passive_ability_manager:
		initialize_passive_system()
	
	# Синхронизируем изученные способности из AbilityLearningSystem
	_sync_learned_abilities_from_learning_system()
	
	for ability_id in learned_passives:
		var ability = passive_ability_manager.get_ability(ability_id)
		if ability:
			# ИСКЛЮЧАЕМ способности развития души - они не требуют активации
			if "soul" in ability.tags:
				continue
			
			# Получаем уровень способности из AbilityLearningSystem
			var ability_level = 0
			if AbilityLearningSystem:
				ability_level = AbilityLearningSystem.get_ability_level(ability_id)
			
			var ui_data = {
				"id": ability.id,
				"name": ability.name,
				"description": ability.description,
				"rarity": ability.rarity,
				"ability_type": ability.ability_type,
				"trigger_type": ability.trigger_type,
				"value": ability.value,
				"level": ability_level,
				"is_active": ability_id in active_passives,
				"can_activate": true  # Все изученные способности можно активировать
			}
			result.append(ui_data)
	
	return result

func _sync_learned_abilities_from_learning_system():
	"""Синхронизирует изученные способности из AbilityLearningSystem с learned_passives"""
	var ability_learning_system = get_node_or_null("/root/AbilityLearningSystem")
	if not ability_learning_system:
		return
	
	# Подключаемся к сигналу изучения способностей (если еще не подключены)
	if not ability_learning_system.is_connected("ability_learned", Callable(self, "_on_ability_learned")):
		ability_learning_system.connect("ability_learned", Callable(self, "_on_ability_learned"))
	
	# Получаем все изученные способности из системы изучения
	var learned_from_system = ability_learning_system.get_learned_abilities()
	
	# Добавляем новые изученные способности в learned_passives
	for ability_id in learned_from_system:
		if ability_id not in learned_passives:
			learned_passives.append(ability_id)
			print("Синхронизирована изученная способность: ", ability_id)

func _on_ability_learned(ability_id: String, _progress: int):
	"""Обработчик сигнала изучения новой способности"""
	if ability_id not in learned_passives:
		learned_passives.append(ability_id)
		print("Автоматически добавлена изученная способность: ", ability_id)

func reset_passive_abilities():
	"""Сбрасывает все пассивные способности игрока"""
	
	learned_passives = []
	active_passives = []
	

func apply_passive_bonuses():
	"""Применяет бонусы от активных пассивных способностей"""
	
	for ability_id in active_passives:
		match ability_id:
			"dodge":
				# Уворот - добавляем бонус к шансу уворота
				var ability_level = AbilityLearningSystem.get_ability_level(ability_id)
				var dodge_ability = AbilityLearningSystem.ability_learning_config.get(ability_id, {})
				if dodge_ability.has("level_values"):
					var dodge_bonus = dodge_ability.level_values[ability_level - 1] / 100.0
					passive_dodge_bonus += dodge_bonus
			_:
				pass  # Тестовые способности удалены
	

func remove_passive_bonuses():
	"""Удаляет бонусы от активных пассивных способностей"""
	
	for ability_id in active_passives:
		match ability_id:
			"dodge":
				# Уворот - удаляем бонус к шансу уворота
				var ability_level = AbilityLearningSystem.get_ability_level(ability_id)
				var dodge_ability = AbilityLearningSystem.ability_learning_config.get(ability_id, {})
				if dodge_ability.has("level_values"):
					var dodge_bonus = dodge_ability.level_values[ability_level - 1] / 100.0
					passive_dodge_bonus -= dodge_bonus
			_:
				pass  # Тестовые способности удалены
	

func _apply_single_passive_bonus(ability_id: String):
	"""Применяет бонус от одной пассивной способности"""
	
	# Проверяем, не применен ли уже бонус от этой способности
	var bonus_already_applied = false
	match ability_id:
		"slime_vitality":
			# Для "Живучести слизня" проверяем, есть ли уже бонус
			if passive_hp_bonus > 0:
				bonus_already_applied = true
		_:
			pass  # Тестовые способности удалены
	
	if bonus_already_applied:
		return
	
	match ability_id:
		"slime_vitality":
			# Живучесть слизня - увеличивает HP на X% в зависимости от уровня
			var ability_level = AbilityLearningSystem.get_ability_level(ability_id)
			var slime_vitality_config = AbilityLearningSystem.ability_learning_config.get(ability_id, {})
			if slime_vitality_config.has("level_values"):
				var hp_percentage = slime_vitality_config.level_values[ability_level - 1]  # Получаем процент для текущего уровня
				var hp_without_slime_bonus = max_hp - passive_hp_bonus  # HP без бонуса от способности
				var hp_increase = int(hp_without_slime_bonus * (hp_percentage / 100.0))  # X% от HP с характеристиками
				passive_hp_bonus += hp_increase
				# Сохраняем значение бонуса для правильного удаления
				set_meta("slime_vitality_bonus", hp_increase)
			# Пересчитываем HP с учетом нового бонуса
			apply_stat_bonuses()
		"dodge":
			# Уворот - добавляем бонус к шансу уворота
			var ability_level = AbilityLearningSystem.get_ability_level(ability_id)
			var dodge_ability = AbilityLearningSystem.ability_learning_config.get(ability_id, {})
			if dodge_ability.has("level_values"):
				var dodge_bonus = dodge_ability.level_values[ability_level - 1] / 100.0
				passive_dodge_bonus += dodge_bonus
				# Пересчитываем характеристики с учетом нового бонуса
				calculate_stat_bonuses()
		"massive":
			# Массивный - добавляем бонус урона от максимального здоровья
			var ability_level = AbilityLearningSystem.get_ability_level(ability_id)
			var massive_ability = AbilityLearningSystem.ability_learning_config.get(ability_id, {})
			if massive_ability.has("level_values"):
				var percentage = massive_ability.level_values[ability_level - 1] / 100.0  # 2%, 4%, 6%
				var damage_bonus = int(max_hp * percentage)
				physical_damage_bonus += damage_bonus
				massive_damage_bonus += damage_bonus
				# Сохраняем значение бонуса для правильного удаления
				set_meta("massive_damage_bonus", damage_bonus)
		_:
			pass  # Тестовые способности удалены
	
	# Пересчитываем итоговые характеристики
	recalculate_stats()

func _remove_single_passive_bonus(ability_id: String):
	"""Удаляет бонус от одной пассивной способности"""
	
	# Проверяем, есть ли бонус для удаления
	var bonus_to_remove = false
	match ability_id:
		"slime_vitality":
			# Проверяем, есть ли бонус от "Живучести слизня"
			if passive_hp_bonus > 0:
				bonus_to_remove = true
		"massive":
			# Проверяем, есть ли бонус от "Массивного"
			if massive_damage_bonus > 0:
				bonus_to_remove = true
		_:
			pass  # Тестовые способности удалены
	
	if not bonus_to_remove:
		return
	
	match ability_id:
		"slime_vitality":
			# Живучесть слизня - удаляем сохраненное значение бонуса
			var hp_decrease = get_meta("slime_vitality_bonus", 0)  # Получаем сохраненное значение
			passive_hp_bonus -= hp_decrease
			# Удаляем сохраненное значение
			remove_meta("slime_vitality_bonus")
			# Пересчитываем HP с учетом удаленного бонуса
			apply_stat_bonuses()
			# Убеждаемся, что текущее HP не превышает максимум
			current_hp = min(current_hp, max_hp)
		"dodge":
			# Уворот - удаляем бонус к шансу уворота
			var ability_level = AbilityLearningSystem.get_ability_level(ability_id)
			var dodge_ability = AbilityLearningSystem.ability_learning_config.get(ability_id, {})
			if dodge_ability.has("level_values"):
				var dodge_bonus = dodge_ability.level_values[ability_level - 1] / 100.0
				passive_dodge_bonus -= dodge_bonus
				# Пересчитываем характеристики с учетом удаленного бонуса
				calculate_stat_bonuses()
				print("Удален бонус Уворота: -", dodge_ability.level_values[ability_level - 1], "%")
		"massive":
			# Массивный - удаляем бонус урона от максимального здоровья
			var damage_decrease = get_meta("massive_damage_bonus", 0)  # Получаем сохраненное значение
			physical_damage_bonus -= damage_decrease
			massive_damage_bonus -= damage_decrease
			# Удаляем сохраненное значение
			remove_meta("massive_damage_bonus")
			print("Удален бонус 'Массивный': -", damage_decrease, " урона")
		_:
			pass  # Тестовые способности удалены
	
	# Пересчитываем итоговые характеристики
	recalculate_stats()

func reset_stats_to_default():
	"""Сбрасывает характеристики к дефолтным значениям для 1 уровня"""
	
	# Подсчитываем потраченные очки характеристик
	# Базовое значение каждой характеристики = 5
	# Начальные stat_points = 20
	var spent_points = (base_strength - 5) + (base_agility - 5) + (base_vitality - 5) + (base_endurance - 5) + (base_intelligence - 5) + (base_wisdom - 5)
	
	# Возвращаем потраченные очки игроку
	stat_points = 20 + spent_points
	
	print("Сброс характеристик: возвращено ", spent_points, " очков. Всего очков: ", stat_points)
	
	# Сбрасываем к дефолтным значениям
	base_strength = 5
	base_agility = 5
	base_vitality = 5
	base_endurance = 5
	base_intelligence = 5
	base_wisdom = 5
	base_accuracy = 100
	
	# Сбрасываем бонусы от пассивных способностей
	passive_strength_bonus = 0
	passive_agility_bonus = 0
	passive_vitality_bonus = 0
	passive_endurance_bonus = 0
	passive_intelligence_bonus = 0
	passive_wisdom_bonus = 0
	passive_accuracy_bonus = 0
	passive_hp_bonus = 0
	passive_dodge_bonus = 0.0
	physical_damage_bonus = 0
	massive_damage_bonus = 0
	
	level = 1
	experience = 0
	
	# Пересчитываем итоговые характеристики
	recalculate_stats()
	
	# Сбрасываем ресурсы к базовым значениям
	# ВАЖНО: Устанавливаем базовые значения БЕЗ бонусов от характеристик
	max_hp = 100
	current_hp = 100
	max_mp = 100
	current_mp = 100
	max_stamina = 100
	current_stamina = 100
	
	# Обнуляем бонусы от характеристик, чтобы не применялись автоматически
	hp_regen = 0
	mp_regen = 0
	stamina_regen = 0
	bonus_damage = 0
	crit_chance = 0.0
	magic_damage_bonus = 0.0
	magic_crit_chance = 0.0
	
	# Сбрасываем пассивные способности
	learned_passives = []
	active_passives = []
	
	print("Характеристики ПОСЛЕ сброса:")
	print("  Сила: ", strength)
	print("  Ловкость: ", agility)
	print("  Витальность: ", vitality)
	print("  Выносливость: ", endurance)
	print("  Интеллект: ", intelligence)
	print("  Мудрость: ", wisdom)
	print("  Уровень: ", level)
	print("  Опыт: ", experience)
	print("  Макс. HP: ", max_hp)
	print("  Макс. MP: ", max_mp)
	print("  Макс. Выносливость: ", max_stamina)

func recalculate_stats():
	"""Пересчитывает итоговые характеристики на основе базовых + бонусов"""
	strength = base_strength + passive_strength_bonus
	agility = base_agility + passive_agility_bonus
	vitality = base_vitality + passive_vitality_bonus
	endurance = base_endurance + passive_endurance_bonus
	intelligence = base_intelligence + passive_intelligence_bonus
	wisdom = base_wisdom + passive_wisdom_bonus
	

func sync_active_passives_with_bonuses():
	"""Синхронизирует активные способности с фактическими бонусами"""
	
	# Добавляем способности, которые имеют бонусы (но не добавляем автоматически при создании персонажа)
	# Это нужно для синхронизации между меню и боем
	
	# Проверяем, какие бонусы фактически применены и добавляем только недостающие
	# Тестовые способности удалены
	
	# Удаляем способности, которые не имеют соответствующих бонусов
	var to_remove = []
	for ability_id in active_passives:
		var should_remove = false
		match ability_id:
			_:
				pass  # Тестовые способности удалены
		
		if should_remove:
			to_remove.append(ability_id)
			print("Удаляем способность ", ability_id, " - нет соответствующего бонуса")
	
	for ability_id in to_remove:
		active_passives.erase(ability_id)
	

func apply_active_passive_bonuses():
	"""Применяет бонусы от всех активных пассивных способностей (используется при загрузке игры)"""
	
	# Сбрасываем все бонусы перед применением
	passive_strength_bonus = 0
	passive_agility_bonus = 0
	passive_vitality_bonus = 0
	passive_endurance_bonus = 0
	passive_intelligence_bonus = 0
	passive_wisdom_bonus = 0
	passive_accuracy_bonus = 0
	passive_hp_bonus = 0
	passive_dodge_bonus = 0.0
	physical_damage_bonus = 0
	massive_damage_bonus = 0
	
	# Применяем бонусы от каждой активной способности
	for ability_id in active_passives:
		_apply_single_passive_bonus(ability_id)

# === ФУНКЦИИ ДЛЯ ПОДРОБНОЙ СТАТИСТИКИ ===

func get_max_health() -> int:
	"""Возвращает максимальное здоровье"""
	return max_hp

func get_max_hp() -> int:
	"""Возвращает максимальное здоровье (алиас для совместимости)"""
	return max_hp

func get_max_mana() -> int:
	"""Возвращает максимальную ману"""
	return max_mp

func get_max_stamina() -> int:
	"""Возвращает максимальную выносливость"""
	return max_stamina

func get_hp_regeneration() -> int:
	"""Возвращает регенерацию здоровья за раунд"""
	return hp_regen

func get_mp_regeneration() -> int:
	"""Возвращает регенерацию маны за раунд"""
	return mp_regen

func get_sp_regeneration() -> int:
	"""Возвращает регенерацию выносливости за раунд"""
	return stamina_regen

func get_action_points() -> int:
	"""Возвращает количество очков действий"""
	return action_points

func get_physical_damage_bonus() -> int:
	"""Возвращает бонус физического урона"""
	return physical_damage_bonus

func get_physical_damage() -> int:
	"""Возвращает урон для физических атак (базовый урон + бонус от Силы + бонусы от пассивных способностей)"""
	var base_damage = 10 + (level * 2)  # Базовый урон + бонус от уровня
	var strength_bonus = strength  # 1 урон за очко Силы
	return base_damage + strength_bonus + physical_damage_bonus

func add_physical_damage_bonus(bonus: int):
	"""Добавляет бонус к физическому урону (используется способностью 'Массивный')"""
	physical_damage_bonus += bonus
	massive_damage_bonus += bonus
	print("Добавлен бонус к физическому урону: +", bonus, " (общий: ", physical_damage_bonus, ")")

func remove_physical_damage_bonus(bonus: int):
	"""Удаляет бонус к физическому урону (используется способностью 'Массивный')"""
	physical_damage_bonus -= bonus
	massive_damage_bonus -= bonus
	print("Удален бонус к физическому урону: -", bonus, " (общий: ", physical_damage_bonus, ")")

func get_crit_chance() -> int:
	"""Возвращает шанс критического удара в процентах"""
	return int(crit_chance * 100)

func get_crit_damage_multiplier() -> float:
	"""Возвращает силу критического удара (множитель)"""
	return 1.5  # Базовая сила крита 150%

func get_dodge_chance() -> int:
	"""Возвращает шанс уворота в процентах"""
	return int(dodge_chance * 100)

func get_accuracy() -> int:
	"""Возвращает меткость в процентах"""
	return accuracy

func add_accuracy_bonus(bonus: int):
	"""Добавляет бонус к меткости"""
	passive_accuracy_bonus += bonus
	calculate_stat_bonuses()  # Пересчитываем характеристики

func remove_accuracy_bonus(bonus: int):
	"""Убирает бонус к меткости"""
	passive_accuracy_bonus -= bonus
	calculate_stat_bonuses()  # Пересчитываем характеристики

func add_dodge_bonus(bonus: float):
	"""Добавляет бонус к шансу уворота"""
	passive_dodge_bonus += bonus
	calculate_stat_bonuses()  # Пересчитываем характеристики

func remove_dodge_bonus(bonus: float):
	"""Удаляет бонус к шансу уворота"""
	passive_dodge_bonus -= bonus
	calculate_stat_bonuses()  # Пересчитываем характеристики

func get_speed_bonus() -> int:
	"""Возвращает бонус скорости в процентах"""
	# Базовое значение 0% + бонусы от пассивных способностей
	var base_speed = 0
	# TODO: Добавить бонусы от пассивных способностей
	return base_speed

func get_armor() -> int:
	"""Возвращает значение брони"""
	# Базовое значение 0 + бонусы от пассивных способностей
	var base_armor = 0
	# TODO: Добавить бонусы от пассивных способностей
	return base_armor

func get_magic_resistance() -> int:
	"""Возвращает магическое сопротивление в процентах"""
	# Базовое значение 0% + бонусы от пассивных способностей
	var base_magic_resist = 0
	# TODO: Добавить бонусы от пассивных способностей
	return base_magic_resist

func get_magic_damage_bonus() -> int:
	"""Returns magic damage bonus in percent"""
	# Base value 0% + 1% per Intelligence point + passive ability bonuses
	var base_magic_damage = 0
	var int_bonus = intelligence  # 1% per intelligence point
	# TODO: Add passive ability bonuses
	return base_magic_damage + int_bonus

func get_magic_crit_chance() -> int:
	"""Returns magic critical hit chance in percent"""
	# Base magic crit chance 5% + 1% per Intelligence point + passive ability bonuses
	var base_magic_crit = 5
	var int_bonus = intelligence  # 1% per intelligence point
	# TODO: Add passive ability bonuses
	return base_magic_crit + int_bonus

func get_magic_crit_damage() -> float:
	"""Returns magic critical damage multiplier"""
	# Base magic crit damage 1.5 + passive ability bonuses
	var base_magic_crit_damage = 1.5
	# TODO: Add passive ability bonuses
	return base_magic_crit_damage

# ============================================================================
# META-PROGRESSION SYSTEM (QUESTS AND ARTIFACTS)
# ============================================================================

func can_learn_passive_abilities() -> bool:
	"""Может ли игрок изучать пассивные способности врагов"""
	return has_soul_urn and soul_urn_delivered

func can_learn_soul_development() -> bool:
	"""Может ли игрок изучать способности развития души"""
	return has_soul_urn and soul_urn_delivered

func can_learn_passive_rarity(rarity: String) -> bool:
	"""Проверка доступности изучения способности по редкости"""
	if not can_learn_passive_abilities():
		return false
	
	match rarity.to_lower():
		"common", "uncommon", "rare":
			return max_passive_level >= 1
		"epic", "legendary":
			return max_passive_level >= 2
		"mythic":
			return max_passive_level >= 3
	return false

func can_learn_soul_development_level(development_level: int) -> bool:
	"""Проверка доступности уровня развития души"""
	if not can_learn_soul_development():
		return false
	return development_level <= max_soul_development_level

func get_max_soul_development_rarity() -> String:
	"""Возвращает максимальную доступную редкость для развития души"""
	match max_soul_development_level:
		0: return ""
		1: return "common"
		2: return "uncommon"
		3: return "rare"
		4: return "epic"
		5: return "legendary"
		6: return "mythic"
	return ""

# Квестовая система
func make_quest_available(quest_id: String):
	"""Делает квест доступным для взятия (золотой ! у NPC)"""
	if quest_id not in available_quests and quest_id not in active_quests and quest_id not in completed_quests:
		available_quests.append(quest_id)
		print("🟡 Квест доступен для взятия: ", quest_id)

func activate_quest(quest_id: String):
	"""Активирует доступный квест (перемещает из available в active, серый ? у NPC)"""
	if quest_id in available_quests:
		available_quests.erase(quest_id)
		active_quests.append(quest_id)
		print("📜 Квест активирован: ", quest_id)

func add_quest(quest_id: String):
	"""Добавляет квест напрямую в активные (для обратной совместимости)"""
	if quest_id not in active_quests:
		active_quests.append(quest_id)
		print("📜 Квест добавлен: ", quest_id)

func complete_quest(quest_id: String):
	"""Завершает квест"""
	if quest_id in active_quests:
		active_quests.erase(quest_id)
		if quest_id not in completed_quests:
			completed_quests.append(quest_id)
		print("✅ Квест завершен: ", quest_id)
	# Также убираем из доступных, если он там был
	if quest_id in available_quests:
		available_quests.erase(quest_id)

func is_quest_available(quest_id: String) -> bool:
	"""Проверяет, доступен ли квест для взятия"""
	return quest_id in available_quests

func is_quest_active(quest_id: String) -> bool:
	"""Проверяет, активен ли квест"""
	return quest_id in active_quests

func is_quest_completed(quest_id: String) -> bool:
	"""Проверяет, завершен ли квест"""
	return quest_id in completed_quests

# Артефакты
func give_soul_urn():
	"""Выдает игроку Урну душ"""
	has_soul_urn = true
	print("🏺 Получена Урна душ!")

func deliver_soul_urn():
	"""Доставляет Урну душ Скульптору"""
	if has_soul_urn:
		soul_urn_delivered = true
		soul_urn_reward_received = true  # Отмечаем, что награда получена
		max_passive_level = 1  # Открывает изучение до Rare
		max_soul_development_level = 2  # Открывает развитие души уровни 1-2
		complete_quest("find_soul_urn")
		print("🎉 Урна душ доставлена! Разблокировано изучение способностей!")
		return true
	return false

func give_knowledge_crystal():
	"""Выдает игроку Кристалл познания"""
	has_knowledge_crystal = true
	# НЕ завершаем квест здесь - квест завершится при доставке Скульптору
	print("💎 Получен Кристалл познания!")

func deliver_knowledge_crystal():
	"""Доставляет Кристалл познания Скульптору"""
	if has_knowledge_crystal:
		knowledge_crystal_delivered = true
		max_passive_level = 2  # Открывает изучение до Legendary
		max_soul_development_level = 4  # Открывает развитие души уровни 3-4
		complete_quest("find_knowledge_crystal")
		print("🎉 Кристалл познания доставлен! Разблокированы Epic и Legendary способности!")
		return true
	return false

func give_phylactery():
	"""Выдает игроку Филактерию некроманта"""
	has_phylactery = true
	# НЕ завершаем квест здесь - квест завершится при доставке Скульптору
	print("💀 Получена Филактерия!")

func deliver_phylactery():
	"""Доставляет Филактерию Скульптору"""
	if has_phylactery:
		phylactery_delivered = true
		max_passive_level = 3  # Открывает изучение Mythic способностей
		max_soul_development_level = 6  # Открывает развитие души уровни 5-6
		complete_quest("find_phylactery")
		print("🎉 Филактерия доставлена! Разблокированы Mythic способности!")
		return true
	return false

func give_ancient_skull():
	"""Выдает игроку Древний череп"""
	has_ancient_skull = true
	# НЕ завершаем квест здесь - квест завершится при доставке Скульптору
	print("💀 Получен Древний череп!")

func deliver_ancient_skull():
	"""Доставляет Древний череп Скульптору"""
	if has_ancient_skull:
		ancient_skull_delivered = true
		complete_quest("find_ancient_skull")
		print("🎉 Древний череп доставлен!")
		return true
	return false

# ============================================================================
# СИСТЕМА СЛОЖНОСТЕЙ ЛОКАЦИЙ
# ============================================================================

func get_unlocked_difficulty(location_id: String) -> int:
	"""Возвращает максимальную разблокированную сложность для локации (1-3)"""
	return unlocked_difficulties.get(location_id, 1)

func get_selected_difficulty(location_id: String) -> int:
	"""Возвращает выбранную сложность для локации (1-3)"""
	return selected_difficulty.get(location_id, 1)

func set_selected_difficulty(location_id: String, difficulty: int):
	"""Устанавливает выбранную сложность для локации"""
	var max_difficulty = get_unlocked_difficulty(location_id)
	selected_difficulty[location_id] = clamp(difficulty, 1, max_difficulty)
	print("Выбрана сложность ", selected_difficulty[location_id], " для локации ", location_id)

func unlock_next_difficulty(location_id: String):
	"""Разблокирует следующую сложность для локации"""
	var current_max = get_unlocked_difficulty(location_id)
	if current_max < 3:
		unlocked_difficulties[location_id] = current_max + 1
		print("🎯 Разблокирована сложность ", unlocked_difficulties[location_id], " для локации ", location_id)

func initialize_location_difficulty(location_id: String):
	"""Инициализирует сложность для новой локации"""
	if location_id not in unlocked_difficulties:
		unlocked_difficulties[location_id] = 1
	if location_id not in selected_difficulty:
		selected_difficulty[location_id] = 1
	if location_id not in unlocked_location_bosses:
		unlocked_location_bosses[location_id] = false
	if location_id not in selected_mode:
		selected_mode[location_id] = "normal"

func unlock_location_boss(location_id: String):
	"""Разблокирует босса локации"""
	unlocked_location_bosses[location_id] = true
	print("🎯 Босс локации разблокирован для ", location_id)

func is_location_boss_unlocked(location_id: String) -> bool:
	"""Проверяет, разблокирован ли босс локации"""
	return unlocked_location_bosses.get(location_id, false)

func set_selected_mode(location_id: String, mode: String):
	"""Устанавливает выбранный режим для локации (normal или boss)"""
	if mode == "boss" and not is_location_boss_unlocked(location_id):
		print("ОШИБКА: Попытка выбрать босса локации, который не разблокирован")
		return
	selected_mode[location_id] = mode
	print("Выбран режим ", mode, " для локации ", location_id)

func get_selected_mode(location_id: String) -> String:
	"""Возвращает выбранный режим для локации"""
	return selected_mode.get(location_id, "normal")

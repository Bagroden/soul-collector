# scripts/battle/body.gd
extends Node2D
signal died
signal attacked(amount)

@export var display_name: String = "Entity"
@export var level: int = 1
@export var max_hp: int = 50
@export var hp: int = 50
@export var max_mp: int = 10
@export var mp: int = 10
@export var max_stamina: int = 100
@export var stamina: int = 100
@export var attack_power: int = 10
@export var defense: int = 0
@export var rarity: String = "common" # common / rare / epic etc.
@export var passive_list: Array = ["quick_bite"] # список строк-пассивок
@export var passive_abilities: Array[PassiveAbility] = [] # активные пассивные способности
var ability_levels: Dictionary = {} # уровни способностей: {ability_id: level}
var ability_cooldowns: Dictionary = {} # текущие кулдауны способностей: {ability_id: remaining_turns}
var effects: Dictionary = {} # активные эффекты
var damage_bonuses: Dictionary = {} # бонусы к урону
var last_attack_damage: int = 0 # последний полученный урон (до применения защиты)
var last_attack_was_crit: bool = false # был ли последний урон критическим
var last_attack_damage_type: String = "physical" # тип последнего урона
var last_attack_type: String = "normal" # тип последней атаки: normal, counter_attack, ability
var pending_counter_attack: Dictionary = {} # отложенная контратака: {"damage": int, "target": Node}
var pending_reflected_damage: Dictionary = {} # отложенное отражение урона: {"damage": int, "target": Node}

# Новые механики
var base_dodge_chance: float = 5.0 # базовый шанс уворота для всех
var current_dodge_chance: float = 5.0 # текущий шанс уворота
var actions_per_turn: int = 1 # количество действий за ход
var extra_action_chance: float = 0.0 # шанс получить дополнительное действие
var has_extra_action: bool = false # есть ли дополнительное действие в этом ходу
var action_points: int = 1 # очки действий (по умолчанию 1)

# Отслеживание урона за раунд для способности "Месть"
var damage_this_round: int = 0 # урон, полученный в текущем раунде
var speed_triggered_round: int = -1 # номер раунда, когда сработала скорость
var max_action_points: int = 1 # максимальные очки действий
var processing_effects: bool = false # флаг для отслеживания обработки эффектов
var using_ability: bool = false # флаг использования способности (для предотвращения дублирования логирования)
var wound_chance: float = 0.0 # шанс нанести рану
var lifesteal_chance: float = 0.0 # шанс вампиризма
var lifesteal_percent: float = 0.0 # процент вампиризма
var true_sight: bool = false # видит невидимых
var spell_failure_chance: float = 0.0 # шанс провала заклинаний
var flat_damage_reduction: float = 0.0 # плоское снижение урона
var percentage_damage_reduction: float = 0.0 # процентное снижение урона
var armor_reduction: float = 0.0 # снижение брони (может быть отрицательным)

# Характеристики
@export var strength: int = 10      # Сила - бонус к урону
@export var agility: int = 10       # Ловкость - шанс крита
@export var vitality: int = 10      # Живучесть - ХП и реген ХП
@export var endurance: int = 10     # Выносливость - ОВ и реген ОВ
@export var accuracy: int = 100

# Магический барьер
var magic_barrier: int = 0  # Текущее количество барьера
var max_magic_barrier: int = 0  # Максимальное количество барьера     # Меткость - шанс попадания (100% = 100)
@export var intelligence: int = 10  # Интеллект - магический урон
@export var wisdom: int = 10        # Мудрость - МП и реген МП
@export var magic_resistance: int = 0  # Магическое сопротивление (снижает магический урон)
@export var magic_resistance_percent: float = 0.0  # Процентное сопротивление магии

# Система уровней для врагов
@export var base_hp: int = 50       # Базовое ОЗ без бонусов от уровня
@export var base_mp: int = 10       # Базовое ОМ без бонусов от уровня
@export var base_stamina: int = 100 # Базовое ОВ без бонусов от уровня
@export var base_attack: int = 10   # Базовый урон без бонусов от уровня

# Бонусы от характеристик (вычисляются автоматически)
var bonus_damage: int = 0
var crit_chance: float = 0.0
var hp_regen: int = 0
var stamina_regen: int = 0
var magic_damage_bonus: float = 0.0
var magic_crit_chance: float = 0.0
var mp_regen: int = 0
var defense_from_vitality: int = 0  # Бонус защиты от живучести (1 защита за каждые 3 единицы живучести)

func _ready():
	calculate_stat_bonuses()
	apply_stat_bonuses()
	# При инициализации устанавливаем полные ресурсы
	hp = max_hp
	mp = max_mp
	stamina = max_stamina

func is_dead() -> bool:
	return hp <= 0

func reduce_ability_cooldowns():
	"""Уменьшает кулдауны всех способностей на 1 ход в начале хода персонажа"""
	for ability_id in ability_cooldowns.keys():
		if ability_cooldowns[ability_id] > 0:
			ability_cooldowns[ability_id] -= 1
			if ability_cooldowns[ability_id] <= 0:
				ability_cooldowns.erase(ability_id)  # Удаляем способность с нулевым кулдауном

func is_ability_on_cooldown(ability_id: String) -> bool:
	"""Проверяет, находится ли способность на кулдауне"""
	return ability_cooldowns.has(ability_id) and ability_cooldowns[ability_id] > 0

func set_ability_cooldown(ability_id: String, cooldown: int):
	"""Устанавливает кулдаун для способности"""
	if cooldown > 0:
		ability_cooldowns[ability_id] = cooldown

func get_base_attack_damage() -> int:
	"""Возвращает урон базовой атаки в зависимости от типа врага"""
	# Проверяем, является ли враг магом (высокий интеллект и мудрость)
	var is_mage = intelligence >= agility and intelligence >= strength
	
	if is_mage:
		# Для магов: урон = интеллект + мудрость
		return intelligence + wisdom
	else:
		# Для бойцов: урон = сила + ловкость
		return strength + agility

func take_damage(amount: int, damage_type: String = "physical") -> void:
	# Сохраняем исходный урон для логирования
	last_attack_damage = amount
	# Сбрасываем тип атаки на normal (если не установлен другой)
	if last_attack_type == "":
		last_attack_type = "normal"
	
	# Проверяем гарантированный уворот
	if has_effect("guaranteed_dodge"):
		remove_effect("guaranteed_dodge")  # Убираем эффект после использования
		# Логируем уворот
		_log_passive_ability("Гарантированный уворот", true, display_name + " увернулся!")
		return
	
	# Проверяем обычный уворот
	if has_effect("dodge_block"):
		var effect = effects.get("dodge_block", {})
		if effect is Dictionary:
			var damage_blocked = effect.get("damage_blocked", 0)
			if amount <= damage_blocked:
				# Полный уворот - убираем эффект после использования
				remove_effect("dodge_block")
				# Логирование уворота теперь происходит в _calculate_hit_chance
				return
			else:
				# Частичный уворот - уменьшаем урон и убираем эффект
				amount = max(0, amount - damage_blocked)
				remove_effect("dodge_block")
		else:
			print("ОШИБКА: dodge_block не является словарем! Удаляем...")
			remove_effect("dodge_block")
	
	# Проверяем защиту
	if has_effect("defend"):
		var effect = effects.get("defend", {})
		if effect is Dictionary:
			var damage_reduction = effect.get("damage_reduction", 0.0)
			if damage_reduction > 0:
				amount = int(amount * (1.0 - damage_reduction))
		else:
			print("ОШИБКА: defend не является словарем! Удаляем...")
			remove_effect("defend")
	
	var final: int
	if damage_type == "magic":
		# Магический урон - учитываем плоское и процентное сопротивление
		var flat_resistance = get_effective_magic_resistance()
		var percentage_resistance = get_magic_resistance_percentage()
		
		# Сначала применяем процентное сопротивление
		var after_percentage = int(amount * (1.0 - percentage_resistance / 100.0))
		# Затем применяем плоское сопротивление
		final = max(0, after_percentage - flat_resistance)
	elif damage_type == "poison":
		# Ядовитый урон - не учитывает защиту и магическое сопротивление
		# Может быть модифицирован только специальными пассивными способностями
		final = amount
	else:
		# Физический урон - получаем эффективную защиту через централизованную функцию
		var effective_defense = get_effective_defense()
		
		# Проверяем эффект игнорирования брони
		if has_effect("armor_ignore"):
			effective_defense = 0  # Игнорируем всю защиту
		
		if effective_defense >= 0:
			final = max(0, amount - effective_defense)
		else:
			# Отрицательная броня увеличивает урон на 1.5% за единицу (более агрессивное масштабирование)
			# Например, -10 брони = +15% урона
			final = int(amount * (1.0 + abs(effective_defense) * 0.015))
	
	# Применяем процентное снижение урона (работает для всех типов урона)
	if percentage_damage_reduction > 0:
		final = int(final * (1.0 - percentage_damage_reduction / 100.0))
	
	# Применяем плоское снижение урона (работает для всех типов урона)
	if flat_damage_reduction > 0:
		final = max(0, final - flat_damage_reduction)
	
	# Применяем Выносливость орка (ork_vitality) - снижение урона за каждый процент потерянного здоровья
	for ability in passive_abilities:
		if ability.id == "ork_vitality":
			var ability_level = ability_levels.get(ability.id, 1)
			var reduction_per_hp_percent = ability.get_value_for_level(ability_level)  # 0.1/0.2/0.3
			var hp_lost_percent = 100.0 - ((float(hp) / float(max_hp)) * 100.0)  # Процент потерянного HP
			var ork_vitality_reduction = reduction_per_hp_percent * hp_lost_percent  # % снижения урона
			if ork_vitality_reduction > 0:
				final = int(final * (1.0 - ork_vitality_reduction / 100.0))
			# Обновляем эффект для визуального отображения
			if has_effect("ork_vitality"):
				var effect = get_effect_safe("ork_vitality")
				if effect.size() > 0:
					effect["damage_reduction_percent"] = ork_vitality_reduction
					effect["reduction_per_hp_percent"] = reduction_per_hp_percent
			break
	
	# Сначала урон отнимается от магического барьера
	var barrier_damage = 0
	var health_damage = final
	
	if has_magic_barrier() and final > 0:
		barrier_damage = min(final, magic_barrier)
		health_damage = final - barrier_damage
		remove_magic_barrier(barrier_damage)
	
	# Остальной урон отнимается от здоровья
	hp = clamp(hp - health_damage, 0, max_hp)
	
	# Отслеживаем урон за раунд для способности "Месть"
	if health_damage > 0:
		add_damage_this_round(health_damage)
	
	# Проигрываем анимацию hurt для врагов (не для игрока)
	if health_damage > 0 and display_name != "Player" and display_name != "Игрок":
		var visual = get_node_or_null("Visual")
		if visual and visual.has_method("play_hurt"):
			visual.play_hurt()
	
	emit_signal("attacked", final)
	if hp <= 0:
		emit_signal("died")

func heal(amount: int) -> void:
	# Применяем снижение эффективности лечения от эффекта "Рана"
	var healing_reduction = 0.0
	if "wound" in effects:
		var wound_effect = get_effect_safe("wound")
		if wound_effect.size() > 0:
			var stacks = wound_effect.get("stacks", 1)
			var reduction_per_stack = wound_effect.get("healing_reduction", 20.0)
			healing_reduction = reduction_per_stack * stacks  # 20% за стак, максимум 60% при 3 стаках
	
	# Применяем снижение эффективности лечения
	var effective_amount = amount
	if healing_reduction > 0:
		effective_amount = int(amount * (1.0 - healing_reduction / 100.0))
		if effective_amount < 0:
			effective_amount = 0
	
	var _old_hp = hp  # Сохраняем старое HP на случай будущего использования
	hp = clamp(hp + effective_amount, 0, max_hp)
	
	# Проверяем деактивацию Берсерка при лечении (если HP стало выше порога)
	if has_meta("berserk_active") and has_effect("berserk"):
		var effect = effects["berserk"]
		var hp_threshold = effect.get("hp_threshold", 20.0)
		var hp_percent = (float(hp) / float(max_hp)) * 100.0
		
		if hp_percent > hp_threshold:
			# Деактивируем берсерк
			remove_meta("berserk_active")
			remove_meta("berserk_multiplier")
			remove_effect("berserk")
	
	# Обновляем эффект Выносливости орка (ork_vitality) при изменении HP
	if has_effect("ork_vitality"):
		for ability in passive_abilities:
			if ability.id == "ork_vitality":
				var ability_level = ability_levels.get(ability.id, 1)
				var reduction_per_hp_percent = ability.get_value_for_level(ability_level)
				var hp_lost_percent = 100.0 - ((float(hp) / float(max_hp)) * 100.0)
				var damage_reduction_percent = reduction_per_hp_percent * hp_lost_percent
				
				var effect = effects["ork_vitality"]
				effect["damage_reduction_percent"] = damage_reduction_percent
				effect["reduction_per_hp_percent"] = reduction_per_hp_percent
				break
	
	# Логирование происходит в пассивных способностях, не дублируем здесь

func get_effective_defense() -> int:
	"""Возвращает эффективную защиту с учетом всех модификаторов"""
	var total_defense = defense  # Базовая защита
	
	# Добавляем бонус от живучести
	total_defense += defense_from_vitality
	
	# Вычитаем снижение брони (дебафы)
	total_defense -= armor_reduction
	
	# Проверяем временные эффекты, увеличивающие защиту
	if "defense_buff" in effects:
		var buff = effects["defense_buff"]
		var bonus = buff.get("defense_bonus", 0)
		total_defense += bonus
	
	# Проверяем эффект игнорирования брони (для атакующего)
	# Это проверяется отдельно в take_damage, здесь просто возвращаем полное значение
	
	return max(0, total_defense)  # Защита не может быть отрицательной для отображения

func get_effective_magic_resistance() -> int:
	"""Возвращает эффективное магическое сопротивление с учетом эффектов"""
	var effective_resistance = magic_resistance
	
	# Проверяем эффекты, которые влияют на магическое сопротивление
	if "curse" in effects:
		var curse_effect = effects["curse"]
		var resistance_reduction = curse_effect.get("resistance_reduction", 0.0)
		effective_resistance = int(effective_resistance * (1.0 - resistance_reduction))
	
	return max(0, effective_resistance)

func get_magic_resistance_percentage() -> float:
	"""Возвращает процентное сопротивление магии с учетом эффектов"""
	var effective_percentage = magic_resistance_percent
	
	# Проверяем эффекты, которые влияют на процентное сопротивление магии
	if "curse" in effects:
		var curse_effect = effects["curse"]
		var resistance_reduction = curse_effect.get("resistance_reduction", 0.0)
		effective_percentage = effective_percentage * (1.0 - resistance_reduction)
	
	return max(0.0, effective_percentage)

func get_accuracy() -> int:
	"""Возвращает меткость в процентах"""
	var base_accuracy = accuracy
	
	# Применяем эффект нейротоксина
	if has_effect("neurotoxin"):
		var effect = effects["neurotoxin"]
		var stacks = effect.get("stacks", 1)
		var accuracy_reduction = effect.get("accuracy_reduction", 5.0)
		base_accuracy -= int(accuracy_reduction * stacks)
	
	# Применяем эффект Боевого безумия (berserker_fury) - штраф к меткости
	if has_effect("berserker_fury"):
		var effect = effects["berserker_fury"]
		var stacks = effect.get("stacks", 1)
		var accuracy_penalty_per_stack = effect.get("accuracy_penalty_per_stack", 5.0)
		base_accuracy -= int(accuracy_penalty_per_stack * stacks)
	
	return max(5, base_accuracy)  # Минимум 5% меткости

func get_dodge_chance() -> int:
	"""Возвращает шанс уворота в процентах"""
	return int(current_dodge_chance)

func reset_full() -> void:
	hp = max_hp
	mp = max_mp
	stamina = max_stamina

func calculate_stat_bonuses() -> void:
	# Сила: 1 сила = 1 урона
	bonus_damage = strength
	
	# Ловкость: 1 ловкость = 1% шанс крита
	crit_chance = float(agility) / 100.0
	
	# Живучесть: 1 живучесть = 10 ХП, каждые 10 = 1 реген ХП, каждые 3 = 1 защита
	hp_regen = int(float(vitality) / 10.0)
	defense_from_vitality = int(float(vitality) / 3.0)
	
	# Выносливость: 1 выносливость = 5 ОВ, каждые 3 = 1 реген ОВ
	stamina_regen = int(float(endurance) / 3.0)
	
	# Интеллект: 1 интеллект = 1% магический урон и 1% магический крит
	magic_damage_bonus = float(intelligence) / 100.0
	magic_crit_chance = float(intelligence) / 100.0
	
	# Мудрость: 1 мудрость = 10 МП, каждые 5 = 1 реген МП
	mp_regen = int(float(wisdom) / 5.0)

func apply_stat_bonuses() -> void:
	# Применяем бонусы к базовым характеристикам + бонусы от уровня
	# НО только если max_hp еще не был изменен бонусами редкости
	var expected_max_hp = base_hp + (vitality * 10) + (level * 10)
	if max_hp <= expected_max_hp:
		max_hp = expected_max_hp
	
	var expected_max_mp = base_mp + (wisdom * 10) + (level * 10)
	if max_mp <= expected_max_mp:
		max_mp = expected_max_mp
	
	var expected_max_stamina = base_stamina + (endurance * 5) + (level * 10)
	if max_stamina <= expected_max_stamina:
		max_stamina = expected_max_stamina
	
	var expected_attack_power = base_attack + (level * 2)
	# Для attack_power используем ту же логику, что и для max_hp
	if attack_power <= expected_attack_power:
		attack_power = expected_attack_power
	
	# НЕ сбрасываем текущие значения - они должны сохраняться
	# hp, mp, stamina остаются неизменными

func apply_enemy_stat_bonuses() -> void:
	# Специальная функция для врагов - добавляет бонусы к уже установленным значениям
	max_hp += vitality * 10  # Добавляем бонус от живучести к существующему HP
	max_mp += wisdom * 10    # Добавляем бонус от мудрости к существующему MP
	max_stamina += endurance * 5  # Добавляем бонус от выносливости к существующей выносливости

func set_enemy_level(new_level: int) -> void:
	# Устанавливаем уровень врага и пересчитываем характеристики
	level = new_level
	
	# Добавляем случайные характеристики за каждый уровень
	_add_random_level_stats()
	
	calculate_stat_bonuses()
	apply_stat_bonuses()
	# Устанавливаем полные ресурсы
	hp = max_hp
	mp = max_mp
	stamina = max_stamina

func _add_random_level_stats():
	"""Добавляет случайные характеристики за каждый уровень врага"""
	# Каждый уровень дает 3 случайных очка характеристик
	var total_points = level * 3
	
	# Список характеристик для случайного распределения
	var stats = ["strength", "agility", "vitality", "endurance", "intelligence", "wisdom"]
	
	# Распределяем очки случайно
	for i in range(total_points):
		var random_stat = stats[randi() % stats.size()]
		match random_stat:
			"strength":
				strength += 1
			"agility":
				agility += 1
			"vitality":
				vitality += 1
			"endurance":
				endurance += 1
			"intelligence":
				intelligence += 1
			"wisdom":
				wisdom += 1
	
	print("Враг %s (ур. %d) получил %d случайных очков характеристик" % [display_name, level, total_points])
	print("Итоговые характеристики: Сила=%d, Ловкость=%d, Живучесть=%d, Выносливость=%d, Интеллект=%d, Мудрость=%d" % [strength, agility, vitality, endurance, intelligence, wisdom])

func test_scaling_system():
	"""Тестирует систему масштабирования характеристик"""
	
	# Сохраняем исходные характеристики
	var original_stats = {
		"strength": strength,
		"agility": agility, 
		"vitality": vitality,
		"endurance": endurance,
		"intelligence": intelligence,
		"wisdom": wisdom
	}
	
	print("Исходные характеристики: %s" % original_stats)
	
	# Тестируем разные уровни
	for test_level in [1, 5, 10, 15, 20]:
		# Сбрасываем характеристики к исходным
		strength = original_stats.strength
		agility = original_stats.agility
		vitality = original_stats.vitality
		endurance = original_stats.endurance
		intelligence = original_stats.intelligence
		wisdom = original_stats.wisdom
		
		# Устанавливаем уровень
		set_enemy_level(test_level)
		
		# Вычисляем общее количество добавленных очков
		var total_added = (strength - original_stats.strength) + (agility - original_stats.agility) + (vitality - original_stats.vitality) + (endurance - original_stats.endurance) + (intelligence - original_stats.intelligence) + (wisdom - original_stats.wisdom)
		
		print("Уровень %d: Всего добавлено %d очков (ожидалось %d)" % [test_level, total_added, test_level * 5])
		print("  HP: %d, MP: %d, Атака: %d" % [max_hp, max_mp, attack_power])
	

func get_total_damage() -> int:
	var total_damage = attack_power + bonus_damage
	
	# Добавляем временные бонусы к урону
	var damage_bonus = get_stat_bonus("damage_bonus")
	if damage_bonus > 0:
		total_damage = int(total_damage * (1.0 + damage_bonus / 100.0))
	
	# Проверяем эффект "final_judgment" для усиленной контратаки
	if has_effect("final_judgment"):
		var effect = effects["final_judgment"]
		var damage_multiplier = effect.get("damage_multiplier", 3.0)
		total_damage = int(total_damage * damage_multiplier)
		# Убираем эффект после использования
		remove_effect("final_judgment")
	
	# Применяем множитель Берсерка (berserk) - огромный урон при критическом состоянии
	if has_meta("berserk_active"):
		var berserk_multiplier = get_meta("berserk_multiplier", 1.0)
		total_damage = int(total_damage * berserk_multiplier)
	
	return total_damage

func get_crit_damage() -> int:
	return apply_crit_multiplier(get_total_damage())

func apply_crit_multiplier(base_damage: int) -> int:
	"""Применяет критический множитель к любому урону"""
	var crit_multiplier = 1.5  # Базовый критический множитель
	
	# Отладочная информация
	# Проверяем, есть ли способность "Гильотина палача"
	for ability in passive_abilities:
		if ability.id == "executioner_guillotine":
			crit_multiplier = ability.value  # Используем множитель из способности (3.0)
			break
	
	var final_damage = int(base_damage * crit_multiplier)
	return final_damage

func is_critical_hit() -> bool:
	return randf() < crit_chance

func is_magic_critical_hit() -> bool:
	return randf() < magic_crit_chance

func get_magic_damage(base_damage: int) -> int:
	var damage: int = base_damage
	damage = int(damage * (1.0 + magic_damage_bonus))
	if is_magic_critical_hit():
		damage = int(damage * 1.5)
	return damage

func regenerate_resources() -> void:
	# Не регенерируем ресурсы если персонаж мертв
	if is_dead():
		return
		
	# Регенерация ХП
	if hp < max_hp and hp_regen > 0:
		var old_hp = hp
		hp = min(hp + hp_regen, max_hp)
		var actual_heal = hp - old_hp
		if actual_heal > 0:
			_log_regeneration("hp", actual_heal)
	
	# Регенерация от "Кровь демона" (tharnok_mastery)
	if has_effect("demon_blood"):
		var effect = effects["demon_blood"]
		var stacks = effect.get("stacks", 1)
		var regen_percent = effect.get("regen_percent", 1.0)
		if hp < max_hp and stacks > 0:
			var heal_amount = int(max_hp * (regen_percent / 100.0) * stacks)
			var old_hp = hp
			hp = min(hp + heal_amount, max_hp)
			var actual_heal = hp - old_hp
			if actual_heal > 0:
				_log_regeneration("hp", actual_heal)
				if has_method("_log_passive_ability"):
					_log_passive_ability("Кровь демона", true, display_name + " восстанавливает " + str(actual_heal) + " HP (" + str(stacks) + " стак)")
	
	# Регенерация МП
	if mp < max_mp and mp_regen > 0:
		var old_mp = mp
		mp = min(mp + mp_regen, max_mp)
		var actual_restore = mp - old_mp
		if actual_restore > 0:
			_log_regeneration("mp", actual_restore)
	
	# Регенерация выносливости
	if stamina < max_stamina and stamina_regen > 0:
		var old_stamina = stamina
		stamina = min(stamina + stamina_regen, max_stamina)
		var actual_restore = stamina - old_stamina
		if actual_restore > 0:
			_log_regeneration("stamina", actual_restore)
	
	# Обрабатываем временные бонусы к характеристикам
	process_stat_bonuses()

func _log_regeneration(resource_type: String, amount: int):
	# Ищем battle_log в сцене
	var battle_log = get_node_or_null("/root/BattleScene/BattleLog")
	if not battle_log:
		# Пробуем найти через battle_manager
		var battle_manager = get_node_or_null("/root/BattleScene")
		if battle_manager and battle_manager.has_method("get_battle_log"):
			battle_log = battle_manager.get_battle_log()
		elif battle_manager and battle_manager.has_method("get") and battle_manager.get("battle_log"):
			battle_log = battle_manager.battle_log
	
	# Дополнительный fallback: рекурсивный поиск
	if not battle_log:
		var scene_tree = get_tree()
		if scene_tree:
			var root = scene_tree.root
			if root:
				battle_log = _find_battle_log_recursive(root)
	
	if battle_log and battle_log.has_method("log_regeneration"):
		# Передаем информацию о текущем значении ресурса
		var current_value = 0
		var max_value = 0
		match resource_type:
			"hp":
				current_value = hp
				max_value = max_hp
			"mp":
				current_value = mp
				max_value = max_mp
			"stamina":
				current_value = stamina
				max_value = max_stamina
		
		battle_log.log_regeneration(display_name, resource_type, amount, current_value, max_value)

func get_inspector_stats() -> Dictionary:
	# Возвращает характеристики из инспектора для синхронизации с глобальным менеджером
	return {
		"strength": strength,
		"agility": agility,
		"vitality": vitality,
		"endurance": endurance,
		"intelligence": intelligence,
		"wisdom": wisdom
	}

# Методы для работы с пассивными способностями
func add_passive_ability(ability: PassiveAbility, ability_level: int = 1):
	if ability and not passive_abilities.has(ability):
		passive_abilities.append(ability)
		ability_levels[ability.id] = ability_level
		# Применяем постоянные эффекты сразу
		_apply_passive_effects(ability)

func _apply_passive_effects(ability: PassiveAbility):
	"""Применяет постоянные эффекты пассивной способности"""
	match ability.id:
		"demon_strength":
			# Сила демона - постоянное увеличение урона
			var base_damage = attack_power
			var demon_bonus = int(base_damage * (ability.value / 100.0))
			add_damage_bonus(demon_bonus)
		"fighter":
			# Боец - постоянное увеличение физического урона
			# Бонус будет применяться в get_physical_damage() к итоговому урону
			pass
		"thief_agility":
			# Ловкость вора - постоянное увеличение ловкости
			agility += int(ability.value)
			# Пересчитываем бонусы от характеристик
			calculate_stat_bonuses()
		"magic_barrier":
			# Магический барьер - создается при активации способности
			# Здесь ничего не делаем, барьер создается в execute_ability
			pass
		"apprentice":
			# Ученик - бонус к мане применяется в execute_ability
			pass
		"magic_resistance":
			# Сопротивление магии - применяется через execute_ability
			pass
		"mana_absorption":
			# Поглощение маны - срабатывает при получении урона
			pass
		"storm_shaman":
			# Шаман бурь - срабатывает при атаке
			pass
		"orc_rage":
			# Сила орка - постоянное увеличение силы
			var ability_level = ability_levels.get(ability.id, 1)
			var strength_bonus = int(ability.get_value_for_level(ability_level))
			strength += strength_bonus
			# Пересчитываем бонусы от характеристик
			calculate_stat_bonuses()
		"mouse_pack":
			# Стайный инстинкт - постоянное увеличение ловкости
			# Бонус к ловкости будет учтен в get_total_agility
			pass
		"ninja_lethality":
			# Летальность - постоянное увеличение урона в спину
			pass
		"alkara_demon_lord":
			# Владыка демонов - постоянное увеличение силы и интеллекта
			strength += int(ability.value)
			intelligence += int(ability.value)
			# Пересчитываем бонусы от характеристик
			calculate_stat_bonuses()
		"tharnok_armor":
			# Броня Тарнока - постоянное увеличение защиты
			if not has_meta("tharnok_armor_applied"):
				var ability_level = ability_levels.get(ability.id, 1)
				var armor_bonus = int(ability.get_value_for_level(ability_level))
				defense += armor_bonus
				set_meta("tharnok_armor_applied", true)
				set_meta("tharnok_armor_bonus", armor_bonus)
		"dodge":
			# Уворот - постоянное увеличение шанса уворота
			# Для игрока бонус применяется через PlayerData, для врагов - через их характеристики
			current_dodge_chance = base_dodge_chance + ability.value
		"demon_vitality":
			# Живучесть Демона - постоянное увеличение живучести
			vitality += int(ability.value)
			# Пересчитываем бонусы от характеристик
			calculate_stat_bonuses()
			apply_stat_bonuses()  # Используем обычную функцию для пересчета
		"massive":
			# Массивный - постоянное увеличение урона от максимального здоровья (ослаблено в 2 раза)
			var ability_level = ability_levels.get(ability.id, 1)
			var current_max_hp = get_max_hp()
			var percentage = 0.01  # 1% по умолчанию
			match ability_level:
				1:
					percentage = 0.01  # 1% (было 2%)
				2:
					percentage = 0.02  # 2% (было 4%)
				3:
					percentage = 0.03  # 3% (было 6%)
			
			var damage_bonus = int(current_max_hp * percentage)
			physical_damage_bonus += damage_bonus
			massive_damage_bonus += damage_bonus
		
		# === ПАССИВНЫЕ СПОСОБНОСТИ ИГРОКА ===
		# Тестовые способности удалены
		"slime_vitality":
			# Живучесть слизня - постоянное увеличение HP на 20%/35%/50% в зависимости от уровня
			# Проверяем, не применен ли уже бонус (чтобы избежать повторного применения)
			if not has_meta("slime_vitality_applied"):
				var ability_level = ability_levels.get(ability.id, 1)
				# Используем правильное значение из level_values (в процентах, например 20.0 для 20%)
				var percentage_value = ability.get_value_for_level(ability_level)
				var percentage = percentage_value / 100.0  # Преобразуем проценты в дробь
				
				# Применяем увеличение к max_hp (базовое HP без бонуса от этой способности)
				var base_max_hp = max_hp
				var hp_increase = int(base_max_hp * percentage)
				max_hp += hp_increase
				hp = min(hp + hp_increase, max_hp)  # Восстанавливаем HP
				# Помечаем, что бонус применен
				set_meta("slime_vitality_applied", true)
				set_meta("slime_vitality_bonus", hp_increase)
		"slime_armor":
			# Слизистая броня - постоянное снижение урона на 3 единицы
			flat_damage_reduction += int(ability.value)
		"tharnok_shield":
			# Щит Тарнока - процентное блокирование урона
			var ability_level = ability_levels.get(ability.id, 1)
			var block_percent = ability.get_value_for_level(ability_level)
			percentage_damage_reduction += block_percent

func remove_passive_ability(ability_id: String):
	for i in range(passive_abilities.size()):
		if passive_abilities[i].id == ability_id:
			_remove_passive_effects(passive_abilities[i])
			passive_abilities.remove_at(i)
			break

func _remove_passive_effects(ability: PassiveAbility):
	"""Удаляет постоянные эффекты пассивной способности"""
	match ability.id:
		"dodge":
			# Уворот - удаляем бонус к шансу уворота
			# Для игрока бонус удаляется через PlayerData, для врагов - через их характеристики
			current_dodge_chance = base_dodge_chance
		"fighter":
			# Боец - бонус применяется в get_physical_damage(), ничего не нужно удалять
			pass
		"thief_agility":
			# Ловкость вора - удаляем бонус к ловкости
			agility -= int(ability.value)
			# Пересчитываем бонусы от характеристик
			calculate_stat_bonuses()
		"magic_barrier":
			# Магический барьер - удаляем барьер при деактивации
			magic_barrier = 0
			max_magic_barrier = 0
		"apprentice":
			# Ученик - бонус к мане удаляется в execute_ability при деактивации
			pass
		"magic_resistance":
			# Сопротивление магии - удаляется через execute_ability при деактивации
			pass
		"mana_absorption":
			# Поглощение маны - ничего не нужно удалять
			pass
		"storm_shaman":
			# Шаман бурь - ничего не нужно удалять
			pass
		"massive":
			# Массивный - удаляем бонус урона от максимального здоровья (ослаблено в 2 раза)
			var ability_level = ability_levels.get(ability.id, 1)
			var current_max_hp = get_max_hp()
			var percentage = 0.01  # 1% по умолчанию
			match ability_level:
				1:
					percentage = 0.01  # 1% (было 2%)
				2:
					percentage = 0.02  # 2% (было 4%)
				3:
					percentage = 0.03  # 3% (было 6%)
			
			var damage_bonus = int(current_max_hp * percentage)
			physical_damage_bonus -= damage_bonus
			massive_damage_bonus -= damage_bonus
		"slime_vitality":
			# Живучесть слизня - удаляем бонус к HP
			if has_meta("slime_vitality_applied"):
				var hp_bonus = get_meta("slime_vitality_bonus", 0)
				max_hp -= hp_bonus
				hp = min(hp, max_hp)  # Убеждаемся, что текущее HP не превышает максимум
				remove_meta("slime_vitality_applied")
				remove_meta("slime_vitality_bonus")
		"slime_armor":
			# Слизистая броня - удаляем бонус к снижению урона
			flat_damage_reduction -= int(ability.value)
		"tharnok_armor":
			# Броня Тарнока - удаляем бонус к защите
			if has_meta("tharnok_armor_applied"):
				var armor_bonus = get_meta("tharnok_armor_bonus", 0)
				defense -= armor_bonus
				remove_meta("tharnok_armor_applied")
				remove_meta("tharnok_armor_bonus")
		"tharnok_shield":
			# Щит Тарнока - удаляем процентное блокирование урона
			var ability_level = ability_levels.get(ability.id, 1)
			var block_percent = ability.get_value_for_level(ability_level)
			percentage_damage_reduction -= block_percent

func trigger_passive_abilities(trigger_type: PassiveAbility.TriggerType, target: Node = null, context: Dictionary = {}):
	for ability in passive_abilities:
		if ability.trigger_type == trigger_type:
			# Добавляем уровень способности в контекст
			var ability_context = context.duplicate()
			ability_context["ability_level"] = ability_levels.get(ability.id, 1)
			var result = ability.trigger(self, target, ability_context)
			if result.get("success", false):
				_handle_ability_result(result, target)
				_log_passive_ability(ability.name, true, result.get("message", ""))
			else:
				# Логируем неудачное срабатывание только для способностей, которые должны срабатывать часто
				# (например, уворот, контратака), но не для статических способностей
				var should_log_failure = ability.id in ["dodge", "agility_dodge", "mouse_nimble", "quick_strike", "sneaky_strike"]
				if should_log_failure:
					_log_passive_ability(ability.name, false, result.get("message", ""))
	

func _handle_ability_result(result: Dictionary, target: Node):
	var effect = result.get("effect", "")
	match effect:
		"dodge", "agility_dodge", "mouse_nimble":
			# Уворот - предотвращаем урон
			var damage_blocked = result.get("damage_blocked", 0)
			if damage_blocked > 0:
				# Добавляем эффект уворота, который предотвратит урон
				add_effect("dodge_block", 1.0, 1, {"damage_blocked": damage_blocked})
		"agility_counter_attack":
			# Контратака при уклонении - сохраняем информацию для нанесения урона позже
			var counter_damage = result.get("counter_attack_damage", 0)
			# Сохраняем информацию о контратаке для battle_manager
			if has_method("set_pending_counter_attack"):
				set_pending_counter_attack(counter_damage, target)
		"quick_strike":
			# Дополнительная атака - НЕ наносим урон здесь, это будет обработано в battle_manager
			pass
		"tharnok_guardian":
			# Страж Тарнока - отражение урона обрабатывается в battle_manager
			# Сохраняем информацию об отраженном уроне для обработки в battle_manager
			var reflected_damage = result.get("reflected_damage", 0)
			if reflected_damage > 0 and target:
				set_pending_reflected_damage(reflected_damage, target)
		"bleeding":
			# Кровотечение
			if target:
				var source_id = get_instance_id()
				target.add_effect("bleeding", 3.0, 1, {"source_id": source_id})
		"wound":
			# Рана - снижает эффективность лечения
			if target:
				var healing_reduction = result.get("healing_reduction", 20.0)
				# Проверяем, есть ли уже эффект раны
				if "wound" in target.effects:
					var existing_effect = target.effects["wound"]
					var current_stacks = existing_effect.get("stacks", 1)
					# Увеличиваем стаки (максимум 3)
					existing_effect["stacks"] = min(current_stacks + 1, 3)
					existing_effect["duration"] = max(existing_effect.get("duration", 0), 3.0)
				else:
					target.add_effect("wound", 3.0, 1, {"healing_reduction": healing_reduction})
		"acid_hits":
			# Кислотные удары - снижают броню
			# Эффект коррозии брони обновляется в reduce_armor, здесь ничего не делаем
			# чтобы избежать двойного обновления
			pass
		"life_steal":
			# Вампиризм
			var heal_amount = result.get("heal_amount", 0)
			if heal_amount > 0:
				heal(heal_amount)
		"slime_regeneration":
			# Регенерация слизи - heal() уже вызван в execute_ability
			pass
		"rat_vitality_regen":
			# Крысиная живучесть - heal() уже вызван в execute_ability
			pass
		"alkara_vampirism":
			# Вампиризм Алкары - heal() уже вызван в execute_ability
			pass
		"life_steal_epic":
			# Эпический вампиризм - heal() уже вызван в execute_ability
			pass
		"executioner_rage":
			# Ярость палача - добавляем бонус к урону
			var rage_bonus = result.get("bonus_damage", 0)
			if rage_bonus > 0:
				add_damage_bonus(rage_bonus)
		"rat_bite":
			# Крысиный укус - дополнительный урон
			var extra_damage = result.get("extra_damage", 0)
			if extra_damage > 0 and target:
				target.take_damage(extra_damage)
		"restlessness":
			# Суетливость - дополнительная атака с уменьшенным уроном
			if owner and owner.has_method("add_effect"):
				owner.add_effect("restlessness_attack", 1.0, 1, {"damage_reduction": result.get("damage_reduction", 0.4)})
		"curse":
			# Проклятие - снижает магическое сопротивление
			if target and target.has_method("add_effect"):
				var duration = result.get("duration", 3.0)
				var stacks = result.get("stacks", 1)
				target.add_effect("curse", duration, stacks, {"resistance_reduction": 0.5})
		"poison":
			# Яд - накладывает эффект отравления
			if target and target.has_method("add_effect"):
				var duration = result.get("duration", 5.0)
				var stacks = result.get("stacks", 1)
				target.add_effect("poison", duration, stacks)
		"stealth":
			# Невидимость - накладывает эффект скрытности
			if owner and owner.has_method("add_effect"):
				var duration = result.get("duration", 2.0)
				var stacks = result.get("stacks", 1)
				owner.add_effect("stealth", duration, stacks)
		"mouse_pack":
			# Ловкий - постоянное увеличение ловкости
			pass
		"mouse_king":
			# Смертельный уворот - контратака при увороте
			var counter_damage = result.get("counter_damage", 0)
			if counter_damage > 0 and target:
				target.take_damage(counter_damage)
		"alkara_demon_lord":
			# Владыка демонов - постоянное увеличение характеристик
			pass
		"executioner_final":
			# Последний приговор - предотвращает смерть
			var hp_set_to = result.get("hp_set_to", 1)
			hp = hp_set_to
		"ninja_master":
			# Мастер ниндзя - гарантированный уворот после удара в спину
			if owner and owner.has_method("add_effect"):
				var duration = result.get("duration", 1.0)
				var stacks = result.get("stacks", 1)
				owner.add_effect("guaranteed_dodge", duration, stacks)
		# "executioner_guillotine" больше не обрабатывается здесь - это постоянная способность

func add_effect(effect_id: String, duration: float = 0.0, stacks: int = 1, effect_data: Dictionary = {}):
	# Проверяем, блокирует ли магический барьер этот эффект
	if has_magic_barrier() and effect_id in ["bleeding", "poison", "neurotoxin"]:
		# Логируем блокировку эффекта
		_log_magic_barrier_block(effect_id)
		return
	
	# Если указан source_id, создаем уникальный ключ для каждого источника эффекта
	var source_id = effect_data.get("source_id", 0)
	var effect_key = effect_id
	if source_id != 0:
		effect_key = effect_id + "_" + str(source_id)
		# Проверяем, есть ли уже эффект от этого источника
		if effect_key in effects:
			var existing_effect = effects[effect_key]
			# Увеличиваем стаки (максимум 3 для кровотечения, яда и раны, 5 для Крови демона)
			if effect_id == "bleeding":
				existing_effect["stacks"] = min(existing_effect.get("stacks", 1) + stacks, 3)
				existing_effect["duration"] = max(existing_effect.get("duration", 0), duration)
			elif effect_id == "poison":
				existing_effect["stacks"] = min(existing_effect.get("stacks", 1) + stacks, 3)
				existing_effect["duration"] = max(existing_effect.get("duration", 0), duration)
			elif effect_id == "wound":
				existing_effect["stacks"] = min(existing_effect.get("stacks", 1) + stacks, 3)
				existing_effect["duration"] = max(existing_effect.get("duration", 0), duration)
				if "healing_reduction" in effect_data:
					existing_effect["healing_reduction"] = effect_data["healing_reduction"]
			elif effect_id == "demon_blood":
				existing_effect["stacks"] = min(existing_effect.get("stacks", 1) + stacks, 5)
				existing_effect["duration"] = max(existing_effect.get("duration", 0), duration)
				if "regen_percent" in effect_data:
					existing_effect["regen_percent"] = effect_data["regen_percent"]
			else:
				existing_effect["duration"] = max(existing_effect.get("duration", 0), duration)
				for key in effect_data:
					existing_effect[key] = effect_data[key]
			return
	
	# Если source_id не указан, используем старое поведение (обратная совместимость)
	# Проверяем, есть ли уже такой эффект
	if effect_id in effects:
		var existing_effect = effects[effect_id]
		# Убеждаемся, что effect_id сохранен в данных эффекта
		if not "effect_id" in existing_effect:
			existing_effect["effect_id"] = effect_id
		# Увеличиваем стаки (максимум 3 для кровотечения, яда и раны, 5 для Крови демона)
		if effect_id == "bleeding":
			existing_effect["stacks"] = min(existing_effect.get("stacks", 1) + stacks, 3)
			existing_effect["duration"] = max(existing_effect.get("duration", 0), duration)  # Обновляем длительность
		elif effect_id == "poison":
			existing_effect["stacks"] = min(existing_effect.get("stacks", 1) + stacks, 3)  # Максимум 3 стака для яда
			existing_effect["duration"] = max(existing_effect.get("duration", 0), duration)  # Обновляем длительность
		elif effect_id == "wound":
			existing_effect["stacks"] = min(existing_effect.get("stacks", 1) + stacks, 3)  # Максимум 3 стака для раны
			existing_effect["duration"] = max(existing_effect.get("duration", 0), duration)  # Обновляем длительность
			if "healing_reduction" in effect_data:
				existing_effect["healing_reduction"] = effect_data["healing_reduction"]
		elif effect_id == "demon_blood":
			existing_effect["stacks"] = min(existing_effect.get("stacks", 1) + stacks, 5)  # Максимум 5 стаков для Крови демона
			existing_effect["duration"] = max(existing_effect.get("duration", 0), duration)  # Обновляем длительность до 3 раундов
			# Обновляем процент регенерации из effect_data
			if "regen_percent" in effect_data:
				existing_effect["regen_percent"] = effect_data["regen_percent"]
		elif effect_id == "rotten":
			# Гниль стакается до максимум 5 стаков, без ограничений по длительности
			existing_effect["stacks"] = min(existing_effect.get("stacks", 1) + stacks, 5)
			existing_effect["duration"] = 999.0  # Гниль не имеет ограничений по длительности
			# Обновляем процент урона из effect_data (берем максимальный процент)
			if "damage_percent" in effect_data:
				existing_effect["damage_percent"] = max(existing_effect.get("damage_percent", 0.5), effect_data["damage_percent"])
		elif effect_id == "corrosive_armor":
			# Для коррозии брони обновляем только данные из effect_data, не трогаем duration и stacks
			# Duration всегда 999 для коррозии брони (до конца боя)
			existing_effect["duration"] = 999.0
			# Обновляем дополнительные данные эффекта (включая armor_reduction)
			# Важно: armor_reduction должен браться из текущего значения armor_reduction, а не из effect_data
			# так как effect_data может содержать только новое значение, а не накопленное
			if "armor_reduction" in effect_data:
				# Если в effect_data есть armor_reduction, используем его (это накопленное значение)
				existing_effect["armor_reduction"] = effect_data["armor_reduction"]
			# Обновляем остальные данные из effect_data
			for key in effect_data:
				if key != "duration" and key != "armor_reduction":  # Не перезаписываем duration и armor_reduction (уже обработано)
					existing_effect[key] = effect_data[key]
		else:
			# Для других эффектов просто обновляем длительность
			existing_effect["duration"] = max(existing_effect.get("duration", 0), duration)
			# Убеждаемся, что effect_id сохранен в данных эффекта
			if not "effect_id" in existing_effect:
				existing_effect["effect_id"] = effect_id
			# Обновляем дополнительные данные эффекта
			for key in effect_data:
				existing_effect[key] = effect_data[key]
	else:
		# Создаем новый эффект
		# Для гнили устанавливаем длительность 999.0 (без ограничений)
		var final_duration = duration
		if effect_id == "rotten":
			final_duration = 999.0
		
		effects[effect_key] = {
			"duration": final_duration,
			"stacks": stacks,
			"start_time": Time.get_time_dict_from_system(),
			"effect_id": effect_id  # Сохраняем оригинальный effect_id для обработки
		}
		# Добавляем дополнительные данные эффекта
		for key in effect_data:
			effects[effect_key][key] = effect_data[key]

func remove_effect(effect_id: String):
	if effect_id in effects:
		effects.erase(effect_id)

func get_effect_safe(effect_id: String) -> Dictionary:
	"""Безопасно получает эффект из словаря, проверяя его тип"""
	var effect = effects.get(effect_id, {})
	if effect is Dictionary:
		return effect
	else:
		print("ПРЕДУПРЕЖДЕНИЕ: Эффект '", effect_id, "' не является словарем! Возвращаем пустой словарь.")
		# Удаляем некорректный эффект
		remove_effect(effect_id)
		return {}

func has_effect(effect_id: String) -> bool:
	return effect_id in effects

func get_effect_stacks(effect_id: String) -> int:
	"""Возвращает количество стаков эффекта"""
	if effect_id in effects:
		return effects[effect_id].stacks
	return 0

func get_last_attack_damage() -> int:
	"""Возвращает последний полученный урон (до применения защиты)"""
	return last_attack_damage

func set_last_attack_type(attack_type: String) -> void:
	"""Устанавливает тип последней атаки"""
	last_attack_type = attack_type

func get_last_attack_type() -> String:
	"""Возвращает тип последней атаки"""
	return last_attack_type

func set_pending_counter_attack(damage: int, target: Node) -> void:
	"""Устанавливает отложенную контратаку"""
	pending_counter_attack = {"damage": damage, "target": target}

func get_pending_counter_attack() -> Dictionary:
	"""Возвращает отложенную контратаку"""
	return pending_counter_attack

func clear_pending_counter_attack() -> void:
	"""Очищает отложенную контратаку"""
	pending_counter_attack = {}

func set_pending_reflected_damage(damage: int, target: Node) -> void:
	"""Устанавливает отложенное отражение урона"""
	pending_reflected_damage = {"damage": damage, "target": target}

func get_pending_reflected_damage() -> Dictionary:
	"""Возвращает информацию об отложенном отражении урона"""
	return pending_reflected_damage

func clear_pending_reflected_damage() -> void:
	"""Очищает информацию об отложенном отражении урона"""
	pending_reflected_damage = {}

func add_damage_bonus(bonus: int):
	damage_bonuses["passive_bonus"] = bonus

func apply_damage_multiplier(multiplier: float):
	"""Применяет модификатор к текущему урону"""
	# Временно увеличиваем урон для текущей атаки
	attack_power = int(attack_power * multiplier)

func process_effects():
	# Обрабатываем эффекты в конце хода
	processing_effects = true  # Устанавливаем флаг обработки эффектов
	
	var _current_time = Time.get_time_dict_from_system()
	var effects_to_remove = []
	
	for effect_key in effects.keys():
		var effect = effects[effect_key]
		
		# Проверяем, что effect является словарем
		if not effect is Dictionary:
			print("ОШИБКА: Эффект '", effect_key, "' не является словарем! Удаляем...")
			effects_to_remove.append(effect_key)
			continue
		
		# Получаем базовый effect_id (без суффикса source_id)
		var effect_id = effect.get("effect_id", effect_key)
		if effect_id == "":
			effect_id = effect_key
		
		var duration = effect.get("duration", 0)
		if duration > 0:
			# Уменьшаем длительность
			effect["duration"] = duration - 1
			
			# Применяем эффект только когда длительность истекает
			if effect["duration"] <= 0:
				_apply_effect_damage(effect_id, effect_key)
				effects_to_remove.append(effect_key)
			else:
				# Для эффектов, которые действуют каждый ход (кровотечение, яд, гниль)
				if effect_id in ["bleeding", "poison", "rotten"]:
					_apply_effect_damage(effect_id, effect_key)
				# Для эффектов, которые действуют постоянно (игнорирование брони, нейротоксин)
				elif effect_id in ["armor_ignore", "neurotoxin"]:
					_apply_effect_damage(effect_id, effect_key)
				# Для эффекта "Ярость" - ничего не делаем, бонус остается активным
				elif effect_id == "rage":
					# Бонус остается активным до истечения эффекта
					pass
	
	# Удаляем истекшие эффекты
	for effect_key in effects_to_remove:
		# Специальная обработка для "rage" - удаляем бонус к физическому урону
		var effect = effects.get(effect_key, {})
		var effect_id = effect.get("effect_id", effect_key)
		if effect_id == "":
			effect_id = effect_key
		if effect_id == "rage":
			var damage_bonus = effect.get("damage_bonus", 0)
			if damage_bonus > 0 and has_method("remove_physical_damage_bonus"):
				remove_physical_damage_bonus(damage_bonus)
				print(display_name, " теряет бонус Ярости: -", damage_bonus, " к физическому урону")
		
		remove_effect(effect_key)
	
	processing_effects = false  # Сбрасываем флаг обработки эффектов

func is_processing_effects() -> bool:
	"""Возвращает true, если сейчас обрабатываются эффекты"""
	return processing_effects

func _apply_effect_damage(effect_id: String, effect_key: String = ""):
	# Если effect_key не указан, используем effect_id (обратная совместимость)
	if effect_key == "":
		effect_key = effect_id
	
	match effect_id:
		"bleeding":
			# Кровотечение наносит урон в зависимости от стаков (2% от максимума ОЗ за стак)
			if effect_key in effects:
				var effect = effects[effect_key]
				var stacks = effect.get("stacks", 1)
				var bleeding_damage = int(max_hp * 0.02 * stacks)  # 2% от максимума ОЗ за стак
				take_damage(bleeding_damage)
				# Показываем всплывающую цифру урона от кровотечения
				if DamageNumberManager.instance:
					DamageNumberManager.show_damage_on_character(self, bleeding_damage, false, false, false, "bleeding")
				# Логируем урон от эффекта
				_log_effect_damage(effect_id, bleeding_damage, stacks)
		"poison":
			# Яд наносит урон в зависимости от стаков и damage_per_turn
			if effect_key in effects:
				var effect = effects[effect_key]
				var stacks = effect.get("stacks", 1)
				var damage_per_turn = effect.get("damage_per_turn", 5)  # По умолчанию 5, но может быть 10
				var poison_damage = damage_per_turn * stacks
				take_damage(poison_damage, "poison")  # Указываем тип урона "poison"
				# Показываем всплывающую цифру урона от яда
				if DamageNumberManager.instance:
					DamageNumberManager.show_damage_on_character(self, poison_damage, false, false, false, "poison")
				# Логируем урон от эффекта
				_log_effect_damage(effect_id, poison_damage, stacks)
		"rotten":
			# Гниль наносит урон в зависимости от стаков и процента от максимального ОЗ
			if effect_id in effects:
				var effect = effects[effect_id]
				var stacks = effect.get("stacks", 1)
				var damage_percent = effect.get("damage_percent", 0.5)  # Процент урона за стак
				var rotten_damage = int(max_hp * (damage_percent / 100.0) * stacks)
				take_damage(rotten_damage)
				# Показываем всплывающую цифру урона от гниения
				if DamageNumberManager.instance:
					DamageNumberManager.show_damage_on_character(self, rotten_damage, false, false, false, "poison")
				# Логируем урон от эффекта
				_log_effect_damage(effect_id, rotten_damage, stacks)
		"wound":
			# Рана снижает эффективность лечения (обрабатывается в функции heal())
			# Здесь ничего не делаем, эффект применяется при лечении
			pass
		"stealth":
			# Невидимость - персонаж не может быть атакован
			if effect_id in effects:
				# Логируем невидимость как пассивную способность
				_log_passive_ability("Невидимость", true, display_name + " невидим!")
		"final_judgment":
			# Последний приговор - усиленная контратака
			if effect_id in effects:
				# Логируем последний приговор как пассивную способность
				_log_passive_ability("Последний приговор", true, display_name + " готов к последнему приговору!")
		"tharnok_guardian_delay":
			# Задержка стража Тарнока - активирует неуязвимость
			if effect_id in effects:
				print(display_name, " активирует защиту стража!")
				# Добавляем неуязвимость на 1 ход
				add_effect("invulnerability", 1.0, 1)
				# Логируем активацию стража
				_log_passive_ability("Страж Тарнока", true, display_name + " получает неуязвимость!")
		"guaranteed_dodge":
			# Гарантированный уворот - следующий уворот будет успешным
			if effect_id in effects:
				print(display_name, " имеет гарантированный уворот!")
				# Логируем гарантированный уворот как пассивную способность
				_log_passive_ability("Гарантированный уворот", true, display_name + " имеет гарантированный уворот!")
		"stun":
			# Оглушение блокирует ход
			if effect_id in effects:
				print(display_name, " оглушен и пропускает ход!")
				# Логируем оглушение как пассивную способность
				_log_passive_ability("Оглушение", true, display_name + " оглушен!")
		"judgment":
			# Суд палача - урон от максимального HP + оглушение
			if effect_id in effects:
				var effect = effects[effect_id]
				var hp_damage_percentage = effect.get("hp_damage_percentage", 0.2)
				var stun_duration = effect.get("stun_duration", 1.0)
				
				# Урон от максимального HP
				var judgment_damage = int(max_hp * hp_damage_percentage)
				take_damage(judgment_damage)
				# Показываем всплывающую цифру урона от суда
				if DamageNumberManager.instance:
					DamageNumberManager.show_damage_on_character(self, judgment_damage, false, false, false, "physical")
				print(display_name, " получает урон от суда! Урон: ", judgment_damage)
				
				# Накладываем оглушение
				add_effect("stun", stun_duration, 1)
				print(display_name, " оглушен судом на ", stun_duration, " ходов!")
				
				# Логируем урон от суда
				_log_effect_damage("Суд палача", judgment_damage, 1)
		"guaranteed_dodge":
			# Гарантированный уворот - не наносит урон, просто логирует
			if effect_id in effects:
				print(display_name, " имеет гарантированный уворот!")
				# Логируем эффект
				_log_passive_ability("Гарантированный уворот", true, display_name + " готов к увороту!")
		"final_judgment":
			# Последний приговор - усиленная контратака
			if effect_id in effects:
				# Логируем эффект
				_log_passive_ability("Последний приговор", true, display_name + " готов к смертельной контратаке!")
		"armor_ignore":
			# Игнорирование брони - эффект применяется в take_damage
			pass
		"neurotoxin":
			# Нейротоксин - уменьшает меткость, эффект применяется в get_accuracy
			pass

func _log_passive_ability(ability_name: String, success: bool, message: String):
	# Список статических способностей, которые не нужно логировать
	var static_abilities = [
		"Крепость", "Сильный", "Мудрый", "Живучесть",  # Игрок
		"Крысиная сила", "Крысиная ловкость",  # Крыса (статические)
		"Мышиная стая", "Мышиная ловкость", "Мышиная сила",  # Мышь
		"Слизистая броня", "Живучесть слизня", "Массивный",  # Слизень (статические)
		"Демон колдун", "Демоническая выносливость",  # Демоны
		"Сила демона", "Владыка демонов", "Броня Тарнока"  # Другие демоны
	]
	
	# Примечание: "Регенерация слизи", "Крысиная живучесть" и "Кровавый ритуал Алкары" НЕ входят в этот список, 
	# так как они имеют активные эффекты и должны логироваться
	
	# Не логируем статические способности
	if ability_name in static_abilities:
		return
	
	# Если способность не сработала, проверяем настройку
	if not success or message == "":
		var settings_manager = get_node_or_null("/root/SettingsManager")
		if settings_manager and not settings_manager.get_show_failed_ability_logs():
			return  # Не показываем несработавшие способности, если настройка выключена
	
	# Получаем battle_log из battle_manager
	var battle_manager = get_node_or_null("/root/BattleScene")
	if battle_manager and battle_manager.has_method("get_battle_log"):
		var battle_log = battle_manager.get_battle_log()
		if battle_log:
			battle_log.log_passive_ability(display_name, ability_name, success, message)
	else:
		# Fallback: ищем battle_log напрямую
		var battle_log = get_node_or_null("/root/BattleScene/BattleLog")
		if battle_log:
			battle_log.log_passive_ability(display_name, ability_name, success, message)
			# ДОПОЛНИТЕЛЬНЫЙ FALLBACK: ищем в родительских узлах
			var current_node = self
			while current_node != null:
				if current_node.has_method("get_battle_log"):
					var found_log = current_node.get_battle_log()
					if found_log:
						found_log.log_passive_ability(display_name, ability_name, success, message)
						break
				current_node = current_node.get_parent()
			
			# ЕЩЕ ОДИН FALLBACK: ищем в дереве сцены
			if current_node == null:
				var scene_tree = get_tree()
				if scene_tree:
					var root = scene_tree.root
					if root:
						# Ищем BattleLog в любом месте дерева
						var found_log = _find_battle_log_recursive(root)
						if found_log:
							found_log.log_passive_ability(display_name, ability_name, success, message)
	

func _find_battle_log_recursive(node: Node) -> Node:
	# Проверяем текущий узел
	if node.name == "BattleLog" or node.get_script() and node.get_script().get_path().ends_with("BattleLog.gd"):
		return node
	
	# Проверяем дочерние узлы
	for child in node.get_children():
		var result = _find_battle_log_recursive(child)
		if result:
			return result
	
	return null

func _log_effect_damage(effect_name: String, damage: int, stacks: int):
	# Получаем battle_log из battle_manager
	var battle_manager = get_node_or_null("/root/BattleScene")
	if battle_manager and battle_manager.has_method("get_battle_log"):
		var battle_log = battle_manager.get_battle_log()
		if battle_log:
			battle_log.log_effect_damage(display_name, effect_name, damage, stacks)
	else:
		# Fallback: ищем battle_log напрямую
		var battle_log = get_node_or_null("/root/BattleScene/BattleLog")
		if battle_log:
			battle_log.log_effect_damage(display_name, effect_name, damage, stacks)
		else:
			# Дополнительный fallback: рекурсивный поиск
			var scene_tree = get_tree()
			if scene_tree:
				var root = scene_tree.root
				if root:
					var found_log = _find_battle_log_recursive(root)
					if found_log:
						found_log.log_effect_damage(display_name, effect_name, damage, stacks)

func _log_counter_attack_damage(damage: int, target: Node):
	# Получаем battle_log из battle_manager
	var battle_manager = get_node_or_null("/root/BattleScene")
	if battle_manager and battle_manager.has_method("get_battle_log"):
		var battle_log = battle_manager.get_battle_log()
		if battle_log and target:
			battle_log.log_damage(display_name, target.display_name, damage, false, "physical", level, target.level, target.hp, target.max_hp, "Контратака")
	else:
		# Fallback: ищем battle_log напрямую
		var battle_log = get_node_or_null("/root/BattleScene/BattleLog")
		if battle_log and target:
			battle_log.log_damage(display_name, target.display_name, damage, false, "physical", level, target.level, target.hp, target.max_hp, "Контратака")
		else:
			# Дополнительный fallback: рекурсивный поиск
			var scene_tree = get_tree()
			if scene_tree:
				var root = scene_tree.root
				if root:
					var found_log = _find_battle_log_recursive(root)
					if found_log and target:
						found_log.log_damage(display_name, target.display_name, damage, false, "physical", level, target.level, target.hp, target.max_hp, "Контратака")

# Новые методы для механик летучей мыши

func add_extra_action_chance(chance: float):
	"""Добавляет шанс получить дополнительное действие"""
	extra_action_chance += chance
	print(display_name, " получил шанс дополнительного действия: +", chance, "% (всего: ", extra_action_chance, "%)")

func set_extra_action(has_action: bool):
	"""Устанавливает дополнительное действие на этот ход"""
	has_extra_action = has_action
	print(display_name, " получил дополнительное действие: ", has_action)

func add_action_point():
	"""Добавляет очко действий"""
	action_points += 1
	max_action_points = max(max_action_points, action_points)
	print(display_name, " получает очко действий! Всего: ", action_points)

func spend_action_point() -> bool:
	"""Тратит очко действий, возвращает true если успешно"""
	if action_points > 0:
		action_points -= 1
		print(display_name, " тратит очко действий. Осталось: ", action_points)
		return true
	return false

func reset_action_points():
	"""Сбрасывает очки действий в начале раунда"""
	action_points = 1
	max_action_points = 1
	# Сбрасываем флаг использования мести
	if has_method("set"):
		set("revenge_used_round", -1)
	# Сбрасываем флаг срабатывания скорости не здесь, а в отдельном методе, 
	# так как reset_action_points может вызываться в разных контекстах
	print(display_name, " очки действий сброшены: ", action_points)

func reset_round_counters(round_number: int):
	"""Сбрасывает счетчики раунда"""
	# Сбрасываем флаг скорости, если раунд изменился
	if speed_triggered_round != round_number:
		speed_triggered_round = -1

func has_action_points() -> bool:
	"""Проверяет, есть ли очки действий"""
	return action_points > 0

func add_action_points(amount: int):
	"""Добавляет очки действий"""
	action_points += amount
	max_action_points = max(max_action_points, action_points)

func add_damage_this_round(amount: int):
	"""Добавляет урон к счетчику урона за раунд"""
	damage_this_round += amount
	print(display_name, " получил ", amount, " урона за раунд (всего: ", damage_this_round, ")")

func get_damage_this_round() -> int:
	"""Возвращает урон, полученный в текущем раунде"""
	return damage_this_round

func reset_damage_this_round():
	"""Сбрасывает счетчик урона за раунд"""
	damage_this_round = 0
	print(display_name, " счетчик урона за раунд сброшен")

func remove_extra_action_chance(chance: float):
	"""Убирает шанс получить дополнительное действие"""
	extra_action_chance -= chance
	print(display_name, " потерял шанс дополнительного действия: -", chance, "% (всего: ", extra_action_chance, "%)")

func add_wound_chance(chance: float):
	"""Добавляет шанс нанести рану"""
	wound_chance += chance
	print(display_name, " получил шанс нанести рану: +", chance, "% (всего: ", wound_chance, "%)")

func remove_wound_chance(chance: float):
	"""Убирает шанс нанести рану"""
	wound_chance -= chance
	print(display_name, " потерял шанс нанести рану: -", chance, "% (всего: ", wound_chance, "%)")

func add_lifesteal(chance: float, percent: float):
	"""Добавляет вампиризм"""
	lifesteal_chance += chance
	lifesteal_percent += percent
	print(display_name, " получил вампиризм: +", chance, "% шанс, +", percent, "% урона (всего: ", lifesteal_chance, "%/", lifesteal_percent, "%)")

func remove_lifesteal():
	"""Убирает вампиризм"""
	lifesteal_chance = 0.0
	lifesteal_percent = 0.0
	print(display_name, " потерял вампиризм")

func add_true_sight():
	"""Добавляет истинное зрение"""
	true_sight = true
	print(display_name, " получил истинное зрение")

func remove_true_sight():
	"""Убирает истинное зрение"""
	true_sight = false
	print(display_name, " потерял истинное зрение")

func add_spell_failure_chance(chance: float):
	"""Добавляет шанс провала заклинаний"""
	spell_failure_chance += chance
	print(display_name, " получил шанс провала заклинаний: +", chance, "% (всего: ", spell_failure_chance, "%)")

func remove_spell_failure_chance():
	"""Убирает шанс провала заклинаний"""
	spell_failure_chance = 0.0
	print(display_name, " потерял шанс провала заклинаний")

func check_dodge() -> bool:
	"""Проверяет, уворачивается ли персонаж"""
	var dodge_roll = randf() * 100.0
	if dodge_roll <= current_dodge_chance:
		print(display_name, " уклонился от атаки! (", dodge_roll, " <= ", current_dodge_chance, ")")
		return true
	return false

func check_extra_action() -> bool:
	"""Проверяет, получает ли персонаж дополнительное действие"""
	# Сначала проверяем гарантированное дополнительное действие
	if has_extra_action:
		print(display_name, " использует дополнительное действие!")
		has_extra_action = false  # Используем действие
		return true
	
	# Затем проверяем шанс дополнительного действия
	if extra_action_chance > 0:
		var action_roll = randf() * 100.0
		if action_roll <= extra_action_chance:
			print(display_name, " получает дополнительное действие! (", action_roll, " <= ", extra_action_chance, ")")
			return true
	return false

func apply_wound_effect(target: Node):
	"""Применяет эффект раны к цели"""
	if target.has_method("reduce_dodge_chance"):
		target.reduce_dodge_chance(5.0)
		print(display_name, " нанес рану ", target.display_name, "! Уклонение уменьшено на 5%")

func reduce_dodge_chance(amount: float):
	"""Уменьшает шанс уворота"""
	current_dodge_chance = max(0.0, current_dodge_chance - amount)
	print(display_name, " получил рану! Уклонение уменьшено на ", amount, "% (текущее: ", current_dodge_chance, "%)")

func apply_lifesteal(damage: int) -> int:
	"""Применяет вампиризм и возвращает количество восстановленного здоровья"""
	var heal_amount = 0
	
	if lifesteal_chance > 0:
		var lifesteal_roll = randf() * 100.0
		if lifesteal_roll <= lifesteal_chance:
			heal_amount = int(damage * (lifesteal_percent / 100.0))
			hp = min(max_hp, hp + heal_amount)
			print(display_name, " восстанавливает ", heal_amount, " здоровья от вампиризма!")
	
	return heal_amount

func apply_elite_bonuses():
	"""Применяет бонусы элитного врага"""
	if rarity == "elite":
		# Удваиваем все характеристики
		max_hp *= 2
		hp = max_hp
		max_mp *= 2
		mp = max_mp
		max_stamina *= 2
		stamina = max_stamina
		attack_power *= 2
		defense *= 2
		
		# Увеличиваем уровень на 1-3
		level += randi_range(1, 3)
		
		# Пересчитываем бонусы от характеристик
		calculate_stat_bonuses()
		apply_stat_bonuses()

func add_stat_bonus(stat_name: String, bonus_value: float, duration: float):
	"""Добавляет временный бонус к характеристике"""
	if not stat_name in damage_bonuses:
		damage_bonuses[stat_name] = []
	
	# Добавляем бонус с указанной длительностью
	damage_bonuses[stat_name].append({
		"value": bonus_value,
		"duration": duration,
		"remaining": duration
	})
	
	print(display_name, " получает временный бонус: ", stat_name, " +", bonus_value, " на ", duration, " раундов")

func process_stat_bonuses():
	"""Обрабатывает временные бонусы к характеристикам"""
	for stat_name in damage_bonuses.keys():
		var bonuses = damage_bonuses[stat_name]
		for i in range(bonuses.size() - 1, -1, -1):
			bonuses[i]["remaining"] -= 1.0
			if bonuses[i]["remaining"] <= 0:
				bonuses.remove_at(i)
				print(display_name, " теряет временный бонус: ", stat_name)
		
		# Удаляем пустые массивы
		if bonuses.is_empty():
			damage_bonuses.erase(stat_name)

func get_stat_bonus(stat_name: String) -> float:
	"""Возвращает суммарный бонус к характеристике"""
	var total_bonus = 0.0
	if stat_name in damage_bonuses:
		for bonus in damage_bonuses[stat_name]:
			total_bonus += bonus["value"]
	return total_bonus

func add_flat_damage_reduction(reduction: float):
	"""Добавляет плоское снижение урона"""
	flat_damage_reduction += reduction
	print(display_name, " получает плоское снижение урона: +", reduction, " (итого: ", flat_damage_reduction, ")")

func reduce_armor(reduction: float):
	"""Снижает броню (может быть отрицательной для увеличения урона)"""
	armor_reduction += reduction
	print(display_name, " теряет броню: -", reduction, " (итого: ", armor_reduction, ")")
	
	# Обновляем или создаем эффект коррозии брони
	# Используем add_effect для правильного обновления UI
	add_effect("corrosive_armor", 999.0, 1, {"armor_reduction": armor_reduction})

# === СИСТЕМА ФИЗИЧЕСКОГО УРОНА ===

var physical_damage_bonus: int = 0  # Общий бонус к физическому урону (P)
var massive_damage_bonus: int = 0  # Бонус урона от способности "Массивный"

func get_max_hp() -> int:
	"""Возвращает максимальное здоровье (для способности 'Массивный')"""
	return max_hp

func get_total_physical_damage_bonus() -> int:
	"""Возвращает общий бонус физического урона (включая 'Массивный')"""
	return physical_damage_bonus

func get_passive_abilities() -> Array:
	"""Возвращает массив пассивных способностей"""
	return passive_abilities

func get_ability_level(ability_id: String) -> int:
	"""Возвращает уровень пассивной способности"""
	return ability_levels.get(ability_id, 1)

func add_physical_damage_bonus(bonus: int):
	"""Добавляет бонус к физическому урону (используется способностью 'Массивный')"""
	physical_damage_bonus += bonus

func remove_physical_damage_bonus(bonus: int):
	"""Удаляет бонус к физическому урону (используется способностью 'Массивный')"""
	physical_damage_bonus -= bonus

func get_base_physical_damage() -> int:
	"""Возвращает базовый физический урон БЕЗ бонусов от пассивных способностей, но С переменной P"""
	# Используем ту же формулу, что и "Двойной удар" - характеристики + переменная P
	return int((strength + agility) / 1.5) + physical_damage_bonus

func get_physical_damage() -> int:
	"""Возвращает урон для физических атак (базовый урон + бонус от Силы + бонусы от пассивных способностей)"""
	var strength_bonus = strength  # 1 урон за очко Силы
	var base_damage = attack_power + strength_bonus + physical_damage_bonus
	
	# Применяем бонус "Боец" к итоговому урону
	var fighter_bonus = 0
	for ability in passive_abilities:
		if ability.id == "fighter":
			var ability_level = ability_levels.get(ability.id, 1)
			var fighter_percentage = ability.get_value_for_level(ability_level)
			fighter_bonus = int(base_damage * (fighter_percentage / 100.0))
			break
	
	var total_damage = base_damage + fighter_bonus
	
	# Применяем бонус Боевого безумия (berserker_fury) - увеличение физического урона за стак
	if has_effect("berserker_fury"):
		var effect = effects["berserker_fury"]
		var stacks = effect.get("stacks", 1)
		var damage_bonus_per_stack = effect.get("damage_bonus_per_stack", 0.0)
		var fury_bonus = int(total_damage * (damage_bonus_per_stack * stacks / 100.0))
		total_damage += fury_bonus
	
	# Применяем множитель Берсерка (berserk) - огромный урон при критическом состоянии
	if has_meta("berserk_active"):
		var berserk_multiplier = get_meta("berserk_multiplier", 1.0)
		total_damage = int(total_damage * berserk_multiplier)
	
	return total_damage

func get_poison_damage() -> int:
	"""Возвращает урон для ядовитых атак (базовый урон + бонусы от пассивных способностей к ядовитому урону)"""
	var base_damage = attack_power
	
	# Применяем бонусы к ядовитому урону (пока нет таких пассивных способностей)
	var poison_bonus = 0
	for ability in passive_abilities:
		if ability.id == "poison_master" or ability.id == "toxic_venom":  # Примеры будущих способностей
			var ability_level = ability_levels.get(ability.id, 1)
			var poison_percentage = ability.get_value_for_level(ability_level)
			poison_bonus = int(base_damage * (poison_percentage / 100.0))
			break
	
	return base_damage + poison_bonus

# Функции для работы с магическим барьером
func add_magic_barrier(amount: int):
	"""Добавляет магический барьер"""
	# Если max_magic_barrier > 0, ограничиваем барьер максимумом
	# Если max_magic_barrier = 0, значит это временный барьер (например, от способностей) и не ограничиваем его
	if max_magic_barrier > 0:
		magic_barrier = min(magic_barrier + amount, max_magic_barrier)
	else:
		magic_barrier += amount
	_log_magic_barrier_change(amount, "добавлен")

func remove_magic_barrier(amount: int):
	"""Удаляет магический барьер"""
	var removed = min(amount, magic_barrier)
	magic_barrier = max(0, magic_barrier - amount)
	if removed > 0:
		_log_magic_barrier_change(-removed, "удален")

func set_magic_barrier(amount: int):
	"""Устанавливает магический барьер"""
	var old_barrier = magic_barrier
	magic_barrier = clamp(amount, 0, max_magic_barrier)
	var change = magic_barrier - old_barrier
	if change != 0:
		_log_magic_barrier_change(change, "изменен")

func get_magic_barrier() -> int:
	"""Возвращает текущее количество магического барьера"""
	return magic_barrier

func has_magic_barrier() -> bool:
	"""Проверяет, есть ли активный магический барьер"""
	return magic_barrier > 0

func _log_magic_barrier_change(amount: int, action: String):
	"""Логирует изменение магического барьера"""
	var battle_manager = get_node_or_null("/root/BattleScene")
	if battle_manager and battle_manager.has_method("get_battle_log"):
		var battle_log = battle_manager.get_battle_log()
		if battle_log:
			var sign_symbol = "+" if amount > 0 else ""
			battle_log.log_event("magic_barrier", display_name, "", amount, "Магический барьер " + action + ": " + sign_symbol + str(amount) + " (итого: " + str(magic_barrier) + ")")
	else:
		# Fallback: ищем battle_log напрямую
		var battle_log = get_node_or_null("/root/BattleScene/BattleLog")
		if battle_log:
			var sign_symbol = "+" if amount > 0 else ""
			battle_log.log_event("magic_barrier", display_name, "", amount, "Магический барьер " + action + ": " + sign_symbol + str(amount) + " (итого: " + str(magic_barrier) + ")")
		else:
			# Дополнительный fallback: рекурсивный поиск
			var scene_tree = get_tree()
			if scene_tree:
				var root = scene_tree.root
				if root:
					var found_log = _find_battle_log_recursive(root)
					if found_log:
						var sign_symbol = "+" if amount > 0 else ""
						found_log.log_event("magic_barrier", display_name, "", amount, "Магический барьер " + action + ": " + sign_symbol + str(amount) + " (итого: " + str(magic_barrier) + ")")

func _log_magic_barrier_block(effect_id: String):
	"""Логирует блокировку эффекта магическим барьером"""
	var battle_manager = get_node_or_null("/root/BattleScene")
	if battle_manager and battle_manager.has_method("get_battle_log"):
		var battle_log = battle_manager.get_battle_log()
		if battle_log:
			var effect_names = {
				"bleeding": "кровотечение",
				"poison": "яд", 
				"neurotoxin": "нейротоксин"
			}
			var effect_name = effect_names.get(effect_id, effect_id)
			battle_log.log_event("magic_barrier_block", display_name, "", 0, "Магический барьер блокирует " + effect_name + "!")
	else:
		# Fallback: ищем battle_log напрямую
		var battle_log = get_node_or_null("/root/BattleScene/BattleLog")
		if battle_log:
			var effect_names = {
				"bleeding": "кровотечение",
				"poison": "яд", 
				"neurotoxin": "нейротоксин"
			}
			var effect_name = effect_names.get(effect_id, effect_id)
			battle_log.log_event("magic_barrier_block", display_name, "", 0, "Магический барьер блокирует " + effect_name + "!")
		else:
			# Дополнительный fallback: рекурсивный поиск
			var scene_tree = get_tree()
			if scene_tree:
				var root = scene_tree.root
				if root:
					var found_log = _find_battle_log_recursive(root)
					if found_log:
						var effect_names = {
							"bleeding": "кровотечение",
							"poison": "яд", 
							"neurotoxin": "нейротоксин"
						}
						var effect_name = effect_names.get(effect_id, effect_id)
						found_log.log_event("magic_barrier_block", display_name, "", 0, "Магический барьер блокирует " + effect_name + "!")

func _log_heal(amount: int):
	"""Логирует восстановление здоровья с учетом текущего здоровья"""
	var battle_manager = get_node_or_null("/root/BattleScene")
	if battle_manager and battle_manager.has_method("get_battle_log"):
		var battle_log = battle_manager.get_battle_log()
		if battle_log:
			# Логируем восстановление здоровья с расчетом
			battle_log.log_heal(display_name, display_name, amount, hp, max_hp)
	else:
		# Fallback: ищем battle_log напрямую
		var battle_log = get_node_or_null("/root/BattleScene/BattleLog")
		if battle_log:
			# Логируем восстановление здоровья с расчетом
			battle_log.log_heal(display_name, display_name, amount, hp, max_hp)
		else:
			# Дополнительный fallback: рекурсивный поиск
			var scene_tree = get_tree()
			if scene_tree:
				var root = scene_tree.root
				if root:
					var found_log = _find_battle_log_recursive(root)
					if found_log:
						# Логируем восстановление здоровья с расчетом
						found_log.log_heal(display_name, display_name, amount, hp, max_hp)

# Дополнительные методы для сохранения информации об атаке (для логирования)
var current_ability_name: String = ""

func get_current_ability_name() -> String:
	"""Возвращает название текущей способности"""
	return current_ability_name

func get_last_attack_damage_type() -> String:
	"""Возвращает тип последнего урона"""
	return last_attack_damage_type

func get_last_attack_was_crit() -> bool:
	"""Возвращает был ли последний урон критическим"""
	return last_attack_was_crit

func set_last_attack_info(damage: int, damage_type: String, was_crit: bool, ability_name: String = ""):
	"""Сохраняет информацию о последней атаке"""
	last_attack_damage = damage
	last_attack_damage_type = damage_type
	last_attack_was_crit = was_crit
	current_ability_name = ability_name

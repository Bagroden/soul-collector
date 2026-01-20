# res://Scripts/Abilities/EnemyAbility.gd
extends Resource
class_name EnemyAbility

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var damage_type: String = "physical"  # physical, magic или poison
@export var base_damage: int = 0
@export var mp_cost: int = 0
@export var stamina_cost: int = 0
@export var cooldown: int = 0  # Ходы до следующего использования
@export var crit_chance_bonus: float = 0.0  # Бонус к шансу крита
@export var damage_multiplier: float = 1.0  # Множитель урона
@export var is_multi_hit: bool = false  # Множественные удары
@export var hit_count: int = 1  # Количество ударов

func can_use(owner: Node) -> bool:
	"""Проверяет, может ли владелец использовать способность"""
	if mp_cost > 0 and owner.mp < mp_cost:
		return false
	if stamina_cost > 0 and owner.stamina < stamina_cost:
		return false
	return true

func get_damage(_owner: Node) -> int:
	"""Рассчитывает урон способности"""
	# Урон способности = базовый урон способности (без бонусов от характеристик)
	# Бонусы редкости будут применены в battle_manager.gd
	var damage = base_damage
	
	# Применяем множитель способности (не редкости!)
	damage = int(damage * damage_multiplier)
	return damage

func get_crit_chance(owner: Node) -> float:
	"""Рассчитывает шанс критического удара"""
	var base_crit = owner.crit_chance
	if damage_type == "magic":
		# Магический крит зависит от мудрости
		base_crit += owner.magic_crit_chance
	else:
		# Физический крит зависит от ловкости
		base_crit += owner.crit_chance
	
	return base_crit + crit_chance_bonus

func use_ability(owner: Node, _target: Node) -> Dictionary:
	"""Использует способность"""
	if not can_use(owner):
		return {"success": false, "message": "Недостаточно ресурсов для использования способности"}
	
	# Тратим ресурсы
	if mp_cost > 0:
		owner.mp = max(0, owner.mp - mp_cost)
	if stamina_cost > 0:
		owner.stamina = max(0, owner.stamina - stamina_cost)
	
	# Специальная обработка для "Двойного удара"
	if id == "double_strike":
		# Воспроизводим звук для двойного удара
		if SoundManager:
			SoundManager.play_sound("sword_hit", -5.0)
		
		# Получаем характеристики владельца
		var strength_val = owner.strength if "strength" in owner else 0
		var agility_val = owner.agility if "agility" in owner else 0
		
		# Получаем бонус физического урона (P)
		var physical_bonus = 0
		if owner.has_method("get_physical_damage_bonus"):
			physical_bonus = owner.get_physical_damage_bonus()
		elif "physical_damage_bonus" in owner:
			physical_bonus = owner.physical_damage_bonus
		
		# Рассчитываем урон за один удар: (сила + ловкость + P) / 1.5
		var damage_per_hit = int((strength_val + agility_val + physical_bonus) / 1.5)
		
		# Проверяем критический удар для каждого удара отдельно
		var first_hit_crit = randf() < (get_crit_chance(owner) / 100.0)
		var second_hit_crit = randf() < (get_crit_chance(owner) / 100.0)
		
		var first_hit_damage = damage_per_hit
		var second_hit_damage = damage_per_hit
		
		if first_hit_crit:
			first_hit_damage = int(first_hit_damage * 1.5)
		
		if second_hit_crit:
			second_hit_damage = int(second_hit_damage * 1.5)
		
		return {
			"success": true,
			"damage": 0,  # Общий урон рассчитывается в battle_manager
			"is_crit": first_hit_crit or second_hit_crit,  # Хотя бы один крит
			"damage_type": damage_type,
			"message": owner.display_name + " использует " + name + "!",
			"double_strike": true,  # Флаг для battle_manager
			"first_hit_damage": first_hit_damage,
			"second_hit_damage": second_hit_damage,
			"first_hit_crit": first_hit_crit,
			"second_hit_crit": second_hit_crit
		}
	
	# Специальная обработка для "Крысиного укуса"
	if id == "rat_bite":
		# Воспроизводим звук крысиной атаки
		if SoundManager:
			SoundManager.play_sound("rat_attack1", -10.0)
		
		# Получаем характеристики владельца
		var strength_val = owner.strength if "strength" in owner else 0
		var agility_val = owner.agility if "agility" in owner else 0
		
		# Получаем бонус физического урона (P)
		var physical_bonus = 0
		if owner.has_method("get_physical_damage_bonus"):
			physical_bonus = owner.get_physical_damage_bonus()
		elif "physical_damage_bonus" in owner:
			physical_bonus = owner.physical_damage_bonus
		
		# Рассчитываем урон: (сила + ловкость + P) * 1.5
		var bite_damage = int((strength_val + agility_val + physical_bonus) * 1.5)
		
		# Проверяем критический удар
		var bite_crit = randf() < (get_crit_chance(owner) / 100.0)
		
		if bite_crit:
			bite_damage = int(bite_damage * 1.5)  # Критический урон
		
		# Проверяем шанс кровотечения (50%)
		var bleeding = randf() < 0.50
		
		return {
			"success": true,
			"damage": bite_damage,
			"is_crit": bite_crit,
			"damage_type": damage_type,
			"message": owner.display_name + " использует " + name + "!",
			"rat_bite": true,  # Флаг для battle_manager
			"apply_bleeding": bleeding  # Флаг для наложения кровотечения
		}
	
	# Специальная обработка для "Пикирования"
	if id == "bat_swoop":
		# Воспроизводим звук
		if SoundManager:
			SoundManager.play_sound("bat_attack", -5.0)
		
		# Получаем характеристики владельца
		var strength_val = owner.strength if "strength" in owner else 0
		var agility_val = owner.agility if "agility" in owner else 0
		
		# Получаем бонус физического урона (P)
		var physical_bonus = 0
		if owner.has_method("get_physical_damage_bonus"):
			physical_bonus = owner.get_physical_damage_bonus()
		elif "physical_damage_bonus" in owner:
			physical_bonus = owner.physical_damage_bonus
		
		# Рассчитываем урон: (сила + ловкость + P) * 1.5
		var swoop_damage = int((strength_val + agility_val + physical_bonus) * 1.5)
		
		# Проверяем критический удар (базовый шанс + 25% бонус)
		var swoop_crit = randf() < (get_crit_chance(owner) / 100.0)
		
		if swoop_crit:
			swoop_damage = int(swoop_damage * 1.5)  # Критический урон
		
		# Проверяем шанс оглушения (30%)
		var stun_roll = randf()
		var apply_stun = stun_roll < 0.30
		
		print("🦇 ", owner.display_name, " использует Пикирование! Урон: ", swoop_damage, " | Крит: ", swoop_crit, " | Шанс оглушения: 30%, выпало: ", snappedf(stun_roll * 100, 0.1), "% → ", "ОГЛУШЕНИЕ!" if apply_stun else "Нет оглушения")
		
		return {
			"success": true,
			"damage": swoop_damage,
			"is_crit": swoop_crit,
			"damage_type": damage_type,
			"message": owner.display_name + " использует " + name + "!",
			"bat_swoop": true,  # Флаг для battle_manager
			"apply_stun": apply_stun  # Флаг для наложения оглушения
		}
	
	# Специальная обработка для "Гнилостного взрыва"
	if id == "rotten_slime_blast":
		# Воспроизводим звук
		if SoundManager:
			SoundManager.play_sound("sword_hit", -5.0)
		
		# Получаем характеристики владельца
		var strength_val = owner.strength if "strength" in owner else 0
		var vitality_val = owner.vitality if "vitality" in owner else 0
		
		# Получаем бонус физического урона (P)
		var physical_bonus = 0
		if owner.has_method("get_physical_damage_bonus"):
			physical_bonus = owner.get_physical_damage_bonus()
		elif "physical_damage_bonus" in owner:
			physical_bonus = owner.physical_damage_bonus
		
		# Рассчитываем урон: (сила + живучесть) * 0.5 + P (ослаблено на 50%)
		var rotten_damage = int((strength_val + vitality_val) * 0.5) + physical_bonus
		
		# Проверяем критический удар
		var rotten_crit = randf() < (get_crit_chance(owner) / 100.0)
		
		if rotten_crit:
			rotten_damage = int(rotten_damage * 1.5)  # Критический урон
		
		return {
			"success": true,
			"damage": rotten_damage,
			"is_crit": rotten_crit,
			"damage_type": damage_type,
			"message": owner.display_name + " использует " + name + "!",
			"rotten_blast": true,  # Флаг для battle_manager
			"trigger_rotten_aura": true  # Флаг для внеочередного срабатывания гнилостной ауры
		}
	
	# Специальная обработка для "Удара палача" - два удара (рубящий и колющий)
	if id == "executioner_strike":
		# Воспроизводим звук
		if SoundManager:
			SoundManager.play_sound("sword_hit", -5.0)
		
		# Получаем характеристики владельца
		var strength_val = owner.strength if "strength" in owner else 0
		var agility_val = owner.agility if "agility" in owner else 0
		
		# Получаем бонус физического урона (P)
		var physical_bonus = 0
		if owner.has_method("get_physical_damage_bonus"):
			physical_bonus = owner.get_physical_damage_bonus()
		elif "physical_damage_bonus" in owner:
			physical_bonus = owner.physical_damage_bonus
		
		# Рассчитываем урон для каждого удара: (сила + ловкость + P) * 1.5
		var damage_per_hit = int((strength_val + agility_val + physical_bonus) * 1.5)
		
		# Проверяем критический удар для каждого удара с бонусом +20%
		var executioner_crit_chance = (get_crit_chance(owner) + crit_chance_bonus) / 100.0
		var first_hit_crit = randf() < executioner_crit_chance
		var second_hit_crit = randf() < executioner_crit_chance
		
		# Рассчитываем урон каждого удара с учетом критов
		var first_hit_damage = damage_per_hit
		var second_hit_damage = damage_per_hit
		
		if first_hit_crit:
			first_hit_damage = int(first_hit_damage * 1.5)
		
		if second_hit_crit:
			second_hit_damage = int(second_hit_damage * 1.5)
		
		return {
			"success": true,
			"damage": 0,  # Общий урон рассчитывается в battle_manager
			"is_crit": first_hit_crit or second_hit_crit,
			"damage_type": damage_type,
			"message": owner.display_name + " использует " + name + "!",
			"executioner_strike": true,  # Флаг для battle_manager
			"first_hit_damage": first_hit_damage,
			"second_hit_damage": second_hit_damage,
			"first_hit_crit": first_hit_crit,
			"second_hit_crit": second_hit_crit
		}
	
	# Специальная обработка для "Темного взрыва"
	if id == "alkara_dark_blast":
		# Воспроизводим звук
		if SoundManager:
			SoundManager.play_sound("magic_arrow", -5.0)
		
		# Получаем характеристики владельца
		var intelligence_val = owner.intelligence if "intelligence" in owner else 0
		
		# Рассчитываем базовый урон: интеллект * 2.5
		var base_dark_damage = int(intelligence_val * 2.5)
		
		# Применяем бонус магического урона от интеллекта
		var magic_damage_bonus = 0.0
		if "magic_damage_bonus" in owner:
			magic_damage_bonus = owner.magic_damage_bonus
		
		var dark_damage = int(base_dark_damage * (1.0 + magic_damage_bonus))
		
		# Проверяем критический удар с бонусом +5%
		var dark_crit_chance = (get_crit_chance(owner) + crit_chance_bonus) / 100.0
		var dark_crit = randf() < dark_crit_chance
		
		if dark_crit:
			dark_damage = int(dark_damage * 1.5)  # Критический урон
		
		return {
			"success": true,
			"damage": dark_damage,
			"is_crit": dark_crit,
			"damage_type": damage_type,
			"message": owner.display_name + " использует " + name + "!",
			"dark_blast": true,  # Флаг для battle_manager
			"lifesteal": true  # Флаг для вампиризма
		}
	
	# Специальная обработка для "Проклятого взрыва"
	if id == "curse_blast":
		# Воспроизводим звук
		if SoundManager:
			SoundManager.play_sound("magic_arrow", -5.0)
		
		# Получаем характеристики владельца
		var intelligence_val = owner.intelligence if "intelligence" in owner else 0
		var wisdom_val = owner.wisdom if "wisdom" in owner else 0
		
		# Рассчитываем базовый урон: интеллект + мудрость * 1.3
		var base_curse_damage = int(intelligence_val + wisdom_val * 1.3)
		
		# Применяем бонус магического урона от интеллекта
		var magic_damage_bonus = 0.0
		if "magic_damage_bonus" in owner:
			magic_damage_bonus = owner.magic_damage_bonus
		
		var curse_damage = int(base_curse_damage * (1.0 + magic_damage_bonus))
		
		# Проверяем критический удар
		var curse_crit = randf() < (get_crit_chance(owner) / 100.0)
		
		if curse_crit:
			curse_damage = int(curse_damage * 1.5)  # Критический урон
		
		# Проверяем шанс проклятия (30%)
		var apply_curse = randf() < 0.30
		
		return {
			"success": true,
			"damage": curse_damage,
			"is_crit": curse_crit,
			"damage_type": damage_type,
			"message": owner.display_name + " использует " + name + "!",
			"curse_blast": true,  # Флаг для battle_manager
			"apply_curse": apply_curse  # Флаг для наложения проклятия
		}
	
	# Специальная обработка для "Сокрушающего удара" - два удара (обычный и усиленный)
	if id == "tharnok_crushing_strike":
		# Воспроизводим звук
		if SoundManager:
			SoundManager.play_sound("sword_hit", -5.0)
		
		# Получаем характеристики владельца
		var strength_val = owner.strength if "strength" in owner else 0
		var vitality_val = owner.vitality if "vitality" in owner else 0
		
		# Получаем бонус физического урона (P)
		var physical_bonus = 0
		if owner.has_method("get_physical_damage_bonus"):
			physical_bonus = owner.get_physical_damage_bonus()
		elif "physical_damage_bonus" in owner:
			physical_bonus = owner.physical_damage_bonus
		
		# Первый удар: сила + живучесть + P
		var first_hit_damage = strength_val + vitality_val + physical_bonus
		
		# Второй удар (усиленный): (сила + живучесть + P) * 1.7
		var second_hit_damage = int((strength_val + vitality_val + physical_bonus) * 1.7)
		
		# Проверяем критический удар для каждого удара
		var first_hit_crit = randf() < (get_crit_chance(owner) / 100.0)
		var second_hit_crit = randf() < (get_crit_chance(owner) / 100.0)
		
		# Применяем критический урон если есть
		if first_hit_crit:
			first_hit_damage = int(first_hit_damage * 1.5)
		
		if second_hit_crit:
			second_hit_damage = int(second_hit_damage * 1.5)
		
		# Проверяем шанс оглушить (30%) - только на втором ударе
		var apply_stun = randf() < 0.30
		
		return {
			"success": true,
			"damage": 0,  # Общий урон рассчитывается в battle_manager
			"is_crit": first_hit_crit or second_hit_crit,
			"damage_type": damage_type,
			"message": owner.display_name + " использует " + name + "!",
			"crushing_strike": true,  # Флаг для battle_manager
			"first_hit_damage": first_hit_damage,
			"second_hit_damage": second_hit_damage,
			"first_hit_crit": first_hit_crit,
			"second_hit_crit": second_hit_crit,
			"apply_stun": apply_stun  # Флаг для оглушения (на втором ударе)
		}
	
	# Специальная обработка для "Кислотного взрыва"
	if id == "slime_acid_blast":
		# Воспроизводим звук
		if SoundManager:
			SoundManager.play_sound("sword_hit", -5.0)
		
		# Получаем характеристики владельца
		var strength_val = owner.strength if "strength" in owner else 0
		var vitality_val = owner.vitality if "vitality" in owner else 0
		
		# Получаем бонус физического урона (P)
		var physical_bonus = 0
		if owner.has_method("get_physical_damage_bonus"):
			physical_bonus = owner.get_physical_damage_bonus()
		elif "physical_damage_bonus" in owner:
			physical_bonus = owner.physical_damage_bonus
		
		# Рассчитываем урон: сила + живучесть + P
		var acid_damage = strength_val + vitality_val + physical_bonus
		
		# Проверяем критический удар
		var acid_crit = randf() < (get_crit_chance(owner) / 100.0)
		
		if acid_crit:
			acid_damage = int(acid_damage * 1.5)  # Критический урон
		
		return {
			"success": true,
			"damage": acid_damage,
			"is_crit": acid_crit,
			"damage_type": damage_type,
			"message": owner.display_name + " использует " + name + "!",
			"slime_acid_blast": true,  # Флаг для battle_manager
			"reduce_armor": 5  # Снижение брони на 5 единиц
		}
	
	# Специальная обработка для "Ядовитого удара"
	if id == "poison_strike":
		# Воспроизводим звук для ядовитого удара
		if SoundManager:
			SoundManager.play_sound("poison_strike1", -5.0)
		
		# Получаем ловкость владельца
		var agility_val = owner.agility if "agility" in owner else 0
		
		# Рассчитываем урон: ловкость * 2.5
		var poison_damage = int(agility_val * 2.5)
		
		# Проверяем критический удар
		var poison_crit = randf() < (get_crit_chance(owner) / 100.0)
		
		if poison_crit:
			poison_damage = int(poison_damage * 1.5)  # Критический урон
		
		return {
			"success": true,
			"damage": poison_damage,
			"is_crit": poison_crit,
			"damage_type": damage_type,
			"message": owner.display_name + " использует " + name + "!",
			"poison_strike": true,  # Флаг для battle_manager
			"poison_stacks": 2  # Накладываем 2 стака яда
		}
	
	# Специальная обработка для "Магических стрел"
	if id == "magic_arrows":
		# Получаем интеллект владельца
		var intelligence = owner.intelligence if "intelligence" in owner else 0
		
		# Рассчитываем количество стрел: 1 + 1 за каждые 15 интеллекта
		var arrows_count = 1 + int(intelligence / 15)
		
		# Рассчитываем базовый урон от одной стрелы = интеллект
		var base_arrow_damage = intelligence
		
		# Применяем бонус магического урона от интеллекта
		var magic_damage_bonus = 0.0
		if "magic_damage_bonus" in owner:
			magic_damage_bonus = owner.magic_damage_bonus
		
		var arrow_damage = int(base_arrow_damage * (1.0 + magic_damage_bonus))
		
		# Проверяем критический удар для каждой стрелы
		var total_damage = 0
		var critical_hits = 0
		
		var scene_tree: SceneTree = null
		if owner and owner is Node:
			scene_tree = owner.get_tree()
		
		for i in range(arrows_count):
			# Планируем воспроизведение звука с задержкой, не блокируя анимацию
			if SoundManager:
				if scene_tree:
					var delay = 0.60 * (i + 1)
					var timer = scene_tree.create_timer(delay)
					timer.timeout.connect( func(): SoundManager.play_sound("magic_arrow", -5.0) )
				else:
					SoundManager.play_sound("magic_arrow", -5.0)
			
			var arrow_is_crit = randf() < (get_crit_chance(owner) / 100.0)
			var arrow_damage_calc = arrow_damage
			
			if arrow_is_crit:
				arrow_damage_calc = int(arrow_damage_calc * 1.5)  # Критический урон
				critical_hits += 1
			
			total_damage += arrow_damage_calc
		
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
	
	# Специальная обработка для "Арбалетного выстрела"
	if id == "crossbow_shot":
		# Воспроизводим звук
		if SoundManager:
			SoundManager.play_sound("sword_hit", -5.0)
		
		# Получаем характеристики владельца
		var strength_val = owner.strength if "strength" in owner else 0
		var agility_val = owner.agility if "agility" in owner else 0
		
		# Получаем бонус физического урона (P)
		var physical_bonus = 0
		if owner.has_method("get_physical_damage_bonus"):
			physical_bonus = owner.get_physical_damage_bonus()
		elif "physical_damage_bonus" in owner:
			physical_bonus = owner.physical_damage_bonus
		
		# Рассчитываем урон: (сила + ловкость + P) * 1.5
		var crossbow_damage = int((strength_val + agility_val + physical_bonus) * 1.5)
		
		# Проверяем критический удар с бонусом +15%
		var crossbow_crit_chance = (get_crit_chance(owner) + 15.0) / 100.0
		var crossbow_crit = randf() < crossbow_crit_chance
		
		if crossbow_crit:
			crossbow_damage = int(crossbow_damage * 1.5)  # Критический урон
		
		return {
			"success": true,
			"damage": crossbow_damage,
			"is_crit": crossbow_crit,
			"damage_type": damage_type,
			"message": owner.display_name + " использует " + name + "!",
			"crossbow_shot": true  # Флаг для battle_manager
		}
	
	# Специальная обработка для "Рубящего удара"
	if id == "slashing_strike":
		# Воспроизводим звук
		if SoundManager:
			SoundManager.play_sound("sword_hit", -5.0)
		
		# Получаем характеристики владельца
		var strength_val = owner.strength if "strength" in owner else 0
		var agility_val = owner.agility if "agility" in owner else 0
		
		# Получаем бонус физического урона (P)
		var physical_bonus = 0
		if owner.has_method("get_physical_damage_bonus"):
			physical_bonus = owner.get_physical_damage_bonus()
		elif "physical_damage_bonus" in owner:
			physical_bonus = owner.physical_damage_bonus
		
		# Рассчитываем урон: (сила + ловкость + P) * 1.2
		var slash_damage = int((strength_val + agility_val + physical_bonus) * 1.2)
		
		# Проверяем критический удар
		var slash_crit = randf() < (get_crit_chance(owner) / 100.0)
		
		if slash_crit:
			slash_damage = int(slash_damage * 1.5)  # Критический урон
		
		return {
			"success": true,
			"damage": slash_damage,
			"is_crit": slash_crit,
			"damage_type": damage_type,
			"message": owner.display_name + " использует " + name + "!",
			"slashing_strike": true,  # Флаг для battle_manager
			"add_momentum_stack": true  # Добавить стак "Импульса" (для пассивки "Танец смерти")
		}
	
	# Специальная обработка для "Надгробия" - массовая магическая атака
	if id == "tombstone":
		# Воспроизводим звук
		if SoundManager:
			SoundManager.play_sound("magic_arrow", -5.0)
		
		# Получаем характеристики владельца
		var intelligence_val = owner.intelligence if "intelligence" in owner else 0
		var wisdom_val = owner.wisdom if "wisdom" in owner else 0
		
		# Применяем бонус магического урона от интеллекта
		var magic_damage_bonus = 0.0
		if "magic_damage_bonus" in owner:
			magic_damage_bonus = owner.magic_damage_bonus
		
		# Рассчитываем средний урон: (интеллект + мудрость) * 1.2
		var base_tombstone_damage = int((intelligence_val + wisdom_val) * 1.2)
		var tombstone_damage = int(base_tombstone_damage * (1.0 + magic_damage_bonus))
		
		# Проверяем критический удар
		var tombstone_crit = randf() < (get_crit_chance(owner) / 100.0)
		
		if tombstone_crit:
			tombstone_damage = int(tombstone_damage * 1.5)  # Критический урон
		
		# Массовая атака - урон будет нанесен всем противникам в battle_manager
		# Паралич будет наложен с шансом 30% на каждого противника отдельно
		
		return {
			"success": true,
			"damage": tombstone_damage,
			"is_crit": tombstone_crit,
			"damage_type": damage_type,
			"message": owner.display_name + " использует " + name + "!",
			"tombstone": true,  # Флаг для battle_manager
			"is_area_attack": true,  # Флаг массовой атаки
			"paralysis_chance": 0.30  # 30% шанс паралича
		}
	
	# Специальная обработка для "Сокрушительного молота" - два удара
	if id == "crushing_hammer":
		# Воспроизводим звук
		if SoundManager:
			SoundManager.play_sound("sword_hit", -5.0)
		
		# Получаем характеристики владельца
		var strength_val = owner.strength if "strength" in owner else 0
		var vitality_val = owner.vitality if "vitality" in owner else 0
		
		# Получаем бонус физического урона (P)
		var physical_bonus = 0
		if owner.has_method("get_physical_damage_bonus"):
			physical_bonus = owner.get_physical_damage_bonus()
		elif "physical_damage_bonus" in owner:
			physical_bonus = owner.physical_damage_bonus
		
		# Первый удар: сила * 1.5 + живучесть + P
		var first_hit_damage = int(strength_val * 1.5 + vitality_val + physical_bonus)
		
		# Второй удар: сила * 2.0 + живучесть * 1.3 + P
		var second_hit_damage = int(strength_val * 2.0 + vitality_val * 1.3 + physical_bonus)
		
		# Проверяем критический удар для каждого удара
		var first_hit_crit = randf() < (get_crit_chance(owner) / 100.0)
		var second_hit_crit = randf() < (get_crit_chance(owner) / 100.0)
		
		# Применяем критический урон если есть
		if first_hit_crit:
			first_hit_damage = int(first_hit_damage * 1.5)
		
		if second_hit_crit:
			second_hit_damage = int(second_hit_damage * 1.5)
		
		# Проверяем шанс оглушения (20%)
		var apply_stun = randf() < 0.20
		
		return {
			"success": true,
			"damage": 0,  # Общий урон рассчитывается в battle_manager
			"is_crit": first_hit_crit or second_hit_crit,
			"damage_type": damage_type,
			"message": owner.display_name + " использует " + name + "!",
			"crushing_hammer": true,  # Флаг для battle_manager
			"first_hit_damage": first_hit_damage,
			"second_hit_damage": second_hit_damage,
			"first_hit_crit": first_hit_crit,
			"second_hit_crit": second_hit_crit,
			"apply_stun": apply_stun  # Флаг для наложения оглушения (20% шанс)
		}
	
	# Специальная обработка для "Точного выстрела" (Орк лучник)
	if id == "orc_arrow_shot":
		# Воспроизводим звук
		if SoundManager:
			SoundManager.play_sound("sword_hit", -5.0)
		
		# Получаем характеристики владельца
		var strength_val = owner.strength if "strength" in owner else 0
		var agility_val = owner.agility if "agility" in owner else 0
		
		# Получаем бонус физического урона (P)
		var physical_bonus = 0
		if owner.has_method("get_physical_damage_bonus"):
			physical_bonus = owner.get_physical_damage_bonus()
		elif "physical_damage_bonus" in owner:
			physical_bonus = owner.physical_damage_bonus
		
		# Рассчитываем урон: (сила + ловкость + P) * 1.6
		var arrow_damage = int((strength_val + agility_val + physical_bonus) * 1.6)
		
		# Проверяем критический удар с бонусом +20%
		var arrow_crit_chance = (get_crit_chance(owner) + 20.0) / 100.0
		var arrow_crit = randf() < arrow_crit_chance
		
		if arrow_crit:
			arrow_damage = int(arrow_damage * 1.5)  # Критический урон
		
		return {
			"success": true,
			"damage": arrow_damage,
			"is_crit": arrow_crit,
			"damage_type": damage_type,
			"message": owner.display_name + " использует " + name + "!",
			"orc_arrow_shot": true
		}
	
	# Специальная обработка для "Удара в спину" (Орк убийца)
	if id == "orc_backstab":
		# Воспроизводим звук
		if SoundManager:
			SoundManager.play_sound("sword_hit", -5.0)
		
		# Получаем характеристики владельца
		var strength_val = owner.strength if "strength" in owner else 0
		var agility_val = owner.agility if "agility" in owner else 0
		
		# Получаем бонус физического урона (P)
		var physical_bonus = 0
		if owner.has_method("get_physical_damage_bonus"):
			physical_bonus = owner.get_physical_damage_bonus()
		elif "physical_damage_bonus" in owner:
			physical_bonus = owner.physical_damage_bonus
		
		# Рассчитываем урон: (сила + ловкость + P) * 2.0
		var backstab_damage = int((strength_val + agility_val + physical_bonus) * 2.0)
		
		# Проверяем критический удар с бонусом +15%
		var backstab_crit_chance = (get_crit_chance(owner) + 15.0) / 100.0
		var backstab_crit = randf() < backstab_crit_chance
		
		if backstab_crit:
			backstab_damage = int(backstab_damage * 1.5)  # Критический урон
		
		# Проверяем шанс наложить яд (40%)
		var apply_poison = randf() < 0.40
		
		return {
			"success": true,
			"damage": backstab_damage,
			"is_crit": backstab_crit,
			"damage_type": damage_type,
			"message": owner.display_name + " использует " + name + "!",
			"orc_backstab": true,
			"apply_poison": apply_poison
		}
	
	# Специальная обработка для "Яростного удара" (Орк берсерк)
	if id == "orc_berserker_strike":
		# Воспроизводим звук
		if SoundManager:
			SoundManager.play_sound("sword_hit", -5.0)
		
		# Получаем характеристики владельца
		var strength_val = owner.strength if "strength" in owner else 0
		var vitality_val = owner.vitality if "vitality" in owner else 0
		
		# Получаем бонус физического урона (P)
		var physical_bonus = 0
		if owner.has_method("get_physical_damage_bonus"):
			physical_bonus = owner.get_physical_damage_bonus()
		elif "physical_damage_bonus" in owner:
			physical_bonus = owner.physical_damage_bonus
		
		# Рассчитываем базовый урон: (сила * 2.0 + живучесть + P)
		var base_berserker_damage = int(strength_val * 2.0 + vitality_val + physical_bonus)
		
		# Проверяем HP для бонуса ярости
		var hp_percent = (float(owner.hp) / float(owner.max_hp)) * 100.0
		var rage_multiplier = 1.0
		if hp_percent <= 30.0:
			rage_multiplier = 1.5  # +50% урон при HP < 30%
		elif hp_percent <= 50.0:
			rage_multiplier = 1.3  # +30% урон при HP < 50%
		
		var berserker_damage = int(base_berserker_damage * rage_multiplier)
		
		# Проверяем критический удар с бонусом +10%
		var berserker_crit_chance = (get_crit_chance(owner) + 10.0) / 100.0
		var berserker_crit = randf() < berserker_crit_chance
		
		if berserker_crit:
			berserker_damage = int(berserker_damage * 1.5)  # Критический урон
		
		return {
			"success": true,
			"damage": berserker_damage,
			"is_crit": berserker_crit,
			"damage_type": damage_type,
			"message": owner.display_name + " использует " + name + "!",
			"orc_berserker_strike": true
		}
	
	# Специальная обработка для "Духовного взрыва" (Орк шаман)
	if id == "orc_spirit_blast":
		# Воспроизводим звук
		if SoundManager:
			SoundManager.play_sound("magic_arrow", -5.0)
		
		# Получаем характеристики владельца
		var intelligence_val = owner.intelligence if "intelligence" in owner else 0
		var wisdom_val = owner.wisdom if "wisdom" in owner else 0
		
		# Применяем бонус магического урона от интеллекта
		var magic_damage_bonus = 0.0
		if "magic_damage_bonus" in owner:
			magic_damage_bonus = owner.magic_damage_bonus
		
		# Рассчитываем урон: (интеллект * 2.0 + мудрость * 1.5) * (1.0 + бонус магического урона)
		var base_spirit_damage = int(intelligence_val * 2.0 + wisdom_val * 1.5)
		var spirit_damage = int(base_spirit_damage * (1.0 + magic_damage_bonus))
		
		# Проверяем критический удар с бонусом +8%
		var spirit_crit_chance = (get_crit_chance(owner) + 8.0) / 100.0
		var spirit_crit = randf() < spirit_crit_chance
		
		if spirit_crit:
			spirit_damage = int(spirit_damage * 1.5)  # Критический урон
		
		# Проверяем шанс наложить дебафф на меткость (25%)
		var apply_accuracy_debuff = randf() < 0.25
		
		return {
			"success": true,
			"damage": spirit_damage,
			"is_crit": spirit_crit,
			"damage_type": damage_type,
			"message": owner.display_name + " использует " + name + "!",
			"orc_spirit_blast": true,
			"apply_accuracy_debuff": apply_accuracy_debuff
		}
	
	# Специальная обработка для "Теневых шипов" (Тёмный шатун)
	if id == "shadow_spikes":
		# Воспроизводим звук
		if SoundManager:
			SoundManager.play_sound("magic_arrow", -5.0)
		
		# Получаем характеристики владельца
		var agility_val = owner.agility if "agility" in owner else 0
		var intelligence_val = owner.intelligence if "intelligence" in owner else 0
		
		# Рассчитываем базовый урон: (ловкость + интеллект) * 2
		var spikes_damage = int((agility_val + intelligence_val) * 2)
		
		# Проверяем, находится ли владелец в невидимости
		var is_stealthed = false
		if owner.has_method("has_effect"):
			is_stealthed = owner.has_effect("stealth")
		
		# Проверяем критический удар
		var spikes_is_crit = false
		
		# Если в невидимости - АВТОКРИТ!
		if is_stealthed:
			spikes_is_crit = true
			spikes_damage = int(spikes_damage * 1.5)  # Критический урон
			print("🌑 Теневые шипы: АВТОКРИТ из невидимости! Урон: ", spikes_damage)
		else:
			# Обычная проверка крита
			var spikes_crit_chance = get_crit_chance(owner) / 100.0
			spikes_is_crit = randf() < spikes_crit_chance
			if spikes_is_crit:
				spikes_damage = int(spikes_damage * 1.5)
		
		return {
			"success": true,
			"damage": spikes_damage,
			"is_crit": spikes_is_crit,
			"damage_type": damage_type,
			"message": owner.display_name + " использует " + name + "!",
			"shadow_spikes": true,
			"from_stealth": is_stealthed
		}
	
	# Специальная обработка для "Удара брони" (Скелет лорд)
	if id == "armor_strike":
		# Воспроизводим звук
		if SoundManager:
			SoundManager.play_sound("sword_hit", -5.0)
		
		# Получаем характеристики владельца
		var strength_val = owner.strength if "strength" in owner else 0
		var vitality_val = owner.vitality if "vitality" in owner else 0
		var current_defense = owner.defense if "defense" in owner else 0
		
		# Получаем бонус физического урона (P)
		var physical_bonus = 0
		if owner.has_method("get_physical_damage_bonus"):
			physical_bonus = owner.get_physical_damage_bonus()
		elif "physical_damage_bonus" in owner:
			physical_bonus = owner.physical_damage_bonus
		
		# Рассчитываем урон: (сила + живучесть) + P + текущая защита * 2
		var armor_strike_damage = strength_val + vitality_val + physical_bonus + (current_defense * 2)
		
		# Проверяем критический удар
		var armor_strike_crit = randf() < (get_crit_chance(owner) / 100.0)
		
		if armor_strike_crit:
			armor_strike_damage = int(armor_strike_damage * 1.5)  # Критический урон
		
		return {
			"success": true,
			"damage": armor_strike_damage,
			"is_crit": armor_strike_crit,
			"damage_type": damage_type,
			"message": owner.display_name + " использует " + name + "!",
			"armor_strike": true,  # Флаг для battle_manager
			"armor_reduction": 6  # Снижение брони на 6 единиц
		}
	
	# Обычная обработка для других способностей
	var ability_damage = get_damage(owner)
	var is_crit = randf() < (get_crit_chance(owner) / 100.0)
	
	if is_crit:
		# Используем функцию из body.gd для применения критического множителя
		if owner.has_method("apply_crit_multiplier"):
			ability_damage = owner.apply_crit_multiplier(ability_damage)
		else:
			ability_damage = int(ability_damage * 1.5)  # Fallback для критического урона
	
	# Воспроизводим звуки для способностей
	if SoundManager:
		match id:
			"rat_bite":
				SoundManager.play_sound("rat_attack1", -10.0)  # Крысиный укус
			"mouse_swarm":
				SoundManager.play_sound("sword_hit", -5.0)  # Мышиная стая
			"slime_acid_blast", "rotten_slime_blast":
				SoundManager.play_sound("sword_hit", -5.0)  # Кислотные атаки
			"executioner_strike":
				SoundManager.play_sound("sword_hit", -5.0)  # Удар палача
			"alkara_dark_blast", "curse_blast", "tharnok_crushing_strike":
				SoundManager.play_sound("magic_arrow", -5.0)  # Магические атаки
			"goblin_warrior_strike", "goblin_thief_strike", "goblin_mage_strike":
				SoundManager.play_sound("sword_hit", -5.0)  # Атаки гоблинов
			"bat_swoop":
				SoundManager.play_sound("bat_attack", -5.0)  # Пикирование летучей мыши
			"bat_sonic_blast":
				SoundManager.play_sound("magic_arrow", -5.0)  # Ультразвуковая атака
			"dark_walker_shadow_strike":
				SoundManager.play_sound("sword_hit", -5.0)  # Теневой удар
	
	# НЕ наносим урон здесь - это будет сделано в battle_manager после проверки пассивных способностей
	# if target.has_method("take_damage"):
	#	target.take_damage(damage, damage_type)
	
	return {
		"success": true,
		"damage": ability_damage,
		"is_crit": is_crit,
		"damage_type": damage_type,
		"message": owner.display_name + " использует " + name + "!"
	}

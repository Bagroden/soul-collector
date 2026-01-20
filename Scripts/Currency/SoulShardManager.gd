# res://Scripts/Currency/SoulShardManager.gd
extends Node

# Глобальный менеджер осколков душ
var soul_shards: int = 0
var total_soul_shards_earned: int = 0
var run_soul_shards: int = 0  # Осколки, собранные за текущий забег
var last_soul_shard_reward: int = 0  # Последняя награда осколков душ

signal soul_shards_changed(new_amount: int)
signal soul_shards_earned(amount: int)
signal run_soul_shards_changed(new_amount: int)

func _ready():
	# Осколки душ загружаются через PlayerManager.load_game_data()
	# чтобы избежать конфликтов с порядком инициализации
	pass

func add_soul_shards(amount: int):
	"""Добавляет осколки душ за забег (НЕ в хранилище)"""
	# Сохраняем последнюю награду
	last_soul_shard_reward = amount
	
	# Добавляем только в счетчик за забег, НЕ в хранилище
	run_soul_shards += amount
	total_soul_shards_earned += amount
	run_soul_shards_changed.emit(run_soul_shards)
	soul_shards_earned.emit(amount)

func spend_soul_shards(amount: int) -> bool:
	"""Тратит осколки душ, возвращает true если успешно"""
	if soul_shards >= amount:
		soul_shards -= amount
		soul_shards_changed.emit(soul_shards)
		return true
	else:
		return false

func get_soul_shards() -> int:
	"""Возвращает текущее количество осколков душ"""
	return soul_shards

func get_total_earned() -> int:
	"""Возвращает общее количество заработанных осколков душ"""
	return total_soul_shards_earned

func get_run_soul_shards() -> int:
	"""Возвращает количество осколков душ, собранных за текущий забег"""
	return run_soul_shards

func get_last_soul_shard_reward() -> int:
	"""Возвращает последнюю награду осколков душ"""
	return last_soul_shard_reward

func reset_run_soul_shards():
	"""Сбрасывает счетчик осколков душ за забег"""
	run_soul_shards = 0
	run_soul_shards_changed.emit(run_soul_shards)

func start_new_run():
	"""Начинает новый забег - сбрасывает счетчик только если он уже был сброшен"""
	# Сбрасываем счетчик только если он равен 0 (новый забег)
	# или если это первый вызов (run_soul_shards еще не инициализирован)
	if run_soul_shards == 0:
		run_soul_shards_changed.emit(run_soul_shards)

func deposit_run_soul_shards():
	"""Переносит осколки душ за забег в основное хранилище (Колодец душ)"""
	var deposited_amount = run_soul_shards
	if deposited_amount > 0:
		soul_shards += deposited_amount
		total_soul_shards_earned += deposited_amount
		run_soul_shards = 0
		soul_shards_changed.emit(soul_shards)
		run_soul_shards_changed.emit(run_soul_shards)
		return deposited_amount
	return 0

func lose_half_run_soul_shards():
	"""Игрок теряет половину осколков душ за забег при смерти"""
	var lost_amount = int(run_soul_shards / 2.0)
	run_soul_shards = run_soul_shards - lost_amount
	run_soul_shards_changed.emit(run_soul_shards)
	return lost_amount

func calculate_soul_shards_for_enemy(enemy_level: int, enemy_rarity: String) -> int:
	"""Рассчитывает количество осколков душ за победу над врагом"""
	var rarity_multiplier = get_rarity_multiplier(enemy_rarity)
	var soul_shards_amount = enemy_level * 10 * rarity_multiplier
	return soul_shards_amount

func get_rarity_multiplier(rarity: String) -> int:
	"""Возвращает множитель редкости для расчета осколков душ"""
	match rarity.to_lower():
		"common":
			return 1
		"uncommon":
			return 2
		"rare":
			return 3
		"epic":
			return 4
		"legendary":
			return 5
		"mythical":
			return 6
		_:
			return 1

func save_soul_shards():
	"""Сохраняет осколки душ в файл"""
	
	var save_data = {
		"soul_shards": soul_shards,
		"total_earned": total_soul_shards_earned
	}
	
	var json_string = JSON.stringify(save_data)
	
	var file = FileAccess.open("user://soul_shards.save", FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
	else:
		print("ОШИБКА: Не удалось создать файл для сохранения осколков душ!")
	

func load_soul_shards():
	"""Загружает осколки душ из файла"""
	# Осколки душ теперь загружаются и сохраняются через основную систему сохранений

func reset_soul_shards():
	"""Сбрасывает осколки душ (для тестирования)"""
	soul_shards = 0
	total_soul_shards_earned = 0
	run_soul_shards = 0
	soul_shards_changed.emit(soul_shards)
	run_soul_shards_changed.emit(run_soul_shards)

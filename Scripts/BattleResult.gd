# res://Scripts/BattleResult.gd
class_name BattleResult
extends Node

var last_enemy_level: int = 1
var last_enemy_rarity: String = "common"
var battle_won: bool = false
var has_result: bool = false  # Флаг, указывающий, что результат боя установлен

func set_battle_result(enemy_level: int, enemy_rarity: String, won: bool):
	last_enemy_level = enemy_level
	last_enemy_rarity = enemy_rarity
	battle_won = won
	has_result = true

func get_last_enemy_level() -> int:
	return last_enemy_level

func get_last_enemy_rarity() -> String:
	return last_enemy_rarity

func was_battle_won() -> bool:
	return battle_won

func clear_result():
	last_enemy_level = 1
	last_enemy_rarity = "common"
	battle_won = false
	has_result = false

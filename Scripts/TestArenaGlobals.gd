# res://Scripts/TestArenaGlobals.gd
extends Node

# Глобальные переменные для тестовой арены
var test_mode: bool = false
var test_enemy_scene: String = ""
var test_enemy_rarity: String = "common"
var test_enemy_level: int = 1

func reset():
	"""Сбрасывает переменные тестового режима"""
	test_mode = false
	test_enemy_scene = ""
	test_enemy_rarity = "common"
	test_enemy_level = 1

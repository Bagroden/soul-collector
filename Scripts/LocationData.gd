# res://Scripts/LocationData.gd
class_name LocationData
extends Resource

@export var location_id: String
@export var location_name: String
@export var description: String
@export var min_level: int
@export var max_level: int
@export var is_unlocked: bool = false
@export var required_previous_location: String = ""

# Пул врагов для этой локации
var enemy_pools: Array = []

# Босс локации
@export var boss_enemy: String = ""

# Награды за прохождение
@export var exp_reward: int = 0
@export var gold_reward: int = 0


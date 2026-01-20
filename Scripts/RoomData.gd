# res://Scripts/RoomData.gd
class_name RoomData
extends Resource

enum RoomType {
	BATTLE,      # Бой с врагом
	REST,        # Отдых - восстановление ресурсов
	EVENT,       # Событие - случайный эффект
	TREASURE,    # Сокровище - награда
	BOSS,        # Босс локации
	ELITE_BATTLE # Элитный бой с усиленным врагом
}

@export var room_id: String
@export var room_type: RoomType
@export var room_name: String
@export var description: String
@export var is_cleared: bool = false
@export var is_quest_room: bool = false  # Является ли комната квестовой

# Для боевых комнат
var enemy_scene: String = ""
var enemy_rarity: String = "common"

# Для событий
var event_effects: Array = []

# Награды за прохождение комнаты
@export var exp_reward: int = 0
@export var gold_reward: int = 0

func _init(id: String = "", type: RoomType = RoomType.BATTLE, name: String = "", desc: String = ""):
	room_id = id
	room_type = type
	room_name = name
	description = desc

func get_room_type_name() -> String:
	match room_type:
		RoomType.BATTLE:
			return "Бой"
		RoomType.REST:
			return "Отдых"
		RoomType.EVENT:
			return "Событие"
		RoomType.TREASURE:
			return "Сокровище"
		RoomType.BOSS:
			return "Босс"
		RoomType.ELITE_BATTLE:
			return "Элитный бой"
		_:
			return "Неизвестно"

func get_rarity_display_name() -> String:
	match enemy_rarity:
		"common":
			return "Обычный"
		"uncommon":
			return "Необычный"
		"rare":
			return "Редкий"
		"epic":
			return "Эпический"
		"legendary":
			return "Легендарный"
		"mythic":
			return "Мифический"
		"elite":
			return "Элитный"
		_:
			return "Неизвестный"

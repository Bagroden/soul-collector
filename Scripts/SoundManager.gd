# Scripts/SoundManager.gd
extends Node

# Синглтон для глобального доступа к звукам
static var instance: SoundManager

# Словарь для хранения звуков
var sound_effects: Dictionary = {}

func _ready():
	instance = self
	_load_sound_effects()

func _load_sound_effects():
	"""Загружает все звуковые эффекты"""
	# Звуки способностей
	sound_effects["rat_bite"] = preload("res://Audio/Sounds/rat_bite.wav")
	sound_effects["rat_attack1"] = preload("res://Audio/Sounds/rat_attack1.wav")
	sound_effects["sword_hit"] = preload("res://Audio/Sounds/sword_hit.wav")
	sound_effects["sword_attack1"] = preload("res://Audio/Sounds/sword_attack1.wav")
	sound_effects["sword_attack3"] = preload("res://Audio/Sounds/sword_attack3.wav")
	sound_effects["sword_attack4"] = preload("res://Audio/Sounds/sword_attack4.wav")
	sound_effects["poison_strike1"] = preload("res://Audio/Sounds/poison_strike1.wav")
	sound_effects["magic2"] = preload("res://Audio/Sounds/magic2.wav")
	sound_effects["bat_attack"] = preload("res://Audio/Sounds/bat_attack.wav")
	# Звуки летучей мыши
	sound_effects["bat_hurt"] = preload("res://Audio/Sounds/Bat/bat_hurt.wav")
	sound_effects["bat_attack_anim"] = preload("res://Audio/Sounds/Bat/bat_attack.wav")
	sound_effects["bat_die"] = preload("res://Audio/Sounds/Bat/bat_die.wav")
	sound_effects["magic_arrow"] = preload("res://Audio/Sounds/magic_arrow.wav")
	sound_effects["critical_hit"] = preload("res://Audio/Sounds/critical_hit.wav")
	sound_effects["Hit1"] = preload("res://Audio/Sounds/Hit1.wav")
	# Звуки слизня
	sound_effects["slime_attack"] = preload("res://Audio/Sounds/Slime/slime_attack.wav")
	sound_effects["acid_blast"] = preload("res://Audio/Sounds/Slime/icid_blast.wav")
	sound_effects["slime_die"] = preload("res://Audio/Sounds/Slime/slime_die.wav")
	# Звуки крысы
	sound_effects["rat_pain"] = preload("res://Audio/Sounds/Rat/rat_pain.wav")
	sound_effects["rat_die"] = preload("res://Audio/Sounds/Rat/rat_die.wav")
	
		# Звуки интерфейса
	sound_effects["button_click"] = preload("res://Audio/Sounds/button_click.wav")
	sound_effects["level_up"] = preload("res://Audio/Sounds/level_up.wav")
	sound_effects["page"] = preload("res://Audio/Sounds/Page.wav")

func play_sound(sound_name: String, volume_db: float = 0.0):
	"""Воспроизводит звуковой эффект"""
	if not sound_effects.has(sound_name):
		print("Звук не найден: ", sound_name)
		return
	
	# Создаем AudioStreamPlayer для звука
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = sound_effects[sound_name]
	audio_player.volume_db = volume_db
	add_child(audio_player)
	
	# Воспроизводим звук
	audio_player.play()
	
	# Удаляем плеер после завершения
	audio_player.finished.connect(func(): audio_player.queue_free())

func play_sound_at_position(sound_name: String, position: Vector2, volume_db: float = 0.0):
	"""Воспроизводит звук в определенной позиции (для 3D звука)"""
	if not sound_effects.has(sound_name):
		print("Звук не найден: ", sound_name)
		return
	
	var audio_player = AudioStreamPlayer2D.new()
	audio_player.stream = sound_effects[sound_name]
	audio_player.volume_db = volume_db
	audio_player.position = position
	add_child(audio_player)
	
	audio_player.play()
	audio_player.finished.connect(func(): audio_player.queue_free())

# Статические методы для удобного доступа
static func play(sound_name: String, volume_db: float = 0.0):
	"""Статический метод для воспроизведения звука"""
	if instance:
		instance.play_sound(sound_name, volume_db)

static func play_at_position(sound_name: String, position: Vector2, volume_db: float = 0.0):
	"""Статический метод для воспроизведения звука в позиции"""
	if instance:
		instance.play_sound_at_position(sound_name, position, volume_db)

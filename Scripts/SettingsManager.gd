# res://Scripts/SettingsManager.gd
extends Node

# Настройки отображения
var show_health_as_percentage: bool = false
var show_mana_as_percentage: bool = false
var show_stamina_as_percentage: bool = false

# Настройки боевого лога
var show_failed_ability_logs: bool = true  # Показывать логи несработавших способностей

# Настройки звука
var music_volume: float = 0.0  # Громкость музыки в dB (0.0 = максимальная громкость)

# Файл настроек
const SETTINGS_FILE = "user://settings.dat"

func _ready():
	load_settings()

func save_settings():
	"""Сохраняет настройки в файл"""
	var settings_data = {
		"show_health_as_percentage": show_health_as_percentage,
		"show_mana_as_percentage": show_mana_as_percentage,
		"show_stamina_as_percentage": show_stamina_as_percentage,
		"show_failed_ability_logs": show_failed_ability_logs,
		"music_volume": music_volume
	}
	
	var save_file = FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(settings_data))
		save_file.close()
		print("Настройки сохранены")
	else:
		print("Ошибка сохранения настроек")

func load_settings():
	"""Загружает настройки из файла"""
	if not FileAccess.file_exists(SETTINGS_FILE):
		return
	
	var save_file = FileAccess.open(SETTINGS_FILE, FileAccess.READ)
	if save_file == null:
		return
	
	var json_string = save_file.get_as_text()
	save_file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		return
	
	var settings_data = json.get_data()
	
	show_health_as_percentage = settings_data.get("show_health_as_percentage", false)
	show_mana_as_percentage = settings_data.get("show_mana_as_percentage", false)
	show_stamina_as_percentage = settings_data.get("show_stamina_as_percentage", false)
	show_failed_ability_logs = settings_data.get("show_failed_ability_logs", true)
	music_volume = settings_data.get("music_volume", 0.0)
	
	# Применяем загруженную громкость к MusicPlayer
	var music_player = get_node_or_null("/root/MusicPlayer")
	if music_player:
		music_player.set_volume(music_volume)
	

func set_health_display_mode(percentage: bool):
	"""Устанавливает режим отображения здоровья"""
	show_health_as_percentage = percentage
	save_settings()

func set_mana_display_mode(percentage: bool):
	"""Устанавливает режим отображения маны"""
	show_mana_as_percentage = percentage
	save_settings()

func set_stamina_display_mode(percentage: bool):
	"""Устанавливает режим отображения выносливости"""
	show_stamina_as_percentage = percentage
	save_settings()

func get_health_display_mode() -> bool:
	"""Возвращает режим отображения здоровья"""
	return show_health_as_percentage

func get_mana_display_mode() -> bool:
	"""Возвращает режим отображения маны"""
	return show_mana_as_percentage

func get_stamina_display_mode() -> bool:
	"""Возвращает режим отображения выносливости"""
	return show_stamina_as_percentage

func set_show_failed_ability_logs(show: bool):
	"""Устанавливает отображение логов несработавших способностей"""
	show_failed_ability_logs = show
	save_settings()

func get_show_failed_ability_logs() -> bool:
	"""Возвращает настройку отображения логов несработавших способностей"""
	return show_failed_ability_logs

func set_music_volume(volume: float):
	"""Устанавливает громкость музыки"""
	music_volume = clamp(volume, -80.0, 0.0)  # Ограничиваем диапазон от -80 до 0 dB
	save_settings()
	
	# Применяем настройку к MusicPlayer
	var music_player = get_node_or_null("/root/MusicPlayer")
	if music_player:
		music_player.set_volume(music_volume)

func get_music_volume() -> float:
	"""Возвращает громкость музыки"""
	return music_volume

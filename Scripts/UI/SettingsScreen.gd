# res://Scripts/UI/SettingsScreen.gd
extends Control

@onready var health_percentage = $MainContainer/DisplaySettings/HealthSetting/HealthPercentage
@onready var health_absolute = $MainContainer/DisplaySettings/HealthSetting/HealthAbsolute
@onready var mana_percentage = $MainContainer/DisplaySettings/ManaSetting/ManaPercentage
@onready var mana_absolute = $MainContainer/DisplaySettings/ManaSetting/ManaAbsolute
@onready var stamina_percentage = $MainContainer/DisplaySettings/StaminaSetting/StaminaPercentage
@onready var stamina_absolute = $MainContainer/DisplaySettings/StaminaSetting/StaminaAbsolute
@onready var failed_abilities_checkbox = $MainContainer/BattleLogSettings/FailedAbilitiesSetting/FailedAbilitiesCheckBox
@onready var music_volume_slider = $MainContainer/AudioSettings/MusicVolumeSetting/MusicVolumeSlider
@onready var music_volume_value = $MainContainer/AudioSettings/MusicVolumeSetting/MusicVolumeValue
@onready var back_button = $MainContainer/Buttons/BackButton
@onready var save_button = $MainContainer/Buttons/SaveButton

var previous_scene: String = ""

func _ready():
	# Подключаем сигналы
	health_percentage.toggled.connect(_on_health_percentage_toggled)
	health_absolute.toggled.connect(_on_health_absolute_toggled)
	mana_percentage.toggled.connect(_on_mana_percentage_toggled)
	mana_absolute.toggled.connect(_on_mana_absolute_toggled)
	stamina_percentage.toggled.connect(_on_stamina_percentage_toggled)
	stamina_absolute.toggled.connect(_on_stamina_absolute_toggled)
	failed_abilities_checkbox.toggled.connect(_on_failed_abilities_toggled)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	back_button.pressed.connect(_on_back_pressed)
	save_button.pressed.connect(_on_save_pressed)
	
	# Загружаем текущие настройки
	_load_current_settings()

func set_previous_scene(scene_path: String):
	"""Устанавливает предыдущую сцену для возврата"""
	previous_scene = scene_path

func _load_current_settings():
	"""Загружает текущие настройки из SettingsManager"""
	var settings_manager = get_node_or_null("/root/SettingsManager")
	if not settings_manager:
		return
	
	# Устанавливаем состояния чекбоксов
	health_percentage.button_pressed = settings_manager.get_health_display_mode()
	health_absolute.button_pressed = not settings_manager.get_health_display_mode()
	mana_percentage.button_pressed = settings_manager.get_mana_display_mode()
	mana_absolute.button_pressed = not settings_manager.get_mana_display_mode()
	stamina_percentage.button_pressed = settings_manager.get_stamina_display_mode()
	stamina_absolute.button_pressed = not settings_manager.get_stamina_display_mode()
	failed_abilities_checkbox.button_pressed = settings_manager.get_show_failed_ability_logs()
	
	# Устанавливаем громкость музыки (временно отключаем сигнал чтобы избежать сброса)
	music_volume_slider.value_changed.disconnect(_on_music_volume_changed)
	music_volume_slider.value = settings_manager.get_music_volume()
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	_update_music_volume_display(settings_manager.get_music_volume())
	
	# Устанавливаем правильный текст для чекбокса несработавших способностей
	if failed_abilities_checkbox.button_pressed:
		failed_abilities_checkbox.text = "Включено"
	else:
		failed_abilities_checkbox.text = "Выключено"

func _on_health_percentage_toggled(pressed: bool):
	"""Обрабатывает переключение отображения здоровья в процентах"""
	if pressed:
		health_absolute.button_pressed = false

func _on_health_absolute_toggled(pressed: bool):
	"""Обрабатывает переключение отображения здоровья в абсолютных значениях"""
	if pressed:
		health_percentage.button_pressed = false

func _on_mana_percentage_toggled(pressed: bool):
	"""Обрабатывает переключение отображения маны в процентах"""
	if pressed:
		mana_absolute.button_pressed = false

func _on_mana_absolute_toggled(pressed: bool):
	"""Обрабатывает переключение отображения маны в абсолютных значениях"""
	if pressed:
		mana_percentage.button_pressed = false

func _on_stamina_percentage_toggled(pressed: bool):
	"""Обрабатывает переключение отображения выносливости в процентах"""
	if pressed:
		stamina_absolute.button_pressed = false

func _on_stamina_absolute_toggled(pressed: bool):
	"""Обрабатывает переключение отображения выносливости в абсолютных значениях"""
	if pressed:
		stamina_percentage.button_pressed = false

func _on_failed_abilities_toggled(pressed: bool):
	"""Обрабатывает переключение отображения несработавших способностей"""
	# Обновляем текст чекбокса
	if pressed:
		failed_abilities_checkbox.text = "Включено"
	else:
		failed_abilities_checkbox.text = "Выключено"

func _on_music_volume_changed(value: float):
	"""Обрабатывает изменение громкости музыки"""
	_update_music_volume_display(value)
	
	# Применяем настройку сразу
	var settings_manager = get_node_or_null("/root/SettingsManager")
	if settings_manager:
		settings_manager.set_music_volume(value)

func _update_music_volume_display(volume_db: float):
	"""Обновляет отображение громкости музыки"""
	# Конвертируем dB в проценты (0 dB = 100%, -80 dB = 0%)
	var percentage = int((volume_db + 80.0) / 80.0 * 100.0)
	music_volume_value.text = str(percentage) + "%"

func _on_save_pressed():
	"""Сохраняет настройки"""
	var settings_manager = get_node_or_null("/root/SettingsManager")
	if not settings_manager:
		return
	
	# Сохраняем настройки
	settings_manager.set_health_display_mode(health_percentage.button_pressed)
	settings_manager.set_mana_display_mode(mana_percentage.button_pressed)
	settings_manager.set_stamina_display_mode(stamina_percentage.button_pressed)
	settings_manager.set_show_failed_ability_logs(failed_abilities_checkbox.button_pressed)
	
	# Показываем сообщение об успехе
	_show_message("Настройки сохранены!")

func _on_back_pressed():
	"""Возвращается к предыдущей сцене"""
	if previous_scene != "":
		SceneTransition.change_scene(previous_scene)
	else:
		SceneTransition.change_scene("res://Scenes/MainMenu.tscn")

func _show_message(text: String):
	"""Показывает сообщение пользователю"""
	var dialog = AcceptDialog.new()
	dialog.title = "Информация"
	dialog.dialog_text = text
	add_child(dialog)
	dialog.popup_centered()
	dialog.connect("confirmed", Callable(dialog, "queue_free"))
	dialog.connect("canceled", Callable(dialog, "queue_free"))

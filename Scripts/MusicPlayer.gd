# Scripts/MusicPlayer.gd
extends Node

# Музыкальный плеер для фоновой музыки
var audio_stream_player: AudioStreamPlayer
var current_music: AudioStream
var is_playing: bool = false
var fade_tween: Tween
var target_volume: float = 0.0
var is_fading: bool = false

func _ready():
	# Создаем AudioStreamPlayer
	audio_stream_player = AudioStreamPlayer.new()
	audio_stream_player.name = "AudioStreamPlayer"
	add_child(audio_stream_player)
	
	# Подключаем сигналы
	audio_stream_player.finished.connect(_on_music_finished)
	
	# Применяем настройки громкости из SettingsManager
	var settings_manager = get_node_or_null("/root/SettingsManager")
	if settings_manager:
		audio_stream_player.volume_db = settings_manager.get_music_volume()
	

func play_music(music_stream: AudioStream, fade_in: bool = true, crossfade: bool = true, fade_duration: float = 4.0, start_volume: float = -20.0):
	"""Воспроизводит музыку с плавными переходами"""
	if music_stream == current_music and is_playing and not is_fading:
		return
	
	# Если музыка уже играет и нужен crossfade
	if is_playing and crossfade and music_stream != current_music:
		_crossfade_to_new_music(music_stream, fade_duration, start_volume)
		return
	
	# Останавливаем текущую анимацию
	_stop_fade_tween()
	
	current_music = music_stream
	audio_stream_player.stream = music_stream
	
	# Настраиваем зацикливание
	if music_stream and music_stream.has_method("set_loop"):
		music_stream.set_loop(true)
	elif music_stream and music_stream.has_method("set_loop_mode"):
		music_stream.set_loop_mode(1)  # LOOP_FORWARD = 1
	
	if fade_in:
		audio_stream_player.volume_db = start_volume  # Настраиваемая начальная громкость
		audio_stream_player.play()
		_fade_in(fade_duration)
	else:
		# Используем target_volume вместо фиксированного 0.0
		audio_stream_player.volume_db = target_volume
		audio_stream_player.play()
	
	is_playing = true
	# Не сбрасываем target_volume, оставляем текущее значение

func stop_music(fade_out: bool = true):
	"""Останавливает музыку с плавным затуханием"""
	_stop_fade_tween()
	
	if fade_out and is_playing:
		_fade_out()
	else:
		audio_stream_player.stop()
		is_playing = false

func pause_music():
	"""Приостанавливает музыку"""
	audio_stream_player.stream_paused = true

func resume_music():
	"""Возобновляет музыку"""
	audio_stream_player.stream_paused = false

func set_volume(volume_db: float):
	"""Устанавливает громкость"""
	audio_stream_player.volume_db = volume_db
	target_volume = volume_db

func get_volume() -> float:
	"""Возвращает текущую громкость"""
	return audio_stream_player.volume_db

func is_music_playing() -> bool:
	"""Проверяет, воспроизводится ли музыка"""
	return audio_stream_player.playing

func is_playing_music(music_stream: AudioStream) -> bool:
	"""Проверяет, играет ли конкретная музыка"""
	return is_playing and current_music == music_stream and audio_stream_player.playing

func get_current_music() -> AudioStream:
	"""Возвращает текущую музыку"""
	return current_music

func set_loop_enabled(enabled: bool = true):
	"""Включает или отключает зацикливание текущей музыки"""
	if current_music:
		if current_music.has_method("set_loop"):
			current_music.set_loop(enabled)
		elif current_music.has_method("set_loop_mode"):
			if enabled:
				current_music.set_loop_mode(1)  # LOOP_FORWARD = 1
			else:
				current_music.set_loop_mode(0)  # LOOP_DISABLED = 0

func _on_music_finished():
	"""Вызывается когда музыка заканчивается"""
	
	# Автоматически перезапускаем музыку для зацикливания
	if current_music and is_playing:
		audio_stream_player.play()
	else:
		is_playing = false

func _fade_in(duration: float = 4.0):
	"""Плавное появление музыки"""
	_stop_fade_tween()
	is_fading = true
	fade_tween = create_tween()
	# Используем target_volume вместо фиксированного 0.0
	fade_tween.tween_property(audio_stream_player, "volume_db", target_volume, duration)
	fade_tween.tween_callback(_on_fade_complete)

func _fade_out(duration: float = 2.0):
	"""Плавное затухание музыки"""
	_stop_fade_tween()
	is_fading = true
	fade_tween = create_tween()
	fade_tween.tween_property(audio_stream_player, "volume_db", -80.0, duration)
	fade_tween.tween_callback(_stop_after_fade)

func _crossfade_to_new_music(new_music: AudioStream, fade_duration: float = 4.0, start_volume: float = -20.0):
	"""Плавный переход к новой музыке"""
	
	# Сначала затухаем текущую музыку (быстрее чем fade-in)
	var fade_out_duration = fade_duration * 0.5  # В 2 раза быстрее
	_fade_out(fade_out_duration)
	
	# Ждем завершения затухания, затем запускаем новую
	await get_tree().create_timer(fade_out_duration).timeout
	
	# Запускаем новую музыку
	current_music = new_music
	audio_stream_player.stream = new_music
	
	# Настраиваем зацикливание для новой музыки
	if new_music and new_music.has_method("set_loop"):
		new_music.set_loop(true)
	elif new_music and new_music.has_method("set_loop_mode"):
		new_music.set_loop_mode(1)  # LOOP_FORWARD = 1
	
	audio_stream_player.volume_db = start_volume  # Настраиваемая начальная громкость
	audio_stream_player.play()
	_fade_in(fade_duration)  # Используем переданную длительность для fade-in

func _stop_fade_tween():
	"""Останавливает текущую анимацию затухания"""
	if fade_tween and fade_tween.is_running():
		fade_tween.kill()
		fade_tween = null
	is_fading = false

func _on_fade_complete():
	"""Вызывается при завершении fade-in"""
	is_fading = false
	# Не сбрасываем target_volume, оставляем текущее значение

func _stop_after_fade():
	"""Останавливает музыку после затухания"""
	audio_stream_player.stop()
	is_playing = false
	is_fading = false

# res://Scripts/Battle/LightningEffectAnimated.gd
extends AnimatedSprite2D
class_name LightningEffectAnimated

## Визуальный эффект удара молнии для пассивки "Шаман бурь"
## Появляется над целью и проигрывает покадровую анимацию молнии

@export var fade_duration: float = 0.2  # Длительность исчезновения
@export var scale_start: float = 0.5    # Начальный размер
@export var scale_end: float = 1.0      # Конечный размер во время анимации
@export var sound_volume_db: float = 0.0  # Громкость звука молнии (-80 до 24)
@export var sound_pitch: float = 1.0     # Высота звука (0.5 - низкий, 2.0 - высокий)

func _ready():
	print("⚡ LightningEffect _ready() вызван")
	
	# Настраиваем начальные параметры
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Начинаем с уменьшенного размера и прозрачности
	scale = Vector2(scale_start, scale_start)
	modulate = Color(1.5, 1.5, 1.8, 0.0)  # Светло-голубой оттенок, прозрачный
	
	print("⚡ Начальные параметры: scale=", scale, ", modulate=", modulate)
	print("⚡ SpriteFrames: ", sprite_frames)
	
	if sprite_frames:
		var anims = sprite_frames.get_animation_names()
		print("⚡ Доступные анимации: ", anims)
	else:
		print("❌ SpriteFrames не установлен!")
	
	# Создаем и настраиваем звук молнии
	_setup_lightning_sound()
	
	# Запускаем анимацию
	_play_animation()

func setup(target_position: Vector2):
	"""Настраивает позицию молнии над целью"""
	print("⚡ setup() вызван с позицией: ", target_position)
	
	# Размещаем молнию немного выше цели
	global_position = target_position + Vector2(0, -100)
	
	# Добавляем небольшое случайное смещение
	var random_offset = Vector2(randf_range(-15, 15), randf_range(-15, 15))
	global_position += random_offset
	
	print("⚡ Итоговая позиция эффекта: ", global_position)

func _setup_lightning_sound():
	"""Создает и настраивает AudioStreamPlayer2D для звука молнии"""
	var audio_player = AudioStreamPlayer2D.new()
	audio_player.name = "LightningSoundPlayer"
	
	# Загружаем звук молнии
	var thunder_sound = load("res://Audio/Sounds/Thunder_bolt.wav")
	if thunder_sound:
		audio_player.stream = thunder_sound
		audio_player.volume_db = sound_volume_db  # Используем экспортируемый параметр
		audio_player.pitch_scale = sound_pitch     # Используем экспортируемый параметр
		audio_player.bus = "Master"
		audio_player.max_distance = 2000.0  # Максимальное расстояние слышимости
		audio_player.attenuation = 1.0      # Затухание звука с расстоянием
		print("🔊 Звук молнии загружен (громкость: ", sound_volume_db, " dB, высота: ", sound_pitch, ")")
	else:
		print("⚠️ Не удалось загрузить звук молнии")
	
	add_child(audio_player)

func _play_animation():
	"""Проигрывает анимацию молнии"""
	print("⚡ _play_animation() начинается")
	
	# Проигрываем звук молнии
	var audio_player = get_node_or_null("LightningSoundPlayer")
	if audio_player:
		audio_player.play()
		print("🔊 Звук молнии проигрывается")
	
	# Фаза 1: Быстрое появление
	print("⚡ Фаза 1: Появление...")
	var appear_tween = create_tween()
	appear_tween.set_parallel(true)
	
	# Плавное появление
	appear_tween.tween_property(self, "modulate:a", 1.0, 0.1)
	
	# Увеличение до нормального размера
	appear_tween.tween_property(self, "scale", Vector2(scale_end, scale_end), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Ждём завершения появления
	await appear_tween.finished
	print("⚡ Фаза 1 завершена")
	
	# Фаза 2: Проигрываем анимацию молнии
	if sprite_frames and sprite_frames.has_animation("lightning"):
		print("⚡ Фаза 2: Проигрывание анимации 'lightning'...")
		play("lightning")
		print("⚡ play('lightning') вызвана, is_playing=", is_playing())
		
		# Добавляем пульсацию яркости во время анимации
		var pulse_count = 0
		while is_playing():
			pulse_count += 1
			var pulse_tween = create_tween()
			pulse_tween.tween_property(self, "modulate", Color(2.0, 2.0, 2.5, 1.0), 0.05)
			await pulse_tween.finished
			
			var dim_tween = create_tween()
			dim_tween.tween_property(self, "modulate", Color(1.2, 1.2, 1.6, 1.0), 0.05)
			await dim_tween.finished
		
		print("⚡ Пульсации выполнено: ", pulse_count)
		
		# Ждём завершения анимации
		await animation_finished
		print("⚡ Фаза 2 завершена (анимация закончилась)")
	else:
		print("⚠️ Анимация 'lightning' не найдена или SpriteFrames отсутствует")
		print("⚠️ sprite_frames=", sprite_frames)
		if sprite_frames:
			print("⚠️ has_animation('lightning')=", sprite_frames.has_animation("lightning"))
		# Если анимации нет, просто ждём немного
		await get_tree().create_timer(0.5).timeout
	
	# Фаза 3: Исчезновение
	print("⚡ Фаза 3: Исчезновение...")
	var fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	fade_tween.tween_property(self, "scale", Vector2(scale_end * 1.2, scale_end * 1.2), fade_duration)
	
	await fade_tween.finished
	print("⚡ Фаза 3 завершена")
	
	# Удаляем эффект
	print("⚡ Удаление эффекта молнии")
	queue_free()

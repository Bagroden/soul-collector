# res://Scripts/UI/IntroScene.gd
extends Control

## Сцена вступительного ролика с историей игры

# Типы кинематографических эффектов
enum CinematicEffect {
	ZOOM_IN,      # Приближение
	ZOOM_OUT,     # Отдаление
	PAN_LEFT,     # Панорама влево
	PAN_RIGHT,    # Панорама вправо
	PAN_UP,       # Панорама вверх
	PAN_DOWN,     # Панорама вниз
	NONE          # Без эффекта
}

# Слайды интро с кинематографическими эффектами
var slides: Array[Dictionary] = [
	{
		"image": "res://Assets/Intro/slide_01_war.png",
		"text": "Веками ангелы и демоны ведут непримиримую войну за судьбу мира...",
		"duration": 4.0,
		"audio": "res://Assets/Audio/Intro/narration_slide_01.ogg",
		"effect": CinematicEffect.ZOOM_IN  # Приближение на битву
	},
	{
		"image": "res://Assets/Intro/slide_02_meeting.png",
		"text": "Но даже в пламени вечной битвы случаются удивительные события.",
		"duration": 3.5,
		"audio": "res://Assets/Audio/Intro/narration_slide_02.ogg",
		"effect": CinematicEffect.ZOOM_IN  # Приближение
	},
	{
		"image": "res://Assets/Intro/slide_03_love.png",
		"text": "Демон и девушка-ангел полюбили друг друга, встречаясь в тайне от обеих сторон...",
		"duration": 4.0,
		"audio": "res://Assets/Audio/Intro/narration_slide_03.ogg",
		"effect": CinematicEffect.ZOOM_IN  # Приближение к влюбленным
	},
	{
		"image": "res://Assets/Intro/slide_04_secret.png",
		"text": "Их любовь была запретной, ведь от союза ангела и демона рождался нефилим - существо, которого боялись все.",
		"duration": 5.0,
		"audio": "res://Assets/Audio/Intro/narration_slide_04.ogg",
		"effect": CinematicEffect.PAN_DOWN  # Панорама вниз
	},
	{
		"image": "res://Assets/Intro/slide_05_betrayal.png",
		"text": "Но брат ангела прознал об их тайне...",
		"duration": 3.5,
		"audio": "res://Assets/Audio/Intro/narration_slide_05.ogg",
		"effect": CinematicEffect.ZOOM_OUT  # Отдаление - драматический момент
	},
	{
		"image": "res://Assets/Intro/slide_06_hunt.png",
		"text": "Объединившись, силы ангелов и демонов выследили влюбленных.",
		"duration": 4.0,
		"audio": "res://Assets/Audio/Intro/narration_slide_06.ogg",
		"effect": CinematicEffect.PAN_LEFT  # Панорама влево - преследование
	},
	{
		"image": "res://Assets/Intro/slide_07_battle.png",
		"text": "Девушка-ангел была уже беременна. В отчаянной битве они проигрывали...",
		"duration": 4.5,
		"audio": "res://Assets/Audio/Intro/narration_slide_07.ogg",
		"effect": CinematicEffect.ZOOM_IN  # Приближение к битве
	},
	{
		"image": "res://Assets/Intro/slide_08_sacrifice.png",
		"text": "Чтобы спасти душу своего неродившегося ребенка, они пожертвовали своими жизнями...",
		"duration": 5.0,
		"audio": "res://Assets/Audio/Intro/narration_slide_08.ogg",
		"effect": CinematicEffect.ZOOM_OUT  # Отдаление - жертва
	},
	{
		"image": "res://Assets/Intro/slide_09_comet.png",
		"text": "Яркая комета пронеслась над землями, унося последнюю надежду влюбленных...",
		"duration": 4.5,
		"audio": "res://Assets/Audio/Intro/narration_slide_09.ogg",
		"effect": CinematicEffect.PAN_UP  # Панорама вверх - комета в небе
	},
	{
		"image": "res://Assets/Intro/slide_10_fall.png",
		"text": "Душа упала в древнем лесу... Где умирающий волк обрел новую жизнь, а ты - свою историю...",
		"duration": 5.5,
		"audio": "res://Assets/Audio/Intro/narration_slide_10.ogg",
		"effect": CinematicEffect.ZOOM_IN  # Приближение к волку
	}
]

# UI элементы
@onready var image_display: TextureRect = null
@onready var text_label: RichTextLabel = null
@onready var skip_button: Button = null
@onready var fade_overlay: ColorRect = null

# Состояние
var current_slide: int = 0
var slide_timer: Timer = null
var fade_tween: Tween = null
var is_transitioning: bool = false
var can_skip: bool = true

# Аудио
var current_voice_player: AudioStreamPlayer = null
var background_music_player: AudioStreamPlayer = null

func _ready():
	# Создаем UI
	_setup_ui()
	
	# Запускаем фоновую музыку
	_play_background_music()
	
	# Ждем 1.5 секунды перед началом интро (музыка играет заранее)
	await get_tree().create_timer(1.5).timeout
	
	# Запускаем интро
	_start_intro()
	
	# Обработка нажатия клавиш
	set_process_input(true)

func _setup_ui():
	"""Создает UI элементы для интро"""
	# Фон (черный)
	var background = ColorRect.new()
	background.color = Color.BLACK
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	add_child(background)
	
	# Изображение слайда (на весь экран с возможностью масштабирования)
	image_display = TextureRect.new()
	image_display.set_anchors_preset(Control.PRESET_FULL_RECT)  # Растягиваем на весь экран
	image_display.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	image_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image_display.modulate = Color(1, 1, 1, 0)  # Начинаем с невидимого
	image_display.pivot_offset = Vector2(960, 540)  # Центр экрана (1920x1080)
	add_child(image_display)
	
	# Субтитры убраны - только изображения и озвучка
	# text_label = RichTextLabel.new()
	# ...
	# add_child(text_label)
	
	# Оверлей для затемнения при переходах
	fade_overlay = ColorRect.new()
	fade_overlay.color = Color.BLACK
	fade_overlay.anchor_right = 1.0
	fade_overlay.anchor_bottom = 1.0
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_overlay.modulate = Color(1, 1, 1, 0)
	add_child(fade_overlay)
	
	# Кнопка пропуска
	skip_button = Button.new()
	skip_button.text = "Пропустить (ESC)"
	skip_button.anchor_left = 1.0
	skip_button.anchor_top = 0.0
	skip_button.anchor_right = 1.0
	skip_button.anchor_bottom = 0.0
	skip_button.offset_left = -180
	skip_button.offset_top = 20
	skip_button.offset_right = -20
	skip_button.offset_bottom = 60
	skip_button.pressed.connect(_on_skip_pressed)
	add_child(skip_button)
	
	# Таймер для смены слайдов
	slide_timer = Timer.new()
	slide_timer.one_shot = true
	slide_timer.timeout.connect(_on_slide_timeout)
	add_child(slide_timer)

func _input(event):
	"""Обработка ввода"""
	if event.is_action_pressed("ui_cancel") and can_skip:
		_on_skip_pressed()
	elif event.is_pressed() and not is_transitioning:
		# Любое нажатие клавиши переключает на следующий слайд
		# Проверяем только что не идет fade-out переход
		_next_slide()

func _start_intro():
	"""Запускает показ интро"""
	current_slide = 0
	_show_slide(current_slide)

func _show_slide(index: int):
	"""Показывает слайд с индексом"""
	if index >= slides.size():
		_finish_intro()
		return
	
	var slide = slides[index]
	
	# Загружаем изображение (если файл существует)
	var texture = _load_slide_image(slide.image)
	if texture:
		image_display.texture = texture
	
	# Воспроизводим озвучку слайда и получаем реальную длительность аудио
	var audio_duration = _play_slide_audio(slide)
	
	# Используем реальную длительность аудио + 0.5 сек паузы, или дефолтную если аудио нет
	var duration = audio_duration if audio_duration > 0 else slide.get("duration", 4.0)
	
	# Обновляем длительность в слайде для кинематографического эффекта
	slide["duration"] = duration
	
	# Запускаем fade in с кинематографическим эффектом (асинхронно)
	# is_transitioning будет установлен внутри _fade_in_slide() и сброшен после анимации
	_fade_in_slide()
	
	# Запускаем таймер для следующего слайда
	slide_timer.start(duration)

func _load_slide_image(path: String) -> Texture2D:
	"""Загружает изображение слайда, возвращает null если не найдено"""
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

func _fade_in_slide():
	"""Анимация появления слайда с кинематографическим эффектом"""
	# Останавливаем предыдущие твины если есть
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	
	# Получаем эффект текущего слайда
	var slide = slides[current_slide]
	var effect = slide.get("effect", CinematicEffect.NONE)
	
	# Fade in изображения + кинематографический эффект
	fade_tween = create_tween().set_parallel(true)  # Параллельное выполнение анимаций
	fade_tween.tween_property(image_display, "modulate:a", 1.0, 1.0).from(0.0)
	
	# Применяем кинематографический эффект
	_apply_cinematic_effect(fade_tween, effect, slide.get("duration", 4.0))
	

func _apply_cinematic_effect(tween: Tween, effect: CinematicEffect, duration: float):
	"""Применяет кинематографический эффект к изображению"""
	# Сбрасываем трансформации перед применением нового эффекта
	image_display.scale = Vector2.ONE
	image_display.position = Vector2.ZERO
	
	match effect:
		CinematicEffect.ZOOM_IN:
			# Плавное приближение (от 100% до 120%)
			tween.tween_property(image_display, "scale", Vector2(1.2, 1.2), duration).from(Vector2.ONE)
		
		CinematicEffect.ZOOM_OUT:
			# Плавное отдаление (от 120% до 100%)
			tween.tween_property(image_display, "scale", Vector2.ONE, duration).from(Vector2(1.2, 1.2))
		
		CinematicEffect.PAN_LEFT:
			# Панорама влево + легкий zoom чтобы не было черных полос
			image_display.scale = Vector2(1.15, 1.15)  # Увеличиваем базовый масштаб
			tween.tween_property(image_display, "position:x", 80.0, duration).from(-80.0)
		
		CinematicEffect.PAN_RIGHT:
			# Панорама вправо + легкий zoom чтобы не было черных полос
			image_display.scale = Vector2(1.15, 1.15)  # Увеличиваем базовый масштаб
			tween.tween_property(image_display, "position:x", -80.0, duration).from(80.0)
		
		CinematicEffect.PAN_UP:
			# Панорама вверх + легкий zoom чтобы не было черных полос
			image_display.scale = Vector2(1.15, 1.15)  # Увеличиваем базовый масштаб
			tween.tween_property(image_display, "position:y", 40.0, duration).from(-40.0)
		
		CinematicEffect.PAN_DOWN:
			# Панорама вниз + легкий zoom чтобы не было черных полос
			image_display.scale = Vector2(1.15, 1.15)  # Увеличиваем базовый масштаб
			tween.tween_property(image_display, "position:y", -40.0, duration).from(40.0)

func _fade_out_slide():
	"""Анимация исчезновения слайда"""
	is_transitioning = true
	
	# Останавливаем предыдущие твины
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	
	# Fade out изображения
	fade_tween = create_tween()
	fade_tween.tween_property(image_display, "modulate:a", 0.0, 0.8)
	
	await fade_tween.finished
	
	# Сбрасываем трансформации после fade out
	image_display.scale = Vector2.ONE
	image_display.position = Vector2.ZERO
	
	# ВАЖНО: Сбрасываем флаг перехода
	is_transitioning = false

func _on_slide_timeout():
	"""Обработчик окончания времени показа слайда"""
	_next_slide()

func _next_slide():
	"""Переход к следующему слайду"""
	if is_transitioning:
		return
	
	
	# Останавливаем таймер
	if slide_timer.is_stopped() == false:
		slide_timer.stop()
	
	# Fade out текущего слайда
	await _fade_out_slide()
	
	# Показываем следующий слайд
	current_slide += 1
	_show_slide(current_slide)

func _finish_intro():
	"""Завершает показ интро и переходит к главному меню"""
	
	# НЕ сохраняем флаг - интро будет показываться каждый раз
	# IntroManager.mark_intro_as_shown()
	
	# Fade to black
	var final_fade = create_tween()
	final_fade.tween_property(fade_overlay, "modulate:a", 1.0, 1.5)
	await final_fade.finished
	
	# Переход к главному меню
	SceneTransition.change_scene("res://Scenes/MainMenu.tscn")

func _on_skip_pressed():
	"""Обработчик нажатия кнопки пропуска"""
	if not can_skip:
		return
	
	can_skip = false
	
	# НЕ сохраняем флаг - интро будет показываться каждый раз
	# IntroManager.mark_intro_as_shown()
	
	# Останавливаем все
	if slide_timer:
		slide_timer.stop()
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	
	# Быстрый переход к главному меню
	_finish_intro()

func _play_slide_audio(slide: Dictionary) -> float:
	"""Воспроизводит аудио для слайда и возвращает его длительность"""
	# Останавливаем предыдущую озвучку если есть
	if current_voice_player and is_instance_valid(current_voice_player):
		current_voice_player.stop()
		current_voice_player.queue_free()
		current_voice_player = null
	
	# Проверяем наличие аудио файла
	var audio_path = slide.get("audio", "")
	if audio_path == "" or not ResourceLoader.exists(audio_path):
		return 0.0
	
	# Загружаем и воспроизводим аудио
	var audio_stream = load(audio_path) as AudioStream
	if audio_stream:
		current_voice_player = AudioStreamPlayer.new()
		current_voice_player.stream = audio_stream
		current_voice_player.bus = "Master"
		current_voice_player.volume_db = 0.0
		add_child(current_voice_player)
		current_voice_player.play()
		
		# Получаем длительность аудио и добавляем небольшую паузу (0.5 сек)
		var duration = audio_stream.get_length() + 0.5
		return duration
	else:
		return 0.0

func _play_background_music(music_path: String = "res://Assets/Audio/Intro/intro_music.ogg"):
	"""Воспроизводит фоновую музыку для интро"""
	if not ResourceLoader.exists(music_path):
		return
	
	var music_stream = load(music_path) as AudioStream
	if music_stream:
		background_music_player = AudioStreamPlayer.new()
		background_music_player.stream = music_stream
		background_music_player.bus = "Music"
		background_music_player.volume_db = -10.0  # Тише, чтобы не заглушать голос
		add_child(background_music_player)
		background_music_player.play()

func _exit_tree():
	"""Очистка при выходе"""
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	
	# Останавливаем аудио
	if current_voice_player and is_instance_valid(current_voice_player):
		current_voice_player.stop()
		current_voice_player.queue_free()
	
	if background_music_player and is_instance_valid(background_music_player):
		background_music_player.stop()
		background_music_player.queue_free()

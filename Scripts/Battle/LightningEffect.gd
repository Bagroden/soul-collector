# res://Scripts/Battle/LightningEffect.gd
extends Sprite2D
class_name LightningEffect

## Визуальный эффект удара молнии для пассивки "Шаман бурь"
## Появляется над целью и проигрывает анимацию молнии

@export var animation_duration: float = 0.5  # Длительность анимации
@export var fade_duration: float = 0.2  # Длительность исчезновения
@export var flash_count: int = 3  # Количество вспышек
@export var scale_start: float = 1.5  # Начальный размер
@export var scale_end: float = 1.0  # Конечный размер

var animation_time: float = 0.0
var is_fading: bool = false
var fade_time: float = 0.0

func _ready():
	# Настраиваем начальные параметры
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Начинаем с увеличенного размера и полупрозрачности
	scale = Vector2(scale_start, scale_start)
	modulate = Color(1.5, 1.5, 1.8, 0.0)  # Светло-голубой оттенок, прозрачный
	
	# Запускаем анимацию появления
	_play_animation()

func setup(target_position: Vector2):
	"""Настраивает позицию молнии над целью"""
	# Размещаем молнию немного выше цели
	global_position = target_position + Vector2(0, -80)
	
	# Добавляем небольшое случайное смещение
	var random_offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
	global_position += random_offset

func _play_animation():
	"""Проигрывает анимацию молнии"""
	# Фаза 1: Быстрое появление с мерцанием
	var appear_tween = create_tween()
	appear_tween.set_parallel(true)
	
	# Плавное появление
	appear_tween.tween_property(self, "modulate:a", 1.0, 0.1)
	
	# Увеличение до нормального размера
	appear_tween.tween_property(self, "scale", Vector2(scale_end, scale_end), animation_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Ждём завершения появления
	await appear_tween.finished
	
	# Фаза 2: Мерцание
	for i in range(flash_count):
		var flash_tween = create_tween()
		# Яркая вспышка
		flash_tween.tween_property(self, "modulate", Color(2.0, 2.0, 2.5, 1.0), 0.05)
		await flash_tween.finished
		
		var dim_tween = create_tween()
		# Затухание
		dim_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.5, 0.8), 0.05)
		await dim_tween.finished
	
	# Фаза 3: Исчезновение
	var fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	fade_tween.tween_property(self, "scale", Vector2(scale_start * 1.2, scale_start * 1.2), fade_duration)
	
	await fade_tween.finished
	
	# Удаляем эффект
	queue_free()

# Альтернативная версия с AnimatedSprite2D, если у вас есть несколько кадров анимации
# Раскомментируйте и используйте эту версию, если создадите SpriteFrames ресурс

# extends AnimatedSprite2D
# class_name LightningEffect
#
# @export var animation_duration: float = 0.5
#
# func _ready():
# 	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
# 	modulate = Color(1.5, 1.5, 1.8, 0.0)
# 	
# 	if sprite_frames and sprite_frames.has_animation("lightning"):
# 		play("lightning")
# 	
# 	# Анимация появления
# 	var appear_tween = create_tween()
# 	appear_tween.tween_property(self, "modulate:a", 1.0, 0.1)
# 	
# 	# Ждём завершения анимации и удаляем
# 	await animation_finished
# 	
# 	var fade_tween = create_tween()
# 	fade_tween.tween_property(self, "modulate:a", 0.0, 0.2)
# 	await fade_tween.finished
# 	
# 	queue_free()
#
# func setup(target_position: Vector2):
# 	global_position = target_position + Vector2(0, -80)

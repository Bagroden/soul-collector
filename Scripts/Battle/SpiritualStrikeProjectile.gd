# res://Scripts/Battle/SpiritualStrikeProjectile.gd
extends AnimatedSprite2D
class_name SpiritualStrikeProjectile

## Визуальный эффект Спиритического удара
## Летит от игрока к цели по параболе

@export var speed: float = 1200.0  # Скорость полёта (быстрее обычных стрел)
@export var arc_height: float = 40.0  # Высота параболы (чуть ниже для духовной энергии)
@export var scale_pulse: float = 0.15  # Пульсация размера
@export var animation_name: String = "default"  # Имя анимации для проигрывания

var target_position: Vector2
var start_position: Vector2
var flight_time: float = 0.0
var max_flight_time: float = 1.0  # Максимальное время полёта
var initial_rotation: float = 0.0  # Начальный угол поворота к цели

func _ready():
	# Настраиваем начальные параметры
	start_position = global_position
	
	# Добавляем эффект свечения (духовная энергия - бело-голубая)
	modulate = Color(0.8, 0.9, 1.0, 1.0)  # Светло-голубой оттенок
	
	# Включаем фильтр текстур для пиксельной графики
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Ускоряем анимацию на 30%
	speed_scale = 1.3
	
	# Запускаем анимацию, если она есть
	if sprite_frames and sprite_frames.has_animation(animation_name):
		play(animation_name)

func setup(from: Vector2, to: Vector2, _index: int = 0):
	"""Настраивает параметры полёта снаряда"""
	start_position = from
	target_position = to
	global_position = from
	
	# Добавляем небольшое смещение для визуального разнообразия
	var random_offset = Vector2(randf_range(-15, 15), randf_range(-15, 15))
	target_position += random_offset
	
	# Поворачиваем снаряд в сторону цели (и сохраняем угол)
	look_at(target_position)
	initial_rotation = rotation
	
	# Рассчитываем время полёта на основе расстояния
	var distance = start_position.distance_to(target_position)
	max_flight_time = distance / speed

func _process(delta: float):
	if flight_time >= max_flight_time:
		# Достигли цели - сразу удаляем снаряд
		queue_free()
		return
	
	# Увеличиваем время полёта
	flight_time += delta
	
	# Интерполируем позицию от старта к цели
	var progress = flight_time / max_flight_time
	
	# Используем ease-out для более плавного замедления при приближении
	var eased_progress = ease(progress, -2.0)  # Ease out quad
	var linear_position = start_position.lerp(target_position, eased_progress)
	
	# Добавляем параболическую траекторию (дугу)
	# Высота дуги максимальна в середине полёта
	var arc_offset = sin(progress * PI) * arc_height
	
	# Смещаем позицию вверх (по оси Y) для создания параболы
	global_position = linear_position + Vector2(0, -arc_offset)
	
	# Поворачиваем снаряд по направлению движения (касательная к параболе)
	# Вычисляем производную параболы для правильного угла
	var arc_derivative = cos(progress * PI) * PI * arc_height / max_flight_time
	var tangent_angle = atan2((target_position.y - start_position.y) / max_flight_time - arc_derivative, 
							  (target_position.x - start_position.x) / max_flight_time)
	rotation = tangent_angle
	
	# Эффект пульсации размера (опционально, можно отключить установив scale_pulse = 0)
	if scale_pulse > 0:
		var pulse = 1.0 + sin(flight_time * 12.0) * scale_pulse
		scale = Vector2(pulse, pulse)
	
	# Эффект мерцания (изменение прозрачности) - духовная энергия светится
	var alpha_pulse = 0.85 + sin(flight_time * 18.0) * 0.15
	modulate.a = alpha_pulse


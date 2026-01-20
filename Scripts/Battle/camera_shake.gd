# res://Scripts/Battle/camera_shake.gd
extends Camera2D

var shake_amount: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var original_offset: Vector2 = Vector2.ZERO

func _ready():
	original_offset = offset

func _process(delta: float):
	if shake_timer > 0:
		shake_timer -= delta
		
		# Генерируем случайное смещение
		var shake_offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		
		offset = original_offset + shake_offset
		
		# Уменьшаем силу тряски со временем
		shake_amount = lerp(shake_amount, 0.0, delta * 5.0)
	else:
		# Возвращаем камеру в исходное положение
		offset = lerp(offset, original_offset, delta * 10.0)

func shake(duration: float = 0.3, amount: float = 10.0):
	"""Запускает эффект тряски камеры
	
	Args:
		duration: длительность тряски в секундах
		amount: сила тряски в пикселях
	"""
	shake_duration = duration
	shake_timer = duration
	shake_amount = amount
	print("Camera shake: duration=", duration, ", amount=", amount)


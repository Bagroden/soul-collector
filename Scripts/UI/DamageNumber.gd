extends Node2D
class_name DamageNumber

@export var duration: float = 4.0
@export var float_height: float = 150.0
@export var fade_start: float = 3.0

var damage_amount: int
var is_critical: bool = false
var is_miss: bool = false
var is_heal: bool = false
var damage_type: String = "physical"  # "physical", "magic", "critical"

func _ready():
	# Создаем Label для отображения урона
	var label = Label.new()
	label.name = "DamageLabel"
	label.add_theme_font_size_override("font_size", 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(label)
	
	# Настраиваем отображение
	_update_display()
	
	# Запускаем анимацию
	_start_animation()

func setup_damage(amount: int, critical: bool = false, miss: bool = false, heal: bool = false, dmg_type: String = "physical"):
	"""Настраивает отображение урона"""
	damage_amount = amount
	is_critical = critical
	is_miss = miss
	is_heal = heal
	damage_type = dmg_type
	
	# Если узел уже готов, обновляем отображение
	if is_inside_tree():
		_update_display()

func _update_display():
	"""Обновляет отображение в зависимости от типа урона"""
	var label = $DamageLabel
	if not label:
		return
	
	if is_miss:
		label.text = "ПРОМАХ!"
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_font_size_override("font_size", 20)
	elif is_heal:
		label.text = "+" + str(damage_amount)
		# Салатовый цвет для лечения
		label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.3))
		label.add_theme_font_size_override("font_size", 22)
	elif is_critical:
		label.text = str(damage_amount) + "!"
		label.add_theme_color_override("font_color", Color.RED)
		label.add_theme_font_size_override("font_size", 28)
	else:
		label.text = str(damage_amount)
		# Цвет в зависимости от типа урона
		if damage_type == "magic":
			# Голубой для магического урона
			label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		elif damage_type == "physical":
			# Оранжевый для физического урона
			label.add_theme_color_override("font_color", Color.ORANGE)
		elif damage_type == "bleeding":
			# Розовый для кровотечения
			label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.7))
		elif damage_type == "poison":
			# Зеленый для яда
			label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
		else:
			label.add_theme_color_override("font_color", Color.YELLOW)
		label.add_theme_font_size_override("font_size", 24)

func _start_animation():
	"""Запускает анимацию всплывания"""
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Анимация движения вверх
	tween.tween_property(self, "position", position + Vector2(0, -float_height), duration)
	
	# Анимация прозрачности
	tween.tween_property(self, "modulate:a", 0.0, fade_start)
	
	# Анимация масштаба для критического урона
	if is_critical:
		tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3).set_delay(0.2)
	
	# Удаляем узел после завершения анимации
	tween.tween_callback(queue_free).set_delay(duration)

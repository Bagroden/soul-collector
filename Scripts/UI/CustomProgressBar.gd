# res://Scripts/UI/CustomProgressBar.gd
extends ProgressBar

var display_mode: String = "absolute"  # "absolute" или "percentage"
var value_label: Label

func _ready():
	# Отключаем встроенное отображение процентов
	show_percentage = false
	
	# Создаем Label для отображения значений
	value_label = Label.new()
	value_label.name = "ValueLabel"
	add_child(value_label)
	
	# Настраиваем Label
	value_label.anchors_preset = Control.PRESET_FULL_RECT
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 12)
	value_label.add_theme_color_override("font_color", Color.WHITE)
	value_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	value_label.add_theme_constant_override("shadow_offset_x", 1)
	value_label.add_theme_constant_override("shadow_offset_y", 1)
	
	# Подключаемся к сигналу изменения значения
	value_changed.connect(_on_value_changed)
	_update_display()

func set_display_mode(mode: String):
	"""Устанавливает режим отображения: 'absolute' или 'percentage'"""
	display_mode = mode
	_update_display()

func _on_value_changed(_new_value: float):
	_update_display()

func _update_display():
	"""Обновляет отображение текста на шкале"""
	if not value_label:
		return
		
	if display_mode == "percentage":
		var percentage = int((value / max_value) * 100)
		value_label.text = str(percentage) + "%"
	else:
		value_label.text = str(int(value)) + " / " + str(int(max_value))

# res://Scripts/Battle/background.gd
extends Sprite2D

@export var texture_path: String = "res://Assets/background.png"

# Маппинг локаций к фонам
var location_backgrounds: Dictionary = {
	"dungeon": "res://Assets/Backgrounds/Dungeon_under_town.png",
	"forest": "res://Assets/Backgrounds/Dark_forest.png",
	"dark_forest": "res://Assets/Backgrounds/Darkforest2.png",
	"cemetery": "res://Assets/Backgrounds/Cemetery.png",  # Заброшенное кладбище - фон со скелетами
	"demon_lair": "res://Assets/Backgrounds/Demon_citadel.png",
	"sinister_swamps": "res://Assets/Backgrounds/Swampland.png",
	"test_arena": "res://Assets/Backgrounds/Dungeon_under_town.png"
}

# Маппинг локаций к фонам боссовых арен
var boss_arena_backgrounds: Dictionary = {
	"demon_lair": "res://Assets/Backgrounds/Demon_citadel_boss_arena.png"
}

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_load_texture_by_location()
	if is_instance_valid(get_viewport()):
		get_viewport().connect("size_changed", Callable(self, "_update_scale"))
	# принудительно обновляем масштаб после загрузки
	await get_tree().process_frame
	_update_scale()

func _load_texture_by_location() -> void:
	"""Загружает текстуру фона в зависимости от текущей локации"""
	# Получаем LocationManager
	var location_manager = get_node_or_null("/root/LocationManager")
	if location_manager and location_manager.current_location:
		var current_location_id = location_manager.current_location.location_id
		
		# Проверяем, это боссовая комната
		var room_generator = get_node_or_null("/root/RoomGenerator")
		var is_boss_room = false
		if room_generator:
			var current_room = room_generator.get_current_room()
			if current_room and current_room.room_type == RoomData.RoomType.BOSS:
				is_boss_room = true
		
		# Если это боссовая комната и есть специальный фон для боссовой арены
		if is_boss_room and current_location_id in boss_arena_backgrounds:
			texture_path = boss_arena_backgrounds[current_location_id]
		# Иначе используем обычный фон для локации
		elif current_location_id in location_backgrounds:
			texture_path = location_backgrounds[current_location_id]
		else:
			# Используем фон подземелья по умолчанию
			texture_path = location_backgrounds["dungeon"]
	else:
		# Если LocationManager не найден, используем фон по умолчанию
		texture_path = location_backgrounds["dungeon"]
	
	# Загружаем выбранную текстуру
	_load_texture()

func _load_texture() -> void:
	if ResourceLoader.exists(texture_path):
		var tex: Resource = load(texture_path)
		if tex is Texture2D:
			texture = tex
		else:
			push_warning("Файл не является Texture2D: %s" % texture_path)
	else:
		push_warning("Файл фона не найден: %s" % texture_path)
		# создаём плейсхолдер: пиксель-арт шахматный узор с градиентом неба
		var img := _make_placeholder_image(320, 180)
		var itex := ImageTexture.create_from_image(img)
		texture = itex

func _update_scale() -> void:
	if texture == null:
		return
	var vp_size: Vector2i = get_viewport_rect().size
	var tex_size: Vector2i = texture.get_size()
	if tex_size.x == 0 or tex_size.y == 0:
		return
	
	# Растягиваем фон на весь экран
	var scale_x: float = float(vp_size.x) / float(tex_size.x)
	var scale_y: float = float(vp_size.y) / float(tex_size.y)
	scale = Vector2(scale_x, scale_y)
	
	# Позиционируем внизу справа
	# Сдвигаем на половину размера экрана вниз и вправо
	position = Vector2(
		vp_size.x * 0.5,  # половина экрана вправо
		vp_size.y * 0.5   # половина экрана вниз
	)

func _make_placeholder_image(w: int, h: int) -> Image:
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	# небо: вертикальный градиент от тёмно-синего к светлому
	for y in range(h):
		var t: float = float(y) / float(h - 1)
		var r: float = lerp(20.0, 135.0, t)
		var g: float = lerp(40.0, 206.0, t)
		var b: float = lerp(82.0, 235.0, t)
		var sky_col := Color(r/255.0, g/255.0, b/255.0, 1.0)
		for x in range(w):
			img.set_pixel(x, y, sky_col)
	# земля: нижняя треть с шахматным узором
	var ground_top := int(h * 0.66)
	for y in range(ground_top, h):
		for x in range(w):
			var checker := ((int(x / 4.0) + int(y / 4.0)) % 2) == 0
			var base_col := Color(0.35, 0.25, 0.18, 1.0)
			var alt_col := Color(0.30, 0.22, 0.16, 1.0)
			img.set_pixel(x, y, base_col if checker else alt_col)
	return img

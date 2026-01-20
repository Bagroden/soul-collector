# res://Scripts/Utils/CreateMapPOI.gd
# Скрипт для создания SpriteFrames ресурсов для точек интереса на карте
# Запустите этот скрипт один раз в Godot (через консоль или как автоскрипт)

extends EditorScript

func _run():
	print("Создаю SpriteFrames ресурсы для MapPOI...")
	
	var poi_names = ["DungeonPOI", "DarkForestPOI", "CemeteryPOI", "SoulWellPOI"]
	var base_path = "res://Assets/Sprites/MapPOI/"
	
	# Создаем директорию, если её нет
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("Assets/Sprites/MapPOI"):
		dir.make_dir_recursive("Assets/Sprites/MapPOI")
		print("Создана директория: Assets/Sprites/MapPOI")
	
	for poi_name in poi_names:
		var sprite_frames = SpriteFrames.new()
		
		# Добавляем пустую анимацию idle
		sprite_frames.add_animation("idle")
		sprite_frames.set_animation_loop("idle", true)
		sprite_frames.set_animation_speed("idle", 8.0)
		
		# Сохраняем ресурс
		var file_path = base_path + poi_name + ".tres"
		var error = ResourceSaver.save(sprite_frames, file_path)
		
		if error == OK:
			print("✅ Создан файл: ", file_path)
		else:
			print("❌ Ошибка при создании файла: ", file_path, " (код ошибки: ", error, ")")
	
	print("Готово! Теперь откройте файлы в Godot и добавьте спрайты.")


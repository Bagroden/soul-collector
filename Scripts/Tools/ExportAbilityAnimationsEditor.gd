# res://Scripts/Tools/ExportAbilityAnimationsEditor.gd
# EditorScript для экспорта анимаций способностей из PlayerBody в универсальный ресурс
# Запускается через: Tools → Run Script → выбрать этот файл

@tool
extends EditorScript

const PLAYER_BODY_SCENE_PATH = "res://Scenes/Battle/PlayerBody.tscn"
const OUTPUT_SPRITEFRAMES_PATH = "res://Data/AbilityEffectAnimations.tres"

# Список анимаций способностей, которые нужно экспортировать
const ABILITY_ANIMATIONS = [
	"acid_blast_anim",
	"bat_swoop_anim",
	"crossbow_shot_anim",
	"crushing_hammer_anim",
	"double_strike_anim",
	"kinetic_strike_anim",
	"poison_strike_anim",
	"rat_bite_anim",
	"rending_claws_anim",
	"shadow_spikes_anim",
	"slashing_strike_anim",
	"spiritual_strike_anim",
	"tombstone_anim"
]

func _run():
	print("==================================================")
	print("Экспорт анимаций способностей из PlayerBody")
	print("==================================================")
	
	# Загружаем сцену игрока
	var player_scene = load(PLAYER_BODY_SCENE_PATH) as PackedScene
	if not player_scene:
		print("❌ Ошибка: Не удалось загрузить сцену игрока: ", PLAYER_BODY_SCENE_PATH)
		return
	
	# Создаем экземпляр сцены
	var player_instance = player_scene.instantiate()
	if not player_instance:
		print("❌ Ошибка: Не удалось создать экземпляр сцены игрока")
		return
	
	# Находим узел Visual
	var visual_node = player_instance.get_node_or_null("Visual")
	if not visual_node:
		print("❌ Ошибка: Узел Visual не найден в сцене игрока")
		player_instance.queue_free()
		return
	
	var source_spriteframes = visual_node.sprite_frames
	if not source_spriteframes:
		print("❌ Ошибка: SpriteFrames не найден в узле Visual")
		player_instance.queue_free()
		return
	
	# Создаем новый SpriteFrames для эффектов способностей
	var effect_spriteframes = SpriteFrames.new()
	
	# Копируем нужные анимации
	var exported_count = 0
	var missing_animations = []
	
	for anim_name in ABILITY_ANIMATIONS:
		if source_spriteframes.has_animation(anim_name):
			# Создаем новую анимацию
			effect_spriteframes.add_animation(anim_name)
			
			# Копируем настройки анимации
			var anim_speed = source_spriteframes.get_animation_speed(anim_name)
			var anim_loop = source_spriteframes.get_animation_loop(anim_name)
			effect_spriteframes.set_animation_speed(anim_name, anim_speed)
			effect_spriteframes.set_animation_loop(anim_name, anim_loop)
			
			# Копируем кадры
			var frame_count = source_spriteframes.get_frame_count(anim_name)
			for i in range(frame_count):
				var texture = source_spriteframes.get_frame_texture(anim_name, i)
				var duration = source_spriteframes.get_frame_duration(anim_name, i)
				effect_spriteframes.add_frame(anim_name, texture, duration)
			
			exported_count += 1
			print("✅ Экспортирована анимация: ", anim_name, " (", frame_count, " кадров)")
		else:
			missing_animations.append(anim_name)
			print("⚠️  Предупреждение: Анимация '", anim_name, "' не найдена в SpriteFrames игрока")
	
	# Сохраняем ресурс
	var dir = OUTPUT_SPRITEFRAMES_PATH.get_base_dir()
	var dir_access = DirAccess.open("res://")
	if not dir_access:
		print("❌ Ошибка: Не удалось открыть доступ к файловой системе")
		player_instance.queue_free()
		return
	
	if not dir_access.dir_exists(dir.trim_prefix("res://")):
		dir_access.make_dir_recursive(dir.trim_prefix("res://"))
		print("📁 Создана директория: ", dir)
	
	var error = ResourceSaver.save(effect_spriteframes, OUTPUT_SPRITEFRAMES_PATH)
	if error == OK:
		print("==================================================")
		print("✅ Успешно экспортировано ", exported_count, " анимаций")
		print("📁 Файл сохранен: ", OUTPUT_SPRITEFRAMES_PATH)
		if missing_animations.size() > 0:
			print("⚠️  Отсутствующие анимации (", missing_animations.size(), "):")
			for anim in missing_animations:
				print("   - ", anim)
		print("==================================================")
	else:
		print("❌ Ошибка при сохранении ресурса: ", error)
	
	player_instance.queue_free()

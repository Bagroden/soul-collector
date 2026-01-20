# res://Scripts/Tools/ExportAbilityAnimations.gd
# Утилита для экспорта анимаций способностей из PlayerBody в универсальный ресурс
# Запускать вручную через консоль: var exporter = preload("res://Scripts/Tools/ExportAbilityAnimations.gd").new(); exporter.export_ability_animations()

extends RefCounted

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

func export_ability_animations() -> void:
	print("Начинаем экспорт анимаций способностей...")
	
	# Загружаем сцену игрока
	var player_scene = load(PLAYER_BODY_SCENE_PATH) as PackedScene
	if not player_scene:
		print("Ошибка: Не удалось загрузить сцену игрока: ", PLAYER_BODY_SCENE_PATH)
		return
	
	# Создаем экземпляр сцены
	var player_instance = player_scene.instantiate()
	if not player_instance:
		print("Ошибка: Не удалось создать экземпляр сцены игрока")
		return
	
	# Находим узел Visual
	var visual_node = player_instance.get_node_or_null("Visual")
	if not visual_node:
		print("Ошибка: Узел Visual не найден в сцене игрока")
		player_instance.queue_free()
		return
	
	var source_spriteframes = visual_node.sprite_frames
	if not source_spriteframes:
		print("Ошибка: SpriteFrames не найден в узле Visual")
		player_instance.queue_free()
		return
	
	# Создаем новый SpriteFrames для эффектов способностей
	var effect_spriteframes = SpriteFrames.new()
	
	# Копируем нужные анимации
	var exported_count = 0
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
			print("Экспортирована анимация: ", anim_name)
		else:
			print("Предупреждение: Анимация '", anim_name, "' не найдена в SpriteFrames игрока")
	
	# Сохраняем ресурс
	var dir = OUTPUT_SPRITEFRAMES_PATH.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	
	var error = ResourceSaver.save(effect_spriteframes, OUTPUT_SPRITEFRAMES_PATH)
	if error == OK:
		print("Успешно экспортировано ", exported_count, " анимаций в ", OUTPUT_SPRITEFRAMES_PATH)
	else:
		print("Ошибка при сохранении ресурса: ", error)
	
	player_instance.queue_free()

# res://Scripts/Battle/character_visual.gd
extends AnimatedSprite2D

@export var frames_resource: SpriteFrames
@export var idle_anim: StringName = "idle"
@export var attack_anim: StringName = "attack"
@export var hurt_anim: StringName = "hurt"
@export var die_anim: StringName = "die"

func _ready() -> void:
	if frames_resource != null:
		sprite_frames = frames_resource
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if has_animation(idle_anim):
		play(idle_anim)

func has_animation(anim_name: StringName) -> bool:
	return sprite_frames != null and sprite_frames.has_animation(String(anim_name))

func play_idle() -> void:
	if has_animation(idle_anim):
		play(idle_anim)

func play_attack() -> void:
	# Воспроизводим звук атаки для разных врагов
	var parent = get_parent()
	if parent and "display_name" in parent:
		var enemy_name = parent.display_name
		var sound_manager = get_node_or_null("/root/SoundManager")
		if sound_manager:
			# Звук атаки для летучей мыши
			if enemy_name == "Летучая мышь" or enemy_name.begins_with("Летучая мышь"):
				sound_manager.play_sound("bat_attack_anim", -5.0)
	
	if has_animation(attack_anim):
		play(attack_anim)
		# Автоматически возвращаемся к idle после анимации, только если враг еще жив
		await animation_finished
		if parent and "hp" in parent:
			if parent.hp > 0:
				play_idle()
			# Если враг мертв, не возвращаемся к idle

func play_hurt() -> void:
	# Воспроизводим звук получения урона для разных врагов (до проверки анимации)
	var parent = get_parent()
	if parent and "display_name" in parent:
		var enemy_name = parent.display_name
		var sound_manager = get_node_or_null("/root/SoundManager")
		if sound_manager:
			# Звук боли для крысы
			if enemy_name == "Крыса" or enemy_name.begins_with("Крыса"):
				sound_manager.play_sound("rat_pain", -5.0)
			# Звук боли для летучей мыши
			elif enemy_name == "Летучая мышь" or enemy_name.begins_with("Летучая мышь"):
				sound_manager.play_sound("bat_hurt", -5.0)
	
	# Проигрываем анимацию hurt, если она есть
	if has_animation(hurt_anim):
		play(hurt_anim)
		# Автоматически возвращаемся к idle после анимации, только если враг еще жив
		await animation_finished
		# Проверяем, жив ли враг перед возвратом к idle
		if parent and "hp" in parent:
			if parent.hp > 0:
				play_idle()
			# Если враг мертв, не возвращаемся к idle - остаемся в текущей анимации

func play_attack_and_wait() -> void:
	if has_animation(attack_anim):
		play(attack_anim)
		await animation_finished
	var parent = get_parent()
	if parent and "hp" in parent:
		if parent.hp > 0:
			play_idle()

func play_hurt_and_wait() -> void:
	if has_animation(hurt_anim):
		play(hurt_anim)
		await animation_finished
	var parent = get_parent()
	if parent and "hp" in parent:
		if parent.hp > 0:
			play_idle()

func play_die() -> void:
	if has_animation(die_anim):
		# Воспроизводим звук смерти для разных врагов
		var parent = get_parent()
		if parent and "display_name" in parent:
			var enemy_name = parent.display_name
			var sound_manager = get_node_or_null("/root/SoundManager")
			if sound_manager:
				# Звук смерти для крысы
				if enemy_name == "Крыса" or enemy_name.begins_with("Крыса"):
					sound_manager.play_sound("rat_die", -5.0)
				# Звук смерти для слизня
				elif enemy_name == "Слизень" or enemy_name.begins_with("Слизень") or enemy_name == "Гнилой слизень":
					sound_manager.play_sound("slime_die", -5.0)
				# Звук смерти для летучей мыши
				elif enemy_name == "Летучая мышь" or enemy_name.begins_with("Летучая мышь"):
					sound_manager.play_sound("bat_die", -5.0)
		# Принудительно устанавливаем анимацию смерти
		animation = die_anim
		play(die_anim)
		# Подключаемся к сигналу завершения, только если еще не подключены
		if not animation_finished.is_connected(_on_die_animation_finished):
			animation_finished.connect(_on_die_animation_finished, CONNECT_ONE_SHOT)

func _on_die_animation_finished():
	"""Обработчик завершения анимации смерти - НЕ возвращаемся к idle"""
	var parent = get_parent()
	if parent and "hp" in parent:
		if parent.hp <= 0:
			# Враг мертв, останавливаем анимацию на последнем кадре
			stop()
			# Устанавливаем последний кадр анимации смерти
			if sprite_frames and sprite_frames.has_animation(die_anim):
				var last_frame = sprite_frames.get_frame_count(die_anim) - 1
				frame = last_frame
				animation = die_anim

func play_animation(anim_name: String) -> void:
	"""Универсальный метод для проигрывания любой анимации по имени"""
	if has_animation(anim_name):
		play(anim_name)
		# Автоматически возвращаемся к idle после анимации, только если враг жив
		await animation_finished
		var parent = get_parent()
		if parent and "hp" in parent:
			if parent.hp > 0:
				play_idle()
	else:
		# Если анимация не найдена, проигрываем обычную атаку
		print("Анимация '", anim_name, "' не найдена, проигрываем стандартную атаку")
		play_attack()

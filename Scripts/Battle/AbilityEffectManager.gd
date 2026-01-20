# res://Scripts/Battle/AbilityEffectManager.gd
# Универсальный менеджер для проигрывания эффектов способностей на любых персонажах
extends Node
class_name AbilityEffectManager

## Путь к универсальному SpriteFrames ресурсу с анимациями способностей
const ABILITY_EFFECT_SPRITEFRAMES_PATH = "res://Data/AbilityEffectAnimations.tres"

var ability_effect_spriteframes: SpriteFrames
var ability_animation_manager: AbilityAnimationManager  # Ссылка на менеджер анимаций

func _ready() -> void:
	_load_ability_effect_spriteframes()

func _load_ability_effect_spriteframes() -> void:
	# Пытаемся загрузить существующий ресурс
	if ResourceLoader.exists(ABILITY_EFFECT_SPRITEFRAMES_PATH):
		ability_effect_spriteframes = load(ABILITY_EFFECT_SPRITEFRAMES_PATH) as SpriteFrames
		if ability_effect_spriteframes == null:
			print("Предупреждение: Ресурс по пути ", ABILITY_EFFECT_SPRITEFRAMES_PATH, " не является SpriteFrames. Выполняем автоматический экспорт.")
			_auto_export_animations()
		else:
			var anim_count = ability_effect_spriteframes.get_animation_names().size()
			print("DEBUG: Универсальный SpriteFrames с анимациями способностей загружен. Анимаций: ", anim_count)
			# Если файл существует, но пустой (нет анимаций), выполняем автоматический экспорт
			if anim_count == 0:
				print("Файл существует, но пустой. Выполняем автоматический экспорт анимаций...")
				_auto_export_animations()
	else:
		# Если ресурс не существует, выполняем автоматический экспорт
		print("Ресурс анимаций способностей не найден. Выполняем автоматический экспорт...")
		_auto_export_animations()

func _save_ability_effect_spriteframes() -> void:
	if ability_effect_spriteframes:
		var dir = ABILITY_EFFECT_SPRITEFRAMES_PATH.get_base_dir()
		if not DirAccess.dir_exists_absolute(dir):
			DirAccess.make_dir_recursive_absolute(dir)
		ResourceSaver.save(ability_effect_spriteframes, ABILITY_EFFECT_SPRITEFRAMES_PATH)
		print("Универсальный SpriteFrames с анимациями способностей сохранен в: ", ABILITY_EFFECT_SPRITEFRAMES_PATH)

## Автоматический экспорт анимаций из PlayerBody
func _auto_export_animations() -> void:
	print("==================================================")
	print("Автоматический экспорт анимаций способностей...")
	print("==================================================")
	
	# Используем существующий скрипт экспорта
	var exporter_script = load("res://Scripts/Tools/ExportAbilityAnimations.gd")
	if exporter_script:
		var exporter = exporter_script.new()
		exporter.export_ability_animations()
		# Перезагружаем ресурс после экспорта
		if ResourceLoader.exists(ABILITY_EFFECT_SPRITEFRAMES_PATH):
			ability_effect_spriteframes = load(ABILITY_EFFECT_SPRITEFRAMES_PATH) as SpriteFrames
			if ability_effect_spriteframes:
				print("✅ Автоматический экспорт завершен. Загружено анимаций: ", ability_effect_spriteframes.get_animation_names().size())
			else:
				print("⚠️  Экспорт выполнен, но не удалось загрузить ресурс. Создаем пустой.")
				ability_effect_spriteframes = SpriteFrames.new()
				_save_ability_effect_spriteframes()
		else:
			print("⚠️  Экспорт не создал файл. Создаем пустой ресурс.")
			ability_effect_spriteframes = SpriteFrames.new()
			_save_ability_effect_spriteframes()
	else:
		print("⚠️  Не удалось загрузить скрипт экспорта. Создаем пустой ресурс.")
		ability_effect_spriteframes = SpriteFrames.new()
		_save_ability_effect_spriteframes()

## Проверить, есть ли анимация для способности
func has_animation_for_ability(ability_id: String) -> bool:
	if not ability_effect_spriteframes:
		return false
	
	var animation_name = _get_animation_name_for_ability(ability_id)
	if animation_name == "":
		return false
	
	return ability_effect_spriteframes.has_animation(animation_name)

## Установить ссылку на AbilityAnimationManager
func set_animation_manager(manager: AbilityAnimationManager) -> void:
	ability_animation_manager = manager
	print("DEBUG AbilityEffectManager: ability_animation_manager установлен: ", manager.name if manager else "null")

## Получить имя анимации для способности из AbilityAnimationData
func _get_animation_name_for_ability(ability_id: String) -> String:
	print("DEBUG AbilityEffectManager: _get_animation_name_for_ability вызван для ability_id='", ability_id, "'")
	
	# Используем сохраненную ссылку на менеджер
	if ability_animation_manager and ability_animation_manager.has_method("get_animation_for_ability"):
		var anim_name = ability_animation_manager.get_animation_for_ability(ability_id)
		print("DEBUG AbilityEffectManager: animation_name из сохраненной ссылки = '", anim_name, "'")
		return anim_name
	
	# Fallback: пытаемся найти AbilityAnimationManager как брата (оба дочерние узлы BattleManager)
	var parent = get_parent()
	print("DEBUG AbilityEffectManager: parent = ", parent.name if parent else "null")
	
	if parent:
		# Ищем как брата (оба дочерние узлы одного родителя)
		var animation_manager = parent.get_node_or_null("AbilityAnimationManager")
		print("DEBUG AbilityEffectManager: animation_manager из parent (как брат) = ", animation_manager.name if animation_manager else "null")
		if animation_manager and animation_manager.has_method("get_animation_for_ability"):
			var anim_name = animation_manager.get_animation_for_ability(ability_id)
			print("DEBUG AbilityEffectManager: animation_name из parent = '", anim_name, "'")
			# Сохраняем ссылку для будущих вызовов
			ability_animation_manager = animation_manager
			return anim_name
		else:
			# Если не найден как брат, пробуем найти через get_tree()
			print("DEBUG AbilityEffectManager: Пробуем найти через get_tree()...")
			var scene_root = get_tree().current_scene
			if scene_root:
				animation_manager = scene_root.get_node_or_null("AbilityAnimationManager")
				print("DEBUG AbilityEffectManager: animation_manager из current_scene = ", animation_manager.name if animation_manager else "null")
				if animation_manager and animation_manager.has_method("get_animation_for_ability"):
					var anim_name = animation_manager.get_animation_for_ability(ability_id)
					print("DEBUG AbilityEffectManager: animation_name из current_scene = '", anim_name, "'")
					# Сохраняем ссылку для будущих вызовов
					ability_animation_manager = animation_manager
					return anim_name
	
	# Fallback: пытаемся найти через абсолютный путь
	var animation_manager = get_node_or_null("/root/BattleManager/AbilityAnimationManager")
	if not animation_manager:
		# Пробуем найти через get_tree().root
		var root = get_tree().root
		if root:
			animation_manager = root.get_node_or_null("BattleManager/AbilityAnimationManager")
	
	print("DEBUG AbilityEffectManager: animation_manager из fallback = ", animation_manager.name if animation_manager else "null")
	if animation_manager and animation_manager.has_method("get_animation_for_ability"):
		var anim_name = animation_manager.get_animation_for_ability(ability_id)
		print("DEBUG AbilityEffectManager: animation_name из fallback = '", anim_name, "'")
		# Сохраняем ссылку для будущих вызовов
		ability_animation_manager = animation_manager
		return anim_name
	
	print("ОШИБКА: AbilityAnimationManager не найден!")
	return ""

## Проиграть эффект способности на цели
## target: Node2D - персонаж, на котором проигрывается эффект
## ability_id: String - ID способности
## position_offset: Vector2 - смещение позиции эффекта относительно цели (по умолчанию Vector2.ZERO)
## scale: Vector2 - масштаб эффекта (по умолчанию Vector2(2, 2))
## z_index: int - z-index эффекта (по умолчанию 100)
## parent_node: Node - родительский узел для эффекта (по умолчанию null, будет использован GameWorld)
## Возвращает: AnimatedSprite2D - созданный узел эффекта или null, если эффект не найден
func play_ability_effect_on_target(
	target: Node2D, 
	ability_id: String, 
	position_offset: Vector2 = Vector2.ZERO,
	scale: Vector2 = Vector2(2, 2),
	z_index: int = 100,
	parent_node: Node = null
) -> AnimatedSprite2D:
	print("DEBUG AbilityEffectManager: play_ability_effect_on_target вызван для ability_id='", ability_id, "'")
	
	if not ability_effect_spriteframes:
		print("ОШИБКА: ability_effect_spriteframes не загружен!")
		return null
	
	print("DEBUG AbilityEffectManager: ability_effect_spriteframes загружен, анимаций: ", ability_effect_spriteframes.get_animation_names().size())
	print("DEBUG AbilityEffectManager: Доступные анимации: ", ability_effect_spriteframes.get_animation_names())
	
	if not target:
		print("ОШИБКА: target is null!")
		return null
	
	print("DEBUG AbilityEffectManager: target найден: ", target.name)
	
	var animation_name = _get_animation_name_for_ability(ability_id)
	print("DEBUG AbilityEffectManager: animation_name для '", ability_id, "' = '", animation_name, "'")
	
	if animation_name == "":
		print("ОШИБКА: Анимация для способности '", ability_id, "' не найдена в маппинге!")
		return null
	
	if not ability_effect_spriteframes.has_animation(animation_name):
		print("ОШИБКА: Анимация '", animation_name, "' не найдена в SpriteFrames!")
		print("DEBUG AbilityEffectManager: Доступные анимации: ", ability_effect_spriteframes.get_animation_names())
		return null
	
	print("DEBUG AbilityEffectManager: Анимация '", animation_name, "' найдена в SpriteFrames")
	
	# Получаем позицию цели
	var target_visual = target.get_node_or_null("Visual")
	var effect_position = target.global_position
	if target_visual:
		effect_position = target_visual.global_position
	effect_position += position_offset
	
	print("DEBUG AbilityEffectManager: effect_position = ", effect_position)
	
	# Создаем временный узел для эффекта
	var temp_effect = AnimatedSprite2D.new()
	temp_effect.name = "TempAbilityEffect_" + ability_id
	temp_effect.sprite_frames = ability_effect_spriteframes
	temp_effect.z_index = z_index
	temp_effect.scale = scale
	temp_effect.global_position = effect_position
	
	print("DEBUG AbilityEffectManager: Создан временный узел эффекта: ", temp_effect.name)
	print("DEBUG AbilityEffectManager: z_index = ", z_index, ", scale = ", scale)
	
	# Определяем родительский узел
	if parent_node:
		print("DEBUG AbilityEffectManager: Используем переданный parent_node: ", parent_node.name)
		parent_node.add_child(temp_effect)
	else:
		# Пытаемся найти GameWorld
		var game_world = get_node_or_null("/root/BattleManager/GameWorld")
		if game_world:
			print("DEBUG AbilityEffectManager: Добавляем эффект в GameWorld: ", game_world.name)
			game_world.add_child(temp_effect)
		else:
			# Fallback: добавляем к цели
			print("DEBUG AbilityEffectManager: Fallback - добавляем эффект к цели: ", target.name)
			target.add_child(temp_effect)
			temp_effect.position = Vector2.ZERO
	
	print("DEBUG AbilityEffectManager: Узел эффекта добавлен в дерево сцены")
	print("DEBUG AbilityEffectManager: Родитель узла: ", temp_effect.get_parent().name if temp_effect.get_parent() else "null")
	
	# Проигрываем анимацию
	print("DEBUG AbilityEffectManager: Запускаем анимацию '", animation_name, "'")
	temp_effect.play(animation_name)
	
	# Автоматически удаляем узел после завершения анимации
	temp_effect.animation_finished.connect(_on_effect_animation_finished.bind(temp_effect), CONNECT_ONE_SHOT)
	
	print("DEBUG AbilityEffectManager: Эффект '", animation_name, "' для способности '", ability_id, "' успешно запущен на цели")
	return temp_effect

## Проиграть эффект способности на источнике (атакующем)
## caster: Node2D - персонаж, который использует способность
## ability_id: String - ID способности
## Возвращает: bool - true, если эффект был проигран, false если использована fallback анимация
func play_ability_effect_on_caster(caster: Node2D, ability_id: String) -> bool:
	if not caster:
		return false
	
	var visual_node = caster.get_node_or_null("Visual")
	if not visual_node:
		return false
	
	# Сначала проверяем, есть ли анимация в универсальном SpriteFrames
	if has_animation_for_ability(ability_id):
		var animation_name = _get_animation_name_for_ability(ability_id)
		
		# Создаем временный узел эффекта поверх кастера
		var temp_effect = AnimatedSprite2D.new()
		temp_effect.name = "TempCasterEffect_" + ability_id
		temp_effect.sprite_frames = ability_effect_spriteframes
		temp_effect.z_index = 50  # Поверх кастера, но ниже эффектов на цели
		temp_effect.scale = visual_node.scale
		
		# Позиционируем относительно Visual узла кастера
		if visual_node:
			temp_effect.global_position = visual_node.global_position
			visual_node.get_parent().add_child(temp_effect)
		else:
			temp_effect.global_position = caster.global_position
			caster.add_child(temp_effect)
		
		# Проигрываем анимацию
		temp_effect.play(animation_name)
		
		# Автоматически удаляем узел после завершения анимации
		temp_effect.animation_finished.connect(_on_effect_animation_finished.bind(temp_effect), CONNECT_ONE_SHOT)
		
		print("DEBUG: Проигрываем эффект '", animation_name, "' для способности '", ability_id, "' на кастере")
		return true
	
	# Fallback: используем стандартную атаку
	if visual_node.has_method("play_attack"):
		visual_node.play_attack()
		return false
	
	return false

## Обработчик завершения анимации эффекта
func _on_effect_animation_finished(effect_node: AnimatedSprite2D) -> void:
	if effect_node and is_instance_valid(effect_node):
		effect_node.queue_free()

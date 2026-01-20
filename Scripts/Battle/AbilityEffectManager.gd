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
			_auto_export_animations()
		else:
			var anim_count = ability_effect_spriteframes.get_animation_names().size()
			# Если файл существует, но пустой (нет анимаций), выполняем автоматический экспорт
			if anim_count == 0:
				_auto_export_animations()
	else:
		# Если ресурс не существует, выполняем автоматический экспорт
		_auto_export_animations()

func _save_ability_effect_spriteframes() -> void:
	if ability_effect_spriteframes:
		var dir = ABILITY_EFFECT_SPRITEFRAMES_PATH.get_base_dir()
		if not DirAccess.dir_exists_absolute(dir):
			DirAccess.make_dir_recursive_absolute(dir)
		ResourceSaver.save(ability_effect_spriteframes, ABILITY_EFFECT_SPRITEFRAMES_PATH)

## Автоматический экспорт анимаций из PlayerBody
func _auto_export_animations() -> void:
	# Используем существующий скрипт экспорта
	var exporter_script = load("res://Scripts/Tools/ExportAbilityAnimations.gd")
	if exporter_script:
		var exporter = exporter_script.new()
		exporter.export_ability_animations()
		# Перезагружаем ресурс после экспорта
		if ResourceLoader.exists(ABILITY_EFFECT_SPRITEFRAMES_PATH):
			ability_effect_spriteframes = load(ABILITY_EFFECT_SPRITEFRAMES_PATH) as SpriteFrames
			if not ability_effect_spriteframes:
				ability_effect_spriteframes = SpriteFrames.new()
				_save_ability_effect_spriteframes()
		else:
			ability_effect_spriteframes = SpriteFrames.new()
			_save_ability_effect_spriteframes()
	else:
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

## Получить имя анимации для способности из AbilityAnimationData
func _get_animation_name_for_ability(ability_id: String) -> String:
	# Используем сохраненную ссылку на менеджер
	if ability_animation_manager and ability_animation_manager.has_method("get_animation_for_ability"):
		return ability_animation_manager.get_animation_for_ability(ability_id)
	
	# Fallback: пытаемся найти AbilityAnimationManager как брата (оба дочерние узлы BattleManager)
	var parent = get_parent()
	if parent:
		# Ищем как брата (оба дочерние узлы одного родителя)
		var animation_manager = parent.get_node_or_null("AbilityAnimationManager")
		if animation_manager and animation_manager.has_method("get_animation_for_ability"):
			# Сохраняем ссылку для будущих вызовов
			ability_animation_manager = animation_manager
			return animation_manager.get_animation_for_ability(ability_id)
		else:
			# Если не найден как брат, пробуем найти через get_tree()
			var scene_root = get_tree().current_scene
			if scene_root:
				animation_manager = scene_root.get_node_or_null("AbilityAnimationManager")
				if animation_manager and animation_manager.has_method("get_animation_for_ability"):
					# Сохраняем ссылку для будущих вызовов
					ability_animation_manager = animation_manager
					return animation_manager.get_animation_for_ability(ability_id)
	
	# Fallback: пытаемся найти через абсолютный путь
	var animation_manager = get_node_or_null("/root/BattleManager/AbilityAnimationManager")
	if not animation_manager:
		# Пробуем найти через get_tree().root
		var root = get_tree().root
		if root:
			animation_manager = root.get_node_or_null("BattleManager/AbilityAnimationManager")
	
	if animation_manager and animation_manager.has_method("get_animation_for_ability"):
		# Сохраняем ссылку для будущих вызовов
		ability_animation_manager = animation_manager
		return animation_manager.get_animation_for_ability(ability_id)
	
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
	if not ability_effect_spriteframes or not target:
		return null
	
	var animation_name = _get_animation_name_for_ability(ability_id)
	if animation_name == "" or not ability_effect_spriteframes.has_animation(animation_name):
		return null
	
	# Получаем позицию цели
	var target_visual = target.get_node_or_null("Visual")
	var effect_position = target.global_position
	if target_visual:
		effect_position = target_visual.global_position
	effect_position += position_offset
	
	# Создаем временный узел для эффекта
	var temp_effect = AnimatedSprite2D.new()
	temp_effect.name = "TempAbilityEffect_" + ability_id
	temp_effect.sprite_frames = ability_effect_spriteframes
	temp_effect.z_index = z_index
	temp_effect.scale = scale
	temp_effect.global_position = effect_position
	
	# Определяем родительский узел
	if parent_node:
		parent_node.add_child(temp_effect)
	else:
		# Пытаемся найти GameWorld
		var game_world = get_node_or_null("/root/BattleManager/GameWorld")
		if game_world:
			game_world.add_child(temp_effect)
		else:
			# Fallback: добавляем к цели
			target.add_child(temp_effect)
			temp_effect.position = Vector2.ZERO
	
	# Проигрываем анимацию
	temp_effect.play(animation_name)
	
	# Автоматически удаляем узел после завершения анимации
	temp_effect.animation_finished.connect(_on_effect_animation_finished.bind(temp_effect), CONNECT_ONE_SHOT)
	
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

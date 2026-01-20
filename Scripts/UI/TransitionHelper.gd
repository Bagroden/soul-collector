# res://Scripts/UI/TransitionHelper.gd
extends Node

func smooth_transition_to_scene(scene_path: String, fade_duration: float = 3.0):
	"""Создает плавный переход к новой сцене"""
	var transition_manager = get_node_or_null("/root/TransitionManager")
	if transition_manager:
		transition_manager.fade_out_and_change_scene(scene_path, fade_duration)
	else:
		# Fallback - обычная смена сцены без перехода
		print("TransitionManager не найден, используем обычную смену сцены")
		get_tree().change_scene_to_file(scene_path)
	
	# Удаляем себя после создания перехода
	queue_free()

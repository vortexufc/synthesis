extends CanvasLayer

@onready var color_rect = $ColorRect

func change_scene(target_scene: String) -> void:
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, 0.3)
	await tween.finished
	get_tree().change_scene_to_file(target_scene)
	var tween_back = create_tween()
	tween_back.tween_property(color_rect, "color:a", 0.0, 0.3)

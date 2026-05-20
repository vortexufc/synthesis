extends Area2D

@export var proxima_cena: String = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and proxima_cena != "":
		get_tree().change_scene_to_file(proxima_cena)

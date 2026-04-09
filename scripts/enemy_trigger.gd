extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player": # Checa se é especificamente o player
		GlobalSignals.iniciar_batalha.emit()
		hide()
		set_deferred("monitoring", false)

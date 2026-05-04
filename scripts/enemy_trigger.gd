extends Area2D

## [Combat-4] Dados do inimigo configuráveis pelo Inspector do Godot.
## Cada guardião da Torre tem sua própria paciência e número de desafios.
@export var num_questoes: int = 5           ## Rodadas de quiz desta batalha
@export var duracao_batalha: float = 300.0  ## Segundos totais (5 min para o Golem do Andar 1)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player": # Checa se é especificamente o player
		var enemy_data: Dictionary = {
			"num_questoes": num_questoes,
			"duracao_batalha": duracao_batalha
		}
		GlobalSignals.iniciar_batalha.emit(enemy_data)
		hide()
		set_deferred("monitoring", false)

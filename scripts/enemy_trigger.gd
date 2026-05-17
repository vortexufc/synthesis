extends Area2D

## [Dev-1 / Combat-4] EnemyTrigger — Área de detecção do inimigo.
## Ao entrar, para a patrulha do inimigo-pai e emite iniciar_batalha.

# ──────────────────────────────────────────
# Dados configuráveis pelo Inspector
# ──────────────────────────────────────────
@export var num_questoes:      int   = 5      ## Rodadas de quiz desta batalha
@export var duracao_batalha:   float = 300.0  ## Segundos totais (5 min = Golem Andar 1)
@export var andar_id:          int   = 1      ## [Dev-1] Identifica o andar → QuizManager carrega Biologia

# Constantes de referência para configuração rápida via código
const GOLEM_MENOR = { "num_questoes": 3, "duracao_batalha": 300.0 }
const GOLEM_ANTIGO = { "num_questoes": 5, "duracao_batalha": 300.0 }

func _ready() -> void:
	GlobalSignals.batalha_encerrada.connect(_on_batalha_encerrada)

func _on_batalha_encerrada(vitoria: bool) -> void:
	## Reativa o trigger somente em derrota (inimigo ainda vivo)
	if not vitoria:
		show()
		set_deferred("monitoring", true)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		# [Dev-1] Monta enemy_data com andar_id para o QuizManager filtrar Biologia
		var enemy_data: Dictionary = {
			"num_questoes":    num_questoes,
			"duracao_batalha": duracao_batalha,
			"andar_id":        andar_id,        ## [Dev-1] Andar 1 → Biologia
		}

		print("[Dev-1 / Combat-5] Batalha: %d questões / %ds / Andar %d" % [
			num_questoes, int(duracao_batalha), andar_id
		])

		# [Dev-1] Para a patrulha do inimigo-pai (se este trigger for filho de um enemy.gd)
		var pai = get_parent()
		if pai and pai.has_method("_on_batalha_iniciada"):
			pai._on_batalha_iniciada(enemy_data)

		GlobalSignals.iniciar_batalha.emit(enemy_data)
		hide()
		set_deferred("monitoring", false)

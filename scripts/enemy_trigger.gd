extends Area2D

## [Dev-1 / Combat-4] EnemyTrigger — Área de detecção do inimigo.
## Ao entrar, para a patrulha do inimigo-pai e emite iniciar_batalha.

# ──────────────────────────────────────────
# Dados configuráveis pelo Inspector
# ──────────────────────────────────────────
@export var id_inimigo:        String = "slime_p"
@export var num_questoes:      int   = 5      ## Rodadas de quiz desta batalha
@export var duracao_batalha:   float = 300.0  ## Segundos totais (5 min = Golem Andar 1)
@export var andar_id:          int   = 1      ## [Dev-1] Identifica o andar → QuizManager carrega Biologia

## [Local] Questões hardcoded para este inimigo (ex: builds de teste).
## Cada item deve ter: { question, options: [], answer (índice) }
## Quando preenchido, substitui o banco de dados para este inimigo.
@export var questoes_locais: Array = []

# Constantes de referência para configuração rápida via código
const GOLEM_MENOR = { "num_questoes": 3, "duracao_batalha": 300.0 }
const GOLEM_ANTIGO = { "num_questoes": 5, "duracao_batalha": 300.0 }


func _ready() -> void:
	GlobalSignals.batalha_encerrada.connect(_on_batalha_encerrada)

var _em_batalha: bool = false

func _on_batalha_encerrada(vitoria: bool) -> void:
	if not _em_batalha:
		return # Ignora se não foi esse inimigo que batalhou

	_em_batalha = false

	if not vitoria:
		show()
		set_deferred("monitoring", true)
	else:
		# Se venceu, deleta o inimigo do mapa
		var pai = get_parent()
		if pai:
			pai.queue_free()
		else:
			queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		# Monta enemy_data com andar_id para o QuizManager filtrar o banco
		var enemy_data: Dictionary = {
			"num_questoes":    num_questoes,
			"duracao_batalha": duracao_batalha,
			"andar_id":        andar_id,
			"id_inimigo":      id_inimigo,
		}

		var node_pai = get_parent()

		# [Fix-9] Fallback inteligente do Sprite do inimigo
		if QuizManager.sprite_frames_inimigos.has(id_inimigo):
			enemy_data["sprite_frames"] = QuizManager.sprite_frames_inimigos[id_inimigo]
		else:
			if node_pai and node_pai.has_node("AnimatedSprite2D"):
				enemy_data["sprite_frames"] = node_pai.get_node("AnimatedSprite2D").sprite_frames
			elif node_pai and node_pai.has_node("sprite"):
				enemy_data["sprite_frames"] = node_pai.get_node("sprite").sprite_frames

		# [Local] Se houver questões hardcoded, injeta no enemy_data
		if questoes_locais.size() > 0:
			enemy_data["questoes_locais"] = questoes_locais
			print("[Local] Usando %d questões locais para '%s'" % [questoes_locais.size(), id_inimigo])

		print("[Combat-5] Batalha: %d questões / %ds / Andar %d" % [
			num_questoes, int(duracao_batalha), andar_id
		])

		# Para a patrulha do inimigo-pai (se este trigger for filho de um enemy.gd)
		if node_pai and node_pai.has_method("_on_batalha_iniciada"):
			node_pai._on_batalha_iniciada(enemy_data)

		_em_batalha = true # <--- MARCA ESTE INIMIGO COMO O ENGAJADO
		GlobalSignals.iniciar_batalha.emit(enemy_data)
		hide()
		set_deferred("monitoring", false)

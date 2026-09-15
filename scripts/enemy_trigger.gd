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
@export var nivel_dificuldade: int   = 0      ## [TRI] 1=Fácil, 2=Médio, 3=Difícil (0=Automático por monstro/sala)

## [Local] Questões hardcoded para este inimigo (ex: builds de teste).
## Cada item deve ter: { question, options: [], answer (índice) }
## Quando preenchido, substitui o banco de dados para este inimigo.
@export var questoes_locais: Array = []

# Constantes de referência para configuração rápida via código
const GOLEM_MENOR = { "num_questoes": 3, "duracao_batalha": 300.0 }
const GOLEM_ANTIGO = { "num_questoes": 5, "duracao_batalha": 300.0 }


func _ready() -> void:
	GlobalSignals.batalha_encerrada.connect(_on_batalha_encerrada)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	call_deferred("_garantir_alcance_trigger")

func _garantir_alcance_trigger() -> void:
	var pai = get_parent()
	if not (pai is CharacterBody2D):
		return
	var col_pai = pai.get_node_or_null("CollisionShape2D")
	var col_trigger = get_node_or_null("CollisionShape2D")
	if col_pai and col_trigger and col_trigger.shape and col_pai.shape:
		col_trigger.shape = col_trigger.shape.duplicate()
		if col_trigger.shape is CircleShape2D:
			if col_pai.shape is CircleShape2D:
				col_trigger.shape.radius = max(col_trigger.shape.radius, col_pai.shape.radius + 8.0)
		elif col_trigger.shape is CapsuleShape2D:
			if col_pai.shape is CircleShape2D:
				col_trigger.shape.radius = max(col_trigger.shape.radius, col_pai.shape.radius + 6.0)
				col_trigger.shape.height = max(col_trigger.shape.height, (col_pai.shape.radius + 6.0) * 2.0)
			elif col_pai.shape is RectangleShape2D:
				var half_size = col_pai.shape.size * 0.5
				col_trigger.shape.radius = max(col_trigger.shape.radius, half_size.y + 8.0)
				col_trigger.shape.height = max(col_trigger.shape.height, col_pai.shape.size.x + 16.0)
			elif col_pai.shape is CapsuleShape2D:
				col_trigger.shape.radius = max(col_trigger.shape.radius, col_pai.shape.radius + 6.0)
				col_trigger.shape.height = max(col_trigger.shape.height, col_pai.shape.height + 12.0)

var _em_batalha: bool = false

func _physics_process(_delta: float) -> void:
	if _em_batalha or not monitoring:
		return
	if get_node_or_null("/root/TransitionScreen") and TransitionScreen.is_transitioning:
		return
	for body in get_overlapping_bodies():
		if body.is_in_group("player") or body.name == "Player":
			_on_body_entered(body)
			return

func _on_batalha_encerrada(vitoria: bool) -> void:
	if not _em_batalha:
		return # Ignora se não foi esse inimigo que batalhou

	_em_batalha = false

	if not vitoria:
		show()
		# [Bugfix] Espera meio segundo (sem rodar no pause) antes de ativar a colisão. 
		# Isso impede que a batalha reinicie no micro-segundo em que o Game Over 
		# despausa o jogo para transitar para o Menu.
		await get_tree().create_timer(0.5, false).timeout
		if is_instance_valid(self):
			set_deferred("monitoring", true)
	else:
		# Se venceu, deleta o inimigo do mapa e registra como derrotado
		var pai = get_parent()
		if pai:
			if get_node_or_null("/root/DungeonGenerator"):
				var room_path = get_tree().current_scene.scene_file_path
				var key = room_path + "::" + pai.name
				DungeonGenerator.registrar_inimigo_derrotado(key)
			if pai.has_method("derrotar"):
				pai.derrotar()
			else:
				pai.queue_free()
		else:
			if get_node_or_null("/root/DungeonGenerator"):
				var room_path = get_tree().current_scene.scene_file_path
				var key = room_path + "::" + self.name
				DungeonGenerator.registrar_inimigo_derrotado(key)
			if has_method("derrotar"):
				call("derrotar")
			else:
				queue_free()

func _on_body_entered(body: Node2D) -> void:
	if get_node_or_null("/root/TransitionScreen") and TransitionScreen.is_transitioning:
		return
	if not (body.is_in_group("player") or body.name == "Player"):
		return
	if _em_batalha:
		return
	_em_batalha = true # <--- MARCA ESTE INIMIGO COMO O ENGAJADO

	var node_pai = get_parent()

	# Monta enemy_data com andar_id para o QuizManager filtrar o banco
	var enemy_data: Dictionary = {
		"num_questoes":      num_questoes,
		"duracao_batalha":   duracao_batalha,
		"andar_id":          andar_id,
		"id_inimigo":        id_inimigo,
		"inimigo_node":      node_pai,
		"nivel_dificuldade": nivel_dificuldade,
	}

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

	GlobalSignals.iniciar_batalha.emit(enemy_data)
	hide()
	set_deferred("monitoring", false)

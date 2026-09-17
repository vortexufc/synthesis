extends Area2D

# area de deteccao do inimigo
# quando o player entra aqui comeca a batalha

@export var id_inimigo:        String = "slime_p"
@export var num_questoes:      int   = 5
@export var duracao_batalha:   float = 300.0
@export var andar_id:          int   = 1
@export var nivel_dificuldade: int   = 0 # 1=facil, 2=medio, 3=dificil, 0=auto
@export var eh_boss: bool           = false
@export var eh_runico: bool          = false

# questoes especificas de teste caso nao queira usar o banco
@export var questoes_locais: Array = []

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

func _player_em_interacao(p_node: Node2D = null) -> bool:
	var pl = p_node
	if pl == null:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			pl = players[0]
	if pl and is_instance_valid(pl):
		if pl.has_method("esta_imune_a_combate"):
			if pl.esta_imune_a_combate():
				return true
		elif pl.has_method("esta_em_interacao"):
			if pl.esta_em_interacao():
				return true
		elif pl.get("travado") == true or pl.get("em_interacao") == true:
			return true
	if get_node_or_null("/root/QuizManager") and QuizManager.em_batalha:
		return true
	if get_node_or_null("/root/TransitionScreen") and TransitionScreen.is_transitioning:
		return true
	if get_tree():
		if get_tree().get_nodes_in_group("minigame_ativo").size() > 0:
			return true
		if get_tree().get_nodes_in_group("dialogo_ativo").size() > 0:
			return true
	return false

func _physics_process(_delta: float) -> void:
	if _em_batalha or not monitoring:
		return
	if get_node_or_null("/root/TransitionScreen") and TransitionScreen.is_transitioning:
		return
	if _player_em_interacao():
		return
	for body in get_overlapping_bodies():
		if body.is_in_group("player") or body.name == "Player":
			if _player_em_interacao(body):
				continue
			_on_body_entered(body)
			return

func _on_batalha_encerrada(vitoria: bool) -> void:
	if not _em_batalha:
		return # Ignora se não foi esse inimigo que batalhou

	_em_batalha = false

	if not vitoria:
		show()
		# espera um pouco antes de reativar pra nao reabrir a batalha no pause
		await get_tree().create_timer(0.5, false).timeout
		if is_instance_valid(self):
			set_deferred("monitoring", true)
	else:
		# se venceu, remove o monstro da sala
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
	if _player_em_interacao(body):
		return
	_em_batalha = true # <--- MARCA ESTE INIMIGO COMO O ENGAJADO

	var node_pai = get_parent()

	var eh_runico_final: bool = eh_runico
	if node_pai and "eh_runico" in node_pai and node_pai.eh_runico:
		eh_runico_final = true

	var eh_boss_final: bool = eh_boss
	var id_low = id_inimigo.to_lower()
	var scene_low = get_tree().current_scene.scene_file_path.to_lower() if get_tree().current_scene else ""
	if node_pai and "eh_boss" in node_pai and node_pai.eh_boss:
		eh_boss_final = true
	elif "boss" in id_low or "roxo" in id_low or id_low == "robo_g" or "wizard" in id_low:
		eh_boss_final = true
	elif "boss" in scene_low or "fisica12" in scene_low or "física12" in scene_low:
		eh_boss_final = true

	var vida_val: float = 100.0
	var dano_val: float = 20.0
	if node_pai:
		if "vida_maxima" in node_pai:
			vida_val = float(node_pai.vida_maxima)
		if "dano" in node_pai:
			dano_val = float(node_pai.dano)

	# Monta enemy_data com andar_id para o QuizManager filtrar o banco
	var enemy_data: Dictionary = {
		"num_questoes":      num_questoes,
		"duracao_batalha":   duracao_batalha,
		"andar_id":          andar_id,
		"id_inimigo":        id_inimigo,
		"inimigo_node":      node_pai,
		"nivel_dificuldade": nivel_dificuldade,
		"eh_runico":          eh_runico_final,
		"eh_boss":            eh_boss_final,
		"vida_maxima":        vida_val,
		"dano":               dano_val,
	}

	# pega o sprite do inimigo pro card da batalha
	if QuizManager.sprite_frames_inimigos.has(id_inimigo):
		enemy_data["sprite_frames"] = QuizManager.sprite_frames_inimigos[id_inimigo]
	else:
		if node_pai and node_pai.has_node("AnimatedSprite2D"):
			enemy_data["sprite_frames"] = node_pai.get_node("AnimatedSprite2D").sprite_frames
		elif node_pai and node_pai.has_node("sprite"):
			enemy_data["sprite_frames"] = node_pai.get_node("sprite").sprite_frames

	if questoes_locais.size() > 0:
		enemy_data["questoes_locais"] = questoes_locais

	# para o monstro de patrulhar enquanto luta
	if node_pai and node_pai.has_method("_on_batalha_iniciada"):
		node_pai._on_batalha_iniciada(enemy_data)

	GlobalSignals.iniciar_batalha.emit(enemy_data)
	hide()
	set_deferred("monitoring", false)

extends CharacterBody2D

## [Dev-1] Script do Inimigo — variáveis exportáveis + patrulha aleatória
## Move-se em direções aleatórias (8 direções) até encontrar o Player.
## Ao receber o sinal de batalha, para completamente.

signal inimigo_derrotado(pos: Vector2)

# ──────────────────────────────────────────
# Atributos do Inimigo (configuráveis pelo Inspector)
# ──────────────────────────────────────────
@export var vida_maxima:       float = 100.0  ## HP total do inimigo
@export var velocidade:        float =  55.0  ## Pixels/segundo na patrulha
@export var dano:              float =  25.0  ## Dano base por erro do jogador
@export var tempo_min_direcao: float =  0.8   ## Mínimo de segundos antes de sortear nova direção
@export var tempo_max_direcao: float =  2.2   ## Máximo de segundos antes de sortear nova direção
@export var chance_pausa:      float =  0.2   ## 0.0‒1.0 — chance de parar por um instante ao trocar direção
@export var distancia_perseguicao: float = 200.0 ## Distância máxima para começar a perseguir o Player
@export var velocidade_perseguicao: float = 75.0  ## Velocidade ao perseguir o Player

# ──────────────────────────────────────────
# Estado interno
# ──────────────────────────────────────────
var vida_atual:      float
var _em_batalha:     bool    = false
var _sou_o_combatente: bool  = false
var _em_pausa:       bool    = false
var _direcao:        Vector2 = Vector2.RIGHT  ## Direção atual da patrulha (normalizada)
var _timer_direcao:  float   = 0.0            ## Tempo restante nesta direção
var _timer_pausa:    float   = 0.0            ## Tempo de pausa (imóvel)
var _player:         Node2D  = null
var _perseguindo:    bool    = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# ── Direções possíveis (8 direções) — var pois .normalized() não é constante no GDScript 4 ──
var DIRECOES: Array = [
	Vector2(1, 0),                 # Direita
	Vector2(-1, 0),                # Esquerda
	Vector2(0, 1),                 # Baixo
	Vector2(0, -1),                # Cima
	Vector2(1, 1).normalized(),    # Diagonal 
	Vector2(-1, 1).normalized(),   # Diagonal 
	Vector2(1, -1).normalized(),   # Diagonal 
	Vector2(-1, -1).normalized(),  # Diagonal 
]

func _ready() -> void:
	# Se este inimigo já foi derrotado nesta masmorra, remove ele imediatamente
	if get_node_or_null("/root/DungeonGenerator"):
		var room_path = get_tree().current_scene.scene_file_path
		var key = room_path + "::" + self.name
		if DungeonGenerator.is_inimigo_derrotado(key):
			print("[Inimigo] Já derrotado anteriormente nesta masmorra, removendo: ", key)
			queue_free()
			return

	add_to_group("inimigos")
	vida_atual = vida_maxima
	randomize()

	# Começa já com uma direção aleatória
	_sortear_nova_direcao()

	# Escuta sinais globais de batalha
	GlobalSignals.iniciar_batalha.connect(_on_batalha_iniciada)
	GlobalSignals.batalha_encerrada.connect(_on_batalha_encerrada)

	if sprite:
		sprite.play("default")
	
	_criar_sombra()

var shadow: Sprite2D = null
var shadow_base_scale: Vector2 = Vector2(1.8, 1.2)
var tempo_anim_sombra: float = 0.0

func _criar_sombra() -> void:
	var shadow_tex = load("res://assets/sprites/Characters/Maguinho/shadow.png")
	if not shadow_tex:
		return
	
	shadow = Sprite2D.new()
	shadow.name = "Shadow"
	shadow.texture = shadow_tex
	shadow.z_index = 0
	
	if sprite and sprite.z_index == 0:
		sprite.z_index = 1
	
	var nome_baixo = name.to_lower()
	
	# Slimes não precisam de sombra pois são colados no chão
	if "slime" in nome_baixo:
		return
	
	var pos_y: float = 20.0
	
	if "robo_g" in nome_baixo:
		pos_y = 82.0
		shadow_base_scale = Vector2(1.8, 1.2)
	elif "robo_p" in nome_baixo:
		pos_y = 46.0
		shadow_base_scale = Vector2(1.9, 1.2)
	elif "evil_wizzard" in nome_baixo or "wizzard" in nome_baixo or "wizard" in nome_baixo:
		pos_y = 40.0
		shadow_base_scale = Vector2(1.85, 1.25)
	else:
		var col = get_node_or_null("CollisionShape2D")
		if col:
			pos_y = col.position.y + 12.0
		else:
			pos_y = 20.0
		shadow_base_scale = Vector2(1.8, 1.2)
	
	shadow.position = Vector2(0, pos_y)
	shadow.scale = shadow_base_scale
	
	add_child(shadow)
	move_child(shadow, 0)

func _process(delta: float) -> void:
	_animar_sombra(delta)

func _animar_sombra(delta: float) -> void:
	if not shadow or not is_instance_valid(shadow):
		return
	
	tempo_anim_sombra += delta
	if velocity.length() > 5.0:
		# Movimento / patrulha: squash & stretch suave acompanhando os passos/quiques
		var onda = sin(tempo_anim_sombra * 14.0)
		shadow.scale.x = shadow_base_scale.x + onda * (shadow_base_scale.x * 0.08)
		shadow.scale.y = shadow_base_scale.y - onda * (shadow_base_scale.y * 0.08)
	else:
		# Parado / pausa: respiração sutil
		var onda = sin(tempo_anim_sombra * 3.0)
		shadow.scale.x = shadow_base_scale.x + onda * (shadow_base_scale.x * 0.04)
		shadow.scale.y = shadow_base_scale.y + onda * (shadow_base_scale.y * 0.04)

# ──────────────────────────────────────────
# Loop de Patrulha Aleatória
# ──────────────────────────────────────────
func _physics_process(delta: float) -> void:
	# Localiza o player dinamicamente se ainda não referenciado
	if not _player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_player = players[0]

	var no_alcance: bool = false
	if _player and is_instance_valid(_player):
		var distancia = global_position.distance_to(_player.global_position)
		if distancia <= distancia_perseguicao:
			no_alcance = true

	if no_alcance:
		if not _perseguindo:
			print("[Inimigo] Jogador avistado! Iniciando perseguição.")
			_perseguindo = true
			_em_pausa = false
		
		# Define a direção apontando para o player
		_direcao = (_player.global_position - global_position).normalized()
		velocity = _direcao * velocidade_perseguicao
	else:
		if _perseguindo:
			print("[Inimigo] Jogador perdeu-se de vista. Retornando à patrulha.")
			_perseguindo = false
			_sortear_nova_direcao()
		
		# Contagem regressiva de pausa (inimigo fica parado por um instante)
		if _em_pausa:
			_timer_pausa -= delta
			if _timer_pausa <= 0.0:
				_em_pausa = false
				_sortear_nova_direcao()
			velocity = Vector2.ZERO
			move_and_slide()
			if sprite:
				sprite.play("default")
			return

		# Contagem regressiva para trocar de direção
		_timer_direcao -= delta
		if _timer_direcao <= 0.0:
			# Chance de entrar em pausa antes de sortear nova direção
			if randf() < chance_pausa:
				_em_pausa     = true
				_timer_pausa  = randf_range(0.3, 0.8)
				velocity      = Vector2.ZERO
				move_and_slide()
				return
			_sortear_nova_direcao()

		# Move na direção atual da patrulha
		velocity = _direcao * velocidade

	# Atualiza a animação dependendo da direção
	if sprite:
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("walk_side"):
			if abs(_direcao.x) > abs(_direcao.y):
				sprite.play("walk_side")
				# A arte original (Y=0) do robô está olhando para a ESQUERDA.
				# Então para andar para a direita (> 0.0), precisamos virar (flip_h = true).
				sprite.flip_h = (_direcao.x > 0.0)
			elif _direcao.y > 0:
				sprite.play("walk_down")
			elif _direcao.y < 0:
				sprite.play("walk_up")
		else:
			# Lógica antiga para inimigos simples (Slime, etc)
			if _direcao.x != 0.0:
				sprite.flip_h = (_direcao.x < 0.0)

	move_and_slide()

	# Se tocou no jogador fisicamente durante o movimento, aciona a batalha imediatamente!
	var em_transicao = get_node_or_null("/root/TransitionScreen") and TransitionScreen.is_transitioning
	if not _em_batalha and not em_transicao:
		for i in range(get_slide_collision_count()):
			var col = get_slide_collision(i)
			var collider = col.get_collider()
			if collider and (collider.is_in_group("player") or collider.name == "Player"):
				var trigger = get_node_or_null("EnemyTrigger")
				if trigger and trigger.has_method("_on_body_entered"):
					trigger._on_body_entered(collider)
					return

	# Se colidiu com parede (e não estiver perseguindo), sorteia nova direção imediatamente
	if not no_alcance and velocity.length() < 1.0 and not _em_pausa:
		_sortear_nova_direcao()

# ──────────────────────────────────────────
# Sorteia uma nova direção e reseta o timer
# ──────────────────────────────────────────
func _sortear_nova_direcao() -> void:
	_direcao       = DIRECOES[randi() % DIRECOES.size()]
	_timer_direcao = randf_range(tempo_min_direcao, tempo_max_direcao)

# ──────────────────────────────────────────
# Reação aos Sinais de Batalha
# ──────────────────────────────────────────
func _on_batalha_iniciada(enemy_data: Dictionary) -> void:
	# Compara se o node referenciado em enemy_data["inimigo_node"] é esta própria instância
	_sou_o_combatente = (enemy_data.get("inimigo_node") == self)

	## Para a patrulha imediatamente — desliga o physics process no nível do engine
	_em_batalha = true
	_em_pausa   = false
	velocity    = Vector2.ZERO
	set_physics_process(false)  # Congelamento garantido, independente do pause da árvore
	hide()                      # Esconde o inimigo enquanto a batalha ocorre
	print("[Dev-1] Inimigo pausou patrulha — batalha iniciada.")

func _on_batalha_encerrada(vitoria: bool) -> void:
	if vitoria:
		if not _sou_o_combatente:
			# Se o jogador venceu a batalha, mas não foi contra este monstro específico,
			# este monstro deve reaparecer e continuar a patrulha normalmente.
			_em_batalha = false
			show()
			set_physics_process(true)
			_sortear_nova_direcao()
			print("[Prog-08] Inimigo secundário retomou patrulha — outro inimigo foi derrotado.")
	else:
		# Se o jogador perdeu a batalha, todos os inimigos voltam a patrulhar
		_em_batalha = false
		show()                      # Volta a exibir o inimigo no mapa
		set_physics_process(true)   # Religa o movimento
		_sortear_nova_direcao()
		print("[Dev-1] Inimigo retomou patrulha aleatória — jogador derrotado.")

# ──────────────────────────────────────────
# Dano recebido (chamado pelo QuizManager via acerto do jogador)
# ──────────────────────────────────────────
func sofrer_dano(quantidade: float) -> void:
	vida_atual = max(0.0, vida_atual - quantidade)
	print("[Dev-1] Inimigo recebeu %.0f de dano. Vida: %.0f / %.0f" % [quantidade, vida_atual, vida_maxima])

func derrotar() -> void:
	_dropar_itens()
	inimigo_derrotado.emit(global_position)
	queue_free()

func _dropar_itens() -> void:
	var enemy_id = ""
	for child in get_children():
		if child.name == "EnemyTrigger":
			enemy_id = child.get("id_inimigo")
			break

	var r = randf()
	var is_quimica = (enemy_id.begins_with("slime"))
	var is_fisica = (enemy_id.begins_with("robo"))

	if is_quimica:
		if r > 0.50:
			_instanciar_drop("res://scenes/Entidades/ItemFragmentoGelatina.tscn")
		else:
			_instanciar_drop("res://scenes/Entidades/ItemMoeda.tscn")
	elif is_fisica:
		if r > 0.50:
			_instanciar_drop("res://scenes/Entidades/ItemChip.tscn")
		else:
			_instanciar_drop("res://scenes/Entidades/ItemMoeda.tscn")
	else:
		if r > 0.50:
			_instanciar_drop("res://scenes/Entidades/ItemMoeda.tscn")

func _instanciar_drop(caminho: String) -> void:
	var cena = load(caminho)
	if not cena: return
	var item = cena.instantiate()
	var angle = randf() * TAU
	var dist = randf_range(30.0, 60.0)
	if caminho.ends_with("ItemChave.tscn"):
		item.position = global_position
	else:
		item.position = global_position + Vector2(cos(angle), sin(angle)) * dist
	get_parent().call_deferred("add_child", item)

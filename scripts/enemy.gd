extends CharacterBody2D

## [Dev-1] Script do Inimigo — variáveis exportáveis + patrulha aleatória
## Move-se em direções aleatórias (8 direções) até encontrar o Player.
## Ao receber o sinal de batalha, para completamente.

# ──────────────────────────────────────────
# Atributos do Inimigo (configuráveis pelo Inspector)
# ──────────────────────────────────────────
@export var vida_maxima:       float = 100.0  ## HP total do inimigo
@export var velocidade:        float =  55.0  ## Pixels/segundo na patrulha
@export var dano:              float =  25.0  ## Dano base por erro do jogador
@export var tempo_min_direcao: float =  0.8   ## Mínimo de segundos antes de sortear nova direção
@export var tempo_max_direcao: float =  2.2   ## Máximo de segundos antes de sortear nova direção
@export var chance_pausa:      float =  0.2   ## 0.0‒1.0 — chance de parar por um instante ao trocar direção

# ──────────────────────────────────────────
# Estado interno
# ──────────────────────────────────────────
var vida_atual:      float
var _em_batalha:     bool    = false
var _em_pausa:       bool    = false
var _direcao:        Vector2 = Vector2.RIGHT  ## Direção atual da patrulha (normalizada)
var _timer_direcao:  float   = 0.0            ## Tempo restante nesta direção
var _timer_pausa:    float   = 0.0            ## Tempo de pausa (imóvel)

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
	vida_atual = vida_maxima
	randomize()

	# Começa já com uma direção aleatória
	_sortear_nova_direcao()

	# Escuta sinais globais de batalha
	GlobalSignals.iniciar_batalha.connect(_on_batalha_iniciada)
	GlobalSignals.batalha_encerrada.connect(_on_batalha_encerrada)

	if sprite:
		sprite.play("default")

# ──────────────────────────────────────────
# Loop de Patrulha Aleatória
# ──────────────────────────────────────────
func _physics_process(delta: float) -> void:
	# Contagem regressiva de pausa (inimigo fica parado por um instante)
	if _em_pausa:
		_timer_pausa -= delta
		if _timer_pausa <= 0.0:
			_em_pausa = false
			_sortear_nova_direcao()
		velocity = Vector2.ZERO
		move_and_slide()
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

	# Move na direção atual
	velocity = _direcao * velocidade

	# Flip horizontal do sprite conforme componente X da direção
	if sprite and _direcao.x != 0.0:
		sprite.flip_h = (_direcao.x < 0.0)

	move_and_slide()

	# Se colidiu com parede (velocity zerou pelo move_and_slide), sorteia nova direção imediatamente
	if velocity.length() < 1.0 and not _em_pausa:
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
func _on_batalha_iniciada(_enemy_data: Dictionary) -> void:
	## Para a patrulha imediatamente — desliga o physics process no nível do engine
	_em_batalha = true
	_em_pausa   = false
	velocity    = Vector2.ZERO
	set_physics_process(false)  # Congelamento garantido, independente do pause da árvore
	hide()                      # Esconde o inimigo enquanto a batalha ocorre
	print("[Dev-1] Inimigo pausou patrulha — batalha iniciada.")

func _on_batalha_encerrada(vitoria: bool) -> void:
	## Retoma patrulha somente se o jogador perdeu (inimigo sobreviveu)
	if not vitoria:
		_em_batalha = false
		show()                      # Volta a exibir o inimigo no mapa
		set_physics_process(true)   # Religa o movimento
		_sortear_nova_direcao()
		print("[Dev-1] Inimigo retomou patrulha aleatória — jogador derrotado.")
	# Se vitoria=true: inimigo permanece oculto e imóvel (foi derrotado)

# ──────────────────────────────────────────
# Dano recebido (chamado pelo QuizManager via acerto do jogador)
# ──────────────────────────────────────────
func sofrer_dano(quantidade: float) -> void:
	vida_atual = max(0.0, vida_atual - quantidade)
	print("[Dev-1] Inimigo recebeu %.0f de dano. Vida: %.0f / %.0f" % [quantidade, vida_atual, vida_maxima])

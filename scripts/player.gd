extends CharacterBody2D

const VELOCIDADE = 200.0

var direcao_horizontal: float
var direcao_vertical: float

var ultima_direcao = "baixo"

# [Trap-1] Mímico — flag que trava o movimento do player
var travado: bool = false

# [Fix-1] HP unificado: gerenciado exclusivamente pelo autoload PlayerStats

func _ready() -> void:
	add_to_group("player")
	
	# Reposiciona o player na porta correta quando estiver voltando de uma sala
	call_deferred("_reposicionar_na_porta_correta")
	
	# quando a batalha começar, vira o mago pra direita (olhando pro inimigo)
	GlobalSignals.iniciar_batalha.connect(func(_d):
		ultima_direcao = "direita"
		$sprite.play("idle_direita")
	)

func _reposicionar_na_porta_correta() -> void:
	if not get_node_or_null("/root/DungeonGenerator"):
		return
	
	var portas = get_tree().get_nodes_in_group("porta_transicao")
	if portas.is_empty():
		return
		
	if DungeonGenerator.vindo_de_porta_de_retorno:
		# Ao VOLTAR, nasce perto da porta de AVANÇO desta sala (porta de cima/norte)
		for porta in portas:
			if not porta.porta_de_retorno:
				global_position = porta.global_position
				global_position.y += 180 # Nasce mais abaixo (escapando de colisão)
				break
	else:
		# Ao AVANÇAR, nasce perto da porta de RETORNO desta sala (porta de baixo/sul)
		for porta in portas:
			if porta.porta_de_retorno:
				global_position = porta.global_position
				global_position.y -= 180 # Nasce mais acima (escapando de colisão)
				break

func _physics_process(_delta: float) -> void:
	# Se travado pelo Mímico, não processa input de movimento
	if travado:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	direcao_horizontal = Input.get_axis("esquerda", "direita")
	direcao_vertical = Input.get_axis("cima", "baixo")

	velocity = Vector2.ZERO
	
	if not direcao_vertical == 0:
		velocity.y = direcao_vertical * VELOCIDADE
		if direcao_vertical < 0:
			ultima_direcao = "cima"
			$sprite.play("correr_cima")
		else:
			ultima_direcao = "baixo"
			$sprite.play("correr_baixo")
	elif not direcao_horizontal == 0:
		velocity.x = direcao_horizontal * VELOCIDADE
		if direcao_horizontal < 0:
			ultima_direcao = "esquerda"
			$sprite.play("correr_esquerda")
		else:
			ultima_direcao = "direita"
			$sprite.play("correr_direita")
	else:
		$sprite.play("idle_" + ultima_direcao)
	
	# Exemplo áudio
	if Input.is_action_just_pressed("ui_accept"):
		AudioManager.play_sfx("ui-1")
	
	
	move_and_slide()

# [Fix-1] Chamado pelo Mímico para aplicar penalidade e feedback visual
func receber_dano_mimico() -> void:
	# [Fix-1] Delega o dano ao autoload centralizado (emite vida_alterada → HUD atualiza)
	PlayerStats.sofrer_dano(15.0)
	print("[Mímico] HP restante: %.0f / %.0f" % [PlayerStats.vida_atual_jogador, PlayerStats.vida_maxima_jogador])

	# Flash vermelho no sprite (feedback visual mantido)
	var tween = create_tween()
	tween.tween_property($sprite, "modulate", Color(1, 0.1, 0.1, 1), 0.08)
	tween.tween_property($sprite, "modulate", Color(1, 1, 1, 1), 0.35)

extends CharacterBody2D

const VELOCIDADE = 200.0

var direcao_horizontal: float
var direcao_vertical: float

var ultima_direcao = "baixo"

# [Trap-1] Mímico — flag que trava o movimento do player
var travado: bool = false

# [Fix-1] HP unificado: gerenciado exclusivamente pelo autoload PlayerStats
var _vida_anterior: float = 100.0
var _shake_tempo: float = 0.0
var _shake_intensidade: float = 0.0

func _ready() -> void:
	add_to_group("player")
	_vida_anterior = PlayerStats.vida_atual_jogador
	
	# Tremer a câmera se tomar dano
	PlayerStats.vida_alterada.connect(func(atual, _maxima):
		if atual < _vida_anterior:
			aplicar_shake(7.0, 0.22)
		_vida_anterior = atual
	)
	
	# Reposiciona o player na porta correta quando estiver voltando de uma sala
	call_deferred("_reposicionar_na_porta_correta")
	
	# quando a batalha começar, vira o mago pra direita e para o movimento
	GlobalSignals.iniciar_batalha.connect(func(_d):
		velocity = Vector2.ZERO
		ultima_direcao = "direita"
		$sprite.play("idle_direita")
		if has_node("PoeiraPassos"):
			$PoeiraPassos.emitting = false
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
				# No Hub, precisamos nascer na porta específica que o jogador entrou!
				if porta.get("is_hub_door") and porta.get("hub_dungeon_name") != DatabaseManager.active_dungeon:
					continue
					
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
	
	var vel_atual = VELOCIDADE
	var dev_mgr = get_node_or_null("/root/DevManager")
	if dev_mgr and dev_mgr.DEV_MODE_ENABLED and dev_mgr.super_velocidade:
		vel_atual *= dev_mgr.multiplicador_velocidade
	
	if not direcao_vertical == 0:
		velocity.y = direcao_vertical * vel_atual
		if direcao_vertical < 0:
			AudioManager.tocar_som_caminhada()
			ultima_direcao = "cima"
			$sprite.play("correr_cima")
		else:
			AudioManager.tocar_som_caminhada()
			ultima_direcao = "baixo"
			$sprite.play("correr_baixo")
	elif not direcao_horizontal == 0:
		velocity.x = direcao_horizontal * vel_atual
		if direcao_horizontal < 0:
			AudioManager.tocar_som_caminhada()
			ultima_direcao = "esquerda"
			$sprite.play("correr_esquerda")
		else:
			AudioManager.tocar_som_caminhada()
			ultima_direcao = "direita"
			$sprite.play("correr_direita")
	else:
		$sprite.play("idle_" + ultima_direcao)
	
	# Exemplo áudio
	if Input.is_action_just_pressed("ui_accept"):
		AudioManager.play_sfx("ui-1")
	
	move_and_slide()

	# Se o jogador colidiu com um inimigo hostil enquanto andava, aciona a batalha imediatamente!
	var em_transicao = get_node_or_null("/root/TransitionScreen") and TransitionScreen.is_transitioning
	if not em_transicao:
		for i in range(get_slide_collision_count()):
			var col = get_slide_collision(i)
			var collider = col.get_collider()
			if collider and collider.is_in_group("inimigos"):
				var trigger = collider.get_node_or_null("EnemyTrigger")
				if trigger and trigger.has_method("_on_body_entered"):
					trigger._on_body_entered(self)
					break

	_animar_sombra(_delta)
	
	# Partículas de poeira nos passos (sempre atrás do corpo do personagem)
	if has_node("PoeiraPassos"):
		var movendo = (velocity.length() > 10.0)
		$PoeiraPassos.emitting = movendo
		if movendo:
			var dir_norm = velocity.normalized()
			$PoeiraPassos.direction = -dir_norm
				
	_process_shake(_delta)

const SOMBRA_BASE_X: float = 1.85
const SOMBRA_BASE_Y: float = 1.25
var tempo_anim_sombra: float = 0.0

func _animar_sombra(delta: float) -> void:
	if not has_node("Shadow"):
		return
	
	tempo_anim_sombra += delta
	var shadow = $Shadow
	
	if velocity.length() > 10.0:
		# Andando: leve efeito elástico (squash & stretch) sincronizado com os passos
		var onda = sin(tempo_anim_sombra * 16.0)
		shadow.scale.x = SOMBRA_BASE_X + onda * 0.15
		shadow.scale.y = SOMBRA_BASE_Y - onda * 0.10
	else:
		# Parado (Idle): pulso suave e sutil acompanhando a respiração do mago
		var onda = sin(tempo_anim_sombra * 3.5)
		shadow.scale.x = SOMBRA_BASE_X + onda * 0.06
		shadow.scale.y = SOMBRA_BASE_Y + onda * 0.04

## Aplica Screen Shake dinâmico na câmera do jogador
func aplicar_shake(intensidade: float = 6.0, duracao: float = 0.2) -> void:
	_shake_intensidade = max(_shake_intensidade, intensidade)
	_shake_tempo = max(_shake_tempo, duracao)

func _process_shake(delta: float) -> void:
	if not has_node("Camera2D"):
		return
	if _shake_tempo > 0.0:
		_shake_tempo -= delta
		var offset_shake = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_intensidade
		$Camera2D.offset = offset_shake
		_shake_intensidade = lerp(_shake_intensidade, 0.0, delta * 8.0)
	else:
		$Camera2D.offset = Vector2.ZERO

# [Fix-1] Chamado pelo Mímico para aplicar penalidade e feedback visual
func receber_dano_mimico() -> void:
	# [Fix-1] Delega o dano ao autoload centralizado (emite vida_alterada → HUD atualiza)
	PlayerStats.sofrer_dano(15.0)
	aplicar_shake(8.0, 0.25)
	print("[Mímico] HP restante: %.0f / %.0f" % [PlayerStats.vida_atual_jogador, PlayerStats.vida_maxima_jogador])
	
	# Flash vermelho no sprite (feedback visual mantido)
	var tween = create_tween()
	tween.tween_property($sprite, "modulate", Color(1, 0.1, 0.1, 1), 0.08)
	tween.tween_property($sprite, "modulate", Color(1, 1, 1, 1), 0.35)

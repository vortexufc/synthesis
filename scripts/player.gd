extends CharacterBody2D

const VELOCIDADE = 200.0

var direcao_horizontal: float
var direcao_vertical: float

var ultima_direcao = "baixo"

# trava o movimento durante interacoes
var travado: bool = false
var em_interacao: bool = false
var _tempo_imunidade_pos_interacao: float = 0.0

func esta_em_interacao() -> bool:
	if travado or em_interacao:
		return true
	if get_node_or_null("/root/QuizManager") and QuizManager.em_batalha:
		return true
	if get_tree():
		if get_tree().get_nodes_in_group("minigame_ativo").size() > 0:
			return true
		if get_tree().get_nodes_in_group("dialogo_ativo").size() > 0:
			return true
	return false

func esta_imune_a_combate() -> bool:
	return esta_em_interacao() or _tempo_imunidade_pos_interacao > 0.0

func finalizar_interacao(tempo_graca: float = 0.8) -> void:
	travado = false
	em_interacao = false
	_tempo_imunidade_pos_interacao = tempo_graca

# hp gerenciado pelo PlayerStats
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
		var masmorra_alvo = ""
		if get_node_or_null("/root/DungeonGenerator") and DungeonGenerator.get("masmorra_retorno_hub") != "":
			masmorra_alvo = DungeonGenerator.masmorra_retorno_hub
		elif get_node_or_null("/root/DatabaseManager") and DatabaseManager.active_dungeon != "":
			masmorra_alvo = DatabaseManager.active_dungeon
			
		for porta in portas:
			if not porta.porta_de_retorno:
				# No Hub, precisamos nascer na porta específica que o jogador explorava!
				if porta.get("is_hub_door"):
					if masmorra_alvo != "" and porta.get("hub_dungeon_name") != masmorra_alvo:
						continue
					
				global_position = porta.global_position
				global_position.y += 180 # Nasce mais abaixo (escapando de colisão)
				break
		DungeonGenerator.vindo_de_porta_de_retorno = false
	else:
		# Ao AVANÇAR, nasce perto da porta de RETORNO desta sala (porta de baixo/sul)
		for porta in portas:
			if porta.porta_de_retorno:
				global_position = porta.global_position
				global_position.y -= 180 # Nasce mais acima (escapando de colisão)
				break

func _physics_process(delta: float) -> void:
	if _tempo_imunidade_pos_interacao > 0.0:
		_tempo_imunidade_pos_interacao -= delta

	# se tiver em dialogo ou minigame, nao move
	if esta_em_interacao():
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
	if not em_transicao and not esta_imune_a_combate():
		for i in range(get_slide_collision_count()):
			var col = get_slide_collision(i)
			var collider = col.get_collider()
			if collider and collider.is_in_group("inimigos"):
				var trigger = collider.get_node_or_null("EnemyTrigger")
				if trigger and trigger.has_method("_on_body_entered"):
					trigger._on_body_entered(self)
					break

	_animar_sombra(delta)
	
	# Partículas de poeira nos passos (sempre atrás do corpo do personagem)
	if has_node("PoeiraPassos"):
		var movendo = (velocity.length() > 10.0)
		$PoeiraPassos.emitting = movendo
		if movendo:
			var dir_norm = velocity.normalized()
			$PoeiraPassos.direction = -dir_norm
				
	_process_shake(delta)

const SOMBRA_BASE_X: float = 1.85
const SOMBRA_BASE_Y: float = 1.25
var tempo_anim_sombra: float = 0.0

func _animar_sombra(delta: float) -> void:
	if not has_node("Shadow"):
		return
	
	tempo_anim_sombra += delta
	var shadow = $Shadow
	
	if velocity.length() > 10.0:
		var onda = sin(tempo_anim_sombra * 16.0)
		shadow.scale.x = SOMBRA_BASE_X + onda * 0.15
		shadow.scale.y = SOMBRA_BASE_Y - onda * 0.10
	else:
		var onda = sin(tempo_anim_sombra * 3.5)
		shadow.scale.x = SOMBRA_BASE_X + onda * 0.06
		shadow.scale.y = SOMBRA_BASE_Y + onda * 0.04

# shake na camera do player
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

# dano do mimico
func receber_dano_mimico(quantidade: float = 70.0) -> void:
	receber_dano(quantidade, 14.0, "Mímico")
	print("[Mímico] Jogador mordido pelo Mímico! Dano: %.0f | HP restante: %.0f / %.0f" % [quantidade, PlayerStats.vida_atual_jogador, PlayerStats.vida_maxima_jogador])

# dano de armadilha / perigo do cenario
func receber_dano(quantidade: float = 15.0, intensidade_shake: float = 8.0, motivo: String = "") -> void:
	PlayerStats.sofrer_dano(quantidade)
	aplicar_shake(intensidade_shake, 0.28)
	
	if has_node("sprite"):
		var tween = create_tween()
		tween.tween_property($sprite, "modulate", Color(2.2, 0.15, 0.15, 1.0), 0.08)
		tween.tween_property($sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.35)
		
	if not motivo.is_empty():
		_exibir_texto_dano(motivo, quantidade)

func _exibir_texto_dano(motivo: String, quantidade: float) -> void:
	var lbl = Label.new()
	lbl.text = "-%.0f HP (%s)" % [quantidade, motivo]
	lbl.z_index = 25
	lbl.position = Vector2(-80, -90)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
	var font_pixel = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	if font_pixel:
		lbl.add_theme_font_override("font", font_pixel)
	add_child(lbl)
	
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 32.0, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.85).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(lbl.queue_free)

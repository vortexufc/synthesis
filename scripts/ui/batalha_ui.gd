extends CanvasLayer

signal resposta_escolhida(indice: int, tempo_usado: float)

@onready var label_pergunta: Label = $Control/FooterColor/MarginContainer/VBoxContainer/QuestionPanel/LabelQuestion
@onready var btn_a: Button = $Control/FooterColor/MarginContainer/VBoxContainer/HBoxButtons/BtnA
@onready var btn_b: Button = $Control/FooterColor/MarginContainer/VBoxContainer/HBoxButtons/BtnB
@onready var btn_c: Button = $Control/FooterColor/MarginContainer/VBoxContainer/HBoxButtons/BtnC
@onready var btn_d: Button = $Control/FooterColor/MarginContainer/VBoxContainer/HBoxButtons/BtnD
@onready var btn_e: Button = $Control/FooterColor/MarginContainer/VBoxContainer/HBoxButtons/BtnE
@onready var label_tempo: Label = $Control/TimerPainel/TextoTempo

@onready var health_player: Control = $Control/HealthPlayer
@onready var health_enemy: Control = $Control/HealthEnemy
@onready var health_player_fill: NinePatchRect = $Control/HealthPlayer/HealthBarFill
@onready var health_enemy_fill: NinePatchRect = $Control/HealthEnemy/HealthBarFill
var health_player_ghost: NinePatchRect = null
var health_enemy_ghost: NinePatchRect = null
var _tween_p_fill: Tween = null
var _tween_p_ghost: Tween = null
var _tween_e_fill: Tween = null
var _tween_e_ghost: Tween = null

var _botoes: Array = []

# [BugFix] Flag que bloqueia chamadas duplicadas enquanto uma resposta está sendo processada
var _processando_resposta: bool = false

# o timer corre continuo durante a batalha
# tempo_restante só é (re)definido por iniciar_timer() — nunca em atualizar_pergunta().
var tempo_restante: float = 300.0
var tempo_rodando: bool = false
var _duracao_batalha: float = 300.0 # tempo total da batalha
var _ultimo_botao_clicado: int = -1
var _tween_botoes: Tween
var _eh_pergunta_vf: bool = false

var battle_music = preload("res://assets/audio/ost/2.wav")
var _font_pixel_combate = preload("res://assets/fonts/PressStart2P-Regular.ttf")

const FUNDO_QUIMICA = preload("res://assets/sprites/Backgrounds/Batalha/fundo_batalha_quimica.png")
const FUNDO_FISICA = preload("res://assets/sprites/Backgrounds/Batalha/fundo_batalha_fisica.png")
const FUNDO_BIOLOGIA = preload("res://assets/sprites/Backgrounds/Batalha/fundo_batalha_biologia.png")

func _ready() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_battle_music(battle_music)
	# garante que os botoes funcionem mesmo com o jogo pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	_configurar_ghost_bars()
	_botoes = [btn_a, btn_b, btn_c, btn_d, btn_e]
	for i in range(_botoes.size()):
		_botoes[i].pressed.connect(_on_botao_pressionado.bind(i))
		
	# se curar no inventario, arruma a barra verde
	var ps = get_node_or_null("/root/PlayerStats")
	if ps:
		ps.vida_alterada.connect(_on_vida_jogador_alterada)
	
	# Configura o fundo conforme o andar ativo
	var qm = get_node_or_null("/root/QuizManager")
	var dm = get_node_or_null("/root/DatabaseManager")
	var andar_detectado = 1
	if qm and "_andar_atual" in qm and qm._andar_atual > 0:
		andar_detectado = qm._andar_atual
	elif dm and dm.active_dungeon != "":
		match dm.active_dungeon:
			"Química": andar_detectado = 1
			"Física": andar_detectado = 2
			"Biologia": andar_detectado = 3
			_: andar_detectado = 1
	configurar_fundo(andar_detectado)

func configurar_fundo(andar_id: int) -> void:
	var tex: Texture2D = FUNDO_QUIMICA
	match andar_id:
		1:
			tex = FUNDO_QUIMICA
		2:
			tex = FUNDO_FISICA
		3:
			tex = FUNDO_BIOLOGIA
		_:
			tex = FUNDO_QUIMICA
	if has_node("Control/BackgroundMockup"):
		$Control/BackgroundMockup.texture = tex

func configurar_inimigo(frames: SpriteFrames, id_inimigo: String = "") -> void:
	if frames and $Control/SpriteMonstro/AnimatedSprite2D:
		$Control/SpriteMonstro/AnimatedSprite2D.sprite_frames = frames
		
		# [UI] Robozinhos pequenos não tem animação de idle, só de andar.
		# Então congelamos eles no primeiro frame para ficarem parados de frente.
		if id_inimigo.begins_with("robo_p"):
			$Control/SpriteMonstro/AnimatedSprite2D.stop()
			$Control/SpriteMonstro/AnimatedSprite2D.frame = 0
		else:
			$Control/SpriteMonstro/AnimatedSprite2D.play("default")
		
		# [UI] Ajusta posições para que a barra de vida nunca fique na frente das animações de pulo/ataque
		$Control/HealthPlayer.position.y = 115.0
		if id_inimigo == "robo_g":
			$Control/SpriteMonstro.position.y = 135.0
			$Control/HealthEnemy.position.y = 105.0
		elif id_inimigo == "evil_wizzard":
			$Control/SpriteMonstro.position.y = 195.0
			$Control/HealthEnemy.position.y = 115.0
		elif "boss" in id_inimigo or "roxo" in id_inimigo or "carnivora" in id_inimigo:
			$Control/SpriteMonstro.position.y = 195.0 # Slime Boss ou Carnívora assentados no chão
			$Control/HealthEnemy.position.y = 100.0 # Barra elevada bem acima da animação
			$Control/SpriteMonstro/AnimatedSprite2D.scale = Vector2(2.3, 2.3)
		elif "laranja" in id_inimigo or id_inimigo == "slime_g":
			$Control/SpriteMonstro.position.y = 205.0
			$Control/HealthEnemy.position.y = 115.0
			$Control/SpriteMonstro/AnimatedSprite2D.scale = Vector2(1.8, 1.8)
		elif "cogumelo" in id_inimigo or "flor" in id_inimigo or "planta" in id_inimigo:
			$Control/SpriteMonstro.position.y = 205.0
			$Control/HealthEnemy.position.y = 115.0
			$Control/SpriteMonstro/AnimatedSprite2D.scale = Vector2(2.2, 2.2)
		else:
			$Control/SpriteMonstro.position.y = 233.0
			$Control/HealthEnemy.position.y = 115.0
			$Control/SpriteMonstro/AnimatedSprite2D.scale = Vector2(1.5, 1.5)
			
		# [UI] Apenas os robôs e as criaturas de biologia encaram a esquerda/frente naturalmente, logo não precisam do flip_h.
		# Slimes e o Mago encaram a direita na sprite original, então precisam.
		var id_low = id_inimigo.to_lower()
		if id_low == "robo_g" or id_low.begins_with("robo_p") or "cogumelo" in id_low or "flor" in id_low or "planta" in id_low or "carnivora" in id_low:
			$Control/SpriteMonstro/AnimatedSprite2D.flip_h = false
		else:
			$Control/SpriteMonstro/AnimatedSprite2D.flip_h = true
func _on_vida_jogador_alterada(atual: float, maxima: float) -> void:
	var pct = clamp(atual / maxima, 0.0, 1.0)
	var target_w = max(0.0, 200.0 * pct)
	if target_w > 0:
		health_player_fill.visible = true
	var t = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(health_player_fill, "size:x", target_w, 0.5)
	if target_w <= 0:
		t.tween_callback(func():
			if is_instance_valid(health_player_fill):
				health_player_fill.visible = false
		)

func _process(delta: float) -> void:
	if self.visible and tempo_rodando:
		tempo_restante -= delta
		if tempo_restante <= 0:
			tempo_restante = 0
			tempo_rodando = false # [BugFix] Para ANTES de chamar o botão para evitar re-entrada
			if not _processando_resposta: # [BugFix] Só dispara se não há resposta em andamento
				_on_botao_pressionado(-1) # errou por tempo
		
		var minutos = int(tempo_restante / 60.0)
		var segundos = int(tempo_restante) % 60
		label_tempo.text = "TEMPO:\n%02d:%02d" % [minutos, segundos]

# inicia o timer da luta
# Deve ser chamado UMA ÚNICA VEZ por batalha, antes da primeira rodada.
func iniciar_timer(duracao: float) -> void:
	_duracao_batalha = duracao
	tempo_restante = duracao
	tempo_rodando = true

func atualizar_pergunta(texto: String, alternativas: Array) -> void:
	self.show()
	_fechar_painel_feedback_imediato()
	if has_node("Control/FooterColor/MarginContainer/VBoxContainer/HBoxButtons"):
		$Control/FooterColor/MarginContainer/VBoxContainer/HBoxButtons.show()
		
	_processando_resposta = false # [BugFix] Libera o lock para a nova pergunta
	# [BugFix] Só retoma o timer se ainda há tempo — evita loop de timeout
	if tempo_restante > 0:
		tempo_rodando = true
	label_pergunta.text = texto.replace('\\"', '"').replace("\\'", "'")
	# Cancela o tween antigo das cores pra ele não sobreescrever o branco da nova pergunta
	if _tween_botoes:
		_tween_botoes.kill()
		
	var eh_vf = (alternativas.size() == 2 and (
		str(alternativas[0]).strip_edges().to_lower().begins_with("verdadeiro") or str(alternativas[0]).strip_edges().to_lower() == "v"
	))
	_eh_pergunta_vf = eh_vf
		
	for i in range(_botoes.size()):
		_botoes[i].modulate = Color.WHITE
		if i < alternativas.size():
			if eh_vf:
				if i == 0:
					_botoes[i].text = "[ V ]  VERDADEIRO"
					_botoes[i].modulate = Color(0.7, 1.25, 0.8) # Verde esmeralda vivo
				elif i == 1:
					_botoes[i].text = "[ F ]  FALSO"
					_botoes[i].modulate = Color(1.25, 0.7, 0.7) # Vermelho rubi vivo
			else:
				var prefix = ["A) ", "B) ", "C) ", "D) ", "E) "][i]
				_botoes[i].text = prefix + str(alternativas[i]).replace('\\"', '"').replace("\\'", "'")
			_botoes[i].show()
			_botoes[i].disabled = false
		else:
			_botoes[i].hide()

func _configurar_ghost_bars() -> void:
	if health_player_fill and health_player:
		health_player_ghost = health_player_fill.duplicate() as NinePatchRect
		health_player_ghost.name = "HealthBarGhost"
		# Rastro de dano ambar/dourado suave (Item 1)
		health_player_ghost.modulate = Color(1.0, 0.88, 0.40, 0.95)
		health_player.add_child(health_player_ghost)
		health_player.move_child(health_player_ghost, health_player_fill.get_index())
		
	if health_enemy_fill and health_enemy:
		health_enemy_ghost = health_enemy_fill.duplicate() as NinePatchRect
		health_enemy_ghost.name = "HealthBarGhost"
		# Rastro de dano alaranjado/branco suave no inimigo (Item 1)
		health_enemy_ghost.modulate = Color(1.0, 0.65, 0.35, 0.95)
		health_enemy.add_child(health_enemy_ghost)
		health_enemy.move_child(health_enemy_ghost, health_enemy_fill.get_index())

func atualizar_vida(pct_player: float, pct_enemy: float) -> void:
	pct_player = clamp(pct_player, 0.0, 1.0)
	pct_enemy = clamp(pct_enemy, 0.0, 1.0)
	var target_p = max(0.0, 200.0 * pct_player)
	var target_e = max(0.0, 230.0 * pct_enemy)
	
	if target_p > 0:
		health_player_fill.visible = true
		if health_player_ghost: health_player_ghost.visible = true
	if target_e > 0:
		health_enemy_fill.visible = true
		if health_enemy_ghost: health_enemy_ghost.visible = true
		
	# --- PLAYER: Ghost Bar com queda rápida da barra principal e rastro suave ---
	if _tween_p_fill and _tween_p_fill.is_running(): _tween_p_fill.kill()
	if _tween_p_ghost and _tween_p_ghost.is_running(): _tween_p_ghost.kill()
	
	_tween_p_fill = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween_p_fill.tween_property(health_player_fill, "size:x", target_p, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	if health_player_ghost:
		_tween_p_ghost = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		if target_p < health_player_ghost.size.x:
			_tween_p_ghost.tween_interval(0.28)
			_tween_p_ghost.tween_property(health_player_ghost, "size:x", target_p, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			_tween_p_ghost.tween_property(health_player_ghost, "size:x", target_p, 0.14)

	# --- INIMIGO: Ghost Bar de impacto ---
	if _tween_e_fill and _tween_e_fill.is_running(): _tween_e_fill.kill()
	if _tween_e_ghost and _tween_e_ghost.is_running(): _tween_e_ghost.kill()
	
	_tween_e_fill = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween_e_fill.tween_property(health_enemy_fill, "size:x", target_e, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	if health_enemy_ghost:
		_tween_e_ghost = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		if target_e < health_enemy_ghost.size.x:
			_tween_e_ghost.tween_interval(0.28)
			_tween_e_ghost.tween_property(health_enemy_ghost, "size:x", target_e, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			_tween_e_ghost.tween_property(health_enemy_ghost, "size:x", target_e, 0.14)
	
	if target_p <= 0:
		_tween_p_fill.chain().tween_callback(func():
			if is_instance_valid(health_player_fill): health_player_fill.visible = false
			if is_instance_valid(health_player_ghost): health_player_ghost.visible = false
		)
	if target_e <= 0:
		_tween_e_fill.chain().tween_callback(func():
			if is_instance_valid(health_enemy_fill): health_enemy_fill.visible = false
			if is_instance_valid(health_enemy_ghost): health_enemy_ghost.visible = false
		)

func _on_botao_pressionado(indice: int) -> void:
	# [BugFix] Ignora cliques duplicados ou re-entrada do timer
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx("ui_1")
	if _processando_resposta:
		return
	_processando_resposta = true
	_ultimo_botao_clicado = indice
	tempo_rodando = false # para o timer
	for btn in _botoes:
		btn.disabled = true
		
	resposta_escolhida.emit(indice, tempo_restante)

func ocultar_interface() -> void:
	_fechar_painel_feedback_imediato()
	self.hide()

func mostrar_resultado(acertou: bool, idx_correto: int, valor: int, dados_pergunta: Dictionary = {}) -> void:
	if _tween_botoes:
		_tween_botoes.kill()
		
	_tween_botoes = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	
	if idx_correto >= 0 and idx_correto < _botoes.size():
		# Pinta instantaneamente e segura a cor (ou anima bem rápido)
		_botoes[idx_correto].modulate = Color(0.2, 0.8, 0.2)
		_tween_botoes.tween_property(_botoes[idx_correto], "modulate", Color(0.2, 0.8, 0.2), 1.2)
		
	if not acertou and _ultimo_botao_clicado >= 0 and _ultimo_botao_clicado < _botoes.size():
		_botoes[_ultimo_botao_clicado].modulate = Color(0.9, 0.2, 0.2)
		_tween_botoes.tween_property(_botoes[_ultimo_botao_clicado], "modulate", Color(0.9, 0.2, 0.2), 1.2)
		
	if acertou:
		# Salto de conjuração do mago para a frente
		var pos_mago = $Control.get_node_or_null("PosicaoMago")
		if pos_mago:
			var tw_m = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			var base_m_x = pos_mago.position.x
			tw_m.tween_property(pos_mago, "position:x", base_m_x + 18.0, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw_m.tween_property(pos_mago, "position:x", base_m_x, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			
		$AnimationPlayer.play("ataque_mago")
		await $AnimationPlayer.animation_finished
		
		# Som original de ataque/impacto
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("tocar_som_ataque"):
			am.tocar_som_ataque()
		
		# Flash e deformação física (Squash & Stretch) no monstro
		var sprite_monstro = $Control/SpriteMonstro
		var scale_base = sprite_monstro.scale
		var tw_sq = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw_sq.tween_property(sprite_monstro, "scale", Vector2(scale_base.x * 1.35, scale_base.y * 0.70), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_sq.tween_property(sprite_monstro, "scale", Vector2(scale_base.x * 0.82, scale_base.y * 1.22), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_sq.tween_property(sprite_monstro, "scale", scale_base, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		# Flash branco puro de impacto (hit-stop visual), seguido de avermelhado
		var tween_flash = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween_flash.tween_property(sprite_monstro, "modulate", Color(2.8, 2.8, 2.8, 1.0), 0.06)
		tween_flash.tween_property(sprite_monstro, "modulate", Color(1.0, 0.2, 0.2, 1.0), 0.14)
		tween_flash.tween_property(sprite_monstro, "modulate", Color.WHITE, 0.28)
		
		# Tremor de tela de impacto potente
		var shake_impact = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		shake_impact.tween_property($Control, "position", Vector2(8, -5), 0.03)
		shake_impact.tween_property($Control, "position", Vector2(-8, 5), 0.03)
		shake_impact.tween_property($Control, "position", Vector2(4, 2), 0.03)
		shake_impact.tween_property($Control, "position", Vector2.ZERO, 0.03)
		
		# Tremor físico posicional do próprio monstro
		var pos_base_x = sprite_monstro.position.x
		var impact_tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		impact_tw.tween_property(sprite_monstro, "position:x", pos_base_x + 10.0, 0.04)
		impact_tw.tween_property(sprite_monstro, "position:x", pos_base_x - 10.0, 0.04)
		impact_tw.tween_property(sprite_monstro, "position:x", pos_base_x + 5.0, 0.04)
		impact_tw.tween_property(sprite_monstro, "position:x", pos_base_x, 0.04)
		
		# Floating Combat Text: Dano subindo e flutuando em cima do monstro
		var eh_critico: bool = (valor >= 30)
		_mostrar_texto_flutuante_dano_monstro(valor, eh_critico)
	else:

		if _ultimo_botao_clicado == -1:
			# [BugFix] Timeout: exibe feedback de tempo no mago
			_mostrar_texto_flutuante_dano_jogador(valor, true)
			await get_tree().create_timer(0.5, true).timeout
		else:
			# Toca animação customizada do monstro se existir (ex: Robão)
			if $Control/SpriteMonstro/AnimatedSprite2D.sprite_frames.has_animation("ataque"):
				$Control/SpriteMonstro/AnimatedSprite2D.play("ataque")
				
			$AnimationPlayer.play("ataque_inimigo")
			await $AnimationPlayer.animation_finished
			
			# Retorna pro idle
			if $Control/SpriteMonstro/AnimatedSprite2D.sprite_frames.has_animation("default"):
				$Control/SpriteMonstro/AnimatedSprite2D.play("default")
			
		# Screen shake dinâmico na tela de batalha ao tomar dano
		var shake_tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		shake_tw.tween_property($Control, "position", Vector2(10, -6), 0.035)
		shake_tw.tween_property($Control, "position", Vector2(-10, 6), 0.035)
		shake_tw.tween_property($Control, "position", Vector2(6, 4), 0.035)
		shake_tw.tween_property($Control, "position", Vector2(-4, -2), 0.035)
		shake_tw.tween_property($Control, "position", Vector2.ZERO, 0.035)
			
		# Floating Combat Text no jogador
		_mostrar_texto_flutuante_dano_jogador(valor, false)
	
	# [Pedagogia] Se o aluno errou, exibe a caixinha de revisão com resposta correta e explicação
	if not acertou and not dados_pergunta.is_empty():
		await _exibir_feedback_erro(dados_pergunta, idx_correto)

func _fechar_painel_feedback_imediato() -> void:
	if has_node("Control/FooterColor/MarginContainer/VBoxContainer/PainelFeedbackErro"):
		var p = $Control/FooterColor/MarginContainer/VBoxContainer/PainelFeedbackErro
		p.queue_free()

func _obter_posicao_topo_monstro() -> Vector2:
	var sm = $Control.get_node_or_null("SpriteMonstro")
	if sm:
		var anim = sm.get_node_or_null("AnimatedSprite2D")
		if anim:
			# Centro visual do monstro na arena
			var centro_monstro = sm.position + anim.position
			return Vector2(centro_monstro.x, centro_monstro.y - 95.0)
		return sm.position + Vector2(sm.size.x * 0.5, -40.0)
	return Vector2(875.0, 270.0)

func _mostrar_texto_flutuante_dano_monstro(qtd: int, eh_critico: bool = false) -> void:
	if not has_node("Control"):
		return
		
	var lbl = Label.new()
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.z_index = 40
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	if eh_critico:
		lbl.text = "-%d HP CRÍTICO!" % qtd
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.20)) # Dourado flamejante crítico
		lbl.add_theme_color_override("font_outline_color", Color(0.28, 0.05, 0.0, 0.98))
		lbl.add_theme_constant_override("outline_size", 4)
	else:
		lbl.text = "-%d HP!" % qtd
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.32, 0.32)) # Carmesim de dano
		lbl.add_theme_color_override("font_outline_color", Color(0.18, 0.02, 0.02, 0.95))
		lbl.add_theme_constant_override("outline_size", 3)
		
	if _font_pixel_combate:
		lbl.add_theme_font_override("font", _font_pixel_combate)
		
	var largura_est = 260.0 if eh_critico else 160.0
	lbl.custom_minimum_size = Vector2(largura_est, 30.0)
	lbl.size = Vector2(largura_est, 30.0)
	lbl.pivot_offset = Vector2(largura_est * 0.5, 15.0)
	
	$Control.add_child(lbl)
	
	var pos_topo = _obter_posicao_topo_monstro()
	var spawn_pos = pos_topo - Vector2(largura_est * 0.5, 15.0) + Vector2(randf_range(-14.0, 14.0), randf_range(-5.0, 5.0))
	lbl.position = spawn_pos
	
	var scale_inicial = Vector2(0.5, 0.5) if not eh_critico else Vector2(0.65, 0.65)
	var scale_pop = Vector2(1.35, 1.35) if not eh_critico else Vector2(1.65, 1.65)
	var scale_final = Vector2(1.0, 1.0) if not eh_critico else Vector2(1.15, 1.15)
	var dist_subida = 65.0 if not eh_critico else 85.0
	
	lbl.scale = scale_inicial
	lbl.modulate.a = 0.0
	
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.parallel().tween_property(lbl, "position:y", spawn_pos.y - dist_subida, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "position:x", spawn_pos.x + randf_range(-10.0, 10.0), 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "scale", scale_pop, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 1.0, 0.08)
	tw.tween_property(lbl, "scale", scale_final, 0.12)
	tw.tween_interval(0.35)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.25)
	tw.finished.connect(lbl.queue_free)

func mostrar_texto_flutuante_dano_monstro(qtd: int, eh_critico: bool = false) -> void:
	_mostrar_texto_flutuante_dano_monstro(qtd, eh_critico)

func _mostrar_texto_flutuante_dano_jogador(qtd: int, por_tempo: bool = false) -> void:
	if not has_node("Control"):
		return
		
	var lbl = Label.new()
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.z_index = 40
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	if por_tempo:
		lbl.text = "TEMPO!"
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.20))
		lbl.add_theme_color_override("font_outline_color", Color(0.20, 0.08, 0.0, 0.95))
	else:
		lbl.text = "-%d HP" % qtd
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.28, 0.28))
		lbl.add_theme_color_override("font_outline_color", Color(0.18, 0.02, 0.02, 0.95))
		
	lbl.add_theme_constant_override("outline_size", 3)
	
	if _font_pixel_combate:
		lbl.add_theme_font_override("font", _font_pixel_combate)
		
	var largura_est = 160.0
	lbl.custom_minimum_size = Vector2(largura_est, 30.0)
	lbl.size = Vector2(largura_est, 30.0)
	lbl.pivot_offset = Vector2(largura_est * 0.5, 15.0)
	
	$Control.add_child(lbl)
	
	var pos_mago = $Control.get_node_or_null("PosicaoMago")
	var topo_mago = (pos_mago.position + Vector2(0.0, -90.0)) if pos_mago else Vector2(260.0, 300.0)
	var spawn_pos = topo_mago - Vector2(largura_est * 0.5, 15.0) + Vector2(randf_range(-10.0, 10.0), randf_range(-4.0, 4.0))
	lbl.position = spawn_pos
	
	lbl.scale = Vector2(0.6, 0.6)
	lbl.modulate.a = 0.0
	
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.parallel().tween_property(lbl, "position:y", spawn_pos.y - 55.0, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "scale", Vector2(1.3, 1.3), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 1.0, 0.08)
	tw.tween_property(lbl, "scale", Vector2.ONE, 0.12)
	tw.tween_interval(0.35)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.25)
	tw.finished.connect(lbl.queue_free)

func mostrar_feedback_critico_parry(texto: String, eh_sucesso: bool) -> void:
	var lbl = Label.new()
	lbl.text = texto
	lbl.modulate = Color(0.3, 1.0, 0.5) if eh_sucesso else Color(1.0, 0.3, 0.3)
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 6)
	var font_pixel = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	if font_pixel:
		lbl.add_theme_font_override("font", font_pixel)
	$Control.add_child(lbl)
	
	if eh_sucesso:
		lbl.position = health_enemy.position + Vector2(10, -30)
		var impact_tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		var pos_base_x = $Control/SpriteMonstro.position.x
		impact_tw.tween_property($Control/SpriteMonstro, "position:x", pos_base_x + 12.0, 0.04)
		impact_tw.tween_property($Control/SpriteMonstro, "position:x", pos_base_x - 12.0, 0.04)
		impact_tw.tween_property($Control/SpriteMonstro, "position:x", pos_base_x, 0.04)
	else:
		lbl.position = health_player.position + Vector2(0, -30)
		var shake_tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		shake_tw.tween_property($Control, "position", Vector2(14, -8), 0.035)
		shake_tw.tween_property($Control, "position", Vector2(-14, 8), 0.035)
		shake_tw.tween_property($Control, "position", Vector2.ZERO, 0.035)
		
	# Animação um pouco mais lenta para leitura confortável
	var t_lbl = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t_lbl.tween_property(lbl, "position:y", lbl.position.y - 40, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t_lbl.tween_interval(1.4) # Fica visível para leitura
	t_lbl.tween_property(lbl, "modulate:a", 0.0, 0.50) # Desvanece suavemente
	t_lbl.chain().tween_callback(lbl.queue_free)

static var _cache_dicas_questoes: Dictionary = {}
static var _cache_dicas_por_texto: Dictionary = {}

static func _garantir_cache_dicas() -> void:
	if not _cache_dicas_questoes.is_empty():
		return
	var path = "res://data/questions.json"
	if not FileAccess.file_exists(path):
		return
	var f = FileAccess.open(path, FileAccess.READ)
	if not f:
		return
	var content = f.get_as_text()
	f.close()
	var json = JSON.new()
	if json.parse(content) == OK and json.data is Array:
		for item in json.data:
			if item is Dictionary:
				var dica = str(item.get("dica", "")).strip_edges()
				if not dica.is_empty():
					if item.has("id"):
						_cache_dicas_questoes[int(item["id"])] = dica
					var q_txt = str(item.get("question", "")).strip_edges().to_lower()
					if not q_txt.is_empty():
						_cache_dicas_por_texto[q_txt] = dica

func _obter_explicacao_pergunta(dados: Dictionary, idx_correto: int) -> Dictionary:
	var prefixos = ["A", "B", "C", "D", "E"]
	var opts = dados.get("options", [])
	var txt_resp = ""
	var letra = ""
	if idx_correto >= 0 and idx_correto < opts.size():
		letra = prefixos[idx_correto] if idx_correto < prefixos.size() else ""
		txt_resp = str(opts[idx_correto]).strip_edges()
	
	var explicacao = str(dados.get("dica", "")).strip_edges()
	if explicacao.is_empty():
		explicacao = str(dados.get("explicacao", "")).strip_edges()
		
	# Se a pergunta veio da nuvem (Supabase) sem coluna 'dica', busca na base local de questões
	if explicacao.is_empty():
		_garantir_cache_dicas()
		if dados.has("id") and _cache_dicas_questoes.has(int(dados["id"])):
			explicacao = _cache_dicas_questoes[int(dados["id"])]
		else:
			var q_norm = str(dados.get("question", "")).strip_edges().to_lower()
			if _cache_dicas_por_texto.has(q_norm):
				explicacao = _cache_dicas_por_texto[q_norm]
			else:
				for chave in _cache_dicas_por_texto.keys():
					if chave.begins_with(q_norm.substr(0, mini(30, q_norm.length()))):
						explicacao = _cache_dicas_por_texto[chave]
						break
		
	if explicacao.is_empty():
		var pm = get_node_or_null("/root/PergaminhoManager")
		if pm and pm.has_method("gerar_explicacao_conceitual"):
			explicacao = pm.gerar_explicacao_conceitual(str(dados.get("question", "")), txt_resp, int(dados.get("andar_id", 1)))
			
	if explicacao.is_empty():
		explicacao = "Revise este conceito com atenção para dominar a resposta nas próximas batalhas!"
	else:
		# Limpa barras invertidas escapadas
		explicacao = explicacao.replace('\\"', '"').replace("\\'", "'")
		txt_resp = txt_resp.replace('\\"', '"').replace("\\'", "'")
		# Limpa o sufixo "A resposta é: ..." que vem do formato de dica rápida para evitar repetição
		var regex_resp = RegEx.new()
		regex_resp.compile("(?i)[\\.\\,\\s]*a resposta é:?.*$")
		var explicacao_limpa = regex_resp.sub(explicacao, "").strip_edges()
		if not explicacao_limpa.is_empty():
			explicacao = explicacao_limpa
			if not explicacao.ends_with(".") and not explicacao.ends_with("!") and not explicacao.ends_with("?"):
				explicacao += "."
		
	return {
		"letra": letra,
		"resposta": txt_resp,
		"explicacao": explicacao
	}

func _exibir_feedback_erro(dados: Dictionary, idx_correto: int) -> void:
	var info = _obter_explicacao_pergunta(dados, idx_correto)
	var vbox_footer = $Control/FooterColor/MarginContainer/VBoxContainer
	var container_botoes = vbox_footer.get_node_or_null("HBoxButtons")
	if container_botoes:
		container_botoes.hide()
		
	_fechar_painel_feedback_imediato()
	
	var painel = PanelContainer.new()
	painel.name = "PainelFeedbackErro"
	painel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	painel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	painel.custom_minimum_size = Vector2(0, 120)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.15, 0.98) # Azul/grafite escuro
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.95, 0.72, 0.25, 1.0) # Borda dourada acadêmica
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.shadow_color = Color(0, 0, 0, 0.75)
	sb.shadow_size = 10
	painel.add_theme_stylebox_override("panel", sb)
	
	vbox_footer.add_child(painel)
	
	var vbox_conteudo = VBoxContainer.new()
	vbox_conteudo.add_theme_constant_override("separation", 6)
	painel.add_child(vbox_conteudo)
	
	# Top bar: Ícone e Título + Botão de continuar
	var hbox_top = HBoxContainer.new()
	vbox_conteudo.add_child(hbox_top)
	
	var lbl_titulo = Label.new()
	lbl_titulo.text = "💡 APRENDA COM O ERRO (Revisão Pedagógica)"
	lbl_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_titulo.add_theme_font_size_override("font_size", 13)
	lbl_titulo.add_theme_color_override("font_color", Color(1.0, 0.84, 0.35))
	hbox_top.add_child(lbl_titulo)
	
	var btn_avancar = Button.new()
	btn_avancar.text = " Continuar ▶ (Espaço) "
	btn_avancar.custom_minimum_size = Vector2(185, 28)
	btn_avancar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_avancar.focus_mode = Control.FOCUS_ALL
	
	var sb_btn_normal = StyleBoxFlat.new()
	sb_btn_normal.bg_color = Color(0.18, 0.24, 0.38, 0.95)
	sb_btn_normal.border_color = Color(0.4, 0.75, 1.0)
	sb_btn_normal.set_border_width_all(1)
	sb_btn_normal.set_corner_radius_all(4)
	sb_btn_normal.content_margin_left = 10
	sb_btn_normal.content_margin_right = 10
	
	var sb_btn_hover = StyleBoxFlat.new()
	sb_btn_hover.bg_color = Color(0.26, 0.40, 0.65, 1.0)
	sb_btn_hover.border_color = Color(0.7, 0.9, 1.0)
	sb_btn_hover.set_border_width_all(1)
	sb_btn_hover.set_corner_radius_all(4)
	sb_btn_hover.content_margin_left = 10
	sb_btn_hover.content_margin_right = 10
	
	var sb_btn_pressed = StyleBoxFlat.new()
	sb_btn_pressed.bg_color = Color(0.12, 0.16, 0.26, 1.0)
	sb_btn_pressed.border_color = Color(0.3, 0.6, 0.8)
	sb_btn_pressed.set_border_width_all(1)
	sb_btn_pressed.set_corner_radius_all(4)
	sb_btn_pressed.content_margin_left = 10
	sb_btn_pressed.content_margin_right = 10
	
	btn_avancar.add_theme_stylebox_override("normal", sb_btn_normal)
	btn_avancar.add_theme_stylebox_override("hover", sb_btn_hover)
	btn_avancar.add_theme_stylebox_override("focus", sb_btn_hover)
	btn_avancar.add_theme_stylebox_override("pressed", sb_btn_pressed)
	btn_avancar.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	btn_avancar.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	btn_avancar.add_theme_font_size_override("font_size", 12)
	hbox_top.add_child(btn_avancar)
	
	var sep = HSeparator.new()
	vbox_conteudo.add_child(sep)
	
	# Resposta Correta
	var lbl_resp = RichTextLabel.new()
	lbl_resp.bbcode_enabled = true
	lbl_resp.fit_content = true
	lbl_resp.scroll_active = false
	var prefixo_letra = (info["letra"] + ") ") if not info["letra"].is_empty() else ""
	lbl_resp.text = "[color=#55ff88][b]✓ Resposta correta:[/b][/color] [color=#ffffff][b]%s%s[/b][/color]" % [prefixo_letra, info["resposta"]]
	lbl_resp.add_theme_font_size_override("normal_font_size", 14)
	vbox_conteudo.add_child(lbl_resp)
	
	# Explicação Pedagógica
	var lbl_desc = RichTextLabel.new()
	lbl_desc.bbcode_enabled = true
	lbl_desc.fit_content = true
	lbl_desc.scroll_active = false
	lbl_desc.text = "[color=#ffd060][b]📖 Explicação:[/b][/color] [color=#eeeeee]%s[/color]" % [info["explicacao"]]
	lbl_desc.add_theme_font_size_override("normal_font_size", 13)
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox_conteudo.add_child(lbl_desc)
	
	# Dica discreta de controle no rodapé (sem timer automático)
	var lbl_dica_rodape = Label.new()
	lbl_dica_rodape.text = "[ Pressione Espaço, Enter ou clique em Continuar quando terminar de ler ]"
	lbl_dica_rodape.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_dica_rodape.add_theme_font_size_override("font_size", 10)
	lbl_dica_rodape.add_theme_color_override("font_color", Color(0.65, 0.75, 0.9, 0.7))
	vbox_conteudo.add_child(lbl_dica_rodape)
	
	var font_sans = SystemFont.new()
	font_sans.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_sans.font_weight = 400

	var font_bold = SystemFont.new()
	font_bold.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_bold.font_weight = 700

	lbl_titulo.add_theme_font_override("font", font_bold)
	btn_avancar.add_theme_font_override("font", font_bold)
	lbl_resp.add_theme_font_override("normal_font", font_sans)
	lbl_resp.add_theme_font_override("bold_font", font_bold)
	lbl_resp.add_theme_font_size_override("bold_font_size", 14)
	lbl_desc.add_theme_font_override("normal_font", font_sans)
	lbl_desc.add_theme_font_override("bold_font", font_bold)
	lbl_desc.add_theme_font_size_override("bold_font_size", 14)
	lbl_dica_rodape.add_theme_font_override("font", font_sans)

	# Efeito suave de entrada
	painel.modulate.a = 0.0
	painel.scale = Vector2(0.97, 0.97)
	painel.pivot_offset = Vector2(400, 50)
	var tw_in = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw_in.tween_property(painel, "modulate:a", 1.0, 0.20)
	tw_in.tween_property(painel, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx("ui_5")
		
	var finalizado = [false]
	var fechar_caixa = func():
		if finalizado[0]: return
		finalizado[0] = true
		if is_instance_valid(painel):
			var tw_out = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw_out.tween_property(painel, "modulate:a", 0.0, 0.15)
			tw_out.tween_property(painel, "scale", Vector2(0.96, 0.96), 0.15)
			tw_out.chain().tween_callback(func():
				if is_instance_valid(painel):
					painel.queue_free()
			)
			
	btn_avancar.pressed.connect(fechar_caixa)
	
	# Debounce inicial curto para garantir que cliques/teclas da resposta anterior não fechem a caixa por acidente
	await get_tree().create_timer(0.25, true).timeout
	if is_instance_valid(btn_avancar):
		btn_avancar.grab_focus()
	
	# Loop aguardando leitura do jogador em seu próprio tempo (sem timer automático)
	while not finalizado[0] and is_instance_valid(painel):
		await get_tree().process_frame
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_select") or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_ENTER):
			fechar_caixa.call()
			break
			
	await get_tree().create_timer(0.2, true).timeout

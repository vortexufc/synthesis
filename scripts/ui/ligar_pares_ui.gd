extends CanvasLayer

# minigame de ligar pares

signal conexao_concluida(vitoria: bool)

var andar_id: int = 1
var ordem_sala: int = 1
var qtd_pares: int = 3
var duracao_total: float = 20.0
var tempo_restante: float = 20.0
var jogo_ativo: bool = false
var bloqueio_input: bool = false
var _finalizado: bool = false

var pares_conectados: int = 0
var bloco_selecionado: Button = null
var bloco_hover_alvo: Button = null
var esta_arrastando: bool = false
var pos_inicio_arrasto: Vector2 = Vector2.ZERO
var tick_selecao: int = 0
var linhas_animadas: Array = []
var tempo_anim_global: float = 0.0

# referencias da interface
var backdrop: ColorRect
var particulas_fundo: CPUParticles2D
var painel_central: PanelContainer
var lbl_titulo: Label
var lbl_sub: Label
var lbl_col_a: Label
var lbl_col_b: Label
var overlay_conexoes: Control
var lbl_timer: Label
var progress_timer: ProgressBar
var lbl_pares: Label
var col_a_container: VBoxContainer
var col_b_container: VBoxContainer
var banner_resultado: PanelContainer
var lbl_banner_emblema: Label
var lbl_banner_titulo: Label
var lbl_banner_sub: Label
var box_banner_recompensas: HBoxContainer
var btn_banner_continuar: Button
var _fechamento_iniciado: bool = false
var _ultimo_foi_vitoria: bool = false

# Identidade visual e temática por disciplina (Harmonizada com o Menu de Perguntas da Batalha)
const TEMAS = {
	1: { # Andar 1: Laboratório de Alquimia / Química (Base Safira Arcana da Batalha & Ácido Púrpura Fluorescente)
		"nome": "Química",
		"titulo": "🧪 SÍNTESE CÁUSTICA: CORROSÃO ALQUÍMICA 🧪",
		"subtitulo": "Canalize o fluxo de ácido cáustico ligando os reagentes e propriedades correspondentes!",
		"col_a_titulo": "🧪 REAGENTE / SÍMBOLO 🧪",
		"col_b_titulo": "🧪 PROPRIEDADE / COMPOSTO 🧪",
		"cor_primaria": Color(0.78, 0.38, 1.0),       # Roxo Ácido Fluorescente (elimina qualquer aspecto aquático)
		"cor_secundaria": Color(0.92, 0.65, 1.0),     # Lilás Reluzente / Efervescência
		"cor_terciaria": Color(0.48, 0.20, 0.85),     # Ametista / Índigo Alquímico
		"cor_painel_bg": Color(0.04, 0.05, 0.22, 0.98), # Safira Arcana Profunda (base do menu da batalha)
		"cor_painel_borda": Color(0.70, 0.42, 1.0),   # Friso Alquímico Violeta
		"cor_painel_sombra": Color(0.55, 0.20, 0.95, 0.45), # Glow de névoa de vapor cáustico púrpura
		"cor_col_a": Color(0.75, 0.45, 1.0),         # Roxo vivo (Coluna A)
		"cor_col_b": Color(0.92, 0.65, 1.0),          # Lilás reluzente (Coluna B)
		"btn_bg": Color(0.05, 0.08, 0.24, 0.94),      # Safira Arcana da batalha
		"btn_border": Color(0.45, 0.38, 0.85, 0.90),  # Borda Safira Violeta
		"btn_hover_bg": Color(0.16, 0.12, 0.38, 0.98), # Hover Índigo profundo
		"btn_hover_border": Color(0.85, 0.45, 1.0, 1.0), # Roxo ácido reluzente
		"btn_correct_border": Color(0.92, 0.55, 1.0, 1.0), # Acerto de Vitríolo Cáustico
		"particulas_cor": Color(0.75, 0.35, 1.0, 0.35), # Vapores e bolhas de ácido roxo
		"particulas_grav": Vector2(0, -32),
		"particulas_vel_min": 15.0,
		"particulas_vel_max": 40.0,
		"emblema_vitoria": "🧪  CORROSÃO ALQUÍMICA TOTAL  🧪",
		"titulo_vitoria": "SOLUÇÃO ÁCIDA DISSOLVEU A BARREIRA!",
		"sub_vitoria": "O vitríolo púrpura consumiu a blindagem do Campeão Rúnico!",
		"emblema_derrota": "⚠️  VAPOR ÁCIDO INSTÁVEL  ⚠️",
		"titulo_derrota": "REAÇÃO DESCONTROLADA!",
		"sub_derrota": "O ácido transbordou e respingos cáusticos atingiram o conjurador!",
		"card_1_ico": "☣️",
		"card_1_tit": "Corrosão Perfurante",
		"card_1_desc": "-40 HP no Campeão Rúnico",
		"card_2_ico": "⚗️",
		"card_2_tit": "Vitríolo Cáustico",
		"card_2_desc": "Blindagem Dissolvida!",
	},
	2: { # Andar 2: Oficina de Física / Cobre Aquecido / Forja / Eletromagnetismo
		"nome": "Física",
		"titulo": "⚡ CONEXÃO ELÉTRICA: SOBRECARGA MAGNÉTICA ⚡",
		"subtitulo": "Feche o circuito conectando as grandezas e fenômenos correspondentes!",
		"col_a_titulo": "⚡ CIRCUITO / GRANDEZA ⚡",
		"col_b_titulo": "⚡ UNIDADE / FENÔMENO ⚡",
		"cor_primaria": Color(0.15, 0.95, 1.0),       # ⚡ Arco Voltaico Cyan Elétrico (btn_hover_border da batalha)
		"cor_secundaria": Color(0.95, 0.52, 0.16),     # Friso de Cobre Polido / Âmbar da Forja (question_border da batalha)
		"cor_terciaria": Color(0.19, 0.11, 0.08),     # Placa de Forja da batalha
		"cor_painel_bg": Color(0.13, 0.08, 0.06, 0.98), # Cobre Escuro / Marrom Forja (footer da batalha)
		"cor_painel_borda": Color(0.95, 0.52, 0.16),   # Friso de Cobre Polido da batalha
		"cor_painel_sombra": Color(0.90, 0.45, 0.12, 0.45), # Glow âmbar da forja
		"cor_col_a": Color(0.95, 0.55, 0.20),         # Cobre polido / Âmbar (Coluna A)
		"cor_col_b": Color(0.20, 0.92, 1.0),          # Arco Cyan de Alta Voltagem (Coluna B)
		"btn_bg": Color(0.15, 0.09, 0.07, 0.94),      # Bronze escuro da batalha
		"btn_border": Color(0.55, 0.32, 0.16, 0.90),  # Borda de bronze oxidado da batalha
		"btn_hover_bg": Color(0.28, 0.16, 0.10, 0.98), # Cobre aquecido sob corrente da batalha
		"btn_hover_border": Color(0.15, 0.95, 1.0, 1.0), # ⚡ Arco Voltaico Cyan Elétrico da batalha
		"btn_correct_border": Color(0.15, 1.0, 0.88, 1.0), # Neon de Alta Voltagem da batalha
		"particulas_cor": Color(0.95, 0.55, 0.18, 0.35), # Centelhas de forja e faíscas
		"particulas_grav": Vector2(0, -12),
		"particulas_vel_min": 20.0,
		"particulas_vel_max": 50.0,
		"emblema_vitoria": "⚡  SOBRECARGA DE ALTA VOLTAGEM  ⚡",
		"titulo_vitoria": "CIRCUITO FECHADO COM SUCESSO!",
		"sub_vitoria": "A sobrecarga elétrica destruiu a barreira do campeão!",
		"emblema_derrota": "⚠️  CURTO-CIRCUITO CRÍTICO  ⚠️",
		"titulo_derrota": "CIRCUITO ROMPIDO!",
		"sub_derrota": "A sobretensão falhou e o arco elétrico atingiu o conjurador!",
		"card_1_ico": "⚡",
		"card_1_tit": "Descarga de Arco",
		"card_1_desc": "-40 HP no Campeão Rúnico",
		"card_2_ico": "🧲",
		"card_2_tit": "Indução Magnética",
		"card_2_desc": "Blindagem Rompida!",
	},
	3: { # Andar 3: Estufa de Biologia / Botânica / Pólen Solar & Floração Viva
		"nome": "Biologia",
		"titulo": "🌿 SIMBIOSE BOTÂNICA: ELO ORGÂNICO 🌿",
		"subtitulo": "Entrelace as vinhas e raízes entre os termos biológicos correspondentes!",
		"col_a_titulo": "🌿 ESTRUTURA / TERMO 🌿",
		"col_b_titulo": "🌿 FUNÇÃO / CONCEITO 🌿",
		"cor_primaria": Color(0.30, 0.85, 0.30),       # Verde Esmeralda Vivo (question_border da batalha)
		"cor_secundaria": Color(1.0, 0.84, 0.18),     # 🌻 Pólen Solar Dourado / Âmbar Radiante (btn_hover_border da batalha)
		"cor_terciaria": Color(0.06, 0.15, 0.08),     # Verde Musgo Escuro (question_bg da batalha)
		"cor_painel_bg": Color(0.04, 0.10, 0.05, 0.98), # Verde Floresta Escuro (footer da batalha)
		"cor_painel_borda": Color(0.30, 0.85, 0.30),   # Friso Verde Esmeralda da batalha
		"cor_painel_sombra": Color(0.15, 0.70, 0.25, 0.40), # Glow botânico vivo
		"cor_col_a": Color(0.35, 0.88, 0.35),         # Verde esmeralda vivo (Coluna A)
		"cor_col_b": Color(1.0, 0.84, 0.20),          # Pólen Solar Dourado (Coluna B)
		"btn_bg": Color(0.06, 0.14, 0.08, 0.94),      # Fundo verde musgo da batalha
		"btn_border": Color(0.22, 0.46, 0.24, 0.90),  # Borda verde folha da batalha
		"btn_hover_bg": Color(0.22, 0.19, 0.05, 0.98), # 🌻 Pólen Solar Dourado da batalha
		"btn_hover_border": Color(1.0, 0.84, 0.18, 1.0), # Âmbar Radiante da batalha
		"btn_correct_border": Color(0.98, 0.88, 0.20, 1.0), # Borda Dourada Solar brilhante da batalha
		"particulas_cor": Color(0.35, 0.85, 0.35, 0.35), # Folhas e esporos
		"particulas_grav": Vector2(0, 14),
		"particulas_vel_min": 10.0,
		"particulas_vel_max": 25.0,
		"emblema_vitoria": "🌿  RESSONÂNCIA BIOLÓGICA  🌿",
		"titulo_vitoria": "SIMBIOSE VITAL ESTABELECIDA!",
		"sub_vitoria": "A expansão das raízes orgânicas destruiu a barreira!",
		"emblema_derrota": "🥀  DETERIORAÇÃO VEGETAL  🥀",
		"titulo_derrota": "VINHAS RESSECADAS!",
		"sub_derrota": "O crescimento foi interrompido e espinhos atingiram o conjurador!",
		"card_1_ico": "🍃",
		"card_1_tit": "Esmagamento de Raízes",
		"card_1_desc": "-40 HP no Campeão Rúnico",
		"card_2_ico": "🌱",
		"card_2_tit": "Drenagem Orgânica",
		"card_2_desc": "Blindagem Consumida!",
	}
}

func _obter_tema() -> Dictionary:
	return TEMAS.get(andar_id, TEMAS[1])

# pares por materia
const PARES_POR_ANDAR = {
	1: [ # Química (Andar 1)
		{"termo_a": "H₂O", "termo_b": "Água"},
		{"termo_a": "Fe", "termo_b": "Ferro"},
		{"termo_a": "O₂", "termo_b": "Oxigênio"},
		{"termo_a": "NaCl", "termo_b": "Sal de Cozinha"},
		{"termo_a": "CO₂", "termo_b": "Gás Carbônico"},
		{"termo_a": "Au", "termo_b": "Ouro"},
		{"termo_a": "Ag", "termo_b": "Prata"},
		{"termo_a": "Cu", "termo_b": "Cobre"},
		{"termo_a": "He", "termo_b": "Hélio (Gás Nobre)"},
		{"termo_a": "pH < 7", "termo_b": "Meio Ácido"},
		{"termo_a": "pH > 7", "termo_b": "Meio Básico / Alcalino"},
		{"termo_a": "pH = 7", "termo_b": "Meio Neutro"},
		{"termo_a": "Próton", "termo_b": "Carga Positiva (+)"},
		{"termo_a": "Elétron", "termo_b": "Carga Negativa (-)"},
		{"termo_a": "Nêutron", "termo_b": "Sem Carga (Neutro)"},
		{"termo_a": "Fusão", "termo_b": "Sólido → Líquido"},
		{"termo_a": "Evaporação", "termo_b": "Líquido → Gás"},
		{"termo_a": "Condensação", "termo_b": "Gás → Líquido"},
		{"termo_a": "Solidificação", "termo_b": "Líquido → Sólido"},
		{"termo_a": "Sublimação", "termo_b": "Sólido ⇄ Gás"},
		{"termo_a": "Exotérmica", "termo_b": "Libera Calor"},
		{"termo_a": "Endotérmica", "termo_b": "Absorve Calor"},
		{"termo_a": "Oxidação", "termo_b": "Perda de Elétrons"},
		{"termo_a": "Redução", "termo_b": "Ganho de Elétrons"}
	],
	2: [ # Física (Andar 2)
		{"termo_a": "Joule (J)", "termo_b": "Energia / Trabalho"},
		{"termo_a": "Newton (N)", "termo_b": "Força"},
		{"termo_a": "Volt (V)", "termo_b": "Tensão Elétrica"},
		{"termo_a": "Ampère (A)", "termo_b": "Corrente Elétrica"},
		{"termo_a": "Ohm (Ω)", "termo_b": "Resistência Elétrica"},
		{"termo_a": "Watt (W)", "termo_b": "Potência Elétrica"},
		{"termo_a": "m/s²", "termo_b": "Aceleração"},
		{"termo_a": "m/s", "termo_b": "Velocidade"},
		{"termo_a": "Hertz (Hz)", "termo_b": "Frequência"},
		{"termo_a": "Gravidade (g)", "termo_b": "Aceleração Terrestre (~9.8 m/s²)"},
		{"termo_a": "Fóton", "termo_b": "Partícula de Luz"},
		{"termo_a": "Inércia", "termo_b": "1ª Lei de Newton"},
		{"termo_a": "Ação e Reação", "termo_b": "3ª Lei de Newton"},
		{"termo_a": "F = m · a", "termo_b": "2ª Lei de Newton"},
		{"termo_a": "Refração", "termo_b": "Desvio da Luz entre Meios"},
		{"termo_a": "Reflexão", "termo_b": "Bate e Retorna"},
		{"termo_a": "Eco", "termo_b": "Reflexão do Som"},
		{"termo_a": "Calor", "termo_b": "Energia Térmica em Trânsito"},
		{"termo_a": "Temperatura", "termo_b": "Agitação Molecular"},
		{"termo_a": "Condutor", "termo_b": "Permite Fluxo de Cargas"},
		{"termo_a": "Isolante", "termo_b": "Dificulta Fluxo de Cargas"},
		{"termo_a": "Óptica", "termo_b": "Estudo da Luz"},
		{"termo_a": "Onda Sonora", "termo_b": "Onda Mecânica Longitudinal"},
		{"termo_a": "Energia Cinética", "termo_b": "Energia do Movimento"}
	],
	3: [ # Biologia (Andar 3)
		{"termo_a": "Mitocôndria", "termo_b": "Respiração Celular / ATP"},
		{"termo_a": "Cloroplasto", "termo_b": "Fotossíntese"},
		{"termo_a": "Ribossomo", "termo_b": "Síntese Proteica"},
		{"termo_a": "DNA", "termo_b": "Código Genético"},
		{"termo_a": "RNA", "termo_b": "Transcrição / Tradução"},
		{"termo_a": "Hemoglobina", "termo_b": "Transporte de Oxigênio (O₂)"},
		{"termo_a": "Neurônio", "termo_b": "Impulso Nervoso"},
		{"termo_a": "Membrana", "termo_b": "Permeabilidade Seletiva"},
		{"termo_a": "Vacúolo", "termo_b": "Armazenamento Celular"},
		{"termo_a": "Lisossomo", "termo_b": "Digestão Intracelular"},
		{"termo_a": "Complexo Golgi", "termo_b": "Secreção Celular"},
		{"termo_a": "Enzima", "termo_b": "Catalisador Biológico"},
		{"termo_a": "Ecossistema", "termo_b": "Comunidade + Ambiente"},
		{"termo_a": "Glicose", "termo_b": "Fonte Primária de Energia"},
		{"termo_a": "Fotossíntese", "termo_b": "Luz + CO₂ → Glicose + O₂"},
		{"termo_a": "Glóbulos Brancos", "termo_b": "Defesa Imunológica"},
		{"termo_a": "Plaquetas", "termo_b": "Coagulação Sanguínea"},
		{"termo_a": "Mitose", "termo_b": "Divisão Celular Equacional"},
		{"termo_a": "Meiose", "termo_b": "Formação de Gametas"},
		{"termo_a": "Autótrofos", "termo_b": "Produzem Próprio Alimento"},
		{"termo_a": "Heterótrofos", "termo_b": "Consomem Outros Seres"},
		{"termo_a": "Xilema", "termo_b": "Seiva Bruta (Água / Sais)"},
		{"termo_a": "Floema", "termo_b": "Seiva Elaborada (Açúcares)"},
		{"termo_a": "Sinapse", "termo_b": "Comunicação entre Neurônios"}
	]
}

func _ready() -> void:
	add_to_group("minigame_ativo")
	add_to_group("interacao_ativa")
	layer = 105
	process_mode = Node.PROCESS_MODE_ALWAYS
	if col_a_container == null:
		_construir_interface()

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not is_inside_tree():
		return
		
	if banner_resultado and banner_resultado.visible:
		if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_F)):
			get_viewport().set_input_as_handled()
			_ao_clicar_continuar()
			return
			
	if not jogo_ativo or bloqueio_input or _finalizado:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if bloco_selecionado != null:
			_desselecionar_bloco()
		return
	if event is InputEventMouseButton:
		if not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if esta_arrastando:
				_ao_soltar_arrasto()
	if event is InputEventKey:
		var key = event as InputEventKey
		if key.pressed and (key.keycode == KEY_F or key.physical_keycode == KEY_F or key.key_label == KEY_F):
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled()
		return

func _process(delta: float) -> void:
	if not jogo_ativo:
		return
		
	tempo_anim_global += delta
	tempo_restante -= delta
	if tempo_restante < 0.0:
		tempo_restante = 0.0
		
	_atualizar_timer_ui()
	
	# Detecta o bloco alvo sob o cursor na coluna oposta
	if is_instance_valid(bloco_selecionado) and not bloqueio_input:
		var vp = get_viewport()
		var mouse_pos = vp.get_mouse_position() if vp else Vector2.ZERO
		var novo_alvo = _obter_bloco_sob_posicao(mouse_pos)
		if novo_alvo != bloco_hover_alvo:
			bloco_hover_alvo = novo_alvo
			if bloco_hover_alvo != null:
				_tocar_sfx("ui-1")
	else:
		bloco_hover_alvo = null
		
	# Atualiza linhas de conexoes concluidas em animacao
	var linhas_vivas: Array = []
	for l in linhas_animadas:
		l.tempo += delta
		if l.tempo < l.duracao:
			linhas_vivas.append(l)
	linhas_animadas = linhas_vivas
	
	# Redesenha a camada de conexões e nós a cada frame
	if is_instance_valid(overlay_conexoes):
		overlay_conexoes.queue_redraw()
	
	if tempo_restante <= 0.0:
		_finalizar_derrota()

# inicia o minigame com base no andar e ordem da sala
func iniciar_conexao(p_andar_id: int = 1, p_ordem_sala: int = -1) -> void:
	if col_a_container == null:
		_construir_interface()
		
	andar_id = p_andar_id

	# Configura a dificuldade de acordo com a ordem da sala na run atual
	var cfg = {
		"ordem": 1,
		"fase": "inicial",
		"ligar_pares": 3,
		"ligar_tempo": 20.0
	}
	var dg = get_node_or_null("/root/DungeonGenerator")
	if dg and dg.has_method("get_config_dificuldade_minigames"):
		var cena_path = ""
		if get_tree() and get_tree().current_scene:
			cena_path = get_tree().current_scene.scene_file_path
		cfg = dg.get_config_dificuldade_minigames(cena_path, p_ordem_sala)
	elif p_ordem_sala >= 8:
		cfg["ordem"] = p_ordem_sala
		cfg["fase"] = "dificil"
		cfg["ligar_pares"] = 5
		cfg["ligar_tempo"] = 24.0
	elif p_ordem_sala >= 4:
		cfg["ordem"] = p_ordem_sala
		cfg["fase"] = "medio"
		cfg["ligar_pares"] = 4
		cfg["ligar_tempo"] = 28.0

	ordem_sala = int(cfg.get("ordem", 1))
	qtd_pares = int(cfg.get("ligar_pares", 3))
	duracao_total = float(cfg.get("ligar_tempo", 20.0))
	tempo_restante = duracao_total
	pares_conectados = 0
	bloco_selecionado = null
	bloco_hover_alvo = null
	esta_arrastando = false
	bloqueio_input = false
	_finalizado = false
	linhas_animadas.clear()
	tempo_anim_global = 0.0
	if banner_resultado:
		banner_resultado.visible = false
	
	print("[LigarPares] Configurado para Sala %d (Fase: %s) -> %d pares, tempo: %.1fs" % [ordem_sala, cfg.get("fase", "inicial"), qtd_pares, duracao_total])

	_aplicar_tema_disciplina()

	if progress_timer:
		progress_timer.max_value = duracao_total
		progress_timer.value = duracao_total

	_gerar_blocos()
	_atualizar_timer_ui()
	if lbl_pares:
		lbl_pares.text = "CONECTADOS: 0 / %d" % qtd_pares
	jogo_ativo = true
	
	if painel_central:
		painel_central.modulate.a = 0.0
		painel_central.scale = Vector2(0.85, 0.85)
		if backdrop:
			backdrop.modulate.a = 0.0
		var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		if backdrop:
			tween.tween_property(backdrop, "modulate:a", 1.0, 0.20)
		tween.tween_property(painel_central, "modulate:a", 1.0, 0.25)
		tween.tween_property(painel_central, "scale", Vector2(1.0, 1.0), 0.28)

	_tocar_sfx("ui_5")

func _aplicar_tema_disciplina() -> void:
	var tema = _obter_tema()
	
	if is_instance_valid(backdrop):
		var bg_tint = tema.get("cor_painel_bg", Color(0.04, 0.03, 0.08, 0.88))
		backdrop.color = Color(bg_tint.r * 0.35, bg_tint.g * 0.35, bg_tint.b * 0.35, 0.88)
	
	if is_instance_valid(lbl_titulo):
		lbl_titulo.text = tema.get("titulo", "")
		lbl_titulo.add_theme_color_override("font_color", tema.get("cor_secundaria", Color.WHITE))
	if is_instance_valid(lbl_sub):
		lbl_sub.text = tema.get("subtitulo", "")
	if is_instance_valid(lbl_col_a):
		lbl_col_a.text = tema.get("col_a_titulo", "")
		lbl_col_a.add_theme_color_override("font_color", tema.get("cor_col_a", Color.WHITE))
	if is_instance_valid(lbl_col_b):
		lbl_col_b.text = tema.get("col_b_titulo", "")
		lbl_col_b.add_theme_color_override("font_color", tema.get("cor_col_b", Color.WHITE))
		
	if is_instance_valid(painel_central):
		var sb_panel = painel_central.get_theme_stylebox("panel") as StyleBoxFlat
		if sb_panel:
			sb_panel.bg_color = tema.get("cor_painel_bg", Color(0.07, 0.06, 0.13, 0.98))
			sb_panel.border_color = tema.get("cor_painel_borda", Color(1.0, 0.85, 0.3))
			sb_panel.shadow_color = tema.get("cor_painel_sombra", Color(0.6, 0.2, 0.9, 0.4))
			
	if is_instance_valid(particulas_fundo):
		particulas_fundo.color = tema.get("particulas_cor", Color(1.0, 0.85, 0.45, 0.30))
		particulas_fundo.gravity = tema.get("particulas_grav", Vector2(0, -16))
		particulas_fundo.initial_velocity_min = float(tema.get("particulas_vel_min", 15.0))
		particulas_fundo.initial_velocity_max = float(tema.get("particulas_vel_max", 40.0))

func _construir_interface() -> void:
	backdrop = ColorRect.new()
	backdrop.color = Color(0.04, 0.03, 0.08, 0.88)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(_ao_gui_input_backdrop)
	add_child(backdrop)
	
	# Partículas de poeira mágica / fluidos flutuando no fundo
	particulas_fundo = CPUParticles2D.new()
	particulas_fundo.name = "ParticulasFundo"
	particulas_fundo.amount = 26
	particulas_fundo.lifetime = 4.0
	particulas_fundo.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particulas_fundo.emission_rect_extents = Vector2(640, 360)
	particulas_fundo.position = Vector2(640, 360)
	particulas_fundo.gravity = Vector2(0, -16)
	particulas_fundo.scale_amount_min = 1.5
	particulas_fundo.scale_amount_max = 3.5
	particulas_fundo.color = Color(1.0, 0.85, 0.45, 0.30)
	backdrop.add_child(particulas_fundo)
	
	var font_sans = SystemFont.new()
	font_sans.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_sans.font_weight = 600

	var font_titulo = SystemFont.new()
	font_titulo.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_titulo.font_weight = 700

	# container central
	var center_painel = CenterContainer.new()
	center_painel.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(center_painel)

	painel_central = PanelContainer.new()
	painel_central.custom_minimum_size = Vector2(880, 540)
	painel_central.pivot_offset = Vector2(440, 270)
	
	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = Color(0.07, 0.06, 0.13, 0.98)
	style_panel.border_width_left = 3
	style_panel.border_width_right = 3
	style_panel.border_width_top = 3
	style_panel.border_width_bottom = 3
	style_panel.border_color = Color(1.0, 0.85, 0.3)
	style_panel.corner_radius_top_left = 12
	style_panel.corner_radius_top_right = 12
	style_panel.corner_radius_bottom_left = 12
	style_panel.corner_radius_bottom_right = 12
	style_panel.shadow_color = Color(0.6, 0.2, 0.9, 0.4)
	style_panel.shadow_size = 24
	style_panel.content_margin_left = 28
	style_panel.content_margin_right = 28
	style_panel.content_margin_top = 20
	style_panel.content_margin_bottom = 20
	painel_central.add_theme_stylebox_override("panel", style_panel)
	center_painel.add_child(painel_central)
	
	var vbox_main = VBoxContainer.new()
	vbox_main.add_theme_constant_override("separation", 10)
	painel_central.add_child(vbox_main)
	
	# cabecalho
	var vbox_titulos = VBoxContainer.new()
	vbox_titulos.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_titulos.add_theme_constant_override("separation", 2)
	vbox_main.add_child(vbox_titulos)
	
	lbl_titulo = Label.new()
	lbl_titulo.text = "CONEXÃO: QUEBRA DE BARREIRA"
	lbl_titulo.add_theme_font_override("font", font_titulo)
	lbl_titulo.add_theme_font_size_override("font_size", 20)
	lbl_titulo.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_titulos.add_child(lbl_titulo)
	
	lbl_sub = Label.new()
	lbl_sub.text = "Conecte os nós dos blocos correspondentes por clique ou arrasto!"
	lbl_sub.add_theme_font_override("font", font_sans)
	lbl_sub.add_theme_font_size_override("font_size", 14)
	lbl_sub.add_theme_color_override("font_color", Color(0.75, 0.82, 0.98))
	lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_titulos.add_child(lbl_sub)
	
	# separador
	vbox_main.add_child(HSeparator.new())
	
	# tempo e instrucoes
	var hbox_status = HBoxContainer.new()
	hbox_status.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_status.add_theme_constant_override("separation", 24)
	vbox_main.add_child(hbox_status)
	
	lbl_timer = Label.new()
	lbl_timer.text = "TEMPO: 20.0s"
	lbl_timer.add_theme_font_override("font", font_titulo)
	lbl_timer.add_theme_font_size_override("font_size", 16)
	lbl_timer.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	hbox_status.add_child(lbl_timer)
	
	progress_timer = ProgressBar.new()
	progress_timer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_timer.custom_minimum_size = Vector2(250, 16)
	progress_timer.max_value = duracao_total
	progress_timer.value = duracao_total
	progress_timer.show_percentage = false
	
	var sb_fill = StyleBoxFlat.new()
	sb_fill.bg_color = Color(0.2, 0.75, 1.0)
	sb_fill.corner_radius_top_left = 6
	sb_fill.corner_radius_top_right = 6
	sb_fill.corner_radius_bottom_left = 6
	sb_fill.corner_radius_bottom_right = 6
	progress_timer.add_theme_stylebox_override("fill", sb_fill)
	
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.12, 0.10, 0.20, 0.9)
	sb_bg.corner_radius_top_left = 6
	sb_bg.corner_radius_top_right = 6
	sb_bg.corner_radius_bottom_left = 6
	sb_bg.corner_radius_bottom_right = 6
	progress_timer.add_theme_stylebox_override("background", sb_bg)
	hbox_status.add_child(progress_timer)
	
	lbl_pares = Label.new()
	lbl_pares.text = "CONECTADOS: 0 / %d" % qtd_pares
	lbl_pares.add_theme_font_override("font", font_titulo)
	lbl_pares.add_theme_font_size_override("font_size", 16)
	lbl_pares.add_theme_color_override("font_color", Color(0.95, 0.82, 0.35))
	hbox_status.add_child(lbl_pares)
	
	# duas colunas de blocos com cabeçalhos e canal central de ligação amplo
	var hbox_colunas = HBoxContainer.new()
	hbox_colunas.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_colunas.add_theme_constant_override("separation", 170)
	hbox_colunas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox_main.add_child(hbox_colunas)
	
	# Coluna A (Termos / Símbolos)
	var vbox_col_a = VBoxContainer.new()
	vbox_col_a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_col_a.add_theme_constant_override("separation", 8)
	hbox_colunas.add_child(vbox_col_a)
	
	lbl_col_a = Label.new()
	lbl_col_a.text = "◆ TERMO / SÍMBOLO ◆"
	lbl_col_a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_col_a.add_theme_font_override("font", font_titulo)
	lbl_col_a.add_theme_font_size_override("font_size", 13)
	lbl_col_a.add_theme_color_override("font_color", Color(0.78, 0.58, 1.0))
	vbox_col_a.add_child(lbl_col_a)
	
	col_a_container = VBoxContainer.new()
	col_a_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_a_container.add_theme_constant_override("separation", 16)
	col_a_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_col_a.add_child(col_a_container)
	
	# Coluna B (Conceitos / Significados)
	var vbox_col_b = VBoxContainer.new()
	vbox_col_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_col_b.add_theme_constant_override("separation", 8)
	hbox_colunas.add_child(vbox_col_b)
	
	lbl_col_b = Label.new()
	lbl_col_b.text = "◆ CONCEITO / SIGNIFICADO ◆"
	lbl_col_b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_col_b.add_theme_font_override("font", font_titulo)
	lbl_col_b.add_theme_font_size_override("font_size", 13)
	lbl_col_b.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	vbox_col_b.add_child(lbl_col_b)
	
	col_b_container = VBoxContainer.new()
	col_b_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_b_container.add_theme_constant_override("separation", 16)
	col_b_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_col_b.add_child(col_b_container)
	
	# Camada de desenho das linhas e nós de ligação
	overlay_conexoes = Control.new()
	overlay_conexoes.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_conexoes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel_central.add_child(overlay_conexoes)
	overlay_conexoes.draw.connect(_desenhar_camada_conexoes.bind(overlay_conexoes))
	
	# aviso de resultado
	var center_banner = CenterContainer.new()
	center_banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(center_banner)
	
	banner_resultado = PanelContainer.new()
	banner_resultado.custom_minimum_size = Vector2(560, 270)
	banner_resultado.visible = false
	banner_resultado.clip_contents = true
	
	var sb_banner = StyleBoxFlat.new()
	sb_banner.bg_color = Color(0.06, 0.12, 0.28, 0.98) # Azul royal arcano elegante
	sb_banner.border_width_left = 3
	sb_banner.border_width_right = 3
	sb_banner.border_width_top = 3
	sb_banner.border_width_bottom = 3
	sb_banner.border_color = Color(1.0, 0.84, 0.22, 1.0) # Borda amarela dourada brilhante
	sb_banner.corner_radius_top_left = 14
	sb_banner.corner_radius_top_right = 14
	sb_banner.corner_radius_bottom_left = 14
	sb_banner.corner_radius_bottom_right = 14
	sb_banner.shadow_color = Color(0.98, 0.78, 0.18, 0.45) # Brilho dourado externo
	sb_banner.shadow_size = 28
	sb_banner.content_margin_left = 26
	sb_banner.content_margin_right = 26
	sb_banner.content_margin_top = 20
	sb_banner.content_margin_bottom = 20
	banner_resultado.add_theme_stylebox_override("panel", sb_banner)
	
	var vbox_b = VBoxContainer.new()
	vbox_b.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_b.add_theme_constant_override("separation", 10)
	banner_resultado.add_child(vbox_b)
	
	lbl_banner_emblema = Label.new()
	lbl_banner_emblema.text = "⚡  VITÓRIA ELEMENTAL  ⚡"
	lbl_banner_emblema.add_theme_font_override("font", font_titulo)
	lbl_banner_emblema.add_theme_font_size_override("font_size", 14)
	lbl_banner_emblema.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	lbl_banner_emblema.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_b.add_child(lbl_banner_emblema)
	
	lbl_banner_titulo = Label.new()
	lbl_banner_titulo.add_theme_font_override("font", font_titulo)
	lbl_banner_titulo.add_theme_font_size_override("font_size", 24)
	lbl_banner_titulo.add_theme_color_override("font_color", Color(1.0, 0.90, 0.35))
	lbl_banner_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_b.add_child(lbl_banner_titulo)
	
	lbl_banner_sub = Label.new()
	lbl_banner_sub.add_theme_font_override("font", font_sans)
	lbl_banner_sub.add_theme_font_size_override("font_size", 14)
	lbl_banner_sub.add_theme_color_override("font_color", Color(0.80, 0.90, 1.0))
	lbl_banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_b.add_child(lbl_banner_sub)
	
	# Divisor com losangos decorativos dourados
	var lbl_divisor = Label.new()
	lbl_divisor.text = "――― ◆ ―――"
	lbl_divisor.add_theme_font_size_override("font_size", 10)
	lbl_divisor.add_theme_color_override("font_color", Color(1.0, 0.82, 0.28, 0.7))
	lbl_divisor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_b.add_child(lbl_divisor)
	
	# Container de cards estilizados de efeitos/recompensas
	box_banner_recompensas = HBoxContainer.new()
	box_banner_recompensas.alignment = BoxContainer.ALIGNMENT_CENTER
	box_banner_recompensas.add_theme_constant_override("separation", 12)
	vbox_b.add_child(box_banner_recompensas)
	
	# Botão continuar com efeito hover azul/dourado
	btn_banner_continuar = Button.new()
	btn_banner_continuar.text = "✨ CONTINUAR [ESPAÇO] ✨"
	btn_banner_continuar.custom_minimum_size = Vector2(240, 36)
	btn_banner_continuar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_banner_continuar.add_theme_font_override("font", font_titulo)
	btn_banner_continuar.add_theme_font_size_override("font_size", 14)
	btn_banner_continuar.add_theme_color_override("font_color", Color(1.0, 0.95, 0.55))
	
	var sb_btn_c = StyleBoxFlat.new()
	sb_btn_c.bg_color = Color(0.10, 0.20, 0.45, 0.95)
	sb_btn_c.border_color = Color(1.0, 0.84, 0.25, 0.95)
	sb_btn_c.set_border_width_all(2)
	sb_btn_c.set_corner_radius_all(8)
	sb_btn_c.content_margin_left = 18
	sb_btn_c.content_margin_right = 18
	sb_btn_c.content_margin_top = 6
	sb_btn_c.content_margin_bottom = 6
	btn_banner_continuar.add_theme_stylebox_override("normal", sb_btn_c)
	
	var sb_btn_c_h = sb_btn_c.duplicate()
	sb_btn_c_h.bg_color = Color(0.18, 0.32, 0.68, 1.0)
	sb_btn_c_h.border_color = Color(1.0, 1.0, 0.65, 1.0)
	btn_banner_continuar.add_theme_stylebox_override("hover", sb_btn_c_h)
	btn_banner_continuar.add_theme_stylebox_override("pressed", sb_btn_c_h)
	btn_banner_continuar.pressed.connect(_ao_clicar_continuar)
	vbox_b.add_child(btn_banner_continuar)
	
	center_banner.add_child(banner_resultado)
	_aplicar_tema_disciplina()

func _ao_gui_input_backdrop(event: InputEvent) -> void:
	if not jogo_ativo or bloqueio_input or _finalizado:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if bloco_selecionado != null:
			_desselecionar_bloco()

func _gerar_blocos() -> void:
	# limpa blocos antigos
	for child in col_a_container.get_children():
		child.queue_free()
	for child in col_b_container.get_children():
		child.queue_free()
		
	var sep = 16
	if qtd_pares == 4:
		sep = 10
	elif qtd_pares >= 5:
		sep = 8
	col_a_container.add_theme_constant_override("separation", sep)
	col_b_container.add_theme_constant_override("separation", sep)

	var pool_pares: Array = PARES_POR_ANDAR.get(andar_id, PARES_POR_ANDAR[1]).duplicate()
	pool_pares.shuffle()
	
	var pares_selecionados = pool_pares.slice(0, qtd_pares)
	
	var lista_a = []
	var lista_b = []
	
	for i in range(pares_selecionados.size()):
		var p = pares_selecionados[i]
		lista_a.append({"par_id": i, "texto": p["termo_a"], "coluna": "A"})
		lista_b.append({"par_id": i, "texto": p["termo_b"], "coluna": "B"})
		
	# embaralha as colunas
	lista_a.shuffle()
	lista_b.shuffle()
	
	var tema = _obter_tema()
	var cor_a = tema.get("cor_col_a", Color(0.65, 0.45, 0.95))
	var cor_b = tema.get("cor_col_b", Color(0.3, 0.75, 1.0))

	for d in lista_a:
		var btn = _criar_botao_bloco(d, cor_a)
		col_a_container.add_child(btn)
		
	for d in lista_b:
		var btn = _criar_botao_bloco(d, cor_b)
		col_b_container.add_child(btn)

func _criar_botao_bloco(dados: Dictionary, cor_borda: Color) -> Button:
	var btn = Button.new()
	btn.text = str(dados.get("texto", ""))
	
	var btn_size = Vector2(300, 68)
	var font_sz = 15
	if qtd_pares == 4:
		btn_size = Vector2(310, 58)
		font_sz = 14
	elif qtd_pares >= 5:
		btn_size = Vector2(320, 50)
		font_sz = 13

	btn.custom_minimum_size = btn_size
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.pivot_offset = btn_size * 0.5
	
	var font_card = SystemFont.new()
	font_card.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "sans-serif"])
	font_card.font_weight = 700
	btn.add_theme_font_override("font", font_card)
	btn.add_theme_font_size_override("font_size", font_sz)
	btn.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	
	var tema = _obter_tema()
	var col = str(dados.get("coluna", "A"))
	var sb = StyleBoxFlat.new()
	sb.bg_color = tema.get("btn_bg", Color(0.04, 0.10, 0.25, 0.94))
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.border_color = cor_borda
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	
	# Margem no lado do nó de ligação para manter o texto perfeitamente legível
	if col == "A":
		sb.content_margin_left = 12
		sb.content_margin_right = 24
	else:
		sb.content_margin_left = 24
		sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", sb)
	
	var sb_hover = sb.duplicate()
	sb_hover.border_color = tema.get("btn_hover_border", tema.get("cor_secundaria", Color(1.0, 0.88, 0.35)))
	sb_hover.bg_color = tema.get("btn_hover_bg", Color(0.09, 0.25, 0.52, 0.98))
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_hover)
	
	btn.set_meta("par_id", int(dados.get("par_id", -1)))
	btn.set_meta("coluna", col)
	btn.set_meta("cor_borda", cor_borda)
	btn.set_meta("btn_bg", sb.bg_color)
	btn.set_meta("btn_hover_bg", sb_hover.bg_color)
	btn.set_meta("btn_hover_border", sb_hover.border_color)
	btn.set_meta("resolvido", false)
	
	# Micro-pop no hover para blocos não conectados (Item 4)
	btn.mouse_entered.connect(func():
		if jogo_ativo and not _finalizado and not btn.get_meta("resolvido", false):
			var tw_h = btn.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw_h.tween_property(btn, "scale", Vector2(1.03, 1.03), 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func():
		if not btn.get_meta("resolvido", false):
			var tw_h = btn.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw_h.tween_property(btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	)
	
	btn.button_down.connect(func(): _ao_pressionar_bloco(btn))
	return btn

# Obtem a posicao exata do nó na borda do botao (em coordenadas locais da camada overlay)
func _obter_posicao_no(btn: Button) -> Vector2:
	if not is_instance_valid(btn) or not is_instance_valid(overlay_conexoes):
		return Vector2.ZERO
	if not btn.is_inside_tree() or not overlay_conexoes.is_inside_tree():
		return Vector2.ZERO
	var col = btn.get_meta("coluna", "A")
	var w = max(btn.size.x, btn.custom_minimum_size.x)
	var h = max(btn.size.y, btn.custom_minimum_size.y)
	var pt_local = Vector2(w, h * 0.5) if col == "A" else Vector2(0.0, h * 0.5)
	var pt_global = btn.get_global_transform() * pt_local
	return overlay_conexoes.get_global_transform().affine_inverse() * pt_global

# Procura o bloco na coluna oposta que está sob a posição global do cursor
func _obter_bloco_sob_posicao(pos_global: Vector2) -> Button:
	if not is_instance_valid(bloco_selecionado):
		return null
	var col_origem = bloco_selecionado.get_meta("coluna", "A")
	var container_alvo = col_b_container if col_origem == "A" else col_a_container
	if not is_instance_valid(container_alvo):
		return null
	for child in container_alvo.get_children():
		if child is Button and child.visible and not child.get_meta("resolvido", false):
			if child.get_global_rect().grow(12.0).has_point(pos_global):
				return child
	return null

func _ao_pressionar_bloco(btn: Button) -> void:
	if not jogo_ativo or bloqueio_input or not is_instance_valid(btn) or btn.get_meta("resolvido", false):
		return
		
	esta_arrastando = true
	pos_inicio_arrasto = get_viewport().get_mouse_position() if get_viewport() else Vector2.ZERO
	
	# Se clicou no bloco que já estava selecionado
	if bloco_selecionado == btn:
		return
		
	# Se nenhum bloco estava selecionado
	if bloco_selecionado == null:
		_selecionar_bloco(btn)
		return
		
	# Havia outro bloco selecionado
	var col_sel = bloco_selecionado.get_meta("coluna", "A")
	var col_btn = btn.get_meta("coluna", "B")
	
	if col_sel == col_btn:
		# Mesma coluna: troca a seleção de forma suave e amigável
		_desselecionar_bloco()
		_selecionar_bloco(btn)
	else:
		# Colunas opostas: tenta a conexão!
		_conectar_dois_blocos(bloco_selecionado, btn)

func _ao_soltar_arrasto() -> void:
	if not esta_arrastando:
		return
	esta_arrastando = false
	
	var pos_atual = get_viewport().get_mouse_position()
	var dist = pos_atual.distance_to(pos_inicio_arrasto)
	
	# Se arrastou e soltou sobre um bloco alvo válido na coluna oposta
	if is_instance_valid(bloco_hover_alvo) and is_instance_valid(bloco_selecionado):
		if bloco_hover_alvo != bloco_selecionado and bloco_hover_alvo.get_meta("coluna") != bloco_selecionado.get_meta("coluna"):
			_conectar_dois_blocos(bloco_selecionado, bloco_hover_alvo)
			return
			
	# Se foi um arrasto longo que terminou no vazio (> 35px), cancela a seleção
	if dist > 35.0:
		_desselecionar_bloco()
	# Se foi um clique no mesmo botão (< 15px) que já estava selecionado
	elif dist < 15.0 and is_instance_valid(bloco_selecionado):
		if Time.get_ticks_msec() - tick_selecao > 300:
			_desselecionar_bloco()
			_tocar_sfx("ui-1")

func _selecionar_bloco(btn: Button) -> void:
	bloco_selecionado = btn
	tick_selecao = Time.get_ticks_msec()
	_destacar_bloco(btn, true)
	_tocar_sfx("ui-1")

func _desselecionar_bloco() -> void:
	if is_instance_valid(bloco_selecionado):
		_destacar_bloco(bloco_selecionado, false)
	bloco_selecionado = null
	bloco_hover_alvo = null
	esta_arrastando = false

func _destacar_bloco(btn: Button, destacar: bool) -> void:
	if not is_instance_valid(btn): return
	var sb = btn.get_theme_stylebox("normal") as StyleBoxFlat
	if sb:
		var tema = _obter_tema()
		if destacar:
			sb.border_color = btn.get_meta("btn_hover_border", tema.get("btn_hover_border", Color(1.0, 0.88, 0.35)))
			sb.bg_color = btn.get_meta("btn_hover_bg", tema.get("btn_hover_bg", Color(0.09, 0.25, 0.52, 0.98)))
			btn.scale = Vector2(1.04, 1.04)
		else:
			sb.border_color = btn.get_meta("cor_borda", tema.get("btn_border", Color(0.18, 0.42, 0.78, 0.90)))
			sb.bg_color = btn.get_meta("btn_bg", tema.get("btn_bg", Color(0.04, 0.10, 0.25, 0.94)))
			btn.scale = Vector2(1.0, 1.0)

func _restaurar_cor_bloco(btn: Button) -> void:
	if not is_instance_valid(btn): return
	var sb = btn.get_theme_stylebox("normal") as StyleBoxFlat
	if sb:
		var tema = _obter_tema()
		sb.border_color = btn.get_meta("cor_borda", tema.get("btn_border", Color(0.18, 0.42, 0.78, 0.90)))
		sb.bg_color = btn.get_meta("btn_bg", tema.get("btn_bg", Color(0.04, 0.10, 0.25, 0.94)))
	btn.scale = Vector2(1.0, 1.0)

func _aplicar_cor_bloco(btn: Button, cor: Color) -> void:
	if not is_instance_valid(btn): return
	var sb = btn.get_theme_stylebox("normal") as StyleBoxFlat
	if sb:
		sb.border_color = cor

func _conectar_dois_blocos(b1: Button, b2: Button) -> void:
	if not jogo_ativo or bloqueio_input:
		return
	if not is_instance_valid(b1) or not is_instance_valid(b2):
		return
		
	bloqueio_input = true
	esta_arrastando = false
	
	var pos1 = _obter_posicao_no(b1)
	var pos2 = _obter_posicao_no(b2)
	
	var par_id_1: int = b1.get_meta("par_id", -1)
	var par_id_2: int = b2.get_meta("par_id", -2)
	var col_1: String = b1.get_meta("coluna", "A")
	var col_2: String = b2.get_meta("coluna", "B")
	
	# Desseleciona bloco ativo para dar lugar à animação de linha
	bloco_selecionado = null
	bloco_hover_alvo = null
	
	if par_id_1 >= 0 and par_id_1 == par_id_2 and col_1 != col_2:
		# PAR CORRETO!
		b1.set_meta("resolvido", true)
		b2.set_meta("resolvido", true)
		b1.disabled = true
		b2.disabled = true
		
		var tema = _obter_tema()
		var cor_sucesso = tema.get("btn_correct_border", tema.get("cor_primaria", Color(0.2, 0.98, 0.45)))
		# Registra linha de conexão bem-sucedida
		linhas_animadas.append({
			"p_start": pos1,
			"p_end": pos2,
			"cor": cor_sucesso,
			"sucesso": true,
			"tempo": 0.0,
			"duracao": 0.45
		})
		
		pares_conectados += 1
		lbl_pares.text = "CONECTADOS: %d / %d" % [pares_conectados, qtd_pares]
		
		# Recompensa com bônus de tempo (+2.0s ou +1.5s em fases mais difíceis)
		var bonus_t = 1.5 if qtd_pares >= 5 else 2.0
		tempo_restante = min(duracao_total, tempo_restante + bonus_t)
		_atualizar_timer_ui()
		_mostrar_bonus_tempo("+%.1fs" % bonus_t if bonus_t != 2.0 else "+2s")
		
		_tocar_sfx("acerto_1")
			
		_aplicar_cor_bloco(b1, cor_sucesso)
		_aplicar_cor_bloco(b2, cor_sucesso)
		
		_criar_particulas_acerto(b1)
		_criar_particulas_acerto(b2)
		
		# Animação suave de desaparecimento dos blocos
		var tw = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(b1, "scale", Vector2(1.08, 1.08), 0.15)
		tw.tween_property(b2, "scale", Vector2(1.08, 1.08), 0.15)
		tw.tween_property(b1, "modulate:a", 0.0, 0.3).set_delay(0.12)
		tw.tween_property(b2, "modulate:a", 0.0, 0.3).set_delay(0.12)
		
		await tw.finished
		if is_instance_valid(b1): b1.visible = false
		if is_instance_valid(b2): b2.visible = false
		
		bloqueio_input = false
		
		if pares_conectados >= qtd_pares:
			_finalizar_vitoria()
	else:
		# PAR ERRADO!
		linhas_animadas.append({
			"p_start": pos1,
			"p_end": pos2,
			"cor": Color(1.0, 0.25, 0.25),
			"sucesso": false,
			"tempo": 0.0,
			"duracao": 0.40
		})
		
		_tocar_sfx("ui-2")
			
		_aplicar_cor_bloco(b1, Color(0.95, 0.25, 0.25))
		_aplicar_cor_bloco(b2, Color(0.95, 0.25, 0.25))
		
		# Treme os dois blocos
		var tw1 = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw1.tween_property(b1, "position:x", b1.position.x + 8.0, 0.05)
		tw1.tween_property(b1, "position:x", b1.position.x - 8.0, 0.05)
		tw1.tween_property(b1, "position:x", b1.position.x, 0.05)
		
		var tw2 = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw2.tween_property(b2, "position:x", b2.position.x + 8.0, 0.05)
		tw2.tween_property(b2, "position:x", b2.position.x - 8.0, 0.05)
		tw2.tween_property(b2, "position:x", b2.position.x, 0.05)
		
		await get_tree().create_timer(0.4, true, false, true).timeout
		
		_restaurar_cor_bloco(b1)
		_restaurar_cor_bloco(b2)
		bloqueio_input = false

func _mostrar_bonus_tempo(texto: String = "+2s") -> void:
	if not is_instance_valid(lbl_timer): return
	var lbl_bonus = Label.new()
	lbl_bonus.text = texto
	var font_t = SystemFont.new()
	font_t.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "sans-serif"])
	font_t.font_weight = 700
	lbl_bonus.add_theme_font_override("font", font_t)
	lbl_bonus.add_theme_font_size_override("font_size", 16)
	lbl_bonus.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	lbl_bonus.position = lbl_timer.position + Vector2(lbl_timer.size.x + 8.0, -4.0)
	lbl_timer.get_parent().add_child(lbl_bonus)
	
	var tw = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(lbl_bonus, "position:y", lbl_bonus.position.y - 18.0, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(lbl_bonus, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(lbl_bonus.queue_free)

# Desenho customizado da camada de sobreposição de conexões
func _desenhar_camada_conexoes(canvas: Control) -> void:
	if not is_instance_valid(canvas):
		return
		
	# 0. Canal central de energia rúnica (guia visual elegante)
	_desenhar_canal_central(canvas)
		
	# 1. Desenha linhas de conexões concluídas (em animação de acerto ou erro)
	for l in linhas_animadas:
		_desenhar_linha_animada(canvas, l)
		
	# 2. Desenha linha ativa sendo arrastada/estendida pelo jogador
	if is_instance_valid(bloco_selecionado) and jogo_ativo:
		_desenhar_linha_ativa(canvas)
		
	# 3. Desenha os nós de conexão nos blocos visíveis de ambas as colunas
	for btn in col_a_container.get_children():
		if btn is Button and btn.visible and not btn.get_meta("resolvido", false):
			_desenhar_no_bloco(canvas, btn)
			
	for btn in col_b_container.get_children():
		if btn is Button and btn.visible and not btn.get_meta("resolvido", false):
			_desenhar_no_bloco(canvas, btn)

func _desenhar_canal_central(canvas: Control) -> void:
	if not is_instance_valid(col_a_container) or not is_instance_valid(col_b_container):
		return
	var filhos_a = col_a_container.get_children()
	var filhos_b = col_b_container.get_children()
	if filhos_a.is_empty() or filhos_b.is_empty():
		return
		
	var btn_a = filhos_a[0] as Control
	var btn_b = filhos_b[0] as Control
	if not is_instance_valid(btn_a) or not is_instance_valid(btn_b):
		return
		
	var p_a = _obter_posicao_no(btn_a)
	var p_b = _obter_posicao_no(btn_b)
	var x_centro = (p_a.x + p_b.x) * 0.5
	var largura_gap = p_b.x - p_a.x
	
	if largura_gap < 50.0:
		return
		
	var y_inicio = p_a.y - 45.0
	var y_fim = p_a.y + 195.0
	if filhos_a.size() > 1:
		var btn_ult = filhos_a[filhos_a.size() - 1] as Control
		if is_instance_valid(btn_ult):
			y_fim = _obter_posicao_no(btn_ult).y + 45.0
			
	var canal_rect = Rect2(x_centro - (largura_gap * 0.44), y_inicio, largura_gap * 0.88, y_fim - y_inicio)

	match andar_id:
		2: # FÍSICA: Campo eletromagnético / Linhas de indução com micro-zaps e cobre da batalha
			# Fundo marrom forja / cobre escuro translúcido da batalha
			canvas.draw_rect(canal_rect, Color(0.12, 0.07, 0.05, 0.40), true)
			# Bordas laterais condutoras de friso de cobre polido / âmbar da batalha
			canvas.draw_line(Vector2(canal_rect.position.x, y_inicio), Vector2(canal_rect.position.x, y_fim), Color(0.95, 0.52, 0.16, 0.45), 1.8)
			canvas.draw_line(Vector2(canal_rect.end.x, y_inicio), Vector2(canal_rect.end.x, y_fim), Color(0.95, 0.52, 0.16, 0.45), 1.8)
			# Linha central de indução tracejada com arco elétrico cyan da batalha
			canvas.draw_dashed_line(Vector2(x_centro, y_inicio + 8.0), Vector2(x_centro, y_fim - 8.0), Color(0.15, 0.95, 1.0, 0.35), 1.5, 7.0)
			# Micro-arcos elétricos verticais crepitando
			var passos = 12
			var alt_passo = (y_fim - y_inicio) / passos
			for i in range(passos):
				var y_p = y_inicio + i * alt_passo
				var onda = sin(y_p * 0.08 + tempo_anim_global * 16.0 + i) * 6.0
				var x_zap = x_centro + onda
				canvas.draw_circle(Vector2(x_zap, y_p), 1.8, Color(0.15, 0.95, 1.0, 0.65))
				if i % 3 == 0:
					canvas.draw_line(Vector2(x_zap - 4, y_p), Vector2(x_zap + 4, y_p), Color(0.95, 0.52, 0.16, 0.60), 1.2)

		3: # BIOLOGIA: Treliça botânica viva / Cipós naturais em verde esmeralda e pólen solar
			# Fundo verde floresta escuro translúcido da batalha
			canvas.draw_rect(canal_rect, Color(0.03, 0.08, 0.04, 0.38), true)
			# Bordas laterais de ramos em verde esmeralda vivo da batalha
			canvas.draw_line(Vector2(canal_rect.position.x, y_inicio), Vector2(canal_rect.position.x, y_fim), Color(0.30, 0.85, 0.30, 0.40), 1.8)
			canvas.draw_line(Vector2(canal_rect.end.x, y_inicio), Vector2(canal_rect.end.x, y_fim), Color(0.30, 0.85, 0.30, 0.40), 1.8)
			# Dois ramos trepadores naturais estáticos entrelaçados na treliça (sem oscilar como onda)
			var passos_bio = 24
			var dy_bio = (y_fim - y_inicio) / passos_bio
			var p_ant1 = Vector2(x_centro - 12.0, y_inicio)
			var p_ant2 = Vector2(x_centro + 12.0, y_inicio)
			for i in range(1, passos_bio + 1):
				var cur_y = y_inicio + i * dy_bio
				var w1 = sin(cur_y * 0.035) * 12.0
				var w2 = cos(cur_y * 0.035) * 12.0
				var p_cur1 = Vector2(x_centro - 10.0 + w1, cur_y)
				var p_cur2 = Vector2(x_centro + 10.0 + w2, cur_y)
				canvas.draw_line(p_ant1, p_cur1, Color(0.22, 0.70, 0.32, 0.50), 2.0)
				canvas.draw_line(p_ant2, p_cur2, Color(0.30, 0.85, 0.30, 0.50), 1.8)
				# Pequenos nós / folhinhas em pontos específicos
				if i % 4 == 0:
					canvas.draw_circle(p_cur1, 2.5, Color(0.30, 0.85, 0.30, 0.85))
					# Folhinha lateral botânica com toque de pólen solar
					var dir_f = Vector2(8, -4) if i % 8 == 0 else Vector2(-8, -4)
					canvas.draw_line(p_cur1, p_cur1 + dir_f, Color(0.30, 0.85, 0.30, 0.80), 1.8)
					canvas.draw_circle(p_cur1 + dir_f, 1.8, Color(1.0, 0.84, 0.18, 0.90))
				p_ant1 = p_cur1
				p_ant2 = p_cur2
			# Esporos de pólen solar dourado flutuando suavemente
			for sp in range(4):
				var y_sp = y_inicio + fmod(tempo_anim_global * 12.0 + sp * 75.0, y_fim - y_inicio)
				var x_sp = x_centro + sin(sp * 2.3) * (largura_gap * 0.25)
				canvas.draw_circle(Vector2(x_sp, y_sp), 1.5, Color(1.0, 0.84, 0.18, 0.75))

		_: # QUÍMICA (1): Coluna de vidro de laboratório alquímico com solução ácida/reagente borbulhante
			# Fundo câmara de vidro translúcido em tom safira arcana profunda da batalha
			canvas.draw_rect(canal_rect, Color(0.04, 0.05, 0.22, 0.40), true)
			# Paredes de vidro da coluna de destilação com reflexo violeta alquímico
			canvas.draw_line(Vector2(canal_rect.position.x, y_inicio), Vector2(canal_rect.position.x, y_fim), Color(0.70, 0.40, 1.0, 0.45), 2.0)
			canvas.draw_line(Vector2(canal_rect.end.x, y_inicio), Vector2(canal_rect.end.x, y_fim), Color(0.70, 0.40, 1.0, 0.45), 2.0)
			# Friso de reflexo de vidro (brilho branco translúcido)
			canvas.draw_line(Vector2(canal_rect.position.x + 3.0, y_inicio + 10.0), Vector2(canal_rect.position.x + 3.0, y_fim - 10.0), Color(1.0, 1.0, 1.0, 0.18), 1.0)
			# Marcas de graduação em ml / escala na parede de vidro em tom lilás
			var n_grad = int((y_fim - y_inicio) / 22.0)
			for i in range(n_grad):
				var yg = y_inicio + 12.0 + i * 22.0
				var comp = 7.0 if i % 2 == 0 else 4.0
				canvas.draw_line(Vector2(canal_rect.position.x + 1.0, yg), Vector2(canal_rect.position.x + 1.0 + comp, yg), Color(0.85, 0.60, 1.0, 0.35), 1.0)
				canvas.draw_line(Vector2(canal_rect.end.x - 1.0, yg), Vector2(canal_rect.end.x - 1.0 - comp, yg), Color(0.85, 0.60, 1.0, 0.35), 1.0)
			# Bolhas de ácido/vitríolo roxo subindo continuamente na coluna
			var bolhas_qtd = 8
			var h_canal = y_fim - y_inicio
			for i in range(bolhas_qtd):
				var seed_i = float(i) * 1.37
				var vel = 38.0 + fmod(seed_i * 19.0, 25.0)
				var r_bolha = 2.5 + fmod(seed_i * 7.0, 4.0)
				var pos_y_b = y_fim - fmod(tempo_anim_global * vel + i * (h_canal / bolhas_qtd), h_canal)
				var ox = sin(pos_y_b * 0.04 + seed_i * 3.0) * (largura_gap * 0.26)
				var centro_b = Vector2(x_centro + ox, pos_y_b)
				# Bolha ácida cáustica roxa translúcida com anel lilás reluzente
				canvas.draw_circle(centro_b, r_bolha, Color(0.55, 0.18, 0.85, 0.38))
				canvas.draw_arc(centro_b, r_bolha, 0.0, TAU, 16, Color(0.92, 0.65, 1.0, 0.88), 1.2)
				canvas.draw_circle(centro_b + Vector2(-r_bolha * 0.35, -r_bolha * 0.35), max(1.0, r_bolha * 0.28), Color(1.0, 1.0, 1.0, 0.85))

func _desenhar_no_bloco(canvas: Control, btn: Button) -> void:
	var pos = _obter_posicao_no(btn)
	var col = btn.get_meta("coluna", "A")
	var is_sel = (btn == bloco_selecionado)
	var is_alvo = (btn == bloco_hover_alvo)
	var tema = _obter_tema()
	
	var cor_base = tema.get("cor_col_a", Color(0.20, 0.58, 0.95)) if col == "A" else tema.get("cor_col_b", Color(0.28, 0.85, 1.0))
	if is_sel:
		cor_base = tema.get("cor_secundaria", Color(0.28, 0.85, 1.0))
	elif is_alvo:
		cor_base = tema.get("btn_hover_border", tema.get("cor_secundaria", Color(0.28, 0.85, 1.0)))
	elif btn.is_hovered():
		cor_base = tema.get("btn_hover_border", tema.get("cor_secundaria", Color(0.28, 0.85, 1.0)))
		
	var r_ext = 9.5
	var r_int = 7.0
	var r_gem = 4.2
	
	if is_sel or is_alvo:
		r_ext = 11.5
		r_int = 8.5
		r_gem = 5.2

	match andar_id:
		2: # FÍSICA: Terminal elétrico com pino metálico e centelhas da batalha
			# Pulso eletromagnético se selecionado ou alvo
			if is_sel or is_alvo:
				var pulso = fmod(tempo_anim_global * 3.0, 1.0)
				var r_pulse = r_ext + 2.0 + pulso * 9.0
				var a_pulse = (1.0 - pulso) * 0.85
				canvas.draw_arc(pos, r_pulse, 0.0, TAU, 28, Color(cor_base.r, cor_base.g, cor_base.b, a_pulse), 2.0)
				for k in range(3):
					var ang = tempo_anim_global * 8.0 + k * (TAU / 3.0)
					var p_spark = pos + Vector2(cos(ang), sin(ang)) * (r_ext + 4.0)
					canvas.draw_line(pos, p_spark, Color(0.15, 0.95, 1.0, 0.85), 1.5)

			# Pino condutor metálico de cobre em direção ao canal central
			if col == "A":
				canvas.draw_line(pos + Vector2(4.0, 0.0), pos + Vector2(16.0, 0.0), cor_base, 2.5)
				canvas.draw_line(pos + Vector2(12.0, -3.0), pos + Vector2(16.0, 0.0), cor_base, 1.8)
				canvas.draw_line(pos + Vector2(12.0, 3.0), pos + Vector2(16.0, 0.0), cor_base, 1.8)
			else:
				canvas.draw_line(pos - Vector2(4.0, 0.0), pos - Vector2(16.0, 0.0), cor_base, 2.5)
				canvas.draw_line(pos - Vector2(12.0, -3.0), pos - Vector2(16.0, 0.0), cor_base, 1.8)
				canvas.draw_line(pos - Vector2(12.0, 3.0), pos - Vector2(16.0, 0.0), cor_base, 1.8)

			# Anel metálico condutor bronze/cobre da batalha
			canvas.draw_circle(pos, r_ext, Color(0.15, 0.09, 0.07, 0.95))
			canvas.draw_arc(pos, r_ext, 0.0, TAU, 24, cor_base, 2.5)
			canvas.draw_circle(pos, r_int, Color(0.19, 0.11, 0.08, 1.0))
			# Núcleo de plasma elétrico
			canvas.draw_circle(pos, r_gem, cor_base)
			canvas.draw_circle(pos + Vector2(-1.2, -1.2), r_gem * 0.35, Color(1.0, 1.0, 1.0, 0.95))

		3: # BIOLOGIA: Broto vegetal com sépalas verdes e pétalas florais
			# Pétalas e brotos desabrochando suavemente se selecionado ou alvo
			if is_sel or is_alvo:
				var pulso_bio = fmod(tempo_anim_global * 1.8, 1.0)
				var a_bio = (1.0 - pulso_bio) * 0.85
				for k in range(5):
					var ang_b = float(k) * (TAU / 5.0) + tempo_anim_global * 1.2
					var dist_pet = r_ext + 3.0 + pulso_bio * 7.0
					var p_pet = pos + Vector2(cos(ang_b), sin(ang_b)) * dist_pet
					canvas.draw_circle(p_pet, 2.4 * (1.0 - pulso_bio * 0.4), Color(0.30, 0.85, 0.30, a_bio))
					canvas.draw_circle(p_pet + Vector2(cos(ang_b), sin(ang_b)) * 1.5, 1.2, Color(1.0, 0.84, 0.18, a_bio))

			# Caule / Raminho brotando do botão em direção ao canal central
			var dir_caule = 1.0 if col == "A" else -1.0
			var p_caule_fim = pos + Vector2(dir_caule * 16.0, 0.0)
			canvas.draw_line(pos + Vector2(dir_caule * 4.0, 0.0), p_caule_fim, Color(0.22, 0.46, 0.24), 2.8)
			# Pequenas folhas no conector
			canvas.draw_line(pos + Vector2(dir_caule * 10.0, 0.0), pos + Vector2(dir_caule * 14.0, -4.0), Color(0.30, 0.85, 0.30), 1.8)
			canvas.draw_line(pos + Vector2(dir_caule * 10.0, 0.0), pos + Vector2(dir_caule * 14.0, 4.0), Color(0.30, 0.85, 0.30), 1.8)

			# Base botânica verde musgo da batalha
			canvas.draw_circle(pos, r_ext, Color(0.06, 0.14, 0.08, 0.95))
			canvas.draw_arc(pos, r_ext, 0.0, TAU, 24, cor_base, 2.5)
			canvas.draw_circle(pos, r_int, Color(0.06, 0.15, 0.08, 1.0))
			# Núcleo de seiva vegetal e pólen solar
			canvas.draw_circle(pos, r_gem, cor_base)
			canvas.draw_circle(pos + Vector2(-1.2, -1.2), r_gem * 0.38, Color(1.0, 1.0, 0.9, 0.95))

		_: # QUÍMICA (1): Retorta / bico com efervescência de bolhas cáusticas lilás
			# Pulso cáustico de bolhas roxo/lilás
			if is_sel or is_alvo:
				var pulso_q = fmod(tempo_anim_global * 3.2, 1.0)
				var r_q = r_ext + 2.0 + pulso_q * 9.0
				var a_q = (1.0 - pulso_q) * 0.85
				canvas.draw_arc(pos, r_q, 0.0, TAU, 24, Color(0.85, 0.45, 1.0, a_q), 2.0)
				for k in range(3):
					var ang_q = -PI * 0.5 + (k - 1) * 0.6 + sin(tempo_anim_global * 5.0 + k) * 0.2
					var dist_q = r_ext + 3.0 + fmod(tempo_anim_global * 12.0 + k * 4.0, 9.0)
					var p_bq = pos + Vector2(cos(ang_q), sin(ang_q)) * dist_q
					canvas.draw_circle(p_bq, 1.5, Color(0.92, 0.65, 1.0, 0.85))

			# Micro-bolhas borbulhantes na ponta do conector
			var dir_tubo = 1.0 if col == "A" else -1.0
			var p_bico_fim = pos + Vector2(dir_tubo * 15.0, 0.0)
			canvas.draw_circle(pos + Vector2(dir_tubo * 7.0, 0.0), 2.0, Color(0.70, 0.35, 0.95, 0.80))
			canvas.draw_circle(p_bico_fim, 2.8, Color(0.92, 0.65, 1.0))
			canvas.draw_arc(p_bico_fim, 2.8, 0.0, TAU, 12, Color(1.0, 1.0, 1.0, 0.90), 1.0)
			canvas.draw_circle(p_bico_fim + Vector2(-0.8, -0.8), 1.0, Color(1.0, 1.0, 1.0, 0.95))

			# Frasco de vidro alquímico do nó em tom safira arcana profunda da batalha
			canvas.draw_circle(pos, r_ext, Color(0.04, 0.05, 0.22, 0.95))
			canvas.draw_arc(pos, r_ext, 0.0, TAU, 24, cor_base, 2.5)
			canvas.draw_circle(pos, r_int, Color(0.06, 0.08, 0.28, 1.0))
			# Núcleo de solução ácida em roxo/lilás reluzente
			canvas.draw_circle(pos, r_gem, cor_base)
			canvas.draw_circle(pos + Vector2(-1.2, -1.2), r_gem * 0.38, Color(1.0, 1.0, 1.0, 0.95))

func _desenhar_linha_ativa(canvas: Control) -> void:
	var p1 = _obter_posicao_no(bloco_selecionado)
	var p2 = Vector2.ZERO
	var tema = _obter_tema()
	var cor_linha = tema.get("cor_secundaria", Color(1.0, 0.88, 0.35))
	
	if is_instance_valid(bloco_hover_alvo):
		p2 = _obter_posicao_no(bloco_hover_alvo)
		cor_linha = tema.get("cor_primaria", Color(0.3, 1.0, 0.65))
	else:
		p2 = canvas.get_local_mouse_position()
		
	var dist = p1.distance_to(p2)
	if dist < 4.0:
		return

	var dir = (p2 - p1) / dist
	var perp = Vector2(-dir.y, dir.x)

	match andar_id:
		2: # FÍSICA: Arco voltaico elétrico oscilante com jitter senoidal e cobre da batalha
			# Brilho externo difuso de campo elétrico / aura de cobre da batalha
			canvas.draw_line(p1, p2, Color(0.95, 0.52, 0.16, 0.20), 14.0, true)
			
			# Feixe elétrico em zigue-zague com alta vibração
			var segs = 18
			var pts_arc = PackedVector2Array()
			pts_arc.append(p1)
			for i in range(1, segs):
				var t = float(i) / float(segs)
				var p_base = p1.lerp(p2, t)
				var jitter = perp * (sin(t * 35.0 + tempo_anim_global * 26.0) * 5.0 + sin(t * 70.0 + tempo_anim_global * 42.0) * 2.5)
				pts_arc.append(p_base + jitter)
			pts_arc.append(p2)
			
			for i in range(pts_arc.size() - 1):
				canvas.draw_line(pts_arc[i], pts_arc[i + 1], Color(0.15, 0.95, 1.0, 0.85), 4.5, true)
				canvas.draw_line(pts_arc[i], pts_arc[i + 1], Color(1.0, 1.0, 1.0, 0.95), 2.0, true)
				
			# Orbs de plasma viajando na linha (Cyan e Cobre/Âmbar da batalha)
			var pulso1 = fmod(tempo_anim_global * 2.0, 1.0)
			var pulso2 = fmod(tempo_anim_global * 2.0 + 0.5, 1.0)
			var orb1 = p1.lerp(p2, pulso1)
			var orb2 = p1.lerp(p2, pulso2)
			canvas.draw_circle(orb1, 4.5, Color(0.15, 0.95, 1.0, 0.90))
			canvas.draw_circle(orb1, 2.0, Color(1.0, 1.0, 1.0, 0.95))
			canvas.draw_circle(orb2, 4.5, Color(0.95, 0.52, 0.16, 0.90))
			canvas.draw_circle(orb2, 2.0, Color(1.0, 1.0, 1.0, 0.95))
			
			if is_instance_valid(bloco_hover_alvo):
				var mira_pulse = fmod(tempo_anim_global * 3.5, 1.0)
				canvas.draw_arc(p2, 14.0 + mira_pulse * 4.0, 0.0, TAU, 24, Color(0.15, 0.95, 1.0, (1.0 - mira_pulse) * 0.9), 2.0)

		3: # BIOLOGIA: Cipó vegetal botânico puro (sem qualquer ondazinha secundária ou raio elétrico)
			var segs_bio = 22
			var pts_stem = PackedVector2Array()
			pts_stem.append(p1)
			
			# Curvatura botânica natural, suave e estável (sem oscilar no tempo como onda)
			var curv_sag = min(10.0, dist * 0.05)
			for i in range(1, segs_bio):
				var t = float(i) / float(segs_bio)
				var p_base = p1.lerp(p2, t)
				var cur_curve = perp * (sin(t * PI) * curv_sag)
				pts_stem.append(p_base + cur_curve)
			pts_stem.append(p2)
			
			# 1. Desenha o caule único do cipó (casca externa lenhosa escura + corpo vegetal verde)
			for i in range(pts_stem.size() - 1):
				canvas.draw_line(pts_stem[i], pts_stem[i + 1], Color(0.12, 0.32, 0.14, 0.95), 5.6, true)
				canvas.draw_line(pts_stem[i], pts_stem[i + 1], Color(0.26, 0.68, 0.28, 0.95), 2.8, true)
				
			# 2. Folhas botânicas brotando diretamente do cipó em posições fixas (sem trepadeira em onda)
			var t_folhas = [0.20, 0.40, 0.60, 0.80]
			for idx in range(t_folhas.size()):
				var tf = t_folhas[idx]
				var p_f = p1.lerp(p2, tf) + perp * (sin(tf * PI) * curv_sag)
				var lado = 1.0 if idx % 2 == 0 else -1.0
				var d_folha = (dir * 0.32 + perp * (0.92 * lado)).normalized() * 11.0
				var p_ponta = p_f + d_folha
				var p_l1 = p_f + d_folha * 0.5 + dir * 3.2
				var p_l2 = p_f + d_folha * 0.5 - dir * 3.2
				var folha_poly = PackedVector2Array([p_f, p_l1, p_ponta, p_l2])
				canvas.draw_colored_polygon(folha_poly, Color(0.24, 0.72, 0.28, 0.95))
				canvas.draw_line(p_f, p_ponta, Color(0.40, 0.90, 0.45, 0.90), 1.2)
				# Pequeno botão floral na junção da folha com o caule
				canvas.draw_circle(p_f, 1.8, Color(1.0, 0.84, 0.20, 0.90))

			# 3. Ao mirar no alvo: coroa floral de pétalas estáticas no nó destino (sem raios)
			if is_instance_valid(bloco_hover_alvo):
				var r_coroa_mira = 15.0
				var qtd_pet_alvo = 5
				for p_i in range(qtd_pet_alvo):
					var ang = float(p_i) * (TAU / float(qtd_pet_alvo))
					var p_petala = p2 + Vector2(cos(ang), sin(ang)) * r_coroa_mira
					canvas.draw_circle(p_petala, 3.0, Color(0.30, 0.85, 0.30, 0.90))
					canvas.draw_circle(p_petala, 1.5, Color(1.0, 0.84, 0.20, 0.95))

		_: # QUÍMICA (1): Conexão formada exclusivamente por cadeia viva de bolhas ácidas efervescentes
			# Sem linhas sólidas: todo o fluxo de conexão é composto apenas por bolhas efervescentes
			var passo_b = 10.0
			var num_bolhas = max(5, int(dist / passo_b))
			
			for i in range(num_bolhas + 1):
				var t = float(i) / float(num_bolhas)
				# Fluxo contínuo de bolhas partindo do nó inicial p1 em direção ao cursor/alvo p2
				var t_anim = fmod(t - tempo_anim_global * 0.40, 1.0)
				if t_anim < 0.0:
					t_anim += 1.0
				var p_base = p1.lerp(p2, t_anim)
				
				# Flutuação e ondulação orgânica efervescente (ondulação transversal + flutuação vertical)
				var ondula = perp * sin(t_anim * TAU * 2.6 + tempo_anim_global * 7.5 + float(i) * 1.6) * 4.2
				var sobe_y = Vector2(0.0, sin(tempo_anim_global * 5.0 + float(i) * 2.1) * 2.8)
				var pos_b = p_base + ondula + sobe_y
				
				# Variação procedural de tamanho das bolhas para aspecto efervescente rico
				var seed_b = float(i) * 2.47
				var r_base = 3.6 + abs(sin(seed_b)) * 4.4 # Entre 3.6px e 8.0px
				var taper = clamp(sin(t_anim * PI) * 1.35, 0.45, 1.0)
				var r_bolha = r_base * taper
				
				# 1. Corpo esférico translúcido de ácido roxo
				canvas.draw_circle(pos_b, r_bolha, Color(0.65, 0.25, 0.95, 0.42))
				# 2. Borda brilhante reluzente em lilás cáustico
				canvas.draw_arc(pos_b, r_bolha, 0.0, TAU, 18, Color(0.92, 0.65, 1.0, 0.92), 1.3)
				# 3. Ponto de reflexo especular de luz (brilho branco no topo)
				var glint_pos = pos_b + Vector2(-r_bolha * 0.35, -r_bolha * 0.35)
				canvas.draw_circle(glint_pos, max(1.0, r_bolha * 0.28), Color(1.0, 1.0, 1.0, 0.92))
				# 4. Reflexo secundário translúcido na base da bolha
				if r_bolha > 4.6:
					var glint2_pos = pos_b + Vector2(r_bolha * 0.26, r_bolha * 0.26)
					canvas.draw_circle(glint2_pos, max(0.8, r_bolha * 0.16), Color(0.85, 0.50, 1.0, 0.65))

			# Micro-bolhas efervescentes dispersas ao redor da corrente
			var num_micro = max(4, int(dist / 22.0))
			for k in range(num_micro):
				var tm = fmod(float(k) / float(num_micro) + tempo_anim_global * 0.30, 1.0)
				var seed_m = float(k) * 3.73
				var lateral = (8.0 + fmod(seed_m * 6.0, 8.0)) * (1.0 if k % 2 == 0 else -1.0)
				var pm = p1.lerp(p2, tm) + perp * lateral + Vector2(0.0, -fmod(tempo_anim_global * 20.0 + seed_m * 11.0, 15.0))
				var rm = 1.6 + fmod(seed_m * 2.0, 1.5)
				canvas.draw_circle(pm, rm, Color(0.85, 0.45, 1.0, 0.65))
				canvas.draw_arc(pm, rm, 0.0, TAU, 12, Color(0.95, 0.75, 1.0, 0.88), 1.0)
				canvas.draw_circle(pm + Vector2(-0.4, -0.4), max(0.6, rm * 0.3), Color(1.0, 1.0, 1.0, 0.90))

			# Halo de mira no alvo: anel orbital de bolhas em torno do nó de destino
			if is_instance_valid(bloco_hover_alvo):
				var r_orbita = 15.0 + sin(tempo_anim_global * 4.0) * 2.0
				var qtd_alvo = 8
				for b in range(qtd_alvo):
					var ang = tempo_anim_global * 3.5 + float(b) * (TAU / float(qtd_alvo))
					var pb = p2 + Vector2(cos(ang), sin(ang)) * r_orbita
					var rb = 2.8 + sin(ang * 2.0) * 0.6
					canvas.draw_circle(pb, rb, Color(0.70, 0.30, 0.95, 0.70))
					canvas.draw_arc(pb, rb, 0.0, TAU, 14, Color(0.95, 0.70, 1.0, 0.95), 1.2)
					canvas.draw_circle(pb + Vector2(-0.7, -0.7), 0.8, Color(1.0, 1.0, 1.0, 0.95))

func _desenhar_linha_animada(canvas: Control, l: Dictionary) -> void:
	var p1 = l.p_start
	var p2 = l.p_end
	var prog = clamp(l.tempo / l.duracao, 0.0, 1.0)
	var alpha = 1.0 - prog
	var cor = l.cor
	
	if l.sucesso:
		match andar_id:
			2: # FÍSICA: Golpe violento de raio / descarga de alta voltagem com zigue-zague e bifurcações
				var dist_strike = p1.distance_to(p2)
				var dir_s = (p2 - p1) / dist_strike
				var perp_s = Vector2(-dir_s.y, dir_s.x)
				var num_segs_s = max(6, int(dist_strike / 12.0))
				
				# Trajetória do raio de impacto em zigue-zague fraturado
				var pts_strike = PackedVector2Array()
				pts_strike.append(p1)
				for i in range(1, num_segs_s):
					var t = float(i) / float(num_segs_s)
					var p_base = p1.lerp(p2, t)
					var seed_s = float(i) * 29.83 + (1.0 - alpha) * 47.11
					var j_perp = (fmod(abs(sin(seed_s) * 31415.9), 1.0) * 2.0 - 1.0) * (sin(t * PI) * 18.0)
					pts_strike.append(p_base + perp_s * j_perp)
				pts_strike.append(p2)
				
				# Camadas do raio de impacto
				for i in range(pts_strike.size() - 1):
					canvas.draw_line(pts_strike[i], pts_strike[i + 1], Color(0.95, 0.52, 0.16, 0.40 * alpha), 18.0 * alpha, true)
					canvas.draw_line(pts_strike[i], pts_strike[i + 1], Color(0.15, 0.95, 1.0, 0.95 * alpha), 7.5 * alpha, true)
					canvas.draw_line(pts_strike[i], pts_strike[i + 1], Color(1.0, 1.0, 1.0, alpha), 3.0 * alpha, true)
				
				# Ramificações explosivas do raio
				for f in range(2):
					var f_idx = int(num_segs_s * (0.35 + float(f) * 0.35))
					if f_idx < pts_strike.size():
						var p_orig = pts_strike[f_idx]
						var sign_f = 1.0 if f % 2 == 0 else -1.0
						var p_f_mid = p_orig + (dir_s * 0.4 + perp_s * (0.8 * sign_f)).normalized() * 16.0
						var p_f_end = p_f_mid + (dir_s * 0.7 + perp_s * (0.5 * sign_f)).normalized() * 14.0
						canvas.draw_line(p_orig, p_f_mid, Color(0.15, 0.95, 1.0, 0.90 * alpha), 2.5 * alpha, true)
						canvas.draw_line(p_f_mid, p_f_end, Color(1.0, 1.0, 1.0, 0.95 * alpha), 1.4 * alpha, true)
				
				# Ondas de choque e centelhas radiais nos nós terminais
				var r_wave = 10.0 + prog * 28.0
				canvas.draw_arc(p1, r_wave, 0.0, TAU, 28, Color(0.15, 0.95, 1.0, alpha * 0.85), 2.5)
				canvas.draw_arc(p2, r_wave, 0.0, TAU, 28, Color(0.95, 0.52, 0.16, alpha * 0.85), 2.5)
				for k in range(4):
					var ang_k = float(k) * (TAU / 4.0) + prog * 1.5
					var p_k1 = p1 + Vector2(cos(ang_k), sin(ang_k)) * (r_wave + 6.0)
					var p_k2 = p2 + Vector2(cos(ang_k), sin(ang_k)) * (r_wave + 6.0)
					canvas.draw_line(p1, p_k1, Color(0.15, 0.95, 1.0, alpha * 0.80), 2.0 * alpha, true)
					canvas.draw_line(p2, p_k2, Color(1.0, 0.90, 0.40, alpha * 0.80), 2.0 * alpha, true)

			3: # BIOLOGIA: Vinha florescendo com folhas e pétalas desabrochando (sem qualquer efeito de raio ou onda)
				var dist_bio = p1.distance_to(p2)
				var dir_b = (p2 - p1) / dist_bio
				var perp_b = Vector2(-dir_b.y, dir_b.x)
				var segs_florece = 20
				var sag_acerto = min(10.0, dist_bio * 0.05)
				
				var pts_flor = PackedVector2Array()
				pts_flor.append(p1)
				for i in range(1, segs_florece):
					var t = float(i) / float(segs_florece)
					var p_base = p1.lerp(p2, t)
					var curv = perp_b * (sin(t * PI) * sag_acerto)
					pts_flor.append(p_base + curv)
				pts_flor.append(p2)
				
				# Caule vegetal curvo verde crescendo
				for i in range(pts_flor.size() - 1):
					canvas.draw_line(pts_flor[i], pts_flor[i + 1], Color(0.12, 0.32, 0.14, 0.90 * alpha), 5.6 * alpha, true)
					canvas.draw_line(pts_flor[i], pts_flor[i + 1], Color(0.26, 0.68, 0.28, 0.95 * alpha), 2.8 * alpha, true)
				
				# Flores e brotos desabrochando ao longo da vinha
				var t_flores = [0.25, 0.50, 0.75]
				for tf in t_flores:
					var p_centro_flor = p1.lerp(p2, tf) + perp_b * (sin(tf * PI) * sag_acerto)
					var r_petala = (3.5 + prog * 4.5) * alpha
					var num_petalas = 5
					for pet in range(num_petalas):
						var ang_pet = float(pet) * (TAU / float(num_petalas))
						var p_pet = p_centro_flor + Vector2(cos(ang_pet), sin(ang_pet)) * (r_petala * 1.2)
						canvas.draw_circle(p_pet, r_petala * 0.7, Color(0.95, 0.88, 0.35, 0.85 * alpha))
					canvas.draw_circle(p_centro_flor, r_petala * 0.6, Color(1.0, 0.70, 0.15, 0.95 * alpha))
				
				# Coroa floral desabrochando nos dois nós terminais
				for no_p in [p1, p2]:
					var r_coroa = 8.0 + prog * 18.0
					var qtd_folhas_no = 6
					for k in range(qtd_folhas_no):
						var ang_f = float(k) * (TAU / float(qtd_folhas_no))
						var p_folha = no_p + Vector2(cos(ang_f), sin(ang_f)) * r_coroa
						canvas.draw_circle(p_folha, max(1.2, 3.2 * alpha), Color(0.30, 0.85, 0.30, 0.85 * alpha))
						var p_ponta = p_folha + Vector2(cos(ang_f), sin(ang_f)) * (4.0 * alpha)
						canvas.draw_line(p_folha, p_ponta, Color(0.20, 0.60, 0.22, 0.90 * alpha), 1.5 * alpha)

			_: # QUÍMICA (1): Torrente de bolhas cáusticas em ascensão rápida e estouro reluzente (sem linhas)
				var dist_anim = p1.distance_to(p2)
				var num_bolhas_anim = max(6, int(dist_anim / 14.0))
				for i in range(num_bolhas_anim + 1):
					var t = float(i) / float(num_bolhas_anim)
					var p_base = p1.lerp(p2, t)
					var seed_a = float(i) * 2.19
					# As bolhas sobem rapidamente enquanto expandem e estouram (fade alpha)
					var sobe_y = Vector2(0.0, -prog * (30.0 + fmod(seed_a * 16.0, 22.0)))
					var deriva_x = Vector2(sin(seed_a + prog * 5.0) * (prog * 14.0), 0.0)
					var pos_b = p_base + sobe_y + deriva_x
					var r_b = (4.0 + fmod(seed_a * 3.2, 4.5)) * (1.0 + prog * 0.9)
					
					canvas.draw_circle(pos_b, r_b, Color(0.70, 0.30, 0.95, 0.40 * alpha))
					canvas.draw_arc(pos_b, r_b, 0.0, TAU, 16, Color(0.95, 0.68, 1.0, 0.85 * alpha), 1.3)
					canvas.draw_circle(pos_b + Vector2(-r_b * 0.35, -r_b * 0.35), max(1.0, r_b * 0.28), Color(1.0, 1.0, 1.0, 0.85 * alpha))
				
				# Anéis orbitais de bolhas estourando nos dois nós
				var r_wave_q = 10.0 + prog * 24.0
				var qtd_pop = 6
				for k in range(qtd_pop):
					var ang_pop = float(k) * (TAU / float(qtd_pop)) + prog * 1.4
					var p_pop1 = p1 + Vector2(cos(ang_pop), sin(ang_pop)) * r_wave_q
					var p_pop2 = p2 + Vector2(cos(ang_pop + PI * 0.5), sin(ang_pop + PI * 0.5)) * r_wave_q
					var r_pop = max(1.2, 3.2 * alpha)
					canvas.draw_circle(p_pop1, r_pop, Color(0.92, 0.65, 1.0, alpha * 0.90))
					canvas.draw_circle(p_pop2, r_pop, Color(0.78, 0.38, 1.0, alpha * 0.90))
	else:
		if andar_id == 1:
			# QUÍMICA (1): Bolhas se desestabilizam e estouram em micro-vapores com ruído de erro
			var num_b_err = max(5, int(p1.distance_to(p2) / 15.0))
			for i in range(num_b_err + 1):
				var t = float(i) / float(num_b_err)
				var jitter = Vector2(sin(l.tempo * 60.0 + i * 2.0) * (8.0 * alpha), -prog * 18.0)
				var pos_err = p1.lerp(p2, t) + jitter
				var r_err = max(1.5, 4.2 * alpha)
				canvas.draw_circle(pos_err, r_err, Color(0.85, 0.25, 0.35, 0.60 * alpha))
				canvas.draw_arc(pos_err, r_err, 0.0, TAU, 14, Color(1.0, 0.45, 0.45, 0.85 * alpha), 1.2)
				canvas.draw_circle(pos_err + Vector2(-r_err * 0.35, -r_err * 0.35), max(0.8, r_err * 0.28), Color(1.0, 0.9, 0.9, 0.85 * alpha))
		elif andar_id == 2:
			# FÍSICA (2): Curto-circuito violento com raios elétricos partidos em centelhas avermelhadas
			var dist_err = p1.distance_to(p2)
			var perp_err = Vector2(-(p2.y - p1.y), p2.x - p1.x).normalized()
			var num_segs_err = max(5, int(dist_err / 13.0))
			var pts_err = PackedVector2Array()
			pts_err.append(p1)
			for i in range(1, num_segs_err):
				var t = float(i) / float(num_segs_err)
				var p_base = p1.lerp(p2, t)
				var j_err = (sin(l.tempo * 65.0 + float(i) * 7.0)) * (14.0 * alpha)
				pts_err.append(p_base + perp_err * j_err)
			pts_err.append(p2)
			
			for i in range(pts_err.size() - 1):
				canvas.draw_line(pts_err[i], pts_err[i + 1], Color(1.0, 0.35, 0.18, 0.90 * alpha), 3.8, true)
				canvas.draw_line(pts_err[i], pts_err[i + 1], Color(1.0, 0.95, 0.85, 0.95 * alpha), 1.5, true)
		else:
			# BIOLOGIA (3): Raminho murchando e folhas secas caindo suavemente (sem faíscas elétricas)
			var dist_murcha = p1.distance_to(p2)
			var segs_m = 12
			var pts_m = PackedVector2Array()
			pts_m.append(p1)
			for i in range(1, segs_m):
				var t = float(i) / float(segs_m)
				var drop_y = Vector2(0.0, prog * 15.0 * sin(t * PI))
				pts_m.append(p1.lerp(p2, t) + drop_y)
			pts_m.append(p2)
			
			for i in range(pts_m.size() - 1):
				canvas.draw_line(pts_m[i], pts_m[i + 1], Color(0.40, 0.32, 0.18, 0.70 * alpha), 3.5, true)
			for fl in range(3):
				var t_fl = 0.25 + fl * 0.25
				var p_fl = p1.lerp(p2, t_fl) + Vector2(sin(prog * 8.0 + fl) * 8.0, prog * 20.0)
				canvas.draw_circle(p_fl, max(1.0, 2.5 * alpha), Color(0.55, 0.40, 0.20, 0.80 * alpha))

func _criar_particulas_acerto(node_alvo: Control) -> void:
	if node_alvo == null or not is_instance_valid(node_alvo): return
	var part = CPUParticles2D.new()
	part.z_index = 25
	part.amount = 18
	part.lifetime = 0.55
	part.one_shot = true
	part.explosiveness = 0.92
	var col = node_alvo.get_meta("coluna", "A")
	part.direction = Vector2(1, 0) if col == "A" else Vector2(-1, 0)
	part.spread = 120.0
	part.scale_amount_min = 2.5
	part.scale_amount_max = 4.5
	
	var grad = Gradient.new()
	match andar_id:
		2: # FÍSICA: Centelhas elétricas e cobre da batalha
			part.gravity = Vector2(0, 30)
			part.initial_velocity_min = 60.0
			part.initial_velocity_max = 110.0
			grad.colors = PackedColorArray([
				Color(0.15, 0.95, 1.0, 1.0),
				Color(0.95, 0.52, 0.16, 0.95),
				Color(1.0, 1.0, 1.0, 0.0)
			])
		3: # BIOLOGIA: Folhas esmeralda e pólen solar da batalha
			part.gravity = Vector2(0, 20)
			part.initial_velocity_min = 35.0
			part.initial_velocity_max = 75.0
			grad.colors = PackedColorArray([
				Color(0.30, 0.85, 0.30, 1.0),
				Color(1.0, 0.84, 0.18, 0.95),
				Color(0.06, 0.15, 0.08, 0.0)
			])
		_: # QUÍMICA (1): Efervescência cáustica em roxo ácido e lilás reluzente
			part.gravity = Vector2(0, -45) # Bolhas sobem!
			part.initial_velocity_min = 40.0
			part.initial_velocity_max = 85.0
			grad.colors = PackedColorArray([
				Color(0.92, 0.65, 1.0, 1.0),
				Color(0.78, 0.38, 1.0, 0.95),
				Color(0.48, 0.18, 0.75, 0.0)
			])
			
	grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	part.color_ramp = grad
	
	node_alvo.add_child(part)
	# Posiciona exatamente no nó de conexão da borda
	part.position = Vector2(node_alvo.size.x, node_alvo.size.y * 0.5) if col == "A" else Vector2(0.0, node_alvo.size.y * 0.5)
	part.emitting = true
	if is_inside_tree() and get_tree():
		get_tree().create_timer(0.65, true, false, true).timeout.connect(part.queue_free)
	else:
		part.queue_free()

func _atualizar_timer_ui() -> void:
	if lbl_timer:
		lbl_timer.text = "TEMPO: %.1fs" % tempo_restante
		if tempo_restante <= 5.0:
			lbl_timer.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
		elif tempo_restante <= 8.0:
			lbl_timer.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		else:
			lbl_timer.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
			
	if progress_timer:
		progress_timer.value = tempo_restante
		var sb = progress_timer.get_theme_stylebox("fill") as StyleBoxFlat
		if sb:
			if tempo_restante <= 5.0:
				sb.bg_color = Color(0.95, 0.2, 0.2)
			elif tempo_restante <= 8.0:
				sb.bg_color = Color(0.95, 0.8, 0.2)
			else:
				sb.bg_color = Color(0.2, 0.75, 1.0)

func _criar_card_recompensa(icone: String, titulo: String, desc: String, cor_destaque: Color) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(170, 56)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.08, 0.18, 0.90) # Fundo azul meia-noite translúcido
	sb.border_color = Color(1.0, 0.82, 0.25, 0.75) # Borda dourada sutil
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", sb)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(hbox)
	
	var lbl_ico = Label.new()
	lbl_ico.text = icone
	lbl_ico.add_theme_font_size_override("font_size", 20)
	hbox.add_child(lbl_ico)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(vbox)
	
	var lbl_tit = Label.new()
	lbl_tit.text = titulo
	lbl_tit.add_theme_font_size_override("font_size", 12)
	lbl_tit.add_theme_color_override("font_color", cor_destaque)
	vbox.add_child(lbl_tit)
	
	var lbl_desc = Label.new()
	lbl_desc.text = desc
	lbl_desc.add_theme_font_size_override("font_size", 11)
	lbl_desc.add_theme_color_override("font_color", Color(0.85, 0.90, 0.98))
	vbox.add_child(lbl_desc)
	
	return card

func _ao_clicar_continuar() -> void:
	if _fechamento_iniciado:
		return
	_fechamento_iniciado = true
	_fechar_e_emitir(_ultimo_foi_vitoria)

func _finalizar_vitoria() -> void:
	if _finalizado:
		return
	_finalizado = true
	jogo_ativo = false
	bloqueio_input = true
	_ultimo_foi_vitoria = true
	_fechamento_iniciado = false
	
	_tocar_sfx("win")
	
	# Dispara explosão comemorativa de confetes/partículas temáticas
	var vp_size = get_viewport().get_visible_rect().size
	_disparar_confetes_vitoria(vp_size * 0.5)
	
	var tema = _obter_tema()
	var sb_banner = banner_resultado.get_theme_stylebox("panel") as StyleBoxFlat
	if sb_banner:
		match andar_id:
			2: # Física: Cobre escuro / Marrom forja com friso de cobre polido e glow âmbar da batalha
				sb_banner.bg_color = Color(0.13, 0.08, 0.06, 0.98)
				sb_banner.border_color = Color(0.95, 0.52, 0.16, 1.0)
				sb_banner.shadow_color = Color(0.90, 0.45, 0.12, 0.45)
			3: # Biologia: Verde floresta profundo com friso esmeralda vivo da batalha
				sb_banner.bg_color = Color(0.04, 0.10, 0.05, 0.98)
				sb_banner.border_color = Color(0.30, 0.85, 0.30, 1.0)
				sb_banner.shadow_color = Color(0.15, 0.70, 0.25, 0.45)
			_: # Química: Safira arcana profunda da batalha com borda e glow em roxo ácido
				sb_banner.bg_color = Color(0.04, 0.05, 0.22, 0.98)
				sb_banner.border_color = Color(0.78, 0.42, 1.0, 1.0)
				sb_banner.shadow_color = Color(0.55, 0.20, 0.95, 0.45)
		
	lbl_banner_emblema.text = tema.get("emblema_vitoria", "⚡  VITÓRIA ELEMENTAL  ⚡")
	lbl_banner_emblema.add_theme_color_override("font_color", tema.get("cor_secundaria", Color(1.0, 0.88, 0.45)))
		
	lbl_banner_titulo.text = tema.get("titulo_vitoria", "BARREIRA RÚNICA DESTRUÍDA!")
	lbl_banner_titulo.add_theme_color_override("font_color", tema.get("cor_secundaria", Color(1.0, 0.90, 0.35)))
	
	lbl_banner_sub.text = tema.get("sub_vitoria", "Conexões estabelecidas com perfeição!")
	lbl_banner_sub.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
	
	for c in box_banner_recompensas.get_children():
		c.queue_free()
		
	box_banner_recompensas.add_child(_criar_card_recompensa(tema.get("card_1_ico", "💥"), tema.get("card_1_tit", "Dano Massivo"), tema.get("card_1_desc", "-40 HP"), Color(1.0, 0.45, 0.45)))
	box_banner_recompensas.add_child(_criar_card_recompensa(tema.get("card_2_ico", "🔮"), tema.get("card_2_tit", "Quebra Elemental"), tema.get("card_2_desc", "Blindagem Destruída!"), tema.get("cor_col_a", Color(0.4, 0.88, 1.0))))
	
	btn_banner_continuar.text = "✨ CONTINUAR [ESPAÇO] ✨"
	
	banner_resultado.visible = true
	banner_resultado.modulate.a = 0.0
	banner_resultado.scale = Vector2(0.8, 0.8)
	
	# Efeito de brilho reluzente passando de lado contínuo e imediato
	_aplicar_efeito_sheen(banner_resultado, Color(1.0, 0.95, 0.80, 0.65), 1.6)
	
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(banner_resultado, "modulate:a", 1.0, 0.25)
	tw.tween_property(banner_resultado, "scale", Vector2(1.0, 1.0), 0.25)
	
	# Auto-fechamento após 4.2 segundos caso o jogador não clique
	get_tree().create_timer(4.2, true, false, true).timeout.connect(func():
		if not _fechamento_iniciado:
			_ao_clicar_continuar()
	)

func _disparar_confetes_vitoria(pos_centro: Vector2) -> void:
	var part = CPUParticles2D.new()
	part.name = "ConfetesVitoria"
	part.z_index = 60
	part.amount = 46
	part.lifetime = 1.35
	part.one_shot = true
	part.explosiveness = 0.95
	part.direction = Vector2(0, -1)
	part.spread = 180.0
	part.gravity = Vector2(0, 160)
	part.initial_velocity_min = 120.0
	part.initial_velocity_max = 250.0
	part.scale_amount_min = 3.0
	part.scale_amount_max = 5.5
	
	var grad = Gradient.new()
	match andar_id:
		2: # FÍSICA: Arco voltaico cyan, cobre polido, âmbar da forja, branco
			grad.colors = PackedColorArray([
				Color(0.15, 0.95, 1.0, 1.0),
				Color(0.95, 0.52, 0.16, 1.0),
				Color(1.0, 0.92, 0.35, 1.0),
				Color(1.0, 1.0, 1.0, 1.0),
				Color(0.15, 0.95, 1.0, 0.0)
			])
		3: # BIOLOGIA: Verde esmeralda vivo, pólen solar dourado, broto jovem, branco
			grad.colors = PackedColorArray([
				Color(0.30, 0.85, 0.30, 1.0),
				Color(1.0, 0.84, 0.18, 1.0),
				Color(0.45, 0.95, 0.40, 1.0),
				Color(1.0, 1.0, 1.0, 1.0),
				Color(0.30, 0.85, 0.30, 0.0)
			])
		_: # QUÍMICA (1): Roxo ácido, lilás reluzente, safira arcana da batalha, branco
			grad.colors = PackedColorArray([
				Color(0.78, 0.38, 1.0, 1.0),
				Color(0.92, 0.65, 1.0, 1.0),
				Color(0.20, 0.45, 0.88, 1.0),
				Color(1.0, 1.0, 1.0, 1.0),
				Color(0.78, 0.38, 1.0, 0.0)
			])
			
	grad.offsets = PackedFloat32Array([0.0, 0.25, 0.50, 0.75, 1.0])
	part.color_ramp = grad
	
	add_child(part)
	part.position = pos_centro
	part.emitting = true
	part.restart()
	get_tree().create_timer(1.5, true, false, true).timeout.connect(part.queue_free)

func _finalizar_derrota() -> void:
	if _finalizado:
		return
	_finalizado = true
	jogo_ativo = false
	bloqueio_input = true
	_ultimo_foi_vitoria = false
	_fechamento_iniciado = false
	
	_tocar_sfx("fail")
	
	var tema = _obter_tema()
	var sb_banner = banner_resultado.get_theme_stylebox("panel") as StyleBoxFlat
	if sb_banner:
		sb_banner.bg_color = Color(0.18, 0.05, 0.08, 0.98) # Vermelho rubi escuro
		sb_banner.border_color = Color(1.0, 0.35, 0.35, 1.0) # Borda vermelha
		sb_banner.shadow_color = Color(0.9, 0.2, 0.2, 0.4)
		
	lbl_banner_emblema.text = tema.get("emblema_derrota", "⚠️  DESCARGA RÚNICA  ⚠️")
	lbl_banner_emblema.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
		
	lbl_banner_titulo.text = tema.get("titulo_derrota", "ATAQUE REPELIDO!")
	lbl_banner_titulo.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	
	lbl_banner_sub.text = tema.get("sub_derrota", "A barreira repeliu seu feitiço!")
	lbl_banner_sub.add_theme_color_override("font_color", Color(0.95, 0.8, 0.8))
	
	for c in box_banner_recompensas.get_children():
		c.queue_free()
		
	var ico_d = "⚡" if andar_id == 2 else ("🥀" if andar_id == 3 else "☣️")
	var tit_d = "Choque Reversivo" if andar_id == 2 else ("Espinhos Orgânicos" if andar_id == 3 else "Respingos Cáusticos")
	var desc_d = "-20 HP de Descarga no Mago" if andar_id == 2 else ("-20 HP de Perfuração no Mago" if andar_id == 3 else "-20 HP de Corrosão no Mago")
	box_banner_recompensas.add_child(_criar_card_recompensa(ico_d, tit_d, desc_d, Color(1.0, 0.35, 0.35)))
	
	btn_banner_continuar.text = "✕ CONTINUAR [ESPAÇO]"
	
	banner_resultado.visible = true
	banner_resultado.modulate.a = 0.0
	banner_resultado.scale = Vector2(0.8, 0.8)
	
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(banner_resultado, "modulate:a", 1.0, 0.25)
	tw.tween_property(banner_resultado, "scale", Vector2(1.0, 1.0), 0.25)
	
	get_tree().create_timer(3.5, true, false, true).timeout.connect(func():
		if not _fechamento_iniciado:
			_ao_clicar_continuar()
	)

func _fechar_e_emitir(vitoria: bool) -> void:
	remove_from_group("minigame_ativo")
	remove_from_group("interacao_ativa")
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(painel_central, "modulate:a", 0.0, 0.2)
	tw.tween_property(painel_central, "scale", Vector2(0.8, 0.8), 0.2)
	tw.tween_property(backdrop, "modulate:a", 0.0, 0.2)
	await tw.finished
	
	conexao_concluida.emit(vitoria)
	queue_free()

func _tocar_sfx(nome: String) -> void:
	if not is_inside_tree():
		return
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx(nome)

func _aplicar_efeito_sheen(alvo: Control, cor_brilho: Color = Color(1.0, 1.0, 1.0, 0.55), intervalo: float = 1.8) -> void:
	if alvo == null or not is_instance_valid(alvo):
		return
	alvo.clip_contents = true
	
	var antigo = alvo.get_node_or_null("SheenEffect")
	if antigo:
		antigo.queue_free()
	
	var sheen = TextureRect.new()
	sheen.name = "SheenEffect"
	sheen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	var grad = Gradient.new()
	grad.colors = PackedColorArray([
		Color(1, 1, 1, 0.0),
		Color(cor_brilho.r, cor_brilho.g, cor_brilho.b, cor_brilho.a * 0.35),
		cor_brilho,
		Color(1.0, 1.0, 1.0, min(1.0, cor_brilho.a * 1.5)),
		cor_brilho,
		Color(cor_brilho.r, cor_brilho.g, cor_brilho.b, cor_brilho.a * 0.35),
		Color(1, 1, 1, 0.0)
	])
	grad.offsets = PackedFloat32Array([0.0, 0.30, 0.46, 0.50, 0.54, 0.70, 1.0])
	
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0.0, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 120
	tex.height = 128
	sheen.texture = tex
	
	alvo.add_child(sheen)
	
	alvo.resized.connect(func():
		_iniciar_animacao_sheen(alvo, sheen, intervalo)
	)
	_iniciar_animacao_sheen(alvo, sheen, intervalo)

func _iniciar_animacao_sheen(alvo: Control, sheen: TextureRect, intervalo: float) -> void:
	if not is_instance_valid(alvo) or not is_instance_valid(sheen): return
	var w = max(alvo.size.x, alvo.custom_minimum_size.x)
	var h = max(alvo.size.y, alvo.custom_minimum_size.y)
	if w <= 0 or h <= 0: return
	
	sheen.size = Vector2(w * 0.55, h * 2.6)
	sheen.rotation = deg_to_rad(24.0)
	sheen.pivot_offset = sheen.size * 0.5
	sheen.position = Vector2(-sheen.size.x * 2.2, -h * 0.8)
	
	var tw = sheen.create_tween().set_loops().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	# Executa imediatamente a varredura e depois aguarda o intervalo em loop
	tw.tween_property(sheen, "position:x", w + sheen.size.x * 1.5, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(sheen, "position:x", -sheen.size.x * 2.2, 0.0)
	tw.tween_interval(intervalo)

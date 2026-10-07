extends CanvasLayer

# minigame de ligar pares

signal conexao_concluida(vitoria: bool)

var andar_id: int = 1
var duracao_total: float = 20.0
var tempo_restante: float = 20.0
var jogo_ativo: bool = false
var bloqueio_input: bool = false

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
var painel_central: PanelContainer
var overlay_conexoes: Control
var lbl_timer: Label
var progress_timer: ProgressBar
var lbl_pares: Label
var col_a_container: VBoxContainer
var col_b_container: VBoxContainer
var banner_resultado: PanelContainer
var lbl_banner_titulo: Label
var lbl_banner_sub: Label

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
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if bloco_selecionado != null:
			_desselecionar_bloco()
		else:
			_finalizar_derrota()
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

# inicia o minigame com base no andar
func iniciar_conexao(p_andar_id: int = 1) -> void:
	if col_a_container == null:
		_construir_interface()
		
	andar_id = p_andar_id
	tempo_restante = duracao_total
	pares_conectados = 0
	bloco_selecionado = null
	bloco_hover_alvo = null
	esta_arrastando = false
	bloqueio_input = false
	linhas_animadas.clear()
	tempo_anim_global = 0.0
	
	_gerar_blocos()
	_atualizar_timer_ui()
	if lbl_pares:
		lbl_pares.text = "CONECTADOS: 0 / 3"
	jogo_ativo = true
	
	if painel_central:
		painel_central.modulate.a = 0.0
		painel_central.scale = Vector2(0.85, 0.85)
		var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(painel_central, "modulate:a", 1.0, 0.25)
		tween.tween_property(painel_central, "scale", Vector2(1.0, 1.0), 0.25)

	_tocar_sfx("ui_5")

func _construir_interface() -> void:
	backdrop = ColorRect.new()
	backdrop.color = Color(0.04, 0.03, 0.08, 0.88)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(_ao_gui_input_backdrop)
	add_child(backdrop)
	
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
	painel_central.custom_minimum_size = Vector2(780, 540)
	painel_central.pivot_offset = Vector2(390, 270)
	
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
	
	var lbl_titulo = Label.new()
	lbl_titulo.text = "CONEXÃO RÚNICA: QUEBRA DE BARREIRA"
	lbl_titulo.add_theme_font_override("font", font_titulo)
	lbl_titulo.add_theme_font_size_override("font_size", 20)
	lbl_titulo.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_titulos.add_child(lbl_titulo)
	
	var lbl_sub = Label.new()
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
	lbl_pares.text = "CONECTADOS: 0 / 3"
	lbl_pares.add_theme_font_override("font", font_titulo)
	lbl_pares.add_theme_font_size_override("font_size", 16)
	lbl_pares.add_theme_color_override("font_color", Color(0.95, 0.82, 0.35))
	hbox_status.add_child(lbl_pares)
	
	# duas colunas de blocos com cabeçalhos e canal central de ligação
	var hbox_colunas = HBoxContainer.new()
	hbox_colunas.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_colunas.add_theme_constant_override("separation", 48)
	hbox_colunas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox_main.add_child(hbox_colunas)
	
	# Coluna A (Termos / Símbolos)
	var vbox_col_a = VBoxContainer.new()
	vbox_col_a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_col_a.add_theme_constant_override("separation", 8)
	hbox_colunas.add_child(vbox_col_a)
	
	var lbl_col_a = Label.new()
	lbl_col_a.text = "◆ TERMO / SÍMBOLO ◆"
	lbl_col_a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_col_a.add_theme_font_override("font", font_titulo)
	lbl_col_a.add_theme_font_size_override("font_size", 13)
	lbl_col_a.add_theme_color_override("font_color", Color(0.78, 0.58, 1.0))
	vbox_col_a.add_child(lbl_col_a)
	
	col_a_container = VBoxContainer.new()
	col_a_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_a_container.add_theme_constant_override("separation", 14)
	col_a_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_col_a.add_child(col_a_container)
	
	# Coluna B (Conceitos / Significados)
	var vbox_col_b = VBoxContainer.new()
	vbox_col_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_col_b.add_theme_constant_override("separation", 8)
	hbox_colunas.add_child(vbox_col_b)
	
	var lbl_col_b = Label.new()
	lbl_col_b.text = "◆ CONCEITO / SIGNIFICADO ◆"
	lbl_col_b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_col_b.add_theme_font_override("font", font_titulo)
	lbl_col_b.add_theme_font_size_override("font_size", 13)
	lbl_col_b.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	vbox_col_b.add_child(lbl_col_b)
	
	col_b_container = VBoxContainer.new()
	col_b_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_b_container.add_theme_constant_override("separation", 14)
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
	banner_resultado.custom_minimum_size = Vector2(520, 160)
	banner_resultado.visible = false
	
	var sb_banner = StyleBoxFlat.new()
	sb_banner.bg_color = Color(0.05, 0.04, 0.09, 0.98)
	sb_banner.border_width_left = 3
	sb_banner.border_width_right = 3
	sb_banner.border_width_top = 3
	sb_banner.border_width_bottom = 3
	sb_banner.border_color = Color(1.0, 0.85, 0.3)
	sb_banner.corner_radius_top_left = 10
	sb_banner.corner_radius_top_right = 10
	sb_banner.corner_radius_bottom_left = 10
	sb_banner.corner_radius_bottom_right = 10
	sb_banner.shadow_size = 25
	sb_banner.content_margin_left = 20
	sb_banner.content_margin_right = 20
	sb_banner.content_margin_top = 16
	sb_banner.content_margin_bottom = 16
	banner_resultado.add_theme_stylebox_override("panel", sb_banner)
	
	var vbox_b = VBoxContainer.new()
	vbox_b.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_b.add_theme_constant_override("separation", 8)
	banner_resultado.add_child(vbox_b)
	
	lbl_banner_titulo = Label.new()
	lbl_banner_titulo.add_theme_font_override("font", font_titulo)
	lbl_banner_titulo.add_theme_font_size_override("font_size", 22)
	lbl_banner_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_b.add_child(lbl_banner_titulo)
	
	lbl_banner_sub = Label.new()
	lbl_banner_sub.add_theme_font_override("font", font_sans)
	lbl_banner_sub.add_theme_font_size_override("font_size", 14)
	lbl_banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_b.add_child(lbl_banner_sub)
	
	center_banner.add_child(banner_resultado)

func _ao_gui_input_backdrop(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if bloco_selecionado != null and not bloqueio_input:
			_desselecionar_bloco()

func _gerar_blocos() -> void:
	# limpa blocos antigos
	for child in col_a_container.get_children():
		child.queue_free()
	for child in col_b_container.get_children():
		child.queue_free()
		
	var pool_pares: Array = PARES_POR_ANDAR.get(andar_id, PARES_POR_ANDAR[1]).duplicate()
	pool_pares.shuffle()
	
	var pares_selecionados = pool_pares.slice(0, 3)
	
	var lista_a = []
	var lista_b = []
	
	for i in range(pares_selecionados.size()):
		var p = pares_selecionados[i]
		lista_a.append({"par_id": i, "texto": p["termo_a"], "coluna": "A"})
		lista_b.append({"par_id": i, "texto": p["termo_b"], "coluna": "B"})
		
	# embaralha as colunas
	lista_a.shuffle()
	lista_b.shuffle()
	
	for d in lista_a:
		var btn = _criar_botao_bloco(d, Color(0.65, 0.45, 0.95))
		col_a_container.add_child(btn)
		
	for d in lista_b:
		var btn = _criar_botao_bloco(d, Color(0.3, 0.75, 1.0))
		col_b_container.add_child(btn)

func _criar_botao_bloco(dados: Dictionary, cor_borda: Color) -> Button:
	var btn = Button.new()
	btn.text = str(dados.get("texto", ""))
	btn.custom_minimum_size = Vector2(300, 68)
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.pivot_offset = Vector2(150, 34)
	
	var font_card = SystemFont.new()
	font_card.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "sans-serif"])
	font_card.font_weight = 700
	btn.add_theme_font_override("font", font_card)
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	
	var col = str(dados.get("coluna", "A"))
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.08, 0.18, 0.96)
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
	sb_hover.border_color = Color(1.0, 0.88, 0.35)
	sb_hover.bg_color = Color(0.16, 0.12, 0.28, 0.96)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_hover)
	
	btn.set_meta("par_id", int(dados.get("par_id", -1)))
	btn.set_meta("coluna", col)
	btn.set_meta("cor_borda", cor_borda)
	btn.set_meta("resolvido", false)
	
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
			if child.get_global_rect().has_point(pos_global):
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
		if destacar:
			sb.border_color = Color(1.0, 0.88, 0.35)
			sb.bg_color = Color(0.18, 0.14, 0.32, 0.98)
			btn.scale = Vector2(1.04, 1.04)
		else:
			sb.border_color = btn.get_meta("cor_borda", Color(0.65, 0.45, 0.95))
			sb.bg_color = Color(0.10, 0.08, 0.18, 0.96)
			btn.scale = Vector2(1.0, 1.0)

func _restaurar_cor_bloco(btn: Button) -> void:
	if not is_instance_valid(btn): return
	var sb = btn.get_theme_stylebox("normal") as StyleBoxFlat
	if sb:
		sb.border_color = btn.get_meta("cor_borda", Color(0.65, 0.45, 0.95))
		sb.bg_color = Color(0.10, 0.08, 0.18, 0.96)
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
		
		# Registra linha de conexão bem-sucedida
		linhas_animadas.append({
			"p_start": pos1,
			"p_end": pos2,
			"cor": Color(0.2, 0.98, 0.45),
			"sucesso": true,
			"tempo": 0.0,
			"duracao": 0.45
		})
		
		pares_conectados += 1
		lbl_pares.text = "CONECTADOS: %d / 3" % pares_conectados
		
		# Recompensa com bônus de tempo (+2.0s)
		tempo_restante = min(duracao_total, tempo_restante + 2.0)
		_atualizar_timer_ui()
		_mostrar_bonus_tempo("+2s")
		
		_tocar_sfx("acerto_1")
			
		_aplicar_cor_bloco(b1, Color(0.2, 0.95, 0.45))
		_aplicar_cor_bloco(b2, Color(0.2, 0.95, 0.45))
		
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
		
		if pares_conectados >= 3:
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

func _desenhar_no_bloco(canvas: Control, btn: Button) -> void:
	var pos = _obter_posicao_no(btn)
	var col = btn.get_meta("coluna", "A")
	var is_sel = (btn == bloco_selecionado)
	var is_alvo = (btn == bloco_hover_alvo)
	
	var cor_base = Color(0.72, 0.45, 1.0) if col == "A" else Color(0.3, 0.85, 1.0)
	if is_sel:
		cor_base = Color(1.0, 0.88, 0.35)
	elif is_alvo:
		cor_base = Color(0.3, 1.0, 0.65)
	elif btn.is_hovered():
		cor_base = Color(1.0, 0.88, 0.35)
		
	var r_ext = 9.5
	var r_int = 7.0
	var r_gem = 4.2
	
	if is_sel or is_alvo:
		r_ext = 11.5
		r_int = 8.5
		r_gem = 5.2
		
	# Aura pulsante de energia quando selecionado ou sob a mira
	if is_sel or is_alvo:
		var pulso = fmod(tempo_anim_global * 2.5, 1.0)
		var r_pulse = r_ext + 2.0 + pulso * 8.0
		var a_pulse = (1.0 - pulso) * 0.8
		canvas.draw_arc(pos, r_pulse, 0.0, TAU, 28, Color(cor_base.r, cor_base.g, cor_base.b, a_pulse), 2.0)
		
	# Pino de contato em direção ao canal central
	if col == "A":
		canvas.draw_line(pos + Vector2(6.0, 0.0), pos + Vector2(13.0, 0.0), cor_base, 2.5)
	else:
		canvas.draw_line(pos - Vector2(6.0, 0.0), pos - Vector2(13.0, 0.0), cor_base, 2.5)
		
	# Borda externa do nó (anel metálico rúnico)
	canvas.draw_circle(pos, r_ext, Color(0.05, 0.04, 0.1, 0.95))
	canvas.draw_arc(pos, r_ext, 0.0, TAU, 24, cor_base, 2.5)
	
	# Interior do soquete
	canvas.draw_circle(pos, r_int, Color(0.08, 0.06, 0.16, 1.0))
	
	# Núcleo / Joia elemental
	canvas.draw_circle(pos, r_gem, cor_base)
	
	# Ponto especular 3D de brilho na joia
	canvas.draw_circle(pos + Vector2(-1.2, -1.2), r_gem * 0.35, Color(1.0, 1.0, 1.0, 0.95))

func _desenhar_linha_ativa(canvas: Control) -> void:
	var p1 = _obter_posicao_no(bloco_selecionado)
	var p2 = Vector2.ZERO
	var cor_linha = Color(1.0, 0.88, 0.35)
	
	if is_instance_valid(bloco_hover_alvo):
		p2 = _obter_posicao_no(bloco_hover_alvo)
		cor_linha = Color(0.3, 1.0, 0.65)
	else:
		p2 = canvas.get_local_mouse_position()
		
	var dist = p1.distance_to(p2)
	if dist < 4.0:
		return
		
	# Brilho externo difuso
	canvas.draw_line(p1, p2, Color(cor_linha.r, cor_linha.g, cor_linha.b, 0.22), 12.0, true)
	# Feixe de energia intermediário
	canvas.draw_line(p1, p2, Color(cor_linha.r, cor_linha.g, cor_linha.b, 0.65), 5.5, true)
	# Núcleo de alta intensidade (laser branco/dourado)
	canvas.draw_line(p1, p2, Color(1.0, 1.0, 1.0, 0.95), 2.0, true)
	
	# Partículas de pulso de energia viajando na linha
	var pulso1 = fmod(tempo_anim_global * 1.8, 1.0)
	var pulso2 = fmod(tempo_anim_global * 1.8 + 0.5, 1.0)
	
	var orb1 = p1.lerp(p2, pulso1)
	var orb2 = p1.lerp(p2, pulso2)
	
	canvas.draw_circle(orb1, 4.5, Color(cor_linha.r, cor_linha.g, cor_linha.b, 0.85))
	canvas.draw_circle(orb1, 2.0, Color(1.0, 1.0, 1.0, 0.95))
	
	canvas.draw_circle(orb2, 4.5, Color(cor_linha.r, cor_linha.g, cor_linha.b, 0.85))
	canvas.draw_circle(orb2, 2.0, Color(1.0, 1.0, 1.0, 0.95))
	
	# Se tiver alvo hovered, desenha anel de mira magnética no alvo
	if is_instance_valid(bloco_hover_alvo):
		var mira_pulse = fmod(tempo_anim_global * 3.0, 1.0)
		canvas.draw_arc(p2, 14.0 + mira_pulse * 4.0, 0.0, TAU, 24, Color(0.3, 1.0, 0.65, (1.0 - mira_pulse) * 0.9), 2.0)

func _desenhar_linha_animada(canvas: Control, l: Dictionary) -> void:
	var p1 = l.p_start
	var p2 = l.p_end
	var prog = clamp(l.tempo / l.duracao, 0.0, 1.0)
	var alpha = 1.0 - prog
	var cor = l.cor
	
	if l.sucesso:
		var w_glow = 16.0 * (1.0 - prog * 0.4)
		var w_mid = 7.0 * (1.0 - prog * 0.3)
		var w_core = 3.0 * (1.0 - prog * 0.3)
		
		canvas.draw_line(p1, p2, Color(cor.r, cor.g, cor.b, 0.35 * alpha), w_glow, true)
		canvas.draw_line(p1, p2, Color(cor.r, cor.g, cor.b, 0.85 * alpha), w_mid, true)
		canvas.draw_line(p1, p2, Color(1.0, 1.0, 1.0, alpha), w_core, true)
		
		# Ondas de choque em anel nos dois nós
		var r_wave = 10.0 + prog * 24.0
		canvas.draw_arc(p1, r_wave, 0.0, TAU, 28, Color(0.2, 1.0, 0.5, alpha * 0.8), 2.5)
		canvas.draw_arc(p2, r_wave, 0.0, TAU, 28, Color(0.2, 1.0, 0.5, alpha * 0.8), 2.5)
	else:
		# Faísca instável de erro com vibração senoidal
		var jitter1 = sin(l.tempo * 65.0) * (7.0 * alpha)
		var jitter2 = -sin(l.tempo * 65.0) * (7.0 * alpha)
		var mid1 = p1.lerp(p2, 0.33) + Vector2(0, jitter1)
		var mid2 = p1.lerp(p2, 0.66) + Vector2(0, jitter2)
		
		canvas.draw_line(p1, mid1, Color(cor.r, cor.g, cor.b, 0.3 * alpha), 10.0, true)
		canvas.draw_line(mid1, mid2, Color(cor.r, cor.g, cor.b, 0.3 * alpha), 10.0, true)
		canvas.draw_line(mid2, p2, Color(cor.r, cor.g, cor.b, 0.3 * alpha), 10.0, true)
		
		canvas.draw_line(p1, mid1, Color(cor.r, cor.g, cor.b, 0.8 * alpha), 4.5, true)
		canvas.draw_line(mid1, mid2, Color(cor.r, cor.g, cor.b, 0.8 * alpha), 4.5, true)
		canvas.draw_line(mid2, p2, Color(cor.r, cor.g, cor.b, 0.8 * alpha), 4.5, true)
		
		canvas.draw_line(p1, mid1, Color(1.0, 0.9, 0.9, 0.9 * alpha), 2.0, true)
		canvas.draw_line(mid1, mid2, Color(1.0, 0.9, 0.9, 0.9 * alpha), 2.0, true)
		canvas.draw_line(mid2, p2, Color(1.0, 0.9, 0.9, 0.9 * alpha), 2.0, true)

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
	part.gravity = Vector2(0, 40)
	part.initial_velocity_min = 40.0
	part.initial_velocity_max = 85.0
	part.scale_amount_min = 2.5
	part.scale_amount_max = 4.5
	
	var grad = Gradient.new()
	grad.colors = PackedColorArray([
		Color(0.35, 1.0, 0.5, 1.0),
		Color(1.0, 0.95, 0.3, 0.9),
		Color(0.2, 0.8, 0.3, 0.0)
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

func _finalizar_vitoria() -> void:
	jogo_ativo = false
	bloqueio_input = true
	
	_tocar_sfx("win")
		
	lbl_banner_titulo.text = "BARREIRA RÚNICA DESTRUÍDA!"
	lbl_banner_titulo.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3))
	
	lbl_banner_sub.text = "Conexões elementais estabelecidas com perfeição!\nO Mago desferiu um DANO CRÍTICO MASSIVO de -40 HP no Campeão!"
	
	banner_resultado.visible = true
	banner_resultado.modulate.a = 0.0
	banner_resultado.scale = Vector2(0.8, 0.8)
	
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(banner_resultado, "modulate:a", 1.0, 0.25)
	tw.tween_property(banner_resultado, "scale", Vector2(1.0, 1.0), 0.25)
	
	await get_tree().create_timer(1.8, true, false, true).timeout
	_fechar_e_emitir(true)

func _finalizar_derrota() -> void:
	jogo_ativo = false
	bloqueio_input = true
	
	_tocar_sfx("fail")
		
	lbl_banner_titulo.text = "DESCARGA RÚNICA!"
	lbl_banner_titulo.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	
	lbl_banner_sub.text = "O tempo esgotou e a barreira repeliu seu ataque!\nVocê sofreu uma descarga de -20 HP do Campeão Rúnico."
	
	banner_resultado.visible = true
	banner_resultado.modulate.a = 0.0
	banner_resultado.scale = Vector2(0.8, 0.8)
	
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(banner_resultado, "modulate:a", 1.0, 0.25)
	tw.tween_property(banner_resultado, "scale", Vector2(1.0, 1.0), 0.25)
	
	await get_tree().create_timer(1.8, true, false, true).timeout
	_fechar_e_emitir(false)

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

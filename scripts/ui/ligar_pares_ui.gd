extends CanvasLayer

# minigame de ligar pares

signal conexao_concluida(vitoria: bool)

var andar_id: int = 1
var duracao_total: float = 15.0
var tempo_restante: float = 15.0
var jogo_ativo: bool = false
var bloqueio_input: bool = false

var pares_conectados: int = 0
var bloco_selecionado: Button = null

# referencias da interface
var backdrop: ColorRect
var painel_central: PanelContainer
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
	layer = 105
	process_mode = Node.PROCESS_MODE_ALWAYS
	_construir_interface()

func _process(delta: float) -> void:
	if not jogo_ativo:
		return
		
	tempo_restante -= delta
	if tempo_restante < 0.0:
		tempo_restante = 0.0
		
	_atualizar_timer_ui()
	
	if tempo_restante <= 0.0:
		_finalizar_derrota()

# inicia o minigame com base no andar
func iniciar_conexao(p_andar_id: int = 1) -> void:
	andar_id = p_andar_id
	tempo_restante = duracao_total
	pares_conectados = 0
	bloco_selecionado = null
	bloqueio_input = false
	
	_gerar_blocos()
	jogo_ativo = true
	
	if painel_central:
		painel_central.modulate.a = 0.0
		painel_central.scale = Vector2(0.85, 0.85)
		var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(painel_central, "modulate:a", 1.0, 0.25)
		tween.tween_property(painel_central, "scale", Vector2(1.0, 1.0), 0.25)

	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui_5")

func _construir_interface() -> void:
	backdrop = ColorRect.new()
	backdrop.color = Color(0.04, 0.03, 0.08, 0.88)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
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
	painel_central.custom_minimum_size = Vector2(760, 520)
	painel_central.pivot_offset = Vector2(380, 260)
	
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
	style_panel.content_margin_top = 22
	style_panel.content_margin_bottom = 22
	painel_central.add_theme_stylebox_override("panel", style_panel)
	center_painel.add_child(painel_central)
	
	var vbox_main = VBoxContainer.new()
	vbox_main.add_theme_constant_override("separation", 12)
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
	lbl_sub.text = "Clique em um termo e conecte com seu conceito correspondente!"
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
	lbl_timer.text = "TEMPO: 15.0s"
	lbl_timer.add_theme_font_override("font", font_titulo)
	lbl_timer.add_theme_font_size_override("font_size", 16)
	lbl_timer.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	hbox_status.add_child(lbl_timer)
	
	progress_timer = ProgressBar.new()
	progress_timer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_timer.custom_minimum_size = Vector2(250, 16)
	progress_timer.max_value = 15.0
	progress_timer.value = 15.0
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
	
	# duas colunas de blocos
	var hbox_colunas = HBoxContainer.new()
	hbox_colunas.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_colunas.add_theme_constant_override("separation", 36)
	hbox_colunas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox_main.add_child(hbox_colunas)
	
	col_a_container = VBoxContainer.new()
	col_a_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_a_container.add_theme_constant_override("separation", 14)
	col_a_container.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_colunas.add_child(col_a_container)
	
	col_b_container = VBoxContainer.new()
	col_b_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_b_container.add_theme_constant_override("separation", 14)
	col_b_container.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_colunas.add_child(col_b_container)
	
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
	btn.custom_minimum_size = Vector2(310, 68)
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.pivot_offset = Vector2(155, 34)
	
	var font_card = SystemFont.new()
	font_card.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "sans-serif"])
	font_card.font_weight = 700
	btn.add_theme_font_override("font", font_card)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	
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
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	btn.add_theme_stylebox_override("normal", sb)
	
	var sb_hover = sb.duplicate()
	sb_hover.border_color = Color(1.0, 0.88, 0.3)
	sb_hover.bg_color = Color(0.16, 0.12, 0.28, 0.96)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_hover)
	
	btn.set_meta("par_id", int(dados.get("par_id", -1)))
	btn.set_meta("coluna", str(dados.get("coluna", "")))
	btn.set_meta("style_normal", sb)
	btn.set_meta("resolvido", false)
	
	btn.pressed.connect(func(): _ao_clicar_bloco(btn))
	return btn

func _ao_clicar_bloco(btn: Button) -> void:
	if not jogo_ativo or bloqueio_input:
		return
	if not is_instance_valid(btn) or btn.get_meta("resolvido", false):
		return
		
	# se clicou no mesmo desmarca
	if bloco_selecionado == btn:
		_desselecionar_bloco()
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("ui-1")
		return
		
	# seleciona o primeiro
	if bloco_selecionado == null:
		bloco_selecionado = btn
		_destacar_bloco(btn, true)
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("ui-1")
		return
		
	# seleciona o segundo
	bloqueio_input = true
	var b1: Button = bloco_selecionado
	var b2: Button = btn
	
	_destacar_bloco(b2, true)
	
	var par_id_1: int = b1.get_meta("par_id", -1)
	var par_id_2: int = b2.get_meta("par_id", -2)
	var col_1: String = b1.get_meta("coluna", "A")
	var col_2: String = b2.get_meta("coluna", "B")
	
	# checa se os dois formam par
	if par_id_1 >= 0 and par_id_1 == par_id_2 and col_1 != col_2:
		# par correto
		b1.set_meta("resolvido", true)
		b2.set_meta("resolvido", true)
		b1.disabled = true
		b2.disabled = true
		
		pares_conectados += 1
		lbl_pares.text = "CONECTADOS: %d / 3" % pares_conectados
		
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("acerto_1")
			
		_aplicar_cor_bloco(b1, Color(0.2, 0.95, 0.45))
		_aplicar_cor_bloco(b2, Color(0.2, 0.95, 0.45))
		
		# animacao de sumir os blocos
		var tw = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(b1, "scale", Vector2(1.12, 1.12), 0.15)
		tw.tween_property(b2, "scale", Vector2(1.12, 1.12), 0.15)
		tw.tween_property(b1, "modulate:a", 0.0, 0.3).set_delay(0.12)
		tw.tween_property(b2, "modulate:a", 0.0, 0.3).set_delay(0.12)
		
		await tw.finished
		b1.visible = false
		b2.visible = false
		
		bloco_selecionado = null
		bloqueio_input = false
		
		if pares_conectados >= 3:
			_finalizar_vitoria()
	else:
		# par errado
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("ui-2")
			
		_aplicar_cor_bloco(b1, Color(0.95, 0.25, 0.25))
		_aplicar_cor_bloco(b2, Color(0.95, 0.25, 0.25))
		
		# treme os dois blocos
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
		bloco_selecionado = null
		bloqueio_input = false

func _destacar_bloco(btn: Button, destacar: bool) -> void:
	if not is_instance_valid(btn): return
	var sb = btn.get_theme_stylebox("normal") as StyleBoxFlat
	if sb:
		if destacar:
			sb.border_color = Color(1.0, 0.88, 0.3)
			sb.bg_color = Color(0.20, 0.16, 0.35, 0.98)
			btn.scale = Vector2(1.04, 1.04)
		else:
			btn.scale = Vector2(1.0, 1.0)

func _desselecionar_bloco() -> void:
	if bloco_selecionado and is_instance_valid(bloco_selecionado):
		_restaurar_cor_bloco(bloco_selecionado)
	bloco_selecionado = null

func _aplicar_cor_bloco(btn: Button, cor: Color) -> void:
	if not is_instance_valid(btn): return
	var sb = btn.get_theme_stylebox("normal") as StyleBoxFlat
	if sb:
		sb.border_color = cor

func _restaurar_cor_bloco(btn: Button) -> void:
	if not is_instance_valid(btn): return
	if btn.has_meta("style_normal"):
		var sb_orig = btn.get_meta("style_normal") as StyleBoxFlat
		btn.add_theme_stylebox_override("normal", sb_orig)
	btn.scale = Vector2(1.0, 1.0)

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
	
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("win")
		
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
	
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("fail")
		
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
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(painel_central, "modulate:a", 0.0, 0.2)
	tw.tween_property(painel_central, "scale", Vector2(0.8, 0.8), 0.2)
	tw.tween_property(backdrop, "modulate:a", 0.0, 0.2)
	await tw.finished
	
	conexao_concluida.emit(vitoria)
	queue_free()

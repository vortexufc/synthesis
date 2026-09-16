extends CanvasLayer

## [Minigame] Desafio da Memória Arcana (Memory Rush)
## Minigame rápido de 15 segundos ativado em Baús Rúnicos/Arcanos.
## Grade 3x2 (6 cartas). O jogador deve encontrar os 3 pares conceituais da disciplina do andar.

signal desafio_concluido(vitoria: bool)

# Referência do jogador travado
var player_ref: Node2D = null

# Configurações do jogo
var andar_id: int = 1
var duracao_total: float = 15.0
var tempo_restante: float = 15.0
var jogo_ativo: bool = false
var bloqueio_input: bool = false

var pares_encontrados: int = 0
var cartas_viradas: Array = [] # [card_data, card_data]
var cartas_nodes: Array = []

# Referências de UI
var backdrop: ColorRect
var painel_central: PanelContainer
var lbl_titulo: Label
var lbl_subtitulo: Label
var lbl_timer: Label
var progress_timer: ProgressBar
var lbl_pares: Label
var grid_cartas: GridContainer
var banner_resultado: PanelContainer
var lbl_banner_titulo: Label
var lbl_banner_sub: Label

# Banco de dados de pares científicos por andar (24 pares por matéria -> mais de 2.000 combinações únicas)
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

var _font_card: SystemFont

func _ready() -> void:
	add_to_group("minigame_ativo")
	add_to_group("desafio_memoria")
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_font_card = SystemFont.new()
	_font_card.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	_font_card.font_weight = 700
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

## Inicia o minigame configurando o andar e travando o jogador
func iniciar_desafio(p_andar_id: int = 1, p_player: Node2D = null) -> void:
	andar_id = p_andar_id
	player_ref = p_player
	if player_ref == null:
		player_ref = get_tree().get_first_node_in_group("player") as Node2D
		
	if player_ref and is_instance_valid(player_ref):
		player_ref.travado = true
		player_ref.em_interacao = true

	tempo_restante = duracao_total
	pares_encontrados = 0
	cartas_viradas.clear()
	bloqueio_input = false
	
	_atualizar_textos_andar()
	_gerar_cartas()
	
	jogo_ativo = true
	
	# Animação de entrada suave
	if painel_central:
		painel_central.modulate.a = 0.0
		painel_central.scale = Vector2(0.85, 0.85)
		var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(painel_central, "modulate:a", 1.0, 0.3)
		tween.tween_property(painel_central, "scale", Vector2(1.0, 1.0), 0.3)

	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui_5")

func _construir_interface() -> void:
	# Fundo vinheta escuro
	backdrop = ColorRect.new()
	backdrop.color = Color(0.03, 0.02, 0.06, 0.85)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)
	
	var font_sans = SystemFont.new()
	font_sans.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_sans.font_weight = 600

	var font_titulo = SystemFont.new()
	font_titulo.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_titulo.font_weight = 700

	# Painel Central
	painel_central = PanelContainer.new()
	painel_central.custom_minimum_size = Vector2(720, 520)
	painel_central.pivot_offset = Vector2(360, 260)
	
	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = Color(0.07, 0.06, 0.12, 0.97)
	style_panel.border_width_left = 3
	style_panel.border_width_right = 3
	style_panel.border_width_top = 3
	style_panel.border_width_bottom = 3
	style_panel.border_color = Color(0.88, 0.72, 0.28, 0.95)
	style_panel.corner_radius_top_left = 12
	style_panel.corner_radius_top_right = 12
	style_panel.corner_radius_bottom_left = 12
	style_panel.corner_radius_bottom_right = 12
	style_panel.shadow_color = Color(0.45, 0.15, 0.75, 0.35)
	style_panel.shadow_size = 20
	style_panel.content_margin_left = 24
	style_panel.content_margin_right = 24
	style_panel.content_margin_top = 20
	style_panel.content_margin_bottom = 20
	# Center Container para o Painel Central
	var center_painel = CenterContainer.new()
	center_painel.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(center_painel)
	center_painel.add_child(painel_central)
	
	var vbox_main = VBoxContainer.new()
	vbox_main.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox_main.add_theme_constant_override("separation", 10)
	painel_central.add_child(vbox_main)
	
	# Top bar (Título e Botão Fechar)
	var hbox_top = HBoxContainer.new()
	vbox_main.add_child(hbox_top)
	
	# Espaçador invisível à esquerda para balancear com o botão fechar e centralizar perfeitamente os títulos
	var spacer_left = Control.new()
	spacer_left.custom_minimum_size = Vector2(36, 32)
	hbox_top.add_child(spacer_left)
	
	var vbox_titulos = VBoxContainer.new()
	vbox_titulos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_titulos.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_titulos.add_theme_constant_override("separation", 2)
	hbox_top.add_child(vbox_titulos)
	
	lbl_titulo = Label.new()
	lbl_titulo.text = "DESAFIO DA MEMÓRIA ARCANA"
	lbl_titulo.add_theme_font_override("font", font_titulo)
	lbl_titulo.add_theme_font_size_override("font_size", 20)
	lbl_titulo.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_titulos.add_child(lbl_titulo)
	
	lbl_subtitulo = Label.new()
	lbl_subtitulo.text = "Encontre os 3 pares correspondentes!"
	lbl_subtitulo.add_theme_font_override("font", font_sans)
	lbl_subtitulo.add_theme_font_size_override("font_size", 13)
	lbl_subtitulo.add_theme_color_override("font_color", Color(0.75, 0.80, 0.95))
	lbl_subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_titulos.add_child(lbl_subtitulo)
	
	var btn_fechar = Button.new()
	btn_fechar.text = " ✕ "
	btn_fechar.custom_minimum_size = Vector2(36, 32)
	btn_fechar.add_theme_font_override("font", font_sans)
	btn_fechar.add_theme_font_size_override("font_size", 16)
	btn_fechar.pressed.connect(_desistir)
	hbox_top.add_child(btn_fechar)
	
	# Linha divisória mágica
	var hsep = HSeparator.new()
	vbox_main.add_child(hsep)
	
	# Seção do Timer e Pares
	var hbox_status = HBoxContainer.new()
	hbox_status.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_status.add_theme_constant_override("separation", 20)
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
	lbl_pares.text = "PARES: 0 / 3"
	lbl_pares.add_theme_font_override("font", font_titulo)
	lbl_pares.add_theme_font_size_override("font_size", 16)
	lbl_pares.add_theme_color_override("font_color", Color(0.95, 0.82, 0.35))
	hbox_status.add_child(lbl_pares)
	
	# Grade 3x2 de Cartas
	var margin_grid = MarginContainer.new()
	margin_grid.add_theme_constant_override("margin_top", 12)
	margin_grid.add_theme_constant_override("margin_bottom", 8)
	vbox_main.add_child(margin_grid)
	
	grid_cartas = GridContainer.new()
	grid_cartas.columns = 3
	grid_cartas.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid_cartas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_cartas.add_theme_constant_override("h_separation", 16)
	grid_cartas.add_theme_constant_override("v_separation", 16)
	margin_grid.add_child(grid_cartas)
	
	# Banner de Resultado (Vitória / Derrota)
	banner_resultado = PanelContainer.new()
	banner_resultado.custom_minimum_size = Vector2(500, 180)
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
	
	var vbox_banner = VBoxContainer.new()
	vbox_banner.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_banner.add_theme_constant_override("separation", 8)
	banner_resultado.add_child(vbox_banner)
	
	lbl_banner_titulo = Label.new()
	lbl_banner_titulo.add_theme_font_override("font", font_titulo)
	lbl_banner_titulo.add_theme_font_size_override("font_size", 22)
	lbl_banner_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_banner.add_child(lbl_banner_titulo)
	
	lbl_banner_sub = Label.new()
	lbl_banner_sub.add_theme_font_override("font", font_sans)
	lbl_banner_sub.add_theme_font_size_override("font_size", 14)
	lbl_banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_banner.add_child(lbl_banner_sub)
	
	var center_banner = CenterContainer.new()
	center_banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(center_banner)
	center_banner.add_child(banner_resultado)

func _atualizar_textos_andar() -> void:
	if lbl_subtitulo:
		lbl_subtitulo.text = "Encontre os 3 pares correspondentes!"

func _gerar_cartas() -> void:
	# Limpa nós anteriores
	for child in grid_cartas.get_children():
		child.queue_free()
	cartas_nodes.clear()
	
	# Seleciona 3 pares aleatórios do andar
	var pool_pares: Array = PARES_POR_ANDAR.get(andar_id, PARES_POR_ANDAR[1]).duplicate()
	pool_pares.shuffle()
	
	var pares_selecionados = pool_pares.slice(0, 3)
	
	# Monta as 6 cartas (2 para cada par)
	var lista_cartas = []
	for i in range(pares_selecionados.size()):
		var p = pares_selecionados[i]
		lista_cartas.append({
			"par_id": i,
			"texto": p["termo_a"],
			"virada": false,
			"resolvida": false
		})
		lista_cartas.append({
			"par_id": i,
			"texto": p["termo_b"],
			"virada": false,
			"resolvida": false
		})
		
	# Embaralha as posições na grade
	lista_cartas.shuffle()
	
	for idx in range(lista_cartas.size()):
		var dados = lista_cartas[idx]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(205, 115)
		btn.pivot_offset = Vector2(102.5, 57.5) # Centro para animação de rotação/flip
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if _font_card:
			btn.add_theme_font_override("font", _font_card)
		
		# Estilo do Verso da Carta (Runa mágica virada para baixo)
		_aplicar_estilo_verso(btn)
		
		btn.pressed.connect(func(): _ao_clicar_carta(btn, dados))
		grid_cartas.add_child(btn)
		
		dados["node"] = btn
		cartas_nodes.append(dados)

func _aplicar_estilo_verso(btn: Button) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.08, 0.22, 0.95)
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.65, 0.45, 0.95, 0.8)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	
	btn.add_theme_stylebox_override("normal", sb)
	
	var sb_hover = sb.duplicate()
	sb_hover.border_color = Color(1.0, 0.85, 0.3, 1.0)
	sb_hover.bg_color = Color(0.18, 0.12, 0.32, 0.95)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_hover)
	
	btn.text = "[ ? ]"
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color(0.85, 0.75, 1.0))

func _aplicar_estilo_frente(btn: Button, texto: String, cor_borda: Color = Color(0.3, 0.85, 1.0)) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.14, 0.22, 0.98)
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.border_color = cor_borda
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("disabled", sb)
	
	btn.text = texto
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

func _ao_clicar_carta(btn: Button, dados: Dictionary) -> void:
	if not jogo_ativo or bloqueio_input:
		return
	if dados["virada"] or dados["resolvida"]:
		return
		
	# Vira a carta atual
	dados["virada"] = true
	cartas_viradas.append(dados)
	
	# Efeito sonoro
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui-1")
		
	# Animação de Flip da Carta (scale.x 1.0 -> 0.0 -> 1.0)
	var tween = create_tween()
	tween.tween_property(btn, "scale:x", 0.0, 0.10).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		_aplicar_estilo_frente(btn, dados["texto"])
	)
	tween.tween_property(btn, "scale:x", 1.0, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Se virou 2 cartas, verifica par
	if cartas_viradas.size() >= 2:
		bloqueio_input = true
		_verificar_par()

func _verificar_par() -> void:
	var c1 = cartas_viradas[0]
	var c2 = cartas_viradas[1]
	
	if c1["par_id"] == c2["par_id"]:
		# PAR ENCONTRADO!
		c1["resolvida"] = true
		c2["resolvida"] = true
		pares_encontrados += 1
		lbl_pares.text = "PARES: %d / 3" % pares_encontrados
		
		# Som de acerto
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("acerto_1")
			
		# Feedback visual verde/dourado nas cartas correspondentes
		_aplicar_estilo_frente(c1["node"], c1["texto"], Color(0.2, 0.95, 0.45))
		_aplicar_estilo_frente(c2["node"], c2["texto"], Color(0.2, 0.95, 0.45))
		
		# Pulsar levemente as cartas que acertaram
		for c in [c1, c2]:
			var tw = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tw.tween_property(c["node"], "scale", Vector2(1.08, 1.08), 0.12)
			tw.tween_property(c["node"], "scale", Vector2(1.0, 1.0), 0.12)
			
		cartas_viradas.clear()
		bloqueio_input = false
		
		# Verifica se ganhou o minigame
		if pares_encontrados >= 3:
			_finalizar_vitoria()
	else:
		# ERROU O PAR!
		# Feedback visual vermelho
		_aplicar_estilo_frente(c1["node"], c1["texto"], Color(0.95, 0.25, 0.25))
		_aplicar_estilo_frente(c2["node"], c2["texto"], Color(0.95, 0.25, 0.25))
		
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("ui-2")
			
		# Aguarda 0.6s para memorização e desvira
		await get_tree().create_timer(0.60, true, false, true).timeout
		
		for c in [c1, c2]:
			var tw = create_tween()
			tw.tween_property(c["node"], "scale:x", 0.0, 0.09)
			tw.tween_callback(func():
				c["virada"] = false
				_aplicar_estilo_verso(c["node"])
			)
			tw.tween_property(c["node"], "scale:x", 1.0, 0.09)
			
		cartas_viradas.clear()
		bloqueio_input = false

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
		
	lbl_banner_titulo.text = "SELO ARCANO ROMPIDO!"
	lbl_banner_titulo.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3))
	
	lbl_banner_sub.text = "Você decifrou todas as runas conceituais com perfeição!\n\n"
	lbl_banner_sub.text += "RECOMPENSAS:\n"
	lbl_banner_sub.text += "• 1x Poção de Cura no Inventário\n"
	lbl_banner_sub.text += "• +30 Moedas de Ouro\n"
	lbl_banner_sub.text += "• Escudo Arcano (+10 Vida Máxima pelas próximas 2 salas)"
	
	banner_resultado.visible = true
	banner_resultado.modulate.a = 0.0
	banner_resultado.scale = Vector2(0.8, 0.8)
	
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(banner_resultado, "modulate:a", 1.0, 0.25)
	tw.tween_property(banner_resultado, "scale", Vector2(1.0, 1.0), 0.25)
	
	await get_tree().create_timer(2.4, true, false, true).timeout
	_fechar_e_emitir(true)

func _finalizar_derrota() -> void:
	jogo_ativo = false
	bloqueio_input = true
	
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("fail")
		
	# Causa dano de armadilha no jogador pelo tempo esgotado
	if get_node_or_null("/root/PlayerStats"):
		PlayerStats.sofrer_dano(15.0)
		
	lbl_banner_titulo.text = "ARMADILHA DO BAÚ DISPARADA!"
	lbl_banner_titulo.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	
	lbl_banner_sub.text = "O tempo esgotou e o selo arcano entrou em colapso!\nVocê sofreu uma descarga de -15 HP de armadilha."
	
	banner_resultado.visible = true
	banner_resultado.modulate.a = 0.0
	banner_resultado.scale = Vector2(0.8, 0.8)
	
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(banner_resultado, "modulate:a", 1.0, 0.25)
	tw.tween_property(banner_resultado, "scale", Vector2(1.0, 1.0), 0.25)
	
	await get_tree().create_timer(1.8, true, false, true).timeout
	_fechar_e_emitir(false)

func _desistir() -> void:
	if not jogo_ativo:
		return
	jogo_ativo = false
	_fechar_e_emitir(false)

func _fechar_e_emitir(vitoria: bool) -> void:
	if player_ref and is_instance_valid(player_ref):
		if player_ref.has_method("finalizar_interacao"):
			player_ref.finalizar_interacao(0.8)
		else:
			player_ref.travado = false
			player_ref.em_interacao = false
		player_ref = null
		
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(painel_central, "modulate:a", 0.0, 0.2)
	tw.tween_property(painel_central, "scale", Vector2(0.8, 0.8), 0.2)
	tw.tween_property(backdrop, "modulate:a", 0.0, 0.2)
	await tw.finished
	
	desafio_concluido.emit(vitoria)
	queue_free()

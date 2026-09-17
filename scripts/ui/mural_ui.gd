extends CanvasLayer

# tela do mural de inscricoes das salas

signal mural_fechado()

var andar_id: int = 1
var player_ref: Node2D = null

# referencias da interface
var backdrop: ColorRect
var painel_central: PanelContainer
var lbl_titulo_mural: Label
var lbl_subtitulo_mural: Label
var container_diagrama: VBoxContainer
var painel_detalhes: PanelContainer
var lbl_detalhe_titulo: Label
var lbl_detalhe_corpo: Label
var lbl_detalhe_dica: Label
var btn_fechar_topo: Button
var btn_fechar_rodape: Button
var botoes_elementos: Array = []

var font_sans: SystemFont
var font_titulo: SystemFont

func _ready() -> void:
	layer = 105
	process_mode = Node.PROCESS_MODE_ALWAYS
	_garantir_fontes()
	_construir_base_ui()
	hide()

func _garantir_fontes() -> void:
	if font_sans == null:
		font_sans = SystemFont.new()
		font_sans.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
		font_sans.font_weight = 600
	if font_titulo == null:
		font_titulo = SystemFont.new()
		font_titulo.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
		font_titulo.font_weight = 700

func _tocar_som(nome_som: String) -> void:
	if not is_inside_tree():
		return
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx(nome_som)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F):
		get_viewport().set_input_as_handled()
		fechar_mural()

# abre o mural do andar certo
func abrir_mural(p_andar_id: int = 1, p_player: Node2D = null) -> void:
	andar_id = p_andar_id
	player_ref = p_player
	if player_ref == null and is_inside_tree() and get_tree():
		player_ref = get_tree().get_first_node_in_group("player") as Node2D
		
	if player_ref and is_instance_valid(player_ref):
		player_ref.travado = true

	if painel_central == null:
		_construir_base_ui()

	_tocar_som("ui_5")

	_montar_conteudo_andar(andar_id)
	
	show()
	if painel_central:
		painel_central.modulate.a = 0.0
		painel_central.scale = Vector2(0.88, 0.88)
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(painel_central, "modulate:a", 1.0, 0.25)
		tw.tween_property(painel_central, "scale", Vector2(1.0, 1.0), 0.25)

func fechar_mural() -> void:
	if not visible:
		return
	_tocar_som("ui-1")
		
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(painel_central, "modulate:a", 0.0, 0.2)
	tw.tween_property(painel_central, "scale", Vector2(0.85, 0.85), 0.2)
	tw.tween_property(backdrop, "modulate:a", 0.0, 0.2)
	await tw.finished

	hide()
	backdrop.modulate.a = 1.0
	
	if player_ref and is_instance_valid(player_ref):
		player_ref.travado = false
		
	mural_fechado.emit()

func _construir_base_ui() -> void:
	_garantir_fontes()
	for c in get_children():
		c.queue_free()

	backdrop = ColorRect.new()
	backdrop.color = Color(0.04, 0.03, 0.08, 0.90)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(center)

	painel_central = PanelContainer.new()
	painel_central.custom_minimum_size = Vector2(910, 610)
	painel_central.pivot_offset = Vector2(455, 305)
	painel_central.mouse_filter = Control.MOUSE_FILTER_STOP

	var sb_painel = StyleBoxFlat.new()
	sb_painel.bg_color = Color(0.08, 0.07, 0.14, 0.98)
	sb_painel.border_color = Color(1.0, 0.84, 0.35)
	sb_painel.border_width_left = 3
	sb_painel.border_width_right = 3
	sb_painel.border_width_top = 3
	sb_painel.border_width_bottom = 3
	sb_painel.corner_radius_top_left = 12
	sb_painel.corner_radius_top_right = 12
	sb_painel.corner_radius_bottom_left = 12
	sb_painel.corner_radius_bottom_right = 12
	sb_painel.shadow_color = Color(0.7, 0.3, 1.0, 0.35)
	sb_painel.shadow_size = 28
	sb_painel.content_margin_left = 22
	sb_painel.content_margin_right = 22
	sb_painel.content_margin_top = 16
	sb_painel.content_margin_bottom = 16
	painel_central.add_theme_stylebox_override("panel", sb_painel)
	center.add_child(painel_central)

	var vbox_main = VBoxContainer.new()
	vbox_main.add_theme_constant_override("separation", 10)
	painel_central.add_child(vbox_main)

	# titulo e fechar
	var hbox_top = HBoxContainer.new()
	hbox_top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_main.add_child(hbox_top)

	var vbox_titulos = VBoxContainer.new()
	vbox_titulos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_titulos.add_theme_constant_override("separation", 2)
	hbox_top.add_child(vbox_titulos)

	lbl_titulo_mural = Label.new()
	lbl_titulo_mural.text = "✦ INSCRIÇÃO ANCESTRAL ✦"
	if font_titulo: lbl_titulo_mural.add_theme_font_override("font", font_titulo)
	lbl_titulo_mural.add_theme_font_size_override("font_size", 20)
	lbl_titulo_mural.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	vbox_titulos.add_child(lbl_titulo_mural)

	lbl_subtitulo_mural = Label.new()
	lbl_subtitulo_mural.text = "Clique nos elementos do diagrama para decifrar os segredos da masmorra."
	lbl_subtitulo_mural.add_theme_font_override("font", font_sans)
	lbl_subtitulo_mural.add_theme_font_size_override("font_size", 13)
	lbl_subtitulo_mural.add_theme_color_override("font_color", Color(0.75, 0.82, 0.96))
	vbox_titulos.add_child(lbl_subtitulo_mural)

	btn_fechar_topo = Button.new()
	btn_fechar_topo.text = "✕"
	btn_fechar_topo.custom_minimum_size = Vector2(28, 28)
	btn_fechar_topo.add_theme_font_size_override("font_size", 14)
	btn_fechar_topo.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	
	var sb_x = StyleBoxFlat.new()
	sb_x.bg_color = Color(0.18, 0.12, 0.28, 0.9)
	sb_x.border_color = Color(0.6, 0.4, 0.8)
	sb_x.border_width_left = 1
	sb_x.border_width_right = 1
	sb_x.border_width_top = 1
	sb_x.border_width_bottom = 1
	sb_x.corner_radius_top_left = 6
	sb_x.corner_radius_top_right = 6
	sb_x.corner_radius_bottom_left = 6
	sb_x.corner_radius_bottom_right = 6
	btn_fechar_topo.add_theme_stylebox_override("normal", sb_x)
	
	var sb_x_hover = sb_x.duplicate()
	sb_x_hover.bg_color = Color(0.85, 0.2, 0.25)
	btn_fechar_topo.add_theme_stylebox_override("hover", sb_x_hover)
	btn_fechar_topo.add_theme_stylebox_override("pressed", sb_x_hover)
	btn_fechar_topo.pressed.connect(fechar_mural)
	hbox_top.add_child(btn_fechar_topo)

	vbox_main.add_child(HSeparator.new())

	# area do diagrama
	container_diagrama = VBoxContainer.new()
	container_diagrama.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container_diagrama.add_theme_constant_override("separation", 10)
	vbox_main.add_child(container_diagrama)

	# explicacao embaixo
	painel_detalhes = PanelContainer.new()
	painel_detalhes.custom_minimum_size = Vector2(760, 115)
	
	var sb_det = StyleBoxFlat.new()
	sb_det.bg_color = Color(0.05, 0.04, 0.10, 0.95)
	sb_det.border_color = Color(0.35, 0.65, 1.0, 0.7)
	sb_det.border_width_left = 2
	sb_det.border_width_right = 2
	sb_det.border_width_top = 2
	sb_det.border_width_bottom = 2
	sb_det.corner_radius_top_left = 8
	sb_det.corner_radius_top_right = 8
	sb_det.corner_radius_bottom_left = 8
	sb_det.corner_radius_bottom_right = 8
	sb_det.content_margin_left = 18
	sb_det.content_margin_right = 18
	sb_det.content_margin_top = 10
	sb_det.content_margin_bottom = 10
	painel_detalhes.add_theme_stylebox_override("panel", sb_det)
	vbox_main.add_child(painel_detalhes)

	var vbox_det = VBoxContainer.new()
	vbox_det.add_theme_constant_override("separation", 4)
	painel_detalhes.add_child(vbox_det)

	lbl_detalhe_titulo = Label.new()
	if font_titulo: lbl_detalhe_titulo.add_theme_font_override("font", font_titulo)
	lbl_detalhe_titulo.add_theme_font_size_override("font_size", 16)
	lbl_detalhe_titulo.add_theme_color_override("font_color", Color(0.35, 0.85, 1.0))
	vbox_det.add_child(lbl_detalhe_titulo)

	lbl_detalhe_corpo = Label.new()
	lbl_detalhe_corpo.add_theme_font_override("font", font_sans)
	lbl_detalhe_corpo.add_theme_font_size_override("font_size", 13)
	lbl_detalhe_corpo.add_theme_color_override("font_color", Color(0.92, 0.92, 0.96))
	lbl_detalhe_corpo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox_det.add_child(lbl_detalhe_corpo)

	lbl_detalhe_dica = Label.new()
	lbl_detalhe_dica.add_theme_font_override("font", font_sans)
	lbl_detalhe_dica.add_theme_font_size_override("font_size", 12)
	lbl_detalhe_dica.add_theme_color_override("font_color", Color(1.0, 0.84, 0.35))
	vbox_det.add_child(lbl_detalhe_dica)

	# rodape
	var hbox_bot = HBoxContainer.new()
	hbox_bot.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_bot.add_theme_constant_override("separation", 16)
	vbox_main.add_child(hbox_bot)

	var lbl_atalho = Label.new()
	lbl_atalho.text = "( Pressione [F] ou [ESC] para fechar a qualquer momento )"
	lbl_atalho.add_theme_font_override("font", font_sans)
	lbl_atalho.add_theme_font_size_override("font_size", 12)
	lbl_atalho.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75))
	hbox_bot.add_child(lbl_atalho)

	btn_fechar_rodape = Button.new()
	btn_fechar_rodape.text = "✓ FECHAR INSCRIÇÃO"
	btn_fechar_rodape.custom_minimum_size = Vector2(180, 32)
	btn_fechar_rodape.add_theme_font_override("font", font_sans)
	btn_fechar_rodape.add_theme_font_size_override("font_size", 13)
	btn_fechar_rodape.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	var sb_btn = StyleBoxFlat.new()
	sb_btn.bg_color = Color(0.18, 0.15, 0.28, 0.95)
	sb_btn.border_color = Color(1.0, 0.84, 0.35)
	sb_btn.border_width_left = 2
	sb_btn.border_width_right = 2
	sb_btn.border_width_top = 2
	sb_btn.border_width_bottom = 2
	sb_btn.corner_radius_top_left = 6
	sb_btn.corner_radius_top_right = 6
	sb_btn.corner_radius_bottom_left = 6
	sb_btn.corner_radius_bottom_right = 6
	btn_fechar_rodape.add_theme_stylebox_override("normal", sb_btn)
	
	var sb_btn_h = sb_btn.duplicate()
	sb_btn_h.bg_color = Color(0.32, 0.24, 0.50, 1.0)
	btn_fechar_rodape.add_theme_stylebox_override("hover", sb_btn_h)
	btn_fechar_rodape.add_theme_stylebox_override("pressed", sb_btn_h)
	btn_fechar_rodape.pressed.connect(fechar_mural)
	hbox_bot.add_child(btn_fechar_rodape)

func _montar_conteudo_andar(p_andar: int) -> void:
	andar_id = p_andar

	# limpa o diagrama antigo
	for c in container_diagrama.get_children():
		c.queue_free()

	match p_andar:
		1: # QUÍMICA
			_construir_diagrama_quimica()
		2: # FÍSICA
			_construir_diagrama_fisica()
		3: # BIOLOGIA
			_construir_diagrama_biologia()
		_:
			_construir_diagrama_quimica()

# diagrama de quimica: tabela periodica
func _construir_diagrama_quimica() -> void:
	lbl_titulo_mural.text = "✦ TABELA PERIÓDICA DOS ELEMENTOS ✦"
	lbl_subtitulo_mural.text = "A grande tábua da matéria universal. Clique nos filtros para destacar famílias ou em qualquer elemento!"

	botoes_elementos.clear()

	# filtros no topo
	var hbox_filtros = HBoxContainer.new()
	hbox_filtros.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_filtros.add_theme_constant_override("separation", 8)
	container_diagrama.add_child(hbox_filtros)

	var btn_f_todos = _criar_botao_filtro("🌐 TABELA COMPLETA", Color(1.0, 0.88, 0.35), func(): _filtrar_tabela_periodica("todos"))
	hbox_filtros.add_child(btn_f_todos)

	var btn_f_metais = _criar_botao_filtro("⚡ METAIS", Color(1.0, 0.78, 0.25), func(): _filtrar_tabela_periodica("metais"))
	hbox_filtros.add_child(btn_f_metais)

	var btn_f_ametais = _criar_botao_filtro("❄️ AMETAIS (NÃO-METAIS)", Color(0.25, 0.88, 0.98), func(): _filtrar_tabela_periodica("ametais"))
	hbox_filtros.add_child(btn_f_ametais)

	var btn_f_semimetais = _criar_botao_filtro("🌿 SEMIMETAIS", Color(0.45, 0.90, 0.55), func(): _filtrar_tabela_periodica("semimetais"))
	hbox_filtros.add_child(btn_f_semimetais)

	var btn_f_gases = _criar_botao_filtro("🔮 GASES NOBRES", Color(0.85, 0.45, 1.0), func(): _filtrar_tabela_periodica("gases_nobres"))
	hbox_filtros.add_child(btn_f_gases)

	# grade da tabela periodica
	var grid = GridContainer.new()
	grid.columns = 18
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	container_diagrama.add_child(grid)

	var dados_tabela = [
		# linha 1
		[1, "H", "Hidrogênio", "hidrogenio"],
		null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null,
		[2, "He", "Hélio", "gases_nobres"],

		# linha 2
		[3, "Li", "Lítio", "metais"],
		[4, "Be", "Berílio", "metais"],
		null, null, null, null, null, null, null, null, null, null,
		[5, "B", "Boro", "semimetais"],
		[6, "C", "Carbono", "ametais"],
		[7, "N", "Nitrogênio", "ametais"],
		[8, "O", "Oxigênio", "ametais"],
		[9, "F", "Flúor", "ametais"],
		[10, "Ne", "Neônio", "gases_nobres"],

		# linha 3
		[11, "Na", "Sódio", "metais"],
		[12, "Mg", "Magnésio", "metais"],
		null, null, null, null, null, null, null, null, null, null,
		[13, "Al", "Alumínio", "metais"],
		[14, "Si", "Silício", "semimetais"],
		[15, "P", "Fósforo", "ametais"],
		[16, "S", "Enxofre", "ametais"],
		[17, "Cl", "Cloro", "ametais"],
		[18, "Ar", "Argônio", "gases_nobres"],

		# linha 4
		[19, "K", "Potássio", "metais"],
		[20, "Ca", "Cálcio", "metais"],
		[21, "Sc", "Escândio", "metais"],
		[22, "Ti", "Titânio", "metais"],
		[23, "V", "Vanádio", "metais"],
		[24, "Cr", "Cromo", "metais"],
		[25, "Mn", "Manganês", "metais"],
		[26, "Fe", "Ferro", "metais"],
		[27, "Co", "Cobalto", "metais"],
		[28, "Ni", "Níquel", "metais"],
		[29, "Cu", "Cobre", "metais"],
		[30, "Zn", "Zinco", "metais"],
		[31, "Ga", "Gálio", "metais"],
		[32, "Ge", "Germânio", "semimetais"],
		[33, "As", "Arsênio", "semimetais"],
		[34, "Se", "Selênio", "ametais"],
		[35, "Br", "Bromo", "ametais"],
		[36, "Kr", "Criptônio", "gases_nobres"],

		# linha 5
		[37, "Rb", "Rubídio", "metais"],
		[38, "Sr", "Estrôncio", "metais"],
		[39, "Y", "Ítrio", "metais"],
		[40, "Zr", "Zircônio", "metais"],
		[41, "Nb", "Nióbio", "metais"],
		[42, "Mo", "Molibdênio", "metais"],
		[43, "Tc", "Tecnécio", "metais"],
		[44, "Ru", "Rutênio", "metais"],
		[45, "Rh", "Ródio", "metais"],
		[46, "Pd", "Paládio", "metais"],
		[47, "Ag", "Prata", "metais"],
		[48, "Cd", "Cádmio", "metais"],
		[49, "In", "Índio", "metais"],
		[50, "Sn", "Estanho", "metais"],
		[51, "Sb", "Antimônio", "semimetais"],
		[52, "Te", "Telúrio", "semimetais"],
		[53, "I", "Iodo", "ametais"],
		[54, "Xe", "Xenônio", "gases_nobres"],

		# linha 6
		[55, "Cs", "Césio", "metais"],
		[56, "Ba", "Bário", "metais"],
		[57, "La", "Lantânio", "metais"],
		[72, "Hf", "Háfnio", "metais"],
		[73, "Ta", "Tântalo", "metais"],
		[74, "W", "Tungstênio", "metais"],
		[75, "Re", "Rênio", "metais"],
		[76, "Os", "Ósmio", "metais"],
		[77, "Ir", "Irídio", "metais"],
		[78, "Pt", "Platina", "metais"],
		[79, "Au", "Ouro", "metais"],
		[80, "Hg", "Mercúrio", "metais"],
		[81, "Tl", "Tálio", "metais"],
		[82, "Pb", "Chumbo", "metais"],
		[83, "Bi", "Bismuto", "metais"],
		[84, "Po", "Polônio", "semimetais"],
		[85, "At", "Astato", "ametais"],
		[86, "Rn", "Radônio", "gases_nobres"],
	]

	for item in dados_tabela:
		if item == null:
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(44, 25)
			spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			grid.add_child(spacer)
		else:
			var z = item[0] as int
			var simb = item[1] as String
			var nome = item[2] as String
			var cat = item[3] as String
			
			var btn = _criar_celula_periodica(z, simb, nome, cat)
			btn.pressed.connect(func(): _selecionar_elemento(z, simb, nome, cat, btn))
			grid.add_child(btn)
			botoes_elementos.append({"btn": btn, "cat": cat, "simb": simb, "z": z, "nome": nome})

	_filtrar_tabela_periodica("todos")

func _filtrar_tabela_periodica(categoria_filtro: String) -> void:
	_tocar_som("ui-1")
	for item in botoes_elementos:
		var btn = item["btn"] as Button
		var cat = item["cat"] as String
		if categoria_filtro == "todos" or cat == categoria_filtro or (categoria_filtro == "ametais" and cat == "hidrogenio"):
			btn.modulate.a = 1.0
		else:
			btn.modulate.a = 0.22
	
	_exibir_info_quimica(categoria_filtro)

func _selecionar_elemento(z: int, simb: String, nome: String, cat: String, btn_clicado: Button) -> void:
	_tocar_som("ui-1")
	for item in botoes_elementos:
		var btn = item["btn"] as Button
		if btn == btn_clicado:
			btn.modulate.a = 1.0
		else:
			btn.modulate.a = 0.38
	
	_exibir_info_elemento_individual(z, simb, nome, cat)

func _exibir_info_quimica(categoria: String) -> void:
	match categoria:
		"metais":
			lbl_detalhe_titulo.text = "⚡ OS METAIS"
			lbl_detalhe_titulo.add_theme_color_override("font_color", Color(1.0, 0.78, 0.25))
			lbl_detalhe_corpo.text = "Propriedades Gerais: Formam a grande maioria dos elementos químicos. Apresentam brilho característico, excelente condutividade térmica e elétrica, maleabilidade (formam lâminas) e ductilidade (formam fios). Ao reagir, tendem a DOAR elétrons e formar íons positivos (Cátions +)."
			lbl_detalhe_dica.text = "💡 SEGREDO ARCANO: A união entre um Metal e um Ametal transfere elétrons e forma a LIGAÇÃO IÔNICA (ex: Na⁺ + Cl⁻ = NaCl, o Sal de Cozinha)!"
		"ametais":
			lbl_detalhe_titulo.text = "❄️ OS AMETAIS (NÃO-METAIS)"
			lbl_detalhe_titulo.add_theme_color_override("font_color", Color(0.25, 0.88, 0.98))
			lbl_detalhe_corpo.text = "Propriedades Gerais: Elementos vitais para a vida e a matéria orgânica. São isolantes térmicos e elétricos (não conduzem bem eletricidade) e fragmentam-se sob impacto mecânico. Possuem alta eletronegatividade: tendem a RECEBER ou COMPARTILHAR elétrons (formam Ânions -)."
			lbl_detalhe_dica.text = "💡 SEGREDO ARCANO: Dois ametais unidos compartilham pares de elétrons em uma LIGAÇÃO COVALENTE estável (ex: H₂O, O₂, CO₂, glicose e DNA)!"
		"gases_nobres":
			lbl_detalhe_titulo.text = "🔮 OS GASES NOBRES (GRUPO 18)"
			lbl_detalhe_titulo.add_theme_color_override("font_color", Color(0.85, 0.45, 1.0))
			lbl_detalhe_corpo.text = "Propriedades Gerais: Elementos gasosos que já possuem 8 elétrons na camada de valência (ou 2 no Hélio), atendendo com perfeição à Regra do Octeto. Por possuírem estabilidade química máxima natural, são inertes e raramente formam compostos."
			lbl_detalhe_dica.text = "💡 SEGREDO ARCANO: Por serem inertes e não inflamáveis, o Hélio (He) e o Argônio (Ar) são usados para criar atmosferas seguras, evitar explosões e iluminar cidades (lâmpadas de néon)!"
		"semimetais":
			lbl_detalhe_titulo.text = "🌿 OS SEMIMETAIS (METALÓIDES)"
			lbl_detalhe_titulo.add_theme_color_override("font_color", Color(0.45, 0.90, 0.55))
			lbl_detalhe_corpo.text = "Propriedades Gerais: Apresentam comportamento intermediário entre metais e ametais. O Silício (Si) e o Germânio (Ge) são semicondutores essenciais para a fabricação de circuitos eletrônicos e inteligência dos robôs."
			lbl_detalhe_dica.text = "💡 SEGREDO ARCANO: A semicondutividade permite controlar o fluxo elétrico sob comando, sendo a base de toda a tecnologia arcana dos robôs de Física!"
		_:
			lbl_detalhe_titulo.text = "✦ TABELA PERIÓDICA: A ORGANIZAÇÃO DA MATÉRIA ✦"
			lbl_detalhe_titulo.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
			lbl_detalhe_corpo.text = "Todos os blocos fundamentais do universo ordenados por Número Atômico (Z, número de prótons). As colunas representam FAMÍLIAS com comportamentos químicos semelhantes, e as linhas representam os PERÍODOS (camadas eletrônicas)."
			lbl_detalhe_dica.text = "💡 EXPLORAÇÃO: Clique nos botões acima para destacar categorias ou selecione qualquer elemento da tabela para desvendar seus segredos alquímicos!"

func _exibir_info_elemento_individual(z: int, simb: String, nome: String, cat: String) -> void:
	var nome_cat = _obter_nome_categoria(cat)
	var cor_cat = _obter_cor_categoria(cat)
	
	lbl_detalhe_titulo.text = "⚛ %s [%s] - NÚMERO ATÔMICO Z=%d (%s)" % [nome.to_upper(), simb, z, nome_cat.to_upper()]
	lbl_detalhe_titulo.add_theme_color_override("font_color", cor_cat)
	
	var desc = _obter_descricao_elemento(simb, nome, z, cat)
	lbl_detalhe_corpo.text = desc["corpo"]
	lbl_detalhe_dica.text = desc["dica"]

func _obter_descricao_elemento(simb: String, nome: String, z: int, cat: String) -> Dictionary:
	match simb:
		"H":
			return {
				"corpo": "O átomo mais abundante do cosmos e o mais leve de todos. Possui apenas 1 próton e 1 elétron. É o combustível nuclear primordial que queima no coração das estrelas!",
				"dica": "💡 Embora esteja na primeira coluna por ter 1 elétron, NÃO é um metal: é um elemento singular com propriedades únicas!"
			}
		"He":
			return {
				"corpo": "Gás nobre ultraleve, inerte e atóxico. Possui 2 elétrons preenchendo completamente seu único nível de energia (camada K).",
				"dica": "💡 Não queima nem sob chamas mágicas. Usado para feitiços de levitação e resfriamento criogênico extremo."
			}
		"Li":
			return {
				"corpo": "O metal mais leve conhecido. Altamente reativo, queima com chama carmim e doa seu único elétron de valência com facilidade (Li⁺).",
				"dica": "💡 Alimenta as baterias de alta densidade energética que movem os autômatos modernos da masmorra."
			}
		"C":
			return {
				"corpo": "A coluna dorsal da química orgânica e da vida. Capaz de realizar 4 ligações covalentes simultâneas (tetravalência), gerando cadeias infinitas.",
				"dica": "💡 Apresenta alotropia: pode se organizar como o grafite macio e condutor ou como o diamante, a gema natural mais dura do mundo!"
			}
		"N":
			return {
				"corpo": "Gás que compõe cerca de 78% do ar. Essencial para a construção de aminoácidos, proteínas e o código genético (DNA/RNA).",
				"dica": "💡 A ligação tripla entre dois átomos de nitrogênio (N≡N) é extremamente forte; romper essa ligação em compostos explosivos libera imensa energia."
			}
		"O":
			return {
				"corpo": "O comburente vital da respiração celular aeróbica, onde células produzem energia (ATP) consumindo glicose. Essencial para a manutenção do fogo.",
				"dica": "💡 Altamente eletronegativo (atrai elétrons com vigor). Em altas camadas da atmosfera, forma o ozônio (O₃), escudo contra radiação ultravioleta."
			}
		"F":
			return {
				"corpo": "O elemento com maior eletronegatividade de toda a Tabela Periódica. Atrai elétrons de qualquer substância com força avassaladora.",
				"dica": "💡 Em doses controladas protege o esmalte dentário (fluoreto); em estado puro é tão corrosivo que ataca até mesmo frascos de vidro!"
			}
		"Ne":
			return {
				"corpo": "Gás nobre estável que emite um brilho vermelho-alaranjado incandescente quando excitado por uma descarga elétrica de alta voltagem.",
				"dica": "💡 Utilizado em letreiros mágicos e iluminação de faróis que guiam viajantes através de névoas densas."
			}
		"Na":
			return {
				"corpo": "Metal alcalino macio e prateado. Doa 1 elétron com grande facilidade para formar o cátion Na⁺, atingindo a configuração de gás nobre.",
				"dica": "💡 Reage explosivamente ao entrar em contato com água pura! Ao doar seu elétron ao Cloro, forma o sal de cozinha inofensivo (NaCl)."
			}
		"Mg":
			return {
				"corpo": "Metal leve e estrutural que queima com um clarão branco ofuscante. Ocupa o centro da molécula de clorofila em organismos fotossintetizantes.",
				"dica": "💡 Fundamental para a fotossíntese nos andares de Biologia e para a produção de chamas de sinalização e sinalizadores de resgate."
			}
		"Al":
			return {
				"corpo": "Metal leve, dúctil e abundante na crosta terrestre. Desenvolve espontaneamente uma fina película transparente de óxido que o protege de corrosão.",
				"dica": "💡 Excelente condutor de calor e eletricidade, usado na forja de armaduras leves que não pesam na mochila do aventureiro."
			}
		"Si":
			return {
				"corpo": "Semimetal semicondutor abundante no quartzo e na areia. Apresenta condutividade elétrica controlável conforme a temperatura e voltagem.",
				"dica": "💡 O coração dos microchips, sensores e cérebros mecânicos dos Robôs de Física!"
			}
		"P":
			return {
				"corpo": "Ametal essencial que compõe a espinha dorsal do DNA e armazena a energia bioquímica na forma de ATP (Trifosfato de Adenosina).",
				"dica": "💡 O fósforo branco brilha no escuro em contato com o ar através de oxidação lenta quimiluminescente."
			}
		"S":
			return {
				"corpo": "Ametal amarelo característico das zonas vulcânicas e fontes termais. Participa de aminoácidos estruturais como a cisteína e metionina.",
				"dica": "💡 Queima com chama azulada gerando dióxido de enxofre (SO₂). Usado na fabricação de pólvora e poções arcanas."
			}
		"Cl":
			return {
				"corpo": "Halogênio de tom amarelo-esverdeado com voracidade por 1 elétron (forma o ânion Cl⁻). Agente oxidante e bactericida consagrado.",
				"dica": "💡 Na forma de cloreto (Cl⁻), equilibra a pressão osmótica e os eletrólitos do sangue do jogador."
			}
		"Ar":
			return {
				"corpo": "O gás nobre mais abundante na atmosfera terrestre (quase 1%). Inerte, serve como escudo gasoso para soldas e fundições delicadas.",
				"dica": "💡 Preenche o bulbo de lâmpadas incandescentes para impedir que o filamento de tungstênio se queime ao atingir milhares de graus."
			}
		"K":
			return {
				"corpo": "Metal alcalino crucial para a condução de impulsos nervosos e batimentos cardíacos nos seres vivos. Doa 1 elétron gerando o cátion K⁺.",
				"dica": "💡 Em contato com a água, reage liberando calor e inflamando o hidrogênio com uma chama violeta brilhante."
			}
		"Ca":
			return {
				"corpo": "Metal alcalino-terroso que confere rigidez aos ossos, carapaças e dentes. Atua como mensageiro nas contrações musculares.",
				"dica": "💡 Na forma de calcário e mármore (CaCO₃), constitui as paredes ancestrais e estátuas da masmorra."
			}
		"Ti":
			return {
				"corpo": "Metal de transição com excepcional relação resistência/peso: tão forte quanto o aço, porém 45% mais leve e imune à corrosão marinha.",
				"dica": "💡 É biocompatível (o corpo não o rejeita), sendo empregado em próteses cirúrgicas e na blindagem de autômatos de elite."
			}
		"Fe":
			return {
				"corpo": "O metal pilar da civilização e da guerra. No corpo humano, reside no centro do grupo heme da hemoglobina, ancorando o oxigênio no sangue.",
				"dica": "💡 Apresenta forte ferromagnetismo. Com pequenas adições de Carbono, transforma-se no Aço das espadas e escudos lendários."
			}
		"Cu":
			return {
				"corpo": "Metal nobre avermelhado com condutividade elétrica e térmica de primeira grandeza. Tem ação antibacteriana e antifúngica natural.",
				"dica": "💡 Uma das primeiras ligas da história foi gerada fundindo Cobre com Estanho: o Bronze, marco da evolução das ferramentas."
			}
		"Zn":
			return {
				"corpo": "Metal de transição usado para proteger o ferro contra ferrugem (galvanização). Atua como cofator de mais de 300 enzimas vitais.",
				"dica": "💡 Essencial para o sistema imune e para a cicatrização de feridas causadas em combate contra monstros da dungeon."
			}
		"Br":
			return {
				"corpo": "O único ametal que é líquido em temperatura ambiente. De coloração marrom-avermelhada densa e vapores sufocantes penetrantes.",
				"dica": "💡 Utilizado em reagentes analíticos e outrora na fabricação de películas fotográficas com haletos de prata."
			}
		"Ag":
			return {
				"corpo": "O metal de maior condutividade elétrica e térmica entre todos os elementos da Tabela Periódica. Apresenta o mais alto índice de reflexão óptica.",
				"dica": "💡 Íons de prata (Ag⁺) destroem a membrana de bactérias patogênicas, purificando a água e ungindo armas contra criaturas sombrias."
			}
		"Sn":
			return {
				"corpo": "Metal prateado macio e resistente à oxidação. Muito utilizado em ligas de solda elétrica e revestimento de latas de provisões.",
				"dica": "💡 Em baixas temperaturas (-13 °C), o estanho branco pode sofrer a 'peste do estanho', transmutando-se espontaneamente em pó cinzento."
			}
		"I":
			return {
				"corpo": "Halogênio sólido arroxeado com brilho quase metálico. Quando aquecido brandamente, sublima diretamente para um denso vapor violeta.",
				"dica": "💡 Imprescindível para os hormônios da tireoide que regulam o metabolismo energético de todos os aventureiros."
			}
		"W":
			return {
				"corpo": "Metal com o maior ponto de fusão entre todos os elementos da Tabela Periódica: resiste a incríveis 3.422 °C sem derreter!",
				"dica": "💡 Por suportar temperaturas escaldantes, forma os filamentos das lâmpadas e as pontas perfurantes das armas de alta penetração."
			}
		"Pt":
			return {
				"corpo": "Metal nobre precioso extremamente denso, resistente a ácidos e corrosão. Extraordinário catalisador para acelerar reações químicas lentas.",
				"dica": "💡 Catalisadores de platina convertem gases venenosos em compostos inertes em laboratórios alquímicos avançados."
			}
		"Au":
			return {
				"corpo": "O rei dos metais nobres. Não sofre oxidação pelo ar, é imune à ferrugem e incrivelmente maleável (1g pode ser transformado em 2 km de fio).",
				"dica": "💡 A moeda suprema de Synthesis! Por não se degradar, preserva a riqueza e os circuitos arcanos por milênios sem falhas."
			}
		"Hg":
			return {
				"corpo": "O lendário 'azougue'. O único metal que permanece em estado líquido em temperatura ambiente. Possui densidade extraordinária (13,6 g/cm³).",
				"dica": "💡 Uma esfera de ferro sólido flutua na superfície do mercúrio líquido devido ao empuxo causado pela altíssima densidade do mercúrio!"
			}
		"Pb":
			return {
				"corpo": "Metal pesado, macio e denso. Conhecido por absorver e barrar eficientemente radiações ionizantes perigosas como raios X e raios gama.",
				"dica": "💡 O grande objetivo dos alquimistas clássicos era descobrir a Pedra Filosofal para transmutar o chumbo comum em ouro puríssimo."
			}
		"Rn":
			return {
				"corpo": "Gás nobre pesado e radioativo proveniente do decaimento natural do rádio e do urânio presentes nas rochas mais profundas da masmorra.",
				"dica": "💡 Por ser cerca de 8 vezes mais denso que o ar comum, tende a se concentrar no assoalho de calabouços e galerias subterrâneas mal ventiladas."
			}
		_:
			match cat:
				"metais":
					return {
						"corpo": "Elemento metálico condutor com Z=%d prótons. Apresenta ductilidade, brilho metálico e tendência a doar elétrons em reações químicas." % z,
						"dica": "💡 Doa elétrons de valência para formar cátions positivos estáveis em ligas e sais."
					}
				"ametais":
					return {
						"corpo": "Elemento não-metálico de alta eletronegatividade com Z=%d prótons. Mau condutor térmico e elétrico, vital em compostos orgânicos e moleculares." % z,
						"dica": "💡 Compartilha pares de elétrons através de ligações covalentes para atingir o octeto completo."
					}
				"semimetais":
					return {
						"corpo": "Elemento semimetálico de comportamento intermediário com Z=%d prótons. Possui propriedades de condução que variam com a energia aplicada." % z,
						"dica": "💡 Valorizado em alquimia aplicada e transistores condutores para maquinários mágicos."
					}
				"gases_nobres":
					return {
						"corpo": "Elemento químico gasoso inerte com Z=%d prótons. Camada de valência completa atendendo à regra do octeto." % z,
						"dica": "💡 Possui baixíssima reatividade química, mantendo-se puro e isolado mesmo em ambientes cáusticos."
					}
				_:
					return {
						"corpo": "Elemento químico elemental com Z=%d prótons no núcleo atômico." % z,
						"dica": "💡 Parte integrante do mapa primordial dos elementos de Synthesis."
					}

# diagrama de fisica: prisma de newton
func _construir_diagrama_fisica() -> void:
	lbl_titulo_mural.text = "✦ REGISTRO ÓPTICO: A DECOMPOSIÇÃO DA LUZ ✦"
	lbl_subtitulo_mural.text = "A luz do Sol oculta todas as cores da criação. Clique nas cores do espectro para entender a refração!"

	# feixe de luz
	var hbox_prisma = HBoxContainer.new()
	hbox_prisma.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_prisma.add_theme_constant_override("separation", 18)
	container_diagrama.add_child(hbox_prisma)

	# luz branca de entrada
	var btn_luz_branca = _criar_cartao_prisma(
		"Luz Branca\n(Policromática)",
		"Feixe Incidente",
		Color(1.0, 1.0, 1.0),
		Color(0.2, 0.2, 0.3),
		func(): _exibir_info_fisica("branca")
	)
	hbox_prisma.add_child(btn_luz_branca)

	# seta
	var lbl_seta1 = Label.new()
	lbl_seta1.text = "━━━▶"
	lbl_seta1.add_theme_font_override("font", font_sans)
	lbl_seta1.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	hbox_prisma.add_child(lbl_seta1)

	# prisma de vidro
	var btn_prisma = _criar_cartao_prisma(
		"▲\nPRISMA DE VIDRO\n(Refração)",
		"Meio Óptico Mais Denso",
		Color(0.4, 0.85, 1.0),
		Color(0.12, 0.20, 0.35),
		func(): _exibir_info_fisica("prisma")
	)
	btn_prisma.custom_minimum_size = Vector2(180, 75)
	hbox_prisma.add_child(btn_prisma)

	# seta
	var lbl_seta2 = Label.new()
	lbl_seta2.text = "━━━▶"
	lbl_seta2.add_theme_font_override("font", font_sans)
	lbl_seta2.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	hbox_prisma.add_child(lbl_seta2)

	# decomposicao das cores
	var vbox_cores = VBoxContainer.new()
	vbox_cores.add_theme_constant_override("separation", 3)
	hbox_prisma.add_child(vbox_cores)

	var cores_espectro = [
		{"nome": "Vermelho", "onda": "~700 nm (Menor Desvio)", "cor": Color(1.0, 0.25, 0.25), "chave": "vermelho"},
		{"nome": "Laranja", "onda": "~620 nm", "cor": Color(1.0, 0.6, 0.15), "chave": "laranja"},
		{"nome": "Amarelo", "onda": "~580 nm", "cor": Color(1.0, 0.9, 0.2), "chave": "amarelo"},
		{"nome": "Verde", "onda": "~530 nm", "cor": Color(0.25, 0.95, 0.45), "chave": "verde"},
		{"nome": "Azul", "onda": "~470 nm", "cor": Color(0.2, 0.75, 1.0), "chave": "azul"},
		{"nome": "Anil / Índigo", "onda": "~440 nm", "cor": Color(0.4, 0.4, 0.95), "chave": "anil"},
		{"nome": "Violeta", "onda": "~400 nm (Maior Desvio)", "cor": Color(0.8, 0.3, 1.0), "chave": "violeta"}
	]

	for c in cores_espectro:
		var btn_cor = _criar_faixa_cor(c["nome"], c["onda"], c["cor"], func(): _exibir_info_fisica(c["chave"], c["nome"], c["onda"]))
		vbox_cores.add_child(btn_cor)

	_exibir_info_fisica("prisma")

func _exibir_info_fisica(tipo: String, nome_cor: String = "", onda: String = "") -> void:
	_tocar_som("ui-1")

	match tipo:
		"prisma":
			lbl_detalhe_titulo.text = "▲ REFRAÇÃO & DISPERSÃO NO PRISMA"
			lbl_detalhe_titulo.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
			lbl_detalhe_corpo.text = "Quando a luz branca viaja do ar para o vidro, sua velocidade diminui. Como cada frequência luminosa viaja em velocidade ligeiramente diferente no vidro, cada cor sofre um desvio angular distinto, separando-se no arco-íris!"
			lbl_detalhe_dica.text = "💡 LEI DE SNELL: O desvio depende do Índice de Refração (n = c / v). Maior frequência = Maior desvio!"
		"branca":
			lbl_detalhe_titulo.text = "⚪ LUZ BRANCA (POLICROMÁTICA)"
			lbl_detalhe_titulo.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
			lbl_detalhe_corpo.text = "A luz emitida pelo Sol e por tochas mágicas não é pura: ela é a superposição contínua de todas as cores do espectro visível combinadas."
			lbl_detalhe_dica.text = "💡 CURIOSIDADE: Isaac Newton comprovou isso em 1666 ao usar um segundo prisma invertido que unia as cores de volta em luz branca!"
		"vermelho":
			lbl_detalhe_titulo.text = "🔴 COR VERMELHA: MENOR DESVIO (~700 nm)"
			lbl_detalhe_titulo.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
			lbl_detalhe_corpo.text = "O vermelho possui a menor frequência e o MAIOR comprimento de onda do espectro visível. Por isso, ele sofre a menor desaceleração no vidro e sofre o MENOR DESVIO angular."
			lbl_detalhe_dica.text = "💡 DICA DE BATALHA: Menor desvio = Vermelho. Por dispersar menos no ar, é a cor usada em faróis e alertas de perigo!"
		"violeta":
			lbl_detalhe_titulo.text = "🟪 COR VIOLETA: MAIOR DESVIO (~400 nm)"
			lbl_detalhe_titulo.add_theme_color_override("font_color", Color(0.85, 0.4, 1.0))
			lbl_detalhe_corpo.text = "O violeta possui a maior frequência e o MENOR comprimento de onda do espectro visível. No vidro, sua velocidade diminui consideravelmente, sofrendo o MAIOR DESVIO angular da dispersão."
			lbl_detalhe_dica.text = "💡 DICA DE BATALHA: Acima do violeta está a radiação Ultravioleta (invisível aos olhos humanos e com alta energia)!"
		_:
			lbl_detalhe_titulo.text = "🌈 ESPECTRO VISÍVEL: %s (%s)" % [nome_cor.to_upper(), onda]
			lbl_detalhe_titulo.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
			lbl_detalhe_corpo.text = "Cada cor do arco-íris representa uma onda eletromagnética vibrando em uma frequência específica que é interpretada pelos olhos como uma cor diferente."
			lbl_detalhe_dica.text = "💡 ORDEM DO ARCO-ÍRIS: Vermelho, Laranja, Amarelo, Verde, Azul, Anil e Violeta!"

# diagrama de biologia: celula e organelas
func _construir_diagrama_biologia() -> void:
	lbl_titulo_mural.text = "✦ MANUSCRITO CELULAR: A ARQUITETURA DA VIDA ✦"
	lbl_subtitulo_mural.text = "Toda criatura nesta masmorra é sustentada por micromáquinas vivas. Clique nas organelas para conhecê-las!"

	var grid_organelas = GridContainer.new()
	grid_organelas.columns = 3
	grid_organelas.add_theme_constant_override("h_separation", 12)
	grid_organelas.add_theme_constant_override("v_separation", 10)
	grid_organelas.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	container_diagrama.add_child(grid_organelas)

	var organelas = [
		{"nome": "🛡️ MEMBRANA", "sub": "Permeabilidade Seletiva", "chave": "membrana", "cor": Color(0.25, 0.9, 0.7)},
		{"nome": "💧 CITOPLASMA", "sub": "Citosol & Metabolismo", "chave": "citoplasma", "cor": Color(0.3, 0.75, 1.0)},
		{"nome": "🧠 NÚCLEO", "sub": "Código Genético (DNA)", "chave": "nucleo", "cor": Color(1.0, 0.8, 0.25)},
		{"nome": "⚡ MITOCÔNDRIA", "sub": "Respiração & ATP", "chave": "mitocondria", "cor": Color(1.0, 0.35, 0.35)},
		{"nome": "🌿 CLOROPLASTO", "sub": "Fotossíntese (Vegetal)", "chave": "cloroplasto", "cor": Color(0.4, 0.95, 0.3)},
		{"nome": "🧬 RIBOSSOMOS", "sub": "Síntese Proteica", "chave": "ribossomos", "cor": Color(0.85, 0.45, 1.0)},
	]

	for org in organelas:
		var btn_org = _criar_cartao_organela(org["nome"], org["sub"], org["cor"], func(): _exibir_info_biologia(org["chave"]))
		grid_organelas.add_child(btn_org)

	_exibir_info_biologia("mitocondria")

func _exibir_info_biologia(chave: String) -> void:
	_tocar_som("ui-1")

	match chave:
		"mitocondria":
			lbl_detalhe_titulo.text = "⚡ MITOCÔNDRIA: A USINA ENERGÉTICA DA CÉLULA"
			lbl_detalhe_titulo.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
			lbl_detalhe_corpo.text = "Função Vital: Realiza a RESPIRAÇÃO CELULAR utilizando Glicose e Oxigênio (O₂) para produzir adenosina trifosfato (ATP), a 'moeda energética' indispensável para o mago conjurar feitiços e se mover!"
			lbl_detalhe_dica.text = "💡 EQUAÇÃO DA VIDA: Glicose + 6 O₂ → 6 CO₂ + 6 H₂O + ENERGIA (ATP)!"
		"nucleo":
			lbl_detalhe_titulo.text = "🧠 NÚCLEO CELULAR: O CÉREBRO GENÉTICO"
			lbl_detalhe_titulo.add_theme_color_override("font_color", Color(1.0, 0.8, 0.25))
			lbl_detalhe_corpo.text = "Função Vital: Abriga as moléculas de DNA (ácido desoxirribonucleico) organizadas em cromossomos. Coordena a reprodução celular (Mitose e Meiose) e dita quais proteínas serão fabricadas."
			lbl_detalhe_dica.text = "💡 DIFERENÇA VITAL: Células Eucariontes possuem núcleo delimitado por membrana (carioteca); Procariontes (bactérias) têm DNA disperso!"
		"membrana":
			lbl_detalhe_titulo.text = "🛡️ MEMBRANA PLASMÁTICA: O ESCUDO SELETIVO"
			lbl_detalhe_titulo.add_theme_color_override("font_color", Color(0.25, 0.9, 0.7))
			lbl_detalhe_corpo.text = "Função Vital: Formada por uma dupla camada de fosfolipídios com proteínas incrustadas (Modelo do Mosaico Fluido). Possui PERMEABILIDADE SELETIVA, escolhendo quais nutrientes entram e quais toxinas são expelidas."
			lbl_detalhe_dica.text = "💡 SEGREDO ARCANO: A osmose (movimento espontâneo da água do meio menos concentrado para o mais concentrado) ocorre através desta membrana!"
		"cloroplasto":
			lbl_detalhe_titulo.text = "🌿 CLOROPLASTO: A FÁBRICA SOLAR"
			lbl_detalhe_titulo.add_theme_color_override("font_color", Color(0.4, 0.95, 0.3))
			lbl_detalhe_corpo.text = "Função Vital: Exclusivo de células vegetais e algas. Contém o pigmento verde Clorofila e executa a FOTOSSÍNTESE, capturando luz solar e dióxido de carbono para gerar glicose e liberar Oxigênio."
			lbl_detalhe_dica.text = "💡 FOTOSSÍNTESE: 6 CO₂ + 6 H₂O + Luz → Glicose + 6 O₂!"
		"citoplasma":
			lbl_detalhe_titulo.text = "💧 CITOPLASMA / CITOSOL: O OCEANO INTERNO"
			lbl_detalhe_titulo.add_theme_color_override("font_color", Color(0.3, 0.75, 1.0))
			lbl_detalhe_corpo.text = "Função Vital: Matriz aquosa e gelatinosa rica em proteínas, sais e íons. Mantém as organelas em posição correta e abriga as reações da Glicólise (primeira etapa da quebra da glicose)."
			lbl_detalhe_dica.text = "💡 CITOESQUELETO: Uma rede de microtúbulos no citoplasma atua como trilhos para movimentar vesículas e manter a forma celular!"
		"ribossomos":
			lbl_detalhe_titulo.text = "🧬 RIBOSSOMOS: OS ARTESÃOS DE PROTEÍNA"
			lbl_detalhe_titulo.add_theme_color_override("font_color", Color(0.85, 0.45, 1.0))
			lbl_detalhe_corpo.text = "Função Vital: Traduzem as mensagens enviadas pelo RNA Mensageiro (RNAm) para montar cadeias de aminoácidos, gerando enzimas, hormônios e anticorpos essenciais."
			lbl_detalhe_dica.text = "💡 PRESENÇA UNIVERSAL: Ribossomos estão presentes em TODAS as células vivas conhecidas, desde a bactéria mais simples até os monstros da masmorra!"

# funcoes de estilo dos botoes
func _criar_cartao_categoria(titulo: String, subtitulo: String, cor_borda: Color, callback: Callable) -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(240, 68)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.08, 0.18, 0.95)
	sb.border_color = cor_borda
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	card.add_theme_stylebox_override("panel", sb)
	
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(vbox)
	
	var lbl_t = Label.new()
	lbl_t.text = titulo
	if font_titulo: lbl_t.add_theme_font_override("font", font_titulo)
	lbl_t.add_theme_font_size_override("font_size", 15)
	lbl_t.add_theme_color_override("font_color", cor_borda)
	lbl_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_t)
	
	var lbl_s = Label.new()
	lbl_s.text = subtitulo
	if font_sans: lbl_s.add_theme_font_override("font", font_sans)
	lbl_s.add_theme_font_size_override("font_size", 11)
	lbl_s.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
	lbl_s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_s.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_s)
	
	var sb_h = sb.duplicate()
	sb_h.bg_color = Color(0.18, 0.14, 0.30, 1.0)
	sb_h.border_color = Color(1.0, 1.0, 1.0)
	
	card.mouse_entered.connect(func(): card.add_theme_stylebox_override("panel", sb_h))
	card.mouse_exited.connect(func(): card.add_theme_stylebox_override("panel", sb))
	card.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			_tocar_som("ui_2")
			callback.call()
	)
	return card

func _criar_celula_periodica(z: int, simb: String, nome: String, cat: String) -> Button:
	var cor_cat = _obter_cor_categoria(cat)
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(44, 25)
	btn.text = simb
	if font_sans: btn.add_theme_font_override("font", font_sans)
	btn.add_theme_font_size_override("font_size", 11)
	btn.add_theme_color_override("font_color", cor_cat)
	btn.tooltip_text = "%s [%s] - Z=%d\nCategoria: %s" % [nome, simb, z, _obter_nome_categoria(cat)]
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = _obter_bg_categoria(cat)
	sb.border_color = cor_cat.darkened(0.15)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", sb)
	
	var sb_h = sb.duplicate()
	sb_h.bg_color = cor_cat.darkened(0.4)
	sb_h.border_color = Color.WHITE
	sb_h.set_border_width_all(2)
	btn.add_theme_stylebox_override("hover", sb_h)
	btn.add_theme_stylebox_override("pressed", sb_h)
	
	return btn

func _criar_botao_filtro(rotulo: String, cor_tema: Color, callback: Callable) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(130, 28)
	btn.text = rotulo
	if font_sans: btn.add_theme_font_override("font", font_sans)
	btn.add_theme_font_size_override("font_size", 11)
	btn.add_theme_color_override("font_color", cor_tema)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.06, 0.14, 0.95)
	sb.border_color = cor_tema
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", sb)
	
	var sb_h = sb.duplicate()
	sb_h.bg_color = cor_tema.darkened(0.6)
	sb_h.border_color = Color.WHITE
	sb_h.set_border_width_all(2)
	btn.add_theme_stylebox_override("hover", sb_h)
	btn.add_theme_stylebox_override("pressed", sb_h)
	
	btn.pressed.connect(callback)
	return btn

func _obter_cor_categoria(cat: String) -> Color:
	match cat:
		"metais": return Color(1.0, 0.78, 0.25)
		"ametais": return Color(0.25, 0.88, 0.98)
		"gases_nobres": return Color(0.85, 0.45, 1.0)
		"semimetais": return Color(0.45, 0.90, 0.55)
		"hidrogenio": return Color(0.92, 0.96, 1.0)
		_: return Color(0.8, 0.8, 0.8)

func _obter_bg_categoria(cat: String) -> Color:
	match cat:
		"metais": return Color(0.16, 0.12, 0.05, 0.95)
		"ametais": return Color(0.04, 0.13, 0.18, 0.95)
		"gases_nobres": return Color(0.14, 0.06, 0.18, 0.95)
		"semimetais": return Color(0.06, 0.15, 0.09, 0.95)
		"hidrogenio": return Color(0.08, 0.14, 0.20, 0.95)
		_: return Color(0.08, 0.08, 0.12, 0.95)

func _obter_nome_categoria(cat: String) -> String:
	match cat:
		"metais": return "Metal"
		"ametais": return "Ametal"
		"gases_nobres": return "Gás Nobre"
		"semimetais": return "Semimetal"
		"hidrogenio": return "Hidrogênio"
		_: return "Elemento"

func _criar_cartao_prisma(titulo: String, subtitulo: String, cor_texto: Color, cor_fundo: Color, callback: Callable) -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(150, 75)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = cor_fundo
	sb.border_color = cor_texto
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	card.add_theme_stylebox_override("panel", sb)
	
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(vbox)
	
	var lbl_t = Label.new()
	lbl_t.text = titulo
	if font_titulo: lbl_t.add_theme_font_override("font", font_titulo)
	lbl_t.add_theme_font_size_override("font_size", 13)
	lbl_t.add_theme_color_override("font_color", cor_texto)
	lbl_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_t)
	
	var lbl_s = Label.new()
	lbl_s.text = subtitulo
	if font_sans: lbl_s.add_theme_font_override("font", font_sans)
	lbl_s.add_theme_font_size_override("font_size", 10)
	lbl_s.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	lbl_s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_s.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_s)
	
	var sb_h = sb.duplicate()
	sb_h.border_color = Color.WHITE
	
	card.mouse_entered.connect(func(): card.add_theme_stylebox_override("panel", sb_h))
	card.mouse_exited.connect(func(): card.add_theme_stylebox_override("panel", sb))
	card.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			_tocar_som("ui_2")
			callback.call()
	)
	return card

func _criar_faixa_cor(nome: String, onda: String, cor: Color, callback: Callable) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(250, 20)
	btn.text = " ■ %s (%s)" % [nome, onda]
	if font_sans: btn.add_theme_font_override("font", font_sans)
	btn.add_theme_font_size_override("font_size", 11)
	btn.add_theme_color_override("font_color", cor)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.06, 0.14, 0.8)
	sb.border_color = cor.darkened(0.3)
	sb.border_width_left = 3
	sb.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", sb)
	
	var sb_h = sb.duplicate()
	sb_h.bg_color = Color(0.18, 0.14, 0.28, 0.95)
	sb_h.border_color = cor
	btn.add_theme_stylebox_override("hover", sb_h)
	btn.add_theme_stylebox_override("pressed", sb_h)
	
	btn.pressed.connect(callback)
	return btn

func _criar_cartao_organela(titulo: String, subtitulo: String, cor_borda: Color, callback: Callable) -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(240, 56)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.07, 0.16, 0.96)
	sb.border_color = cor_borda
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	card.add_theme_stylebox_override("panel", sb)
	
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(vbox)
	
	var lbl_t = Label.new()
	lbl_t.text = titulo
	if font_titulo: lbl_t.add_theme_font_override("font", font_titulo)
	lbl_t.add_theme_font_size_override("font_size", 14)
	lbl_t.add_theme_color_override("font_color", cor_borda)
	lbl_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_t)
	
	var lbl_s = Label.new()
	lbl_s.text = subtitulo
	if font_sans: lbl_s.add_theme_font_override("font", font_sans)
	lbl_s.add_theme_font_size_override("font_size", 10)
	lbl_s.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	lbl_s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_s.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_s)
	
	var sb_h = sb.duplicate()
	sb_h.bg_color = Color(0.18, 0.14, 0.30, 1.0)
	sb_h.border_color = Color.WHITE
	
	card.mouse_entered.connect(func(): card.add_theme_stylebox_override("panel", sb_h))
	card.mouse_exited.connect(func(): card.add_theme_stylebox_override("panel", sb))
	card.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			_tocar_som("ui_2")
			callback.call()
	)
	return card

extends Control

# ==============================================================================
# GERENCIADOR DE PERGUNTAS - CADASTRO DE NOVA QUESTÃO
# Design System alinhado ao Painel Administrativo do Synthesis
# ==============================================================================

# Cores e Design System
const COLOR_BG_DARK = Color(0.06, 0.08, 0.12, 1.0)
const COLOR_HEADER_BG = Color(0.10, 0.13, 0.19, 1.0)
const COLOR_PANEL_BG = Color(0.11, 0.14, 0.21, 0.95)
const COLOR_CARD_BG = Color(0.13, 0.17, 0.25, 0.90)
const COLOR_BORDER_SUBTLE = Color(0.22, 0.28, 0.38, 0.70)
const COLOR_BORDER_ACCENT = Color(0.26, 0.60, 0.95, 0.80)

const COLOR_FACIL = Color(0.15, 0.78, 0.45, 1.0)      # Verde Esmeralda (Nível 1 / Acertos / Salvar)
const COLOR_MEDIO = Color(0.96, 0.68, 0.18, 1.0)      # Âmbar / Dourado (Nível 2)
const COLOR_DIFICIL = Color(0.95, 0.30, 0.32, 1.0)    # Carmim / Vermelho (Nível 3 / Erro)
const COLOR_TAXA = Color(0.96, 0.78, 0.20, 1.0)       # Amarelo Ouro
const COLOR_TEXT_MUTED = Color(0.62, 0.68, 0.78, 1.0)
const COLOR_TEXT_BRIGHT = Color(0.95, 0.97, 1.0, 1.0)

# Disciplinas
var disciplinas_info = {
	1: {"nome": "Química (Andar 1)", "cor": Color(0.70, 0.40, 0.95)},
	2: {"nome": "Física (Andar 2)", "cor": Color(0.20, 0.70, 0.95)},
	3: {"nome": "Biologia (Andar 3)", "cor": Color(0.35, 0.85, 0.45)}
}

# Limites de Caracteres para perfeita visualização na Batalha e Pergaminho
const MAX_CHARS_PERGUNTA: int = 280
const MAX_CHARS_DICA: int = 250
const MAX_CHARS_ALTERNATIVA: int = 80

# Referências de Componentes
var opt_disciplina: OptionButton
var opt_dificuldade: OptionButton
var badge_preview_disc: PanelContainer
var badge_preview_dif: PanelContainer
var lbl_preview_disc: Label
var lbl_preview_dif: Label

var input_pergunta: TextEdit
var lbl_contador_pergunta: Label
var input_dica: LineEdit
var lbl_contador_dica: Label

var inputs_alternativas: Array[LineEdit] = []
var containers_linhas_alt: Array[HBoxContainer] = []
var badges_letras_alt: Array[PanelContainer] = []
var labels_letras_alt: Array[Label] = []
var botoes_marcar_correta: Array[Button] = []

var opt_correta: OptionButton
var btn_salvar: Button
var btn_limpar: Button
var lbl_status: Label
var panel_status: PanelContainer

# Toast
var toast_notificacao: PanelContainer
var toast_label: Label
var toast_timer: Timer

func _ready() -> void:
	# Fundo Escuro Profissional
	var bg = ColorRect.new()
	bg.color = COLOR_BG_DARK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Margens Principais (Viewport 1280x720 calibrado)
	var margem = MarginContainer.new()
	margem.add_theme_constant_override("margin_left", 24)
	margem.add_theme_constant_override("margin_right", 24)
	margem.add_theme_constant_override("margin_top", 16)
	margem.add_theme_constant_override("margin_bottom", 16)
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(margem)
	
	var vbox_root = VBoxContainer.new()
	vbox_root.add_theme_constant_override("separation", 14)
	vbox_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margem.add_child(vbox_root)
	
	# 1. Cabeçalho Superior Alinhado ao Painel Admin
	_criar_cabecalho(vbox_root)
	
	# 2. Área Rolável Central (Scroll Vertical Apenas)
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_root.add_child(scroll)
	
	var vbox_form = VBoxContainer.new()
	vbox_form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_form.add_theme_constant_override("separation", 14)
	scroll.add_child(vbox_form)
	
	# 3. Card 1: Configuração Pedagógica (Disciplina e Grau TRI)
	_criar_card_configuracao(vbox_form)
	
	# 4. Card 2: Enunciado da Pergunta e Dica
	_criar_card_enunciado(vbox_form)
	
	# 5. Card 3: Alternativas de Resposta e Seleção do Gabarito
	_criar_card_alternativas(vbox_form)
	
	# 6. Card 4: Ações de Salvamento e Status
	_criar_card_acoes(vbox_form)
	
	# 7. Toast Notificação Flutuante
	_criar_toast(self)
	
	# Inicializa destaques visuais
	_atualizar_badges_preview()
	_atualizar_destaque_gabarito()

# ==============================================================================
# CONSTRUÇÃO DOS COMPONENTES VISUAIS
# ==============================================================================

func _criar_cabecalho(parent: Control) -> void:
	var panel_cab = PanelContainer.new()
	var style_cab = _criar_stylebox(COLOR_HEADER_BG, COLOR_BORDER_SUBTLE, 10, 1)
	style_cab.content_margin_left = 18
	style_cab.content_margin_right = 18
	style_cab.content_margin_top = 12
	style_cab.content_margin_bottom = 12
	panel_cab.add_theme_stylebox_override("panel", style_cab)
	parent.add_child(panel_cab)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 14)
	panel_cab.add_child(hbox)
	
	# Título e Subtítulo
	var vbox_titulos = VBoxContainer.new()
	vbox_titulos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_titulos.add_theme_constant_override("separation", 2)
	hbox.add_child(vbox_titulos)
	
	var hbox_tag = HBoxContainer.new()
	hbox_tag.add_theme_constant_override("separation", 8)
	vbox_titulos.add_child(hbox_tag)
	
	var badge_tag = _criar_badge("NOVA QUESTÃO", COLOR_BORDER_ACCENT * 0.25, COLOR_BORDER_ACCENT)
	hbox_tag.add_child(badge_tag)
	
	var lbl_tit = Label.new()
	lbl_tit.text = "Gerenciador Pedagógico - Cadastrar Pergunta"
	lbl_tit.add_theme_font_size_override("font_size", 18)
	lbl_tit.add_theme_color_override("font_color", COLOR_TEXT_BRIGHT)
	hbox_tag.add_child(lbl_tit)
	
	var lbl_sub = Label.new()
	lbl_sub.text = "Synthesis • Cadastre novas perguntas e desafios para os jogadores"
	lbl_sub.add_theme_font_size_override("font_size", 12)
	lbl_sub.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	vbox_titulos.add_child(lbl_sub)
	
	# Botão Voltar ao Painel
	var btn_voltar = _criar_botao_acao("Voltar ao Painel", Color(0.45, 0.50, 0.62))
	btn_voltar.pressed.connect(func(): TransitionScreen.change_scene("res://scenes/ui/painel_admin.tscn"))
	hbox.add_child(btn_voltar)

func _criar_card_configuracao(parent: Control) -> void:
	var card = _criar_card_base(parent)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	card.add_child(vbox)
	
	_criar_cabecalho_secao(vbox, "1. Disciplina e Dificuldade", "Selecione a matéria e o nível de desafio da questão.")
	
	var grid = HBoxContainer.new()
	grid.add_theme_constant_override("separation", 24)
	vbox.add_child(grid)
	
	# Coluna 1: Disciplina
	var col_disc = VBoxContainer.new()
	col_disc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_disc.add_theme_constant_override("separation", 6)
	grid.add_child(col_disc)
	
	var hbox_lbl_disc = HBoxContainer.new()
	hbox_lbl_disc.add_theme_constant_override("separation", 8)
	col_disc.add_child(hbox_lbl_disc)
	
	var lbl_disc = Label.new()
	lbl_disc.text = "Disciplina (Andar):"
	lbl_disc.add_theme_font_size_override("font_size", 13)
	lbl_disc.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	hbox_lbl_disc.add_child(lbl_disc)
	
	badge_preview_disc = _criar_badge("Química", Color(0.70, 0.40, 0.95) * 0.25, Color(0.70, 0.40, 0.95))
	lbl_preview_disc = badge_preview_disc.get_child(0) as Label
	hbox_lbl_disc.add_child(badge_preview_disc)
	
	opt_disciplina = OptionButton.new()
	opt_disciplina.custom_minimum_size = Vector2(0, 38)
	opt_disciplina.focus_mode = Control.FOCUS_NONE
	opt_disciplina.add_item("Química (Andar 1)", 1)
	opt_disciplina.add_item("Física (Andar 2)", 2)
	opt_disciplina.add_item("Biologia (Andar 3)", 3)
	_estilizar_option_button(opt_disciplina)
	opt_disciplina.item_selected.connect(func(_idx): _atualizar_badges_preview())
	col_disc.add_child(opt_disciplina)
	
	# Coluna 2: Grau de Dificuldade (TRI)
	var col_dif = VBoxContainer.new()
	col_dif.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_dif.add_theme_constant_override("separation", 6)
	grid.add_child(col_dif)
	
	var hbox_lbl_dif = HBoxContainer.new()
	hbox_lbl_dif.add_theme_constant_override("separation", 8)
	col_dif.add_child(hbox_lbl_dif)
	
	var lbl_dif = Label.new()
	lbl_dif.text = "Grau de Dificuldade:"
	lbl_dif.add_theme_font_size_override("font_size", 13)
	lbl_dif.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	hbox_lbl_dif.add_child(lbl_dif)
	
	badge_preview_dif = _criar_badge("Fácil", COLOR_FACIL * 0.25, COLOR_FACIL)
	lbl_preview_dif = badge_preview_dif.get_child(0) as Label
	hbox_lbl_dif.add_child(badge_preview_dif)
	
	opt_dificuldade = OptionButton.new()
	opt_dificuldade.custom_minimum_size = Vector2(0, 38)
	opt_dificuldade.focus_mode = Control.FOCUS_NONE
	opt_dificuldade.add_item("Nível 1 - Fácil (Salas 1 a 3)", 1)
	opt_dificuldade.add_item("Nível 2 - Médio (Salas 4 a 5)", 2)
	opt_dificuldade.add_item("Nível 3 - Difícil (Salas 6 a 8 / Desafio Final)", 3)
	_estilizar_option_button(opt_dificuldade)
	opt_dificuldade.item_selected.connect(func(_idx): _atualizar_badges_preview())
	col_dif.add_child(opt_dificuldade)

func _criar_card_enunciado(parent: Control) -> void:
	var card = _criar_card_base(parent)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	card.add_child(vbox)
	
	# Cabeçalho com Contador de Caracteres da Pergunta
	var hbox_header = HBoxContainer.new()
	vbox.add_child(hbox_header)
	
	var vbox_tit = VBoxContainer.new()
	vbox_tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_tit.add_theme_constant_override("separation", 2)
	hbox_header.add_child(vbox_tit)
	
	var lbl_tit = Label.new()
	lbl_tit.text = "2. Enunciado da Pergunta"
	lbl_tit.add_theme_font_size_override("font_size", 15)
	lbl_tit.add_theme_color_override("font_color", COLOR_TEXT_BRIGHT)
	vbox_tit.add_child(lbl_tit)
	
	var lbl_sub = Label.new()
	lbl_sub.text = "Escreva a pergunta de forma clara (máx. %d caracteres para caber na tela de batalha)." % MAX_CHARS_PERGUNTA
	lbl_sub.add_theme_font_size_override("font_size", 11)
	lbl_sub.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	vbox_tit.add_child(lbl_sub)
	
	lbl_contador_pergunta = Label.new()
	lbl_contador_pergunta.text = "0 / %d caracteres" % MAX_CHARS_PERGUNTA
	lbl_contador_pergunta.add_theme_font_size_override("font_size", 12)
	lbl_contador_pergunta.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	hbox_header.add_child(lbl_contador_pergunta)
	
	# Caixa de Enunciado
	input_pergunta = TextEdit.new()
	input_pergunta.custom_minimum_size = Vector2(0, 95)
	input_pergunta.placeholder_text = "Digite aqui o enunciado completo da pergunta..."
	input_pergunta.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_estilizar_text_edit(input_pergunta)
	input_pergunta.text_changed.connect(_on_pergunta_text_changed)
	vbox.add_child(input_pergunta)
	
	# Campo Opcional de Dica para os Pergaminhos
	var vbox_dica = VBoxContainer.new()
	vbox_dica.add_theme_constant_override("separation", 4)
	vbox.add_child(vbox_dica)
	
	var hbox_dica_header = HBoxContainer.new()
	vbox_dica.add_child(hbox_dica_header)
	
	var lbl_dica_tit = Label.new()
	lbl_dica_tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_dica_tit.text = "Dica para o Pergaminho (Opcional - exibida nas anotações encontradas no mapa):"
	lbl_dica_tit.add_theme_font_size_override("font_size", 12)
	lbl_dica_tit.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	hbox_dica_header.add_child(lbl_dica_tit)
	
	lbl_contador_dica = Label.new()
	lbl_contador_dica.text = "0 / %d caracteres" % MAX_CHARS_DICA
	lbl_contador_dica.add_theme_font_size_override("font_size", 12)
	lbl_contador_dica.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	hbox_dica_header.add_child(lbl_contador_dica)
	
	input_dica = LineEdit.new()
	input_dica.max_length = MAX_CHARS_DICA
	input_dica.custom_minimum_size = Vector2(0, 36)
	input_dica.placeholder_text = "Ex: Observe a tabela periódica e o número de elétrons da camada de valência..."
	_estilizar_line_edit(input_dica)
	input_dica.text_changed.connect(_on_dica_text_changed)
	vbox_dica.add_child(input_dica)

func _criar_card_alternativas(parent: Control) -> void:
	var card = _criar_card_base(parent)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	card.add_child(vbox)
	
	_criar_cabecalho_secao(vbox, "3. Alternativas de Resposta & Gabarito Oficial", "Preencha as 5 opções (máx. %d caracteres cada) e indique qual delas é a correta." % MAX_CHARS_ALTERNATIVA)
	
	inputs_alternativas.clear()
	containers_linhas_alt.clear()
	badges_letras_alt.clear()
	labels_letras_alt.clear()
	botoes_marcar_correta.clear()
	
	var letras = ["A", "B", "C", "D", "E"]
	for i in range(5):
		var letra = letras[i]
		
		var hbox_linha = HBoxContainer.new()
		hbox_linha.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox_linha)
		containers_linhas_alt.append(hbox_linha)
		
		# Badge da Letra
		var badge_letra = _criar_badge("Alternativa " + letra, Color(0.15, 0.18, 0.26), COLOR_TEXT_MUTED)
		badge_letra.custom_minimum_size = Vector2(105, 36)
		var lbl_letra = badge_letra.get_child(0) as Label
		lbl_letra.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hbox_linha.add_child(badge_letra)
		badges_letras_alt.append(badge_letra)
		labels_letras_alt.append(lbl_letra)
		
		# Campo de Texto
		var input_alt = LineEdit.new()
		input_alt.max_length = MAX_CHARS_ALTERNATIVA
		input_alt.custom_minimum_size = Vector2(0, 36)
		input_alt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		input_alt.placeholder_text = "Digite o texto da alternativa %s..." % letra
		_estilizar_line_edit(input_alt)
		hbox_linha.add_child(input_alt)
		inputs_alternativas.append(input_alt)
		
		# Botão rápido para marcar como correta
		var btn_marcar = Button.new()
		btn_marcar.text = "Marcar como Correta"
		btn_marcar.focus_mode = Control.FOCUS_NONE
		btn_marcar.custom_minimum_size = Vector2(160, 36)
		btn_marcar.pressed.connect(func():
			opt_correta.select(i)
			_atualizar_destaque_gabarito()
		)
		_estilizar_botao_secundario(btn_marcar)
		hbox_linha.add_child(btn_marcar)
		botoes_marcar_correta.append(btn_marcar)
	
	# Seletor de Gabarito Oficial Inferior
	var hbox_gabarito = HBoxContainer.new()
	hbox_gabarito.add_theme_constant_override("separation", 12)
	hbox_gabarito.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.add_child(hbox_gabarito)
	
	var lbl_gab = Label.new()
	lbl_gab.text = "Gabarito Selecionado:"
	lbl_gab.add_theme_font_size_override("font_size", 13)
	lbl_gab.add_theme_color_override("font_color", COLOR_FACIL)
	hbox_gabarito.add_child(lbl_gab)
	
	opt_correta = OptionButton.new()
	opt_correta.custom_minimum_size = Vector2(220, 36)
	opt_correta.focus_mode = Control.FOCUS_NONE
	opt_correta.add_item("Alternativa A (Correta)", 0)
	opt_correta.add_item("Alternativa B (Correta)", 1)
	opt_correta.add_item("Alternativa C (Correta)", 2)
	opt_correta.add_item("Alternativa D (Correta)", 3)
	opt_correta.add_item("Alternativa E (Correta)", 4)
	_estilizar_option_button(opt_correta, COLOR_FACIL)
	opt_correta.item_selected.connect(func(_idx): _atualizar_destaque_gabarito())
	hbox_gabarito.add_child(opt_correta)

func _criar_card_acoes(parent: Control) -> void:
	var card = _criar_card_base(parent)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	card.add_child(vbox)
	
	var hbox_botoes = HBoxContainer.new()
	hbox_botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_botoes.add_theme_constant_override("separation", 16)
	vbox.add_child(hbox_botoes)
	
	# Botão Salvar
	btn_salvar = Button.new()
	btn_salvar.text = "  Salvar Nova Pergunta  "
	btn_salvar.focus_mode = Control.FOCUS_NONE
	btn_salvar.custom_minimum_size = Vector2(260, 44)
	
	var style_salvar = _criar_stylebox(Color(0.12, 0.65, 0.38, 1.0), COLOR_FACIL, 8, 1)
	style_salvar.content_margin_left = 16
	style_salvar.content_margin_right = 16
	var style_salvar_hover = style_salvar.duplicate()
	style_salvar_hover.bg_color = Color(0.15, 0.78, 0.45, 1.0)
	
	btn_salvar.add_theme_stylebox_override("normal", style_salvar)
	btn_salvar.add_theme_stylebox_override("hover", style_salvar_hover)
	btn_salvar.add_theme_stylebox_override("pressed", style_salvar)
	btn_salvar.add_theme_color_override("font_color", Color.WHITE)
	btn_salvar.add_theme_font_size_override("font_size", 14)
	btn_salvar.pressed.connect(_on_salvar_pressed)
	hbox_botoes.add_child(btn_salvar)
	
	# Botão Limpar
	btn_limpar = Button.new()
	btn_limpar.text = "Limpar Formulário"
	btn_limpar.focus_mode = Control.FOCUS_NONE
	btn_limpar.custom_minimum_size = Vector2(160, 44)
	_estilizar_botao_secundario(btn_limpar)
	btn_limpar.pressed.connect(_limpar_formulario)
	hbox_botoes.add_child(btn_limpar)
	
	# Painel de Status
	panel_status = PanelContainer.new()
	panel_status.visible = false
	var style_status = _criar_stylebox(Color(0.08, 0.10, 0.15, 0.95), COLOR_BORDER_SUBTLE, 6, 1)
	style_status.content_margin_top = 8
	style_status.content_margin_bottom = 8
	panel_status.add_theme_stylebox_override("panel", style_status)
	vbox.add_child(panel_status)
	
	lbl_status = Label.new()
	lbl_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_status.add_theme_font_size_override("font_size", 13)
	panel_status.add_child(lbl_status)

# ==============================================================================
# LOGICA VISUAL E DINÂMICA (PREVIEWS & GABARITO)
# ==============================================================================

func _atualizar_badges_preview() -> void:
	var id_disc = opt_disciplina.get_selected_id()
	if disciplinas_info.has(id_disc):
		var info = disciplinas_info[id_disc]
		lbl_preview_disc.text = info["nome"]
		var style_d = _criar_stylebox(info["cor"] * 0.22, info["cor"] * 0.7, 4, 1)
		style_d.content_margin_left = 6
		style_d.content_margin_right = 6
		badge_preview_disc.add_theme_stylebox_override("panel", style_d)
		lbl_preview_disc.add_theme_color_override("font_color", info["cor"])
	
	var id_dif = opt_dificuldade.get_selected_id()
	var cor_dif = COLOR_FACIL
	var nome_dif = "Nível 1 - Fácil"
	if id_dif == 2:
		cor_dif = COLOR_TAXA
		nome_dif = "Nível 2 - Médio"
	elif id_dif == 3:
		cor_dif = COLOR_DIFICIL
		nome_dif = "Nível 3 - Difícil"
		
	lbl_preview_dif.text = nome_dif
	var style_dif = _criar_stylebox(cor_dif * 0.22, cor_dif * 0.7, 4, 1)
	style_dif.content_margin_left = 6
	style_dif.content_margin_right = 6
	badge_preview_dif.add_theme_stylebox_override("panel", style_dif)
	lbl_preview_dif.add_theme_color_override("font_color", cor_dif)

func _atualizar_destaque_gabarito() -> void:
	var idx_correto = opt_correta.get_selected_id()
	var letras = ["A", "B", "C", "D", "E"]
	
	for i in range(5):
		var eh_correta = (i == idx_correto)
		var letra = letras[i]
		var badge = badges_letras_alt[i]
		var lbl_letra = labels_letras_alt[i]
		var input_alt = inputs_alternativas[i]
		var btn_marcar = botoes_marcar_correta[i]
		
		if eh_correta:
			# Estilo de Destaque para a Alternativa Correta
			lbl_letra.text = "Alternativa " + letra + " (Correta)"
			lbl_letra.add_theme_color_override("font_color", COLOR_FACIL)
			var sb_badge = _criar_stylebox(COLOR_FACIL * 0.22, COLOR_FACIL, 5, 1)
			sb_badge.content_margin_left = 8
			sb_badge.content_margin_right = 8
			badge.add_theme_stylebox_override("panel", sb_badge)
			
			var sb_inp = _criar_stylebox_input(true)
			sb_inp.border_color = COLOR_FACIL
			input_alt.add_theme_stylebox_override("normal", sb_inp)
			
			btn_marcar.text = "Gabarito Selecionado"
			var sb_btn = _criar_stylebox(COLOR_FACIL * 0.25, COLOR_FACIL, 6, 1)
			btn_marcar.add_theme_stylebox_override("normal", sb_btn)
			btn_marcar.add_theme_stylebox_override("hover", sb_btn)
			btn_marcar.add_theme_color_override("font_color", COLOR_FACIL)
		else:
			# Estilo Padrão para as outras
			lbl_letra.text = "Alternativa " + letra
			lbl_letra.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
			var sb_badge = _criar_stylebox(Color(0.12, 0.15, 0.22), COLOR_BORDER_SUBTLE, 5, 1)
			sb_badge.content_margin_left = 8
			sb_badge.content_margin_right = 8
			badge.add_theme_stylebox_override("panel", sb_badge)
			
			var sb_inp = _criar_stylebox_input(false)
			input_alt.add_theme_stylebox_override("normal", sb_inp)
			
			btn_marcar.text = "Marcar como Correta"
			_estilizar_botao_secundario(btn_marcar)

# ==============================================================================
# SALVAMENTO E SINCRONIZAÇÃO
# ==============================================================================

func _on_salvar_pressed() -> void:
	if input_pergunta.text.strip_edges().is_empty():
		_mostrar_erro("O enunciado da questão não pode ficar vazio!")
		return
		
	for i in range(inputs_alternativas.size()):
		if inputs_alternativas[i].text.strip_edges().is_empty():
			var letras = ["A", "B", "C", "D", "E"]
			_mostrar_erro("Preencha o texto da Alternativa %s!" % letras[i])
			return
			
	_mostrar_status("Salvando nova pergunta, aguarde...", COLOR_TAXA)
	btn_salvar.disabled = true
	
	var opcoes_array = [
		inputs_alternativas[0].text.strip_edges(),
		inputs_alternativas[1].text.strip_edges(),
		inputs_alternativas[2].text.strip_edges(),
		inputs_alternativas[3].text.strip_edges(),
		inputs_alternativas[4].text.strip_edges()
	]
	
	var andar_escolhido = opt_disciplina.get_selected_id()
	var nivel_escolhido = opt_dificuldade.get_selected_id()
	var dica_texto = input_dica.text.strip_edges()
	
	var dados_supabase = {
		"andar_id": andar_escolhido,
		"question": input_pergunta.text.strip_edges(),
		"options": opcoes_array,
		"answer": opt_correta.get_selected_id(),
		"nivel_progresso": nivel_escolhido
	}
	
	var res = await DatabaseManager.request_async("/rest/v1/perguntas", HTTPClient.METHOD_POST, dados_supabase)
	btn_salvar.disabled = false
	
	if res["success"]:
		_mostrar_status("Pergunta cadastrada com sucesso no jogo!", COLOR_FACIL)
		_exibir_toast("Questão cadastrada com sucesso!")
		
		# Salva também no arquivo local questions.json associando a dica para os pergaminhos
		var dados_para_salvar = dados_supabase.duplicate()
		if res.get("data") is Array and res["data"].size() > 0:
			dados_para_salvar = res["data"][0].duplicate()
		elif res.get("data") is Dictionary:
			dados_para_salvar = res["data"].duplicate()
			
		dados_para_salvar["dica"] = dica_texto
		DatabaseManager.salvar_pergunta_local(dados_para_salvar)
		
		_limpar_formulario()
	else:
		_mostrar_erro("Erro ao salvar a pergunta: " + str(res.get("message", "Falha de conexão")))

func _on_pergunta_text_changed() -> void:
	var txt = input_pergunta.text
	if txt.length() > MAX_CHARS_PERGUNTA:
		var caret_col = input_pergunta.get_caret_column()
		var caret_line = input_pergunta.get_caret_line()
		input_pergunta.text = txt.substr(0, MAX_CHARS_PERGUNTA)
		input_pergunta.set_caret_line(caret_line)
		input_pergunta.set_caret_column(min(caret_col, MAX_CHARS_PERGUNTA))
		txt = input_pergunta.text
		
	var count = txt.length()
	if lbl_contador_pergunta:
		lbl_contador_pergunta.text = "%d / %d caracteres" % [count, MAX_CHARS_PERGUNTA]
		if count >= MAX_CHARS_PERGUNTA:
			lbl_contador_pergunta.add_theme_color_override("font_color", COLOR_DIFICIL)
		elif count >= 220:
			lbl_contador_pergunta.add_theme_color_override("font_color", COLOR_TAXA)
		else:
			lbl_contador_pergunta.add_theme_color_override("font_color", COLOR_TEXT_MUTED)

func _on_dica_text_changed(novo_texto: String) -> void:
	var count = novo_texto.length()
	if lbl_contador_dica:
		lbl_contador_dica.text = "%d / %d caracteres" % [count, MAX_CHARS_DICA]
		if count >= MAX_CHARS_DICA:
			lbl_contador_dica.add_theme_color_override("font_color", COLOR_DIFICIL)
		elif count >= 200:
			lbl_contador_dica.add_theme_color_override("font_color", COLOR_TAXA)
		else:
			lbl_contador_dica.add_theme_color_override("font_color", COLOR_TEXT_MUTED)

func _limpar_formulario() -> void:
	input_pergunta.text = ""
	input_dica.text = ""
	if lbl_contador_pergunta:
		lbl_contador_pergunta.text = "0 / %d caracteres" % MAX_CHARS_PERGUNTA
		lbl_contador_pergunta.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	if lbl_contador_dica:
		lbl_contador_dica.text = "0 / %d caracteres" % MAX_CHARS_DICA
		lbl_contador_dica.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	for inp in inputs_alternativas:
		inp.text = ""
	opt_correta.select(0)
	_atualizar_destaque_gabarito()

func _mostrar_status(msg: String, cor: Color) -> void:
	panel_status.visible = true
	lbl_status.text = msg
	lbl_status.add_theme_color_override("font_color", cor)
	var sb = _criar_stylebox(cor * 0.15, cor * 0.5, 6, 1)
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	panel_status.add_theme_stylebox_override("panel", sb)

func _mostrar_erro(msg: String) -> void:
	_mostrar_status("ATENÇÃO: " + msg, COLOR_DIFICIL)
	_exibir_toast(msg)

# ==============================================================================
# HELPERS DE DESIGN SYSTEM E ESTILOS
# ==============================================================================

func _criar_card_base(parent: Control) -> PanelContainer:
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = _criar_stylebox(COLOR_CARD_BG, COLOR_BORDER_SUBTLE, 8, 1)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)
	return card

func _criar_cabecalho_secao(parent: Control, titulo: String, subtitulo: String) -> void:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	parent.add_child(vbox)
	
	var lbl_tit = Label.new()
	lbl_tit.text = titulo
	lbl_tit.add_theme_font_size_override("font_size", 15)
	lbl_tit.add_theme_color_override("font_color", COLOR_TEXT_BRIGHT)
	vbox.add_child(lbl_tit)
	
	var lbl_sub = Label.new()
	lbl_sub.text = subtitulo
	lbl_sub.add_theme_font_size_override("font_size", 11)
	lbl_sub.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	vbox.add_child(lbl_sub)

func _criar_stylebox(bg: Color, border_c: Color = Color(0, 0, 0, 0), radius: int = 6, border_w: int = 0) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	if border_w > 0:
		sb.border_color = border_c
		sb.border_width_left = border_w
		sb.border_width_top = border_w
		sb.border_width_right = border_w
		sb.border_width_bottom = border_w
	return sb

func _criar_stylebox_input(foco: bool = false) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.15, 0.95)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = COLOR_BORDER_ACCENT if foco else COLOR_BORDER_SUBTLE
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

func _estilizar_line_edit(line_edit: LineEdit) -> void:
	var sb_normal = _criar_stylebox_input(false)
	var sb_focus = _criar_stylebox_input(true)
	line_edit.add_theme_stylebox_override("normal", sb_normal)
	line_edit.add_theme_stylebox_override("focus", sb_focus)
	line_edit.add_theme_color_override("font_color", COLOR_TEXT_BRIGHT)
	line_edit.add_theme_color_override("font_placeholder_color", Color(0.40, 0.45, 0.55))
	line_edit.add_theme_font_size_override("font_size", 13)

func _estilizar_text_edit(text_edit: TextEdit) -> void:
	var sb_normal = _criar_stylebox_input(false)
	var sb_focus = _criar_stylebox_input(true)
	text_edit.add_theme_stylebox_override("normal", sb_normal)
	text_edit.add_theme_stylebox_override("focus", sb_focus)
	text_edit.add_theme_color_override("font_color", COLOR_TEXT_BRIGHT)
	text_edit.add_theme_color_override("font_placeholder_color", Color(0.40, 0.45, 0.55))
	text_edit.add_theme_font_size_override("font_size", 13)

func _estilizar_option_button(btn: OptionButton, borda_destaque: Color = Color(0, 0, 0, 0)) -> void:
	var sb = _criar_stylebox_input(false)
	if borda_destaque != Color(0, 0, 0, 0):
		sb.border_color = borda_destaque
	var sb_hover = sb.duplicate()
	sb_hover.bg_color = Color(0.12, 0.15, 0.22, 0.95)
	
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_hover)
	btn.add_theme_stylebox_override("focus", sb_hover)
	btn.add_theme_color_override("font_color", COLOR_TEXT_BRIGHT)
	btn.add_theme_font_size_override("font_size", 13)
	
	var popup = btn.get_popup()
	if popup:
		var sb_pop = _criar_stylebox(Color(0.09, 0.12, 0.18, 0.98), COLOR_BORDER_SUBTLE, 6, 1)
		popup.add_theme_stylebox_override("panel", sb_pop)
		popup.add_theme_color_override("font_color", COLOR_TEXT_BRIGHT)
		popup.add_theme_color_override("font_hover_color", Color.WHITE)

func _estilizar_botao_secundario(btn: Button) -> void:
	var sb = _criar_stylebox(Color(0.12, 0.15, 0.22, 0.9), COLOR_BORDER_SUBTLE, 6, 1)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	var sb_hover = sb.duplicate()
	sb_hover.bg_color = Color(0.18, 0.22, 0.32, 1.0)
	sb_hover.border_color = COLOR_BORDER_ACCENT
	
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	btn.add_theme_color_override("font_hover_color", COLOR_TEXT_BRIGHT)
	btn.add_theme_font_size_override("font_size", 12)

func _criar_botao_acao(texto: String, cor: Color) -> Button:
	var btn = Button.new()
	btn.text = " " + texto + " "
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 32)
	
	var style = _criar_stylebox(cor * 0.22, cor, 6, 1)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	
	var style_hover = style.duplicate()
	style_hover.bg_color = cor * 0.40
	
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 12)
	return btn

func _criar_badge(texto: String, bg_cor: Color, texto_cor: Color) -> PanelContainer:
	var panel = PanelContainer.new()
	var style = _criar_stylebox(bg_cor, texto_cor * 0.7, 4, 1)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", style)
	
	var lbl = Label.new()
	lbl.text = texto
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", texto_cor)
	panel.add_child(lbl)
	return panel

func _criar_toast(parent: Control) -> void:
	toast_notificacao = PanelContainer.new()
	toast_notificacao.visible = false
	toast_notificacao.custom_minimum_size = Vector2(320, 40)
	toast_notificacao.anchor_left = 1.0
	toast_notificacao.anchor_right = 1.0
	toast_notificacao.offset_left = -350
	toast_notificacao.offset_right = -20
	toast_notificacao.offset_top = 16
	toast_notificacao.offset_bottom = 60
	toast_notificacao.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	
	var style_toast = _criar_stylebox(Color(0.15, 0.20, 0.28, 0.95), COLOR_BORDER_ACCENT, 6, 2)
	style_toast.content_margin_left = 14
	style_toast.content_margin_right = 14
	style_toast.content_margin_top = 8
	style_toast.content_margin_bottom = 8
	toast_notificacao.add_theme_stylebox_override("panel", style_toast)
	parent.add_child(toast_notificacao)
	
	toast_label = Label.new()
	toast_label.add_theme_font_size_override("font_size", 12)
	toast_label.add_theme_color_override("font_color", COLOR_TEXT_BRIGHT)
	toast_notificacao.add_child(toast_label)
	
	toast_timer = Timer.new()
	toast_timer.one_shot = true
	toast_timer.wait_time = 3.5
	toast_timer.timeout.connect(func(): toast_notificacao.visible = false)
	add_child(toast_timer)

func _exibir_toast(mensagem: String) -> void:
	if toast_label != null and toast_notificacao != null:
		toast_label.text = mensagem
		toast_notificacao.visible = true
		toast_timer.start()

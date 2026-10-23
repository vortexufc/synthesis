extends Control

# PAINEL ADMINISTRATIVO & PEDAGÓGICO - SYNTHESIS
# Gestão de Questões, Análise TRI e Estatísticas de Desempenho

# Cores e Design System
const COLOR_BG_DARK = Color(0.06, 0.08, 0.12, 1.0)
const COLOR_HEADER_BG = Color(0.10, 0.13, 0.19, 1.0)
const COLOR_PANEL_BG = Color(0.11, 0.14, 0.21, 0.95)
const COLOR_CARD_BG = Color(0.13, 0.17, 0.25, 0.90)
const COLOR_BORDER_SUBTLE = Color(0.22, 0.28, 0.38, 0.70)
const COLOR_BORDER_ACCENT = Color(0.26, 0.60, 0.95, 0.80)

const COLOR_FACIL = Color(0.15, 0.78, 0.45, 1.0)      # Verde Esmeralda (Nível 1 / Acertos)
const COLOR_MEDIO = Color(0.96, 0.68, 0.18, 1.0)      # Âmbar / Dourado (Nível 2)
const COLOR_DIFICIL = Color(0.95, 0.30, 0.32, 1.0)    # Carmim / Vermelho (Nível 3 / Erros)
const COLOR_TAXA = Color(0.96, 0.78, 0.20, 1.0)       # Amarelo Ouro (Padrão para Taxa)
const COLOR_TEXT_MUTED = Color(0.62, 0.68, 0.78, 1.0)
const COLOR_TEXT_BRIGHT = Color(0.95, 0.97, 1.0, 1.0)

# Disciplinas disponíveis no jogo (Andar 1 = Química, 2 = Física, 3 = Biologia)
var disciplinas: Array[Dictionary] = [
	{"nome": "Química", "andar_id": 1, "cor": Color(0.70, 0.40, 0.95)},
	{"nome": "Física", "andar_id": 2, "cor": Color(0.20, 0.70, 0.95)},
	{"nome": "Biologia", "andar_id": 3, "cor": Color(0.35, 0.85, 0.45)}
]
var disciplina_atual_idx: int = 0

# Estado dos dados
var dados_perguntas_brutos: Array = []
var mapa_respostas: Dictionary = {}
var lista_questoes_processadas: Array = []
var total_jogadores_count: int = 0

# Estado de filtros e ordenação
var filtro_dificuldade_atual: String = "todas" # "todas", "facil", "medio", "dificil"
var modo_ordenacao_atual: int = 0
var texto_pesquisa: String = ""

# Referências de UI
var tabela_dados: VBoxContainer
var lbl_total_questoes_val: Label
var lbl_total_questoes_sub: Label
var lbl_taxa_acerto_val: Label
var lbl_taxa_acerto_sub: Label
var lbl_total_respostas_val: Label
var lbl_total_respostas_sub: Label
var lbl_total_jogadores_val: Label
var lbl_total_jogadores_sub: Label

var btn_disciplinas: Array[Button] = []
var btn_filtros: Dictionary = {}
var opt_ordenacao: OptionButton
var input_busca: LineEdit
var toast_notificacao: PanelContainer
var toast_label: Label
var toast_timer: Timer

# Modal de Confirmação de Exclusão
var modal_exclusao: Control
# Modal de Reset
var popup_reset: Control
var line_edit_senha: LineEdit

# Gestão de Sessões / Escolas (Avaliação Pedagógica)
var opt_sessao_escola: OptionButton
var btn_ativar_sessao: Button
var lbl_sessao_status: Label
var sessoes_carregadas: Array[Dictionary] = []
var popup_nova_sessao: Control
var popup_ativar_sessao: Control

func _ready() -> void:
	# Fundo geral sofisticado
	var bg = ColorRect.new()
	bg.color = COLOR_BG_DARK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Layout Principal calibrado para viewport 1280x720 (sem overflow)
	var margem = MarginContainer.new()
	margem.add_theme_constant_override("margin_left", 20)
	margem.add_theme_constant_override("margin_right", 20)
	margem.add_theme_constant_override("margin_top", 16)
	margem.add_theme_constant_override("margin_bottom", 16)
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(margem)
	
	var vbox_principal = VBoxContainer.new()
	vbox_principal.add_theme_constant_override("separation", 12)
	vbox_principal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_principal.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margem.add_child(vbox_principal)
	
	# 1. Cabeçalho Superior Limpo e Profissional
	_criar_cabecalho(vbox_principal)
	
	# 2. Barra de Gestão de Sessão / Escola (Escola Ativa, Nova Escola, Ativação)
	_criar_barra_sessao_escola(vbox_principal)
	
	# 3. Seletor de Disciplina
	_criar_seletor_disciplinas(vbox_principal)
	
	# 4. Cards de Resumo KPI (Dashboard Pedagógico)
	_criar_dashboard_cards(vbox_principal)
	
	# 4. Barra de Controles: Filtro, Ordenação e Pesquisa
	_criar_barra_controles(vbox_principal)
	
	# 5. Tabela/Cards com Lista de Questões Rolável (apenas scroll vertical)
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_principal.add_child(scroll)
	
	tabela_dados = VBoxContainer.new()
	tabela_dados.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabela_dados.add_theme_constant_override("separation", 10)
	scroll.add_child(tabela_dados)
	
	# 6. Toast Flutuante para Mensagens
	_criar_toast(self)
	
	# Carrega os dados iniciais
	_carregar_dados()

# CONSTRUÇÃO DE COMPONENTES VISUAIS

func _criar_cabecalho(parent: Control) -> void:
	var panel_cab = PanelContainer.new()
	var style_cab = _criar_stylebox(COLOR_HEADER_BG, COLOR_BORDER_SUBTLE, 10, 1)
	style_cab.content_margin_left = 16
	style_cab.content_margin_right = 16
	style_cab.content_margin_top = 10
	style_cab.content_margin_bottom = 10
	panel_cab.add_theme_stylebox_override("panel", style_cab)
	parent.add_child(panel_cab)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 12)
	panel_cab.add_child(hbox)
	
	# Título e Subtítulo
	var vbox_titulos = VBoxContainer.new()
	vbox_titulos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_titulos.add_theme_constant_override("separation", 2)
	hbox.add_child(vbox_titulos)
	
	var lbl_tit = Label.new()
	lbl_tit.text = "Painel Administrativo & Pedagógico"
	lbl_tit.add_theme_font_size_override("font_size", 20)
	lbl_tit.add_theme_color_override("font_color", COLOR_TEXT_BRIGHT)
	vbox_titulos.add_child(lbl_tit)
	
	var lbl_sub = Label.new()
	lbl_sub.text = "Synthesis • Desempenho dos Alunos e Gestão de Perguntas"
	lbl_sub.add_theme_font_size_override("font_size", 12)
	lbl_sub.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	vbox_titulos.add_child(lbl_sub)
	
	# Botão + Nova Pergunta
	var btn_add = _criar_botao_acao("+ Nova Pergunta", COLOR_FACIL)
	btn_add.pressed.connect(func(): TransitionScreen.change_scene("res://scenes/ui/adicionar_perguntas.tscn"))
	hbox.add_child(btn_add)
	
	# Botão Exportar CSV (Planilha para Pesquisa / Excel)
	var btn_csv = _criar_botao_acao("Exportar Planilha (CSV)", COLOR_FACIL)
	btn_csv.pressed.connect(_exportar_csv)
	hbox.add_child(btn_csv)
	
	# Botão Relatório Formatado (Impressão / PDF)
	var btn_pdf = _criar_botao_acao("Gerar Relatório (PDF)", Color(0.20, 0.75, 0.95))
	btn_pdf.pressed.connect(_exportar_pdf_relatorio)
	hbox.add_child(btn_pdf)
	
	# Botão Atualizar
	var btn_reload = _criar_botao_acao("Atualizar", Color(0.20, 0.65, 0.90))
	btn_reload.pressed.connect(_carregar_dados)
	hbox.add_child(btn_reload)
	
	# Botão Resetar Dados
	var btn_reset = _criar_botao_acao("Resetar Dados", Color(0.85, 0.25, 0.30))
	btn_reset.pressed.connect(_abrir_popup_reset)
	hbox.add_child(btn_reset)
	
	# Botão Voltar ao Jogo
	var btn_voltar = _criar_botao_acao("Voltar ao Jogo", Color(0.45, 0.50, 0.62))
	btn_voltar.pressed.connect(func(): TransitionScreen.change_scene("res://scenes/ui/main_menu.tscn"))
	hbox.add_child(btn_voltar)

func _criar_seletor_disciplinas(parent: Control) -> void:
	var hbox_disc = HBoxContainer.new()
	hbox_disc.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_disc.add_theme_constant_override("separation", 14)
	parent.add_child(hbox_disc)
	
	var lbl_seletor = Label.new()
	lbl_seletor.text = "Disciplina:"
	lbl_seletor.add_theme_font_size_override("font_size", 13)
	lbl_seletor.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	hbox_disc.add_child(lbl_seletor)
	
	btn_disciplinas.clear()
	for i in range(disciplinas.size()):
		var d = disciplinas[i]
		var btn = Button.new()
		btn.text = "%s (Andar %d)" % [d["nome"], d["andar_id"]]
		btn.custom_minimum_size = Vector2(170, 32)
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_on_disciplina_selecionada.bind(i))
		hbox_disc.add_child(btn)
		btn_disciplinas.append(btn)
		
	_atualizar_estilo_botoes_disciplina()

func _atualizar_estilo_botoes_disciplina() -> void:
	for i in range(btn_disciplinas.size()):
		var btn = btn_disciplinas[i]
		var d = disciplinas[i]
		var eh_ativa = (i == disciplina_atual_idx)
		
		var cor_bg = d["cor"] * 0.25 if eh_ativa else Color(0.12, 0.15, 0.22, 0.8)
		var cor_borda = d["cor"] if eh_ativa else COLOR_BORDER_SUBTLE
		var cor_texto = Color.WHITE if eh_ativa else COLOR_TEXT_MUTED
		var borda_w = 2 if eh_ativa else 1
		
		var style = _criar_stylebox(cor_bg, cor_borda, 6, borda_w)
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 6
		style.content_margin_bottom = 6
		
		var style_hover = style.duplicate()
		style_hover.bg_color = cor_bg.lightened(0.15)
		
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style_hover)
		btn.add_theme_stylebox_override("pressed", style)
		btn.add_theme_color_override("font_color", cor_texto)

func _on_disciplina_selecionada(idx: int) -> void:
	if disciplina_atual_idx != idx:
		disciplina_atual_idx = idx
		_atualizar_estilo_botoes_disciplina()
		_carregar_dados()

func _criar_dashboard_cards(parent: Control) -> void:
	var hbox_dash = HBoxContainer.new()
	hbox_dash.add_theme_constant_override("separation", 12)
	parent.add_child(hbox_dash)
	
	var c1 = _criar_card_kpi(hbox_dash, "TOTAL DE QUESTÕES", "...", "Distribuição por nível", Color(0.3, 0.7, 1.0))
	lbl_total_questoes_val = c1["val"]
	lbl_total_questoes_sub = c1["sub"]
	
	var c2 = _criar_card_kpi(hbox_dash, "TAXA GERAL DE ACERTO", "...", "Desempenho dos alunos", COLOR_TAXA)
	lbl_taxa_acerto_val = c2["val"]
	lbl_taxa_acerto_sub = c2["sub"]
	
	var c3 = _criar_card_kpi(hbox_dash, "RESPOSTAS REGISTRADAS", "...", "Acertos vs Erros", COLOR_MEDIO)
	lbl_total_respostas_val = c3["val"]
	lbl_total_respostas_sub = c3["sub"]
	
	var c4 = _criar_card_kpi(hbox_dash, "ALUNOS CADASTRADOS", "...", "Jogadores registrados", Color(0.8, 0.5, 0.95))
	lbl_total_jogadores_val = c4["val"]
	lbl_total_jogadores_sub = c4["sub"]

func _criar_card_kpi(parent: Control, titulo: String, valor: String, subtitulo: String, cor_destaque: Color) -> Dictionary:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style = _criar_stylebox(COLOR_CARD_BG, COLOR_BORDER_SUBTLE, 8, 1)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	panel.add_child(vbox)
	
	var lbl_tit = Label.new()
	lbl_tit.text = titulo
	lbl_tit.add_theme_color_override("font_color", cor_destaque)
	lbl_tit.add_theme_font_size_override("font_size", 11)
	vbox.add_child(lbl_tit)
	
	var lbl_val = Label.new()
	lbl_val.text = valor
	lbl_val.add_theme_font_size_override("font_size", 20)
	lbl_val.add_theme_color_override("font_color", COLOR_TEXT_BRIGHT)
	vbox.add_child(lbl_val)
	
	var lbl_sub = Label.new()
	lbl_sub.text = subtitulo
	lbl_sub.add_theme_font_size_override("font_size", 11)
	lbl_sub.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	vbox.add_child(lbl_sub)
	
	return {"val": lbl_val, "sub": lbl_sub}

func _criar_barra_controles(parent: Control) -> void:
	var panel_bar = PanelContainer.new()
	var style_bar = _criar_stylebox(COLOR_PANEL_BG, COLOR_BORDER_SUBTLE, 8, 1)
	style_bar.content_margin_left = 12
	style_bar.content_margin_right = 12
	style_bar.content_margin_top = 8
	style_bar.content_margin_bottom = 8
	panel_bar.add_theme_stylebox_override("panel", style_bar)
	parent.add_child(panel_bar)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	panel_bar.add_child(hbox)
	
	# Seção de Filtro por Dificuldade (Com badges limpas sem emojis)
	var lbl_filtro = Label.new()
	lbl_filtro.text = "Dificuldade:"
	lbl_filtro.add_theme_font_size_override("font_size", 12)
	lbl_filtro.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	hbox.add_child(lbl_filtro)
	
	btn_filtros.clear()
	var filtros_config = [
		{"id": "todas", "label": "Todas", "cor": Color(0.6, 0.65, 0.75)},
		{"id": "facil", "label": "Fácil (N1)", "cor": COLOR_FACIL},
		{"id": "medio", "label": "Médio (N2)", "cor": COLOR_MEDIO},
		{"id": "dificil", "label": "Difícil (N3)", "cor": COLOR_DIFICIL}
	]
	
	for cfg in filtros_config:
		var btn = Button.new()
		btn.text = cfg["label"]
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(85, 30)
		btn.pressed.connect(_on_filtro_alterado.bind(cfg["id"]))
		hbox.add_child(btn)
		btn_filtros[cfg["id"]] = {"btn": btn, "cor": cfg["cor"]}
		
	_atualizar_estilo_botoes_filtro()
	
	# Espaçador
	var sep = Control.new()
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(sep)
	
	# Seção de Ordenação
	var lbl_ordem = Label.new()
	lbl_ordem.text = "Ordenar:"
	lbl_ordem.add_theme_font_size_override("font_size", 12)
	lbl_ordem.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	hbox.add_child(lbl_ordem)
	
	opt_ordenacao = OptionButton.new()
	opt_ordenacao.custom_minimum_size = Vector2(175, 30)
	opt_ordenacao.add_item("Maior Taxa de Erro", 0)
	opt_ordenacao.add_item("Maior Taxa de Acerto", 1)
	opt_ordenacao.add_item("Nível: Fácil → Difícil", 2)
	opt_ordenacao.add_item("Nível: Difícil → Fácil", 3)
	opt_ordenacao.add_item("Ordem por ID", 4)
	opt_ordenacao.item_selected.connect(_on_ordenacao_alterada)
	hbox.add_child(opt_ordenacao)
	
	# Campo de Pesquisa Rápida
	input_busca = LineEdit.new()
	input_busca.placeholder_text = "Buscar..."
	input_busca.custom_minimum_size = Vector2(150, 30)
	input_busca.text_changed.connect(_on_busca_alterada)
	hbox.add_child(input_busca)

func _atualizar_estilo_botoes_filtro() -> void:
	for f_id in btn_filtros.keys():
		var item = btn_filtros[f_id]
		var btn: Button = item["btn"]
		var cor: Color = item["cor"]
		var ativa = (f_id == filtro_dificuldade_atual)
		
		var cor_bg = cor * 0.25 if ativa else Color(0.14, 0.17, 0.24, 0.7)
		var cor_borda = cor if ativa else COLOR_BORDER_SUBTLE
		var cor_texto = Color.WHITE if ativa else COLOR_TEXT_MUTED
		
		var style = _criar_stylebox(cor_bg, cor_borda, 5, 2 if ativa else 1)
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 4
		style.content_margin_bottom = 4
		
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)
		btn.add_theme_color_override("font_color", cor_texto)

func _on_filtro_alterado(novo_filtro: String) -> void:
	filtro_dificuldade_atual = novo_filtro
	_atualizar_estilo_botoes_filtro()
	_renderizar_lista()

func _on_ordenacao_alterada(idx: int) -> void:
	modo_ordenacao_atual = idx
	_renderizar_lista()

func _on_busca_alterada(novo_texto: String) -> void:
	texto_pesquisa = novo_texto.strip_edges().to_lower()
	_renderizar_lista()

# CARREGAMENTO E PROCESSAMENTO DE DADOS

func _obter_sessao_selecionada_id() -> String:
	if opt_sessao_escola and opt_sessao_escola.selected >= 0 and opt_sessao_escola.selected < sessoes_carregadas.size():
		return str(sessoes_carregadas[opt_sessao_escola.selected].get("id", DatabaseManager.escola_ativa_id))
	return DatabaseManager.escola_ativa_id

func _obter_sessao_selecionada_nome() -> String:
	if opt_sessao_escola and opt_sessao_escola.selected >= 0 and opt_sessao_escola.selected < sessoes_carregadas.size():
		return str(sessoes_carregadas[opt_sessao_escola.selected].get("nome", DatabaseManager.escola_ativa_nome))
	return DatabaseManager.escola_ativa_nome

func _carregar_dados() -> void:
	lbl_total_questoes_val.text = "..."
	lbl_taxa_acerto_val.text = "..."
	lbl_total_respostas_val.text = "..."
	lbl_total_jogadores_val.text = "..."
	
	_mostrar_mensagem_tabela("Carregando perguntas e estatísticas...", COLOR_TEXT_MUTED)
	
	var id_escola = _obter_sessao_selecionada_id()
	
	# 1. Total de jogadores no ranking para a sessão selecionada
	var query_jog = "/rest/v1/rankinggeral?select=player_name"
	if id_escola == "geral":
		query_jog += "&or=(escola_id.eq.geral,escola_id.is.null)"
	elif id_escola != "todas":
		query_jog += "&escola_id=eq." + id_escola.uri_encode()
		
	var res_jogadores = await DatabaseManager.request_async(query_jog, HTTPClient.METHOD_GET)
	if res_jogadores.get("success", false) and res_jogadores.get("data") is Array:
		total_jogadores_count = res_jogadores["data"].size()
		lbl_total_jogadores_val.text = "%d Magos" % total_jogadores_count
		if id_escola == "geral":
			lbl_total_jogadores_sub.text = "Cadastrados (Geral)"
		else:
			lbl_total_jogadores_sub.text = "Cadastrados nesta escola"
	else:
		total_jogadores_count = 0
		lbl_total_jogadores_val.text = "0 Magos"
		lbl_total_jogadores_sub.text = "Nenhum aluno cadastrado"
	
	# 2. Respostas registradas para a disciplina atual e sessão selecionada
	var id_andar = disciplinas[disciplina_atual_idx]["andar_id"]
	var query_resp = "/rest/v1/respostas?select=pergunta_id,acertou&andar_id=eq." + str(id_andar)
	if id_escola == "geral":
		query_resp += "&or=(escola_id.eq.geral,escola_id.is.null)"
	elif id_escola != "todas":
		query_resp += "&escola_id=eq." + id_escola.uri_encode()
		
	var res_resp = await DatabaseManager.request_async(query_resp, HTTPClient.METHOD_GET)
	
	mapa_respostas.clear()
	var soma_acertos_geral: int = 0
	var soma_erros_geral: int = 0
	
	var lista_respostas: Array = []
	if res_resp.get("success", false) and res_resp.get("data") is Array:
		lista_respostas = res_resp["data"]
	else:
		# Fallback local se estiver offline
		var locais = DatabaseManager.obter_respostas_analytics(id_escola)
		for r in locais:
			if int(r.get("andar_id", 1)) == id_andar:
				lista_respostas.append(r)
				
	for r in lista_respostas:
		var p_id = int(r.get("pergunta_id", -1))
		if not mapa_respostas.has(p_id):
			mapa_respostas[p_id] = {"acertos": 0, "erros": 0}
		
		if r.get("acertou", false):
			mapa_respostas[p_id]["acertos"] += 1
			soma_acertos_geral += 1
		else:
			mapa_respostas[p_id]["erros"] += 1
			soma_erros_geral += 1
	
	# 3. Perguntas da disciplina atual
	var query = "/rest/v1/perguntas?select=*&andar_id=eq." + str(id_andar)
	var res_perguntas = await DatabaseManager.request_async(query, HTTPClient.METHOD_GET)
	
	dados_perguntas_brutos = []
	if res_perguntas.get("success", false) and res_perguntas.get("data") is Array and res_perguntas["data"].size() > 0:
		dados_perguntas_brutos = res_perguntas["data"]
	else:
		print("[PainelAdmin] Buscando fallback local para andar %d..." % id_andar)
		dados_perguntas_brutos = DatabaseManager.carregar_perguntas_locais(id_andar)
		
	# 4. Processamento analítico das questões
	lista_questoes_processadas.clear()
	var cont_facil: int = 0
	var cont_medio: int = 0
	var cont_dificil: int = 0
	
	for q in dados_perguntas_brutos:
		var p_id = int(q.get("id", -1))
		var acertos = 0
		var erros = 0
		if mapa_respostas.has(p_id):
			acertos = mapa_respostas[p_id]["acertos"]
			erros = mapa_respostas[p_id]["erros"]
			
		var total_tentativas = acertos + erros
		var taxa_acerto: int = 0
		var taxa_erro: int = 0
		if total_tentativas > 0:
			taxa_acerto = int((float(acertos) / float(total_tentativas)) * 100)
			taxa_erro = 100 - taxa_acerto
			
		# Dificuldade teórica TRI (cadastrada no banco)
		var nivel_tri = int(q.get("nivel_progresso", 1))
		if nivel_tri < 1 or nivel_tri > 3:
			nivel_tri = 1
			
		# Grau de dificuldade prático (baseado em erros e acertos reais)
		var grau_empirico = "Sem Dados"
		var cor_grau = COLOR_TEXT_MUTED
		if total_tentativas > 0:
			if taxa_acerto >= 70:
				grau_empirico = "Fácil"
				cor_grau = COLOR_FACIL
			elif taxa_acerto >= 40:
				grau_empirico = "Médio"
				cor_grau = COLOR_MEDIO
			else:
				grau_empirico = "Difícil"
				cor_grau = COLOR_DIFICIL
		else:
			if nivel_tri == 1:
				grau_empirico = "Fácil"
				cor_grau = COLOR_FACIL
			elif nivel_tri == 2:
				grau_empirico = "Médio"
				cor_grau = COLOR_MEDIO
			else:
				grau_empirico = "Difícil"
				cor_grau = COLOR_DIFICIL
				
		if nivel_tri == 1: cont_facil += 1
		elif nivel_tri == 2: cont_medio += 1
		else: cont_dificil += 1
		
		var opcoes = q.get("options", [])
		var resposta_idx = int(q.get("answer", 0))
		var enunciado = str(q.get("question", "Sem enunciado")).strip_edges()
		var dica = str(q.get("dica", q.get("explicacao", ""))).strip_edges()
		
		lista_questoes_processadas.append({
			"id": p_id,
			"enunciado": enunciado,
			"options": opcoes,
			"answer": resposta_idx,
			"dica": dica,
			"nivel_tri": nivel_tri,
			"grau_empirico": grau_empirico,
			"cor_grau": cor_grau,
			"acertos": acertos,
			"erros": erros,
			"total_tentativas": total_tentativas,
			"taxa_acerto": taxa_acerto,
			"taxa_erro": taxa_erro
		})
	
	# Atualiza os Cards KPI
	lbl_total_questoes_val.text = "%d Questões" % lista_questoes_processadas.size()
	lbl_total_questoes_sub.text = "%d Fáceis  |  %d Médias  |  %d Difíceis" % [cont_facil, cont_medio, cont_dificil]
	
	var total_tentativas_geral = soma_acertos_geral + soma_erros_geral
	if total_tentativas_geral > 0:
		var taxa_geral = int((float(soma_acertos_geral) / float(total_tentativas_geral)) * 100)
		lbl_taxa_acerto_val.text = "%d%% de Acertos" % taxa_geral
		if taxa_geral >= 70:
			lbl_taxa_acerto_sub.text = "Desempenho: Alto Domínio"
		elif taxa_geral >= 40:
			lbl_taxa_acerto_sub.text = "Desempenho: Equilibrado"
		else:
			lbl_taxa_acerto_sub.text = "Desempenho: Alto Desafio"
	else:
		lbl_taxa_acerto_val.text = "Sem Respostas"
		lbl_taxa_acerto_sub.text = "Aguardando tentativas"
		
	lbl_total_respostas_val.text = "%d Respostas" % total_tentativas_geral
	lbl_total_respostas_sub.text = "%d Acertos  |  %d Erros" % [soma_acertos_geral, soma_erros_geral]
	
	_atualizar_rotulos_botoes_filtro(cont_facil, cont_medio, cont_dificil, lista_questoes_processadas.size())
	_renderizar_lista()

func _atualizar_rotulos_botoes_filtro(f: int, m: int, d: int, total: int) -> void:
	if btn_filtros.has("todas"):
		btn_filtros["todas"]["btn"].text = "Todas (%d)" % total
	if btn_filtros.has("facil"):
		btn_filtros["facil"]["btn"].text = "Fácil (%d)" % f
	if btn_filtros.has("medio"):
		btn_filtros["medio"]["btn"].text = "Médio (%d)" % m
	if btn_filtros.has("dificil"):
		btn_filtros["dificil"]["btn"].text = "Difícil (%d)" % d

# RENDERIZAÇÃO DA LISTA DE CARDS DE QUESTÃO

func _renderizar_lista() -> void:
	for child in tabela_dados.get_children():
		child.queue_free()
		
	if lista_questoes_processadas.is_empty():
		_mostrar_mensagem_tabela("Nenhuma questão cadastrada para este andar.", COLOR_TEXT_MUTED)
		return
		
	# 1. Filtra as questões
	var lista_filtrada: Array = []
	for item in lista_questoes_processadas:
		if not texto_pesquisa.is_empty():
			var busca_no_enunciado = item["enunciado"].to_lower().find(texto_pesquisa) != -1
			var busca_no_id = str(item["id"]).find(texto_pesquisa) != -1
			if not (busca_no_enunciado or busca_no_id):
				continue
				
		match filtro_dificuldade_atual:
			"facil":
				if item["nivel_tri"] != 1 and not ("fácil" in item["grau_empirico"].to_lower()):
					continue
			"medio":
				if item["nivel_tri"] != 2 and not ("médio" in item["grau_empirico"].to_lower()):
					continue
			"dificil":
				if item["nivel_tri"] != 3 and not ("difícil" in item["grau_empirico"].to_lower()):
					continue
			"todas":
				pass
				
		lista_filtrada.append(item)
		
	if lista_filtrada.is_empty():
		_mostrar_mensagem_tabela("Nenhuma questão corresponde aos filtros selecionados.", COLOR_TEXT_MUTED)
		return
		
	# 2. Ordenação
	match modo_ordenacao_atual:
		0:
			lista_filtrada.sort_custom(func(a, b):
				if a["taxa_erro"] != b["taxa_erro"]:
					return a["taxa_erro"] > b["taxa_erro"]
				return a["id"] < b["id"]
			)
		1:
			lista_filtrada.sort_custom(func(a, b):
				if a["taxa_acerto"] != b["taxa_acerto"]:
					return a["taxa_acerto"] > b["taxa_acerto"]
				return a["id"] < b["id"]
			)
		2:
			lista_filtrada.sort_custom(func(a, b):
				if a["nivel_tri"] != b["nivel_tri"]:
					return a["nivel_tri"] < b["nivel_tri"]
				return a["taxa_acerto"] > b["taxa_acerto"]
			)
		3:
			lista_filtrada.sort_custom(func(a, b):
				if a["nivel_tri"] != b["nivel_tri"]:
					return a["nivel_tri"] > b["nivel_tri"]
				return a["taxa_erro"] > b["taxa_erro"]
			)
		4:
			lista_filtrada.sort_custom(func(a, b): return a["id"] < b["id"])
			
	# 3. Renderiza cada Card
	for item in lista_filtrada:
		_criar_card_questao(item)

func _criar_card_questao(item: Dictionary) -> void:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var cor_indicador = COLOR_FACIL
	if item["nivel_tri"] == 2: cor_indicador = COLOR_MEDIO
	elif item["nivel_tri"] == 3: cor_indicador = COLOR_DIFICIL
	
	var style = _criar_stylebox(COLOR_CARD_BG, COLOR_BORDER_SUBTLE, 8, 1)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	tabela_dados.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	
	# --- LINHA SUPERIOR DO CARD (Metadados à esquerda, Métricas e Botão à direita) ---
	var hbox_topo = HBoxContainer.new()
	hbox_topo.add_theme_constant_override("separation", 8)
	hbox_topo.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox_topo)
	
	# Badge do ID
	var badge_id = _criar_badge("#%d" % item["id"], Color(0.18, 0.22, 0.32), COLOR_TEXT_BRIGHT)
	hbox_topo.add_child(badge_id)
	
	# Badge do Nível Teórico (TRI)
	var texto_tri = "Nível 1 (Fácil)"
	if item["nivel_tri"] == 2: texto_tri = "Nível 2 (Médio)"
	elif item["nivel_tri"] == 3: texto_tri = "Nível 3 (Difícil)"
	var badge_tri = _criar_badge(texto_tri, cor_indicador * 0.22, cor_indicador)
	hbox_topo.add_child(badge_tri)
	
	# Badge do Grau Empírico
	var badge_grau = _criar_badge("Grau: " + item["grau_empirico"], item["cor_grau"] * 0.22, item["cor_grau"])
	hbox_topo.add_child(badge_grau)
	
	# Alerta Pedagógico de Discrepância TRI
	if item["total_tentativas"] >= 3:
		if item["nivel_tri"] == 1 and item["taxa_erro"] >= 50:
			var badge_aviso = _criar_badge("Alta Taxa de Erro", Color(0.4, 0.1, 0.1), COLOR_DIFICIL)
			hbox_topo.add_child(badge_aviso)
		elif item["nivel_tri"] == 3 and item["taxa_acerto"] >= 85:
			var badge_aviso = _criar_badge("Alto Acerto para Nível 3", Color(0.1, 0.3, 0.4), Color(0.3, 0.8, 1.0))
			hbox_topo.add_child(badge_aviso)
			
	# Espaçador
	var sep = Control.new()
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_topo.add_child(sep)
	
	# Estatísticas de Desempenho (Acertos, Erros, Taxa - padrão de cores fixo)
	var lbl_acertos = Label.new()
	lbl_acertos.text = "Acertos: %d" % item["acertos"]
	lbl_acertos.add_theme_color_override("font_color", COLOR_FACIL) # Sempre Verde
	lbl_acertos.add_theme_font_size_override("font_size", 12)
	hbox_topo.add_child(lbl_acertos)
	
	var lbl_erros = Label.new()
	lbl_erros.text = "Erros: %d" % item["erros"]
	lbl_erros.add_theme_color_override("font_color", COLOR_DIFICIL) # Sempre Vermelho
	lbl_erros.add_theme_font_size_override("font_size", 12)
	hbox_topo.add_child(lbl_erros)
	
	var lbl_taxa = Label.new()
	lbl_taxa.text = "Taxa: %d%%" % item["taxa_acerto"]
	lbl_taxa.add_theme_color_override("font_color", COLOR_TAXA) # Sempre Amarelo
	lbl_taxa.add_theme_font_size_override("font_size", 12)
	hbox_topo.add_child(lbl_taxa)
	
	# Espaço entre stats e botão
	var sep_btn = Control.new()
	sep_btn.custom_minimum_size = Vector2(8, 0)
	hbox_topo.add_child(sep_btn)
	
	# Botão Excluir Questão
	var btn_remover = Button.new()
	btn_remover.text = " Excluir "
	btn_remover.focus_mode = Control.FOCUS_NONE
	btn_remover.custom_minimum_size = Vector2(75, 26)
	
	var style_rem = _criar_stylebox(Color(0.28, 0.12, 0.16, 0.85), Color(0.80, 0.25, 0.30), 5, 1)
	style_rem.content_margin_left = 8
	style_rem.content_margin_right = 8
	style_rem.content_margin_top = 2
	style_rem.content_margin_bottom = 2
	
	var style_rem_hover = style_rem.duplicate()
	style_rem_hover.bg_color = Color(0.65, 0.18, 0.22, 1.0)
	
	btn_remover.add_theme_stylebox_override("normal", style_rem)
	btn_remover.add_theme_stylebox_override("hover", style_rem_hover)
	btn_remover.add_theme_stylebox_override("pressed", style_rem)
	btn_remover.add_theme_color_override("font_color", Color(1.0, 0.9, 0.9))
	btn_remover.add_theme_font_size_override("font_size", 11)
	btn_remover.pressed.connect(_abrir_modal_confirmar_remocao.bind(item))
	hbox_topo.add_child(btn_remover)
	
	# --- ENUNCIADO DA QUESTÃO (Claro, direto e legível) ---
	var lbl_enunciado = Label.new()
	lbl_enunciado.text = item["enunciado"]
	lbl_enunciado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_enunciado.add_theme_font_size_override("font_size", 13)
	lbl_enunciado.add_theme_color_override("font_color", COLOR_TEXT_BRIGHT)
	vbox.add_child(lbl_enunciado)
	
	# --- SEÇÃO DE GABARITO E ALTERNATIVAS (ORGANIZADA & EXPANSÍVEL) ---
	if item["options"] is Array and item["options"].size() > 0:
		var hbox_expansor = HBoxContainer.new()
		vbox.add_child(hbox_expansor)
		
		var btn_ver_opcoes = Button.new()
		btn_ver_opcoes.text = "Ver Alternativas"
		btn_ver_opcoes.focus_mode = Control.FOCUS_NONE
		btn_ver_opcoes.add_theme_font_size_override("font_size", 11)
		btn_ver_opcoes.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
		
		var style_exp = _criar_stylebox(Color(0.14, 0.17, 0.25, 0.5), COLOR_BORDER_SUBTLE, 4, 1)
		style_exp.content_margin_left = 8
		style_exp.content_margin_right = 8
		style_exp.content_margin_top = 2
		style_exp.content_margin_bottom = 2
		btn_ver_opcoes.add_theme_stylebox_override("normal", style_exp)
		btn_ver_opcoes.add_theme_stylebox_override("hover", style_exp)
		hbox_expansor.add_child(btn_ver_opcoes)
		
		# Painel de detalhes (INICIALMENTE OCULTO para manter os cards limpos!)
		var panel_opcoes = PanelContainer.new()
		panel_opcoes.visible = false
		var style_p_opc = _criar_stylebox(Color(0.09, 0.11, 0.17, 0.95), COLOR_BORDER_SUBTLE, 6, 1)
		style_p_opc.content_margin_left = 12
		style_p_opc.content_margin_right = 12
		style_p_opc.content_margin_top = 8
		style_p_opc.content_margin_bottom = 8
		panel_opcoes.add_theme_stylebox_override("panel", style_p_opc)
		vbox.add_child(panel_opcoes)
		
		var vbox_opcoes = VBoxContainer.new()
		vbox_opcoes.add_theme_constant_override("separation", 5)
		panel_opcoes.add_child(vbox_opcoes)
		
		var letras = ["A", "B", "C", "D", "E"]
		for opt_idx in range(item["options"].size()):
			var letra = letras[opt_idx] if opt_idx < letras.size() else str(opt_idx + 1)
			var texto_opcao = str(item["options"][opt_idx])
			var eh_correta = (opt_idx == item["answer"])
			
			var lbl_opt = Label.new()
			lbl_opt.text = "%s) %s %s" % [letra, texto_opcao, "[Resposta Correta]" if eh_correta else ""]
			lbl_opt.add_theme_font_size_override("font_size", 12)
			lbl_opt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			
			if eh_correta:
				lbl_opt.add_theme_color_override("font_color", COLOR_FACIL)
			else:
				lbl_opt.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
				
			vbox_opcoes.add_child(lbl_opt)
			
		if not item["dica"].is_empty():
			var sep_dica = HSeparator.new()
			vbox_opcoes.add_child(sep_dica)
			
			var lbl_dica = Label.new()
			lbl_dica.text = "Dica Pedagógica: " + item["dica"]
			lbl_dica.add_theme_font_size_override("font_size", 11)
			lbl_dica.add_theme_color_override("font_color", Color(0.90, 0.75, 0.35))
			lbl_dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			vbox_opcoes.add_child(lbl_dica)
			
		btn_ver_opcoes.pressed.connect(func():
			panel_opcoes.visible = not panel_opcoes.visible
			btn_ver_opcoes.text = "Ocultar Alternativas" if panel_opcoes.visible else "Ver Alternativas"
		)

func _mostrar_mensagem_tabela(msg: String, cor: Color) -> void:
	for child in tabela_dados.get_children():
		child.queue_free()
		
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = _criar_stylebox(COLOR_CARD_BG, COLOR_BORDER_SUBTLE, 8, 1)
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	panel.add_theme_stylebox_override("panel", style)
	tabela_dados.add_child(panel)
	
	var lbl = Label.new()
	lbl.text = msg
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", cor)
	lbl.add_theme_font_size_override("font_size", 14)
	panel.add_child(lbl)

# MODAL DE REMOÇÃO DE QUESTÃO (COM CONFIRMAÇÃO)

func _abrir_modal_confirmar_remocao(item: Dictionary) -> void:
	if modal_exclusao != null and is_instance_valid(modal_exclusao):
		modal_exclusao.queue_free()
		
	modal_exclusao = ColorRect.new()
	modal_exclusao.color = Color(0, 0, 0, 0.75)
	modal_exclusao.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(modal_exclusao)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 240)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var style_modal = _criar_stylebox(Color(0.12, 0.15, 0.22, 1.0), Color(0.70, 0.25, 0.30), 10, 2)
	style_modal.content_margin_left = 24
	style_modal.content_margin_right = 24
	style_modal.content_margin_top = 20
	style_modal.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style_modal)
	modal_exclusao.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)
	
	var lbl_tit = Label.new()
	lbl_tit.text = "Confirmar Exclusão de Questão"
	lbl_tit.add_theme_font_size_override("font_size", 18)
	lbl_tit.add_theme_color_override("font_color", COLOR_DIFICIL)
	vbox.add_child(lbl_tit)
	
	var lbl_aviso = Label.new()
	lbl_aviso.text = "Tem certeza que deseja remover esta questão permanentemente do jogo?\nIsso apagará o histórico de acertos e erros desta pergunta no servidor."
	lbl_aviso.add_theme_font_size_override("font_size", 12)
	lbl_aviso.add_theme_color_override("font_color", COLOR_TEXT_BRIGHT)
	lbl_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lbl_aviso)
	
	var panel_resumo = PanelContainer.new()
	var style_resumo = _criar_stylebox(Color(0.08, 0.10, 0.15, 1.0), COLOR_BORDER_SUBTLE, 6, 1)
	style_resumo.content_margin_left = 12
	style_resumo.content_margin_right = 12
	style_resumo.content_margin_top = 8
	style_resumo.content_margin_bottom = 8
	panel_resumo.add_theme_stylebox_override("panel", style_resumo)
	vbox.add_child(panel_resumo)
	
	var lbl_resumo = Label.new()
	lbl_resumo.text = "Questão #%d • Nível %d (%s)\n\"%s\"" % [
		item["id"],
		item["nivel_tri"],
		disciplinas[disciplina_atual_idx]["nome"],
		item["enunciado"].substr(0, 90) + ("..." if item["enunciado"].length() > 90 else "")
	]
	lbl_resumo.add_theme_font_size_override("font_size", 12)
	lbl_resumo.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	lbl_resumo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_resumo.add_child(lbl_resumo)
	
	var lbl_status_modal = Label.new()
	lbl_status_modal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_status_modal.add_theme_font_size_override("font_size", 12)
	vbox.add_child(lbl_status_modal)
	
	var hbox_btns = HBoxContainer.new()
	hbox_btns.alignment = BoxContainer.ALIGNMENT_END
	hbox_btns.add_theme_constant_override("separation", 12)
	vbox.add_child(hbox_btns)
	
	var btn_cancelar = Button.new()
	btn_cancelar.text = "Cancelar"
	btn_cancelar.custom_minimum_size = Vector2(90, 32)
	btn_cancelar.pressed.connect(func(): modal_exclusao.queue_free())
	hbox_btns.add_child(btn_cancelar)
	
	var btn_confirmar = Button.new()
	btn_confirmar.text = "Sim, Excluir"
	btn_confirmar.custom_minimum_size = Vector2(130, 32)
	var style_conf = _criar_stylebox(Color(0.75, 0.20, 0.25), Color(0.9, 0.3, 0.35), 6, 1)
	btn_confirmar.add_theme_stylebox_override("normal", style_conf)
	btn_confirmar.add_theme_stylebox_override("hover", style_conf)
	btn_confirmar.add_theme_color_override("font_color", Color.WHITE)
	btn_confirmar.pressed.connect(_executar_remocao_questao.bind(item, lbl_status_modal, btn_confirmar, btn_cancelar))
	hbox_btns.add_child(btn_confirmar)

func _executar_remocao_questao(item: Dictionary, lbl_status: Label, btn_conf: Button, btn_canc: Button) -> void:
	btn_conf.disabled = true
	btn_canc.disabled = true
	lbl_status.text = "Excluindo questão..."
	lbl_status.add_theme_color_override("font_color", COLOR_MEDIO)
	
	var res = await DatabaseManager.remover_pergunta(item["id"])
	
	if res.get("success", false) or res.get("code", 0) == 200 or res.get("code", 0) == 204:
		_exibir_toast("Questão #%d excluída com sucesso." % item["id"])
	else:
		_exibir_toast("Removida localmente. Verifique conexão.")
		
	for i in range(lista_questoes_processadas.size() - 1, -1, -1):
		if lista_questoes_processadas[i]["id"] == item["id"]:
			lista_questoes_processadas.remove_at(i)
			break
			
	if modal_exclusao != null and is_instance_valid(modal_exclusao):
		modal_exclusao.queue_free()
		
	_recalcular_metricas_apos_remocao()
	_renderizar_lista()

func _recalcular_metricas_apos_remocao() -> void:
	var cont_facil = 0
	var cont_medio = 0
	var cont_dificil = 0
	var soma_acertos = 0
	var soma_erros = 0
	for q in lista_questoes_processadas:
		if q["nivel_tri"] == 1: cont_facil += 1
		elif q["nivel_tri"] == 2: cont_medio += 1
		else: cont_dificil += 1
		soma_acertos += q["acertos"]
		soma_erros += q["erros"]
		
	lbl_total_questoes_val.text = "%d Questões" % lista_questoes_processadas.size()
	lbl_total_questoes_sub.text = "%d Fáceis  |  %d Médias  |  %d Difíceis" % [cont_facil, cont_medio, cont_dificil]
	
	var total_tentativas = soma_acertos + soma_erros
	if total_tentativas > 0:
		var taxa = int((float(soma_acertos) / float(total_tentativas)) * 100)
		lbl_taxa_acerto_val.text = "%d%% de Acertos" % taxa
		if taxa >= 70:
			lbl_taxa_acerto_sub.text = "Desempenho: Alto Domínio"
		elif taxa >= 40:
			lbl_taxa_acerto_sub.text = "Desempenho: Equilibrado"
		else:
			lbl_taxa_acerto_sub.text = "Desempenho: Alto Desafio"
	else:
		lbl_taxa_acerto_val.text = "Sem Respostas"
		lbl_taxa_acerto_sub.text = "Aguardando tentativas"
		
	lbl_total_respostas_val.text = "%d Respostas" % total_tentativas
	lbl_total_respostas_sub.text = "%d Acertos  |  %d Erros" % [soma_acertos, soma_erros]
	_atualizar_rotulos_botoes_filtro(cont_facil, cont_medio, cont_dificil, lista_questoes_processadas.size())

# MODAL DE RESET GERAL DO JOGO (COM SENHA)

func _abrir_popup_reset() -> void:
	if popup_reset != null and is_instance_valid(popup_reset):
		popup_reset.queue_free()
		
	popup_reset = ColorRect.new()
	popup_reset.color = Color(0, 0, 0, 0.85)
	popup_reset.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(popup_reset)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(440, 220)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var style_reset = _criar_stylebox(Color(0.12, 0.14, 0.20, 1.0), Color(0.85, 0.25, 0.30), 10, 2)
	style_reset.content_margin_left = 22
	style_reset.content_margin_right = 22
	style_reset.content_margin_top = 18
	style_reset.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", style_reset)
	popup_reset.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)
	
	var lbl = Label.new()
	lbl.text = "ATENÇÃO: Reset Geral de Dados\nEsta ação apagará todos os jogadores, clãs, histórico e rankings.\nDigite a senha de administrador para prosseguir:"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", COLOR_DIFICIL)
	lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(lbl)
	
	line_edit_senha = LineEdit.new()
	line_edit_senha.secret = true
	line_edit_senha.placeholder_text = "Senha administrativa..."
	line_edit_senha.custom_minimum_size = Vector2(280, 34)
	vbox.add_child(line_edit_senha)
	
	var hbox_btns = HBoxContainer.new()
	hbox_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_btns.add_theme_constant_override("separation", 14)
	vbox.add_child(hbox_btns)
	
	var btn_cancelar = Button.new()
	btn_cancelar.text = "Cancelar"
	btn_cancelar.custom_minimum_size = Vector2(90, 32)
	btn_cancelar.pressed.connect(func(): popup_reset.queue_free())
	hbox_btns.add_child(btn_cancelar)
	
	var btn_confirmar = Button.new()
	btn_confirmar.text = "Confirmar Reset"
	btn_confirmar.custom_minimum_size = Vector2(140, 32)
	var style_wipe = _criar_stylebox(Color(0.80, 0.20, 0.25), Color(1.0, 0.3, 0.35), 6, 1)
	btn_confirmar.add_theme_stylebox_override("normal", style_wipe)
	btn_confirmar.add_theme_color_override("font_color", Color.WHITE)
	btn_confirmar.pressed.connect(_confirmar_reset)
	hbox_btns.add_child(btn_confirmar)

func _confirmar_reset() -> void:
	if line_edit_senha.text == "2026Vortex@ufc":
		print("[PainelAdmin] Iniciando wipe geral do servidor...")
		for child in line_edit_senha.get_parent().get_children():
			if child is HBoxContainer or child is LineEdit:
				child.visible = false
			elif child is Label:
				child.text = "Limpando banco de dados e caches locais, aguarde..."
				child.add_theme_color_override("font_color", COLOR_MEDIO)
				
		await DatabaseManager.request_async("/rest/v1/MembrosCla?player_name=not.is.null", HTTPClient.METHOD_DELETE)
		await DatabaseManager.request_async("/rest/v1/Clas?nome=not.is.null", HTTPClient.METHOD_DELETE)
		await DatabaseManager.request_async("/rest/v1/rankinggeral?player_name=not.is.null", HTTPClient.METHOD_DELETE)
		await DatabaseManager.request_async("/rest/v1/respostas?pergunta_id=not.is.null", HTTPClient.METHOD_DELETE)
		
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove("ranking.json")
			dir.remove("pending_sync.json")
			dir.remove("guest_config.json")
			dir.remove("progresso.json")
			
		RankingManager.ranking_geral.clear()
		RankingManager.ranking_diario.clear()
		RankingManager.ranking_semanal.clear()
		RankingManager.ranking_mensal.clear()
		RankingManager.ranking_atualizado.emit()
		
		ClanManager.clans_list.clear()
		ClanManager.clan_list_updated.emit()
		
		_exibir_toast("Reset completo concluído com sucesso.")
		popup_reset.queue_free()
		_carregar_dados()
	else:
		line_edit_senha.text = ""
		line_edit_senha.placeholder_text = "Senha incorreta! Acesso negado."

# notificacao flutuante

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

# funcoes auxiliares de estilo

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

func _criar_botao_acao(texto: String, cor: Color) -> Button:
	var btn = Button.new()
	btn.text = " " + texto + " "
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 32)
	
	var style = _criar_stylebox(cor * 0.22, cor, 6, 1)
	style.content_margin_left = 10
	style.content_margin_right = 10
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

# --- GESTÃO DE SESSÕES / ESCOLAS (AVALIAÇÃO PEDAGÓGICA) ---

func _criar_barra_sessao_escola(parent: Control) -> void:
	var panel_sessao = PanelContainer.new()
	var style_sessao = _criar_stylebox(COLOR_PANEL_BG, COLOR_BORDER_SUBTLE, 8, 1)
	style_sessao.content_margin_left = 14
	style_sessao.content_margin_right = 14
	style_sessao.content_margin_top = 8
	style_sessao.content_margin_bottom = 8
	panel_sessao.add_theme_stylebox_override("panel", style_sessao)
	parent.add_child(panel_sessao)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	panel_sessao.add_child(hbox)
	
	var lbl_ico = Label.new()
	lbl_ico.text = "Sessão / Escola:"
	lbl_ico.add_theme_font_size_override("font_size", 13)
	lbl_ico.add_theme_color_override("font_color", COLOR_TEXT_BRIGHT)
	hbox.add_child(lbl_ico)
	
	opt_sessao_escola = OptionButton.new()
	opt_sessao_escola.custom_minimum_size = Vector2(260, 32)
	opt_sessao_escola.add_theme_font_size_override("font_size", 13)
	_recarregar_opcoes_sessoes()
	_recarregar_opcoes_sessoes_async()
	opt_sessao_escola.item_selected.connect(_on_sessao_selecionada)
	DatabaseManager.sessao_escola_alterada.connect(func(_id, _nome):
		_recarregar_opcoes_sessoes()
	)
	hbox.add_child(opt_sessao_escola)
	
	lbl_sessao_status = Label.new()
	_atualizar_label_sessao_status()
	lbl_sessao_status.add_theme_font_size_override("font_size", 12)
	hbox.add_child(lbl_sessao_status)
	
	var sep = Control.new()
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(sep)
	
	btn_ativar_sessao = _criar_botao_acao("Ativar Esta Sessão", COLOR_MEDIO)
	btn_ativar_sessao.pressed.connect(_on_btn_ativar_sessao_pressed)
	hbox.add_child(btn_ativar_sessao)
	
	var btn_nova = _criar_botao_acao("+ Nova Escola / Turma", COLOR_BORDER_ACCENT)
	btn_nova.pressed.connect(_abrir_popup_nova_sessao)
	hbox.add_child(btn_nova)

func _recarregar_opcoes_sessoes() -> void:
	if not opt_sessao_escola: return
	opt_sessao_escola.clear()
	sessoes_carregadas = DatabaseManager.carregar_sessoes_escolas()
	var selected_idx = 0
	for i in range(sessoes_carregadas.size()):
		var s = sessoes_carregadas[i]
		var id_s = s.get("id", "geral")
		var nome_s = s.get("nome", "Geral")
		var display_text = nome_s
		if id_s == DatabaseManager.escola_ativa_id:
			display_text += " [ATIVA]"
			selected_idx = i
		opt_sessao_escola.add_item(display_text, i)
	opt_sessao_escola.selected = selected_idx
	_atualizar_label_sessao_status()

func _recarregar_opcoes_sessoes_async() -> void:
	if not opt_sessao_escola: return
	sessoes_carregadas = await DatabaseManager.carregar_sessoes_escolas_async()
	opt_sessao_escola.clear()
	var selected_idx = 0
	for i in range(sessoes_carregadas.size()):
		var s = sessoes_carregadas[i]
		var id_s = s.get("id", "geral")
		var nome_s = s.get("nome", "Geral")
		var display_text = nome_s
		if id_s == DatabaseManager.escola_ativa_id:
			display_text += " [ATIVA]"
			selected_idx = i
		opt_sessao_escola.add_item(display_text, i)
	opt_sessao_escola.selected = selected_idx
	_atualizar_label_sessao_status()

func _atualizar_label_sessao_status() -> void:
	if not lbl_sessao_status: return
	lbl_sessao_status.text = "Ativa no Jogo: %s" % DatabaseManager.escola_ativa_nome
	lbl_sessao_status.add_theme_color_override("font_color", COLOR_FACIL)

func _on_sessao_selecionada(idx: int) -> void:
	if idx >= 0 and idx < sessoes_carregadas.size():
		var s = sessoes_carregadas[idx]
		var id_s = s.get("id", "geral")
		var nome_s = s.get("nome", "Geral")
		if id_s != DatabaseManager.escola_ativa_id:
			if btn_ativar_sessao:
				btn_ativar_sessao.text = "Ativar '%s'" % nome_s.substr(0, 18)
		else:
			if btn_ativar_sessao:
				btn_ativar_sessao.text = "Ativar Esta Sessão"
		_carregar_dados()

func _on_btn_ativar_sessao_pressed() -> void:
	var idx = opt_sessao_escola.selected if opt_sessao_escola else 0
	if idx >= 0 and idx < sessoes_carregadas.size():
		var s = sessoes_carregadas[idx]
		var id_s = s.get("id", "geral")
		var nome_s = s.get("nome", "Geral")
		_abrir_popup_ativar_sessao(id_s, nome_s)

func _abrir_popup_ativar_sessao(id_alvo: String, nome_alvo: String) -> void:
	if popup_ativar_sessao and is_instance_valid(popup_ativar_sessao):
		popup_ativar_sessao.queue_free()
		
	popup_ativar_sessao = Control.new()
	popup_ativar_sessao.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(popup_ativar_sessao)
	
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.78)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_ativar_sessao.add_child(overlay)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_ativar_sessao.add_child(center)
	
	var panel = PanelContainer.new()
	var style = _criar_stylebox(COLOR_HEADER_BG, COLOR_MEDIO, 12, 2)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(500, 0)
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)
	
	var lbl_tit = Label.new()
	lbl_tit.text = "Ativar Sessão: %s" % nome_alvo
	lbl_tit.add_theme_font_size_override("font_size", 18)
	lbl_tit.add_theme_color_override("font_color", COLOR_MEDIO)
	vbox.add_child(lbl_tit)
	
	var lbl_msg = Label.new()
	lbl_msg.text = "Ao ativar esta sessão:\n• O jogo propagará esta escola como ativa no banco de dados.\n• Todos os jogadores e celulares conectados na Web carregarão os rankings e respostas desta escola.\n\nImportante: Os dados das outras escolas permanecem seguros e guardados no histórico.\n\nDeseja ativar esta sessão e recarregar os dados agora?"
	lbl_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_msg.add_theme_font_size_override("font_size", 13)
	lbl_msg.add_theme_color_override("font_color", COLOR_TEXT_BRIGHT)
	vbox.add_child(lbl_msg)
	
	var hbox_btn = HBoxContainer.new()
	hbox_btn.alignment = BoxContainer.ALIGNMENT_END
	hbox_btn.add_theme_constant_override("separation", 12)
	vbox.add_child(hbox_btn)
	
	var btn_canc = _criar_botao_acao("Cancelar", Color(0.45, 0.50, 0.62))
	btn_canc.pressed.connect(func(): popup_ativar_sessao.queue_free())
	hbox_btn.add_child(btn_canc)
	
	var btn_conf = _criar_botao_acao("Confirmar e Ativar", COLOR_FACIL)
	btn_conf.pressed.connect(func():
		btn_conf.disabled = true
		btn_conf.text = "Ativando no banco de dados..."
		await DatabaseManager.definir_sessao_ativa_async(id_alvo, nome_alvo)
		popup_ativar_sessao.queue_free()
		_recarregar_opcoes_sessoes()
		_carregar_dados()
		_exibir_toast("Sessão '%s' ativada com sucesso!" % nome_alvo)
	)
	hbox_btn.add_child(btn_conf)

func _abrir_popup_nova_sessao() -> void:
	if popup_nova_sessao and is_instance_valid(popup_nova_sessao):
		popup_nova_sessao.queue_free()
		
	popup_nova_sessao = Control.new()
	popup_nova_sessao.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(popup_nova_sessao)
	
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.78)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_nova_sessao.add_child(overlay)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_nova_sessao.add_child(center)
	
	var panel = PanelContainer.new()
	var style = _criar_stylebox(COLOR_HEADER_BG, COLOR_BORDER_ACCENT, 12, 2)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(440, 0)
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)
	
	var lbl_tit = Label.new()
	lbl_tit.text = "+ Cadastrar Nova Escola / Turma"
	lbl_tit.add_theme_font_size_override("font_size", 18)
	lbl_tit.add_theme_color_override("font_color", COLOR_BORDER_ACCENT)
	vbox.add_child(lbl_tit)
	
	var lbl_info = Label.new()
	lbl_info.text = "Digite o nome da escola ou turma que vai jogar o Synthesis:"
	lbl_info.add_theme_font_size_override("font_size", 13)
	lbl_info.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	vbox.add_child(lbl_info)
	
	var input_nome = LineEdit.new()
	input_nome.placeholder_text = "Ex: EEFM Paulo Freire (1º Ano A)"
	input_nome.custom_minimum_size = Vector2(0, 36)
	input_nome.add_theme_font_size_override("font_size", 14)
	vbox.add_child(input_nome)
	
	var input_codigo = LineEdit.new()
	input_codigo.placeholder_text = "Código/ID (Opcional, ex: paulo_freire_1a)"
	input_codigo.custom_minimum_size = Vector2(0, 32)
	input_codigo.add_theme_font_size_override("font_size", 12)
	vbox.add_child(input_codigo)
	
	var hbox_btn = HBoxContainer.new()
	hbox_btn.alignment = BoxContainer.ALIGNMENT_END
	hbox_btn.add_theme_constant_override("separation", 12)
	vbox.add_child(hbox_btn)
	
	var btn_canc = _criar_botao_acao("Cancelar", Color(0.45, 0.50, 0.62))
	btn_canc.pressed.connect(func(): popup_nova_sessao.queue_free())
	hbox_btn.add_child(btn_canc)
	
	var btn_salvar = _criar_botao_acao("Criar e Ativar", COLOR_FACIL)
	btn_salvar.pressed.connect(func():
		var n = input_nome.text.strip_edges()
		if n.is_empty():
			input_nome.placeholder_text = "O nome não pode estar vazio!"
			return
		var c = input_codigo.text.strip_edges()
		btn_salvar.disabled = true
		btn_salvar.text = "Salvando no banco de dados..."
		var criada = await DatabaseManager.adicionar_sessao_escola_async(n, c)
		await DatabaseManager.definir_sessao_ativa_async(criada["id"], criada["nome"])
		popup_nova_sessao.queue_free()
		await _recarregar_opcoes_sessoes_async()
		_carregar_dados()
		_exibir_toast("Nova sessão '%s' criada e ativada com sucesso!" % criada["nome"])
	)
	hbox_btn.add_child(btn_salvar)

# --- COLETA E ANÁLISE COMPLETA DAS 150 QUESTÕES E RESPOSTAS ---

func _coletar_dados_completos_150() -> Dictionary:
	var escola_id = _obter_sessao_selecionada_id()
	var escola_nome = _obter_sessao_selecionada_nome()
	
	# 1. Carrega todas as 150 perguntas e cria mapa por ID
	var todas_questoes: Array = DatabaseManager.carregar_perguntas_locais(0)
	todas_questoes.sort_custom(func(a, b):
		var a_andar = int(a.get("andar_id", 1))
		var b_andar = int(b.get("andar_id", 1))
		if a_andar != b_andar:
			return a_andar < b_andar
		return int(a.get("id", 0)) < int(b.get("id", 0))
	)
	var mapa_questoes_por_id = {}
	for q in todas_questoes:
		mapa_questoes_por_id[int(q.get("id", 0))] = q
	
	# 2. Busca lista de todos os alunos/jogadores cadastrados no ranking desta sessão
	var lista_jogadores_cadastrados = []
	var query_jog = "/rest/v1/rankinggeral?select=*&order=score.desc"
	if escola_id == "geral":
		query_jog += "&or=(escola_id.eq.geral,escola_id.is.null)"
	elif escola_id != "todas":
		query_jog += "&escola_id=eq." + escola_id.uri_encode()
		
	var res_jog = await DatabaseManager.request_async(query_jog, HTTPClient.METHOD_GET)
	if res_jog.get("success", false) and res_jog.get("data") is Array and res_jog["data"].size() > 0:
		lista_jogadores_cadastrados = res_jog["data"]
	else:
		for rk in RankingManager.ranking_geral:
			lista_jogadores_cadastrados.append({
				"player_name": rk.get("name", "Mago"),
				"score": rk.get("score", 0),
				"cla": rk.get("cla", "-")
			})
			
	# 3. Respostas analíticas registradas localmente para esta escola
	var respostas_sessao: Array = DatabaseManager.obter_respostas_analytics(escola_id)
	
	# Se Supabase estiver conectado, tenta mesclar respostas adicionais sem duplicatas
	var query_supa = "/rest/v1/respostas?select=*"
	if escola_id == "geral":
		query_supa += "&or=(escola_id.eq.geral,escola_id.is.null)"
	elif escola_id != "todas":
		query_supa += "&escola_id=eq." + escola_id.uri_encode()
	var res_supa = await DatabaseManager.request_async(query_supa, HTTPClient.METHOD_GET)
	if res_supa.get("success", false) and res_supa.get("data") is Array:
		var chaves_existentes = {}
		for r in respostas_sessao:
			var k = str(r.get("pergunta_id", "")) + "_" + str(r.get("aluno_nick", "")) + "_" + str(r.get("timestamp", ""))
			chaves_existentes[k] = true
		for s_resp in res_supa["data"]:
			var ts = str(s_resp.get("timestamp", s_resp.get("created_at", "")))
			var k = str(s_resp.get("pergunta_id", "")) + "_" + str(s_resp.get("aluno_nick", "")) + "_" + ts
			if not chaves_existentes.has(k):
				respostas_sessao.append(s_resp)
				
	# 4. Inicializa o mapa consolidado de cada aluno (para a tabela individual de estudantes)
	var mapa_alunos = {}
	for j in lista_jogadores_cadastrados:
		var nick = str(j.get("player_name", j.get("name", ""))).strip_edges()
		if not nick.is_empty():
			mapa_alunos[nick] = {
				"nick": nick,
				"cla": str(j.get("cla", "-")),
				"score": int(j.get("score", 0)),
				"questoes_respondidas": 0,
				"acertos": 0,
				"erros": 0,
				"taxa": 0,
				"tempo_total": 0.0,
				"tempo_count": 0,
				"tempo_medio": 0.0,
				"grimorio_total": 0
			}
				
	# 5. Mapa de Estatísticas por Pergunta (1 a 150)
	var mapa_stats = {}
	for q in todas_questoes:
		var pid = int(q.get("id", 0))
		mapa_stats[pid] = {
			"acertos": 0,
			"erros": 0,
			"tempo_total": 0.0,
			"tempo_count": 0,
			"grimorio_total": 0
		}
		
	# 6. Agrega respostas por questão, por aluno e estatísticas globais
	var soma_acertos_global = 0
	var soma_erros_global = 0
	var tempo_total_global = 0.0
	var tempo_count_global = 0
	var grimorio_total_global = 0
	
	for r in respostas_sessao:
		var pid = int(r.get("pergunta_id", -1))
		var acertou = bool(r.get("acertou", false))
		var t_resp = float(r.get("tempo_resposta", 0.0))
		var c_grim = int(r.get("consultas_grimorio", 0))
		var nick = str(r.get("aluno_nick", "Mago")).strip_edges()
		
		# Agregação por Aluno
		if not mapa_alunos.has(nick):
			mapa_alunos[nick] = {
				"nick": nick,
				"cla": str(r.get("cla_aluno", "-")),
				"score": 0,
				"questoes_respondidas": 0,
				"acertos": 0,
				"erros": 0,
				"taxa": 0,
				"tempo_total": 0.0,
				"tempo_count": 0,
				"tempo_medio": 0.0,
				"grimorio_total": 0
			}
			
		var al = mapa_alunos[nick]
		al["questoes_respondidas"] += 1
		if acertou: al["acertos"] += 1
		else: al["erros"] += 1
		if t_resp > 0.0:
			al["tempo_total"] += t_resp
			al["tempo_count"] += 1
		al["grimorio_total"] += c_grim
		if (al["cla"] == "-" or al["cla"].is_empty()) and r.has("cla_aluno") and not str(r["cla_aluno"]).is_empty():
			al["cla"] = str(r["cla_aluno"])
			
		# Agregação Global
		if acertou:
			soma_acertos_global += 1
		else:
			soma_erros_global += 1
			
		if t_resp > 0.0:
			tempo_total_global += t_resp
			tempo_count_global += 1
			
		grimorio_total_global += c_grim
		
		# Agregação por Pergunta
		if mapa_stats.has(pid):
			if acertou:
				mapa_stats[pid]["acertos"] += 1
			else:
				mapa_stats[pid]["erros"] += 1
			if t_resp > 0.0:
				mapa_stats[pid]["tempo_total"] += t_resp
				mapa_stats[pid]["tempo_count"] += 1
			mapa_stats[pid]["grimorio_total"] += c_grim

	# Finaliza taxas dos alunos
	for nick in mapa_alunos.keys():
		var al = mapa_alunos[nick]
		if al["questoes_respondidas"] > 0:
			al["taxa"] = int((float(al["acertos"]) / float(al["questoes_respondidas"])) * 100)
		if al["tempo_count"] > 0:
			al["tempo_medio"] = snappedf(al["tempo_total"] / float(al["tempo_count"]), 0.1)

	var total_resp_global = soma_acertos_global + soma_erros_global
	var taxa_geral_global = 0
	if total_resp_global > 0:
		taxa_geral_global = int((float(soma_acertos_global) / float(total_resp_global)) * 100)
	var tempo_medio_global = 0.0
	if tempo_count_global > 0:
		tempo_medio_global = snappedf(tempo_total_global / float(tempo_count_global), 0.1)

	# 7. Estruturação por Disciplina (1: Química, 2: Física, 3: Biologia)
	var stats_disciplinas = {
		1: {"nome": "Química", "andar": 1, "questoes": 0, "faceis": 0, "medias": 0, "dificeis": 0, "respostas": 0, "acertos": 0, "erros": 0, "taxa": 0, "tempo_total": 0.0, "tempo_count": 0, "tempo_medio": 0.0, "grimorio": 0},
		2: {"nome": "Física", "andar": 2, "questoes": 0, "faceis": 0, "medias": 0, "dificeis": 0, "respostas": 0, "acertos": 0, "erros": 0, "taxa": 0, "tempo_total": 0.0, "tempo_count": 0, "tempo_medio": 0.0, "grimorio": 0},
		3: {"nome": "Biologia", "andar": 3, "questoes": 0, "faceis": 0, "medias": 0, "dificeis": 0, "respostas": 0, "acertos": 0, "erros": 0, "taxa": 0, "tempo_total": 0.0, "tempo_count": 0, "tempo_medio": 0.0, "grimorio": 0}
	}
	
	# 8. Estruturação por Dificuldade Teórica TRI (1: Fácil, 2: Médio, 3: Difícil)
	var stats_dificuldades = {
		1: {"nome": "Fácil", "nivel": 1, "questoes": 0, "respostas": 0, "acertos": 0, "erros": 0, "taxa": 0, "tempo_total": 0.0, "tempo_count": 0, "tempo_medio": 0.0},
		2: {"nome": "Médio", "nivel": 2, "questoes": 0, "respostas": 0, "acertos": 0, "erros": 0, "taxa": 0, "tempo_total": 0.0, "tempo_count": 0, "tempo_medio": 0.0},
		3: {"nome": "Difícil", "nivel": 3, "questoes": 0, "respostas": 0, "acertos": 0, "erros": 0, "taxa": 0, "tempo_total": 0.0, "tempo_count": 0, "tempo_medio": 0.0}
	}
	
	for q in todas_questoes:
		var a_id = int(q.get("andar_id", 1))
		var n_tri = int(q.get("nivel_progresso", 1))
		var pid = int(q.get("id", 0))
		var s = mapa_stats[pid]
		
		if stats_disciplinas.has(a_id):
			stats_disciplinas[a_id]["questoes"] += 1
			if n_tri == 1: stats_disciplinas[a_id]["faceis"] += 1
			elif n_tri == 2: stats_disciplinas[a_id]["medias"] += 1
			elif n_tri == 3: stats_disciplinas[a_id]["dificeis"] += 1
			
			stats_disciplinas[a_id]["acertos"] += s["acertos"]
			stats_disciplinas[a_id]["erros"] += s["erros"]
			stats_disciplinas[a_id]["tempo_total"] += s["tempo_total"]
			stats_disciplinas[a_id]["tempo_count"] += s["tempo_count"]
			stats_disciplinas[a_id]["grimorio"] += s["grimorio_total"]
			
		if stats_dificuldades.has(n_tri):
			stats_dificuldades[n_tri]["questoes"] += 1
			stats_dificuldades[n_tri]["acertos"] += s["acertos"]
			stats_dificuldades[n_tri]["erros"] += s["erros"]
			stats_dificuldades[n_tri]["tempo_total"] += s["tempo_total"]
			stats_dificuldades[n_tri]["tempo_count"] += s["tempo_count"]

	for a_id in stats_disciplinas.keys():
		var sd = stats_disciplinas[a_id]
		sd["respostas"] = sd["acertos"] + sd["erros"]
		if sd["respostas"] > 0:
			sd["taxa"] = int((float(sd["acertos"]) / float(sd["respostas"])) * 100)
		if sd["tempo_count"] > 0:
			sd["tempo_medio"] = snappedf(sd["tempo_total"] / float(sd["tempo_count"]), 0.1)

	for n_tri in stats_dificuldades.keys():
		var sdf = stats_dificuldades[n_tri]
		sdf["respostas"] = sdf["acertos"] + sdf["erros"]
		if sdf["respostas"] > 0:
			sdf["taxa"] = int((float(sdf["acertos"]) / float(sdf["respostas"])) * 100)
		if sdf["tempo_count"] > 0:
			sdf["tempo_medio"] = snappedf(sdf["tempo_total"] / float(sdf["tempo_count"]), 0.1)

	return {
		"escola_id": escola_id,
		"escola_nome": escola_nome,
		"todas_questoes": todas_questoes,
		"mapa_questoes_por_id": mapa_questoes_por_id,
		"respostas_sessao": respostas_sessao,
		"mapa_alunos": mapa_alunos,
		"mapa_stats": mapa_stats,
		"totais_globais": {
			"total_questoes": todas_questoes.size(),
			"total_respostas": total_resp_global,
			"total_acertos": soma_acertos_global,
			"total_erros": soma_erros_global,
			"taxa_geral": taxa_geral_global,
			"tempo_medio": tempo_medio_global,
			"total_grimorio": grimorio_total_global,
			"total_alunos": mapa_alunos.size()
		},
		"stats_disciplinas": stats_disciplinas,
		"stats_dificuldades": stats_dificuldades
	}

# --- EXPORTAÇÃO DE PLANILHAS (CSV PARA EXCEL / GESTÃO ESCOLAR) ---

func _exportar_csv() -> void:
	var dir_relatorios = "user://relatorios"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_relatorios))
	
	var dados = await _coletar_dados_completos_150()
	var escola_id = dados["escola_id"]
	var escola_nome = dados["escola_nome"]
	var dt = Time.get_datetime_dict_from_system()
	var timestamp_str = "%04d%02d%02d_%02d%02d" % [dt.year, dt.month, dt.day, dt.hour, dt.minute]
	var mapa_q = dados["mapa_questoes_por_id"]
	
	# ARQUIVO 1: Microdados / Respostas Individuais dos Alunos
	var fn_alunos = "synthesis_respostas_alunos_%s_%s.csv" % [escola_id, timestamp_str]
	var path_alunos = dir_relatorios + "/" + fn_alunos
	var f_alunos = FileAccess.open(path_alunos, FileAccess.WRITE)
	if f_alunos:
		f_alunos.store_8(0xEF); f_alunos.store_8(0xBB); f_alunos.store_8(0xBF)
		f_alunos.store_line("Sessao_Escola;Data_Hora;Aluno;Cla;Disciplina;Andar;ID_Pergunta;Nivel_Dificuldade;Alternativa_Marcada;Alternativa_Correta;Resultado;Tempo_Resposta_Seg;Consultas_Grimorio;Enunciado")
		
		var respostas = dados["respostas_sessao"]
		if respostas.size() > 0:
			for r in respostas:
				var a_id = int(r.get("andar_id", 1))
				var disc = "Química"
				if a_id == 2: disc = "Física"
				elif a_id == 3: disc = "Biologia"
				
				var pid = int(r.get("pergunta_id", 0))
				var q_obj = mapa_q.get(pid, {})
				
				# Gabarito sempre preenchido via banco de perguntas
				var gabarito = str(r.get("alternativa_correta", "")).strip_edges()
				if (gabarito.is_empty() or gabarito == "-") and q_obj.size() > 0:
					var opts = q_obj.get("options", [])
					var aidx = int(q_obj.get("answer", 0))
					if aidx >= 0 and aidx < opts.size():
						gabarito = ["A", "B", "C", "D"][aidx] + ") " + str(opts[aidx])
						
				# Opção marcada com resolução inteligente
				var marcada = str(r.get("alternativa_marcada", "")).strip_edges()
				if marcada.is_empty() or marcada == "-":
					if r.get("acertou", false):
						marcada = gabarito
					else:
						marcada = "Incorreta (Partida antiga)"
				
				var n_tri = int(q_obj.get("nivel_progresso", r.get("nivel_progresso", 1)))
				var dif_str = "Nível 1 (Fácil)"
				if n_tri == 2: dif_str = "Nível 2 (Médio)"
				elif n_tri == 3: dif_str = "Nível 3 (Difícil)"
				
				var enunciado = str(r.get("enunciado", q_obj.get("question", "")))
				
				var linha = [
					str(r.get("escola_nome", escola_nome)),
					str(r.get("timestamp", "-")),
					str(r.get("aluno_nick", "Mago")),
					str(r.get("cla_aluno", "-")),
					disc,
					str(a_id),
					str(pid),
					dif_str,
					'"' + marcada.replace('"', '""') + '"',
					'"' + gabarito.replace('"', '""') + '"',
					"Acertou" if r.get("acertou", false) else "Errou",
					str(r.get("tempo_resposta", 0.0)),
					str(r.get("consultas_grimorio", 0)),
					'"' + enunciado.replace('"', '""') + '"'
				]
				f_alunos.store_line(";".join(linha))
		else:
			f_alunos.store_line("%s;%s;Sem respostas registradas ainda;-;-;-;-;-;-;-;-;-;-;-" % [escola_nome, Time.get_datetime_string_from_system()])
		f_alunos.close()

	# ARQUIVO 2: Catálogo Completo das 150 Questões e Desempenho
	var fn_questoes = "synthesis_catalogo_150_questoes_%s_%s.csv" % [escola_id, timestamp_str]
	var path_questoes = dir_relatorios + "/" + fn_questoes
	var f_questoes = FileAccess.open(path_questoes, FileAccess.WRITE)
	if f_questoes:
		f_questoes.store_8(0xEF); f_questoes.store_8(0xBB); f_questoes.store_8(0xBF)
		f_questoes.store_line("ID_Questao;Disciplina;Andar;Nivel_TRI;Dificuldade;Total_Tentativas;Total_Acertos;Total_Erros;Taxa_Acerto_Pct;Tempo_Medio_Seg;Consultas_Grimorio_Total;Alternativa_Correta;Enunciado;Dica_Explicacao")
		
		var todas_q = dados["todas_questoes"]
		var mapa_stats = dados["mapa_stats"]
		
		for q in todas_q:
			var pid = int(q.get("id", 0))
			var a_id = int(q.get("andar_id", 1))
			var disc = "Química"
			if a_id == 2: disc = "Física"
			elif a_id == 3: disc = "Biologia"
			
			var n_tri = int(q.get("nivel_progresso", 1))
			var dif_str = "Fácil"
			if n_tri == 2: dif_str = "Médio"
			elif n_tri == 3: dif_str = "Difícil"
			
			var s = mapa_stats[pid]
			var tent = s["acertos"] + s["erros"]
			var taxa = 0
			if tent > 0:
				taxa = int((float(s["acertos"]) / float(tent)) * 100)
			var tempo_m = 0.0
			if s["tempo_count"] > 0:
				tempo_m = snappedf(s["tempo_total"] / float(s["tempo_count"]), 0.1)
				
			var opcoes = q.get("options", [])
			var ans_idx = int(q.get("answer", 0))
			var resp_correta = ""
			if ans_idx >= 0 and ans_idx < opcoes.size():
				resp_correta = ["A", "B", "C", "D"][ans_idx] + ") " + str(opcoes[ans_idx])
				
			var linha = [
				str(pid),
				disc,
				str(a_id),
				"Nível " + str(n_tri),
				dif_str,
				str(tent),
				str(s["acertos"]),
				str(s["erros"]),
				str(taxa) + "%",
				str(tempo_m),
				str(s["grimorio_total"]),
				'"' + resp_correta.replace('"', '""') + '"',
				'"' + str(q.get("question", "")).replace('"', '""') + '"',
				'"' + str(q.get("dica", "")).replace('"', '""') + '"'
			]
			f_questoes.store_line(";".join(linha))
		f_questoes.close()

	if OS.has_feature("web"):
		var baixou = false
		if ClassDB.class_exists("JavaScriptBridge"):
			var bytes_alunos = FileAccess.get_file_as_bytes(path_alunos)
			var bytes_questoes = FileAccess.get_file_as_bytes(path_questoes)
			JavaScriptBridge.download_buffer(bytes_alunos, fn_alunos, "text/csv;charset=utf-8")
			await get_tree().create_timer(0.4).timeout
			JavaScriptBridge.download_buffer(bytes_questoes, fn_questoes, "text/csv;charset=utf-8")
			baixou = true
		if baixou:
			_exibir_toast("Download das planilhas CSV iniciado no navegador!")
		else:
			_exibir_toast("Erro ao iniciar download na plataforma Web.")
	else:
		OS.shell_open(ProjectSettings.globalize_path(dir_relatorios))
		_exibir_toast("Planilhas CSV exportadas (Microdados de Alunos e Matriz das 150 Questões)!")

# --- EXPORTAÇÃO DE RELATÓRIO PEDAGÓGICO (IMPRESSÃO / PDF) ---

func _exportar_pdf_relatorio() -> void:
	var dir_relatorios = "user://relatorios"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_relatorios))
	
	var dados = await _coletar_dados_completos_150()
	var escola_id = dados["escola_id"]
	var escola_nome = dados["escola_nome"]
	var dt = Time.get_datetime_dict_from_system()
	var data_formatada = "%02d/%02d/%04d às %02d:%02d" % [dt.day, dt.month, dt.year, dt.hour, dt.minute]
	
	var filename = "synthesis_relatorio_%s_%04d%02d%02d_%02d%02d.html" % [
		escola_id, dt.year, dt.month, dt.day, dt.hour, dt.minute
	]
	var path_html = dir_relatorios + "/" + filename
	var file = FileAccess.open(path_html, FileAccess.WRITE)
	if not file:
		_exibir_toast("Erro ao gerar relatório HTML para impressão.")
		return
		
	var totais = dados["totais_globais"]
	var disc_stats = dados["stats_disciplinas"]
	var dif_stats = dados["stats_dificuldades"]
	var todas_q = dados["todas_questoes"]
	var mapa_stats = dados["mapa_stats"]
	var mapa_q = dados["mapa_questoes_por_id"]
	var mapa_alunos = dados["mapa_alunos"]
	var respostas_sessao = dados["respostas_sessao"]
	
	# Classificação pedagógica geral
	var desempenho_class = "Aguardando Tentativas"
	if totais["total_respostas"] > 0:
		if totais["taxa_geral"] >= 70:
			desempenho_class = "Alto Domínio Cognitivo"
		elif totais["taxa_geral"] >= 40:
			desempenho_class = "Desempenho Equilibrado"
		else:
			desempenho_class = "Alto Grau de Desafio"
			
	# Tabela 1: Resumo por Disciplina (Química, Física, Biologia)
	var linhas_disc_html = ""
	for a_id in [1, 2, 3]:
		var sd = disc_stats[a_id]
		var cor_taxa = "#16a34a" if sd["taxa"] >= 60 else ("#d97706" if sd["taxa"] >= 40 else "#dc2626")
		linhas_disc_html += """
			<tr>
				<td><b>%s</b> (Andar %d)</td>
				<td style="text-align: center;">%d</td>
				<td style="text-align: center;">%d F | %d M | %d D</td>
				<td style="text-align: center;">%d</td>
				<td style="text-align: center; color: #16a34a; font-weight: 600;">%d</td>
				<td style="text-align: center; color: #dc2626; font-weight: 600;">%d</td>
				<td style="text-align: center; font-weight: 700; color: %s;">%d%%</td>
				<td style="text-align: center;">%.1fs</td>
				<td style="text-align: center;">%d</td>
			</tr>
		""" % [
			sd["nome"], sd["andar"], sd["questoes"],
			sd["faceis"], sd["medias"], sd["dificeis"],
			sd["respostas"], sd["acertos"], sd["erros"],
			cor_taxa, sd["taxa"], sd["tempo_medio"], sd["grimorio"]
		]

	# Tabela 2: Resumo Psicométrico TRI por Dificuldade
	var linhas_dif_html = ""
	for n_tri in [1, 2, 3]:
		var sdf = dif_stats[n_tri]
		var badge_cls = "dif-1" if n_tri == 1 else ("dif-2" if n_tri == 2 else "dif-3")
		var cor_taxa = "#16a34a" if sdf["taxa"] >= 60 else ("#d97706" if sdf["taxa"] >= 40 else "#dc2626")
		linhas_dif_html += """
			<tr>
				<td><span class="tag-dificuldade %s">%s</span></td>
				<td style="text-align: center;">Nível %d</td>
				<td style="text-align: center;">%d questões</td>
				<td style="text-align: center;">%d</td>
				<td style="text-align: center; color: #16a34a; font-weight: 600;">%d</td>
				<td style="text-align: center; color: #dc2626; font-weight: 600;">%d</td>
				<td style="text-align: center; font-weight: 700; color: %s;">%d%%</td>
				<td style="text-align: center;">%.1fs</td>
			</tr>
		""" % [
			badge_cls, sdf["nome"], sdf["nivel"], sdf["questoes"],
			sdf["respostas"], sdf["acertos"], sdf["erros"],
			cor_taxa, sdf["taxa"], sdf["tempo_medio"]
		]

	# Tabela 3: Desempenho Consolidado por Aluno / Jogador (1 LINHA POR ALUNO!)
	var linhas_alunos_html = ""
	var lista_alunos = mapa_alunos.values()
	lista_alunos.sort_custom(func(a, b):
		if a["questoes_respondidas"] != b["questoes_respondidas"]:
			return a["questoes_respondidas"] > b["questoes_respondidas"]
		if a["taxa"] != b["taxa"]:
			return a["taxa"] > b["taxa"]
		return a["score"] > b["score"]
	)
	
	for al in lista_alunos:
		var cor_taxa = "#16a34a" if al["taxa"] >= 60 else ("#d97706" if al["taxa"] >= 40 else "#dc2626")
		var situacao_html = ""
		if al["questoes_respondidas"] == 0:
			situacao_html = '<span class="tag-sem-dados">Aguardando Partidas</span>'
			cor_taxa = "#94a3b8"
		elif al["taxa"] >= 70:
			situacao_html = '<span class="tag-dificuldade dif-1">Alto Domínio</span>'
		elif al["taxa"] >= 40:
			situacao_html = '<span class="tag-dificuldade dif-2">Equilibrado</span>'
		else:
			situacao_html = '<span class="tag-dificuldade dif-3">Necessita Apoio</span>'
			
		var tempo_str = (str(al["tempo_medio"]) + "s") if al["tempo_count"] > 0 else "-"
		var grim_str = str(al["grimorio_total"]) if al["grimorio_total"] > 0 else "-"
		var score_str = "%d pts" % al["score"] if al["score"] > 0 else "-"
		var taxa_str = (str(al["taxa"]) + "%") if al["questoes_respondidas"] > 0 else "-"
		
		linhas_alunos_html += """
			<tr>
				<td><b>%s</b></td>
				<td>%s</td>
				<td style="text-align: center; color: #475569;">%s</td>
				<td style="text-align: center;">%d</td>
				<td style="text-align: center; color: #16a34a; font-weight: 600;">%d</td>
				<td style="text-align: center; color: #dc2626; font-weight: 600;">%d</td>
				<td style="text-align: center; font-weight: 700; color: %s;">%s</td>
				<td style="text-align: center;">%s</td>
				<td style="text-align: center;">%s</td>
				<td style="text-align: center;">%s</td>
			</tr>
		""" % [
			al["nick"].xml_escape(),
			al["cla"].xml_escape(),
			score_str,
			al["questoes_respondidas"],
			al["acertos"],
			al["erros"],
			cor_taxa, taxa_str,
			tempo_str,
			grim_str,
			situacao_html
		]

	# Tabela 4: Amostragem Recente de Respostas (Audit Trail Compacto com Gabarito Resolvido)
	var secao_respostas_alunos_html = ""
	if respostas_sessao.size() > 0:
		var linhas_resp_html = ""
		var limite_amostragem = min(respostas_sessao.size(), 12)
		for i in range(limite_amostragem):
			var r = respostas_sessao[respostas_sessao.size() - 1 - i]
			var a_id = int(r.get("andar_id", 1))
			var d_nome = "Química"
			if a_id == 2: d_nome = "Física"
			elif a_id == 3: d_nome = "Biologia"
			
			var pid = int(r.get("pergunta_id", 0))
			var q_obj = mapa_q.get(pid, {})
			
			var gabarito = str(r.get("alternativa_correta", "")).strip_edges()
			if (gabarito.is_empty() or gabarito == "-") and q_obj.size() > 0:
				var opts = q_obj.get("options", [])
				var aidx = int(q_obj.get("answer", 0))
				if aidx >= 0 and aidx < opts.size():
					gabarito = ["A", "B", "C", "D"][aidx] + ") " + str(opts[aidx])
					
			var marcada = str(r.get("alternativa_marcada", "")).strip_edges()
			if marcada.is_empty() or marcada == "-":
				if r.get("acertou", false):
					marcada = gabarito
				else:
					marcada = "Alternativa Incorreta"
			
			var acertou = bool(r.get("acertou", false))
			var res_cls = "tag-acerto" if acertou else "tag-erro"
			var res_txt = "Acertou" if acertou else "Errou"
			
			var t_resp_num = float(r.get("tempo_resposta", 0.0))
			var t_resp_str = ("%.1fs" % t_resp_num) if t_resp_num > 0.0 else "-"
			var c_grim_num = int(r.get("consultas_grimorio", 0))
			var c_grim_str = str(c_grim_num) if c_grim_num > 0 else "-"
			
			linhas_resp_html += """
				<tr>
					<td style="font-size: 11px; color: #64748b;">%s</td>
					<td><b>%s</b></td>
					<td>%s</td>
					<td style="text-align: center;">#%s</td>
					<td style="font-size: 12px;">%s</td>
					<td style="font-size: 12px; color: #16a34a; font-weight: 500;">%s</td>
					<td class="%s">%s</td>
					<td style="text-align: center;">%s</td>
					<td style="text-align: center;">%s</td>
				</tr>
			""" % [
				str(r.get("timestamp", "-")),
				str(r.get("aluno_nick", "Mago")),
				d_nome,
				str(pid),
				marcada.xml_escape(),
				gabarito.xml_escape(),
				res_cls, res_txt,
				t_resp_str,
				c_grim_str
			]
			
		secao_respostas_alunos_html = """
			<h3>4. Amostragem Recente de Respostas Registradas</h3>
			<p style="font-size: 12px; color: #64748b; margin-top: -6px; margin-bottom: 8px;">
				Amostragem das tentativas mais recentes com validação das alternativas escolhidas e gabarito correspondente.
			</p>
			<table>
				<thead>
					<tr>
						<th style="width: 115px;">Data/Hora</th>
						<th style="width: 100px;">Aluno</th>
						<th style="width: 80px;">Disciplina</th>
						<th style="width: 45px; text-align: center;">ID</th>
						<th>Opção Marcada</th>
						<th>Gabarito da Questão</th>
						<th style="width: 75px;">Resultado</th>
						<th style="width: 65px; text-align: center;">Tempo</th>
						<th style="width: 65px; text-align: center;">Grimório</th>
					</tr>
				</thead>
				<tbody>
					%s
				</tbody>
			</table>
		""" % linhas_resp_html

	# Tabela 5: Catálogo Completo das 150 Questões do Jogo
	var linhas_150_html = ""
	for q in todas_q:
		var pid = int(q.get("id", 0))
		var a_id = int(q.get("andar_id", 1))
		var disc = "Química"
		var disc_badge = "disc-qui"
		if a_id == 2:
			disc = "Física"
			disc_badge = "disc-fis"
		elif a_id == 3:
			disc = "Biologia"
			disc_badge = "disc-bio"
			
		var n_tri = int(q.get("nivel_progresso", 1))
		var dif_cls = "dif-1"
		var dif_txt = "Fácil"
		if n_tri == 2:
			dif_cls = "dif-2"
			dif_txt = "Médio"
		elif n_tri == 3:
			dif_cls = "dif-3"
			dif_txt = "Difícil"
			
		var s = mapa_stats[pid]
		var tent = s["acertos"] + s["erros"]
		var taxa = 0
		if tent > 0:
			taxa = int((float(s["acertos"]) / float(tent)) * 100)
		var tempo_m = 0.0
		if s["tempo_count"] > 0:
			tempo_m = snappedf(s["tempo_total"] / float(s["tempo_count"]), 0.1)
			
		var tx_cor = "tag-acerto" if taxa >= 60 else ("tag-alerta" if taxa >= 40 else "tag-erro")
		if tent == 0:
			tx_cor = "tag-sem-dados"
			
		linhas_150_html += """
			<tr>
				<td style="font-weight: 600;">#%d</td>
				<td><span class="tag-disciplina %s">%s</span></td>
				<td><span class="tag-dificuldade %s">%s</span></td>
				<td>%s</td>
				<td style="text-align: center; color: #16a34a; font-weight: 600;">%d</td>
				<td style="text-align: center; color: #dc2626; font-weight: 600;">%d</td>
				<td style="text-align: center;" class="%s">%s</td>
				<td style="text-align: center;">%s</td>
			</tr>
		""" % [
			pid,
			disc_badge, disc,
			dif_cls, dif_txt,
			str(q.get("question", "")).xml_escape(),
			s["acertos"],
			s["erros"],
			tx_cor, (str(taxa) + "%") if tent > 0 else "-",
			(str(tempo_m) + "s") if s["tempo_count"] > 0 else "-"
		]

	# Template Base do Relatório com Estilos Formais e Impressão Limpa
	var template = """<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<title>Synthesis - Relatório Pedagógico e Desempenho Escolar</title>
<style>
	body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background: #f1f5f9; color: #0f172a; margin: 0; padding: 24px; font-size: 13px; line-height: 1.5; }
	.container { max-width: 1020px; margin: 0 auto; background: #ffffff; border-radius: 10px; box-shadow: 0 4px 20px rgba(0,0,0,0.06); padding: 32px 36px; border: 1px solid #e2e8f0; }
	.banner-print { background: #eff6ff; border: 1px solid #bfdbfe; color: #1e40af; padding: 12px 18px; border-radius: 8px; font-size: 13px; margin-bottom: 24px; font-weight: 500; }
	.header { border-bottom: 2px solid #e2e8f0; padding-bottom: 18px; margin-bottom: 24px; display: flex; justify-content: space-between; align-items: flex-start; }
	.header h1 { font-size: 22px; color: #0f172a; margin: 0 0 4px 0; font-weight: 700; letter-spacing: -0.3px; }
	.header .instituicao { font-size: 13px; color: #1e3a8a; font-weight: 600; margin-bottom: 2px; }
	.header .emissao { color: #64748b; font-size: 12px; margin: 0; }
	.badge-sessao { background: #f8fafc; color: #0f172a; padding: 8px 16px; border-radius: 6px; font-weight: 600; font-size: 13px; border: 1px solid #cbd5e1; text-align: right; }
	.badge-sessao .sub { font-size: 11px; color: #64748b; font-weight: normal; margin-top: 2px; }
	
	.cards { display: grid; grid-template-columns: repeat(6, 1fr); gap: 12px; margin-bottom: 28px; }
	.card { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 12px 10px; text-align: center; }
	.card .val { font-size: 22px; font-weight: 700; color: #0f172a; margin-bottom: 2px; }
	.card .lbl { font-size: 10px; color: #475569; text-transform: uppercase; font-weight: 700; letter-spacing: 0.3px; }
	.card .sub { font-size: 10px; color: #64748b; margin-top: 3px; }
	
	h3 { font-size: 15px; color: #0f172a; margin: 24px 0 10px 0; font-weight: 700; border-left: 4px solid #1e3a8a; padding-left: 8px; }
	table { width: 100%; border-collapse: collapse; margin-top: 8px; margin-bottom: 20px; font-size: 12px; }
	th { background: #f8fafc; color: #334155; text-align: left; padding: 9px 10px; border-bottom: 2px solid #cbd5e1; font-weight: 600; }
	td { padding: 8px 10px; border-bottom: 1px solid #e2e8f0; vertical-align: middle; }
	tr:nth-child(even) { background: #fbfcfe; }
	
	.tag-acerto { font-weight: 700; color: #16a34a; }
	.tag-erro { font-weight: 700; color: #dc2626; }
	.tag-alerta { font-weight: 700; color: #d97706; }
	.tag-sem-dados { color: #94a3b8; font-weight: normal; }
	
	.tag-dificuldade { display: inline-block; padding: 2px 7px; border-radius: 4px; font-size: 11px; font-weight: 600; text-align: center; }
	.dif-1 { background: #dcfce7; color: #166534; border: 1px solid #bbf7d0; }
	.dif-2 { background: #fef3c7; color: #854d0e; border: 1px solid #fde68a; }
	.dif-3 { background: #fee2e2; color: #991b1b; border: 1px solid #fecaca; }
	
	.tag-disciplina { display: inline-block; padding: 2px 6px; border-radius: 4px; font-size: 11px; font-weight: 600; }
	.disc-qui { background: #f3e8ff; color: #6b21a8; border: 1px solid #e9d5ff; }
	.disc-fis { background: #e0f2fe; color: #0369a1; border: 1px solid #bae6fd; }
	.disc-bio { background: #dcfce7; color: #15803d; border: 1px solid #bbf7d0; }
	
	.footer { border-top: 1px solid #e2e8f0; margin-top: 32px; padding-top: 14px; display: flex; justify-content: space-between; font-size: 11px; color: #64748b; }
	
	@media print {
		body { background: #ffffff !important; padding: 0 !important; color: #000000; font-size: 11px; }
		.container { box-shadow: none !important; padding: 0 !important; max-width: 100% !important; border: none !important; }
		.banner-print { display: none !important; }
		.page-break { page-break-before: always; }
		table { page-break-inside: auto; }
		tr { page-break-inside: avoid; page-break-after: auto; }
		thead { display: table-header-group; }
		.cards { gap: 8px; }
		.card { padding: 8px 6px; }
		.card .val { font-size: 18px; }
	}
</style>
</head>
<body>
<div class="container">
	<div class="banner-print" style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px;">
		<div>
			<b>Dica para gerar PDF:</b> Pressione <b>Ctrl + P</b> no seu teclado ou clique no botão ao lado, escolha a impressora <b>"Salvar como PDF"</b> e clique em Salvar!
		</div>
		<button onclick="window.print()" style="background: #2563eb; color: #ffffff; border: none; padding: 8px 16px; border-radius: 6px; font-weight: 600; cursor: pointer; font-size: 13px; box-shadow: 0 2px 4px rgba(37,99,235,0.25);">
			🖨️ Imprimir / Salvar em PDF
		</button>
	</div>
	
	<div class="header">
		<div>
			<div class="instituicao">UNIVERSIDADE FEDERAL DO CEARÁ • PROJETO VORTEX UFC • JOGO EDUCACIONAL</div>
			<h1>Synthesis — Relatório Pedagógico & Desempenho Escolar</h1>
			<p class="emissao">Relatório Pedagógico de Avaliação da Aprendizagem | Emissão: {{DATA_EMISSAO}}</p>
		</div>
		<div class="badge-sessao">
			<div>Sessão: <b>{{NOME_ESCOLA}}</b></div>
			<div class="sub">Identificador: {{ID_ESCOLA}}</div>
		</div>
	</div>
	
	<div class="cards">
		<div class="card">
			<div class="val">{{TOTAL_QUESTOES}}</div>
			<div class="lbl">Questões Analisadas</div>
			<div class="sub">150 no Total (50/andar)</div>
		</div>
		<div class="card">
			<div class="val">{{TAXA_GERAL}}%</div>
			<div class="lbl">Taxa Média de Acerto</div>
			<div class="sub">{{DESEMPENHO_DOMINIO}}</div>
		</div>
		<div class="card">
			<div class="val">{{TOTAL_RESPOSTAS}}</div>
			<div class="lbl">Respostas Coletadas</div>
			<div class="sub">{{TOTAL_ACERTOS}} Acertos | {{TOTAL_ERROS}} Erros</div>
		</div>
		<div class="card">
			<div class="val">{{TEMPO_MEDIO}}s</div>
			<div class="lbl">Tempo Médio Resposta</div>
			<div class="sub">Latência por Pergunta</div>
		</div>
		<div class="card">
			<div class="val">{{TOTAL_GRIMORIO}}</div>
			<div class="lbl">Consultas Grimório</div>
			<div class="sub">Pergaminhos e Apoio</div>
		</div>
		<div class="card">
			<div class="val">{{TOTAL_ALUNOS}}</div>
			<div class="lbl">Alunos Cadastrados</div>
			<div class="sub">Participantes no Sistema</div>
		</div>
	</div>
	
	<h3>1. Desempenho por Disciplina (Andares da Torre)</h3>
	<table>
		<thead>
			<tr>
				<th>Disciplina</th>
				<th style="text-align: center; width: 80px;">Questões</th>
				<th style="text-align: center; width: 140px;">Distribuição TRI</th>
				<th style="text-align: center; width: 80px;">Respostas</th>
				<th style="text-align: center; width: 70px;">Acertos</th>
				<th style="text-align: center; width: 70px;">Erros</th>
				<th style="text-align: center; width: 90px;">Taxa Acerto</th>
				<th style="text-align: center; width: 95px;">Tempo Médio</th>
				<th style="text-align: center; width: 80px;">Grimório</th>
			</tr>
		</thead>
		<tbody>
			{{TABELA_DISCIPLINAS}}
		</tbody>
	</table>

	<h3>2. Matriz Psicométrica por Dificuldade Teórica (TRI)</h3>
	<table>
		<thead>
			<tr>
				<th>Dificuldade Teórica</th>
				<th style="text-align: center; width: 90px;">Classificação</th>
				<th style="text-align: center; width: 90px;">Questões</th>
				<th style="text-align: center; width: 90px;">Respostas</th>
				<th style="text-align: center; width: 80px;">Acertos</th>
				<th style="text-align: center; width: 80px;">Erros</th>
				<th style="text-align: center; width: 100px;">Taxa Acerto</th>
				<th style="text-align: center; width: 100px;">Tempo Médio</th>
			</tr>
		</thead>
		<tbody>
			{{TABELA_DIFICULDADES}}
		</tbody>
	</table>

	<div class="page-break"></div>
	<h3>3. Desempenho Individual por Aluno / Jogador Cadastrado</h3>
	<p style="font-size: 12px; color: #64748b; margin-top: -6px; margin-bottom: 12px;">
		Quadro consolidado de todos os estudantes cadastrados com total de questões, acertos, taxa de domínio e situação pedagógica.
	</p>
	<table>
		<thead>
			<tr>
				<th>Aluno (Nick)</th>
				<th style="width: 100px;">Clã</th>
				<th style="text-align: center; width: 85px;">Pontuação</th>
				<th style="text-align: center; width: 90px;">Questões</th>
				<th style="text-align: center; width: 70px;">Acertos</th>
				<th style="text-align: center; width: 70px;">Erros</th>
				<th style="text-align: center; width: 90px;">Taxa Acerto</th>
				<th style="text-align: center; width: 95px;">Tempo Médio</th>
				<th style="text-align: center; width: 80px;">Grimório</th>
				<th style="text-align: center; width: 130px;">Situação</th>
			</tr>
		</thead>
		<tbody>
			{{TABELA_ALUNOS_CONSOLIDADA}}
		</tbody>
	</table>

	{{SECAO_RESPOSTAS_AMOSTRAGEM}}

	<div class="page-break"></div>
	<h3>5. Catálogo Completo das 150 Questões do Jogo (Química, Física e Biologia)</h3>
	<p style="font-size: 12px; color: #64748b; margin-top: -6px; margin-bottom: 12px;">
		Mapeamento integral de todas as 150 questões do jogo com identificação de nível TRI, taxa de acerto acumulada e tempo médio de resposta.
	</p>
	<table>
		<thead>
			<tr>
				<th style="width: 45px;">ID</th>
				<th style="width: 85px;">Disciplina</th>
				<th style="width: 75px;">Dificuldade</th>
				<th>Enunciado da Questão</th>
				<th style="width: 60px; text-align: center;">Acertos</th>
				<th style="width: 60px; text-align: center;">Erros</th>
				<th style="width: 80px; text-align: center;">Taxa</th>
				<th style="width: 75px; text-align: center;">Tempo</th>
			</tr>
		</thead>
		<tbody>
			{{TABELA_150_QUESTOES}}
		</tbody>
	</table>
	
	<div class="footer">
		<div>Synthesis • Projeto Vortex UFC</div>
		<div>Documento gerado automaticamente pelo Sistema Synthesis</div>
	</div>
</div>
</body>
</html>
"""

	# Substituição segura via replace (sem interferência de caracteres de porcentagem do CSS)
	var html = template
	html = html.replace("{{DATA_EMISSAO}}", data_formatada)
	html = html.replace("{{NOME_ESCOLA}}", escola_nome)
	html = html.replace("{{ID_ESCOLA}}", escola_id)
	html = html.replace("{{TOTAL_QUESTOES}}", str(totais["total_questoes"]))
	html = html.replace("{{TAXA_GERAL}}", str(totais["taxa_geral"]))
	html = html.replace("{{DESEMPENHO_DOMINIO}}", desempenho_class)
	html = html.replace("{{TOTAL_RESPOSTAS}}", str(totais["total_respostas"]))
	html = html.replace("{{TOTAL_ACERTOS}}", str(totais["total_acertos"]))
	html = html.replace("{{TOTAL_ERROS}}", str(totais["total_erros"]))
	html = html.replace("{{TEMPO_MEDIO}}", str(totais["tempo_medio"]))
	html = html.replace("{{TOTAL_GRIMORIO}}", str(totais["total_grimorio"]))
	html = html.replace("{{TOTAL_ALUNOS}}", str(totais["total_alunos"]))
	html = html.replace("{{TABELA_DISCIPLINAS}}", linhas_disc_html)
	html = html.replace("{{TABELA_DIFICULDADES}}", linhas_dif_html)
	html = html.replace("{{TABELA_ALUNOS_CONSOLIDADA}}", linhas_alunos_html)
	html = html.replace("{{SECAO_RESPOSTAS_AMOSTRAGEM}}", secao_respostas_alunos_html)
	html = html.replace("{{TABELA_150_QUESTOES}}", linhas_150_html)

	file.store_string(html)
	file.close()
	
	if OS.has_feature("web"):
		var aberto = false
		if ClassDB.class_exists("JavaScriptBridge"):
			var js_win = JavaScriptBridge.get_interface("window")
			if js_win:
				# Tenta abrir o relatório em nova aba via Blob URL (sem 404 de servidor)
				var res = js_win.synthesisOpenReportHtml(html, filename)
				if str(res) == "opened":
					aberto = true
					_exibir_toast("Relatório aberto em nova aba! Pressione Ctrl + P para salvar como PDF.")
				elif str(res) == "downloaded":
					aberto = true
					_exibir_toast("Relatório HTML baixado! (Bloqueador de popups impediu nova aba).")
		
		if not aberto and ClassDB.class_exists("JavaScriptBridge"):
			var bytes_html = FileAccess.get_file_as_bytes(path_html)
			JavaScriptBridge.download_buffer(bytes_html, filename, "text/html;charset=utf-8")
			_exibir_toast("Relatório HTML baixado! Abra-o para imprimir ou salvar em PDF.")
	else:
		var caminho_global = ProjectSettings.globalize_path(path_html)
		OS.shell_open(caminho_global)
		_exibir_toast("Relatório aberto no navegador! Pressione Ctrl + P para salvar como PDF.")


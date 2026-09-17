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
	
	# 2. Seletor de Disciplina
	_criar_seletor_disciplinas(vbox_principal)
	
	# 3. Cards de Resumo KPI (Dashboard Pedagógico)
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

func _carregar_dados() -> void:
	lbl_total_questoes_val.text = "..."
	lbl_taxa_acerto_val.text = "..."
	lbl_total_respostas_val.text = "..."
	lbl_total_jogadores_val.text = "..."
	
	_mostrar_mensagem_tabela("Carregando perguntas e estatísticas...", COLOR_TEXT_MUTED)
	
	# 1. Total de jogadores no ranking geral
	var res_jogadores = await DatabaseManager.request_async("/rest/v1/rankinggeral?select=player_name", HTTPClient.METHOD_GET)
	if res_jogadores.get("success", false) and res_jogadores.get("data") is Array:
		total_jogadores_count = res_jogadores["data"].size()
		lbl_total_jogadores_val.text = "%d Magos" % total_jogadores_count
		lbl_total_jogadores_sub.text = "Cadastrados no servidor"
	else:
		total_jogadores_count = 0
		lbl_total_jogadores_val.text = "Offline"
		lbl_total_jogadores_sub.text = "Dados locais"
	
	# 2. Respostas registradas para a disciplina atual
	var id_andar = disciplinas[disciplina_atual_idx]["andar_id"]
	var res_resp = await DatabaseManager.request_async("/rest/v1/respostas?select=pergunta_id,acertou&andar_id=eq." + str(id_andar), HTTPClient.METHOD_GET)
	
	mapa_respostas.clear()
	var soma_acertos_geral: int = 0
	var soma_erros_geral: int = 0
	
	if res_resp.get("success", false) and res_resp.get("data") is Array:
		for r in res_resp["data"]:
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

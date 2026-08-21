extends Control

var tabela_dados: VBoxContainer
var lbl_total_alunos: Label
var lbl_taxa_acerto: Label
var lbl_total_jogadores: Label
var lbl_disciplina: Label

var disciplinas = ["Física", "Química", "Biologia"]
var disciplina_atual_idx = 0

func _ready() -> void:
	# Fundo
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.15, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Layout Principal
	var margem = MarginContainer.new()
	margem.add_theme_constant_override("margin_left", 40)
	margem.add_theme_constant_override("margin_right", 40)
	margem.add_theme_constant_override("margin_top", 40)
	margem.add_theme_constant_override("margin_bottom", 40)
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(margem)
	
	var vbox_principal = VBoxContainer.new()
	vbox_principal.add_theme_constant_override("separation", 20)
	margem.add_child(vbox_principal)
	
	# Cabeçalho
	var cabecalho_hbox = HBoxContainer.new()
	vbox_principal.add_child(cabecalho_hbox)
	
	var lbl_titulo = Label.new()
	lbl_titulo.text = "Painel Administrativo - Estatísticas"
	lbl_titulo.add_theme_font_size_override("font_size", 28)
	lbl_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabecalho_hbox.add_child(lbl_titulo)
	
	var btn_reset = Button.new()
	btn_reset.text = " ⚠ RESETAR JOGO "
	btn_reset.add_theme_color_override("font_color", Color.RED)
	btn_reset.pressed.connect(_abrir_popup_reset)
	cabecalho_hbox.add_child(btn_reset)
	
	var separador = Control.new()
	separador.custom_minimum_size = Vector2(20, 0)
	cabecalho_hbox.add_child(separador)
	
	var btn_add = Button.new()
	btn_add.text = " ➕ Adicionar Questões "
	btn_add.add_theme_color_override("font_color", Color.GREEN)
	btn_add.pressed.connect(func(): TransitionScreen.change_scene("res://scenes/ui/adicionar_perguntas.tscn"))
	cabecalho_hbox.add_child(btn_add)
	
	var separador2 = Control.new()
	separador2.custom_minimum_size = Vector2(20, 0)
	cabecalho_hbox.add_child(separador2)
	
	var btn_voltar = Button.new()
	btn_voltar.text = "Voltar ao Jogo"
	btn_voltar.pressed.connect(func(): TransitionScreen.change_scene("res://scenes/ui/main_menu.tscn"))
	cabecalho_hbox.add_child(btn_voltar)
	
	# Dashboard Geral
	var hbox_dash = HBoxContainer.new()
	hbox_dash.add_theme_constant_override("separation", 30)
	vbox_principal.add_child(hbox_dash)
	
	lbl_total_alunos = _criar_card(hbox_dash, "Total de Perguntas", "Carregando...")
	lbl_taxa_acerto = _criar_card(hbox_dash, "Taxa de Acerto (Geral)", "Carregando...")
	lbl_total_jogadores = _criar_card(hbox_dash, "Total de Jogadores", "Carregando...")
	
	# Raio-X das Questões
	var lbl_raio_x = Label.new()
	lbl_raio_x.text = "Desempenho por Questão (Das Mais Erradas para as Mais Acertadas)"
	lbl_raio_x.add_theme_font_size_override("font_size", 20)
	vbox_principal.add_child(lbl_raio_x)
	
	# Seletor de Disciplina
	var hbox_disciplina = HBoxContainer.new()
	hbox_disciplina.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_disciplina.add_theme_constant_override("separation", 20)
	vbox_principal.add_child(hbox_disciplina)
	
	var btn_esq = Button.new()
	btn_esq.text = " < "
	btn_esq.pressed.connect(_mudar_disciplina.bind(-1))
	hbox_disciplina.add_child(btn_esq)
	
	lbl_disciplina = Label.new()
	lbl_disciplina.text = disciplinas[disciplina_atual_idx]
	lbl_disciplina.custom_minimum_size = Vector2(150, 0)
	lbl_disciplina.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_disciplina.add_theme_font_size_override("font_size", 18)
	lbl_disciplina.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
	hbox_disciplina.add_child(lbl_disciplina)
	
	var btn_dir = Button.new()
	btn_dir.text = " > "
	btn_dir.pressed.connect(_mudar_disciplina.bind(1))
	hbox_disciplina.add_child(btn_dir)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox_principal.add_child(scroll)
	
	tabela_dados = VBoxContainer.new()
	tabela_dados.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabela_dados.add_theme_constant_override("separation", 10)
	scroll.add_child(tabela_dados)
	
	_carregar_dados_simulados()

func _criar_card(parent: Control, titulo: String, valor: String) -> Label:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.16, 0.22, 1.0)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 4)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	panel.add_theme_stylebox_override("panel", style)
	
	parent.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	
	var lbl_tit = Label.new()
	lbl_tit.text = titulo
	lbl_tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_tit.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	lbl_tit.add_theme_font_size_override("font_size", 14)
	vbox.add_child(lbl_tit)
	
	var lbl_val = Label.new()
	lbl_val.text = valor
	lbl_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_val.add_theme_font_size_override("font_size", 32)
	lbl_val.add_theme_color_override("font_color", Color(1, 1, 1))
	vbox.add_child(lbl_val)
	
	return lbl_val

func _mudar_disciplina(direcao: int) -> void:
	disciplina_atual_idx += direcao
	if disciplina_atual_idx < 0:
		disciplina_atual_idx = disciplinas.size() - 1
	elif disciplina_atual_idx >= disciplinas.size():
		disciplina_atual_idx = 0
		
	lbl_disciplina.text = disciplinas[disciplina_atual_idx]
	_carregar_dados_simulados()

# Puxa os dados reais do banco
func _carregar_dados_simulados() -> void:
	lbl_total_alunos.text = "Carregando..."
	lbl_taxa_acerto.text = "..."
	lbl_total_jogadores.text = "..."
	
	# Limpa a tabela atual
	for child in tabela_dados.get_children():
		child.queue_free()
	
	# Busca o total de jogadores
	var res_jogadores = await DatabaseManager.request_async("/rest/v1/rankinggeral?select=player_name", HTTPClient.METHOD_GET)
	if res_jogadores.has("success") and res_jogadores["success"] and res_jogadores.has("data"):
		lbl_total_jogadores.text = str(res_jogadores["data"].size())
	else:
		lbl_total_jogadores.text = "Erro"
	
	# Mapeando a disciplina para o Andar correto do Banco
	var id_andar = 1
	var nome_disc = disciplinas[disciplina_atual_idx]
	if nome_disc == "Química": id_andar = 1
	elif nome_disc == "Física": id_andar = 2
	elif nome_disc == "Biologia": id_andar = 3
	
	# Busca as perguntas reais do Supabase para esse andar
	var query = "/rest/v1/perguntas?select=*&andar_id=eq." + str(id_andar)
	var res = await DatabaseManager.request_async(query, HTTPClient.METHOD_GET)
	
	# Busca os acertos/erros dos alunos para esse andar
	var res_resp = await DatabaseManager.request_async("/rest/v1/respostas?select=pergunta_id,acertou&andar_id=eq." + str(id_andar), HTTPClient.METHOD_GET)
	
	var mapa_resp = {}
	var total_acertos_geral = 0
	var total_tentativas_geral = 0
	if res_resp.has("success") and res_resp["success"] and res_resp.has("data") and res_resp["data"] is Array:
		for r in res_resp["data"]:
			var p_id = int(r.get("pergunta_id", -1))
			if not mapa_resp.has(p_id):
				mapa_resp[p_id] = {"acertos": 0, "erros": 0}
			
			total_tentativas_geral += 1
			if r.get("acertou", false):
				mapa_resp[p_id]["acertos"] += 1
				total_acertos_geral += 1
			else:
				mapa_resp[p_id]["erros"] += 1
	
	var table_data = []
	if res.has("success") and res["success"] and res.has("data") and res["data"] is Array:
		for q in res["data"]:
			var p_id = int(q.get("id", -1))
			var acc = 0
			var err = 0
			if mapa_resp.has(p_id):
				acc = mapa_resp[p_id]["acertos"]
				err = mapa_resp[p_id]["erros"]
			
			var total_q = acc + err
			var tx = 0
			if total_q > 0:
				tx = int(float(acc) / float(total_q) * 100)
			
			table_data.append({
				"pergunta": q.get("question", "Texto desconhecido"),
				"acertos": acc,
				"erros": err,
				"taxa": str(tx) + "%"
			})
		
		# Ordena da menor taxa para a maior (Mais Erradas primeiro)
		table_data.sort_custom(func(a, b): return int(a["taxa"]) < int(b["taxa"]))
		
		lbl_total_alunos.text = str(res["data"].size()) + " Perguntas"
		if total_tentativas_geral > 0:
			var taxa_geral = int(float(total_acertos_geral) / float(total_tentativas_geral) * 100)
			lbl_taxa_acerto.text = str(taxa_geral) + "% de Sucesso"
		else:
			lbl_taxa_acerto.text = "Sem Respostas"
	else:
		lbl_total_alunos.text = "Erro ao buscar"
		table_data = [
			{"pergunta": "Falha de conexão com o banco...", "acertos": 0, "erros": 0, "taxa": "0%"}
		]
	
	for item in table_data:
		var row = HBoxContainer.new()
		
		var lbl_p = Label.new()
		lbl_p.text = item["pergunta"]
		lbl_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_p.clip_text = true # Para não vazar tela se for longa
		row.add_child(lbl_p)
		
		var lbl_a = Label.new()
		lbl_a.text = "Acertos: " + str(item["acertos"])
		lbl_a.custom_minimum_size = Vector2(120, 0)
		lbl_a.add_theme_color_override("font_color", Color.GREEN)
		row.add_child(lbl_a)
		
		var lbl_e = Label.new()
		lbl_e.text = "Erros: " + str(item["erros"])
		lbl_e.custom_minimum_size = Vector2(120, 0)
		lbl_e.add_theme_color_override("font_color", Color.RED)
		row.add_child(lbl_e)
		
		var lbl_t = Label.new()
		lbl_t.text = item["taxa"]
		lbl_t.custom_minimum_size = Vector2(80, 0)
		row.add_child(lbl_t)
		
		tabela_dados.add_child(row)

# ----- SISTEMA DE RESET -----
var popup_reset: Control
var line_edit_senha: LineEdit

func _abrir_popup_reset() -> void:
	if popup_reset != null:
		popup_reset.queue_free()
		
	popup_reset = ColorRect.new()
	popup_reset.color = Color(0, 0, 0, 0.8)
	popup_reset.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(popup_reset)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 200)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	popup_reset.add_child(panel)
	
	var margem = MarginContainer.new()
	margem.add_theme_constant_override("margin_left", 20)
	margem.add_theme_constant_override("margin_right", 20)
	margem.add_theme_constant_override("margin_top", 20)
	margem.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margem)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margem.add_child(vbox)
	
	var lbl = Label.new()
	lbl.text = "ATENÇÃO!\nIsso apagará TODOS os jogadores, clãs e respostas.\nDigite a senha de admin para confirmar:"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color.RED)
	vbox.add_child(lbl)
	
	line_edit_senha = LineEdit.new()
	line_edit_senha.secret = true
	line_edit_senha.placeholder_text = "Senha..."
	vbox.add_child(line_edit_senha)
	
	var hbox_btns = HBoxContainer.new()
	hbox_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_btns.add_theme_constant_override("separation", 20)
	vbox.add_child(hbox_btns)
	
	var btn_cancelar = Button.new()
	btn_cancelar.text = "Cancelar"
	btn_cancelar.pressed.connect(func(): popup_reset.queue_free())
	hbox_btns.add_child(btn_cancelar)
	
	var btn_confirmar = Button.new()
	btn_confirmar.text = " APAGAR TUDO "
	btn_confirmar.add_theme_color_override("font_color", Color.RED)
	btn_confirmar.pressed.connect(_confirmar_reset)
	hbox_btns.add_child(btn_confirmar)

func _confirmar_reset() -> void:
	if line_edit_senha.text == "2026Vortex@ufc":
		print("Apagando dados do Supabase...")
		# Mostra mensagem de carregando no popup
		for child in line_edit_senha.get_parent().get_children():
			if child is HBoxContainer or child is LineEdit:
				child.visible = false
			elif child is Label:
				child.text = "Limpando banco de dados e caches locais, aguarde..."
				child.add_theme_color_override("font_color", Color.YELLOW)
		
		# Faz os DELETES no Supabase
		await DatabaseManager.request_async("/rest/v1/MembrosCla?player_name=not.is.null", HTTPClient.METHOD_DELETE)
		await DatabaseManager.request_async("/rest/v1/Clas?nome=not.is.null", HTTPClient.METHOD_DELETE)
		await DatabaseManager.request_async("/rest/v1/rankinggeral?player_name=not.is.null", HTTPClient.METHOD_DELETE)
		await DatabaseManager.request_async("/rest/v1/respostas?pergunta_id=not.is.null", HTTPClient.METHOD_DELETE)
		
		# Limpa arquivos de Cache Locais
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove("ranking.json")
			dir.remove("pending_sync.json")
			dir.remove("guest_config.json")
			dir.remove("progresso.json")
			
		# Zera variáveis na memória dos Managers
		RankingManager.ranking_geral.clear()
		RankingManager.ranking_diario.clear()
		RankingManager.ranking_semanal.clear()
		RankingManager.ranking_mensal.clear()
		RankingManager.ranking_atualizado.emit()
		
		ClanManager.clans_list.clear()
		ClanManager.clan_list_updated.emit()
			
		print("WIPE CONCLUÍDO!")
		popup_reset.queue_free()
		_carregar_dados_simulados() # recarrega a tabela limpa
	else:
		line_edit_senha.text = ""
		line_edit_senha.placeholder_text = "Senha incorreta!"

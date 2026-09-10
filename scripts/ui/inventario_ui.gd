extends CanvasLayer

@onready var grid_pocoes = $Control/MarginContainer/Panel/VBox/HBox/TabContainer/Pocoes/ScrollContainer/GridPocoes
@onready var grid_itens = $Control/MarginContainer/Panel/VBox/HBox/TabContainer/Itens/ScrollContainer/GridItens
@onready var grid_grimorio = $Control/MarginContainer/Panel/VBox/HBox/TabContainer/Grimorio/ScrollContainer/GridGrimorio

@onready var lbl_detalhe_titulo = $Control/MarginContainer/Panel/VBox/HBox/PainelDetalhes/Margin/VBox/DetalheTitulo
@onready var lbl_detalhe_desc = $Control/MarginContainer/Panel/VBox/HBox/PainelDetalhes/Margin/VBox/DetalheDesc
@onready var btn_acao = $Control/MarginContainer/Panel/VBox/HBox/PainelDetalhes/Margin/VBox/BtnAcao

@onready var painel_leitura = $Control/PainelLeitura
@onready var label_titulo_leitura = $Control/PainelLeitura/Margem/VBox/LabelTitulo
@onready var label_texto_leitura = $Control/PainelLeitura/Margem/VBox/LabelTexto
@onready var btn_fechar_leitura = $Control/PainelLeitura/Margem/VBox/BtnFecharLeitura
@onready var margem_leitura = $Control/PainelLeitura/Margem

var item_selecionado: Dictionary = {}
var paginas_leitura: Array[String] = []
var pagina_atual: int = 0
var btn_anterior: Button
var btn_proxima: Button

var tex_pocao = preload("res://assets/sprites/vida.png")
var tex_pergaminho = preload("res://assets/sprites/pergaminho.png")
var atlas_pergaminho_fechado: AtlasTexture
var atlas_pergaminho_aberto: AtlasTexture

var lbl_moedas_inv: Button
var box_descarte: HBoxContainer
var spin_descarte: SpinBox
var btn_descartar: Button

func _ready() -> void:
	visible = false
	painel_leitura.visible = false
	btn_fechar_leitura.pressed.connect(_fechar_leitura)
	
	btn_acao.pressed.connect(_on_btn_acao_pressionado)
	
	box_descarte = HBoxContainer.new()
	box_descarte.alignment = BoxContainer.ALIGNMENT_CENTER
	
	spin_descarte = SpinBox.new()
	spin_descarte.min_value = 1
	spin_descarte.max_value = 1
	box_descarte.add_child(spin_descarte)
	
	btn_descartar = Button.new()
	btn_descartar.text = "JOGAR FORA"
	btn_descartar.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	btn_descartar.pressed.connect(_on_btn_descartar_pressionado)
	box_descarte.add_child(btn_descartar)
	
	btn_acao.get_parent().add_child(box_descarte)
	
	_limpar_detalhes()
	
	atlas_pergaminho_fechado = AtlasTexture.new()
	atlas_pergaminho_fechado.atlas = tex_pergaminho
	atlas_pergaminho_fechado.region = Rect2(0, 0, 64, 64)
	
	atlas_pergaminho_aberto = AtlasTexture.new()
	atlas_pergaminho_aberto.atlas = tex_pergaminho
	atlas_pergaminho_aberto.region = Rect2(64, 0, 64, 64)
	
	# Adiciona o fundo de pergaminho aberto dinamicamente
	var fundo_pergaminho = TextureRect.new()
	fundo_pergaminho.texture = atlas_pergaminho_aberto
	fundo_pergaminho.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fundo_pergaminho.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fundo_pergaminho.modulate = Color(1.0, 1.0, 1.0, 0.4) # Retorna a transparência que você gostou
	fundo_pergaminho.set_anchors_preset(Control.PRESET_FULL_RECT)
	painel_leitura.add_child(fundo_pergaminho)
	painel_leitura.move_child(fundo_pergaminho, 1) # Logo acima do ColorRect de fundo escuro
	
	# Ajusta as margens para o texto ficar DENTRO da parte clara do pergaminho desenhado
	margem_leitura.add_theme_constant_override("margin_left", 380)
	margem_leitura.add_theme_constant_override("margin_right", 380)
	margem_leitura.add_theme_constant_override("margin_top", 170)
	margem_leitura.add_theme_constant_override("margin_bottom", 170)
	
	# Cria botões de paginação dinamicamente
	var hbox_nav = HBoxContainer.new()
	hbox_nav.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_nav.add_theme_constant_override("separation", 20)
	
	btn_anterior = Button.new()
	btn_anterior.text = " < Anterior "
	btn_anterior.pressed.connect(_pagina_anterior)
	
	btn_proxima = Button.new()
	btn_proxima.text = " Próxima > "
	btn_proxima.pressed.connect(_pagina_proxima)
	
	var vbox = btn_fechar_leitura.get_parent()
	vbox.remove_child(btn_fechar_leitura)
	
	hbox_nav.add_child(btn_anterior)
	hbox_nav.add_child(btn_fechar_leitura)
	hbox_nav.add_child(btn_proxima)
	
	vbox.add_child(hbox_nav)
	
	# faz o menu funcionar com jogo pausado
	process_mode = Node.PROCESS_MODE_ALWAYS 
	add_to_group("inventario_ui") 
	
	# Adiciona o label de moedas como botão para ser selecionável
	lbl_moedas_inv = Button.new()
	lbl_moedas_inv.flat = true
	lbl_moedas_inv.add_theme_color_override("font_color", Color(1, 0.8, 0.2)) # Dourado
	lbl_moedas_inv.add_theme_color_override("font_hover_color", Color(1, 0.9, 0.5))
	lbl_moedas_inv.add_theme_font_size_override("font_size", 22)
	lbl_moedas_inv.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_moedas_inv.pressed.connect(func(): _selecionar_item({"nome": "Moedas", "qtd": PlayerStats.moedas}, "moeda", -1))
	
	var painel_principal = $Control/MarginContainer/Panel
	painel_principal.add_child(lbl_moedas_inv)
	lbl_moedas_inv.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	lbl_moedas_inv.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	lbl_moedas_inv.offset_top = 25
	lbl_moedas_inv.offset_right = -35

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("inventory"):
		_toggle_inventario()

func _toggle_inventario() -> void:
	var ui_pergaminho = get_tree().get_first_node_in_group("parchment_ui")
	if ui_pergaminho and ui_pergaminho.visible:
		if ui_pergaminho.has_method("_fechar_pergaminho"):
			ui_pergaminho._fechar_pergaminho()
		else:
			ui_pergaminho.hide()

	visible = !visible
	
	var em_batalha = (QuizManager.ui_instancia != null and QuizManager.ui_instancia.visible)
	if not em_batalha:
		get_tree().paused = visible # congela o jogo
		
	if visible:
		painel_leitura.visible = false
		_limpar_detalhes()
		_atualizar_listas()
		PlayerStats.salvar()

func _on_btn_descartar_pressionado() -> void:
	if item_selecionado.is_empty(): return
	
	var tipo = item_selecionado["tipo"]
	var idx = item_selecionado["index"]
	var qtd_descarte = int(spin_descarte.value)
	
	if tipo == "pocao":
		var po = PlayerStats.pocoes[idx]
		po["qtd"] -= qtd_descarte
		if po["qtd"] <= 0:
			PlayerStats.pocoes.remove_at(idx)
	elif tipo == "item":
		if item_selecionado["nome"] == "Chave de Porta":
			PlayerStats.chaves = max(0, PlayerStats.chaves - qtd_descarte)
		else:
			PlayerStats.itens.remove_at(idx)
	elif tipo == "grimorio":
		PlayerStats.grimorio.remove_at(idx)
	elif tipo == "moeda":
		if PlayerStats.moedas > 0:
			PlayerStats.moedas = max(0, PlayerStats.moedas - qtd_descarte)
	
	_atualizar_listas()
	_limpar_detalhes()
	PlayerStats.salvar()

func _atualizar_listas() -> void:
	_limpar_filhos(grid_pocoes)
	_limpar_filhos(grid_itens)
	_limpar_filhos(grid_grimorio)
	
	if get_node_or_null("/root/PlayerStats") and lbl_moedas_inv:
		lbl_moedas_inv.text = "Moedas: " + str(PlayerStats.moedas)
	
	# carrega as pocoes
	if PlayerStats.pocoes.is_empty():
		_add_label_vazia(grid_pocoes, "Sua bolsa está sem poções.")
	else:
		for i in range(PlayerStats.pocoes.size()):
			var po = PlayerStats.pocoes[i]
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(100, 100)
			btn.text = po["nome"] + "\n(x" + str(po["qtd"]) + ")"
			btn.icon = tex_pocao
			btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			btn.expand_icon = true
			# quando clica, mostra os detalhes na direita
			btn.pressed.connect(func(): _selecionar_item(po, "pocao", i))
			grid_pocoes.add_child(btn)
			
	# carrega os itens
	var tem_qualquer_item = false
	
	# Exibe as chaves separadamente se houver
	if get_node_or_null("/root/PlayerStats") and PlayerStats.chaves > 0:
		tem_qualquer_item = true
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(100, 100)
		btn.text = "Chave de Porta\n(x" + str(PlayerStats.chaves) + ")"
		
		var icone = load("res://assets/sprites/ui/icon_key_transparent.png")
		if icone:
			btn.icon = icone
			btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			btn.expand_icon = true
			
		var dic_chave = {"nome": "Chave de Porta", "descricao": "Uma chave dourada brilhante capaz de abrir portas mágicas seladas."}
		btn.pressed.connect(func(): _selecionar_item(dic_chave, "item", -1))
		grid_itens.add_child(btn)
		
	for i in range(PlayerStats.itens.size()):
		tem_qualquer_item = true
		var item = PlayerStats.itens[i]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(100, 100)
		btn.text = item["nome"]
		
		if item["nome"] == "Livro de Fórmulas":
			var icone = load("res://assets/sprites/ui/item_livro_formulas.png")
			if icone:
				btn.icon = icone
				btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
				btn.expand_icon = true
		elif item["nome"] == "Fragmento de Gelatina":
			var icone = load("res://assets/sprites/ui/item_fragmento_gelatina.png")
			if icone:
				btn.icon = icone
				btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
				btn.expand_icon = true
		elif item["nome"] == "Bateria Elétrica":
			var icone = load("res://assets/sprites/ui/item_bateria.png")
			if icone:
				btn.icon = icone
				btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
				btn.expand_icon = true
		elif item["nome"] == "Fragmento de Chip":
			var icone = load("res://assets/sprites/ui/item_chip.png")
			if icone:
				btn.icon = icone
				btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
				btn.expand_icon = true
				
		btn.pressed.connect(func(): _selecionar_item(item, "item", i))
		grid_itens.add_child(btn)
		
	if not tem_qualquer_item:
		_add_label_vazia(grid_itens, "Você não tem itens importantes.")
			
	# carrega as paginas do grimorio
	if PlayerStats.grimorio.is_empty():
		_add_label_vazia(grid_grimorio, "O grimório está em branco.")
	else:
		for i in range(PlayerStats.grimorio.size()):
			var doc = PlayerStats.grimorio[i]
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(100, 100)
			btn.text = doc["titulo"]
			btn.icon = atlas_pergaminho_fechado
			btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			btn.expand_icon = true
			btn.pressed.connect(func(): _selecionar_item(doc, "grimorio", i))
			grid_grimorio.add_child(btn)

func _limpar_filhos(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()

func _add_label_vazia(node: Node, texto: String) -> void:
	var lbl = Label.new()
	lbl.text = texto
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.add_child(lbl)

func _limpar_detalhes() -> void:
	lbl_detalhe_titulo.text = "Selecione um item"
	lbl_detalhe_desc.text = "Detalhes aparecerão aqui."
	btn_acao.visible = false
	if box_descarte: box_descarte.visible = false
	item_selecionado = {}

func _selecionar_item(item: Dictionary, tipo: String, index: int) -> void:
	item_selecionado = item
	item_selecionado["tipo"] = tipo
	item_selecionado["index"] = index
	
	if tipo == "pocao":
		lbl_detalhe_titulo.text = item["nome"]
		lbl_detalhe_desc.text = item.get("desc", "Cura " + str(item.get("cura", 0)) + " PV.\nQuantidade: " + str(item["qtd"]))
		btn_acao.text = "USAR"
		btn_acao.visible = true
		box_descarte.visible = true
		spin_descarte.max_value = max(1, item["qtd"])
	elif tipo == "item":
		lbl_detalhe_titulo.text = item["nome"]
		lbl_detalhe_desc.text = item.get("descricao", "Um item misterioso.")
		btn_acao.visible = false
		box_descarte.visible = true
		spin_descarte.max_value = max(1, PlayerStats.chaves) if item["nome"] == "Chave de Porta" else 1
	elif tipo == "grimorio":
		lbl_detalhe_titulo.text = item["titulo"]
		lbl_detalhe_desc.text = "Um pedaço de conhecimento.\nLeia para desvendar."
		btn_acao.text = "LER"
		btn_acao.visible = true
		box_descarte.visible = true
		spin_descarte.max_value = 1
	elif tipo == "moeda":
		lbl_detalhe_titulo.text = "Moedas"
		lbl_detalhe_desc.text = "Dinheiro utilizado para comprar itens e poções no Mercador.\nTotal: " + str(PlayerStats.moedas)
		btn_acao.visible = false
		box_descarte.visible = true
		spin_descarte.max_value = max(1, PlayerStats.moedas)
	
	spin_descarte.value = 1

func _on_btn_acao_pressionado() -> void:
	if item_selecionado.is_empty(): return
	
	var tipo = item_selecionado["tipo"]
	var idx = item_selecionado["index"]
	
	if tipo == "pocao":
		if PlayerStats.vida_atual_jogador >= PlayerStats.vida_maxima_jogador:
			lbl_detalhe_desc.text = "Sua vida já está cheia!\nNão desperdice magia."
			return
			
		var po = PlayerStats.pocoes[idx]
		if po["qtd"] > 0:
			PlayerStats.curar_vida(po["cura"])
			po["qtd"] -= 1
			if po["qtd"] <= 0:
				PlayerStats.pocoes.remove_at(idx)
				_limpar_detalhes()
			else:
				# atualiza a tela
				_selecionar_item(po, "pocao", idx)
			_atualizar_listas()
	elif tipo == "grimorio":
		var doc = PlayerStats.grimorio[idx]
		if doc.has("paginas") and doc["paginas"] is Array and doc["paginas"].size() > 0:
			var paginas_cast: Array[String] = []
			for p in doc["paginas"]:
				paginas_cast.append(str(p))
			var ui = get_tree().get_first_node_in_group("parchment_ui")
			if ui == null and get_tree().current_scene:
				ui = get_tree().current_scene.find_child("ParchmentUI", true, false)
			if ui and ui.has_method("abrir_pergaminho"):
				visible = false
				get_tree().paused = false
				ui.abrir_pergaminho(paginas_cast, null)
			else:
				_abrir_leitura(doc["titulo"], doc["texto"])
		else:
			_abrir_leitura(doc["titulo"], doc["texto"])


func _abrir_leitura(titulo: String, texto: String) -> void:
	label_titulo_leitura.text = titulo
	
	# Divide o texto em páginas usando "|" ou quebras grandes se necessário
	# Caso os designers queiram quebrar página manualmente, eles usarão "|"
	if texto.contains("|"):
		paginas_leitura = Array(texto.split("|", false))
	else:
		# Se não tiver separador manual, coloca tudo na página 1 (no futuro pode usar lógica de limite de chars)
		paginas_leitura = [texto]
		
	pagina_atual = 0
	_atualizar_pagina()
	painel_leitura.visible = true

func _atualizar_pagina() -> void:
	if paginas_leitura.is_empty(): return
	
	label_texto_leitura.text = paginas_leitura[pagina_atual].strip_edges()
	
	btn_anterior.visible = (pagina_atual > 0)
	btn_proxima.visible = (pagina_atual < paginas_leitura.size() - 1)

func _pagina_anterior() -> void:
	if pagina_atual > 0:
		pagina_atual -= 1
		_atualizar_pagina()

func _pagina_proxima() -> void:
	if pagina_atual < paginas_leitura.size() - 1:
		pagina_atual += 1
		_atualizar_pagina()

func _fechar_leitura() -> void:
	painel_leitura.visible = false

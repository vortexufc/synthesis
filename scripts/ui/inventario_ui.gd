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

func _ready() -> void:
	visible = false
	painel_leitura.visible = false
	btn_fechar_leitura.pressed.connect(_fechar_leitura)
	
	btn_acao.pressed.connect(_on_btn_acao_pressionado)
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

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("inventory"):
		_toggle_inventario()

func _toggle_inventario() -> void:
	visible = !visible
	
	var em_batalha = (QuizManager.ui_instancia != null and QuizManager.ui_instancia.visible)
	if not em_batalha:
		get_tree().paused = visible # congela o jogo
		
	if visible:
		painel_leitura.visible = false
		_limpar_detalhes()
		_atualizar_listas()

func _atualizar_listas() -> void:
	_limpar_filhos(grid_pocoes)
	_limpar_filhos(grid_itens)
	_limpar_filhos(grid_grimorio)
	
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
	if PlayerStats.itens.is_empty():
		_add_label_vazia(grid_itens, "Você não tem itens importantes.")
	else:
		for i in range(PlayerStats.itens.size()):
			var item = PlayerStats.itens[i]
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(100, 100)
			btn.text = item["nome"]
			btn.pressed.connect(func(): _selecionar_item(item, "item", i))
			grid_itens.add_child(btn)
			
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
	elif tipo == "item":
		lbl_detalhe_titulo.text = item["nome"]
		lbl_detalhe_desc.text = item.get("descricao", "Um item misterioso.")
		btn_acao.visible = false
	elif tipo == "grimorio":
		lbl_detalhe_titulo.text = item["titulo"]
		lbl_detalhe_desc.text = "Um pedaço de conhecimento.\nLeia para desvendar."
		btn_acao.text = "LER"
		btn_acao.visible = true

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

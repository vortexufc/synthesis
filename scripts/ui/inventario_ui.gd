extends CanvasLayer

## Interface Profissional da Bolsa Arcana (Inventário RPG)
## Apresenta cartas de itens com slots moldurados, pedestais arcanos de detalhes e badges dourados.

@onready var tab_container: TabContainer = $Control/MarginContainer/Panel/VBox/HBox/MarginTabs/TabContainer
@onready var grid_pocoes: HFlowContainer = $Control/MarginContainer/Panel/VBox/HBox/MarginTabs/TabContainer/Pocoes/ScrollContainer/GridPocoes
@onready var grid_itens: HFlowContainer = $Control/MarginContainer/Panel/VBox/HBox/MarginTabs/TabContainer/Itens/ScrollContainer/GridItens
@onready var grid_grimorio: HFlowContainer = $Control/MarginContainer/Panel/VBox/HBox/MarginTabs/TabContainer/Grimorio/ScrollContainer/GridGrimorio

@onready var pedestal_icone: PanelContainer = $Control/MarginContainer/Panel/VBox/HBox/MarginDetalhes/PainelDetalhes/Margin/VBox/PedestalIcone
@onready var img_detalhe_icone: TextureRect = $Control/MarginContainer/Panel/VBox/HBox/MarginDetalhes/PainelDetalhes/Margin/VBox/PedestalIcone/DetalheIcone
@onready var lbl_detalhe_titulo: Label = $Control/MarginContainer/Panel/VBox/HBox/MarginDetalhes/PainelDetalhes/Margin/VBox/DetalheTitulo
@onready var lbl_detalhe_desc: Label = $Control/MarginContainer/Panel/VBox/HBox/MarginDetalhes/PainelDetalhes/Margin/VBox/ScrollDesc/DetalheDesc
@onready var btn_acao: Button = $Control/MarginContainer/Panel/VBox/HBox/MarginDetalhes/PainelDetalhes/Margin/VBox/BtnAcao

@onready var painel_leitura: Panel = $Control/PainelLeitura
@onready var label_titulo_leitura: Label = $Control/PainelLeitura/Margem/VBox/LabelTitulo
@onready var label_texto_leitura: Label = $Control/PainelLeitura/Margem/VBox/LabelTexto
@onready var btn_fechar_leitura: Button = $Control/PainelLeitura/Margem/VBox/BtnFecharLeitura
@onready var margem_leitura: MarginContainer = $Control/PainelLeitura/Margem

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

var _style_slot_normal: StyleBoxFlat
var _style_slot_hover: StyleBoxFlat
var _style_slot_selected: StyleBoxFlat

func _ready() -> void:
	visible = false
	painel_leitura.visible = false
	btn_fechar_leitura.pressed.connect(_fechar_leitura)
	btn_acao.pressed.connect(_on_btn_acao_pressionado)
	
	_criar_estilos_slots()
	
	# Nomes estilizados das Abas
	if tab_container:
		tab_container.set_tab_title(0, " 🧪 Poções ")
		tab_container.set_tab_title(1, " 🗝️ Relíquias ")
		tab_container.set_tab_title(2, " 📜 Grimório ")

	# Configura a barra de descarte
	box_descarte = HBoxContainer.new()
	box_descarte.alignment = BoxContainer.ALIGNMENT_CENTER
	box_descarte.add_theme_constant_override("separation", 10)
	
	spin_descarte = SpinBox.new()
	spin_descarte.min_value = 1
	spin_descarte.max_value = 1
	spin_descarte.custom_minimum_size = Vector2(65, 32)
	box_descarte.add_child(spin_descarte)
	
	btn_descartar = Button.new()
	btn_descartar.text = "✕ DESCARTAR"
	btn_descartar.custom_minimum_size = Vector2(130, 32)
	
	var sb_descarte = StyleBoxFlat.new()
	sb_descarte.bg_color = Color(0.25, 0.08, 0.08, 0.95)
	sb_descarte.border_width_left = 1
	sb_descarte.border_width_top = 1
	sb_descarte.border_width_right = 1
	sb_descarte.border_width_bottom = 1
	sb_descarte.border_color = Color(0.85, 0.3, 0.3, 0.8)
	sb_descarte.corner_radius_top_left = 6
	sb_descarte.corner_radius_top_right = 6
	sb_descarte.corner_radius_bottom_right = 6
	sb_descarte.corner_radius_bottom_left = 6
	btn_descartar.add_theme_stylebox_override("normal", sb_descarte)
	btn_descartar.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	btn_descartar.add_theme_font_size_override("font_size", 9)
	btn_descartar.pressed.connect(_on_btn_descartar_pressionado)
	box_descarte.add_child(btn_descartar)
	
	btn_acao.get_parent().add_child(box_descarte)
	
	_limpar_detalhes()
	
	atlas_pergaminho_fechado = AtlasTexture.new()
	atlas_pergaminho_fechado.atlas = tex_pergaminho
	atlas_pergaminho_fechado.region = Rect2(0, 0, 23, 64)
	
	atlas_pergaminho_aberto = AtlasTexture.new()
	atlas_pergaminho_aberto.atlas = tex_pergaminho
	atlas_pergaminho_aberto.region = Rect2(64, 0, 64, 64)
	
	# Fundo de pergaminho aberto dinâmico para leitura
	var fundo_pergaminho = TextureRect.new()
	fundo_pergaminho.texture = atlas_pergaminho_aberto
	fundo_pergaminho.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fundo_pergaminho.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fundo_pergaminho.modulate = Color(1.0, 1.0, 1.0, 0.45)
	fundo_pergaminho.set_anchors_preset(Control.PRESET_FULL_RECT)
	painel_leitura.add_child(fundo_pergaminho)
	painel_leitura.move_child(fundo_pergaminho, 1)
	
	margem_leitura.add_theme_constant_override("margin_left", 380)
	margem_leitura.add_theme_constant_override("margin_right", 380)
	margem_leitura.add_theme_constant_override("margin_top", 170)
	margem_leitura.add_theme_constant_override("margin_bottom", 170)
	
	# Botões de paginação da leitura
	var hbox_nav = HBoxContainer.new()
	hbox_nav.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_nav.add_theme_constant_override("separation", 20)
	
	btn_anterior = Button.new()
	btn_anterior.text = " ◀ Anterior "
	btn_anterior.pressed.connect(_pagina_anterior)
	
	btn_proxima = Button.new()
	btn_proxima.text = " Próxima ▶ "
	btn_proxima.pressed.connect(_pagina_proxima)
	
	var vbox = btn_fechar_leitura.get_parent()
	vbox.remove_child(btn_fechar_leitura)
	
	hbox_nav.add_child(btn_anterior)
	hbox_nav.add_child(btn_fechar_leitura)
	hbox_nav.add_child(btn_proxima)
	vbox.add_child(hbox_nav)
	
	process_mode = Node.PROCESS_MODE_ALWAYS 
	add_to_group("inventario_ui") 
	
	# Badge Elegante de Moedas (Cofre Dourado)
	lbl_moedas_inv = Button.new()
	var sb_moeda = StyleBoxFlat.new()
	sb_moeda.bg_color = Color(0.14, 0.09, 0.20, 0.95)
	sb_moeda.border_width_left = 2
	sb_moeda.border_width_top = 2
	sb_moeda.border_width_right = 2
	sb_moeda.border_width_bottom = 2
	sb_moeda.border_color = Color(0.90, 0.72, 0.28, 1.0)
	sb_moeda.corner_radius_top_left = 10
	sb_moeda.corner_radius_top_right = 10
	sb_moeda.corner_radius_bottom_right = 10
	sb_moeda.corner_radius_bottom_left = 10
	sb_moeda.content_margin_left = 14
	sb_moeda.content_margin_right = 14
	sb_moeda.content_margin_top = 6
	sb_moeda.content_margin_bottom = 6
	
	var sb_moeda_hover = sb_moeda.duplicate() as StyleBoxFlat
	sb_moeda_hover.bg_color = Color(0.22, 0.14, 0.32, 1.0)
	sb_moeda_hover.border_color = Color(1.0, 0.88, 0.45, 1.0)
	sb_moeda_hover.shadow_size = 6
	sb_moeda_hover.shadow_color = Color(0.9, 0.7, 0.2, 0.35)
	
	lbl_moedas_inv.add_theme_stylebox_override("normal", sb_moeda)
	lbl_moedas_inv.add_theme_stylebox_override("hover", sb_moeda_hover)
	lbl_moedas_inv.add_theme_stylebox_override("pressed", sb_moeda)
	lbl_moedas_inv.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	lbl_moedas_inv.add_theme_font_size_override("font_size", 11)
	lbl_moedas_inv.pressed.connect(func(): _selecionar_item({"nome": "Moedas de Ouro", "qtd": PlayerStats.moedas}, "moeda", -1))
	
	var painel_principal = $Control/MarginContainer/Panel
	painel_principal.add_child(lbl_moedas_inv)
	lbl_moedas_inv.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	lbl_moedas_inv.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	lbl_moedas_inv.offset_top = 16
	lbl_moedas_inv.offset_right = -24

func _criar_estilos_slots() -> void:
	# Normal: Fundo recessed obsidian com moldura metálica
	_style_slot_normal = StyleBoxFlat.new()
	_style_slot_normal.bg_color = Color(0.12, 0.08, 0.18, 0.95)
	_style_slot_normal.border_width_left = 2
	_style_slot_normal.border_width_top = 2
	_style_slot_normal.border_width_right = 2
	_style_slot_normal.border_width_bottom = 2
	_style_slot_normal.border_color = Color(0.38, 0.28, 0.50, 0.9)
	_style_slot_normal.corner_radius_top_left = 8
	_style_slot_normal.corner_radius_top_right = 8
	_style_slot_normal.corner_radius_bottom_right = 8
	_style_slot_normal.corner_radius_bottom_left = 8

	# Hover: Iluminação violeta com borda dourada acentuada
	_style_slot_hover = StyleBoxFlat.new()
	_style_slot_hover.bg_color = Color(0.24, 0.16, 0.36, 1.0)
	_style_slot_hover.border_width_left = 2
	_style_slot_hover.border_width_top = 2
	_style_slot_hover.border_width_right = 2
	_style_slot_hover.border_width_bottom = 2
	_style_slot_hover.border_color = Color(0.95, 0.78, 0.32, 1.0)
	_style_slot_hover.corner_radius_top_left = 8
	_style_slot_hover.corner_radius_top_right = 8
	_style_slot_hover.corner_radius_bottom_right = 8
	_style_slot_hover.corner_radius_bottom_left = 8
	_style_slot_hover.shadow_size = 6
	_style_slot_hover.shadow_color = Color(0.95, 0.78, 0.32, 0.3)

	# Selected: Ouro brilhante
	_style_slot_selected = StyleBoxFlat.new()
	_style_slot_selected.bg_color = Color(0.30, 0.20, 0.44, 1.0)
	_style_slot_selected.border_width_left = 2
	_style_slot_selected.border_width_top = 2
	_style_slot_selected.border_width_right = 2
	_style_slot_selected.border_width_bottom = 2
	_style_slot_selected.border_color = Color(1.0, 0.88, 0.45, 1.0)
	_style_slot_selected.corner_radius_top_left = 8
	_style_slot_selected.corner_radius_top_right = 8
	_style_slot_selected.corner_radius_bottom_right = 8
	_style_slot_selected.corner_radius_bottom_left = 8
	_style_slot_selected.shadow_size = 8
	_style_slot_selected.shadow_color = Color(1.0, 0.88, 0.45, 0.45)

var _tween_anim_inv: Tween = null

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

	var em_batalha = (QuizManager.ui_instancia != null and QuizManager.ui_instancia.visible)
	var painel = $Control/MarginContainer
	
	if _tween_anim_inv and _tween_anim_inv.is_running():
		_tween_anim_inv.kill()

	if visible:
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("ui-2")
			
		if painel:
			_tween_anim_inv = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			_tween_anim_inv.tween_property(painel, "scale", Vector2(0.94, 0.94), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			_tween_anim_inv.parallel().tween_property(painel, "modulate:a", 0.0, 0.12)
			_tween_anim_inv.tween_callback(func():
				visible = false
				if not em_batalha:
					get_tree().paused = false
			)
		else:
			visible = false
			if not em_batalha:
				get_tree().paused = false
	else:
		visible = true
		if not em_batalha:
			get_tree().paused = true
			
		painel_leitura.visible = false
		_limpar_detalhes()
		_atualizar_listas()
		PlayerStats.salvar()
		
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("ui_1")
			
		if painel:
			painel.pivot_offset = painel.size / 2.0
			painel.scale = Vector2(0.92, 0.92)
			painel.modulate.a = 0.0
			_tween_anim_inv = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			_tween_anim_inv.tween_property(painel, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_tween_anim_inv.parallel().tween_property(painel, "modulate:a", 1.0, 0.16)

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
			var removidos = 0
			for k in range(PlayerStats.itens.size() - 1, -1, -1):
				if PlayerStats.itens[k]["nome"] == item_selecionado["nome"]:
					PlayerStats.itens.remove_at(k)
					removidos += 1
					if removidos >= qtd_descarte:
						break
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
		lbl_moedas_inv.text = " 🪙  %d Moedas " % PlayerStats.moedas
	
	# 1. Carrega Poções
	if PlayerStats.pocoes.is_empty():
		_add_mensagem_vazia(grid_pocoes, "🧪", "Nenhuma Poção na Bolsa", "Visite o Mercador ou explore as salas para coletar novos elixires.")
	else:
		for i in range(PlayerStats.pocoes.size()):
			var po = PlayerStats.pocoes[i]
			var card = _criar_slot_card(tex_pocao, po["nome"], po["qtd"], func(): _selecionar_item(po, "pocao", i))
			grid_pocoes.add_child(card)
			
	# 2. Carrega Relíquias e Itens Chave
	var tem_qualquer_item = false
	
	if get_node_or_null("/root/PlayerStats") and PlayerStats.chaves > 0:
		tem_qualquer_item = true
		var icone_chave = load("res://assets/sprites/ui/icon_key_transparent.png")
		var dic_chave = {"nome": "Chave de Porta", "descricao": "Uma chave dourada brilhante capaz de abrir portas mágicas seladas."}
		var card = _criar_slot_card(icone_chave, "Chave de Porta", PlayerStats.chaves, func(): _selecionar_item(dic_chave, "item", -1))
		grid_itens.add_child(card)
		
	# Agrupa itens repetidos por nome
	var itens_agrupados: Dictionary = {}
	for it in PlayerStats.itens:
		var nome = it.get("nome", "Item Desconhecido")
		if not itens_agrupados.has(nome):
			itens_agrupados[nome] = {
				"item_base": it,
				"qtd": 0,
				"cores": []
			}
		itens_agrupados[nome]["qtd"] += 1
		if it.has("cor"):
			itens_agrupados[nome]["cores"].append(it["cor"])
			
	for nome in itens_agrupados.keys():
		tem_qualquer_item = true
		var grupo = itens_agrupados[nome]
		var item_base = grupo["item_base"]
		var qtd = grupo["qtd"]
		var icone: Texture2D = null
		
		if nome == "Livro de Fórmulas":
			icone = load("res://assets/sprites/ui/item_livro_formulas.png")
		elif nome == "Fragmento de Gelatina":
			var cores = grupo["cores"]
			var todas_mesma_cor = true
			for c in cores:
				if c != cores[0]:
					todas_mesma_cor = false
					break
			if cores.size() > 1 and not todas_mesma_cor:
				icone = load("res://assets/sprites/ui/item_fragmento_gelatina_mercado.png")
			else:
				var cor_destaque = cores[0] if cores.size() > 0 else "azul"
				icone = _obter_icone_gelatina(cor_destaque)
		elif nome == "Bateria Elétrica":
			icone = load("res://assets/sprites/ui/item_bateria.png")
		elif nome == "Fragmento de Chip":
			icone = load("res://assets/sprites/ui/item_chip.png")
			
		var item_display = item_base.duplicate()
		item_display["qtd"] = qtd
		if nome == "Fragmento de Gelatina":
			var cores = grupo["cores"]
			var todas_mesma_cor = true
			for c in cores:
				if c != cores[0]:
					todas_mesma_cor = false
					break
			if cores.size() > 1 and not todas_mesma_cor:
				item_display["cores_mistas"] = true
			else:
				item_display["cor"] = cores[0] if cores.size() > 0 else "azul"
		var card = _criar_slot_card(icone, nome, qtd, func(): _selecionar_item(item_display, "item", -1))
		grid_itens.add_child(card)
		
	if not tem_qualquer_item:
		_add_mensagem_vazia(grid_itens, "🗝️", "Sem Relíquias no Momento", "Resolva enigmas ou derrote guardiões para obter artefatos e chaves.")
			
	# 3. Carrega Páginas do Grimório
	if PlayerStats.grimorio.is_empty():
		_add_mensagem_vazia(grid_grimorio, "📜", "Grimório em Branco", "Descubra pergaminhos antigos pelas masmorras para registrar fórmulas.")
	else:
		for i in range(PlayerStats.grimorio.size()):
			var doc = PlayerStats.grimorio[i]
			var icone_doc: Texture2D = atlas_pergaminho_fechado
			if doc is Dictionary and doc.get("tipo_codice") == "mural":
				var tex_livro = load("res://assets/sprites/ui/item_livro_formulas.png") as Texture2D
				if tex_livro:
					icone_doc = tex_livro
			var card = _criar_slot_card(icone_doc, doc["titulo"], 1, func(): _selecionar_item(doc, "grimorio", i))
			grid_grimorio.add_child(card)

## Cria um Card de Slot de Inventário com moldura de alta qualidade, ícone e badge de quantidade
func _criar_slot_card(icone: Texture2D, nome: String, qtd: int, callback: Callable) -> Control:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(118, 118)
	btn.add_theme_stylebox_override("normal", _style_slot_normal)
	btn.add_theme_stylebox_override("hover", _style_slot_hover)
	btn.add_theme_stylebox_override("pressed", _style_slot_selected)
	btn.focus_mode = Control.FOCUS_NONE
	btn.clip_contents = true
	
	# MarginContainer interno para acolchoamento e alinhamento perfeito
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)
	
	# Ícone Central
	var tex_rect = TextureRect.new()
	tex_rect.texture = icone
	tex_rect.custom_minimum_size = Vector2(46, 46)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(tex_rect)
	
	# Rótulo com nome completo do item (com quebra natural de palavras, sem cortar com ..)
	var lbl_nome = Label.new()
	lbl_nome.text = nome
	lbl_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_nome.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_nome.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lbl_nome.add_theme_font_size_override("font_size", 8)
	lbl_nome.add_theme_constant_override("line_spacing", 2)
	lbl_nome.add_theme_color_override("font_color", Color(0.90, 0.86, 0.96))
	lbl_nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(lbl_nome)
	
	# Badge de Quantidade organizado no canto inferior direito do bloco
	if qtd > 1:
		var badge_panel = PanelContainer.new()
		var sb_badge = StyleBoxFlat.new()
		sb_badge.bg_color = Color(0.06, 0.04, 0.10, 0.90)
		sb_badge.border_width_left = 1
		sb_badge.border_width_top = 1
		sb_badge.border_width_right = 1
		sb_badge.border_width_bottom = 1
		sb_badge.border_color = Color(0.95, 0.78, 0.32, 0.95)
		sb_badge.corner_radius_top_left = 4
		sb_badge.corner_radius_top_right = 4
		sb_badge.corner_radius_bottom_right = 4
		sb_badge.corner_radius_bottom_left = 4
		sb_badge.content_margin_left = 5
		sb_badge.content_margin_right = 5
		sb_badge.content_margin_top = 2
		sb_badge.content_margin_bottom = 2
		badge_panel.add_theme_stylebox_override("panel", sb_badge)
		badge_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		badge_panel.offset_left = -34
		badge_panel.offset_top = -22
		badge_panel.offset_right = -4
		badge_panel.offset_bottom = -4
		badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var lbl_qtd = Label.new()
		lbl_qtd.text = "x" + str(qtd)
		lbl_qtd.add_theme_font_size_override("font_size", 8)
		lbl_qtd.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
		lbl_qtd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_qtd.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge_panel.add_child(lbl_qtd)
		btn.add_child(badge_panel)
		
	# Efeito dinâmico de clique e foco
	btn.pressed.connect(func():
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("ui-1")
		callback.call()
	)
	
	# Animação suave ao passar o mouse
	btn.mouse_entered.connect(func():
		var tw = btn.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(btn, "scale", Vector2(1.03, 1.03), 0.08)
	)
	btn.mouse_exited.connect(func():
		var tw = btn.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(btn, "scale", Vector2.ONE, 0.08)
	)
	
	return btn

func _add_mensagem_vazia(node: Node, icone_emoji: String, titulo: String, dica: String) -> void:
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	
	var lbl_ico = Label.new()
	lbl_ico.text = icone_emoji
	lbl_ico.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_ico.add_theme_font_size_override("font_size", 28)
	vbox.add_child(lbl_ico)
	
	var lbl_tit = Label.new()
	lbl_tit.text = titulo
	lbl_tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_tit.add_theme_font_size_override("font_size", 12)
	lbl_tit.add_theme_color_override("font_color", Color(0.85, 0.72, 0.35))
	vbox.add_child(lbl_tit)
	
	var lbl_dica = Label.new()
	lbl_dica.text = dica
	lbl_dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_dica.add_theme_font_size_override("font_size", 9)
	lbl_dica.add_theme_color_override("font_color", Color(0.65, 0.60, 0.75, 0.8))
	vbox.add_child(lbl_dica)
	
	node.add_child(vbox)

func _limpar_filhos(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()

func _limpar_detalhes() -> void:
	if pedestal_icone: pedestal_icone.visible = false
	if img_detalhe_icone: img_detalhe_icone.texture = null
	lbl_detalhe_titulo.text = "Selecione um item"
	lbl_detalhe_desc.text = "Selecione qualquer item da bolsa para inspecionar seus poderes e propriedades."
	btn_acao.visible = false
	if box_descarte: box_descarte.visible = false
	item_selecionado = {}

func _selecionar_item(item: Dictionary, tipo: String, index: int) -> void:
	item_selecionado = item
	item_selecionado["tipo"] = tipo
	item_selecionado["index"] = index
	
	if pedestal_icone: pedestal_icone.visible = true
	
	if tipo == "pocao":
		if img_detalhe_icone: img_detalhe_icone.texture = tex_pocao
		lbl_detalhe_titulo.text = item["nome"]
		var desc_formatada = "❤️ Cura Instantânea: +%d Pontos de Vida\n\nQuantidade Restante: %d frascos\n\nUm elixir revitalizante refinado em caldeirões mágicos da masmorra." % [item.get("cura", 30), item["qtd"]]
		lbl_detalhe_desc.text = item.get("desc", desc_formatada)
		
		btn_acao.text = "✦ BEBER POÇÃO ✦"
		btn_acao.visible = true
		box_descarte.visible = true
		spin_descarte.max_value = max(1, item["qtd"])
		
	elif tipo == "item":
		var icone_item: Texture2D = null
		if item["nome"] == "Chave de Porta":
			icone_item = load("res://assets/sprites/ui/icon_key_transparent.png")
		elif item["nome"] == "Livro de Fórmulas":
			icone_item = load("res://assets/sprites/ui/item_livro_formulas.png")
		elif item["nome"] == "Fragmento de Gelatina":
			if item.get("cores_mistas", false):
				icone_item = load("res://assets/sprites/ui/item_fragmento_gelatina_mercado.png")
			else:
				icone_item = _obter_icone_gelatina(item.get("cor", "azul"))
		elif item["nome"] == "Bateria Elétrica":
			icone_item = load("res://assets/sprites/ui/item_bateria.png")
		elif item["nome"] == "Fragmento de Chip":
			icone_item = load("res://assets/sprites/ui/item_chip.png")
			
		if img_detalhe_icone: img_detalhe_icone.texture = icone_item
		if item["nome"] == "Fragmento de Gelatina":
			if item.get("cores_mistas", false):
				lbl_detalhe_titulo.text = "Fragmentos de Gelatina"
			elif item.has("cor"):
				lbl_detalhe_titulo.text = "Fragmento de Gelatina (%s)" % str(item["cor"]).capitalize()
			else:
				lbl_detalhe_titulo.text = item["nome"]
		else:
			lbl_detalhe_titulo.text = item["nome"]
			
		var desc_base = item.get("descricao", "Um item raro e valioso necessário para abrir caminhos ou avançar na jornada.")
		if item.has("qtd") and item["qtd"] > 1:
			lbl_detalhe_desc.text = "Quantidade na Bolsa: %d\n\n%s" % [item["qtd"], desc_base]
		else:
			lbl_detalhe_desc.text = desc_base
			
		btn_acao.visible = false
		box_descarte.visible = true
		spin_descarte.max_value = max(1, PlayerStats.chaves) if item["nome"] == "Chave de Porta" else max(1, item.get("qtd", 1))
		
	elif tipo == "grimorio":
		var e_codice = (item is Dictionary and item.get("tipo_codice") == "mural")
		if img_detalhe_icone:
			if e_codice:
				var tex_livro = load("res://assets/sprites/ui/item_livro_formulas.png") as Texture2D
				img_detalhe_icone.texture = tex_livro if tex_livro else atlas_pergaminho_fechado
			else:
				img_detalhe_icone.texture = atlas_pergaminho_fechado
		lbl_detalhe_titulo.text = item["titulo"]
		lbl_detalhe_desc.text = item.get("desc", "Um manuscrito acadêmico sagrado repleto de fórmulas e teorias científicas.\n\nAbra o documento para consultar anotações essenciais dos desafios.")
		if e_codice:
			btn_acao.text = "✦ ABRIR CÓDICE CIENTÍFICO ✦"
			box_descarte.visible = false # Códices acadêmicos não podem ser descartados pelo aluno!
		else:
			btn_acao.text = "✦ LER DOCUMENTO ✦"
			box_descarte.visible = true
			spin_descarte.max_value = 1
		btn_acao.visible = true
		
	elif tipo == "moeda":
		var icone_moeda = load("res://assets/sprites/ui/coin.png")
		if img_detalhe_icone: img_detalhe_icone.texture = icone_moeda
		lbl_detalhe_titulo.text = "Moedas de Ouro"
		lbl_detalhe_desc.text = "Tesouros cunhados em ouro puro.\n\nUtilizadas para negociar itens valiosos e poções revigorantes com o Mago Mercador no saguão central."
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
			lbl_detalhe_desc.text = "✨ Sua vitalidade já está plena!\nGuarde este frasco para momentos de necessidade."
			return
			
		var po = PlayerStats.pocoes[idx]
		if po["qtd"] > 0:
			PlayerStats.curar_vida(po["cura"])
			po["qtd"] -= 1
			if po["qtd"] <= 0:
				PlayerStats.pocoes.remove_at(idx)
				_limpar_detalhes()
			else:
				_selecionar_item(po, "pocao", idx)
			_atualizar_listas()
	elif tipo == "grimorio":
		var doc = PlayerStats.grimorio[idx]
		if doc is Dictionary and doc.get("tipo_codice") == "mural":
			var andar = int(doc.get("andar", 1))
			var cena_mural = load("res://scenes/ui/mural_ui.tscn")
			if cena_mural:
				var mural_inst = cena_mural.instantiate()
				get_tree().root.add_child(mural_inst)
				visible = false
				mural_inst.mural_fechado.connect(func():
					visible = true
				)
				mural_inst.abrir_mural(andar, null)
			return
		elif doc.has("paginas") and doc["paginas"] is Array and doc["paginas"].size() > 0:
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
	if texto.contains("|"):
		paginas_leitura = Array(texto.split("|", false))
	else:
		paginas_leitura = [texto]
		
	pagina_atual = 0
	_atualizar_pagina()
	painel_leitura.visible = true

func _atualizar_pagina() -> void:
	if paginas_leitura.is_empty(): return
	label_texto_leitura.text = paginas_leitura[pagina_atual].strip_edges()
	btn_anterior.visible = (pagina_atual > 0)
	btn_proxima.visible = (pagina_atual < paginas_leitura.size() - 1)

func _obter_icone_gelatina(cor: String = "azul") -> Texture2D:
	var tex = load("res://assets/sprites/ui/item_fragmento_gelatina.png") as Texture2D
	if not tex: return null
	var atlas = AtlasTexture.new()
	atlas.atlas = tex
	var fw = tex.get_width() / 3.0
	var fh = tex.get_height() / 3.0
	var row = 2 # Padrão: Azul (linha 2)
	var cor_l = cor.to_lower()
	if "verm" in cor_l or "laranja" in cor_l:
		row = 0
	elif "verd" in cor_l:
		row = 1
	atlas.region = Rect2(0, row * fh, fw, fh)
	return atlas

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

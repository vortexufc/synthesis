extends CanvasLayer

# tela de inventario do jogador

@onready var tab_container: TabContainer = $Control/MarginContainer/Panel/VBox/HBox/MarginTabs/TabContainer
@onready var grid_pocoes: HFlowContainer = $Control/MarginContainer/Panel/VBox/HBox/MarginTabs/TabContainer/Pocoes/ScrollContainer/GridPocoes
@onready var grid_itens: HFlowContainer = $Control/MarginContainer/Panel/VBox/HBox/MarginTabs/TabContainer/Itens/ScrollContainer/GridItens
@onready var grid_grimorio: HFlowContainer = $Control/MarginContainer/Panel/VBox/HBox/MarginTabs/TabContainer/Grimorio/ScrollContainer/GridGrimorio

@onready var pedestal_icone: PanelContainer = $Control/MarginContainer/Panel/VBox/HBox/MarginDetalhes/PainelDetalhes/Margin/VBox/PedestalIcone
@onready var img_detalhe_icone: TextureRect = $Control/MarginContainer/Panel/VBox/HBox/MarginDetalhes/PainelDetalhes/Margin/VBox/PedestalIcone/DetalheIcone
@onready var lbl_detalhe_titulo: Label = $Control/MarginContainer/Panel/VBox/HBox/MarginDetalhes/PainelDetalhes/Margin/VBox/DetalheTitulo
@onready var detalhe_divisor: Label = $Control/MarginContainer/Panel/VBox/HBox/MarginDetalhes/PainelDetalhes/Margin/VBox/DetalheDivisor
@onready var scroll_desc: ScrollContainer = $Control/MarginContainer/Panel/VBox/HBox/MarginDetalhes/PainelDetalhes/Margin/VBox/ScrollDesc
@onready var lbl_detalhe_desc: Label = $Control/MarginContainer/Panel/VBox/HBox/MarginDetalhes/PainelDetalhes/Margin/VBox/ScrollDesc/DetalheDesc
@onready var btn_acao: Button = $Control/MarginContainer/Panel/VBox/HBox/MarginDetalhes/PainelDetalhes/Margin/VBox/BtnAcao

@onready var painel_leitura: Panel = $Control/PainelLeitura
@onready var label_titulo_leitura: Label = $Control/PainelLeitura/Margem/VBox/LabelTitulo
@onready var label_texto_leitura: Label = $Control/PainelLeitura/Margem/VBox/LabelTexto
@onready var btn_fechar_leitura: Button = $Control/PainelLeitura/Margem/VBox/BtnFecharLeitura
@onready var margem_leitura: MarginContainer = $Control/PainelLeitura/Margem

const SLOTS_POR_GRADE: int = 15

var item_selecionado: Dictionary = {}
var paginas_leitura: Array[String] = []
var pagina_atual: int = 0
var btn_anterior: Button
var btn_proxima: Button

var tex_pocao = preload("res://assets/sprites/vida.png")
var tex_pocao_menor = preload("res://assets/sprites/pocao_menor.png")
var tex_pergaminho = preload("res://assets/sprites/pergaminho.png")
var atlas_pergaminho_fechado: AtlasTexture
var atlas_pergaminho_aberto: AtlasTexture

var lbl_moedas_inv: Button
var lbl_capacidade_inv: Button
var btn_fechar_inv: Button
var box_descarte: HBoxContainer
var spin_descarte: SpinBox
var btn_descartar: Button

var badge_categoria: PanelContainer
var lbl_badge_categoria: Label
var painel_placeholder: VBoxContainer
var lbl_ph_icone: Label
var _card_selecionado: Button = null

var _style_slot_normal: StyleBoxFlat
var _style_slot_hover: StyleBoxFlat
var _style_slot_selected: StyleBoxFlat

func _ready() -> void:
	visible = false
	painel_leitura.visible = false
	btn_fechar_leitura.pressed.connect(_fechar_leitura)
	btn_acao.pressed.connect(_on_btn_acao_pressionado)
	_aplicar_efeito_sheen(btn_acao) # Efeito de varredura reluzente (Item 7)
	
	_criar_estilos_slots()
	
	# nomes das abas
	if tab_container:
		tab_container.set_tab_title(0, " 🧪 Poções ")
		tab_container.set_tab_title(1, " 🗝️ Relíquias ")
		tab_container.set_tab_title(2, " 📜 Grimório ")
		if not tab_container.tab_changed.is_connected(_on_tab_changed):
			tab_container.tab_changed.connect(_on_tab_changed)

	# barra pra descartar item
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
	
	# Badge de Categoria e Raridade do item selecionado
	var vbox_detalhes = lbl_detalhe_titulo.get_parent()
	badge_categoria = PanelContainer.new()
	badge_categoria.name = "BadgeCategoria"
	badge_categoria.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	lbl_badge_categoria = Label.new()
	lbl_badge_categoria.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_badge_categoria.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_badge_categoria.add_theme_font_size_override("font_size", 9)
	var font_badge = SystemFont.new()
	font_badge.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_badge.font_weight = 700
	lbl_badge_categoria.add_theme_font_override("font", font_badge)
	badge_categoria.add_child(lbl_badge_categoria)
	vbox_detalhes.add_child(badge_categoria)
	vbox_detalhes.move_child(badge_categoria, lbl_detalhe_titulo.get_index() + 1)
	
	# Painel Placeholder quando nenhum item esta selecionado
	painel_placeholder = VBoxContainer.new()
	painel_placeholder.name = "PainelPlaceholder"
	painel_placeholder.alignment = BoxContainer.ALIGNMENT_CENTER
	painel_placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	painel_placeholder.add_theme_constant_override("separation", 12)
	
	var pedestal_ph = PanelContainer.new()
	pedestal_ph.custom_minimum_size = Vector2(72, 72)
	pedestal_ph.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var sb_ph = StyleBoxFlat.new()
	sb_ph.bg_color = Color(0.12, 0.08, 0.18, 0.95)
	sb_ph.border_width_left = 2
	sb_ph.border_width_top = 2
	sb_ph.border_width_right = 2
	sb_ph.border_width_bottom = 2
	sb_ph.border_color = Color(0.65, 0.45, 0.85, 0.6)
	sb_ph.corner_radius_top_left = 36
	sb_ph.corner_radius_top_right = 36
	sb_ph.corner_radius_bottom_right = 36
	sb_ph.corner_radius_bottom_left = 36
	sb_ph.shadow_size = 10
	sb_ph.shadow_color = Color(0.6, 0.3, 0.8, 0.25)
	pedestal_ph.add_theme_stylebox_override("panel", sb_ph)
	
	lbl_ph_icone = Label.new()
	lbl_ph_icone.text = "✦"
	lbl_ph_icone.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_ph_icone.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_ph_icone.add_theme_font_size_override("font_size", 28)
	lbl_ph_icone.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	pedestal_ph.add_child(lbl_ph_icone)
	painel_placeholder.add_child(pedestal_ph)
	
	var lbl_ph_tit = Label.new()
	lbl_ph_tit.text = "✦ INSPECIONAR ITEM ✦"
	lbl_ph_tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_ph_tit.add_theme_font_size_override("font_size", 12)
	lbl_ph_tit.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	painel_placeholder.add_child(lbl_ph_tit)
	
	var lbl_ph_div = Label.new()
	lbl_ph_div.text = "────── ❖ ──────"
	lbl_ph_div.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_ph_div.add_theme_font_size_override("font_size", 8)
	lbl_ph_div.add_theme_color_override("font_color", Color(0.65, 0.52, 0.25, 0.6))
	painel_placeholder.add_child(lbl_ph_div)
	
	var lbl_ph_desc = Label.new()
	lbl_ph_desc.text = "Toque ou clique em qualquer item da bolsa para inspecionar poderes, fórmulas e propriedades arcanas."
	lbl_ph_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_ph_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_ph_desc.add_theme_font_size_override("font_size", 9)
	lbl_ph_desc.add_theme_color_override("font_color", Color(0.78, 0.72, 0.85, 0.85))
	painel_placeholder.add_child(lbl_ph_desc)
	
	var card_dica = PanelContainer.new()
	card_dica.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb_dica = StyleBoxFlat.new()
	sb_dica.bg_color = Color(0.06, 0.04, 0.10, 0.85)
	sb_dica.border_width_left = 1
	sb_dica.border_width_top = 1
	sb_dica.border_width_right = 1
	sb_dica.border_width_bottom = 1
	sb_dica.border_color = Color(0.55, 0.42, 0.22, 0.6)
	sb_dica.corner_radius_top_left = 8
	sb_dica.corner_radius_top_right = 8
	sb_dica.corner_radius_bottom_right = 8
	sb_dica.corner_radius_bottom_left = 8
	sb_dica.content_margin_left = 10
	sb_dica.content_margin_right = 10
	sb_dica.content_margin_top = 10
	sb_dica.content_margin_bottom = 10
	card_dica.add_theme_stylebox_override("panel", sb_dica)
	
	var vbox_dica = VBoxContainer.new()
	vbox_dica.add_theme_constant_override("separation", 5)
	var lbl_dica_tit = Label.new()
	lbl_dica_tit.text = "💡 DICA ALQUÍMICA"
	lbl_dica_tit.add_theme_font_size_override("font_size", 9)
	lbl_dica_tit.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	vbox_dica.add_child(lbl_dica_tit)
	
	var lbl_dica_corpo = Label.new()
	lbl_dica_corpo.text = "Poções recuperam seus pontos de vida durante confrontos com guardiões. Pergaminhos contêm fórmulas essenciais para os murais e desafios!"
	lbl_dica_corpo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_dica_corpo.add_theme_font_size_override("font_size", 8)
	lbl_dica_corpo.add_theme_color_override("font_color", Color(0.7, 0.65, 0.78, 0.8))
	vbox_dica.add_child(lbl_dica_corpo)
	card_dica.add_child(vbox_dica)
	painel_placeholder.add_child(card_dica)
	
	vbox_detalhes.add_child(painel_placeholder)
	
	_limpar_detalhes()
	
	atlas_pergaminho_fechado = AtlasTexture.new()
	atlas_pergaminho_fechado.atlas = tex_pergaminho
	atlas_pergaminho_fechado.region = Rect2(0, 0, 23, 64)
	
	atlas_pergaminho_aberto = AtlasTexture.new()
	atlas_pergaminho_aberto.atlas = tex_pergaminho
	atlas_pergaminho_aberto.region = Rect2(64, 0, 64, 64)
	
	# fundo do pergaminho
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
	
	# botoes de passar pagina
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
	
	# contador de moedas
	lbl_moedas_inv = Button.new()
	var tex_coin_inv = load("res://assets/sprites/ui/coin.png") as Texture2D
	if tex_coin_inv:
		lbl_moedas_inv.icon = tex_coin_inv
		lbl_moedas_inv.expand_icon = true
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
	var font_num_inv = SystemFont.new()
	font_num_inv.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_num_inv.font_weight = 600
	lbl_moedas_inv.add_theme_font_override("font", font_num_inv)
	lbl_moedas_inv.pressed.connect(func():
		var ps = get_node_or_null("/root/PlayerStats")
		var m = ps.moedas if ps else 0
		_selecionar_item({"nome": "Moedas de Ouro", "qtd": m}, "moeda", -1)
	)
	
	var painel_principal = $Control/MarginContainer/Panel
	if painel_principal:
		var particulas = CPUParticles2D.new()
		particulas.name = "ParticulasArcanas"
		particulas.position = Vector2(560, 560)
		particulas.amount = 18
		particulas.lifetime = 4.0
		particulas.preprocess = 2.5
		particulas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		particulas.emission_rect_extents = Vector2(480, 10)
		particulas.direction = Vector2(0, -1)
		particulas.spread = 15.0
		particulas.gravity = Vector2(0, -12)
		particulas.initial_velocity_min = 12.0
		particulas.initial_velocity_max = 28.0
		particulas.scale_amount_min = 1.8
		particulas.scale_amount_max = 3.6
		particulas.color = Color(1.0, 0.88, 0.45, 0.28)
		particulas.process_mode = Node.PROCESS_MODE_ALWAYS
		painel_principal.add_child(particulas)
		painel_principal.move_child(particulas, 0)
	
	var hbox_topo_direita = HBoxContainer.new()
	hbox_topo_direita.name = "HBoxTopoDireita"
	hbox_topo_direita.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox_topo_direita.add_theme_constant_override("separation", 10)
	hbox_topo_direita.alignment = BoxContainer.ALIGNMENT_END
	painel_principal.add_child(hbox_topo_direita)
	hbox_topo_direita.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	hbox_topo_direita.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hbox_topo_direita.offset_top = 14
	hbox_topo_direita.offset_right = -18
	
	# Indicador de Capacidade de Slots
	lbl_capacidade_inv = Button.new()
	lbl_capacidade_inv.mouse_filter = Control.MOUSE_FILTER_PASS
	lbl_capacidade_inv.focus_mode = Control.FOCUS_NONE
	var sb_cap = StyleBoxFlat.new()
	sb_cap.bg_color = Color(0.12, 0.08, 0.18, 0.95)
	sb_cap.border_width_left = 2
	sb_cap.border_width_top = 2
	sb_cap.border_width_right = 2
	sb_cap.border_width_bottom = 2
	sb_cap.border_color = Color(0.55, 0.42, 0.70, 0.9)
	sb_cap.corner_radius_top_left = 10
	sb_cap.corner_radius_top_right = 10
	sb_cap.corner_radius_bottom_right = 10
	sb_cap.corner_radius_bottom_left = 10
	sb_cap.content_margin_left = 12
	sb_cap.content_margin_right = 12
	sb_cap.content_margin_top = 6
	sb_cap.content_margin_bottom = 6
	lbl_capacidade_inv.add_theme_stylebox_override("normal", sb_cap)
	lbl_capacidade_inv.add_theme_color_override("font_color", Color(0.9, 0.85, 0.95))
	lbl_capacidade_inv.add_theme_font_size_override("font_size", 11)
	lbl_capacidade_inv.add_theme_font_override("font", font_num_inv)
	hbox_topo_direita.add_child(lbl_capacidade_inv)
	
	hbox_topo_direita.add_child(lbl_moedas_inv)
	_aplicar_efeito_sheen(lbl_moedas_inv, Color(1.0, 0.9, 0.4, 0.38), 3.8)
	
	# Botão de Fechar Inventário (Mobile + PC)
	btn_fechar_inv = Button.new()
	btn_fechar_inv.name = "BtnFecharInventario"
	btn_fechar_inv.text = "✕"
	btn_fechar_inv.custom_minimum_size = Vector2(36, 36)
	btn_fechar_inv.pivot_offset = Vector2(18, 18)
	btn_fechar_inv.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_fechar_inv.tooltip_text = "Fechar (Esc / E)"
	
	var sb_close = StyleBoxFlat.new()
	sb_close.bg_color = Color(0.20, 0.08, 0.12, 0.95)
	sb_close.border_width_left = 2
	sb_close.border_width_top = 2
	sb_close.border_width_right = 2
	sb_close.border_width_bottom = 2
	sb_close.border_color = Color(0.85, 0.35, 0.35, 0.90)
	sb_close.corner_radius_top_left = 8
	sb_close.corner_radius_top_right = 8
	sb_close.corner_radius_bottom_right = 8
	sb_close.corner_radius_bottom_left = 8
	
	var sb_close_hover = sb_close.duplicate() as StyleBoxFlat
	sb_close_hover.bg_color = Color(0.38, 0.12, 0.18, 1.0)
	sb_close_hover.border_color = Color(1.0, 0.55, 0.55, 1.0)
	sb_close_hover.shadow_size = 6
	sb_close_hover.shadow_color = Color(0.8, 0.2, 0.2, 0.45)
	
	var sb_close_pressed = sb_close.duplicate() as StyleBoxFlat
	sb_close_pressed.bg_color = Color(0.12, 0.04, 0.07, 1.0)
	sb_close_pressed.border_color = Color(0.70, 0.25, 0.25, 1.0)
	
	btn_fechar_inv.add_theme_stylebox_override("normal", sb_close)
	btn_fechar_inv.add_theme_stylebox_override("hover", sb_close_hover)
	btn_fechar_inv.add_theme_stylebox_override("pressed", sb_close_pressed)
	btn_fechar_inv.add_theme_color_override("font_color", Color(1.0, 0.85, 0.85))
	btn_fechar_inv.add_theme_font_size_override("font_size", 16)
	
	var font_btn = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	if font_btn:
		btn_fechar_inv.add_theme_font_override("font", font_btn)
		
	btn_fechar_inv.mouse_entered.connect(func():
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn_fechar_inv, "scale", Vector2(1.1, 1.1), 0.1)
	)
	btn_fechar_inv.mouse_exited.connect(func():
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn_fechar_inv, "scale", Vector2.ONE, 0.1)
	)
	btn_fechar_inv.pressed.connect(_on_btn_fechar_inventario_pressionado)
	hbox_topo_direita.add_child(btn_fechar_inv)

func _criar_estilos_slots() -> void:
	# estilo normal do slot
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

	# estilo quando passa o mouse
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

	# estilo selecionado
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

var _tempo_ph: float = 0.0

func _process(delta: float) -> void:
	if visible and painel_placeholder and painel_placeholder.visible and lbl_ph_icone:
		_tempo_ph += delta * 2.5
		lbl_ph_icone.position.y = sin(_tempo_ph) * 3.5
		
	var gs = get_node_or_null("/root/GlobalSignals")
	if visible and gs and gs.tem_interacao_ou_minigame_ativo():
		_toggle_inventario()
		return
	if Input.is_action_just_pressed("inventory"):
		if not visible and gs and gs.tem_interacao_ou_minigame_ativo():
			return
		_toggle_inventario()

func _on_btn_fechar_inventario_pressionado() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx("ui-2")
	if painel_leitura and painel_leitura.visible:
		_fechar_leitura()
	else:
		_toggle_inventario()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		if painel_leitura and painel_leitura.visible:
			_fechar_leitura()
		else:
			_toggle_inventario()

func fechar_inventario() -> void:
	if visible:
		_toggle_inventario()

func _toggle_inventario() -> void:
	var gs = get_node_or_null("/root/GlobalSignals")
	if not visible and gs and gs.tem_interacao_ou_minigame_ativo():
		return
	var ui_pergaminho = get_tree().get_first_node_in_group("parchment_ui")
	if ui_pergaminho and ui_pergaminho.visible:
		if ui_pergaminho.has_method("_fechar_pergaminho"):
			ui_pergaminho._fechar_pergaminho()
		else:
			ui_pergaminho.hide()

	var qm = get_node_or_null("/root/QuizManager")
	var em_batalha = (qm != null and qm.ui_instancia != null and qm.ui_instancia.visible)
	var painel = $Control/MarginContainer
	
	if _tween_anim_inv and _tween_anim_inv.is_running():
		_tween_anim_inv.kill()

	if visible:
		var am = get_node_or_null("/root/AudioManager")
		if am:
			am.play_sfx("ui-2")
			
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
		var ps = get_node_or_null("/root/PlayerStats")
		if ps:
			ps.salvar()
		
		var am = get_node_or_null("/root/AudioManager")
		if am:
			am.play_sfx("ui_1")
			
		if painel:
			painel.pivot_offset = painel.size / 2.0
			painel.scale = Vector2(0.92, 0.92)
			painel.modulate.a = 0.0
			_tween_anim_inv = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			_tween_anim_inv.tween_property(painel, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_tween_anim_inv.parallel().tween_property(painel, "modulate:a", 1.0, 0.16)

func _on_btn_descartar_pressionado() -> void:
	if item_selecionado.is_empty(): return
	var ps = get_node_or_null("/root/PlayerStats")
	if not ps: return
	
	var tipo = item_selecionado["tipo"]
	var idx = item_selecionado["index"]
	var qtd_descarte = int(spin_descarte.value)
	
	if tipo == "pocao":
		var po = ps.pocoes[idx]
		po["qtd"] -= qtd_descarte
		if po["qtd"] <= 0:
			ps.pocoes.remove_at(idx)
	elif tipo == "item":
		if item_selecionado["nome"] == "Chave de Porta":
			ps.chaves = max(0, ps.chaves - qtd_descarte)
		else:
			var removidos = 0
			for k in range(ps.itens.size() - 1, -1, -1):
				var it = ps.itens[k]
				var mesmo_item = false
				if it.get("nome") == item_selecionado.get("nome"):
					mesmo_item = true
				elif ("Gelatina" in item_selecionado.get("nome", "")) and it.get("cor") == item_selecionado.get("cor"):
					mesmo_item = true
				if mesmo_item:
					ps.itens.remove_at(k)
					removidos += 1
					if removidos >= qtd_descarte:
						break
	elif tipo == "grimorio":
		ps.grimorio.remove_at(idx)
	elif tipo == "moeda":
		if ps.moedas > 0:
			ps.moedas = max(0, ps.moedas - qtd_descarte)
	
	_atualizar_listas()
	_limpar_detalhes()
	ps.salvar()

func _atualizar_listas() -> void:
	_limpar_filhos(grid_pocoes)
	_limpar_filhos(grid_itens)
	_limpar_filhos(grid_grimorio)
	
	var ps = get_node_or_null("/root/PlayerStats")
	if not ps:
		return
		
	if lbl_moedas_inv:
		lbl_moedas_inv.text = " 🪙  %d Moedas " % ps.moedas
	
	# carrega pocoes
	for i in range(ps.pocoes.size()):
		var po = ps.pocoes[i]
		var icone_po = tex_pocao
		var n_low = po.get("nome", "").to_lower()
		var t_low = po.get("tipo", "").to_lower()
		if "menor" in n_low or "pocao_menor" in t_low:
			icone_po = tex_pocao_menor
		var card = _criar_slot_card(icone_po, po["nome"], po["qtd"], func(): _selecionar_item(po, "pocao", i))
		grid_pocoes.add_child(card)

	var cap_pocoes = max(SLOTS_POR_GRADE, int(ceil(float(ps.pocoes.size()) / 5.0)) * 5)
	var vazios_pocoes = max(0, cap_pocoes - ps.pocoes.size())
	for k in range(vazios_pocoes):
		grid_pocoes.add_child(_criar_slot_vazio("poção"))
			
	# carrega itens e chaves
	var total_reliquias_cards = 0
	if ps.chaves > 0:
		total_reliquias_cards += 1
		var icone_chave = load("res://assets/sprites/ui/icon_key_transparent.png")
		var dic_chave = {"nome": "Chave de Porta", "descricao": "Uma chave dourada brilhante capaz de abrir portas mágicas seladas."}
		var card = _criar_slot_card(icone_chave, "Chave de Porta", ps.chaves, func(): _selecionar_item(dic_chave, "item", -1))
		grid_itens.add_child(card)
		
	# junta itens iguais por nome (separando os fragmentos por cor)
	var itens_agrupados: Dictionary = {}
	for it in ps.itens:
		var nome = it.get("nome", "Item Desconhecido")
		var cor = it.get("cor", "")
		
		# Garante que fragmentos gelatinosos fiquem separados por cor no repartimento
		if nome == "Fragmento de Gelatina" or "Gelatina" in nome or cor != "":
			if cor == "" and nome == "Fragmento de Gelatina":
				cor = "azul"
			if cor == "verde" or "verde" in nome.to_lower():
				nome = "Fragmento Gelatinoso Verde"
				cor = "verde"
			elif cor == "vermelho" or "vermelh" in nome.to_lower() or "laranja" in nome.to_lower():
				nome = "Fragmento Gelatinoso Vermelho"
				cor = "vermelho"
			else:
				nome = "Fragmento Gelatinoso Azul"
				cor = "azul"
			it["nome"] = nome
			it["cor"] = cor
			
		if not itens_agrupados.has(nome):
			itens_agrupados[nome] = {
				"item_base": it,
				"qtd": 0
			}
		itens_agrupados[nome]["qtd"] += 1
			
	for nome in itens_agrupados.keys():
		total_reliquias_cards += 1
		var grupo = itens_agrupados[nome]
		var item_base = grupo["item_base"]
		var qtd = grupo["qtd"]
		var icone: Texture2D = null
		
		if nome == "Livro de Fórmulas":
			icone = load("res://assets/sprites/ui/item_livro_formulas.png")
		elif "Gelatina" in nome or item_base.has("cor"):
			var cor = item_base.get("cor", "azul")
			icone = _obter_icone_gelatina(cor)
		elif nome == "Bateria Elétrica":
			icone = load("res://assets/sprites/ui/item_bateria.png")
		elif nome == "Fragmento de Chip":
			icone = load("res://assets/sprites/ui/item_chip.png")
		elif nome == "Chip de DNA" or "DNA" in nome:
			icone = load("res://assets/sprites/ui/item_chip_dna.png")
		elif nome == "Flor Rara" or "Flor" in nome:
			icone = load("res://assets/sprites/ui/item_flor_rara.png")
			
		var item_display = item_base.duplicate()
		item_display["qtd"] = qtd
		var card = _criar_slot_card(icone, nome, qtd, func(): _selecionar_item(item_display, "item", -1))
		grid_itens.add_child(card)
		
	var cap_itens = max(SLOTS_POR_GRADE, int(ceil(float(total_reliquias_cards) / 5.0)) * 5)
	var vazios_itens = max(0, cap_itens - total_reliquias_cards)
	for k in range(vazios_itens):
		grid_itens.add_child(_criar_slot_vazio("relíquia"))
			
	# carrega folhas do grimorio
	for i in range(ps.grimorio.size()):
		var doc = ps.grimorio[i]
		var icone_doc: Texture2D = atlas_pergaminho_fechado
		if doc is Dictionary and doc.get("tipo_codice") == "mural":
			var tex_livro = load("res://assets/sprites/ui/item_livro_formulas.png") as Texture2D
			if tex_livro:
				icone_doc = tex_livro
		var card = _criar_slot_card(icone_doc, doc["titulo"], 1, func(): _selecionar_item(doc, "grimorio", i))
		grid_grimorio.add_child(card)

	var cap_grimorio = max(SLOTS_POR_GRADE, int(ceil(float(ps.grimorio.size()) / 5.0)) * 5)
	var vazios_grimorio = max(0, cap_grimorio - ps.grimorio.size())
	for k in range(vazios_grimorio):
		grid_grimorio.add_child(_criar_slot_vazio("manuscrito"))

	_atualizar_capacidade_label()

# monta o slot do item na grade
func _criar_slot_card(icone: Texture2D, nome: String, qtd: int, callback: Callable) -> Control:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(118, 118)
	btn.add_theme_stylebox_override("normal", _style_slot_normal)
	btn.add_theme_stylebox_override("hover", _style_slot_hover)
	btn.add_theme_stylebox_override("pressed", _style_slot_selected)
	btn.focus_mode = Control.FOCUS_NONE
	btn.clip_contents = true
	
	# margem do slot
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
	
	# icone do item
	var tex_rect = TextureRect.new()
	tex_rect.texture = icone
	tex_rect.custom_minimum_size = Vector2(46, 46)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	vbox.add_child(tex_rect)
	
	# nome do item
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
	
	# quantidade do item
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
		
	# efeito de clique
	btn.pressed.connect(func():
		var am = get_node_or_null("/root/AudioManager")
		if am:
			am.play_sfx("ui-1")
		_destacar_card_ativo(btn)
		callback.call()
	)
	
	# animacao de hover
	btn.mouse_entered.connect(func():
		if btn != _card_selecionado:
			var tw = btn.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.08)
	)
	btn.mouse_exited.connect(func():
		if btn != _card_selecionado:
			var tw = btn.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw.tween_property(btn, "scale", Vector2.ONE, 0.08)
	)
	
	return btn

func _destacar_card_ativo(btn: Button) -> void:
	if _card_selecionado and is_instance_valid(_card_selecionado):
		_card_selecionado.add_theme_stylebox_override("normal", _style_slot_normal)
	_card_selecionado = btn
	if _card_selecionado and is_instance_valid(_card_selecionado):
		_card_selecionado.add_theme_stylebox_override("normal", _style_slot_selected)
		var tw_click = _card_selecionado.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw_click.tween_property(_card_selecionado, "scale", Vector2(0.96, 0.96), 0.05)
		tw_click.tween_property(_card_selecionado, "scale", Vector2(1.03, 1.03), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _criar_slot_vazio(_categoria_hint: String = "") -> Control:
	var slot = PanelContainer.new()
	slot.custom_minimum_size = Vector2(118, 118)
	slot.focus_mode = Control.FOCUS_NONE
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.05, 0.11, 0.65)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.35, 0.25, 0.45, 0.35)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left = 8
	slot.add_theme_stylebox_override("panel", sb)
	
	var center = CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	center.add_child(vbox)
	
	var lbl_icone = Label.new()
	lbl_icone.text = "◇"
	lbl_icone.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_icone.add_theme_font_size_override("font_size", 14)
	lbl_icone.add_theme_color_override("font_color", Color(0.55, 0.45, 0.70, 0.25))
	vbox.add_child(lbl_icone)
	
	var lbl_txt = Label.new()
	lbl_txt.text = "Vazio"
	lbl_txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_txt.add_theme_font_size_override("font_size", 8)
	lbl_txt.add_theme_color_override("font_color", Color(0.55, 0.48, 0.70, 0.25))
	vbox.add_child(lbl_txt)
	
	slot.mouse_entered.connect(func():
		var sb_h = sb.duplicate() as StyleBoxFlat
		sb_h.border_color = Color(0.65, 0.50, 0.85, 0.6)
		sb_h.bg_color = Color(0.12, 0.08, 0.18, 0.8)
		slot.add_theme_stylebox_override("panel", sb_h)
	)
	slot.mouse_exited.connect(func():
		slot.add_theme_stylebox_override("panel", sb)
	)
	
	return slot

func _atualizar_capacidade_label() -> void:
	if not lbl_capacidade_inv: return
	var ps = get_node_or_null("/root/PlayerStats")
	if not ps: return
	var aba = tab_container.current_tab if tab_container else 0
	var qtd = 0
	var icone = "🎒"
	if aba == 0:
		qtd = ps.pocoes.size()
		icone = "🧪"
	elif aba == 1:
		var total_reliquias = 0
		if ps.chaves > 0: total_reliquias += 1
		var vistos = {}
		for it in ps.itens:
			var n = it.get("nome", "")
			if not vistos.has(n):
				vistos[n] = true
				total_reliquias += 1
		qtd = total_reliquias
		icone = "🗝️"
	elif aba == 2:
		qtd = ps.grimorio.size()
		icone = "📜"
	
	var cap_max = max(SLOTS_POR_GRADE, int(ceil(float(qtd) / 5.0)) * 5)
	lbl_capacidade_inv.text = " %s  %d / %d " % [icone, qtd, cap_max]

func _on_tab_changed(_tab_idx: int) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx("ui-3")
	_limpar_detalhes()
	_atualizar_capacidade_label()

func _add_mensagem_vazia(node: Node, icone_recurso: Variant, titulo: String, dica: String) -> void:
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	
	if icone_recurso is Texture2D and icone_recurso != null:
		var tex_icone = TextureRect.new()
		tex_icone.texture = icone_recurso
		tex_icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_icone.custom_minimum_size = Vector2(36, 36)
		tex_icone.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tex_icone.modulate = Color(1.0, 1.0, 1.0, 0.45)
		vbox.add_child(tex_icone)
	
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
	if lbl_detalhe_titulo: lbl_detalhe_titulo.visible = false
	if badge_categoria: badge_categoria.visible = false
	if detalhe_divisor: detalhe_divisor.visible = false
	if scroll_desc: scroll_desc.visible = false
	if btn_acao: btn_acao.visible = false
	if box_descarte: box_descarte.visible = false
	if painel_placeholder: painel_placeholder.visible = true
	if _card_selecionado and is_instance_valid(_card_selecionado):
		_card_selecionado.add_theme_stylebox_override("normal", _style_slot_normal)
	_card_selecionado = null
	item_selecionado = {}

func _aplicar_estilo_badge(texto: String, cor_texto: Color, cor_bg: Color, cor_borda: Color) -> void:
	if not badge_categoria or not lbl_badge_categoria: return
	lbl_badge_categoria.text = texto
	lbl_badge_categoria.add_theme_color_override("font_color", cor_texto)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = cor_bg
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = cor_borda
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_right = 6
	sb.corner_radius_bottom_left = 6
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	badge_categoria.add_theme_stylebox_override("panel", sb)

func _selecionar_item(item: Dictionary, tipo: String, index: int) -> void:
	item_selecionado = item
	item_selecionado["tipo"] = tipo
	item_selecionado["index"] = index
	
	if painel_placeholder: painel_placeholder.visible = false
	if pedestal_icone:
		pedestal_icone.visible = true
		pedestal_icone.scale = Vector2(0.88, 0.88)
		pedestal_icone.pivot_offset = pedestal_icone.size * 0.5
		var tw_ped = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw_ped.tween_property(pedestal_icone, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if lbl_detalhe_titulo: lbl_detalhe_titulo.visible = true
	if badge_categoria: badge_categoria.visible = true
	if detalhe_divisor: detalhe_divisor.visible = true
	if scroll_desc: scroll_desc.visible = true
	
	if tipo == "pocao":
		_aplicar_estilo_badge("🧪 CONSUMÍVEL REVITALIZANTE", Color(0.4, 1.0, 0.6), Color(0.06, 0.20, 0.12, 0.95), Color(0.28, 0.85, 0.45, 0.95))
		var icone_detalhe = tex_pocao
		var n_low = item.get("nome", "").to_lower()
		var t_low = item.get("tipo", "").to_lower()
		if "menor" in n_low or "pocao_menor" in t_low:
			icone_detalhe = tex_pocao_menor
		if img_detalhe_icone: img_detalhe_icone.texture = icone_detalhe
		lbl_detalhe_titulo.text = item["nome"]
		var desc_formatada = "❤️ Cura Instantânea: +%d Pontos de Vida\n\nQuantidade Restante: %d frascos\n\nUm elixir revitalizante refinado em caldeirões mágicos da masmorra." % [item.get("cura", 30), item["qtd"]]
		lbl_detalhe_desc.text = item.get("desc", desc_formatada)
		
		btn_acao.text = "✦ BEBER POÇÃO ✦"
		btn_acao.visible = true
		box_descarte.visible = true
		spin_descarte.max_value = max(1, item["qtd"])
		
	elif tipo == "item":
		if item["nome"] == "Chave de Porta":
			_aplicar_estilo_badge("🗝️ CHAVE DE MASMORRA", Color(1.0, 0.88, 0.45), Color(0.22, 0.16, 0.06, 0.95), Color(0.95, 0.75, 0.25, 0.95))
		else:
			_aplicar_estilo_badge("💎 ARTEFATO ALQUÍMICO", Color(0.5, 0.9, 1.0), Color(0.08, 0.16, 0.28, 0.95), Color(0.3, 0.75, 1.0, 0.95))
			
		var icone_item: Texture2D = null
		if item["nome"] == "Chave de Porta":
			icone_item = load("res://assets/sprites/ui/icon_key_transparent.png")
		elif item["nome"] == "Livro de Fórmulas":
			icone_item = load("res://assets/sprites/ui/item_livro_formulas.png")
		elif "Gelatina" in item["nome"] or item.has("cor"):
			icone_item = _obter_icone_gelatina(item.get("cor", "azul"))
		elif item["nome"] == "Bateria Elétrica":
			icone_item = load("res://assets/sprites/ui/item_bateria.png")
		elif item["nome"] == "Fragmento de Chip":
			icone_item = load("res://assets/sprites/ui/item_chip.png")
		elif item["nome"] == "Chip de DNA" or "DNA" in item["nome"]:
			icone_item = load("res://assets/sprites/ui/item_chip_dna.png")
		elif item["nome"] == "Flor Rara" or "Flor" in item["nome"]:
			icone_item = load("res://assets/sprites/ui/item_flor_rara.png")
			
		if img_detalhe_icone:
			img_detalhe_icone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			img_detalhe_icone.texture = icone_item
		lbl_detalhe_titulo.text = item["nome"]
			
		var desc_base = item.get("descricao", "Um item raro e valioso necessário para abrir caminhos ou avançar na jornada.")
		if item.has("qtd") and item["qtd"] > 1:
			lbl_detalhe_desc.text = "Quantidade na Bolsa: %d\n\n%s" % [item["qtd"], desc_base]
		else:
			lbl_detalhe_desc.text = desc_base
			
		btn_acao.visible = false
		box_descarte.visible = true
		var ps = get_node_or_null("/root/PlayerStats")
		var max_v = ps.chaves if (ps and item["nome"] == "Chave de Porta") else max(1, item.get("qtd", 1))
		spin_descarte.max_value = max_v
		
	elif tipo == "grimorio":
		var e_codice = (item is Dictionary and item.get("tipo_codice") == "mural")
		if e_codice:
			_aplicar_estilo_badge("🏛️ CÓDICE ACADÊMICO", Color(0.9, 0.75, 1.0), Color(0.18, 0.10, 0.30, 0.95), Color(0.85, 0.55, 1.0, 0.95))
		else:
			_aplicar_estilo_badge("📜 PERGAMINHO DE FÓRMULAS", Color(1.0, 0.80, 0.50), Color(0.22, 0.14, 0.08, 0.95), Color(0.95, 0.65, 0.30, 0.95))
			
		if img_detalhe_icone:
			if e_codice:
				var tex_livro = load("res://assets/sprites/ui/item_livro_formulas.png") as Texture2D
				if tex_livro:
					img_detalhe_icone.texture = tex_livro
				else:
					img_detalhe_icone.texture = atlas_pergaminho_fechado
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
		_aplicar_estilo_badge("🪙 TESOURO REAL", Color(1.0, 0.88, 0.45), Color(0.22, 0.16, 0.06, 0.95), Color(1.0, 0.82, 0.25, 0.95))
		var icone_moeda = load("res://assets/sprites/ui/coin.png")
		if img_detalhe_icone: img_detalhe_icone.texture = icone_moeda
		lbl_detalhe_titulo.text = "Moedas de Ouro"
		lbl_detalhe_desc.text = "Tesouros cunhados em ouro puro.\n\nUtilizadas para negociar itens valiosos e poções revigorantes com o Mago Mercador no saguão central."
		btn_acao.visible = false
		box_descarte.visible = true
		var ps = get_node_or_null("/root/PlayerStats")
		spin_descarte.max_value = max(1, ps.moedas if ps else 1)
	
	spin_descarte.value = 1

func _on_btn_acao_pressionado() -> void:
	if item_selecionado.is_empty(): return
	var ps = get_node_or_null("/root/PlayerStats")
	if not ps: return
	
	var tipo = item_selecionado["tipo"]
	var idx = item_selecionado["index"]
	
	if tipo == "pocao":
		if ps.vida_atual_jogador >= ps.vida_maxima_jogador:
			lbl_detalhe_desc.text = "✨ Sua vitalidade já está plena!\nGuarde este frasco para momentos de necessidade."
			return
			
		var po = ps.pocoes[idx]
		if po["qtd"] > 0:
			var am = get_node_or_null("/root/AudioManager")
			if am:
				am.play_sfx("pocao_cura")
			ps.curar_vida(po["cura"])
			po["qtd"] -= 1
			if po["qtd"] <= 0:
				ps.pocoes.remove_at(idx)
				_limpar_detalhes()
			else:
				_selecionar_item(po, "pocao", idx)
			_atualizar_listas()
	elif tipo == "grimorio":
		var doc = ps.grimorio[idx]
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

func _aplicar_efeito_sheen(alvo: Control, cor_brilho: Color = Color(1.0, 1.0, 1.0, 0.38), intervalo: float = 3.2) -> void:
	if alvo == null or not is_instance_valid(alvo):
		return
	alvo.clip_contents = true
	
	var sheen = TextureRect.new()
	sheen.name = "SheenEffect"
	sheen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	var grad = Gradient.new()
	grad.colors = PackedColorArray([
		Color(1, 1, 1, 0.0),
		cor_brilho,
		Color(1, 1, 1, 0.0)
	])
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0.0, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 128
	sheen.texture = tex
	
	alvo.add_child(sheen)
	
	alvo.resized.connect(func():
		_iniciar_animacao_sheen(alvo, sheen, intervalo)
	)
	_iniciar_animacao_sheen(alvo, sheen, intervalo)

func _iniciar_animacao_sheen(alvo: Control, sheen: TextureRect, intervalo: float) -> void:
	if not is_instance_valid(alvo) or not is_instance_valid(sheen): return
	var w = max(alvo.size.x, alvo.custom_minimum_size.x)
	var h = max(alvo.size.y, alvo.custom_minimum_size.y)
	if w <= 0 or h <= 0: return
	
	sheen.size = Vector2(w * 0.45, h * 2.4)
	sheen.rotation = deg_to_rad(24.0)
	sheen.pivot_offset = sheen.size * 0.5
	sheen.position = Vector2(-sheen.size.x * 2.0, -h * 0.7)
	
	var tw = sheen.create_tween().set_loops().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_interval(intervalo)
	tw.tween_property(sheen, "position:x", w + sheen.size.x, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(sheen, "position:x", -sheen.size.x * 2.0, 0.0)

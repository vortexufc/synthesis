extends CanvasLayer

## Interface do Pergaminho Arcano com estilo Pixel Art
## Exibe anotações educativas detalhadas com suporte a rolagem interna e navegação por páginas.

# Fonte pixelada oficial do jogo
var font_pixel: Font = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font

# Nós da interface
var backdrop: ColorRect
var painel_pergaminho: PanelContainer
var lbl_titulo: Label
var texto_dica: RichTextLabel
var lbl_pagina: Label
var btn_esquerda: Button
var btn_direita: Button
var btn_fechar_topo: Button

# Estado da leitura
var paginas_do_texto: Array[String] = []
var pagina_atual: int = 0
var player_ref: Node2D = null

func _ready() -> void:
	layer = 100 # Mantém o pergaminho no topo de qualquer HUD/Batalha
	add_to_group("parchment_ui")
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_construir_interface_pixel()
	hide()

## Constrói um painel de pergaminho limpo, bonito e pixel-art com rolagem interna
func _construir_interface_pixel() -> void:
	# Limpa nós antigos para evitar bugs de layout
	for c in get_children():
		c.queue_free()
		
	# 1. Fundo escuro semi-transparente
	backdrop = ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.04, 0.06, 0.10, 0.85)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)
	
	# 2. Painel Central do Pergaminho (Dimensão espaçosa)
	painel_pergaminho = PanelContainer.new()
	painel_pergaminho.name = "PainelPergaminho"
	painel_pergaminho.anchor_left = 0.5
	painel_pergaminho.anchor_top = 0.5
	painel_pergaminho.anchor_right = 0.5
	painel_pergaminho.anchor_bottom = 0.5
	painel_pergaminho.offset_left = -410
	painel_pergaminho.offset_top = -250
	painel_pergaminho.offset_right = 410
	painel_pergaminho.offset_bottom = 250
	backdrop.add_child(painel_pergaminho)
	
	# Estilo visual do papel pergaminho em Pixel Art
	var style_papel = StyleBoxFlat.new()
	style_papel.bg_color = Color(0.92, 0.84, 0.68) # Papel pergaminho amarelado
	style_papel.border_color = Color(0.35, 0.20, 0.08) # Borda escura estilo madeira/tinta
	style_papel.set_border_width_all(5)
	style_papel.set_corner_radius_all(6)
	style_papel.content_margin_left = 25
	style_papel.content_margin_top = 18
	style_papel.content_margin_right = 25
	style_papel.content_margin_bottom = 18
	painel_pergaminho.add_theme_stylebox_override("panel", style_papel)
	
	# Layout vertical principal
	var vbox_main = VBoxContainer.new()
	vbox_main.add_theme_constant_override("separation", 10)
	painel_pergaminho.add_child(vbox_main)
	
	# --- CABEÇALHO / TÍTULO ---
	var hbox_header = HBoxContainer.new()
	vbox_main.add_child(hbox_header)
	
	lbl_titulo = Label.new()
	lbl_titulo.text = "PERGAMINHO ARCANO"
	if font_pixel:
		lbl_titulo.add_theme_font_override("font", font_pixel)
	lbl_titulo.add_theme_font_size_override("font_size", 22)
	lbl_titulo.add_theme_color_override("font_color", Color(0.35, 0.18, 0.05))
	hbox_header.add_child(lbl_titulo)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_header.add_child(spacer)
	
	# ÚNICO botão de fechar: o "X" no canto superior direito
	btn_fechar_topo = Button.new()
	btn_fechar_topo.text = " X "
	if font_pixel:
		btn_fechar_topo.add_theme_font_override("font", font_pixel)
	btn_fechar_topo.add_theme_font_size_override("font_size", 18)
	btn_fechar_topo.pressed.connect(_fechar_pergaminho)
	_estilar_botao(btn_fechar_topo, true)
	hbox_header.add_child(btn_fechar_topo)
	
	# Linha divisora
	var linha_divisora = ColorRect.new()
	linha_divisora.custom_minimum_size = Vector2(0, 2)
	linha_divisora.color = Color(0.55, 0.38, 0.18, 0.6)
	vbox_main.add_child(linha_divisora)
	
	# --- CORPO DO TEXTO (COM ROLAGEM INTERNA HABILITADA) ---
	texto_dica = RichTextLabel.new()
	texto_dica.size_flags_vertical = Control.SIZE_EXPAND_FILL
	texto_dica.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texto_dica.bbcode_enabled = true
	texto_dica.scroll_active = true
	texto_dica.scroll_following = false
	texto_dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	if font_pixel:
		texto_dica.add_theme_font_override("normal_font", font_pixel)
		texto_dica.add_theme_font_override("bold_font", font_pixel)
	texto_dica.add_theme_font_size_override("normal_font_size", 18)
	texto_dica.add_theme_font_size_override("bold_font_size", 19)
	texto_dica.add_theme_color_override("default_color", Color(0.18, 0.10, 0.04))
	
	# Estilo suave para a barra de rolagem interna
	var scroll_bar = texto_dica.get_v_scroll_bar()
	if scroll_bar:
		var style_scroll_grab = StyleBoxFlat.new()
		style_scroll_grab.bg_color = Color(0.45, 0.28, 0.12)
		style_scroll_grab.set_corner_radius_all(3)
		scroll_bar.add_theme_stylebox_override("grabber", style_scroll_grab)
		scroll_bar.add_theme_stylebox_override("grabber_highlight", style_scroll_grab)
		scroll_bar.add_theme_stylebox_override("grabber_pressed", style_scroll_grab)
		
	vbox_main.add_child(texto_dica)
	
	# Linha divisora inferior
	var linha_divisora2 = ColorRect.new()
	linha_divisora2.custom_minimum_size = Vector2(0, 2)
	linha_divisora2.color = Color(0.55, 0.38, 0.18, 0.4)
	vbox_main.add_child(linha_divisora2)
	
	# --- BARRA DE NAVEGAÇÃO ---
	var hbox_footer = HBoxContainer.new()
	hbox_footer.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_footer.add_theme_constant_override("separation", 25)
	vbox_main.add_child(hbox_footer)
	
	btn_esquerda = Button.new()
	btn_esquerda.text = "< Anterior"
	if font_pixel:
		btn_esquerda.add_theme_font_override("font", font_pixel)
	btn_esquerda.add_theme_font_size_override("font_size", 17)
	btn_esquerda.pressed.connect(_voltar_pagina)
	_estilar_botao(btn_esquerda)
	hbox_footer.add_child(btn_esquerda)
	
	lbl_pagina = Label.new()
	lbl_pagina.text = "Página 1 de 1"
	if font_pixel:
		lbl_pagina.add_theme_font_override("font", font_pixel)
	lbl_pagina.add_theme_font_size_override("font_size", 17)
	lbl_pagina.add_theme_color_override("font_color", Color(0.35, 0.18, 0.05))
	hbox_footer.add_child(lbl_pagina)
	
	btn_direita = Button.new()
	btn_direita.text = "Próxima >"
	if font_pixel:
		btn_direita.add_theme_font_override("font", font_pixel)
	btn_direita.add_theme_font_size_override("font_size", 17)
	btn_direita.pressed.connect(_avancar_pagina)
	_estilar_botao(btn_direita)
	hbox_footer.add_child(btn_direita)

## Aplica estilização de botão pixel art
func _estilar_botao(btn: Button, destaque: bool = false) -> void:
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.35, 0.20, 0.08) if not destaque else Color(0.55, 0.15, 0.10)
	style_normal.border_color = Color(0.20, 0.10, 0.04)
	style_normal.set_border_width_all(2)
	style_normal.set_corner_radius_all(4)
	style_normal.content_margin_left = 14
	style_normal.content_margin_right = 14
	style_normal.content_margin_top = 5
	style_normal.content_margin_bottom = 5
	
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Color(0.48, 0.28, 0.12) if not destaque else Color(0.70, 0.20, 0.15)
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_normal)
	btn.add_theme_color_override("font_color", Color(0.98, 0.94, 0.85))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
		
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		_fechar_pergaminho()
		get_viewport().set_input_as_handled()
	elif (event.is_action_pressed("ui_left") or event.is_action_pressed("esquerda")) and not event.is_echo():
		_voltar_pagina()
		get_viewport().set_input_as_handled()
	elif (event.is_action_pressed("ui_right") or event.is_action_pressed("direita")) and not event.is_echo():
		_avancar_pagina()
		get_viewport().set_input_as_handled()

func abrir_pergaminho(paginas: Array[String], player: Node2D = null) -> void:
	paginas_do_texto = paginas
	player_ref = player
	if player_ref == null:
		player_ref = get_tree().get_first_node_in_group("player") as Node2D
		
	if player_ref and is_instance_valid(player_ref):
		player_ref.travado = true
		
	pagina_atual = 0
	
	if backdrop == null or not is_instance_valid(backdrop):
		_construir_interface_pixel()
		
	atualizar_tela()
	show()

func atualizar_tela() -> void:
	if paginas_do_texto.is_empty():
		return
		
	texto_dica.text = paginas_do_texto[pagina_atual]
	
	# Reseta o scroll para o topo ao trocar de página
	var v_scroll = texto_dica.get_v_scroll_bar()
	if v_scroll:
		v_scroll.value = 0
		
	btn_esquerda.visible = pagina_atual > 0
	btn_direita.visible = pagina_atual < (paginas_do_texto.size() - 1)
	
	if lbl_pagina:
		lbl_pagina.text = "Página %d de %d" % [pagina_atual + 1, paginas_do_texto.size()]

func _voltar_pagina() -> void:
	if pagina_atual > 0:
		pagina_atual -= 1
		atualizar_tela()
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("ui-1")

func _avancar_pagina() -> void:
	if pagina_atual < paginas_do_texto.size() - 1:
		pagina_atual += 1
		atualizar_tela()
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("ui-1")

signal pergaminho_fechado

func _fechar_pergaminho() -> void:
	hide()
	if player_ref and is_instance_valid(player_ref):
		player_ref.travado = false
		player_ref = null
	if get_tree().paused:
		get_tree().paused = false
	pergaminho_fechado.emit()

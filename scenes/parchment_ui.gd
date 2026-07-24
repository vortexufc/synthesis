extends CanvasLayer

# ==========================================
# REFERÊNCIAS DOS NÓS VISUAIS
# ==========================================
@onready var control: Control = $Control if has_node("Control") else null
@onready var background_papel: TextureRect = $Control/BackgroundPapel if has_node("Control/BackgroundPapel") else null
@onready var texto_dica: RichTextLabel = $Control/BackgroundPapel/TextoDica if has_node("Control/BackgroundPapel/TextoDica") else null
@onready var botoes_container: HBoxContainer = $Control/BackgroundPapel/BotoesContainer if has_node("Control/BackgroundPapel/BotoesContainer") else null
@onready var btn_esquerda: TextureButton = $Control/BackgroundPapel/BotoesContainer/BtnEsquerda if has_node("Control/BackgroundPapel/BotoesContainer/BtnEsquerda") else null
@onready var btn_direita: TextureButton = $Control/BackgroundPapel/BotoesContainer/BtnDireita if has_node("Control/BackgroundPapel/BotoesContainer/BtnDireita") else null
@onready var btn_fechar: TextureButton = $Control/BackgroundPapel/BotoesContainer/BtnFechar if has_node("Control/BackgroundPapel/BotoesContainer/BtnFechar") else null

var lbl_pagina: Label = null

# Variáveis para controlar a leitura
var paginas_do_texto: Array[String] = []
var pagina_atual: int = 0
var player_ref: Node2D = null

func _ready() -> void:
	layer = 99 # Mantém a interface acima de outros CanvasLayers/HUD
	add_to_group("parchment_ui")
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_configurar_layout_programatico()
	hide()
	
	if btn_esquerda and not btn_esquerda.pressed.is_connected(_voltar_pagina):
		btn_esquerda.pressed.connect(_voltar_pagina)
	if btn_direita and not btn_direita.pressed.is_connected(_avancar_pagina):
		btn_direita.pressed.connect(_avancar_pagina)
	if btn_fechar and not btn_fechar.pressed.is_connected(_fechar_pergaminho):
		btn_fechar.pressed.connect(_fechar_pergaminho)

## Ajusta o layout do pergaminho dinamicamente para resolver desalinhamentos de cena
func _configurar_layout_programatico() -> void:
	if control == null or background_papel == null or texto_dica == null:
		return
		
	# 1. Control ocupa a tela inteira
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# 2. Centraliza o BackgroundPapel (Pergaminho) na tela
	background_papel.anchor_left = 0.5
	background_papel.anchor_top = 0.5
	background_papel.anchor_right = 0.5
	background_papel.anchor_bottom = 0.5
	background_papel.offset_left = -380
	background_papel.offset_top = -250
	background_papel.offset_right = 380
	background_papel.offset_bottom = 250
	background_papel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_papel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# 3. Formata o TextoDica para ocupar o centro do papel com margens legíveis
	texto_dica.anchor_left = 0.0
	texto_dica.anchor_top = 0.0
	texto_dica.anchor_right = 1.0
	texto_dica.anchor_bottom = 1.0
	texto_dica.offset_left = 120
	texto_dica.offset_top = 75
	texto_dica.offset_right = -120
	texto_dica.offset_bottom = -90
	texto_dica.bbcode_enabled = true
	texto_dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto_dica.add_theme_color_override("default_color", Color(0.18, 0.10, 0.04, 1.0))
	texto_dica.add_theme_font_size_override("normal_font_size", 18)
	texto_dica.add_theme_font_size_override("bold_font_size", 19)
	
	# 4. Ajusta o BotoesContainer na parte inferior do papel
	if botoes_container:
		botoes_container.anchor_left = 0.5
		botoes_container.anchor_top = 1.0
		botoes_container.anchor_right = 0.5
		botoes_container.anchor_bottom = 1.0
		botoes_container.offset_left = -180
		botoes_container.offset_top = -75
		botoes_container.offset_right = 180
		botoes_container.offset_bottom = -25
		botoes_container.alignment = BoxContainer.ALIGNMENT_CENTER
		botoes_container.add_theme_constant_override("separation", 25)
		
		# Cria o indicador visual "Página X de Y" entre as setas
		if lbl_pagina == null:
			lbl_pagina = Label.new()
			lbl_pagina.name = "LblPagina"
			lbl_pagina.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl_pagina.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl_pagina.add_theme_color_override("font_color", Color(0.30, 0.15, 0.05, 1.0))
			lbl_pagina.add_theme_font_size_override("font_size", 16)
			botoes_container.add_child(lbl_pagina)
			if btn_direita:
				botoes_container.move_child(lbl_pagina, btn_direita.get_index())
				
	if btn_esquerda:
		btn_esquerda.custom_minimum_size = Vector2(48, 48)
	if btn_direita:
		btn_direita.custom_minimum_size = Vector2(48, 48)
	if btn_fechar:
		btn_fechar.custom_minimum_size = Vector2(48, 48)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
		
	if event.is_action_just_pressed("ui_cancel"):
		_fechar_pergaminho()
		get_viewport().set_input_as_handled()
	elif event.is_action_just_pressed("ui_left") or event.is_action_just_pressed("esquerda"):
		_voltar_pagina()
		get_viewport().set_input_as_handled()
	elif event.is_action_just_pressed("ui_right") or event.is_action_just_pressed("direita"):
		_avancar_pagina()
		get_viewport().set_input_as_handled()

func abrir_pergaminho(paginas: Array[String], player: Node2D = null) -> void:
	paginas_do_texto = paginas
	player_ref = player
	if player_ref:
		player_ref.travado = true
		
	pagina_atual = 0
	
	_configurar_layout_programatico()
	atualizar_tela()
	show()

func atualizar_tela() -> void:
	if paginas_do_texto.is_empty():
		return
		
	texto_dica.text = paginas_do_texto[pagina_atual]
	
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

func _fechar_pergaminho() -> void:
	hide()
	if player_ref:
		player_ref.travado = false
		player_ref = null

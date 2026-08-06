extends Area2D

## [Pergaminho/Baú] Componente de Baú com Pergaminhos Arcanos.
## Revela um pergaminho de até 4 páginas com dicas sobre as questões do andar/sala.
## Salva o pergaminho no inventário do jogador (Aba Grimório).

@export var titulo_pergaminho: String = "Pergaminho Arcano"
@export var usar_paginas_custom: bool = false
@export_multiline var paginas_custom: Array[String] = []
@export_range(1, 4) var num_paginas: int = 4

var ja_aberto: bool = false

@onready var sprite: Sprite2D = $BauSprite if has_node("BauSprite") else null

# Texturas da folha de sprite Alquimia/preto.png (32x32)
var tex_fechado: AtlasTexture
var tex_aberto: AtlasTexture

var player_perto: bool = false
var player_ref: Node2D = null
var canvas_prompt: CanvasLayer = null
var panel_prompt: PanelContainer = null

func _ready() -> void:
	# Prepara as texturas para o baú fechado e aberto
	var base_tex = load("res://assets/sprites/tilesets/Alquimia/preto.png")
	if base_tex:
		tex_fechado = AtlasTexture.new()
		tex_fechado.atlas = base_tex
		tex_fechado.region = Rect2(0, 128, 32, 32)
		
		tex_aberto = AtlasTexture.new()
		tex_aberto.atlas = base_tex
		tex_aberto.region = Rect2(32, 128, 32, 32)
		
		if sprite:
			sprite.texture = tex_fechado

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _exit_tree() -> void:
	_remover_prompt_tela()

func _exibir_prompt_tela() -> void:
	if canvas_prompt and is_instance_valid(canvas_prompt):
		return
		
	canvas_prompt = CanvasLayer.new()
	canvas_prompt.name = "PromptAbrirBau"
	add_child(canvas_prompt)
	
	panel_prompt = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.90)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.set_content_margin_all(10)
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_color = Color(0.95, 0.80, 0.25, 0.95)
	
	panel_prompt.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = "Pressione [F] para Abrir o Baú"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var font_pixel = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	if font_pixel:
		label.add_theme_font_override("font", font_pixel)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	
	panel_prompt.add_child(label)
	panel_prompt.custom_minimum_size = Vector2(420, 50)
	canvas_prompt.add_child(panel_prompt)
	
	panel_prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel_prompt.offset_top = -130
	panel_prompt.offset_bottom = -80
	panel_prompt.offset_left = 340
	panel_prompt.offset_right = -340

func _remover_prompt_tela() -> void:
	if canvas_prompt and is_instance_valid(canvas_prompt):
		canvas_prompt.queue_free()
		canvas_prompt = null
		panel_prompt = null

func _on_body_entered(body: Node2D) -> void:
	if ja_aberto:
		return
	if not body.is_in_group("player") and body.name != "Player":
		return
	player_perto = true
	player_ref = body
	_exibir_prompt_tela()

func _on_body_exited(body: Node2D) -> void:
	if body == player_ref or body.is_in_group("player") or body.name == "Player":
		player_perto = false
		player_ref = null
		_remover_prompt_tela()

func _unhandled_input(event: InputEvent) -> void:
	if not player_perto or ja_aberto:
		return
		
	var pressionou_f = (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F)
	if pressionou_f or event.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled()
		abrir_bau()

func abrir_bau() -> void:
	if ja_aberto:
		return
	ja_aberto = true
	
	_remover_prompt_tela()
	
	# Transiciona o sprite para o estado Aberto
	if sprite and tex_aberto:
		sprite.texture = tex_aberto

	# Toca efeito sonoro se disponível
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui-1")

	# Obtém as páginas do pergaminho (até 4 páginas)
	var paginas: Array[String] = []
	if usar_paginas_custom and paginas_custom.size() > 0:
		paginas = paginas_custom
	else:
		var andar_id = 1
		if get_node_or_null("/root/QuizManager"):
			andar_id = QuizManager._andar_atual
		paginas = PergaminhoManager.obter_paginas_dicas(andar_id, [], num_paginas)

	# Salva o pergaminho no Inventário (Aba Grimório)
	if get_node_or_null("/root/PlayerStats"):
		var nome_sala = ""
		if get_tree() and get_tree().current_scene:
			nome_sala = get_tree().current_scene.name
		var titulo_final = titulo_pergaminho
		if nome_sala != "":
			titulo_final += " (" + nome_sala + ")"
		PlayerStats.adicionar_pergaminho(titulo_final, paginas)

	# Localiza a UI do Pergaminho e abre
	var ui = get_tree().get_first_node_in_group("parchment_ui")
	if ui == null and get_tree().current_scene:
		ui = get_tree().current_scene.find_child("ParchmentUI", true, false)

	if ui and ui.has_method("abrir_pergaminho"):
		ui.abrir_pergaminho(paginas, player_ref)
	else:
		push_warning("[Bau] ParchmentUI não foi encontrado na cena!")


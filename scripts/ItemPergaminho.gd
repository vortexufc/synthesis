extends Area2D

# Textos do pergaminho
@export var titulo_pergaminho: String = "Pergaminho Encontrado"
@export_multiline var paginas: Array[String] = [
	"Página 1 do pergaminho...",
	"Página 2 do pergaminho..."
]

var player_perto: bool = false
var player_ref: Node2D = null
var canvas_prompt: CanvasLayer = null
var panel_prompt: PanelContainer = null

func _ready() -> void:
	body_entered.connect(_quando_corpo_entra)
	body_exited.connect(_quando_corpo_sai)

func _exit_tree() -> void:
	_remover_prompt_tela()

func _exibir_prompt_tela() -> void:
	if canvas_prompt and is_instance_valid(canvas_prompt):
		return
		
	canvas_prompt = CanvasLayer.new()
	canvas_prompt.name = "PromptColetaPergaminho"
	add_child(canvas_prompt)
	
	panel_prompt = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.90) # Escuro translúcido arcano
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.set_content_margin_all(10)
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_color = Color(0.95, 0.80, 0.25, 0.95) # Borda dourada brilhante
	
	panel_prompt.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = "Pressione [F] para Coletar o Pergaminho"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var font_pixel = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	if font_pixel:
		label.add_theme_font_override("font", font_pixel)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7)) # Amarelo ouro
	
	panel_prompt.add_child(label)
	panel_prompt.custom_minimum_size = Vector2(460, 50)
	canvas_prompt.add_child(panel_prompt)
	
	# Posiciona centralizado no rodapé da tela (mesmo padrão das portas)
	panel_prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel_prompt.offset_top = -130
	panel_prompt.offset_bottom = -80
	panel_prompt.offset_left = 320
	panel_prompt.offset_right = -320

func _remover_prompt_tela() -> void:
	if canvas_prompt and is_instance_valid(canvas_prompt):
		canvas_prompt.queue_free()
		canvas_prompt = null
		panel_prompt = null

func _quando_corpo_entra(corpo: Node2D) -> void:
	if not corpo.is_in_group("player") and corpo.name != "Player":
		return
	player_perto = true
	player_ref = corpo
	_exibir_prompt_tela()

func _quando_corpo_sai(corpo: Node2D) -> void:
	if corpo == player_ref or corpo.is_in_group("player") or corpo.name == "Player":
		player_perto = false
		player_ref = null
		_remover_prompt_tela()

func _unhandled_input(event: InputEvent) -> void:
	if not player_perto:
		return
		
	var pressionou_f = (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F)
	if pressionou_f or event.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled()
		coletar()

func coletar() -> void:
	_remover_prompt_tela()
		
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui-1")

	# Salva no Inventário
	if get_node_or_null("/root/PlayerStats"):
		PlayerStats.adicionar_pergaminho(titulo_pergaminho, paginas)

	# Abre o pergaminho na tela dinamicamente ao coletar com a tecla F
	var ui = get_tree().get_first_node_in_group("parchment_ui")
	if ui == null and get_tree().current_scene:
		ui = get_tree().current_scene.find_child("ParchmentUI", true, false)

	if ui and ui.has_method("abrir_pergaminho"):
		ui.abrir_pergaminho(paginas, player_ref)

	# Remove o pergaminho do mapa
	queue_free()




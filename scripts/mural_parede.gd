extends Area2D

# mural na parede com infografico (aperta F pra ver)

@export_enum("Automático (Detectar pela Sala)", "Andar 1 (Química)", "Andar 2 (Física)", "Andar 3 (Biologia)") var forcar_andar: int = 0
@export var recompensa_descoberta: int = 0

var ja_examinado: bool = false
var player_perto: bool = false
var player_ref: Node2D = null
var canvas_prompt: CanvasLayer = null
var panel_prompt: PanelContainer = null
var mural_ui_instancia: CanvasLayer = null

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_criar_aura_brilho()

func _exit_tree() -> void:
	_remover_prompt_tela()
	if mural_ui_instancia and is_instance_valid(mural_ui_instancia):
		mural_ui_instancia.queue_free()

func _criar_aura_brilho() -> void:
	var andar = _determinar_andar()
	var cor_brilho_centro = Color(0.3, 0.8, 1.0, 0.50)
	var cor_brilho_meio = Color(0.7, 0.3, 1.0, 0.30)
	
	match andar:
		1: # quimica
			cor_brilho_centro = Color(0.25, 0.85, 1.0, 0.55)
			cor_brilho_meio = Color(0.75, 0.35, 1.0, 0.32)
		2: # fisica
			cor_brilho_centro = Color(1.0, 0.88, 0.25, 0.60)
			cor_brilho_meio = Color(1.0, 0.48, 0.12, 0.35)
		3: # biologia
			cor_brilho_centro = Color(0.25, 1.0, 0.55, 0.55)
			cor_brilho_meio = Color(0.12, 0.75, 0.38, 0.32)

	var grad = Gradient.new()
	grad.colors = PackedColorArray([
		cor_brilho_centro,
		cor_brilho_meio,
		Color(0.05, 0.0, 0.15, 0.0)
	])
	grad.offsets = PackedFloat32Array([0.0, 0.52, 1.0])

	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 56
	tex.height = 56

	var aura = Sprite2D.new()
	aura.name = "AuraMural"
	aura.texture = tex
	aura.scale = Vector2(1.6, 1.6)
	aura.z_index = 0
	add_child(aura)
	move_child(aura, 0)

	var tw = create_tween().set_loops().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(aura, "scale", Vector2(1.95, 1.95), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(aura, "scale", Vector2(1.5, 1.5), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _determinar_andar() -> int:
	if forcar_andar > 0:
		return forcar_andar
		
	var cena_atual = ""
	if get_tree() and get_tree().current_scene:
		cena_atual = get_tree().current_scene.scene_file_path.to_lower()
		
	var caminho_completo = (cena_atual + " " + String(get_path())).to_lower()
		
	if "quimica" in caminho_completo or "alquimia" in caminho_completo:
		return 1
	elif "fisica" in caminho_completo or "física" in caminho_completo:
		return 2
	elif "biologia" in caminho_completo or "bio" in caminho_completo:
		return 3
		
	return 1

func _on_body_entered(body: Node2D) -> void:
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
	if not player_perto:
		return
		
	var pressionou_f = (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F)
	if pressionou_f or event.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled()
		examinar_mural()

func examinar_mural() -> void:
	_remover_prompt_tela()
	
	var andar = _determinar_andar()
	
	if not mural_ui_instancia or not is_instance_valid(mural_ui_instancia):
		var cena_ui = load("res://scenes/ui/mural_ui.tscn")
		if cena_ui:
			mural_ui_instancia = cena_ui.instantiate()
			get_tree().root.add_child(mural_ui_instancia)
			mural_ui_instancia.mural_fechado.connect(func():
				if player_perto:
					_exibir_prompt_tela()
			)
			
	if mural_ui_instancia:
		mural_ui_instancia.abrir_mural(andar, player_ref)
		
	# Recompensa de primeira descoberta
	if not ja_examinado and recompensa_descoberta > 0:
		ja_examinado = true
		var ps = get_node_or_null("/root/PlayerStats")
		if ps and ps.has_method("adicionar_moedas"):
			ps.adicionar_moedas(recompensa_descoberta)
			print("[Mural] Descoberta Científica! +%d Moedas concedidas." % recompensa_descoberta)

func _exibir_prompt_tela() -> void:
	if canvas_prompt and is_instance_valid(canvas_prompt):
		return
		
	canvas_prompt = CanvasLayer.new()
	canvas_prompt.name = "PromptMural"
	add_child(canvas_prompt)
	
	panel_prompt = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.14, 0.92)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	style.set_border_width_all(2)
	style.border_color = Color(0.35, 0.85, 1.0, 0.95)
	panel_prompt.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = "Pressione [F] - Examinar Inscrição Ancestral"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var font_pixel = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	if font_pixel:
		label.add_theme_font_override("font", font_pixel)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.8, 0.95, 1.0))
	
	panel_prompt.add_child(label)
	panel_prompt.custom_minimum_size = Vector2(440, 50)
	canvas_prompt.add_child(panel_prompt)
	
	panel_prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel_prompt.offset_top = -130
	panel_prompt.offset_bottom = -80
	panel_prompt.offset_left = 330
	panel_prompt.offset_right = -330

func _remover_prompt_tela() -> void:
	if canvas_prompt and is_instance_valid(canvas_prompt):
		canvas_prompt.queue_free()
		canvas_prompt = null
		panel_prompt = null

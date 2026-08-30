extends Area2D

var player_perto: bool = false
var canvas_prompt: CanvasLayer = null
var panel_prompt: PanelContainer = null

var _tween_brilho: Tween
var _tween_bob: Tween

func _ready() -> void:
	collision_layer = 0
	collision_mask = 15 # Pega o player independentemente da layer 1-4
	
	body_entered.connect(_quando_corpo_entra)
	body_exited.connect(_quando_corpo_sai)
	_iniciar_efeito_brilho()

func _iniciar_efeito_brilho() -> void:
	var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		for child in get_children():
			if child is Sprite2D:
				sprite = child as Sprite2D
				break
				
	if sprite:
		_tween_brilho = create_tween().set_loops()
		_tween_brilho.tween_property(sprite, "modulate", Color(1.5, 1.5, 0.5, 1.0), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween_brilho.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		var pos_y = sprite.position.y
		_tween_bob = create_tween().set_loops()
		_tween_bob.tween_property(sprite, "position:y", pos_y - 4.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween_bob.tween_property(sprite, "position:y", pos_y + 4.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _exit_tree() -> void:
	_remover_prompt_tela()

func _exibir_prompt_tela() -> void:
	if canvas_prompt and is_instance_valid(canvas_prompt):
		return
		
	canvas_prompt = CanvasLayer.new()
	canvas_prompt.name = "PromptColetaChave"
	add_child(canvas_prompt)
	
	panel_prompt = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.12, 0.90) 
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.set_content_margin_all(10)
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_color = Color(0.8, 0.8, 0.8, 0.95)
	
	panel_prompt.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = "Pressione [F] para Coletar a Chave Secreta"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var font_pixel = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	if font_pixel:
		label.add_theme_font_override("font", font_pixel)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	panel_prompt.add_child(label)
	panel_prompt.custom_minimum_size = Vector2(460, 50)
	canvas_prompt.add_child(panel_prompt)
	
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
	_exibir_prompt_tela()

func _quando_corpo_sai(corpo: Node2D) -> void:
	if corpo.is_in_group("player") or corpo.name == "Player":
		player_perto = false
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

	if get_node_or_null("/root/PlayerStats"):
		PlayerStats.chaves += 1
		print("Chave coletada! Total: ", PlayerStats.chaves)

	queue_free()

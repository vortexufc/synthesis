extends StaticBody2D

var player_perto: bool = false
var canvas_prompt: CanvasLayer = null
var panel_prompt: PanelContainer = null
var label_prompt: Label = null

func _ready() -> void:
	# Cria a área de interação via código para facilitar
	var area = Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 15 # Máscara 15 (Pega layers 1, 2, 3 e 4 - impossível errar o player)
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 65.0 # Bem perto da porta
	shape.shape = circle
	area.add_child(shape)
	add_child(area)
	
	area.body_entered.connect(_quando_corpo_entra)
	area.body_exited.connect(_quando_corpo_sai)

func _exit_tree() -> void:
	_remover_prompt_tela()

func _exibir_prompt_tela() -> void:
	if canvas_prompt and is_instance_valid(canvas_prompt):
		_atualizar_texto_prompt()
		return
		
	canvas_prompt = CanvasLayer.new()
	canvas_prompt.name = "PromptPortaTrancada"
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
	
	label_prompt = Label.new()
	label_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var font_pixel = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	if font_pixel:
		label_prompt.add_theme_font_override("font", font_pixel)
	label_prompt.add_theme_font_size_override("font_size", 18)
	label_prompt.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	panel_prompt.add_child(label_prompt)
	panel_prompt.custom_minimum_size = Vector2(460, 50)
	canvas_prompt.add_child(panel_prompt)
	
	panel_prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel_prompt.offset_top = -130
	panel_prompt.offset_bottom = -80
	panel_prompt.offset_left = 320
	panel_prompt.offset_right = -320
	
	_atualizar_texto_prompt()

func _atualizar_texto_prompt() -> void:
	if not label_prompt: return
	
	var dev_mgr = get_node_or_null("/root/DevManager")
	var ignorar = dev_mgr and dev_mgr.DEV_MODE_ENABLED and dev_mgr.passar_portas_trancadas
	
	var tem_chave = false
	if get_node_or_null("/root/PlayerStats"):
		tem_chave = PlayerStats.chaves > 0
		
	if tem_chave or ignorar:
		label_prompt.text = "Pressione [F] para Usar a Chave Secreta"
		label_prompt.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3)) # Verde
	else:
		label_prompt.text = "Use a chave secreta para acessar essa porta."
		label_prompt.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3)) # Vermelho

func _remover_prompt_tela() -> void:
	if canvas_prompt and is_instance_valid(canvas_prompt):
		canvas_prompt.queue_free()
		canvas_prompt = null
		panel_prompt = null
		label_prompt = null

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
		tentar_abrir()

func tentar_abrir() -> void:
	var dev_mgr = get_node_or_null("/root/DevManager")
	var ignorar = dev_mgr and dev_mgr.DEV_MODE_ENABLED and dev_mgr.passar_portas_trancadas
	
	var player_stats = get_node_or_null("/root/PlayerStats")
	var tem_chave = player_stats and player_stats.chaves > 0
	
	if tem_chave or ignorar:
		if tem_chave and not ignorar:
			player_stats.chaves -= 1
			print("Porta aberta! Chaves restantes: ", player_stats.chaves)
		
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("ui-1") # Pode trocar por som de porta depois
			
		_remover_prompt_tela()
		
		# Recupera a PortaTransicao original e reativa ela
		var pai = get_parent()
		if pai:
			var porta_original = pai.get_node_or_null("PortaTransicao")
			if porta_original:
				porta_original.process_mode = Node.PROCESS_MODE_INHERIT
				porta_original.show()
				porta_original._porta_aberta = true
				if porta_original.has_method("_abrir_porta_animacao"):
					porta_original._abrir_porta_animacao()
				
				# Força a transição, pois o player já está encostado nela e o sinal body_entered pode não re-disparar sozinho
				if porta_original.has_method("_transacionar_porta"):
					porta_original._transacionar_porta()
					
		queue_free() # Destrói a tranca, liberando a porta original
	else:
		# Feedback visual de erro, balançando o texto
		if label_prompt:
			var tween = create_tween()
			var pos_x = label_prompt.position.x
			tween.tween_property(label_prompt, "position:x", pos_x - 5, 0.05)
			tween.tween_property(label_prompt, "position:x", pos_x + 5, 0.05)
			tween.tween_property(label_prompt, "position:x", pos_x, 0.05)

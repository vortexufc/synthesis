extends Area2D

var player_perto: bool = false
var player_ref: Node2D = null
var canvas_prompt: CanvasLayer = null
var panel_prompt: PanelContainer = null

var _tween_brilho: Tween
var _tween_glow: Tween
var _tween_bob: Tween
var _coletado: bool = false

func _ready() -> void:
	z_index = 2
	collision_layer = 0
	collision_mask = 15 # Detecta o player
	body_entered.connect(_quando_corpo_entra)
	body_exited.connect(_quando_corpo_sai)
	
	_iniciar_efeito_brilho()
	call_deferred("_verificar_player_inicial")

func _iniciar_efeito_brilho() -> void:
	var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		for child in get_children():
			if child is Sprite2D and child.name != "GlowSprite":
				sprite = child as Sprite2D
				break
				
	# glow amarelo atras
	var glow: Sprite2D = get_node_or_null("GlowSprite") as Sprite2D
	if glow == null:
		glow = Sprite2D.new()
		glow.name = "GlowSprite"
		var tex_glow = load("res://assets/sprites/ui/glow_yellow.png") as Texture2D
		if tex_glow:
			glow.texture = tex_glow
			glow.scale = Vector2(0.4, 0.4)
			glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			add_child(glow)
			move_child(glow, 0)
			
	if glow:
		glow.modulate = Color(1.0, 0.9, 0.3, 0.5)
		_tween_glow = create_tween().set_loops()
		_tween_glow.tween_property(glow, "modulate:a", 0.85, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween_glow.tween_property(glow, "modulate:a", 0.35, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
	# chave flutuando
	if sprite:
		_tween_brilho = create_tween().set_loops()
		_tween_brilho.tween_property(sprite, "modulate", Color(1.7, 1.45, 0.35, 1.0), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween_brilho.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		var pos_y = sprite.position.y
		_tween_bob = create_tween().set_loops()
		_tween_bob.tween_property(sprite, "position:y", pos_y - 4.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween_bob.tween_property(sprite, "position:y", pos_y + 4.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		# sombra no chao
		_criar_sombra()
		if _shadow:
			var tw_s = create_tween().set_loops()
			tw_s.tween_property(_shadow, "scale", Vector2(0.75, 0.40), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw_s.parallel().tween_property(_shadow, "modulate:a", 0.65, 0.9)
			tw_s.tween_property(_shadow, "scale", Vector2(1.00, 0.55), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw_s.parallel().tween_property(_shadow, "modulate:a", 0.90, 0.9)

var _shadow: Sprite2D = null

func _criar_sombra() -> void:
	if _shadow == null:
		_shadow = get_node_or_null("Shadow") as Sprite2D
	if _shadow != null:
		_shadow.z_as_relative = false
		_shadow.z_index = 1
		return
	_shadow = Sprite2D.new()
	_shadow.name = "Shadow"
	var tex_shadow = load("res://assets/sprites/Characters/Maguinho/shadow.png") as Texture2D
	if tex_shadow:
		_shadow.texture = tex_shadow
		_shadow.position = Vector2(0, 30)
		_shadow.scale = Vector2(0.9, 0.5)
		_shadow.modulate = Color(1.0, 1.0, 1.0, 0.85)
		_shadow.z_as_relative = false
		_shadow.z_index = 1
		add_child(_shadow)
		move_child(_shadow, 0)

	# luz no chao
	var luz: PointLight2D = get_node_or_null("LuzChave") as PointLight2D
	if luz == null:
		luz = PointLight2D.new()
		luz.name = "LuzChave"
		var tex_glow = load("res://assets/sprites/ui/glow_yellow.png") as Texture2D
		if tex_glow:
			luz.texture = tex_glow
			luz.texture_scale = 0.5
			luz.color = Color(1.0, 0.85, 0.35)
			luz.energy = 0.8
			add_child(luz)

func _verificar_player_inicial() -> void:
	for corpo in get_overlapping_bodies():
		if _eh_player(corpo):
			_quando_corpo_entra(corpo)
			break

func _eh_player(corpo: Node2D) -> bool:
	return corpo != null and (corpo.is_in_group("player") or corpo.name == "Player" or corpo.name.begins_with("Player"))

func _quando_corpo_entra(corpo: Node2D) -> void:
	if _coletado or not _eh_player(corpo):
		return
	player_perto = true
	player_ref = corpo
	_exibir_prompt_tela()

func _quando_corpo_sai(corpo: Node2D) -> void:
	if corpo == player_ref or _eh_player(corpo):
		player_perto = false
		player_ref = null
		_remover_prompt_tela()

func _exibir_prompt_tela() -> void:
	if canvas_prompt and is_instance_valid(canvas_prompt):
		return
		
	canvas_prompt = CanvasLayer.new()
	canvas_prompt.name = "PromptColetaChave"
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
	label.text = "Pressione [F] para Coletar a Chave"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var font_pixel = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	if font_pixel:
		label.add_theme_font_override("font", font_pixel)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7)) # Amarelo ouro
	
	panel_prompt.add_child(label)
	panel_prompt.custom_minimum_size = Vector2(420, 50)
	canvas_prompt.add_child(panel_prompt)
	
	# Posiciona centralizado no rodapé da tela (mesmo padrão do pergaminho e das portas)
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

func _unhandled_input(event: InputEvent) -> void:
	if not player_perto or _coletado:
		return
		
	var pressionou_f = (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F)
	if pressionou_f or event.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled()
		coletar()

func coletar() -> void:
	if _coletado:
		return
	_coletado = true
	_remover_prompt_tela()
	
	# Adiciona chave nas estatísticas do jogador
	if get_node_or_null("/root/PlayerStats"):
		PlayerStats.chaves += 1
		PlayerStats.salvar()
		print("Chave coletada via [F]! Total: ", PlayerStats.chaves)
		
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("mostrar_mensagem"):
			hud.mostrar_mensagem("Você coletou 1 Chave de Porta!")
			
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui-1")
		
	# animacao e particulas de coleta
	if _tween_brilho and _tween_brilho.is_valid(): _tween_brilho.kill()
	if _tween_glow and _tween_glow.is_valid(): _tween_glow.kill()
	if _tween_bob and _tween_bob.is_valid(): _tween_bob.kill()
	
	var pos_coleta = global_position
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		pos_coleta = sprite.global_position
		
	var part = CPUParticles2D.new()
	part.top_level = true
	part.z_index = 15
	part.local_coords = false
	
	var mat_p = CanvasItemMaterial.new()
	mat_p.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	part.material = mat_p
	
	var grad_tex = Gradient.new()
	grad_tex.offsets = PackedFloat32Array([0, 0.6, 1])
	grad_tex.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 0.9, 0.4, 0.9), Color(1, 0.6, 0.1, 0)])
	var tex_spark = GradientTexture2D.new()
	tex_spark.gradient = grad_tex
	tex_spark.width = 10
	tex_spark.height = 10
	tex_spark.fill = GradientTexture2D.FILL_RADIAL
	tex_spark.fill_from = Vector2(0.5, 0.5)
	tex_spark.fill_to = Vector2(0.5, 0)
	part.texture = tex_spark
	
	part.amount = 16
	part.lifetime = 0.60
	part.one_shot = true
	part.explosiveness = 0.9
	part.direction = Vector2(0, -1)
	part.spread = 180.0
	part.gravity = Vector2(0, 45)
	part.initial_velocity_min = 45.0
	part.initial_velocity_max = 95.0
	part.scale_amount_min = 0.7
	part.scale_amount_max = 1.4
	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color(1.0, 0.95, 0.4, 1.0), Color(1.0, 0.5, 0.05, 0.0)])
	part.color_ramp = grad
	
	var arvore = get_tree()
	var pai = arvore.current_scene if (arvore and arvore.current_scene) else get_parent()
	if pai:
		pai.add_child(part)
	else:
		get_tree().root.add_child(part)
	part.global_position = pos_coleta
	part.emitting = true
	part.restart()
	if arvore:
		arvore.create_timer(0.7).timeout.connect(part.queue_free)
	
	var tween_coleta = create_tween()
	tween_coleta.set_parallel(true)
	tween_coleta.tween_property(self, "position:y", position.y - 34.0, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_coleta.tween_property(self, "scale", scale * 1.35, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_coleta.tween_property(self, "modulate", Color(1.7, 1.7, 1.1, 1.0), 0.20)
	tween_coleta.chain().set_parallel(true)
	tween_coleta.tween_property(self, "scale", Vector2.ZERO, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween_coleta.tween_property(self, "modulate:a", 0.0, 0.22)
	await tween_coleta.finished
	queue_free()

func _exit_tree() -> void:
	_remover_prompt_tela()

extends CanvasLayer

var is_transitioning: bool = false

@onready var color_rect = $ColorRect as ColorRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if color_rect and color_rect.material is ShaderMaterial:
		(color_rect.material as ShaderMaterial).set_shader_parameter("progresso", 0.0)
	if color_rect:
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func change_scene(target_scene: String, porta_de_retorno: bool = false) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	# cancela batalha se tiver mudando de sala
	if get_node_or_null("/root/QuizManager"):
		var qm = get_node("/root/QuizManager")
		if qm.has_method("fechar_ui_batalha"):
			qm.fechar_ui_batalha()
		qm.set("em_batalha", false)
	
	var vp_size = get_viewport().get_visible_rect().size
	
	var mat = color_rect.material as ShaderMaterial if color_rect else null
	
	# tipo de transicao: fade pra menu e portal iris pras salas
	var eh_menu = "/ui/" in target_scene or "menu" in target_scene.to_lower() or "login" in target_scene.to_lower() or "cadastro" in target_scene.to_lower()
	if get_tree().current_scene:
		var cena_antiga = get_tree().current_scene.scene_file_path.to_lower()
		if "/ui/" in cena_antiga or "menu" in cena_antiga or "login" in cena_antiga:
			eh_menu = true
			
	if mat:
		mat.set_shader_parameter("modo", 1 if eh_menu else 0)
		mat.set_shader_parameter("progresso", 0.0)
		
	if color_rect:
		color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		
	# trava o player durante a transicao
	get_tree().get_root().set_disable_input(true)
	
	# toca som de transicao
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("transicao-1")
		
	# fecha o portal
	if mat:
		var tween_in = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween_in.tween_method(func(v: float): mat.set_shader_parameter("progresso", v), 0.0, 1.0, 0.36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		await tween_in.finished
	else:
		await get_tree().create_timer(0.3, true, false, true).timeout
	
	# se for pro hub, corredor ou menu pula a animacao
	var pular_animacao = false
	if "Corredor.tscn" in target_scene or "Hub_Geral" in target_scene or "/ui/" in target_scene or "Menu" in target_scene:
		pular_animacao = true
		
	# pula se estiver saindo do corredor
	if get_tree().current_scene and "Corredor.tscn" in get_tree().current_scene.scene_file_path:
		pular_animacao = true
		
	# por enquanto so toca cutscene em quimica
	if "Fisica" in target_scene or "Física" in target_scene or "Biologia" in target_scene:
		pular_animacao = true
	
	if not pular_animacao:
		await _tocar_animacao_corredor(vp_size, porta_de_retorno)
	else:
		# pausa rapida com a tela escura
		await get_tree().create_timer(0.18, true, false, true).timeout

	# troca a cena
	get_tree().change_scene_to_file(target_scene)
	
	# espera carregar
	await get_tree().create_timer(0.08, true, false, true).timeout
	
	# abre a transicao revelando o mapa
	if mat:
		var tween_out = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween_out.tween_method(func(v: float): mat.set_shader_parameter("progresso", v), 1.0, 0.0, 0.40).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		await tween_out.finished
		
	if color_rect:
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# despausa o jogo
	get_tree().paused = false
	get_tree().get_root().set_disable_input(false)
	is_transitioning = false
	
	# diminui 1 sala do buff de escudo
	var t_lower = target_scene.to_lower()
	var eh_sala_masmorra = not ("/ui/" in t_lower or "menu" in t_lower or "hub" in t_lower or "login" in t_lower or "cadastro" in t_lower or "config" in t_lower)
	if eh_sala_masmorra and get_node_or_null("/root/PlayerStats"):
		PlayerStats.decrementar_buff_escudo()

func _obter_textura_luz() -> Texture2D:
	var grad_tex = GradientTexture2D.new()
	var grad = Gradient.new()
	grad.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CUBIC
	grad.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	grad.colors = PackedColorArray([
		Color(1, 1, 1, 1.0),
		Color(1, 1, 1, 0.4),
		Color(1, 1, 1, 0.0)
	])
	grad_tex.gradient = grad
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(1.0, 0.5)
	grad_tex.width = 256
	grad_tex.height = 256
	return grad_tex

func _tocar_animacao_corredor(vp_size: Vector2, porta_de_retorno: bool) -> void:
	# viewport pra renderizar a animacao do corredor
	var vp_container = SubViewportContainer.new()
	vp_container.anchors_preset = Control.PRESET_FULL_RECT
	
	var vp = SubViewport.new()
	vp.size = vp_size
	vp.transparent_bg = true
	vp_container.add_child(vp)
	add_child(vp_container)
	move_child(vp_container, -1)
	
	# carrega a ceninha do corredor
	var cena_corredor = load("res://scenes/Salas/Comum/MiniCorredorTransicao.tscn")
	var corredor = cena_corredor.instantiate()
	vp.add_child(corredor)
	
	var porta_cima = corredor.get_node_or_null("PortaTransicao")
	var porta_baixo = corredor.get_node_or_null("PortaRetorno")

	# luzes dos portais
	var tex_luz = _obter_textura_luz()
				
	# luz nos portais
	if porta_cima:
		var luz_p_cima = PointLight2D.new()
		luz_p_cima.name = "LuzPortalCima"
		luz_p_cima.texture = tex_luz
		luz_p_cima.color = Color(0.85, 0.38, 1.0, 1.0) # Roxo arcano alquímico
		luz_p_cima.energy = 0.50
		luz_p_cima.texture_scale = 1.50
		luz_p_cima.position = Vector2(0, -25)
		porta_cima.add_child(luz_p_cima)
	if porta_baixo:
		var luz_p_baixo = PointLight2D.new()
		luz_p_baixo.name = "LuzPortalBaixo"
		luz_p_baixo.texture = tex_luz
		luz_p_baixo.color = Color(0.25, 0.78, 1.0, 1.0) # Azul misterioso
		luz_p_baixo.energy = 0.50
		luz_p_baixo.texture_scale = 1.50
		luz_p_baixo.position = Vector2(0, -25)
		porta_baixo.add_child(luz_p_baixo)
	
	# camera focada no corredor
	var cam = corredor.get_node_or_null("Camera2D") as Camera2D
	if not cam:
		cam = Camera2D.new()
		vp.add_child(cam)
	if porta_de_retorno:
		cam.position = Vector2(628, 1040) # Câmera começa no novo topo
	else:
		cam.position = Vector2(628, 1150) # Câmera na base
	
	# cria o bonequinho do mago correndo
	var dummy = load("res://scenes/Entidades/player.tscn").instantiate()
	dummy.set_script(null)
	for child in dummy.get_children():
		if child is Camera2D or child is CollisionShape2D or child is AudioStreamPlayer2D or child.name == "PointLight2D":
			child.queue_free()
			
	if porta_de_retorno:
		dummy.position = Vector2(628, 940) # Boneco nasce dentro do novo topo
	else:
		dummy.position = Vector2(628, 1250) # Boneco dentro da porta de baixo
	vp.add_child(dummy)
	
	# luz que segue os passos dele
	var luz_player = PointLight2D.new()
	luz_player.name = "AuraPlayer"
	luz_player.texture = tex_luz
	luz_player.color = Color(1.0, 0.94, 0.82, 1.0) # Luz mágica acolhedora
	luz_player.energy = 0.38
	luz_player.texture_scale = 1.65
	luz_player.position = Vector2(0, -10)
	dummy.add_child(luz_player)
	
	var sprite = dummy.get_node_or_null("sprite")
	if sprite:
		if porta_de_retorno:
			sprite.play("correr_baixo")
		else:
			sprite.play("correr_cima")
			
	# som de passos
	var passo_timer = Timer.new()
	passo_timer.wait_time = 0.28
	passo_timer.autostart = true
	passo_timer.timeout.connect(func():
		if get_node_or_null("/root/AudioManager"):
			AudioManager.tocar_som_caminhada()
	)
	add_child(passo_timer)
	if get_node_or_null("/root/AudioManager"): AudioManager.tocar_som_caminhada()

	# pisca a luz das tochas
	var luzes_tochas: Array = corredor.find_children("", "PointLight2D", true, false)
	var tween_flicker = create_tween().set_loops().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_flicker.tween_callback(func():
		for t in luzes_tochas:
			if is_instance_valid(t):
				t.energy = randf_range(0.55, 0.70)
		if is_instance_valid(luz_player):
			luz_player.energy = randf_range(0.35, 0.41)
	).set_delay(0.08)
		
	# move o boneco e a camera pro fim
	var tween_walk = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if porta_de_retorno:
		tween_walk.tween_property(dummy, "position:y", 1250, 1.0)
		tween_walk.tween_property(cam, "position:y", 1150, 1.0)
	else:
		tween_walk.tween_property(dummy, "position:y", 940, 1.0)
		tween_walk.tween_property(cam, "position:y", 1040, 1.0)
	
	await tween_walk.finished
	tween_flicker.kill()
	passo_timer.queue_free()
		
	# limpa o viewport
	vp_container.queue_free()

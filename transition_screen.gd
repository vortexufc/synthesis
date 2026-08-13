extends CanvasLayer

func change_scene(target_scene: String, porta_de_retorno: bool = false) -> void:
	var vp_size = get_viewport().get_visible_rect().size
	
	# 1. Fundo Preto total
	var black_bg = ColorRect.new()
	black_bg.color = Color.BLACK
	black_bg.size = vp_size
	black_bg.modulate.a = 0.0
	add_child(black_bg)
	
	# Bloqueia input do player pra não mexer durante o loading
	get_tree().get_root().set_disable_input(true)
	
	# Fade In pro escuro
	var tween_in = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_in.tween_property(black_bg, "modulate:a", 1.0, 0.3)
	await tween_in.finished
	
	# Verifica se é para pular a animação (ir para o Corredor, para o Hub, ou qualquer tela de UI/Menu)
	var pular_animacao = false
	if "Corredor.tscn" in target_scene or "Hub_Geral" in target_scene or "/ui/" in target_scene or "Menu" in target_scene:
		pular_animacao = true
		
	# Também pula se a gente estiver saindo do corredor para outra sala
	if get_tree().current_scene and "Corredor.tscn" in get_tree().current_scene.scene_file_path:
		pular_animacao = true
		
	# Retira a cutscene nas portas de Física e Biologia (pois o corredor atual é de Química)
	if "Fisica" in target_scene or "Física" in target_scene or "Biologia" in target_scene:
		pular_animacao = true
	
	if not pular_animacao:
		await _tocar_animacao_corredor(vp_size, porta_de_retorno)
	else:
		# Pausa super rápida enquanto a tela tá preta
		await get_tree().create_timer(0.3, true, false, true).timeout

	# Muda a cena de verdade no jogo
	get_tree().change_scene_to_file(target_scene)
	
	# Faz um tempinho pro novo mapa carregar
	await get_tree().create_timer(0.1, true, false, true).timeout
	
	# Fade Out (voltando a clarear)
	var tween_out = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_out.tween_property(black_bg, "modulate:a", 0.0, 0.4)
	await tween_out.finished
	
	black_bg.queue_free()
	
	# Garante que, ao carregar a nova sala, o jogo não fique pausado (caso algum monstro tenha pausado durante o fade)
	get_tree().paused = false
	get_tree().get_root().set_disable_input(false)

func _tocar_animacao_corredor(vp_size: Vector2, porta_de_retorno: bool) -> void:
	# 2. Cria um SubViewport para renderizar o Corredor real em 2D na tela!
	var vp_container = SubViewportContainer.new()
	vp_container.anchors_preset = Control.PRESET_FULL_RECT
	
	var vp = SubViewport.new()
	vp.size = vp_size
	vp.transparent_bg = true
	vp_container.add_child(vp)
	add_child(vp_container)
	
	# Carrega e limpa o mapa do Corredor
	var cena_corredor = load("res://scenes/Salas/Salas_BuildTGXP/Corredor.tscn")
	var corredor = cena_corredor.instantiate()
	corredor.set_script(null)
	
	# Deleta tudo que não for mapa nem porta
	for child in corredor.get_children():
		if child is TileMapLayer or child is TileMap:
			continue
		elif child.name == "PortaTransicao" or child.name == "PortaRetorno":
			continue
		else:
			child.queue_free()
	
	vp.add_child(corredor)
	
	# Encurta o corredor magicamente (move o arco de pedra e a porta do topo lá pra baixo!)
	var offset_y_tiles = 14
	for layer_name in ["Floor", "Wall", "Decoration"]:
		var layer = corredor.get_node_or_null(layer_name)
		if layer and layer is TileMapLayer:
			var used = layer.get_used_cells()
			var top_tiles = []
			for cell in used:
				if cell.y < 12: # Pega as 12 primeiras linhas (onde fica a porta do topo)
					top_tiles.append({
						"pos": cell, 
						"source": layer.get_cell_source_id(cell), 
						"atlas": layer.get_cell_atlas_coords(cell), 
						"alt": layer.get_cell_alternative_tile(cell)
					})
					layer.set_cell(cell, -1) # Apaga original
			
			for t in top_tiles:
				var new_pos = t.pos + Vector2i(0, offset_y_tiles)
				layer.set_cell(new_pos, t.source, t.atlas, t.alt)
				
	var porta_cima = corredor.get_node_or_null("PortaTransicao")
	if porta_cima:
		porta_cima.position.y += (offset_y_tiles * 48) # 48 é o tamanho do tile (16 * scale 3)
	
	# 3. Coloca uma Câmera apontando pro início/fim do corredor
	var cam = Camera2D.new()
	if porta_de_retorno:
		cam.position = Vector2(628, 1040) # Câmera começa no novo topo
	else:
		cam.position = Vector2(628, 1150) # Câmera na base
	vp.add_child(cam)
	
	# 4. Pega o Sprite do Player
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
	
	var sprite = dummy.get_node_or_null("sprite")
	if sprite:
		if porta_de_retorno:
			sprite.play("correr_baixo")
		else:
			sprite.play("correr_cima")
			
	# Toca o som de passo a cada 0.3s
	var passo_timer = Timer.new()
	passo_timer.wait_time = 0.28
	passo_timer.autostart = true
	passo_timer.timeout.connect(func():
		if get_node_or_null("/root/AudioManager"):
			AudioManager.tocar_som_caminhada()
	)
	add_child(passo_timer)
	if get_node_or_null("/root/AudioManager"): AudioManager.tocar_som_caminhada()
		
	# 5. Anima o boneco E a câmera (transição rápida ajustada pro novo tamanho)
	var tween_walk = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if porta_de_retorno:
		tween_walk.tween_property(dummy, "position:y", 1250, 1.0)
		tween_walk.tween_property(cam, "position:y", 1150, 1.0)
	else:
		tween_walk.tween_property(dummy, "position:y", 940, 1.0)
		tween_walk.tween_property(cam, "position:y", 1040, 1.0)
	
	await tween_walk.finished
	passo_timer.queue_free()
		
	# Limpa o render 3D/2D
	vp_container.queue_free()

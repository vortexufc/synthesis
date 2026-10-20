extends Area2D

# Item de Poção de Cura dropada no chão dos laboratórios de alquimia

@export var cura_imediata: float = 25.0
@export var cura_inventario: int = 40
@export var nome_pocao: String = "Poção de Cura"

var coletavel = false
var _coletado = false
var id_unico: String = ""
var is_drop_dinamico: bool = false

var _tween_glow: Tween
var _tween_bob: Tween
var _shadow: Sprite2D = null

func _obter_id_unico() -> String:
	if id_unico != "":
		return id_unico
	var cena_path = ""
	if get_tree() and get_tree().current_scene:
		cena_path = get_tree().current_scene.scene_file_path
	var pos_str = "%d_%d" % [int(global_position.x), int(global_position.y)]
	var pai_nome = get_parent().name if get_parent() else ""
	return "%s::%s/%s@%s" % [cena_path, pai_nome, name, pos_str]

func _physics_process(delta: float) -> void:
	if not coletavel or _coletado:
		return
		
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < 65.0: # Leve atração magnética quando o jogador passa perto
			var dir = (player.global_position - global_position).normalized()
			var speed = lerp(180.0, 420.0, 1.0 - (dist / 65.0))
			global_position += dir * speed * delta
			if dist < 18.0:
				_coletar(player)

func _ready() -> void:
	if not is_drop_dinamico:
		if id_unico == "":
			id_unico = _obter_id_unico()
		if get_node_or_null("/root/PlayerStats") and PlayerStats.is_item_coletado(id_unico):
			queue_free()
			return

	z_index = 2
	collision_layer = 0
	collision_mask = 15 # player
	body_entered.connect(_coletar)
	
	if "menor" in nome_pocao.to_lower() and has_node("Sprite2D"):
		var tex_m = load("res://assets/sprites/pocao_menor.png") as Texture2D
		if tex_m:
			$Sprite2D.texture = tex_m
	
	_criar_sombra()
	_iniciar_efeito_brilho()
	
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.2)
	tween.tween_callback(func(): coletavel = true)
	tween.tween_callback(_verificar_coleta_imediata)

	if not is_drop_dinamico:
		call_deferred("_garantir_posicao_segura")

func _garantir_posicao_segura() -> void:
	if not is_inside_tree():
		return
	var root_sala = get_parent()
	if not root_sala:
		return
	var floor_node = root_sala.get_node_or_null("Floor") as TileMapLayer
	if not floor_node and get_tree() and get_tree().current_scene:
		floor_node = get_tree().current_scene.get_node_or_null("Floor") as TileMapLayer
	if not floor_node:
		return
		
	var camadas_obstaculos: Array[TileMapLayer] = []
	var containers = [root_sala]
	if get_tree() and get_tree().current_scene and get_tree().current_scene != root_sala:
		containers.append(get_tree().current_scene)
	for cont in containers:
		if not is_instance_valid(cont): continue
		for child in cont.get_children():
			if child is TileMapLayer and child.name != "Floor":
				if not camadas_obstaculos.has(child):
					camadas_obstaculos.append(child)
					
	if _posicao_tem_problema(global_position, floor_node, camadas_obstaculos):
		var nova_pos = _encontrar_chao_seguro(global_position, floor_node, camadas_obstaculos)
		if nova_pos != Vector2.ZERO:
			global_position = nova_pos

func _posicao_tem_problema(pos: Vector2, floor_node: TileMapLayer, camadas_obstaculos: Array[TileMapLayer]) -> bool:
	var cell = floor_node.local_to_map(floor_node.to_local(pos))
	if not _is_celula_coberta_item(cell, floor_node):
		return true
	for ol in camadas_obstaculos:
		var o_cell = ol.local_to_map(ol.to_local(pos))
		if _is_celula_coberta_item(o_cell, ol):
			return true
	if is_inside_tree() and get_world_2d():
		var space = get_world_2d().direct_space_state
		var q = PhysicsShapeQueryParameters2D.new()
		var circle = CircleShape2D.new()
		circle.radius = 12.0
		q.shape = circle
		q.transform = Transform2D(0.0, pos)
		q.collision_mask = 1
		q.collide_with_bodies = true
		var hits = space.intersect_shape(q)
		for h in hits:
			if h.collider != self and not is_ancestor_of(h.collider):
				return true
	return false

func _is_celula_coberta_item(cell: Vector2i, layer: TileMapLayer) -> bool:
	if not layer or not layer.tile_set: return false
	if layer.get_cell_source_id(cell) != -1: return true
	for used in layer.get_used_cells():
		var src_id = layer.get_cell_source_id(used)
		var atlas = layer.get_cell_atlas_coords(used)
		var source = layer.tile_set.get_source(src_id) as TileSetAtlasSource if layer.tile_set else null
		var size = source.get_tile_size_in_atlas(atlas) if (source and source.has_tile(atlas)) else Vector2i(1, 1)
		if cell.x >= used.x and cell.x < used.x + size.x and cell.y >= used.y and cell.y < used.y + size.y:
			return true
	return false

func _encontrar_chao_seguro(pos_desejada: Vector2, floor_node: TileMapLayer, camadas_obstaculos: Array[TileMapLayer]) -> Vector2:
	var cells = floor_node.get_used_cells()
	var melhor_pos = Vector2.ZERO
	var menor_dist = 9999999.0
	for cell in cells:
		var wpos = floor_node.to_global(floor_node.map_to_local(cell))
		if _posicao_tem_problema(wpos, floor_node, camadas_obstaculos):
			continue
		var dist = wpos.distance_to(pos_desejada)
		if dist < menor_dist:
			menor_dist = dist
			melhor_pos = wpos
	return melhor_pos

func _criar_sombra() -> void:
	if _shadow != null: return
	_shadow = Sprite2D.new()
	_shadow.name = "Shadow"
	var tex_shadow = load("res://assets/sprites/Characters/Maguinho/shadow.png") as Texture2D
	if tex_shadow:
		_shadow.texture = tex_shadow
		_shadow.position = Vector2(0, 18)
		_shadow.scale = Vector2(0.9, 0.5)
		_shadow.modulate = Color(0.0, 0.0, 0.0, 0.65)
		_shadow.z_as_relative = false
		_shadow.z_index = 1
		add_child(_shadow)
		move_child(_shadow, 0)

func _iniciar_efeito_brilho() -> void:
	var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
	
	# Aura curativa suave verde/esmeralda
	var glow: Sprite2D = get_node_or_null("GlowSprite") as Sprite2D
	if glow == null:
		glow = Sprite2D.new()
		glow.name = "GlowSprite"
		var grad = Gradient.new()
		grad.colors = PackedColorArray([
			Color(0.2, 1.0, 0.45, 0.65),
			Color(0.1, 0.8, 0.3, 0.35),
			Color(0.0, 0.0, 0.0, 0.0)
		])
		grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
		var tex_glow = GradientTexture2D.new()
		tex_glow.gradient = grad
		tex_glow.fill = GradientTexture2D.FILL_RADIAL
		tex_glow.fill_from = Vector2(0.5, 0.5)
		tex_glow.fill_to = Vector2(0.5, 0.0)
		tex_glow.width = 48
		tex_glow.height = 48
		glow.texture = tex_glow
		glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(glow)
		move_child(glow, 1)
		
	if glow:
		_tween_glow = create_tween().set_loops()
		_tween_glow.tween_property(glow, "scale", Vector2(1.25, 1.25), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween_glow.tween_property(glow, "scale", Vector2(0.95, 0.95), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
	if sprite:
		var pos_y = sprite.position.y
		_tween_bob = create_tween().set_loops()
		_tween_bob.tween_property(sprite, "position:y", pos_y - 4.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween_bob.tween_property(sprite, "position:y", pos_y + 4.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _verificar_coleta_imediata() -> void:
	for corpo in get_overlapping_bodies():
		if corpo.is_in_group("player") or corpo.name.begins_with("Player"):
			_coletar(corpo)
			break

func _coletar(corpo: Node2D) -> void:
	if not coletavel or _coletado: return
	if corpo.is_in_group("player") or corpo.name.begins_with("Player"):
		_coletado = true
		coletavel = false
		
		var curou = false
		if get_node_or_null("/root/PlayerStats"):
			# Guarda a poção no inventário do jogador
			PlayerStats.adicionar_pocao(nome_pocao, cura_inventario, "Cura 40 HP (Laboratório Alquímico)", 1)
			
			# Se o jogador estiver com a vida baixa, também cura imediatamente +25 HP!
			if PlayerStats.vida_atual_jogador < PlayerStats.vida_maxima_jogador:
				PlayerStats.curar_vida(cura_imediata)
				curou = true
				
			if not is_drop_dinamico and id_unico != "":
				PlayerStats.registrar_item_coletado(id_unico)
			PlayerStats.salvar()
			
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("pocao_cura")
			
		_exibir_texto_flutuante(curou)
		
		if _tween_glow and _tween_glow.is_valid(): _tween_glow.kill()
		if _tween_bob and _tween_bob.is_valid(): _tween_bob.kill()
		
		# Partículas mágicas de cura
		var pos_coleta = global_position
		var sprite = get_node_or_null("Sprite2D")
		if sprite: pos_coleta = sprite.global_position
		
		var part = CPUParticles2D.new()
		part.top_level = true
		part.z_index = 15
		part.local_coords = false
		part.amount = 16
		part.lifetime = 0.65
		part.one_shot = true
		part.explosiveness = 0.88
		part.direction = Vector2(0, -1)
		part.spread = 160.0
		part.gravity = Vector2(0, -25)
		part.initial_velocity_min = 35.0
		part.initial_velocity_max = 75.0
		part.scale_amount_min = 2.0
		part.scale_amount_max = 4.0
		
		var grad = Gradient.new()
		grad.colors = PackedColorArray([
			Color(0.2, 1.0, 0.45, 1.0),
			Color(1.0, 0.95, 0.35, 0.9),
			Color(0.1, 0.7, 0.3, 0.0)
		])
		grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
		part.color_ramp = grad
		
		var arvore = get_tree()
		var pai = arvore.current_scene if (arvore and arvore.current_scene) else get_parent()
		if pai: pai.add_child(part)
		else: get_tree().root.add_child(part)
		
		part.global_position = pos_coleta
		part.emitting = true
		part.restart()
		if arvore:
			arvore.create_timer(0.75).timeout.connect(part.queue_free)
			
		# Animação suave de subida e desaparecimento
		var tween_coleta = create_tween().set_parallel(true)
		tween_coleta.tween_property(self, "position:y", position.y - 28.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween_coleta.tween_property(self, "scale", Vector2(1.3, 1.3), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween_coleta.tween_property(self, "modulate", Color(1.8, 2.0, 1.8, 1.0), 0.22)
		tween_coleta.chain().set_parallel(true)
		tween_coleta.tween_property(self, "scale", Vector2.ZERO, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween_coleta.tween_property(self, "modulate:a", 0.0, 0.20)
		await tween_coleta.finished
		queue_free()

func _exibir_texto_flutuante(curou: bool) -> void:
	var lbl = Label.new()
	if curou:
		lbl.text = "+1 Poção 🧪 (+%.0f HP ❤️)" % cura_imediata
	else:
		lbl.text = "+1 Poção de Cura 🧪"
	lbl.z_index = 25
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55))
	lbl.add_theme_color_override("font_outline_color", Color(0.04, 0.18, 0.08, 0.95))
	lbl.add_theme_constant_override("outline_size", 3)
	
	var font_pixel = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	if font_pixel:
		lbl.add_theme_font_override("font", font_pixel)
		
	var arvore = get_tree()
	var cena_alvo = arvore.current_scene if (arvore and arvore.current_scene) else get_parent()
	if cena_alvo:
		cena_alvo.add_child(lbl)
	else:
		get_tree().root.add_child(lbl)
		
	lbl.global_position = global_position + Vector2(-60, -28)
	
	var tw = lbl.create_tween().set_parallel(true)
	tw.tween_property(lbl, "global_position:y", lbl.global_position.y - 32.0, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.25).set_delay(0.50)
	tw.chain().tween_callback(lbl.queue_free)

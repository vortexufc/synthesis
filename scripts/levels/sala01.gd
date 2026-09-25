extends Node2D

# script da primeira sala de quimica

var monstros_na_sala: int = 0

var _canvas_modulate: CanvasModulate = null
var _luz_player: PointLight2D = null
var _luzes_caldeiroes: Array = []
var _luzes_portais: Array = []
var _luzes_props: Array = []
var _tempo_iluminacao: float = 0.0

func _ready() -> void:
	print("Sala01 Iniciada - Injetando Realismo e Teste de Chaves/Portas")
	
	if get_node_or_null("/root/DatabaseManager"):
		DatabaseManager.active_dungeon = "Química"
	if get_node_or_null("/root/DungeonGenerator"):
		DungeonGenerator.masmorra_retorno_hub = "Química"
		
	if get_node_or_null("/root/AudioManager"):
		AudioManager.start_playlist()
		
	_configurar_sistema_iluminacao()
	_iniciar_sistema_inimigos_e_portas()

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

func _obter_textura_bolha() -> Texture2D:
	var grad_tex = GradientTexture2D.new()
	var grad = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	grad.colors = PackedColorArray([
		Color(1, 1, 1, 1.0),
		Color(1, 1, 1, 0.85),
		Color(1, 1, 1, 0.0)
	])
	grad_tex.gradient = grad
	grad_tex.width = 16
	grad_tex.height = 16
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(0.5, 0.0)
	return grad_tex

func _adicionar_caldeirao(tex_luz: Texture2D, tex_bolha: Texture2D, pos: Vector2, cor_luz: Color, cores_gradiente: PackedColorArray, extents_emissao: Vector2, id_sufixo: String) -> void:
	var luz = PointLight2D.new()
	luz.name = "LuzCaldeirao_" + id_sufixo
	luz.texture = tex_luz
	luz.color = cor_luz
	luz.energy = 0.52
	luz.texture_scale = 0.50
	luz.position = pos
	add_child(luz)
	
	_luzes_caldeiroes.append({
		"node": luz,
		"base_energy": 0.52,
		"offset": randf() * 10.0
	})
	
	# fumaca e bolhas do caldeirao
	var part = CPUParticles2D.new()
	part.name = "ParticulasCaldeirao_" + id_sufixo
	part.position = pos + Vector2(0, -10)
	part.z_index = 5
	
	var mat = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	part.material = mat
	part.texture = tex_bolha
	
	part.amount = 18
	part.lifetime = 1.8
	part.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	part.emission_rect_extents = extents_emissao
	part.direction = Vector2(0, -1)
	part.spread = 28.0
	part.gravity = Vector2(0, -22)
	part.initial_velocity_min = 18.0
	part.initial_velocity_max = 38.0
	part.scale_amount_min = 0.5
	part.scale_amount_max = 1.3
	
	var grad = Gradient.new()
	grad.colors = cores_gradiente
	part.color_ramp = grad
	
	add_child(part)

func _configurar_sistema_iluminacao() -> void:
	var tex_luz = _obter_textura_luz()
	var tex_bolha = _obter_textura_bolha()
	
	# escurece a sala
	_canvas_modulate = CanvasModulate.new()
	_canvas_modulate.name = "AmbienteMasmorra"
	_canvas_modulate.color = Color(0.24, 0.24, 0.35, 1.0)
	add_child(_canvas_modulate)
	
	# luz que segue o player
	var player = find_child("Player", true, false)
	if player:
		_luz_player = PointLight2D.new()
		_luz_player.name = "AuraPlayer"
		_luz_player.texture = tex_luz
		_luz_player.color = Color(1.0, 0.94, 0.82, 1.0) # Luz mágica acolhedora
		_luz_player.energy = 0.34
		_luz_player.texture_scale = 1.65 # Raio amplo para clarear os passos
		_luz_player.position = Vector2(0, -10)
		player.add_child(_luz_player)
		
	# luzes nos portais
	_criar_luz_portal("PortaTransicao", Color(0.85, 0.38, 1.0, 1.0)) # Roxo químico arcano
	_criar_luz_portal("PortaRetorno", Color(0.25, 0.78, 1.0, 1.0))   # Azul misterioso de retorno
	
	# caldeiroes e frascos
	var decor = get_node_or_null("Decoration") as TileMapLayer
	if decor:
		for cell in decor.get_used_cells():
			var atlas = decor.get_cell_atlas_coords(cell)
			var cell_world = decor.to_global(decor.map_to_local(cell))
			var cell_id = str(cell.x) + "_" + str(cell.y)
			
			var src_id = decor.get_cell_source_id(cell)
			var src = decor.tile_set.get_source(src_id) as TileSetAtlasSource if decor.tile_set else null
			var tex_name = src.texture.resource_path.get_file() if (src and src.texture) else ""
			
			# runas no chao
			var is_circulo = (src and src.texture and ("círculo" in src.texture.resource_path or "circulo" in src.texture.resource_path.to_lower())) or ("c" in tex_name.to_lower() and "ulo" in tex_name.to_lower())
			if is_circulo or (atlas.y == 0 and (atlas.x == 0 or atlas.x == 6 or atlas.x == 12) and ("OBJETOS" not in tex_name)):
				var cor_runa = Color(1.0, 1.0, 1.0, 1.0)
				var pos_runa = cell_world
				var id_runa = ""
				
				if atlas.x == 0:
					# runa verde
					cor_runa = Color(0.35, 0.95, 0.30, 1.0)
					pos_runa = cell_world
					id_runa = "RunaVerde_" + cell_id
				elif atlas.x == 6:
					# runa dourada
					cor_runa = Color(0.95, 0.52, 0.18, 1.0)
					pos_runa = cell_world + Vector2(-16, 0)
					id_runa = "RunaAmbar_" + cell_id
				elif atlas.x == 12:
					# runa roxa
					cor_runa = Color(0.80, 0.32, 0.95, 1.0)
					pos_runa = cell_world
					id_runa = "RunaRoxa_" + cell_id
					
				if id_runa != "":
					var luz_runa = PointLight2D.new()
					luz_runa.name = "BrilhoRunaChao_" + id_runa
					luz_runa.texture = tex_luz
					luz_runa.color = cor_runa
					luz_runa.energy = 0.35
					luz_runa.texture_scale = 0.70
					luz_runa.position = pos_runa
					add_child(luz_runa)
					_luzes_props.append({"node": luz_runa, "base_energy": 0.35, "speed": 1.5, "offset": randf() * 5.0})
					
			# caldeiroes de pe
			elif atlas.y == 6 and (atlas.x == 0 or atlas.x == 8) and ("OBJETOS02" in tex_name or tex_name == ""):
				if atlas.x == 0:
					# caldeirao amarelo
					_adicionar_caldeirao(
						tex_luz, tex_bolha,
						cell_world + Vector2(-4, -36),
						Color(1.0, 0.82, 0.20, 1.0),
						PackedColorArray([
							Color(1.0, 0.85, 0.25, 0.95),
							Color(0.95, 0.55, 0.15, 0.85),
							Color(0.85, 0.35, 0.10, 0.0)
						]),
						Vector2(20, 7),
						"CaldeiraoAmarelo_" + cell_id
					)
				elif atlas.x == 8:
					# caldeirao verde
					_adicionar_caldeirao(
						tex_luz, tex_bolha,
						cell_world + Vector2(-4, -36),
						Color(0.40, 0.98, 0.25, 1.0),
						PackedColorArray([
							Color(0.45, 1.0, 0.30, 0.95),
							Color(0.20, 0.85, 0.45, 0.85),
							Color(0.15, 0.70, 0.30, 0.0)
						]),
						Vector2(20, 7),
						"CaldeiraoVerde_" + cell_id
					)
					
			# caldeirao roxo
			elif atlas == Vector2i(91, 20):
				_adicionar_caldeirao(
					tex_luz, tex_bolha,
					cell_world + Vector2(-20, -32),
					Color(0.84, 0.22, 0.98, 1.0),
					PackedColorArray([
						Color(0.85, 0.35, 1.0, 0.95),
						Color(0.40, 0.85, 1.0, 0.85),
						Color(0.60, 0.20, 0.95, 0.0)
					]),
					Vector2(18, 6),
					"ObjetosRoxo_" + cell_id
				)
				
			# caldeiroes tombados
			elif atlas.y == 19 and ("OBJETOS02" in tex_name or tex_name == ""):
				if atlas.x in [16, 17]:
					# caldeirao azul tombado
					_adicionar_caldeirao(
						tex_luz, tex_bolha,
						cell_world + Vector2(10, 14),
						Color(0.28, 0.65, 1.0, 1.0),
						PackedColorArray([
							Color(0.35, 0.70, 1.0, 0.95),
							Color(0.18, 0.45, 0.95, 0.85),
							Color(0.10, 0.25, 0.80, 0.0)
						]),
						Vector2(14, 6),
						"TombadoAzul_" + cell_id
					)
				elif atlas.x in [24, 25]:
					# caldeirao ciano tombado
					_adicionar_caldeirao(
						tex_luz, tex_bolha,
						cell_world + Vector2(10, 14),
						Color(0.20, 0.92, 0.95, 1.0),
						PackedColorArray([
							Color(0.25, 0.95, 0.95, 0.95),
							Color(0.15, 0.75, 0.85, 0.85),
							Color(0.08, 0.50, 0.70, 0.0)
						]),
						Vector2(14, 6),
						"TombadoCiano_" + cell_id
					)
				elif atlas.x in [32, 33]:
					# caldeirao vermelho tombado
					_adicionar_caldeirao(
						tex_luz, tex_bolha,
						cell_world + Vector2(10, 14),
						Color(1.0, 0.25, 0.25, 1.0),
						PackedColorArray([
							Color(1.0, 0.30, 0.28, 0.95),
							Color(0.90, 0.15, 0.20, 0.85),
							Color(0.70, 0.08, 0.12, 0.0)
						]),
						Vector2(14, 6),
						"TombadoVermelho_" + cell_id
					)
				# ignora madeira quebrada
					
			# frascos com cristais
			elif atlas == Vector2i(40, 20):
				var luz_cristal = PointLight2D.new()
				luz_cristal.name = "LuzFrascoCristal_" + cell_id
				luz_cristal.texture = tex_luz
				luz_cristal.color = Color(0.18, 0.88, 1.0, 1.0)
				luz_cristal.energy = 0.40
				luz_cristal.texture_scale = 0.35
				luz_cristal.position = cell_world + Vector2(4, -16)
				add_child(luz_cristal)
				_luzes_props.append({"node": luz_cristal, "base_energy": 0.40, "speed": 1.9, "offset": 0.0})
			elif atlas == Vector2i(40, 32):
				var luz_planta = PointLight2D.new()
				luz_planta.name = "LuzFrascoPlanta_" + cell_id
				luz_planta.texture = tex_luz
				luz_planta.color = Color(0.20, 0.98, 0.45, 1.0)
				luz_planta.energy = 0.40
				luz_planta.texture_scale = 0.35
				luz_planta.position = cell_world + Vector2(0, -16)
				add_child(luz_planta)
				_luzes_props.append({"node": luz_planta, "base_energy": 0.40, "speed": 1.4, "offset": 2.1})

func _criar_luz_portal(nome_porta: String, cor_luz: Color) -> void:
	var porta = find_child(nome_porta, true, false)
	if not porta:
		return
		
	var luz = PointLight2D.new()
	luz.name = "LuzPortal_" + nome_porta
	luz.texture = _obter_textura_luz()
	luz.color = cor_luz
	luz.energy = 0.48
	luz.texture_scale = 1.5
	luz.position = Vector2(0, -25)
	porta.add_child(luz)
	
	_luzes_portais.append({
		"node": luz,
		"base_energy": 0.48,
		"offset": randf() * 10.0
	})

var _tempo_luz_tick: float = 0.0

func _process(delta: float) -> void:
	_tempo_luz_tick += delta
	if _tempo_luz_tick < 0.033:
		return
	var dt = _tempo_luz_tick
	_tempo_luz_tick = 0.0
	_tempo_iluminacao += dt
	
	# bolhas no caldeirao
	for c_data in _luzes_caldeiroes:
		var luz = c_data["node"] as PointLight2D
		if luz and is_instance_valid(luz):
			var t = _tempo_iluminacao + c_data["offset"]
			var borbulha = sin(t * 5.5) * 0.06 + sin(t * 9.2) * 0.03
			luz.energy = c_data["base_energy"] + borbulha
		
	# pulso de luz do player
	if _luz_player and is_instance_valid(_luz_player):
		var pulso_p = sin(_tempo_iluminacao * 2.0) * 0.02
		_luz_player.energy = 0.34 + pulso_p
		
	# luz dos portais pulsando
	for portal in _luzes_portais:
		var node = portal["node"] as PointLight2D
		if node and is_instance_valid(node):
			var pulso = sin((_tempo_iluminacao + portal["offset"]) * 2.2) * 0.04
			node.energy = portal["base_energy"] + pulso
			
	# pisca a luz dos frascos
	for prop in _luzes_props:
		var node = prop["node"] as PointLight2D
		if node and is_instance_valid(node):
			var pulso = sin((_tempo_iluminacao + prop["offset"]) * prop["speed"]) * 0.04
			node.energy = prop["base_energy"] + pulso

func _iniciar_sistema_inimigos_e_portas() -> void:
	var inimigos = get_tree().get_nodes_in_group("inimigos")
	monstros_na_sala = inimigos.size()
	
	for inimigo in inimigos:
		if inimigo:
			inimigo.inimigo_derrotado.connect(_on_inimigo_derrotado)
	
	# troca pela porta trancada
	var porta = get_node_or_null("PortaTransicao")
	if porta:
		porta.process_mode = Node.PROCESS_MODE_DISABLED
		porta.hide()
		
		var trancada = StaticBody2D.new()
		trancada.name = "PortaTrancadaTeste"
		trancada.position = porta.position
		
		var script_porta = load("res://scripts/PortaTrancada.gd")
		if script_porta: trancada.set_script(script_porta)
		
		var sprite_porta = porta.get_node_or_null("SpritePorta")
		if sprite_porta:
			trancada.add_child(sprite_porta.duplicate())
			
		var col_porta = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(100, 100)
		col_porta.shape = rect
		trancada.add_child(col_porta)
		
		call_deferred("add_child", trancada)

func _on_inimigo_derrotado(pos: Vector2) -> void:
	monstros_na_sala -= 1
	print("Monstro derrotado! Restam: ", monstros_na_sala)
	
	if monstros_na_sala <= 0:
		_dropar_chave(pos)

func _dropar_chave(pos: Vector2) -> void:
	print("Último monstro morto! Dropando a chave!")
	var cena_chave = load("res://scenes/Entidades/Items/ItemChave.tscn")
	if not cena_chave:
		cena_chave = load("res://scenes/Entidades/ItemChave.tscn")
	if not cena_chave: return
	var chave = cena_chave.instantiate()
	chave.position = to_local(pos)
	call_deferred("add_child", chave)

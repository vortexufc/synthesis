extends Node2D

## Controlador Base de Iluminação e Visual de Laboratório para as Salas de Física
## Aplica a atmosfera industrial, eletromagnética e de alta tecnologia:
## - Ambiente de laboratório metálico iluminado (CanvasModulate azul-chumbo frio)
## - Aura elétrica no pé do jogador (PointLight2D com luz branca fria)
## - Portais energizados (Azul elétrico de avanço e Ciano quântico de retorno)
## - Telas e monitores com iluminação fosforescente e flicker de varredura
## - Canos com liberação de vapor de pressão e ventiladores com exaustão
## - Baterias elétricas emitindo brilho dourado e faíscas estáticas
## - Chips eletrônicos pulsando em ciano neon
## - Robôs com sensores ópticos/olhos luminosos patrulhando a sala
## - Luminárias industriais de parede distribuídas pelo laboratório
## - Gerenciamento de inimigos, combate e drop de chaves de progressão

var monstros_na_sala: int = 0

@export_group("Iluminação Ambiente")
## Tom de iluminação ambiente do laboratório.
## Tons claros (ex: 0.74, 0.78, 0.84) mantêm a sala bem iluminada e nítida como um laboratório de ponta.
@export var cor_ambiente: Color = Color(0.74, 0.78, 0.84, 1.0)
@export var energia_aura_player: float = 0.38

var _canvas_modulate: CanvasModulate = null
var _luz_player: PointLight2D = null
var _luzes_telas: Array = []
var _luzes_portais: Array = []
var _luzes_itens: Array = []
var _luzes_robos: Array = []
var _tempo_iluminacao: float = 0.0

func _ready() -> void:
	if get_node_or_null("/root/AudioManager"):
		AudioManager.start_playlist()
		
	_configurar_sistema_iluminacao()
	_iniciar_sistema_inimigos_e_portas()

func _obter_textura_luz() -> Texture2D:
	var grad_tex = GradientTexture2D.new()
	var grad = Gradient.new()
	grad.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CUBIC
	grad.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	grad.colors = PackedColorArray([
		Color(1, 1, 1, 1.0),
		Color(1, 1, 1, 0.45),
		Color(1, 1, 1, 0.0)
	])
	grad_tex.gradient = grad
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(1.0, 0.5)
	grad_tex.width = 256
	grad_tex.height = 256
	return grad_tex

func _obter_textura_vapor() -> Texture2D:
	var grad_tex = GradientTexture2D.new()
	var grad = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	grad.colors = PackedColorArray([
		Color(1, 1, 1, 0.6),
		Color(0.85, 0.95, 1.0, 0.3),
		Color(0.7, 0.85, 1.0, 0.0)
	])
	grad_tex.gradient = grad
	grad_tex.width = 32
	grad_tex.height = 32
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(0.5, 0.0)
	return grad_tex

func _configurar_sistema_iluminacao() -> void:
	var tex_luz = _obter_textura_luz()
	
	# 1. CanvasModulate: Ambiente de laboratório tecnológico e metálico claro
	# (Visual límpido e iluminado de laboratório, sem a escuridão pesada da masmorra de alquimia)
	if not find_child("AmbienteLaboratorio", true, false) and not find_child("AmbienteMasmorra", true, false):
		_canvas_modulate = CanvasModulate.new()
		_canvas_modulate.name = "AmbienteLaboratorio"
		_canvas_modulate.color = cor_ambiente
		add_child(_canvas_modulate)
	elif find_child("AmbienteLaboratorio", true, false):
		_canvas_modulate = find_child("AmbienteLaboratorio", true, false) as CanvasModulate
		if _canvas_modulate:
			_canvas_modulate.color = cor_ambiente
	
	# 2. Aura Elétrica do Jogador: Projeção limpa de luz branca-fria
	var player = find_child("Player", true, false)
	if player and not player.get_node_or_null("AuraPlayer"):
		_luz_player = PointLight2D.new()
		_luz_player.name = "AuraPlayer"
		_luz_player.texture = tex_luz
		_luz_player.color = Color(0.90, 0.96, 1.0, 1.0)
		_luz_player.energy = energia_aura_player
		_luz_player.texture_scale = 1.7
		_luz_player.position = Vector2(0, -10)
		player.add_child(_luz_player)
	elif player:
		_luz_player = player.get_node_or_null("AuraPlayer") as PointLight2D
		
	# 3. Luzes temáticas nos Portais de Física
	_criar_luz_portal("PortaTransicao", Color(0.20, 0.75, 1.0, 1.0)) # Azul elétrico de avanço
	_criar_luz_portal("PortaRetorno", Color(0.15, 0.90, 0.85, 1.0))   # Ciano quântico de retorno
	
	# 4. Detecção e iluminação automática de máquinas, telas e canos na camada Decoration
	_configurar_props_fisica(tex_luz)
	
	# 5. Efeitos visuais em itens colecionáveis e sensores dos robôs
	_configurar_itens_e_entidades(tex_luz)
	
	# 6. Luminárias industriais de parede caso a sala não possua iluminação manual
	_garantir_luminarias_na_sala()

func _configurar_props_fisica(tex_luz: Texture2D) -> void:
	var decor = get_node_or_null("Decoration") as TileMapLayer
	if not decor or not decor.tile_set:
		return
		
	var tex_vapor = _obter_textura_vapor()
	
	for cell in decor.get_used_cells():
		var atlas = decor.get_cell_atlas_coords(cell)
		var cell_world = decor.to_global(decor.map_to_local(cell))
		var cell_id = str(cell.x) + "_" + str(cell.y)
		var src_id = decor.get_cell_source_id(cell)
		
		# 4.1 Monitores, Consoles e Painéis Computadorizados (Source 3: objetos.png)
		if src_id == 3:
			# Grandes terminais com monitores luminosos
			if atlas in [Vector2i(0, 0), Vector2i(10, 0), Vector2i(0, 11), Vector2i(10, 11), Vector2i(20, 14), Vector2i(30, 3), Vector2i(30, 14), Vector2i(80, 0), Vector2i(90, 0), Vector2i(100, 0), Vector2i(110, 0)]:
				var luz_tela = PointLight2D.new()
				luz_tela.name = "LuzMonitor_" + cell_id
				luz_tela.texture = tex_luz
				luz_tela.color = Color(0.25, 0.90, 0.80, 1.0) # Fosforescência ciano-esmeralda de terminal
				luz_tela.energy = 0.48
				luz_tela.texture_scale = 0.9
				luz_tela.position = cell_world + Vector2(0, 12)
				add_child(luz_tela)
				_luzes_telas.append({
					"node": luz_tela,
					"base_energy": 0.48,
					"speed": randf_range(5.0, 9.0),
					"offset": randf() * 10.0
				})
			# Painéis elétricos secundários / medidores
			elif atlas in [Vector2i(44, 7), Vector2i(40, 7), Vector2i(76, 13), Vector2i(66, 6), Vector2i(72, 13), Vector2i(60, 17), Vector2i(65, 17)]:
				var luz_painel = PointLight2D.new()
				luz_painel.name = "LuzPainel_" + cell_id
				luz_painel.texture = tex_luz
				luz_painel.color = Color(1.0, 0.75, 0.25, 1.0) # Âmbar de alerta/medição
				luz_painel.energy = 0.38
				luz_painel.texture_scale = 0.55
				luz_painel.position = cell_world
				add_child(luz_painel)
				_luzes_telas.append({
					"node": luz_painel,
					"base_energy": 0.38,
					"speed": randf_range(2.0, 4.0),
					"offset": randf() * 10.0
				})
				
		# 4.2 Ventiladores Industriais (Source 1: ventiladores.png)
		elif src_id == 1:
			var part_vento = CPUParticles2D.new()
			part_vento.name = "ExaustaoVentilador_" + cell_id
			part_vento.position = cell_world + Vector2(0, 8)
			part_vento.z_index = 4
			part_vento.texture = tex_vapor
			part_vento.amount = 4
			part_vento.lifetime = 1.4
			part_vento.direction = Vector2(0, 1)
			part_vento.spread = 25.0
			part_vento.gravity = Vector2(0, 10)
			part_vento.initial_velocity_min = 15.0
			part_vento.initial_velocity_max = 35.0
			part_vento.scale_amount_min = 0.4
			part_vento.scale_amount_max = 0.8
			part_vento.color = Color(1, 1, 1, 0.25)
			add_child(part_vento)
			
		# 4.3 Válvulas e Canos de Pressão (Source 2: canos2.png)
		elif src_id == 2:
			# Pequenos vazamentos de vapor em conexões selecionadas
			if atlas in [Vector2i(7, 5), Vector2i(55, 14), Vector2i(145, 3), Vector2i(151, 3)]:
				var part_vapor = CPUParticles2D.new()
				part_vapor.name = "VaporCano_" + cell_id
				part_vapor.position = cell_world + Vector2(0, -6)
				part_vapor.z_index = 5
				part_vapor.texture = tex_vapor
				part_vapor.amount = 5
				part_vapor.lifetime = 1.2
				part_vapor.direction = Vector2(0, -1)
				part_vapor.spread = 35.0
				part_vapor.gravity = Vector2(0, -18)
				part_vapor.initial_velocity_min = 20.0
				part_vapor.initial_velocity_max = 40.0
				part_vapor.scale_amount_min = 0.3
				part_vapor.scale_amount_max = 0.7
				part_vapor.color = Color(0.9, 0.95, 1.0, 0.35)
				add_child(part_vapor)

func _configurar_itens_e_entidades(tex_luz: Texture2D) -> void:
	# 1. Brilho elétrico nas Baterias (ItemBateria)
	for item in get_children():
		if item.name.begins_with("ItemBateria") and not item.get_node_or_null("LuzBateria"):
			var luz_bat = PointLight2D.new()
			luz_bat.name = "LuzBateria"
			luz_bat.texture = tex_luz
			luz_bat.color = Color(1.0, 0.85, 0.25, 1.0) # Amarelo/dourado elétrico
			luz_bat.energy = 0.45
			luz_bat.texture_scale = 0.65
			item.add_child(luz_bat)
			_luzes_itens.append({"node": luz_bat, "base_energy": 0.45, "speed": 4.0, "offset": randf() * 5.0})
			
			# Faíscas estáticas na bateria
			var faiscas = CPUParticles2D.new()
			faiscas.name = "FaiscasBateria"
			faiscas.amount = 3
			faiscas.lifetime = 0.4
			faiscas.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
			faiscas.emission_sphere_radius = 8.0
			faiscas.gravity = Vector2(0, -15)
			faiscas.scale_amount_min = 1.0
			faiscas.scale_amount_max = 2.0
			faiscas.color = Color(1.0, 0.9, 0.4, 0.8)
			item.add_child(faiscas)
			
		# 2. Pulso tecnológico nos Chips (ItemChip)
		elif item.name.begins_with("ItemChip") and not item.get_node_or_null("LuzChip"):
			var luz_chip = PointLight2D.new()
			luz_chip.name = "LuzChip"
			luz_chip.texture = tex_luz
			luz_chip.color = Color(0.20, 0.85, 1.0, 1.0) # Ciano elétrico neon
			luz_chip.energy = 0.42
			luz_chip.texture_scale = 0.55
			item.add_child(luz_chip)
			_luzes_itens.append({"node": luz_chip, "base_energy": 0.42, "speed": 5.5, "offset": randf() * 5.0})
			
		# 3. Sensores ópticos / olhos luminosos nos Robôs
		elif (item.name.begins_with("Robo_P") or item.name.begins_with("Robo_G")) and not item.get_node_or_null("LuzSensorRobo"):
			var cor_olho = Color(1.0, 0.85, 0.2, 1.0)
			if "Ciano" in item.name:
				cor_olho = Color(0.20, 0.90, 1.0, 1.0)
			elif "Laranja" in item.name:
				cor_olho = Color(1.0, 0.50, 0.15, 1.0)
			elif "Robo_G" in item.name:
				cor_olho = Color(1.0, 0.25, 0.15, 1.0)
				
			var luz_robo = PointLight2D.new()
			luz_robo.name = "LuzSensorRobo"
			luz_robo.texture = tex_luz
			luz_robo.color = cor_olho
			luz_robo.energy = 0.42
			luz_robo.texture_scale = 0.48
			luz_robo.position = Vector2(0, -18)
			item.add_child(luz_robo)
			_luzes_robos.append({"node": luz_robo, "base_energy": 0.42, "speed": 3.0, "offset": randf() * 5.0})

func _criar_luz_portal(nome_porta: String, cor_luz: Color) -> void:
	var porta = find_child(nome_porta, true, false)
	if not porta or porta.get_node_or_null("LuzPortal_" + nome_porta):
		return
		
	var luz = PointLight2D.new()
	luz.name = "LuzPortal_" + nome_porta
	luz.texture = _obter_textura_luz()
	luz.color = cor_luz
	luz.energy = 0.52
	luz.texture_scale = 1.6
	luz.position = Vector2(0, -35)
	porta.add_child(luz)
	
	_luzes_portais.append({
		"node": luz,
		"base_energy": 0.52,
		"offset": randf() * 10.0
	})

func _garantir_luminarias_na_sala() -> void:
	if find_child("Luminarias", true, false):
		return
		
	var luminarias_existentes = get_tree().get_nodes_in_group("luminarias_fisica")
	var count = 0
	for lum in luminarias_existentes:
		if is_ancestor_of(lum):
			count += 1
			
	if count > 0:
		return
		
	var floor_layer = get_node_or_null("Floor") as TileMapLayer
	if not floor_layer:
		return
		
	var cena_luminaria = load("res://scenes/Entidades/LuminariaFisica.tscn")
	if not cena_luminaria:
		return
		
	var rect = floor_layer.get_used_rect()
	var min_world = floor_layer.to_global(floor_layer.map_to_local(rect.position))
	var max_world = floor_layer.to_global(floor_layer.map_to_local(rect.end))
	
	# Detectar portas na sala para evitar que luminárias fiquem sobrepostas a elas
	var porta = find_child("PortaTransicao", true, false) as Node2D
	var porta_pos = porta.global_position if porta else Vector2(-9999, -9999)
	
	var room_w = max_world.x - min_world.x
	var room_h = max_world.y - min_world.y
	
	# 1. Y da parede norte: elevado para o painel metálico superior da parede
	var north_wall_y = min_world.y - 100.0
	
	# Distribuição ao longo da parede Norte
	var fractions: Array = []
	if room_w > 1200:
		fractions = [0.15, 0.38, 0.62, 0.85]
	elif room_w > 700:
		fractions = [0.22, 0.50, 0.78]
	else:
		fractions = [0.28, 0.72]
		
	var luminarias_info: Array = []
	for frac in fractions:
		var lx = min_world.x + room_w * frac
		# Evitar sobreposição com a porta
		if abs(lx - porta_pos.x) < 70 and abs(north_wall_y - porta_pos.y) < 75:
			var offset_x = 80.0 if lx >= porta_pos.x else -80.0
			lx += offset_x
		luminarias_info.append({
			"pos": Vector2(lx, north_wall_y),
			"orient": 0 # NORTE
		})
		
	# 2. Paredes laterais (Oeste e Leste): detecta a coluna da parede para encostar com precisão
	var wall_layer = get_node_or_null("Wall") as TileMapLayer
	var side_fractions = [0.35, 0.65] if room_h > 900 else [0.50]
	for sfrac in side_fractions:
		var sy = min_world.y + room_h * sfrac
		var map_y = int(rect.position.y + rect.size.y * sfrac)
		
		# Buscar coluna da parede esquerda
		var left_wall_x = min_world.x - 69.0
		if wall_layer:
			var achou_esq = false
			for dy in [0, -1, 1, -2, 2]:
				for cx in range(rect.position.x - 1, rect.position.x - 6, -1):
					if wall_layer.get_cell_source_id(Vector2i(cx, map_y + dy)) != -1:
						left_wall_x = wall_layer.to_global(wall_layer.map_to_local(Vector2i(cx, map_y + dy))).x - 5.0
						achou_esq = true
						break
				if achou_esq:
					break
					
		# Buscar coluna da parede direita
		var right_wall_x = max_world.x + 42.0
		if wall_layer:
			var achou_dir = false
			for dy in [0, -1, 1, -2, 2]:
				for cx in range(rect.end.x - 1, rect.end.x + 6):
					if wall_layer.get_cell_source_id(Vector2i(cx, map_y + dy)) != -1:
						right_wall_x = wall_layer.to_global(wall_layer.map_to_local(Vector2i(cx, map_y + dy))).x + 10.0
						achou_dir = true
						break
				if achou_dir:
					break
					
		luminarias_info.append({
			"pos": Vector2(left_wall_x, sy),
			"orient": 1 # OESTE
		})
		luminarias_info.append({
			"pos": Vector2(right_wall_x, sy),
			"orient": 2 # LESTE
		})
		
	for i in range(luminarias_info.size()):
		var info = luminarias_info[i]
		var lum = cena_luminaria.instantiate()
		lum.name = "LuminariaAuto_" + str(i + 1)
		lum.position = info["pos"]
		if lum.has_method("atualizar_orientacao"):
			lum.atualizar_orientacao(info["orient"])
		add_child(lum)

func _process(delta: float) -> void:
	_tempo_iluminacao += delta
	
	# 1. Flicker sutil e scanlines de telas e monitores
	for i in range(_luzes_telas.size() - 1, -1, -1):
		var tela = _luzes_telas[i]
		var raw_node = tela.get("node")
		if not is_instance_valid(raw_node):
			_luzes_telas.remove_at(i)
			continue
		var node: PointLight2D = raw_node
		var t = (_tempo_iluminacao + tela["offset"]) * tela["speed"]
		var osc = sin(t) * 0.04 + sin(t * 2.3) * 0.02
		node.energy = tela["base_energy"] + osc
			
	# 2. Pulso sutil da aura elétrica do jogador
	if is_instance_valid(_luz_player):
		var pulso_p = sin(_tempo_iluminacao * 2.5) * 0.02
		_luz_player.energy = energia_aura_player + pulso_p
	else:
		_luz_player = null
		
	# 3. Pulsação dos portais eletromagnéticos
	for i in range(_luzes_portais.size() - 1, -1, -1):
		var portal = _luzes_portais[i]
		var raw_node = portal.get("node")
		if not is_instance_valid(raw_node):
			_luzes_portais.remove_at(i)
			continue
		var node: PointLight2D = raw_node
		var pulso = sin((_tempo_iluminacao + portal["offset"]) * 2.8) * 0.05
		node.energy = portal["base_energy"] + pulso
			
	# 4. Brilho oscilante dos itens (Baterias e Chips - removidos ao coletar)
	for i in range(_luzes_itens.size() - 1, -1, -1):
		var item_luz = _luzes_itens[i]
		var raw_node = item_luz.get("node")
		if not is_instance_valid(raw_node):
			_luzes_itens.remove_at(i)
			continue
		var node: PointLight2D = raw_node
		var pulso = sin((_tempo_iluminacao + item_luz["offset"]) * item_luz["speed"]) * 0.05
		node.energy = item_luz["base_energy"] + pulso
			
	# 5. Pulsação dos olhos/sensores dos robôs (removidos ao derrotar)
	for i in range(_luzes_robos.size() - 1, -1, -1):
		var robo_luz = _luzes_robos[i]
		var raw_node = robo_luz.get("node")
		if not is_instance_valid(raw_node):
			_luzes_robos.remove_at(i)
			continue
		var node: PointLight2D = raw_node
		var pulso = sin((_tempo_iluminacao + robo_luz["offset"]) * robo_luz["speed"]) * 0.04
		node.energy = robo_luz["base_energy"] + pulso

func _iniciar_sistema_inimigos_e_portas() -> void:
	var inimigos = get_tree().get_nodes_in_group("inimigos")
	var count = 0
	for inimigo in inimigos:
		if is_ancestor_of(inimigo):
			count += 1
			if inimigo.has_signal("inimigo_derrotado") and not inimigo.inimigo_derrotado.is_connected(_on_inimigo_derrotado):
				inimigo.inimigo_derrotado.connect(_on_inimigo_derrotado)
			
	if count == 0:
		for child in get_children():
			if child.name.begins_with("Robo") or child.name == "CharacterBody2D":
				count += 1
				if child.has_signal("inimigo_derrotado") and not child.inimigo_derrotado.is_connected(_on_inimigo_derrotado):
					child.inimigo_derrotado.connect(_on_inimigo_derrotado)
					
	monstros_na_sala = count

func _on_inimigo_derrotado(pos: Vector2) -> void:
	monstros_na_sala -= 1
	if monstros_na_sala <= 0:
		_dropar_recompensa(pos)

func _dropar_recompensa(pos: Vector2) -> void:
	# Prioriza dropar a chave da porta ou uma bateria restauradora
	var cena_chave = load("res://scenes/Entidades/ItemChave.tscn")
	if cena_chave:
		var chave = cena_chave.instantiate()
		chave.position = pos
		call_deferred("add_child", chave)

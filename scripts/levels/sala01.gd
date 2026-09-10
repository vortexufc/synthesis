extends Node2D

## Controlador da Sala 01 de Química
## Aplica o sistema de iluminação realista da masmorra (idêntico ao Hub e ao Corredor):
## - Escuridão ambiente misteriosa (CanvasModulate)
## - Tochas de parede com chamas vivas e flicker dinâmico
## - Aura mágica de caminhada do mago jogador
## - Portais das portas com iluminação temática
## - Brilho alquímico no caldeirão borbulhante e frascos de laboratório
## - Sistema de combate, drop de chaves e porta trancada

var monstros_na_sala: int = 0

var _canvas_modulate: CanvasModulate = null
var _luz_player: PointLight2D = null
var _luz_caldeirao: PointLight2D = null
var _luzes_portais: Array = []
var _luzes_props: Array = []
var _tempo_iluminacao: float = 0.0

func _ready() -> void:
	print("Sala01 Iniciada - Injetando Realismo e Teste de Chaves/Portas")
	
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

func _configurar_sistema_iluminacao() -> void:
	var tex_luz = _obter_textura_luz()
	
	# 1. CanvasModulate: Cria a atmosfera escura e profunda da masmorra (mesmo tom do Hub e Corredor)
	_canvas_modulate = CanvasModulate.new()
	_canvas_modulate.name = "AmbienteMasmorra"
	_canvas_modulate.color = Color(0.24, 0.24, 0.35, 1.0)
	add_child(_canvas_modulate)
	
	# 2. Aura do Jogador: Clareia os passos do mago e as paredes próximas
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
		
	# 3. Luzes temáticas nos Portais (PortaTransicao e PortaRetorno)
	_criar_luz_portal("PortaTransicao", Color(0.85, 0.38, 1.0, 1.0)) # Roxo químico arcano
	_criar_luz_portal("PortaRetorno", Color(0.25, 0.78, 1.0, 1.0))   # Azul misterioso de retorno
	
	# 4. Caldeirão Alquímico e Frascos de Laboratório:
	# Localiza as coordenadas exatas dos objetos da decoração para posicionar a luz diretamente sobre eles
	var pos_caldeirao = Vector2(956, 592)
	var pos_frasco_cristal = Vector2(180, 672)
	var pos_frasco_planta = Vector2(272, 672)
	
	var decor = get_node_or_null("Decoration") as TileMapLayer
	if decor:
		for cell in decor.get_used_cells():
			var atlas = decor.get_cell_atlas_coords(cell)
			if atlas == Vector2i(91, 20):
				var cell_world = decor.to_global(decor.map_to_local(cell))
				pos_caldeirao = cell_world + Vector2(-20, -32)
			elif atlas == Vector2i(40, 20):
				var cell_world = decor.to_global(decor.map_to_local(cell))
				pos_frasco_cristal = cell_world + Vector2(4, -16)
			elif atlas == Vector2i(40, 32):
				var cell_world = decor.to_global(decor.map_to_local(cell))
				pos_frasco_planta = cell_world + Vector2(0, -16)

	# 4.1. Caldeirão Alquímico: Brilho violeta concentrado na boca borbulhante do caldeirão
	_luz_caldeirao = PointLight2D.new()
	_luz_caldeirao.name = "LuzCaldeirao"
	_luz_caldeirao.texture = tex_luz
	_luz_caldeirao.color = Color(0.84, 0.22, 0.98, 1.0) # Violeta alquímico vivo
	_luz_caldeirao.energy = 0.52
	_luz_caldeirao.texture_scale = 0.50 # Raio compacto focado diretamente na boca do caldeirão
	_luz_caldeirao.position = pos_caldeirao
	add_child(_luz_caldeirao)
	
	# 4.2. Frasco de Cristais Arcanos (Mesa inferior esquerda): Brilho ciano mágico
	var luz_cristal = PointLight2D.new()
	luz_cristal.name = "LuzFrascoCristal"
	luz_cristal.texture = tex_luz
	luz_cristal.color = Color(0.18, 0.88, 1.0, 1.0) # Ciano celestial bioluminescente
	luz_cristal.energy = 0.40
	luz_cristal.texture_scale = 0.35 # Focado diretamente sobre o vidro do frasco
	luz_cristal.position = pos_frasco_cristal
	add_child(luz_cristal)
	_luzes_props.append({"node": luz_cristal, "base_energy": 0.40, "speed": 1.9, "offset": 0.0})
	
	# 4.3. Frasco de Alquimia Botânica (Mesa inferior direita): Brilho esmeralda vivo
	var luz_planta = PointLight2D.new()
	luz_planta.name = "LuzFrascoPlanta"
	luz_planta.texture = tex_luz
	luz_planta.color = Color(0.20, 0.98, 0.45, 1.0) # Verde esmeralda vivo
	luz_planta.energy = 0.40
	luz_planta.texture_scale = 0.35 # Focado diretamente sobre o vidro do frasco
	luz_planta.position = pos_frasco_planta
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

func _process(delta: float) -> void:
	_tempo_iluminacao += delta
	
	# 1. Borbulhar dinâmico no Caldeirão Alquímico (intensidade e leve pulso na poção)
	if _luz_caldeirao and is_instance_valid(_luz_caldeirao):
		var borbulha = sin(_tempo_iluminacao * 5.5) * 0.06 + sin(_tempo_iluminacao * 9.2) * 0.03
		_luz_caldeirao.energy = 0.52 + borbulha
		_luz_caldeirao.texture_scale = 0.50 + sin(_tempo_iluminacao * 6.0) * 0.02
		
	# 2. Pulso sutil da aura do mago jogador
	if _luz_player and is_instance_valid(_luz_player):
		var pulso_p = sin(_tempo_iluminacao * 2.0) * 0.02
		_luz_player.energy = 0.34 + pulso_p
		
	# 3. Pulsação dos portais das portas
	for portal in _luzes_portais:
		var node = portal["node"] as PointLight2D
		if node and is_instance_valid(node):
			var pulso = sin((_tempo_iluminacao + portal["offset"]) * 2.2) * 0.04
			node.energy = portal["base_energy"] + pulso
			
	# 4. Cintilação mágica suave dos frascos de laboratório
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
	
	# Substitui a porta de transicao pela trancada
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
	var cena_chave = load("res://scenes/Entidades/ItemChave.tscn")
	if not cena_chave: return
	var chave = cena_chave.instantiate()
	chave.position = pos
	call_deferred("add_child", chave)

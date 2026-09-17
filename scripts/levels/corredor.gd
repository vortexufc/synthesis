extends Node2D

# script do corredor de quimica

var _canvas_modulate: CanvasModulate = null
var _luzes_tochas: Array = []
var _luz_player: PointLight2D = null
var _luz_frasco_cientista: PointLight2D = null
var _luzes_portais: Array = []
var _tempo_iluminacao: float = 0.0

func _ready() -> void:
	if get_node_or_null("/root/DatabaseManager"):
		DatabaseManager.active_dungeon = "Química"
	if get_node_or_null("/root/DungeonGenerator"):
		DungeonGenerator.masmorra_retorno_hub = "Química"
		
	if get_node_or_null("/root/AudioManager"):
		AudioManager.start_playlist()
	_configurar_sistema_iluminacao()

func _obter_textura_luz() -> Texture2D:
	# cria a textura da luz
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
	
	# escurece o corredor
	_canvas_modulate = CanvasModulate.new()
	_canvas_modulate.name = "AmbienteMasmorra"
	_canvas_modulate.color = Color(0.24, 0.24, 0.35, 1.0)
	add_child(_canvas_modulate)
	
	# luzes das tochas nas paredes
	var decor_layer = find_child("Decoration", true, false) as TileMapLayer
	if decor_layer:
		var cells = decor_layer.get_used_cells()
		for cell in cells:
			var local_pos = decor_layer.map_to_local(cell)
			var pos_global = decor_layer.to_global(local_pos)
			
			var luz = PointLight2D.new()
			luz.name = "LuzTocha_%d_%d" % [cell.x, cell.y]
			luz.texture = tex_luz
			luz.color = Color(1.0, 0.70, 0.35, 1.0) # Chama quente alaranjada
			luz.energy = 0.55
			luz.texture_scale = 1.55
			add_child(luz)
			# ajusta altura da luz na tocha
			luz.global_position = pos_global + Vector2(0, -18)
			
			_luzes_tochas.append({
				"node": luz,
				"base_energy": 0.55,
				"base_scale": 1.55,
				"offset": randf() * 100.0,
				"speed": randf_range(7.0, 12.0)
			})
	
	# luz que segue o player
	var player = find_child("Player", true, false)
	if player:
		_luz_player = PointLight2D.new()
		_luz_player.name = "AuraPlayer"
		_luz_player.texture = tex_luz
		_luz_player.color = Color(1.0, 0.94, 0.82, 1.0) # Luz mágica acolhedora
		_luz_player.energy = 0.34
		_luz_player.texture_scale = 1.65 # Raio amplo para clarear os passos do mago
		_luz_player.position = Vector2(0, -10)
		player.add_child(_luz_player)
	
	# luz no frasco do cientista
	var cientista = find_child("NPCCientista", true, false)
	if cientista:
		_luz_frasco_cientista = PointLight2D.new()
		_luz_frasco_cientista.name = "LuzFrascoAlquimico"
		_luz_frasco_cientista.texture = tex_luz
		_luz_frasco_cientista.color = Color(0.35, 1.0, 0.50, 1.0) # Verde esmeralda químico
		_luz_frasco_cientista.energy = 0.18
		_luz_frasco_cientista.texture_scale = 0.35 # Foco compacto no frasco, sem lavar o chão
		_luz_frasco_cientista.position = Vector2(18, -98) # Posição exata do frasco na mão do cientista
		cientista.add_child(_luz_frasco_cientista)
	
	# portais nas pontas do corredor
	_criar_luz_portal("PortaTransicao", Color(0.85, 0.38, 1.0, 1.0)) # Saída para Química - Roxo arcano
	_criar_luz_portal("PortaRetorno", Color(0.60, 0.65, 1.0, 1.0))    # Retorno ao Hub - Azul misterioso

func _criar_luz_portal(nome_porta: String, cor_luz: Color) -> void:
	var porta = find_child(nome_porta, true, false)
	if not porta:
		return
		
	var luz = PointLight2D.new()
	luz.name = "LuzPortal_" + nome_porta
	luz.texture = _obter_textura_luz()
	luz.color = cor_luz
	luz.energy = 0.45
	luz.texture_scale = 1.45
	luz.position = Vector2(0, -25)
	porta.add_child(luz)
	
	_luzes_portais.append({
		"node": luz,
		"base_energy": 0.45,
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
	
	# pisca a luz das tochas
	for tocha in _luzes_tochas:
		var node = tocha["node"] as PointLight2D
		if not node or not is_instance_valid(node):
			continue
		var off = tocha["offset"]
		var spd = tocha["speed"]
		var f1 = sin((_tempo_iluminacao + off) * spd) * 0.03
		var f2 = sin((_tempo_iluminacao + off * 1.7) * (spd * 1.5)) * 0.02
		var flicker = f1 + f2
		node.energy = tocha["base_energy"] + flicker
	
	# pulso da luz do player
	if _luz_player and is_instance_valid(_luz_player):
		var pulso_p = sin(_tempo_iluminacao * 2.0) * 0.02
		_luz_player.energy = 0.34 + pulso_p
		
	# pulso no frasco do npc
	if _luz_frasco_cientista and is_instance_valid(_luz_frasco_cientista):
		var pulso_c = sin(_tempo_iluminacao * 2.6) * 0.02
		_luz_frasco_cientista.energy = 0.18 + pulso_c
	
	# pulso nos portais
	for portal_info in _luzes_portais:
		var luz_p = portal_info["node"] as PointLight2D
		if luz_p and is_instance_valid(luz_p):
			var off_p = portal_info["offset"]
			var pulso_portal = sin((_tempo_iluminacao + off_p) * 2.2) * 0.04
			luz_p.energy = portal_info["base_energy"] + pulso_portal

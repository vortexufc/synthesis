extends Node2D

# script do corredor de física com iluminação realista escura de laboratório

@export_group("Iluminação Ambiente")
# cor ambiente escura e realista, idêntica às salas de física e química
@export var cor_ambiente: Color = Color(0.24, 0.26, 0.35, 1.0)
@export var energia_aura_player: float = 0.42

var _canvas_modulate: CanvasModulate = null
var _luz_player: PointLight2D = null
var _luz_npc_fisica: PointLight2D = null
var _luzes_portais: Array = []
var _tempo_iluminacao: float = 0.0

func _ready() -> void:
	if get_node_or_null("/root/DatabaseManager"):
		DatabaseManager.active_dungeon = "Física"
	if get_node_or_null("/root/DungeonGenerator"):
		DungeonGenerator.masmorra_retorno_hub = "Física"
		
	if get_node_or_null("/root/AudioManager"):
		AudioManager.start_playlist()
		
	_configurar_sistema_iluminacao()

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

func _configurar_sistema_iluminacao() -> void:
	var tex_luz = _obter_textura_luz()
	
	# 1. Modulação de luz ambiente escura realista (igual às salas de física e química)
	if not find_child("AmbienteLaboratorio", true, false) and not find_child("AmbienteMasmorra", true, false):
		_canvas_modulate = CanvasModulate.new()
		_canvas_modulate.name = "AmbienteLaboratorio"
		_canvas_modulate.color = cor_ambiente
		add_child(_canvas_modulate)
	elif find_child("AmbienteLaboratorio", true, false):
		_canvas_modulate = find_child("AmbienteLaboratorio", true, false) as CanvasModulate
		if _canvas_modulate:
			_canvas_modulate.color = cor_ambiente
	elif find_child("AmbienteMasmorra", true, false):
		_canvas_modulate = find_child("AmbienteMasmorra", true, false) as CanvasModulate
		if _canvas_modulate:
			_canvas_modulate.color = cor_ambiente
			
	# 2. Luz de aura suave que segue o jogador
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

	# 3. Luz no NPC de Física (brilho sutil azul elétrico tecnológico de suas ferramentas)
	var npc = find_child("NPCFisica", true, false)
	if npc and not npc.get_node_or_null("LuzTecnologiaNPC"):
		_luz_npc_fisica = PointLight2D.new()
		_luz_npc_fisica.name = "LuzTecnologiaNPC"
		_luz_npc_fisica.texture = tex_luz
		_luz_npc_fisica.color = Color(0.35, 0.85, 1.0, 1.0) # Azul elétrico de física
		_luz_npc_fisica.energy = 0.32
		_luz_npc_fisica.texture_scale = 0.85
		_luz_npc_fisica.position = Vector2(0, -45)
		npc.add_child(_luz_npc_fisica)

	# 4. Luzes nos portais das pontas do corredor
	_criar_luz_portal("PortaTransicao", Color(0.20, 0.75, 1.0, 1.0)) # Azul elétrico de avanço
	_criar_luz_portal("PortaRetorno", Color(0.15, 0.90, 0.85, 1.0))   # Ciano quântico de retorno

func _criar_luz_portal(nome_porta: String, cor_luz: Color) -> void:
	var porta = find_child(nome_porta, true, false)
	if not porta:
		return
	if porta.get_node_or_null("LuzPortal_" + nome_porta):
		return
		
	var luz = PointLight2D.new()
	luz.name = "LuzPortal_" + nome_porta
	luz.texture = _obter_textura_luz()
	luz.color = cor_luz
	luz.energy = 0.48
	luz.texture_scale = 1.6
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
	
	# Pulsação sutil na aura do player
	if _luz_player and is_instance_valid(_luz_player):
		var pulso_p = sin(_tempo_iluminacao * 2.0) * 0.02
		_luz_player.energy = energia_aura_player + pulso_p
		
	# Pulsação sutil no brilho do NPC
	if _luz_npc_fisica and is_instance_valid(_luz_npc_fisica):
		var pulso_npc = sin(_tempo_iluminacao * 2.5) * 0.025
		_luz_npc_fisica.energy = 0.32 + pulso_npc
		
	# Pulsação mágica e tecnológica nos portais
	for portal_info in _luzes_portais:
		var luz_p = portal_info["node"] as PointLight2D
		if luz_p and is_instance_valid(luz_p):
			var off_p = portal_info["offset"]
			var pulso_portal = sin((_tempo_iluminacao + off_p) * 2.2) * 0.04
			luz_p.energy = portal_info["base_energy"] + pulso_portal

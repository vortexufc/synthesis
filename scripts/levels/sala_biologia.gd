extends Node2D

# script base das salas de biologia (Estufa)

var monstros_na_sala: int = 0
var total_monstros_inicial: int = 0
var _chave_dropada: bool = false

@export_group("Recompensas")
# ativa o drop de chave ao derrotar o ultimo monstro da sala
@export var dropar_chave_no_ultimo_monstro: bool = false

@export_group("Iluminação Solar (Estufa)")
# ativa os feixes de luz solar volumétricos (God Rays) entrando pelo teto de vidro (Item 1)
@export var ativar_feixes_solares: bool = true
# intensidade geral dos feixes solares
@export_range(0.05, 1.0, 0.05) var intensidade_feixes: float = 0.22
# ativa reflexos solares e brilhos especulares nos espelhos, vidraças e decorações (Item 2)
@export var ativar_reflexos_vidro: bool = true
# intensidade dos reflexos e brilhos especulares
@export_range(0.1, 1.0, 0.05) var intensidade_reflexos: float = 0.85
# ativa as sombras suaves de folhagens e copas balançando ao vento no chão (Item 3 - desativado por padrão)
@export var ativar_sombras_folhagens: bool = false
# intensidade das sombras de folhagem no chão
@export_range(0.1, 0.7, 0.05) var intensidade_sombras: float = 0.42
# ativa sombras de contato e projeção nos móveis, mesas, estantes e decorações
@export var ativar_sombras_moveis: bool = true
# intensidade das sombras dos móveis
@export_range(0.1, 0.9, 0.05) var intensidade_sombras_moveis: float = 0.60

# ativa sombras das vigas e caixilhos da claraboia de vidro no chão (Item 4)
@export var ativar_sombras_caixilhos: bool = true
# intensidade das sombras dos caixilhos no chão
@export_range(0.05, 0.40, 0.02) var intensidade_caixilhos: float = 0.16

# ativa sombra suave de contato na raiz/base dos inimigos botânicos (Item 5)
@export var ativar_sombras_inimigos: bool = true
# intensidade da sombra dos inimigos
@export_range(0.1, 0.8, 0.05) var intensidade_sombras_inimigos: float = 0.38

# Bioluminescência Suave nas Flores Raras, Inimigos e Cenário (Item 5)
@export var ativar_bioluminescencia: bool = true
@export_range(0.1, 1.0, 0.05) var intensidade_bioluminescencia: float = 0.65

# Poeira Solar e Grãos de Pólen Flutuantes (Item 4)
@export var ativar_polen_solar: bool = true

# Texturas geradas proceduralmente em cache
static var _textura_feixe_solar: Texture2D = null
static var _textura_mancha_chao: Texture2D = null
static var _textura_brilho_glint: Texture2D = null
static var _textura_sombra_folhagem: Texture2D = null
static var _textura_sombra_objeto: Texture2D = null
static var _textura_sombra_retangular: Texture2D = null
static var _textura_sombra_caixilho: Texture2D = null
static var _textura_luz_bioluminescente: Texture2D = null

var _feixes_solares: Array = []
var _reflexos_vidro: Array = []
var _sombras_folhagens: Array = []
var _luzes_bioluminescentes: Array = []
var _tempo_iluminacao_tick: float = 0.0
var _tempo_animacao_solar: float = 0.0

var _top_y_por_col: Dictionary = {}
var _bot_y_por_col: Dictionary = {}
var _celulas_validas_sala: Dictionary = {}
var _celulas_chao_sala: Dictionary = {}
var _min_col_x: int = 999999
var _max_col_x: int = -999999

const POSICOES_FLORES = {
	"Sala_Biologia01": {"pos": Vector2(176, 688), "cor": "amarela"},
	"Sala_Biologia02": {"pos": Vector2(816, 880), "cor": "azul"},
	"Sala_Biologia03": {"pos": Vector2(3120, 848), "cor": "roxa"},
	"Sala_Biologia04": {"pos": Vector2(1056, 640), "cor": "laranja"},
	"Sala_Biologia05": {"pos": Vector2(2096, 752), "cor": "vermelha"},
	"Sala_Biologia06": {"pos": Vector2(2160, 1520), "cor": "amarela"},
	"Sala_Biologia07": {"pos": Vector2(624, 976), "cor": "azul"},
	"Sala_Biologia08": {"pos": Vector2(2896, 2352), "cor": "roxa"},
	"Sala_Biologia09": {"pos": Vector2(1584, 912), "cor": "laranja"},
	"Sala_Biologia10": {"pos": Vector2(1200, 816), "cor": "vermelha"},
	"Sala_Biologia11": {"pos": Vector2(1328, 1040), "cor": "azul"},
	"Sala_BossBiologia": {"pos": Vector2(240, 784), "cor": "amarela"},
}

func _ready() -> void:
	var db = get_node_or_null("/root/DatabaseManager")
	if db:
		db.active_dungeon = "Biologia"
	var dg = get_node_or_null("/root/DungeonGenerator")
	if dg:
		dg.masmorra_retorno_hub = "Biologia"
		dropar_chave_no_ultimo_monstro = dg.sala_usa_chave(scene_file_path)
		print("[Sala Biologia] dropar_chave_no_ultimo_monstro = ", dropar_chave_no_ultimo_monstro, " para ", scene_file_path)
		
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.start_playlist()
		
	# Configura os inimigos da sala de acordo com o tier dinâmico da masmorra
	# Progressão: 3 salas Flor Amarela (Tier 1) -> 2 salas Flor Roxa (Tier 2) -> 2 salas Flor Vermelha (Tier 3) -> Boss (Planta Carnívora)
	var cena_atual = scene_file_path.to_lower()
	var eh_boss = "boss" in cena_atual
	if dg:
		eh_boss = eh_boss or dg.is_sala_boss(scene_file_path)
	
	if not eh_boss and dg:
		var tier = dg.get_tier_da_sala(scene_file_path)
		if tier > 0:
			_configurar_tier_dos_inimigos(tier)
	
	_iniciar_sistema_inimigos_e_portas()
	_spawn_flor_rara_se_necessario()
	
	_construir_geometria_sala()
	
	if ativar_sombras_caixilhos:
		_configurar_sombras_caixilhos()
	if ativar_feixes_solares:
		_configurar_feixes_solares()
	if ativar_reflexos_vidro:
		_configurar_reflexos_vidro()
	if ativar_sombras_folhagens:
		_configurar_sombras_folhagens()
	if ativar_sombras_moveis:
		_configurar_sombras_moveis()
	if ativar_sombras_inimigos:
		call_deferred("_configurar_sombras_inimigos")
	if ativar_bioluminescencia:
		call_deferred("_configurar_bioluminescencia")
	if ativar_polen_solar:
		_configurar_polen_solar()

# Configura os inimigos da sala para o tier da progressão (1=amarela/fácil, 2=roxa/médio, 3=vermelha/difícil)
func _configurar_tier_dos_inimigos(tier: int) -> void:
	print("[Sala Biologia] Configurando inimigos para TIER %d em %s" % [tier, scene_file_path])
	
	var sprite_path = ""
	var sprite_scale = Vector2(2.0, 2.0)
	var enemy_id = ""
	var stats = {}
	
	if tier == 1:
		# Tier 1: Flor Amarela (Fácil)
		sprite_path = "res://assets/sprites/Sprite Frames/flor_amarela.tres"
		enemy_id = "flor_amarela"
		stats = {
			"vida_maxima": 50.0,
			"dano": 12.0,
			"velocidade": 36.0,
			"velocidade_perseguicao": 52.0,
			"distancia_perseguicao": 160.0
		}
	elif tier == 2:
		# Tier 2: Flor Roxa (Médio)
		sprite_path = "res://assets/sprites/Sprite Frames/flor_roxa.tres"
		enemy_id = "flor_roxa"
		stats = {
			"vida_maxima": 75.0,
			"dano": 16.0,
			"velocidade": 40.0,
			"velocidade_perseguicao": 60.0,
			"distancia_perseguicao": 180.0
		}
	elif tier == 3:
		# Tier 3: Flor Vermelha (Difícil)
		sprite_path = "res://assets/sprites/Sprite Frames/flor_vermelha.tres"
		enemy_id = "flor_vermelha"
		stats = {
			"vida_maxima": 105.0,
			"dano": 22.0,
			"velocidade": 46.0,
			"velocidade_perseguicao": 68.0,
			"distancia_perseguicao": 190.0
		}
	else:
		return
		
	var sprite_frames = load(sprite_path) as SpriteFrames
	if not sprite_frames:
		push_warning("[Sala Biologia] Não foi possível carregar sprite frames: %s" % sprite_path)
		return
		
	# Encontra todos os inimigos da sala
	var inimigos_encontrados: Array = []
	for node in get_tree().get_nodes_in_group("inimigos"):
		if is_ancestor_of(node) and is_instance_valid(node) and not node.is_queued_for_deletion():
			inimigos_encontrados.append(node)
			
	if inimigos_encontrados.is_empty():
		for body in find_children("*", "CharacterBody2D", true, false):
			if not body.is_queued_for_deletion() and not body.is_in_group("player") and body.name != "Player" and not body.name.begins_with("Player"):
				inimigos_encontrados.append(body)
				
	for inimigo in inimigos_encontrados:
		if not is_instance_valid(inimigo) or inimigo.is_queued_for_deletion():
			continue
			
		# Se o inimigo tinha nome de chefe herdado de template antigo, limpa o nome e flag
		if "boss" in inimigo.name.to_lower() or "carnivora" in inimigo.name.to_lower():
			inimigo.name = "Planta_" + str(inimigo.get_index())
		inimigo.set("eh_boss", false)
		
		# Atualiza AnimatedSprite2D
		var sprite_node = inimigo.get_node_or_null("AnimatedSprite2D")
		if sprite_node and sprite_node is AnimatedSprite2D:
			sprite_node.sprite_frames = sprite_frames
			sprite_node.scale = sprite_scale
			if sprite_node.sprite_frames.has_animation("default"):
				sprite_node.play("default")
				
		# Atualiza atributos do enemy.gd
		for key in stats:
			if key in inimigo:
				inimigo.set(key, stats[key])
		if "vida_atual" in inimigo:
			inimigo.vida_atual = stats.get("vida_maxima", 100.0)
		
		# Atualiza EnemyTrigger
		var trigger = inimigo.get_node_or_null("EnemyTrigger")
		if trigger:
			if "id_inimigo" in trigger:
				trigger.id_inimigo = enemy_id
			if "nivel_dificuldade" in trigger:
				trigger.nivel_dificuldade = tier
			if "andar_id" in trigger:
				trigger.andar_id = 3
				
		# Sincroniza cor da bioluminescência se o inimigo já tiver luz criada
		var luz_bio = inimigo.get_node_or_null("LuzBioInimigo") as PointLight2D
		if luz_bio:
			if tier == 1:
				luz_bio.color = Color(1.0, 0.88, 0.32, 1.0)
			elif tier == 2:
				luz_bio.color = Color(0.85, 0.40, 1.0, 1.0)
			elif tier == 3:
				luz_bio.color = Color(1.0, 0.30, 0.38, 1.0)

func _is_posicao_valida(pos: Vector2, floor_node: TileMapLayer, wall_node: TileMapLayer, decor_node: TileMapLayer = null) -> bool:
	if not floor_node:
		return true
	_construir_geometria_sala()
	if not _pos_esta_dentro_da_sala(pos, 44.0):
		return false
		
	var cell = floor_node.local_to_map(floor_node.to_local(pos))
	if not _is_celula_coberta(cell, floor_node):
		return false
		
	# Checa se a célula atual está em parede
	if wall_node and _is_celula_coberta(cell, wall_node):
		return false
		
	# Checa se há colisão física sólida na posição (paredes, balcões, obstáculos com colisão)
	if is_inside_tree() and get_world_2d():
		var space = get_world_2d().direct_space_state
		var q = PhysicsShapeQueryParameters2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 14.0
		q.shape = shape
		q.transform = Transform2D(0.0, pos)
		q.collision_mask = 1
		q.collide_with_bodies = true
		if space.intersect_shape(q).size() > 0:
			return false
			
	return true

func _is_celula_coberta(cell: Vector2i, layer: TileMapLayer) -> bool:
	if not layer or not layer.tile_set:
		return false
	if layer.get_cell_source_id(cell) != -1:
		return true
	for used_cell in layer.get_used_cells():
		var source_id = layer.get_cell_source_id(used_cell)
		var atlas_coords = layer.get_cell_atlas_coords(used_cell)
		var source = layer.tile_set.get_source(source_id) as TileSetAtlasSource
		if source and source.has_tile(atlas_coords):
			var size = source.get_tile_size_in_atlas(atlas_coords)
			if size.x > 1 or size.y > 1:
				if cell.x >= used_cell.x and cell.x < used_cell.x + size.x and \
				   cell.y >= used_cell.y and cell.y < used_cell.y + size.y:
					return true
	return false

func _encontrar_posicao_chao_segura(pos_desejada: Vector2, floor_node: TileMapLayer, wall_node: TileMapLayer, decor_node: TileMapLayer = null) -> Vector2:
	if not floor_node:
		return pos_desejada
	_construir_geometria_sala()
	var cells = floor_node.get_used_cells()
	if cells.is_empty():
		return pos_desejada
		
	var melhor_pos = Vector2.ZERO
	var menor_dist = 9999999.0
	
	for cell in cells:
		var wpos = floor_node.to_global(floor_node.map_to_local(cell))
		if not _is_posicao_valida(wpos, floor_node, wall_node, decor_node):
			continue
		var dist = wpos.distance_to(pos_desejada)
		if dist < menor_dist:
			menor_dist = dist
			melhor_pos = wpos
			
	return melhor_pos if melhor_pos != Vector2.ZERO else pos_desejada

func _spawn_flor_rara_se_necessario() -> void:
	var cena_nome = ""
	if scene_file_path:
		cena_nome = scene_file_path.get_file().get_basename()
	elif name:
		cena_nome = name
		
	if not POSICOES_FLORES.has(cena_nome):
		return
		
	var item_id = "FlorRara::" + cena_nome
	var ps = get_node_or_null("/root/PlayerStats")
	if ps and ps.is_item_coletado(item_id):
		return
		
	# Checa se ja tem na cena
	for child in get_children():
		if child.name.begins_with("ItemFlorRara"):
			return
			
	var cena_flor = load("res://scenes/Entidades/Items/ItemFlorRara.tscn") as PackedScene
	if not cena_flor:
		return
		
	var info = POSICOES_FLORES[cena_nome]
	var target_pos: Vector2 = info["pos"]
	
	# Validação de segurança: se a posição não estiver em uma célula de chão válida ou colidir com parede/decoração, ajusta automaticamente
	var floor_node = get_node_or_null("Floor") as TileMapLayer
	var wall_node = get_node_or_null("Wall") as TileMapLayer
	var decor_node = get_node_or_null("Decoration") as TileMapLayer
	if floor_node:
		if not _is_posicao_valida(to_global(target_pos), floor_node, wall_node, decor_node):
			target_pos = to_local(_encontrar_posicao_chao_segura(to_global(target_pos), floor_node, wall_node, decor_node))
			
	var flor_inst = cena_flor.instantiate()
	flor_inst.name = "ItemFlorRara"
	flor_inst.id_unico = item_id
	if "tipo_cor" in flor_inst:
		flor_inst.tipo_cor = info["cor"]
	flor_inst.position = target_pos
	add_child(flor_inst)
	if ativar_bioluminescencia:
		_adicionar_luz_flor_rara(flor_inst, info["cor"])

func _iniciar_sistema_inimigos_e_portas() -> void:
	var inimigos = get_tree().get_nodes_in_group("inimigos")
	var count = 0
	for inimigo in inimigos:
		if is_ancestor_of(inimigo) and not inimigo.is_queued_for_deletion():
			count += 1
			if inimigo.has_signal("inimigo_derrotado") and not inimigo.inimigo_derrotado.is_connected(_on_inimigo_derrotado):
				inimigo.inimigo_derrotado.connect(_on_inimigo_derrotado)
			elif inimigo.has_node("EnemyTrigger"):
				var trig = inimigo.get_node("EnemyTrigger")
				if trig.has_signal("inimigo_derrotado") and not trig.inimigo_derrotado.is_connected(_on_inimigo_derrotado):
					trig.inimigo_derrotado.connect(_on_inimigo_derrotado)
			
	if count == 0:
		for child in get_children():
			if not child.is_queued_for_deletion() and not child.is_in_group("player") and child.name != "Player" and not child.name.begins_with("Player"):
				if child.has_node("EnemyTrigger") or child.name.begins_with("Slime") or child.name.begins_with("Robo") or (child is CharacterBody2D):
					count += 1
					child.add_to_group("inimigos")
					if child.has_signal("inimigo_derrotado") and not child.inimigo_derrotado.is_connected(_on_inimigo_derrotado):
						child.inimigo_derrotado.connect(_on_inimigo_derrotado)
					elif child.has_node("EnemyTrigger"):
						var trig = child.get_node("EnemyTrigger")
						if trig.has_signal("inimigo_derrotado") and not trig.inimigo_derrotado.is_connected(_on_inimigo_derrotado):
							trig.inimigo_derrotado.connect(_on_inimigo_derrotado)
					
	monstros_na_sala = count
	total_monstros_inicial = count

func _contar_monstros_restantes() -> int:
	var count = 0
	for inimigo in get_tree().get_nodes_in_group("inimigos"):
		if is_ancestor_of(inimigo) and is_instance_valid(inimigo) and not inimigo.is_queued_for_deletion():
			count += 1
	return count

func _on_inimigo_derrotado(pos: Vector2) -> void:
	monstros_na_sala = max(0, monstros_na_sala - 1)
	var vivos_restantes = _contar_monstros_restantes()
	print("[Sala Biologia] Inimigo derrotado. Restantes contados: %d, contador: %d" % [vivos_restantes, monstros_na_sala])
	if not _chave_dropada and (monstros_na_sala <= 0 or vivos_restantes <= 1) and _deve_dropar_chave():
		_chave_dropada = true
		_dropar_chave(pos)

func _deve_dropar_chave() -> bool:
	if dropar_chave_no_ultimo_monstro:
		return true
	for p in get_tree().get_nodes_in_group("porta_transicao"):
		if is_ancestor_of(p) and (p.get("esta_trancada") == true or p.get("precisa_de_chave") == true):
			return true
	if has_node("PortaTrancada") or has_node("PortaTrancadaTeste"):
		return true
	return false

func _dropar_chave(pos: Vector2) -> void:
	var cena_atual = scene_file_path.to_lower()
	if "boss" in cena_atual:
		return
	var cena_chave = load("res://scenes/Entidades/Items/ItemChave.tscn")
	if not cena_chave:
		cena_chave = load("res://scenes/Entidades/ItemChave.tscn")
	if not cena_chave:
		return
	var chave = cena_chave.instantiate()
	if "is_drop_dinamico" in chave:
		chave.is_drop_dinamico = true
		
	var drop_pos = to_local(pos)
	var floor_node = get_node_or_null("Floor") as TileMapLayer
	var wall_node = get_node_or_null("Wall") as TileMapLayer
	if floor_node:
		if not _is_posicao_valida(to_global(drop_pos), floor_node, wall_node):
			drop_pos = to_local(_encontrar_posicao_chao_segura(to_global(drop_pos), floor_node, wall_node))
			
	chave.position = drop_pos
	call_deferred("add_child", chave)
	print("[Sala Biologia] Chave dropada com sucesso na posição: ", drop_pos)

# ==============================================================================
# ILUMINAÇÃO SOLAR (ESTUFA DE BIOLOGIA)
# ITEM 1: FEIXES VOLUMÉTRICOS (GOD RAYS)
# ITEM 2: REFLEXOS SOLARES & BRILHOS ESPECULARES (GLINTS NOS ESPELHOS E VIDROS)
# ITEM 3: SOMBRAS SUAVES DE FOLHAGENS AO VENTO (CANOPY WIND SHADOWS)
# ==============================================================================

static func _obter_textura_feixe_solar() -> Texture2D:
	if _textura_feixe_solar != null:
		return _textura_feixe_solar
		
	var img = Image.create(128, 512, false, Image.FORMAT_RGBA8)
	for y in range(512):
		var v_factor: float
		if y < 90:
			v_factor = smoothstep(0.0, 90.0, float(y))
		elif y > 420:
			v_factor = 1.0 - smoothstep(420.0, 512.0, float(y))
		else:
			v_factor = 1.0
			
		for x in range(128):
			var dist_center = abs(float(x) - 64.0) / 64.0
			var h_factor = clampf(1.0 - dist_center, 0.0, 1.0)
			h_factor = pow(h_factor, 1.6)
			var a = v_factor * h_factor
			img.set_pixel(x, y, Color(1.0, 0.95, 0.82, a))
			
	_textura_feixe_solar = ImageTexture.create_from_image(img)
	return _textura_feixe_solar

static func _obter_textura_mancha_chao() -> Texture2D:
	if _textura_mancha_chao != null:
		return _textura_mancha_chao
		
	var img_chao = Image.create(160, 80, false, Image.FORMAT_RGBA8)
	for y in range(80):
		var dy = (float(y) - 40.0) / 40.0
		for x in range(160):
			var dx = (float(x) - 80.0) / 80.0
			var dist = sqrt(dx * dx + dy * dy)
			var a = clampf(1.0 - dist, 0.0, 1.0)
			a = pow(a, 1.5) * 0.55
			img_chao.set_pixel(x, y, Color(1.0, 0.94, 0.78, a))
			
	_textura_mancha_chao = ImageTexture.create_from_image(img_chao)
	return _textura_mancha_chao

static func _obter_textura_brilho_glint() -> Texture2D:
	if _textura_brilho_glint != null:
		return _textura_brilho_glint
		
	var size = 48
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var half = float(size) / 2.0
	
	for y in range(size):
		for x in range(size):
			var dx = (float(x) - half + 0.5) / half
			var dy = (float(y) - half + 0.5) / half
			var r = sqrt(dx * dx + dy * dy)
			
			var glow = clampf(1.0 - r * 1.6, 0.0, 1.0)
			glow = pow(glow, 2.0) * 0.65
			
			var h_line = clampf(1.0 - abs(dx), 0.0, 1.0) * clampf(1.0 - abs(dy) * 4.5, 0.0, 1.0)
			h_line = pow(h_line, 2.5) * 0.95
			
			var v_line = clampf(1.0 - abs(dy), 0.0, 1.0) * clampf(1.0 - abs(dx) * 4.5, 0.0, 1.0)
			v_line = pow(v_line, 2.5) * 0.95
			
			var d1 = abs(dx + dy) * 0.707
			var d2 = abs(dx - dy) * 0.707
			var diag = clampf(1.0 - (d1 + d2), 0.0, 1.0) * 0.35
			diag = pow(diag, 3.0)
			
			var val = clampf(glow + h_line + v_line + diag, 0.0, 1.0)
			if val > 0.01:
				img.set_pixel(x, y, Color(1.0, 0.96, 0.84, val))
				
	_textura_brilho_glint = ImageTexture.create_from_image(img)
	return _textura_brilho_glint

static func _obter_textura_sombra_folhagem() -> Texture2D:
	if _textura_sombra_folhagem != null:
		return _textura_sombra_folhagem
		
	var size = 192
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var half = float(size) / 2.0
	
	var rng = RandomNumberGenerator.new()
	rng.seed = 12345
	
	for i in range(32):
		var lx = rng.randf_range(35.0, size - 35.0)
		var ly = rng.randf_range(35.0, size - 35.0)
		var rx = rng.randf_range(16.0, 36.0)
		var ry = rng.randf_range(10.0, 22.0)
		var ang = rng.randf_range(0.0, PI)
		var cos_a = cos(ang)
		var sin_a = sin(ang)
		var max_r = maxf(rx, ry)
		
		var min_x = clampi(int(lx - max_r), 0, size - 1)
		var max_x = clampi(int(lx + max_r), 0, size - 1)
		var min_y = clampi(int(ly - max_r), 0, size - 1)
		var max_y = clampi(int(ly + max_r), 0, size - 1)
		
		for y in range(min_y, max_y + 1):
			var dy = float(y) - ly
			for x in range(min_x, max_x + 1):
				var dx = float(x) - lx
				var rx_rot = (dx * cos_a + dy * sin_a) / rx
				var ry_rot = (-dx * sin_a + dy * cos_a) / ry
				var d = rx_rot * rx_rot + ry_rot * ry_rot
				if d < 1.0:
					var leaf_alpha = pow(1.0 - d, 0.8) * 0.85
					var cdx = (float(x) - half) / half
					var cdy = (float(y) - half) / half
					var c_dist = sqrt(cdx * cdx + cdy * cdy)
					var c_fade = clampf(1.0 - c_dist, 0.0, 1.0)
					var final_a = leaf_alpha * c_fade
					
					var cur_c = img.get_pixel(x, y)
					if final_a > cur_c.a:
						img.set_pixel(x, y, Color(0.0, 0.0, 0.0, final_a))
						
	_textura_sombra_folhagem = ImageTexture.create_from_image(img)
	return _textura_sombra_folhagem

static func _obter_textura_sombra_objeto() -> Texture2D:
	if _textura_sombra_objeto != null:
		return _textura_sombra_objeto
		
	var w = 64
	var h = 32
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var hw = float(w) / 2.0
	var hh = float(h) / 2.0
	
	for y in range(h):
		var dy = (float(y) - hh + 0.5) / hh
		for x in range(w):
			var dx = (float(x) - hw + 0.5) / hw
			var dist = sqrt(dx * dx + dy * dy)
			var a = clampf(1.0 - dist, 0.0, 1.0)
			a = pow(a, 1.4)
			if a > 0.01:
				img.set_pixel(x, y, Color(0.0, 0.0, 0.0, a))
				
	_textura_sombra_objeto = ImageTexture.create_from_image(img)
	return _textura_sombra_objeto

static func _obter_textura_sombra_retangular() -> Texture2D:
	if _textura_sombra_retangular != null:
		return _textura_sombra_retangular
		
	var w = 128
	var h = 64
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var half_w = float(w) / 2.0
	var half_h = float(h) / 2.0
	
	for y in range(h):
		var ny = abs(float(y) - half_h + 0.5) / half_h
		var ay = clampf(1.0 - pow(ny, 2.6), 0.0, 1.0)
		for x in range(w):
			var nx = abs(float(x) - half_w + 0.5) / half_w
			var ax = clampf(1.0 - pow(nx, 3.0), 0.0, 1.0)
			var a = ax * ay
			a = pow(a, 1.2)
			if a > 0.01:
				img.set_pixel(x, y, Color(0.0, 0.0, 0.0, a))
				
	_textura_sombra_retangular = ImageTexture.create_from_image(img)
	return _textura_sombra_retangular

static func _obter_textura_sombra_caixilho() -> Texture2D:
	if _textura_sombra_caixilho != null:
		return _textura_sombra_caixilho
		
	var w = 32
	var h = 256
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		for x in range(w):
			var nx = abs(float(x) - 16.0) / 16.0
			var h_factor = clampf(1.0 - nx, 0.0, 1.0)
			h_factor = pow(h_factor, 1.8)
			if h_factor > 0.01:
				img.set_pixel(x, y, Color(0.0, 0.0, 0.0, h_factor))
				
	_textura_sombra_caixilho = ImageTexture.create_from_image(img)
	return _textura_sombra_caixilho

static func _obter_textura_luz_bioluminescente() -> Texture2D:
	if _textura_luz_bioluminescente != null:
		return _textura_luz_bioluminescente
		
	var grad_tex = GradientTexture2D.new()
	grad_tex.width = 128
	grad_tex.height = 128
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	var grad = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.40, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.42),
		Color(1.0, 1.0, 1.0, 0.0)
	])
	grad_tex.gradient = grad
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(0.5, 0.0)
	_textura_luz_bioluminescente = grad_tex
	return _textura_luz_bioluminescente

# Constrói o mapa de colunas e células válidas da sala considerando o tamanho real dos azulejos nos atlas
func _construir_geometria_sala() -> void:
	if not _top_y_por_col.is_empty():
		return
	_top_y_por_col.clear()
	_bot_y_por_col.clear()
	_celulas_validas_sala.clear()
	_celulas_chao_sala.clear()
	_min_col_x = 999999
	_max_col_x = -999999
	
	var floor_layer = get_node_or_null("Floor") as TileMapLayer
	var wall_layer = get_node_or_null("Wall") as TileMapLayer
	var decor_layer = get_node_or_null("Decoration") as TileMapLayer
	
	var layers: Array[TileMapLayer] = []
	if floor_layer:
		layers.append(floor_layer)
	if wall_layer:
		layers.append(wall_layer)
	if decor_layer:
		layers.append(decor_layer)
		
	for layer in layers:
		var ts = layer.tile_set
		for cell in layer.get_used_cells():
			var s_id = layer.get_cell_source_id(cell)
			var size = Vector2i(1, 1)
			if s_id != -1 and ts:
				var src = ts.get_source(s_id)
				if src is TileSetAtlasSource:
					var coords = layer.get_cell_atlas_coords(cell)
					size = src.get_tile_size_in_atlas(coords)
			for dx in range(size.x):
				for dy in range(size.y):
					var c = Vector2i(cell.x + dx, cell.y + dy)
					_celulas_validas_sala[c] = true
					if layer == floor_layer:
						_celulas_chao_sala[c] = true
					
					var cx = c.x
					var cy = c.y
					_min_col_x = mini(_min_col_x, cx)
					_max_col_x = maxi(_max_col_x, cx)
					if not _top_y_por_col.has(cx) or cy < _top_y_por_col[cx]:
						_top_y_por_col[cx] = cy
					if not _bot_y_por_col.has(cx) or cy > _bot_y_por_col[cx]:
						_bot_y_por_col[cx] = cy

# Valida se uma posição do mundo está estritamente dentro do ambiente da sala
func _pos_esta_dentro_da_sala(pos_world: Vector2, margem: float = 0.0) -> bool:
	var floor_layer = get_node_or_null("Floor") as TileMapLayer
	if not floor_layer or _top_y_por_col.is_empty():
		return true
		
	var pontos: Array[Vector2] = [pos_world]
	if margem > 0.0:
		pontos.append(pos_world + Vector2(-margem, 0.0))
		pontos.append(pos_world + Vector2(margem, 0.0))
		pontos.append(pos_world + Vector2(0.0, -margem))
		pontos.append(pos_world + Vector2(0.0, margem))
		
	for pt in pontos:
		var cell = floor_layer.local_to_map(floor_layer.to_local(pt))
		if cell.x < _min_col_x or cell.x > _max_col_x:
			return false
		if not _top_y_por_col.has(cell.x):
			return false
		if cell.y < _top_y_por_col[cell.x] or cell.y > _bot_y_por_col[cell.x]:
			return false
	return true

func _configurar_feixes_solares() -> void:
	var floor_layer = get_node_or_null("Floor") as TileMapLayer
	if not floor_layer:
		return
		
	_construir_geometria_sala()
	if _top_y_por_col.is_empty():
		return
		
	var container = Node2D.new()
	container.name = "FeixesSolares"
	add_child(container)
	
	var tex_feixe = _obter_textura_feixe_solar()
	var tex_chao = _obter_textura_mancha_chao()
	
	var mat = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	
	var cols_sorted = _top_y_por_col.keys()
	cols_sorted.sort()
	
	# Filtra apenas colunas com altura de sala substancial (mínimo 10 ladrilhos de altura)
	# e com margem de segurança de 3 ladrilhos das bordas externas
	var usable_cols: Array[int] = []
	for c in cols_sorted:
		if (_bot_y_por_col[c] - _top_y_por_col[c]) >= 10 and c >= _min_col_x + 3 and c <= _max_col_x - 3:
			usable_cols.append(c)
			
	if usable_cols.is_empty():
		return
		
	var colunas_viaveis: Array = []
	var hw = 56.0 # Meia-largura real do feixe para garantir que nenhuma borda encoste em paredes ou no vazio
	
	for cx in usable_cols:
		var cy_top = _top_y_por_col[cx]
		var start_local = floor_layer.map_to_local(Vector2i(cx, cy_top))
		var start_world = floor_layer.to_global(start_local) + Vector2(0.0, 38.0)
		
		# Projeção solar majestosa inclinada para a esquerda
		var angulo_solar = clampf(0.26 + randf_range(-0.015, 0.015), 0.18, 0.30)
		var dir = Vector2(-sin(angulo_solar), cos(angulo_solar)).normalized()
		var rot = Vector2.DOWN.angle_to(dir)
		var perp = Vector2(-dir.y, dir.x)
		
		# Validação estrita da largura completa na origem (o centro e ambas as bordas devem estar dentro da sala)
		if not _pos_esta_dentro_da_sala(start_world, 16.0):
			continue
		if not _pos_esta_dentro_da_sala(start_world + perp * hw) or not _pos_esta_dentro_da_sala(start_world - perp * hw):
			continue
			
		var dist = 0.0
		var step_len = 16.0
		while dist + step_len < 3000.0:
			var next_d = dist + step_len
			var px = start_world + dir * next_d
			if not _pos_esta_dentro_da_sala(px):
				break
			if not _pos_esta_dentro_da_sala(px + perp * hw) or not _pos_esta_dentro_da_sala(px - perp * hw):
				break
			dist = next_d
			
		if dist >= 160.0:
			colunas_viaveis.append({
				"cx": cx,
				"start_world": start_world,
				"dist": dist,
				"dir": dir,
				"rot": rot
			})
			
	if colunas_viaveis.is_empty():
		return
		
	# Identifica se há porta na parede superior próxima à borda direita com vidraça ao seu lado
	var cols_janela_porta: Array = []
	var cols_sala_principal: Array = []
	
	var floor_rect = floor_layer.get_used_rect()
	var min_w = floor_layer.to_global(floor_layer.map_to_local(floor_rect.position))
	var max_w = floor_layer.to_global(floor_layer.map_to_local(floor_rect.end))
	var room_min_y = minf(min_w.y, max_w.y)
	var room_max_y = maxf(min_w.y, max_w.y)
	var room_max_x = maxf(min_w.x, max_w.x)
	var room_h = room_max_y - room_min_y
	
	var porta_direita_topo: Node2D = null
	for child in get_children():
		if child is Node2D and ("porta" in child.name.to_lower() or "door" in child.name.to_lower()):
			var p_world = to_global(child.position)
			var rel_y = (p_world.y - room_min_y) / room_h if room_h > 0.0 else 0.0
			var dist_direita = room_max_x - p_world.x
			# Porta no terço superior da sala e situada entre 120px e 420px da parede direita
			if rel_y <= 0.35 and dist_direita >= 120.0 and dist_direita <= 420.0:
				porta_direita_topo = child
				break
				
	if porta_direita_topo:
		var door_x = to_global(porta_direita_topo.position).x
		for c_data in colunas_viaveis:
			if c_data["start_world"].x > door_x + 35.0:
				cols_janela_porta.append(c_data)
			else:
				cols_sala_principal.append(c_data)
	else:
		cols_sala_principal = colunas_viaveis.duplicate()
		
	var feixes_selecionados: Array = []
	
	# 1. Garante feixe de sol na vidraça ao lado direito da porta
	if not cols_janela_porta.is_empty():
		var mid_idx = int(float(cols_janela_porta.size()) / 2.0)
		feixes_selecionados.append(cols_janela_porta[mid_idx])
		
	# 2. Distribui os feixes na sala principal
	var total_feixes = clampi(int(float(colunas_viaveis.size()) / 10.0), 3, 6)
	var feixes_principais = total_feixes
	if not cols_janela_porta.is_empty() and total_feixes >= 5:
		feixes_principais = total_feixes - 1
	if feixes_principais < 2 and not cols_sala_principal.is_empty():
		feixes_principais = mini(2, cols_sala_principal.size())
		
	if not cols_sala_principal.is_empty() and feixes_principais > 0:
		var step = maxi(1, int(cols_sala_principal.size() / float(feixes_principais + 1)))
		for i in range(feixes_principais):
			var idx = mini(cols_sala_principal.size() - 1, step * (i + 1))
			feixes_selecionados.append(cols_sala_principal[idx])
			
	feixes_selecionados.sort_custom(func(a, b): return a["cx"] < b["cx"])
	
	for i in range(feixes_selecionados.size()):
		var c_data = feixes_selecionados[i]
		var start_world: Vector2 = c_data["start_world"]
		var dist: float = c_data["dist"]
		var dir: Vector2 = c_data["dir"]
		var rot: float = c_data["rot"]
		
		var scale_x = clampf(dist / 650.0, 0.70, 1.30)
		var scale_y = dist / 512.0
		var base_alpha = randf_range(0.18, 0.28) * (intensidade_feixes / 0.22)
		
		var sprite_feixe = Sprite2D.new()
		sprite_feixe.name = "FeixeSolar_" + str(i + 1)
		sprite_feixe.texture = tex_feixe
		sprite_feixe.material = mat
		sprite_feixe.z_index = 5
		sprite_feixe.centered = true
		sprite_feixe.offset = Vector2(0, 256)
		sprite_feixe.position = to_local(start_world)
		sprite_feixe.rotation = rot
		sprite_feixe.scale = Vector2(scale_x, scale_y)
		sprite_feixe.modulate = Color(1.0, 0.95, 0.82, base_alpha)
		container.add_child(sprite_feixe)
		
		# Mancha de sol no chão apenas se atingir solo válido e dentro da sala
		var sprite_chao: Sprite2D = null
		var chao_pos = start_world + dir * (dist * 0.94)
		var chao_cell = floor_layer.local_to_map(floor_layer.to_local(chao_pos))
		if _celulas_chao_sala.has(chao_cell) and _pos_esta_dentro_da_sala(chao_pos, 28.0):
			sprite_chao = Sprite2D.new()
			sprite_chao.name = "ManchaChaoSolar_" + str(i + 1)
			sprite_chao.texture = tex_chao
			sprite_chao.material = mat
			sprite_chao.z_index = 1
			sprite_chao.position = to_local(chao_pos)
			sprite_chao.scale = Vector2(scale_x * 1.3, 1.0)
			sprite_chao.modulate = Color(1.0, 0.94, 0.78, base_alpha * 0.70)
			container.add_child(sprite_chao)
			
		_feixes_solares.append({
			"feixe": sprite_feixe,
			"chao": sprite_chao,
			"base_alpha": base_alpha,
			"base_rot": rot,
			"speed_shimmer": randf_range(1.2, 2.2),
			"speed_drift": randf_range(0.35, 0.65),
			"offset": randf() * 10.0
		})

func _configurar_reflexos_vidro() -> void:
	var floor_layer = get_node_or_null("Floor") as TileMapLayer
	if not floor_layer:
		return
		
	_construir_geometria_sala()
	if _top_y_por_col.is_empty():
		return
		
	var container = Node2D.new()
	container.name = "ReflexosVidro"
	add_child(container)
	
	var tex_glint = _obter_textura_brilho_glint()
	var mat = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	
	var posicoes: Array[Vector2] = []
	
	# 1. Reflexos nas claraboias / vidraças superiores (ancorados nos feixes solares ou vidraças válidas)
	if not _feixes_solares.is_empty():
		for f in _feixes_solares:
			if f.has("feixe") and f["feixe"] != null:
				var f_spr = f["feixe"] as Sprite2D
				if f_spr and is_instance_valid(f_spr):
					var p_beam = to_global(f_spr.position) + Vector2(randf_range(-14.0, 14.0), randf_range(-6.0, 6.0))
					if _pos_esta_dentro_da_sala(p_beam, 28.0):
						posicoes.append(p_beam)
						
	# 2. Reflexos nas decorações de vidro, frascos e espelhos da sala
	var decor_layer = get_node_or_null("Decoration") as TileMapLayer
	if decor_layer:
		var cells = decor_layer.get_used_cells()
		if not cells.is_empty():
			var cells_shuffled = cells.duplicate()
			cells_shuffled.shuffle()
			var count = mini(cells_shuffled.size(), 8)
			for i in range(count):
				var local_pos = decor_layer.map_to_local(cells_shuffled[i])
				var glob_pos = decor_layer.to_global(local_pos) + Vector2(randf_range(-10.0, 10.0), randf_range(-14.0, 6.0))
				if _pos_esta_dentro_da_sala(glob_pos, 20.0):
					posicoes.append(glob_pos)
					
	# 3. Reflexos ocasionais onde os feixes de sol atingem o piso
	if not _feixes_solares.is_empty():
		for f in _feixes_solares:
			if randf() < 0.65 and f.has("chao") and f["chao"] != null:
				var chao_spr = f["chao"] as Sprite2D
				if chao_spr and is_instance_valid(chao_spr):
					var p_ref = to_global(chao_spr.position) + Vector2(randf_range(-20.0, 20.0), randf_range(-10.0, 10.0))
					var f_cell = floor_layer.local_to_map(floor_layer.to_local(p_ref))
					if _celulas_chao_sala.has(f_cell) and _pos_esta_dentro_da_sala(p_ref, 20.0):
						posicoes.append(p_ref)
						
	for i in range(posicoes.size()):
		var pos = posicoes[i]
		var base_scale = randf_range(0.35, 0.65)
		var max_alpha = randf_range(0.65, 0.95) * (intensidade_reflexos / 0.85)
		var cycle_dur = randf_range(3.0, 7.5)
		var flash_dur = randf_range(0.9, 1.4)
		var rot = randf() * TAU
		
		var sprite = Sprite2D.new()
		sprite.name = "ReflexoVidro_" + str(i + 1)
		sprite.texture = tex_glint
		sprite.material = mat
		sprite.z_index = 6
		sprite.centered = true
		sprite.position = to_local(pos)
		sprite.rotation = rot
		sprite.scale = Vector2(base_scale, base_scale)
		sprite.modulate = Color(1.0, 0.96, 0.84, 0.0)
		container.add_child(sprite)
		
		_reflexos_vidro.append({
			"sprite": sprite,
			"timer": randf() * cycle_dur,
			"cycle_duration": cycle_dur,
			"flash_duration": flash_dur,
			"max_alpha": max_alpha,
			"base_scale": base_scale,
			"base_rot": rot,
			"rot_speed": randf_range(-0.5, 0.5)
		})

func _configurar_sombras_folhagens() -> void:
	var floor_layer = get_node_or_null("Floor") as TileMapLayer
	if not floor_layer:
		return
		
	_construir_geometria_sala()
	if _celulas_chao_sala.is_empty():
		return
		
	var container = Node2D.new()
	container.name = "SombrasFolhagens"
	add_child(container)
	
	var tex_sombra = _obter_textura_sombra_folhagem()
	var cells_keys = _celulas_chao_sala.keys()
	var num_sombras = clampi(int(float(cells_keys.size()) / 60.0), 3, 9)
	var step = maxi(1, int(cells_keys.size() / float(num_sombras + 1)))
	
	for i in range(num_sombras):
		var idx = (step * (i + 1) + randi() % maxi(1, step)) % cells_keys.size()
		var cell = cells_keys[idx]
		var w_pos = floor_layer.to_global(floor_layer.map_to_local(cell))
		var px = w_pos.x + randf_range(-15.0, 15.0)
		var py = w_pos.y + randf_range(-15.0, 15.0)
		var pos = Vector2(px, py)
		
		# Validação estrita: sombra suave de copa de árvore apenas em chão de estufa seguro
		if not _pos_esta_dentro_da_sala(pos, 36.0):
			continue
			
		var rot = randf() * TAU
		var sc = randf_range(1.5, 2.4)
		var base_alpha = randf_range(0.85, 1.15) * intensidade_sombras
		
		var sprite = Sprite2D.new()
		sprite.name = "SombraFolhagem_" + str(i + 1)
		sprite.texture = tex_sombra
		sprite.z_index = 1
		sprite.centered = true
		sprite.position = to_local(pos)
		sprite.rotation = rot
		sprite.scale = Vector2(sc, sc)
		sprite.modulate = Color(1.0, 1.0, 1.0, base_alpha)
		container.add_child(sprite)
		
		_sombras_folhagens.append({
			"sprite": sprite,
			"base_pos": sprite.position,
			"base_rot": rot,
			"base_scale": Vector2(sc, sc),
			"base_alpha": base_alpha,
			"speed_sway": randf_range(0.7, 1.3),
			"amp_x": randf_range(8.0, 16.0),
			"amp_y": randf_range(4.0, 8.0),
			"offset": randf() * 10.0
		})

# Atlas de decorações que ficam EM CIMA de móveis/prateleiras (não devem projetar sombra no chão)
const ATLAS_OBJETOS_SOBRE_MOVEIS = [
	Vector2i(88, 4), # Vaso / cilindro laranja sobre a mesa
	Vector2i(80, 4), # Vaso de flores sobre móvel
	Vector2i(96, 6), # Almofariz e frascos sobre a mesa
	Vector2i(95, 4), # Frasco sobre a mesa
	Vector2i(56, 6), # Tigela de sementes sobre prateleira
	Vector2i(64, 6), # Tigela sobre prateleira
	Vector2i(72, 6), # Frasco sobre prateleira
	Vector2i(51, 0), # Vigas e caixilhos da parede superior
	Vector2i(56, 0), # Pilar vertical de madeira da parede
]

# Item 4: Configura sombras das vigas e caixilhos da vidraça (claraboia da estufa) no chão
func _configurar_sombras_caixilhos() -> void:
	if not ativar_sombras_caixilhos:
		return
	var floor_layer = get_node_or_null("Floor") as TileMapLayer
	if not floor_layer:
		return
		
	var rect = floor_layer.get_used_rect()
	var min_w = floor_layer.to_global(floor_layer.map_to_local(rect.position))
	var max_w = floor_layer.to_global(floor_layer.map_to_local(rect.end))
	var room_w = abs(max_w.x - min_w.x)
	var room_h = abs(max_w.y - min_w.y)
	
	if room_w <= 0.0 or room_h <= 0.0:
		return
		
	var container = Node2D.new()
	container.name = "SombrasCaixilhos"
	container.z_index = 1 # Acima do piso, abaixo das sombras de móveis e entidades
	
	var floor_node = get_node_or_null("Floor")
	if floor_node:
		add_child(container)
		move_child(container, floor_node.get_index() + 1)
	else:
		add_child(container)
		
	var tex_caixilho = _obter_textura_sombra_caixilho()
	var angulo = 0.36 # Ângulo dos raios solares (~20.6°)
	var espacamento = 144.0 # Espaçamento entre os caixilhos (coincide com os módulos de janela da estufa)
	var total_largura = room_w + room_h * tan(angulo) + 200.0
	var num_caixilhos = clampi(int(total_largura / espacamento), 4, 30)
	
	var y_center = min_w.y + room_h * 0.5
	var target_h = (room_h + 300.0) / cos(angulo)
	var scale_y = target_h / 256.0
	var start_x = min_w.x - 120.0
	
	for i in range(num_caixilhos):
		var x_pos = start_x + float(i) * espacamento
		var spr = Sprite2D.new()
		spr.name = "Caixilho_" + str(i + 1)
		spr.texture = tex_caixilho
		spr.centered = true
		spr.position = to_local(Vector2(x_pos, y_center))
		spr.rotation = angulo
		spr.scale = Vector2(1.3, scale_y)
		spr.modulate = Color(1.0, 1.0, 1.0, intensidade_caixilhos)
		container.add_child(spr)

func _configurar_sombras_moveis() -> void:
	var decor_layer = get_node_or_null("Decoration") as TileMapLayer
	if not decor_layer or not decor_layer.tile_set:
		return
		
	var container = Node2D.new()
	container.name = "SombrasMoveis"
	container.z_index = 2 # Acima do piso (0) e da mancha de sol (1), garantindo oclusão solar sob os móveis
	
	# Garante que as sombras fiquem coladas no chão (após o Floor e mancha de sol, antes de entidades/decoração)
	var floor_node = get_node_or_null("Floor")
	if floor_node:
		add_child(container)
		move_child(container, floor_node.get_index() + 1)
	else:
		add_child(container)
	
	var tex_sombra_obj = _obter_textura_sombra_objeto()
	var tex_sombra_ret = _obter_textura_sombra_retangular()
	var scale_x = decor_layer.scale.x
	var scale_y = decor_layer.scale.y
	
	for cell in decor_layer.get_used_cells():
		var src_id = decor_layer.get_cell_source_id(cell)
		var atlas = decor_layer.get_cell_atlas_coords(cell)
		
		# Posição global e local exata do centro da célula no TileMapLayer
		var cell_world = decor_layer.to_global(decor_layer.map_to_local(cell))
		var local_pos = to_local(cell_world)
		
		# 1. Mesa Grande de Madeira (6x5 tiles = 96x80 px em atlas, 192x160 px na tela):
		# src 0: atlas (1, 3) (texture_origin = (8, 0))
		# src 1: atlas (1, 2) (texture_origin = (0, 0))
		if (src_id == 0 and atlas == Vector2i(1, 3)) or (src_id == 1 and atlas == Vector2i(1, 2)):
			var tex_orig_x = (8.0 * scale_x) if src_id == 0 else 0.0
			var table_cx = local_pos.x - tex_orig_x
			var table_cy = local_pos.y
			
			# A) Sombra ampla de oclusão sob o tampo (cobre exatamente o chão entre as 4 pernas da mesa):
			var spr_under = Sprite2D.new()
			spr_under.name = "SombraMesaOclusao_" + str(cell.x) + "_" + str(cell.y)
			spr_under.texture = tex_sombra_ret
			spr_under.centered = true
			spr_under.position = Vector2(table_cx, table_cy + 22.0 * scale_y)
			spr_under.scale = Vector2(170.0 / 128.0, 68.0 / 64.0)
			spr_under.modulate = Color(1.0, 1.0, 1.0, intensidade_sombras_moveis * 0.90)
			container.add_child(spr_under)
			
			# B) Sombra de contato nos pés da mesa (assenta a mesa firmemente na terra):
			var spr_feet = Sprite2D.new()
			spr_feet.name = "SombraMesaPes_" + str(cell.x) + "_" + str(cell.y)
			spr_feet.texture = tex_sombra_obj
			spr_feet.centered = true
			spr_feet.position = Vector2(table_cx, table_cy + 37.0 * scale_y)
			spr_feet.scale = Vector2(165.0 / 64.0, 20.0 / 32.0)
			spr_feet.modulate = Color(1.0, 1.0, 1.0, intensidade_sombras_moveis * 0.95)
			container.add_child(spr_feet)
			
		# 2. Estante de Livros / Prateleira Alta de Madeira (7x8 tiles = 112x128 px em atlas, 224x256 px na tela):
		# atlas (24, 0) e (32, 0) - texture_origin = (0, 8)
		elif atlas == Vector2i(24, 0) or atlas == Vector2i(32, 0):
			var tex_orig_y = (8.0 * scale_y) if src_id == 0 else 0.0
			var shelf_cx = local_pos.x
			var shelf_base_y = local_pos.y - tex_orig_y + (64.0 * scale_y)
			
			# Sombra na base da estante e piso logo à frente:
			var spr = Sprite2D.new()
			spr.name = "SombraEstante_" + str(cell.x) + "_" + str(cell.y)
			spr.texture = tex_sombra_ret
			spr.centered = true
			spr.position = Vector2(shelf_cx, shelf_base_y)
			spr.scale = Vector2(210.0 / 128.0, 36.0 / 64.0)
			spr.modulate = Color(1.0, 1.0, 1.0, intensidade_sombras_moveis * 0.95)
			container.add_child(spr)
			
		# 3. Prateleira / Suporte de Madeira de Parede (src 1: atlas (14, 3) 2x4 tiles = 64 px de largura):
		# Sombra colada na base da estrutura de madeira da prateleira na parede
		elif src_id == 1 and atlas == Vector2i(14, 3):
			var spr = Sprite2D.new()
			spr.name = "SombraMadeiraPrateleira_" + str(cell.x) + "_" + str(cell.y)
			spr.texture = tex_sombra_ret
			spr.centered = true
			spr.position = Vector2(local_pos.x, local_pos.y + 21.0 * scale_y)
			spr.scale = Vector2(64.0 / 128.0, 24.0 / 64.0)
			spr.modulate = Color(1.0, 1.0, 1.0, intensidade_sombras_moveis * 0.90)
			container.add_child(spr)
			
		# Mesa / Bancada Lateral de Madeira da Parede (src 0: atlas (13, 2) 3x5 tiles = 66 px de largura):
		# Sombra da base de madeira assentada contra a parede/chão
		elif src_id == 0 and atlas == Vector2i(13, 2):
			var spr = Sprite2D.new()
			spr.name = "SombraMadeiraMesa_" + str(cell.x) + "_" + str(cell.y)
			spr.texture = tex_sombra_ret
			spr.centered = true
			spr.position = Vector2(local_pos.x + 14.0, local_pos.y + 27.0 * scale_y)
			spr.scale = Vector2(66.0 / 128.0, 24.0 / 64.0)
			spr.modulate = Color(1.0, 1.0, 1.0, intensidade_sombras_moveis * 0.90)
			container.add_child(spr)
			
		# 4. Banco Baixo / Prateleira Horizontal de Madeira (atlas (17, 0) - 6x2 tiles, texture_origin=(8, 8)):
		elif atlas == Vector2i(17, 0):
			var tex_orig_x = (8.0 * scale_x) if src_id == 0 else 0.0
			var tex_orig_y = (8.0 * scale_y) if src_id == 0 else 0.0
			var bench_cx = local_pos.x - tex_orig_x
			var bench_cy = local_pos.y - tex_orig_y
			var spr = Sprite2D.new()
			spr.name = "SombraMadeiraBanco_" + str(cell.x) + "_" + str(cell.y)
			spr.texture = tex_sombra_ret
			spr.centered = true
			spr.position = Vector2(bench_cx, bench_cy + 16.0 * scale_y)
			spr.scale = Vector2(160.0 / 128.0, 22.0 / 64.0)
			spr.modulate = Color(1.0, 1.0, 1.0, intensidade_sombras_moveis * 0.85)
			container.add_child(spr)

# Item 5: Sombra suave de contato na raiz/base dos inimigos botânicos (Mago já possui sombra própria)
func _configurar_sombras_inimigos() -> void:
	if not ativar_sombras_inimigos:
		return
		
	var tex_sombra = _obter_textura_sombra_objeto()
	
	# Busca todos os inimigos da sala
	var inimigos_encontrados: Array = []
	for node in get_tree().get_nodes_in_group("inimigos"):
		if is_ancestor_of(node) and is_instance_valid(node) and not node.is_queued_for_deletion():
			inimigos_encontrados.append(node)
			
	if inimigos_encontrados.is_empty():
		for child in get_children():
			if child is CharacterBody2D and not child.is_in_group("player") and child.name != "Player" and not child.name.begins_with("Player"):
				inimigos_encontrados.append(child)
				
	for inimigo in inimigos_encontrados:
		if not is_instance_valid(inimigo) or inimigo.is_queued_for_deletion() or inimigo.has_node("SombraPlanta"):
			continue
			
		var nome_low = inimigo.name.to_lower()
		var eh_cogumelo = "cogumelo" in nome_low
		var eh_boss = "boss" in nome_low or "carnivora" in nome_low or inimigo.get("eh_boss") == true
		
		var spr_e = Sprite2D.new()
		spr_e.name = "SombraPlanta"
		spr_e.texture = tex_sombra
		spr_e.centered = true
		spr_e.z_index = -1 # No chão, atrás do sprite da planta
		
		if eh_boss:
			# Chefe (Planta Carnívora Grande): sombra de raiz ampla na terra
			spr_e.position = Vector2(8.0, 26.0)
			spr_e.scale = Vector2(1.30, 0.50)
			spr_e.modulate = Color(1.0, 1.0, 1.0, intensidade_sombras_inimigos * 1.1)
		elif eh_cogumelo:
			# Cogumelinho que anda pelo chão: sombra na base dos pezinhos
			spr_e.position = Vector2(2.0, 20.0)
			spr_e.scale = Vector2(0.65, 0.28)
			spr_e.modulate = Color(1.0, 1.0, 1.0, intensidade_sombras_inimigos * 0.95)
		else:
			# Plantas com caule/raiz fixadas no chão (Flor Amarela, Roxa, Vermelha):
			# Sombra de raiz rente ao solo com leve projeção solar para a direita
			spr_e.position = Vector2(5.0, 16.0)
			spr_e.scale = Vector2(0.58, 0.22)
			spr_e.modulate = Color(1.0, 1.0, 1.0, intensidade_sombras_inimigos)
			
		inimigo.add_child(spr_e)

# Item 5: Configura bioluminescência orgânica em flores raras, inimigos e cenário
func _configurar_bioluminescencia() -> void:
	if not ativar_bioluminescencia:
		return
		
	# 1. Flores Raras na sala
	for child in get_children():
		if child.name.begins_with("ItemFlorRara"):
			var cor = "amarela"
			if "tipo_cor" in child:
				cor = child.tipo_cor
			_adicionar_luz_flor_rara(child, cor)
			
	# 2. Inimigos Botânicos
	_configurar_bioluminescencia_inimigos()
	
	# 3. Decorações e Frascos de Cristal
	_configurar_props_biologia()

func _adicionar_luz_flor_rara(flor: Node, cor_nome: String) -> void:
	if not flor or not is_instance_valid(flor) or flor.has_node("LuzFlorRara"):
		return
		
	var cor_luz = Color(1.0, 0.88, 0.32, 1.0)
	match cor_nome:
		"azul":
			cor_luz = Color(0.35, 0.75, 1.0, 1.0)
		"roxa":
			cor_luz = Color(0.85, 0.40, 1.0, 1.0)
		"laranja":
			cor_luz = Color(1.0, 0.58, 0.20, 1.0)
		"vermelha":
			cor_luz = Color(1.0, 0.30, 0.38, 1.0)
		_:
			cor_luz = Color(1.0, 0.88, 0.32, 1.0)
			
	var tex_luz = _obter_textura_luz_bioluminescente()
	var luz = PointLight2D.new()
	luz.name = "LuzFlorRara"
	luz.texture = tex_luz
	luz.color = cor_luz
	var base_en = intensidade_bioluminescencia * 0.75
	luz.energy = base_en
	luz.texture_scale = 0.75
	luz.position = Vector2(0.0, -6.0)
	flor.add_child(luz)
	
	_luzes_bioluminescentes.append({
		"node": luz,
		"base_energy": base_en,
		"speed": 2.8,
		"offset": randf() * 6.0
	})
	
	# Partículas sutis de brilho mágico subindo suavemente da flor rara
	if not flor.has_node("BrilhoFlorRara"):
		var part = CPUParticles2D.new()
		part.name = "BrilhoFlorRara"
		part.amount = 4
		part.lifetime = 1.2
		part.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		part.emission_sphere_radius = 8.0
		part.gravity = Vector2(0.0, -14.0)
		part.initial_velocity_min = 4.0
		part.initial_velocity_max = 10.0
		part.scale_amount_min = 1.0
		part.scale_amount_max = 1.8
		part.color = Color(cor_luz.r, cor_luz.g, cor_luz.b, 0.75)
		var mat = CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		part.material = mat
		flor.add_child(part)

func _configurar_bioluminescencia_inimigos() -> void:
	var tex_luz = _obter_textura_luz_bioluminescente()
	
	var inimigos = get_tree().get_nodes_in_group("inimigos")
	var lista_inimigos: Array = []
	for n in inimigos:
		if is_ancestor_of(n) and is_instance_valid(n) and not n.is_queued_for_deletion():
			lista_inimigos.append(n)
			
	if lista_inimigos.is_empty():
		for child in get_children():
			if child is CharacterBody2D and not child.is_in_group("player") and child.name != "Player" and not child.name.begins_with("Player"):
				lista_inimigos.append(child)
				
	for inimigo in lista_inimigos:
		if not is_instance_valid(inimigo) or inimigo.is_queued_for_deletion():
			continue
		if inimigo.has_node("LuzBioInimigo"):
			continue
			
		var nome_low = inimigo.name.to_lower()
		var eh_boss = "boss" in nome_low or "carnivora" in nome_low or inimigo.get("eh_boss") == true
		
		var cor_inimigo = Color(1.0, 0.88, 0.32, 1.0) # Tier 1 Flor Amarela padrão
		var scale_luz = 0.65
		var base_en = intensidade_bioluminescencia * 0.70
		
		var tier = 1
		var trigger = inimigo.get_node_or_null("EnemyTrigger")
		if trigger and "nivel_dificuldade" in trigger:
			tier = trigger.nivel_dificuldade
			
		if eh_boss:
			cor_inimigo = Color(0.92, 0.98, 0.28, 1.0) # Predador Botânico / Carnívora
			scale_luz = 1.20
			base_en = intensidade_bioluminescencia * 0.95
		elif tier == 2 or "roxa" in nome_low:
			cor_inimigo = Color(0.85, 0.40, 1.0, 1.0) # Flor Roxa
			scale_luz = 0.70
			base_en = intensidade_bioluminescencia * 0.75
		elif tier == 3 or "vermelha" in nome_low:
			cor_inimigo = Color(1.0, 0.30, 0.38, 1.0) # Flor Vermelha
			scale_luz = 0.75
			base_en = intensidade_bioluminescencia * 0.80
			
		var luz_ini = PointLight2D.new()
		luz_ini.name = "LuzBioInimigo"
		luz_ini.texture = tex_luz
		luz_ini.color = cor_inimigo
		luz_ini.energy = base_en
		luz_ini.texture_scale = scale_luz
		luz_ini.position = Vector2(0.0, -14.0)
		inimigo.add_child(luz_ini)
		
		_luzes_bioluminescentes.append({
			"node": luz_ini,
			"base_energy": base_en,
			"speed": 3.2,
			"offset": randf() * 6.0
		})

func _configurar_props_biologia() -> void:
	var decor = get_node_or_null("Decoration") as TileMapLayer
	if not decor or not decor.tile_set:
		return
		
	var tex_luz = _obter_textura_luz_bioluminescente()
	var scale_decor = decor.scale
	
	for cell in decor.get_used_cells():
		var atlas = decor.get_cell_atlas_coords(cell)
		var src_id = decor.get_cell_source_id(cell)
		var cell_world = decor.to_global(decor.map_to_local(cell))
		var cell_id = str(cell.x) + "_" + str(cell.y)
		
		var src = decor.tile_set.get_source(src_id) as TileSetAtlasSource if decor.tile_set else null
		var tex_name = src.texture.resource_path.get_file().to_lower() if (src and src.texture) else ""
		var eh_biologia_tex = "biologia" in tex_name or src_id == 1
		
		# 1. Frasco com Cristal Azul Arcano (Ciano idêntico ao Hub e Sala de Química: Color(0.18, 0.88, 1.0))
		if not eh_biologia_tex and atlas == Vector2i(88, 4):
			if not get_node_or_null("LuzFrascoCristal_" + cell_id):
				# Posicionamento no topo do frasco, logo abaixo da tampa de cortiça (idêntico ao Hub)
				var pos_jar = to_local(cell_world + Vector2(-13.0, -34.0))
				
				var luz = PointLight2D.new()
				luz.name = "LuzFrascoCristal_" + cell_id
				luz.texture = tex_luz
				luz.color = Color(0.18, 0.88, 1.0, 1.0)
				var base_en = 0.40
				luz.energy = base_en
				luz.texture_scale = 0.65
				luz.position = pos_jar
				add_child(luz)
				
				_luzes_bioluminescentes.append({
					"node": luz,
					"base_energy": base_en,
					"speed": 2.2,
					"offset": randf() * 5.0
				})
				
		# 2. Frasco com Planta/Espécime Verde (Verde idêntico ao Hub e Sala de Química: Color(0.20, 0.98, 0.45))
		elif (not eh_biologia_tex and atlas == Vector2i(80, 4)) or (eh_biologia_tex and (atlas == Vector2i(88, 4) or atlas == Vector2i(95, 4))):
			if not get_node_or_null("LuzFrascoPlanta_" + cell_id):
				# Posicionamento no topo do frasco, logo abaixo da tampa (idêntico ao Hub)
				var offset_world = Vector2(-7.0, -6.0)
				if eh_biologia_tex:
					if atlas == Vector2i(95, 4):
						offset_world = Vector2(8.5, 0.0)
					else:
						offset_world = Vector2(-3.5, 0.0)
						
				var pos_jar = to_local(cell_world + offset_world)
				
				var luz = PointLight2D.new()
				luz.name = "LuzFrascoPlanta_" + cell_id
				luz.texture = tex_luz
				luz.color = Color(0.20, 0.98, 0.45, 1.0)
				var base_en = 0.40
				luz.energy = base_en
				luz.texture_scale = 0.65
				luz.position = pos_jar
				add_child(luz)
				
				_luzes_bioluminescentes.append({
					"node": luz,
					"base_energy": base_en,
					"speed": 1.7,
					"offset": randf() * 5.0
				})
				
		# 3. Caldeirão Botânico de Alquimia (atlas (112, 4) ou (112, 5))
		elif (atlas == Vector2i(112, 4) or atlas == Vector2i(112, 5)) and not get_node_or_null("LuzCaldeirao_" + cell_id):
			var offset_cald = Vector2(12.0 * scale_decor.x, 16.0 * scale_decor.y)
			if atlas == Vector2i(112, 4):
				offset_cald = Vector2(24.0 * scale_decor.x, 24.0 * scale_decor.y)
				
			var pos_cald = to_local(cell_world + offset_cald)
			var luz = PointLight2D.new()
			luz.name = "LuzCaldeirao_" + cell_id
			luz.texture = tex_luz
			luz.color = Color(0.40, 0.95, 0.45, 1.0) # Verde botânico alquímico
			var base_en = intensidade_bioluminescencia * 0.65
			luz.energy = base_en
			luz.texture_scale = 0.55
			luz.position = pos_cald
			add_child(luz)
			_luzes_bioluminescentes.append({
				"node": luz,
				"base_energy": base_en,
				"speed": 2.5,
				"offset": randf() * 4.0
			})

# Item 4: Poeira Solar e Grãos de Pólen Flutuantes na Estufa
func _configurar_polen_solar() -> void:
	if not ativar_polen_solar or get_node_or_null("PolenSolarEstufa"):
		return
		
	var floor_layer = get_node_or_null("Floor") as TileMapLayer
	if not floor_layer:
		return
		
	_construir_geometria_sala()
	if _celulas_chao_sala.is_empty():
		return
		
	var pontos: PackedVector2Array = []
	var cells_keys = _celulas_chao_sala.keys()
	var step = maxi(1, int(float(cells_keys.size()) / 150.0))
	for idx in range(0, cells_keys.size(), step):
		var cell = cells_keys[idx]
		var w_pos = floor_layer.to_global(floor_layer.map_to_local(cell))
		pontos.append(to_local(w_pos + Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0))))
		
	if pontos.is_empty():
		return
		
	var part = CPUParticles2D.new()
	part.name = "PolenSolarEstufa"
	part.z_index = 8
	part.position = Vector2.ZERO
	part.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINTS
	part.emission_points = pontos
	
	part.amount = 26
	part.lifetime = 7.0
	part.preprocess = 3.5
	part.speed_scale = 0.8
	
	part.direction = Vector2(0.6, 0.3)
	part.spread = 45.0
	part.gravity = Vector2(-2.0, 4.0)
	part.initial_velocity_min = 6.0
	part.initial_velocity_max = 18.0
	
	part.scale_amount_min = 1.0
	part.scale_amount_max = 2.5
	
	var mat = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	part.material = mat
	
	var grad = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.25, 0.75, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 0.95, 0.65, 0.0),
		Color(1.0, 0.95, 0.65, 0.40),
		Color(1.0, 0.90, 0.55, 0.35),
		Color(1.0, 0.85, 0.45, 0.0)
	])
	part.color_ramp = grad
	
	add_child(part)

func _process(delta: float) -> void:
	if _feixes_solares.is_empty() and _reflexos_vidro.is_empty() and _sombras_folhagens.is_empty() and _luzes_bioluminescentes.is_empty():
		return
		
	_tempo_iluminacao_tick += delta
	if _tempo_iluminacao_tick < 0.033:
		return
	var dt = _tempo_iluminacao_tick
	_tempo_iluminacao_tick = 0.0
	_tempo_animacao_solar += dt
	
	# Atualiza Feixes Solares (Item 1)
	for feixe in _feixes_solares:
		var t = _tempo_animacao_solar + feixe["offset"]
		var shimmer = sin(t * feixe["speed_shimmer"]) * 0.15 + sin(t * (feixe["speed_shimmer"] * 1.6)) * 0.07
		var alpha = clampf(feixe["base_alpha"] * (1.0 + shimmer), 0.05, 0.50)
		
		var s_feixe = feixe["feixe"]
		if s_feixe and is_instance_valid(s_feixe):
			s_feixe.modulate.a = alpha
			var drift = sin(t * feixe["speed_drift"]) * 0.015
			s_feixe.rotation = feixe["base_rot"] + drift
			
		var s_chao = feixe["chao"]
		if s_chao and is_instance_valid(s_chao):
			s_chao.modulate.a = alpha * 0.70
			
	# Atualiza Reflexos Solares nos Vidros e Espelhos (Item 2)
	for reflexo in _reflexos_vidro:
		reflexo["timer"] += dt
		if reflexo["timer"] >= reflexo["cycle_duration"]:
			reflexo["timer"] = 0.0
			reflexo["cycle_duration"] = randf_range(3.0, 7.5)
			
		var t_ref = reflexo["timer"]
		var flash_dur = reflexo["flash_duration"]
		var sprite = reflexo["sprite"]
		if not sprite or not is_instance_valid(sprite):
			continue
			
		if t_ref < flash_dur:
			var prog = t_ref / flash_dur
			var curve = sin(prog * PI)
			var a = curve * reflexo["max_alpha"]
			var s = reflexo["base_scale"] * (0.65 + curve * 0.45)
			sprite.modulate.a = a
			sprite.scale = Vector2(s, s)
			sprite.rotation = reflexo["base_rot"] + prog * reflexo["rot_speed"]
		else:
			sprite.modulate.a = 0.0
			
	# Atualiza Sombras de Folhagens Balançando ao Vento (Item 3)
	for sombra in _sombras_folhagens:
		var spr = sombra["sprite"]
		if not spr or not is_instance_valid(spr):
			continue
		var t_s = _tempo_animacao_solar * sombra["speed_sway"] + sombra["offset"]
		var sway_x = sin(t_s) * sombra["amp_x"] + cos(t_s * 0.5) * (sombra["amp_x"] * 0.4)
		var sway_y = cos(t_s * 0.8) * sombra["amp_y"]
		spr.position = sombra["base_pos"] + Vector2(sway_x, sway_y)
		spr.rotation = sombra["base_rot"] + sin(t_s * 0.7) * 0.05
		var s_factor = 1.0 + sin(t_s * 1.1) * 0.03
		spr.scale = sombra["base_scale"] * s_factor

	# Atualiza Bioluminescência Orgânica das Flores, Inimigos e Cenário (Item 5)
	for i in range(_luzes_bioluminescentes.size() - 1, -1, -1):
		var item = _luzes_bioluminescentes[i]
		var node = item.get("node")
		if not node or not is_instance_valid(node) or node.is_queued_for_deletion():
			_luzes_bioluminescentes.remove_at(i)
			continue
		var t_bio = _tempo_animacao_solar * item["speed"] + item["offset"]
		var pulse = sin(t_bio) * 0.18 + sin(t_bio * 2.3) * 0.06
		node.energy = clampf(item["base_energy"] * (1.0 + pulse), 0.05, 1.5)
		var spr = item.get("sprite")
		if spr and is_instance_valid(spr) and not spr.is_queued_for_deletion():
			var base_a = item.get("base_alpha", 0.52)
			spr.modulate.a = clampf(base_a * (1.0 + pulse * 0.4), 0.15, 0.85)

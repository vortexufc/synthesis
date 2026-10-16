extends Node2D

# script base das salas de biologia (Estufa)

var monstros_na_sala: int = 0
var total_monstros_inicial: int = 0
var _chave_dropada: bool = false

@export_group("Recompensas")
# ativa o drop de chave ao derrotar o ultimo monstro da sala
@export var dropar_chave_no_ultimo_monstro: bool = false

const POSICOES_FLORES = {
	"Sala_Biologia01": {"pos": Vector2(176, 720), "cor": "amarela"},
	"Sala_Biologia02": {"pos": Vector2(944, 784), "cor": "azul"},
	"Sala_Biologia03": {"pos": Vector2(3120, 848), "cor": "roxa"},
	"Sala_Biologia04": {"pos": Vector2(1168, 560), "cor": "laranja"},
	"Sala_Biologia05": {"pos": Vector2(2096, 816), "cor": "vermelha"},
	"Sala_Biologia06": {"pos": Vector2(2160, 1520), "cor": "amarela"},
	"Sala_Biologia07": {"pos": Vector2(624, 976), "cor": "azul"},
	"Sala_Biologia08": {"pos": Vector2(2768, 2288), "cor": "roxa"},
	"Sala_Biologia09": {"pos": Vector2(1488, 880), "cor": "laranja"},
	"Sala_Biologia10": {"pos": Vector2(1168, 752), "cor": "vermelha"},
	"Sala_Biologia11": {"pos": Vector2(1360, 976), "cor": "azul"},
	"Sala_BossBiologia": {"pos": Vector2(240, 720), "cor": "amarela"},
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
	if get_node_or_null("/root/DungeonGenerator"):
		eh_boss = eh_boss or DungeonGenerator.is_sala_boss(scene_file_path)
	
	if not eh_boss and get_node_or_null("/root/DungeonGenerator"):
		var tier = DungeonGenerator.get_tier_da_sala(scene_file_path)
		if tier > 0:
			_configurar_tier_dos_inimigos(tier)
	
	_iniciar_sistema_inimigos_e_portas()
	_spawn_flor_rara_se_necessario()

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
		inimigo.vida_atual = stats.get("vida_maxima", inimigo.vida_maxima)
		
		# Atualiza EnemyTrigger
		var trigger = inimigo.get_node_or_null("EnemyTrigger")
		if trigger:
			if "id_inimigo" in trigger:
				trigger.id_inimigo = enemy_id
			if "nivel_dificuldade" in trigger:
				trigger.nivel_dificuldade = tier
			if "andar_id" in trigger:
				trigger.andar_id = 3

func _is_posicao_valida(pos: Vector2, floor_node: TileMapLayer, wall_node: TileMapLayer) -> bool:
	if not floor_node:
		return true
	var cell = floor_node.local_to_map(floor_node.to_local(pos))
	if not _is_celula_coberta(cell, floor_node):
		return false
	if wall_node and _is_celula_coberta(cell, wall_node):
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

func _encontrar_posicao_chao_segura(pos_desejada: Vector2, floor_node: TileMapLayer, wall_node: TileMapLayer) -> Vector2:
	if not floor_node:
		return pos_desejada
	var cells = floor_node.get_used_cells()
	if cells.is_empty():
		return pos_desejada
		
	var melhor_pos = Vector2.ZERO
	var menor_dist = 9999999.0
	
	for cell in cells:
		var source_id = floor_node.get_cell_source_id(cell)
		var atlas_coords = floor_node.get_cell_atlas_coords(cell)
		var source = floor_node.tile_set.get_source(source_id) as TileSetAtlasSource if floor_node.tile_set else null
		var size = source.get_tile_size_in_atlas(atlas_coords) if (source and source.has_tile(atlas_coords)) else Vector2i(1, 1)
		
		var passos_x = [0] if size.x <= 1 else [0, int(size.x / 2), size.x - 1]
		var passos_y = [0] if size.y <= 1 else [0, int(size.y / 2), size.y - 1]
		
		for px in passos_x:
			for py in passos_y:
				var sub_cell = cell + Vector2i(px, py)
				if wall_node and _is_celula_coberta(sub_cell, wall_node):
					continue
				var wpos = floor_node.to_global(floor_node.map_to_local(sub_cell))
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
	
	# Validação de segurança: se a posição não estiver em uma célula de chão válida ou colidir com parede, ajusta automaticamente
	var floor_node = get_node_or_null("Floor") as TileMapLayer
	var wall_node = get_node_or_null("Wall") as TileMapLayer
	if floor_node:
		if not _is_posicao_valida(to_global(target_pos), floor_node, wall_node):
			target_pos = to_local(_encontrar_posicao_chao_segura(to_global(target_pos), floor_node, wall_node))
			
	var flor_inst = cena_flor.instantiate()
	flor_inst.name = "ItemFlorRara"
	flor_inst.id_unico = item_id
	if "tipo_cor" in flor_inst:
		flor_inst.tipo_cor = info["cor"]
	flor_inst.position = target_pos
	add_child(flor_inst)

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

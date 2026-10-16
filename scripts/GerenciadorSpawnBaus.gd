extends Node2D
class_name GerenciadorSpawnBaus

# sorteia onde os baus e mimicos vao nascer na sala

@export_group("Regras de Spawn")
@export_range(1, 5) var qtd_baus_reais: int = 1
@export_range(0.0, 1.0, 0.05) var chance_mimico: float = 0.40
@export var dano_mimico_custom: float = 35.0

@export_group("Cenas dos Objetos")
@export var cena_bau: PackedScene = preload("res://scenes/Objetos/bau1.tscn")
@export var cena_mimico: PackedScene = preload("res://scenes/Objetos/mimico.tscn")

@export_group("Configuração do Baú Real")
@export_enum("Desafio da Memória Arcana", "Pergaminho de Dicas") var modo_conteudo: int = 0
@export_enum("Automático", "Química", "Física", "Biologia") var forcar_andar: int = 0
@export var recompensa_moedas: int = 30
@export var recompensa_pocao: String = "Poção de Cura"

func _ready() -> void:
	if Engine.is_editor_hint():
		return
		
	_limpar_residuos()
	call_deferred("_executar_spawn_aleatorio")

func _limpar_residuos() -> void:
	for child in get_children():
		for sub in child.get_children():
			if sub.name.begins_with("Preview"):
				sub.queue_free()

func _obter_spawner_id() -> String:
	var cena_path = ""
	if get_tree() and get_tree().current_scene:
		cena_path = get_tree().current_scene.scene_file_path
	return "%s::%s" % [cena_path, name]

func _executar_spawn_aleatorio() -> void:
	_limpar_residuos()
	
	# pega todos os pontos marcados na sala mapeados por nome
	var pontos_map: Dictionary = {}
	
	for child in get_children():
		if (child is Marker2D or child is Node2D) and not child.name.begins_with("Preview"):
			pontos_map[child.name] = child
			
	if pontos_map.size() == 0 and get_tree():
		var grupo = get_tree().get_nodes_in_group("pontos_bau")
		for p in grupo:
			if p is Node2D and not p.name in pontos_map:
				pontos_map[p.name] = p
			
	if pontos_map.size() == 0:
		push_warning("[GerenciadorSpawnBaus] Nenhum ponto de spawn encontrado para %s!" % name)
		return
		
	var spawner_id = _obter_spawner_id()
	var nomes_pontos_baus: Array = []
	var nome_ponto_mimico: String = ""

	var dados_salvos: Dictionary = {}
	if get_node_or_null("/root/PlayerStats"):
		dados_salvos = PlayerStats.get_bau_spawnado(spawner_id)

	if dados_salvos.size() > 0 and dados_salvos.has("pontos_baus"):
		# Reutiliza o sorteio ja persistido para manter consistencia
		nomes_pontos_baus = dados_salvos.get("pontos_baus", [])
		nome_ponto_mimico = dados_salvos.get("ponto_mimico", "")
	else:
		randomize()
		var lista_chaves = pontos_map.keys()
		lista_chaves.shuffle()
		
		var total_reais = min(qtd_baus_reais, lista_chaves.size())
		for i in range(total_reais):
			nomes_pontos_baus.append(lista_chaves[i])
			
		var chaves_restantes: Array = []
		for k in lista_chaves:
			if not (k in nomes_pontos_baus):
				chaves_restantes.append(k)
				
		if chaves_restantes.size() > 0 and randf() < chance_mimico:
			nome_ponto_mimico = chaves_restantes.pick_random()
			
		if get_node_or_null("/root/PlayerStats"):
			PlayerStats.registrar_bau_spawnado(spawner_id, {
				"pontos_baus": nomes_pontos_baus,
				"ponto_mimico": nome_ponto_mimico
			})

	var pai = get_parent()
	if pai == null:
		pai = self
		
	# instancia os baus reais
	for nome_ponto in nomes_pontos_baus:
		if not pontos_map.has(nome_ponto):
			continue
		var ponto = pontos_map[nome_ponto]
		if cena_bau != null:
			var bau_id = "%s::%s" % [spawner_id, nome_ponto]
			
			var ja_aberto_anteriormente = false
			if get_node_or_null("/root/PlayerStats"):
				ja_aberto_anteriormente = PlayerStats.is_bau_aberto(bau_id) or PlayerStats.is_item_coletado(bau_id) or PlayerStats.is_bau_aberto(spawner_id)
				
			if ja_aberto_anteriormente:
				# Se já foi pego/aberto, NÃO aparece na sala!
				continue

			var bau_inst = cena_bau.instantiate()
			bau_inst.id_unico = bau_id
			
			var pos_bau = ponto.global_position
			var floor_node = pai.get_node_or_null("Floor") as TileMapLayer
			if not floor_node and get_tree() and get_tree().current_scene:
				floor_node = get_tree().current_scene.get_node_or_null("Floor") as TileMapLayer
			var wall_node = pai.get_node_or_null("Wall") as TileMapLayer
			if not wall_node and get_tree() and get_tree().current_scene:
				wall_node = get_tree().current_scene.get_node_or_null("Wall") as TileMapLayer
				
			if "modo_conteudo" in bau_inst:
				bau_inst.modo_conteudo = modo_conteudo
			if "forcar_andar" in bau_inst:
				bau_inst.forcar_andar = forcar_andar
			if "recompensa_moedas" in bau_inst:
				bau_inst.recompensa_moedas = recompensa_moedas
			if "recompensa_pocao" in bau_inst:
				bau_inst.recompensa_pocao = recompensa_pocao
				
			pai.add_child(bau_inst)
			
			if floor_node:
				if not _is_posicao_valida(pos_bau, floor_node, wall_node):
					pos_bau = _encontrar_posicao_chao_segura(pos_bau, floor_node, wall_node)
			bau_inst.global_position = pos_bau
			
	# verifica se todos os baus desta sala ja foram abertos
	var todos_abertos = true
	for nome_ponto in nomes_pontos_baus:
		var b_id = "%s::%s" % [spawner_id, nome_ponto]
		if get_node_or_null("/root/PlayerStats") and not PlayerStats.is_bau_aberto(b_id) and not PlayerStats.is_item_coletado(b_id) and not PlayerStats.is_bau_aberto(spawner_id):
			todos_abertos = false
			break

	# instancia o mimico apenas se os baus ainda nao foram abertos e o mimico nao foi ativado
	if nome_ponto_mimico != "" and pontos_map.has(nome_ponto_mimico) and cena_mimico != null and not todos_abertos:
		var mimico_id = "%s::mimico_%s" % [spawner_id, nome_ponto_mimico]
		var ja_ativado = false
		if get_node_or_null("/root/PlayerStats"):
			ja_ativado = PlayerStats.is_item_coletado(mimico_id) or PlayerStats.is_bau_aberto(mimico_id)
			
		if not ja_ativado:
			var ponto_mimico = pontos_map[nome_ponto_mimico]
			var mimico_inst = cena_mimico.instantiate()
			
			if "id_unico" in mimico_inst:
				mimico_inst.id_unico = mimico_id
			if dano_mimico_custom > 0 and "dano" in mimico_inst:
				mimico_inst.dano = dano_mimico_custom
			pai.add_child(mimico_inst)
			
			var pos_mimico = ponto_mimico.global_position
			var f_node = pai.get_node_or_null("Floor") as TileMapLayer
			if not f_node and get_tree() and get_tree().current_scene:
				f_node = get_tree().current_scene.get_node_or_null("Floor") as TileMapLayer
			var w_node = pai.get_node_or_null("Wall") as TileMapLayer
			if not w_node and get_tree() and get_tree().current_scene:
				w_node = get_tree().current_scene.get_node_or_null("Wall") as TileMapLayer
				
			if f_node:
				if not _is_posicao_valida(pos_mimico, f_node, w_node):
					pos_mimico = _encontrar_posicao_chao_segura(pos_mimico, f_node, w_node)
			mimico_inst.global_position = pos_mimico

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


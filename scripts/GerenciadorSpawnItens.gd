@tool
extends Node2D
class_name GerenciadorSpawnItens

# gerencia o spawn dos itens na sala com chance configuravel

enum TipoItem {
	PERGAMINHO = 0,
	LIVRO_QUIMICA = 1,
	BATERIA_FISICA = 2,
	CHIP_FISICA = 3,
	MOEDA = 4,
	CHAVE = 5,
	POCAO = 6,
	ARMADILHA_POCAO = 7,
	CUSTOMIZADO = 8,
	FLOR_BIOLOGIA = 9,
	CHIP_DNA = 10
}

@export_group("Tipo do Item")
@export var tipo_item: TipoItem = TipoItem.LIVRO_QUIMICA:
	set(valor):
		tipo_item = valor
		if Engine.is_editor_hint():
			for child in get_children():
				if child is CanvasItem:
					child.queue_redraw()

@export var cena_customizada: PackedScene = null

@export_group("Regras de Spawn")
@export_range(0.05, 1.0, 0.05) var chance_spawn: float = 0.50
@export var garantir_ao_menos_um: bool = true

# caminhos das cenas dos itens
const CENAS_PADRAO = {
	TipoItem.PERGAMINHO: "res://scenes/Objetos/pergaminho.tscn",
	TipoItem.LIVRO_QUIMICA: "res://scenes/Entidades/Items/ItemLivroFormula.tscn",
	TipoItem.BATERIA_FISICA: "res://scenes/Entidades/Items/ItemBateria.tscn",
	TipoItem.CHIP_FISICA: "res://scenes/Entidades/Items/ItemChip.tscn",
	TipoItem.MOEDA: "res://scenes/Entidades/Items/ItemMoeda.tscn",
	TipoItem.CHAVE: "res://scenes/Entidades/Items/ItemChave.tscn",
	TipoItem.POCAO: "res://scenes/Entidades/Items/ItemPocao.tscn",
	TipoItem.ARMADILHA_POCAO: "res://scenes/Armadilhas/frasco_instavel.tscn",
	TipoItem.FLOR_BIOLOGIA: "res://scenes/Entidades/Items/ItemFlorRara.tscn",
	TipoItem.CHIP_DNA: "res://scenes/Entidades/Items/ItemChipDNA.tscn"
}

func _ready() -> void:
	if Engine.is_editor_hint():
		return
		
	call_deferred("_executar_spawn")

func _obter_spawner_id() -> String:
	var cena_path = ""
	if get_tree() and get_tree().current_scene:
		cena_path = get_tree().current_scene.scene_file_path
	return "%s::%s" % [cena_path, name]

func _executar_spawn() -> void:
	# pega a cena certa pro tipo selecionado
	var cena_para_instanciar: PackedScene = null
	if tipo_item == TipoItem.CUSTOMIZADO:
		cena_para_instanciar = cena_customizada
	elif CENAS_PADRAO.has(tipo_item):
		var caminho = CENAS_PADRAO[tipo_item]
		if ResourceLoader.exists(caminho):
			cena_para_instanciar = load(caminho) as PackedScene
			
	if cena_para_instanciar == null:
		push_warning("[GerenciadorSpawnItens] Nenhuma cena válida configurada para %s!" % name)
		return
		
	# lista os pontos filhos indexados pelo nome
	var pontos_map: Dictionary = {}
	for child in get_children():
		if child is Marker2D or child is Node2D:
			pontos_map[child.name] = child
			
	if pontos_map.size() == 0 and get_tree():
		var grupo = get_tree().get_nodes_in_group("pontos_item")
		for p in grupo:
			if p is Node2D and p.get_parent() == self:
				pontos_map[p.name] = p
				
	if pontos_map.size() == 0:
		return

	var spawner_id = _obter_spawner_id()
	var pontos_selecionados: Array = []

	if get_node_or_null("/root/PlayerStats") and PlayerStats.has_spawner_sorteio(spawner_id):
		pontos_selecionados = PlayerStats.get_spawner_sorteio(spawner_id)
	else:
		randomize()
		var chaves_pontos = pontos_map.keys()
		chaves_pontos.shuffle()
		for k in chaves_pontos:
			if randf() <= chance_spawn:
				pontos_selecionados.append(k)
		if pontos_selecionados.size() == 0 and garantir_ao_menos_um and chaves_pontos.size() > 0:
			pontos_selecionados.append(chaves_pontos.pick_random())
		if get_node_or_null("/root/PlayerStats"):
			PlayerStats.registrar_spawner_sorteio(spawner_id, pontos_selecionados)

	var pai = get_parent()
	if pai == null:
		pai = self

	for nome_ponto in pontos_selecionados:
		if not pontos_map.has(nome_ponto):
			continue
		var p = pontos_map[nome_ponto]
		var item_id = "%s::%s" % [spawner_id, nome_ponto]
		
		# Se o jogador ja coletou esse item, nao spawna novamente!
		if get_node_or_null("/root/PlayerStats") and PlayerStats.is_item_coletado(item_id):
			continue
			
		var item_inst = cena_para_instanciar.instantiate()
		if "id_unico" in item_inst:
			item_inst.id_unico = item_id
		pai.add_child(item_inst)
		# Validação dinâmica de segurança: garante que o item spawne no chão jogável e fora de paredes
		var pos_final = p.global_position
		var floor_node = pai.get_node_or_null("Floor") as TileMapLayer
		if not floor_node and get_tree() and get_tree().current_scene:
			floor_node = get_tree().current_scene.get_node_or_null("Floor") as TileMapLayer
		var wall_node = pai.get_node_or_null("Wall") as TileMapLayer
		if not wall_node and get_tree() and get_tree().current_scene:
			wall_node = get_tree().current_scene.get_node_or_null("Wall") as TileMapLayer
			
		if floor_node:
			if not _is_posicao_valida(pos_final, floor_node, wall_node):
				pos_final = _encontrar_posicao_chao_segura(pos_final, floor_node, wall_node)
				
		item_inst.global_position = pos_final

func _is_posicao_valida(pos: Vector2, floor_node: TileMapLayer, wall_node: TileMapLayer) -> bool:
	if not floor_node or not is_instance_valid(floor_node):
		return true
	var cell = floor_node.local_to_map(floor_node.to_local(pos))
	if not _is_celula_coberta(cell, floor_node):
		return false
	if wall_node and is_instance_valid(wall_node) and _is_celula_coberta(cell, wall_node):
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
	if not floor_node or not is_instance_valid(floor_node):
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
				if wall_node and is_instance_valid(wall_node) and _is_celula_coberta(sub_cell, wall_node):
					continue
				var wpos = floor_node.to_global(floor_node.map_to_local(sub_cell))
				var dist = wpos.distance_to(pos_desejada)
				if dist < menor_dist:
					menor_dist = dist
					melhor_pos = wpos
			
	return melhor_pos if melhor_pos != Vector2.ZERO else pos_desejada


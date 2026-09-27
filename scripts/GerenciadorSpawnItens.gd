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
	CUSTOMIZADO = 6
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
	TipoItem.CHAVE: "res://scenes/Entidades/Items/ItemChave.tscn"
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
		item_inst.global_position = p.global_position


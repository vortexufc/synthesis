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
	TipoItem.LIVRO_QUIMICA: "res://scenes/Entidades/ItemLivroFormula.tscn",
	TipoItem.BATERIA_FISICA: "res://scenes/Entidades/ItemBateria.tscn",
	TipoItem.CHIP_FISICA: "res://scenes/Entidades/ItemChip.tscn",
	TipoItem.MOEDA: "res://scenes/Entidades/ItemMoeda.tscn",
	TipoItem.CHAVE: "res://scenes/Entidades/ItemChave.tscn"
}

func _ready() -> void:
	if Engine.is_editor_hint():
		return
		
	call_deferred("_executar_spawn")

func _executar_spawn() -> void:
	randomize()
	
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
		
	# lista os pontos filhos
	var pontos: Array[Node2D] = []
	for child in get_children():
		if child is Marker2D or child is Node2D:
			pontos.append(child)
			
	if pontos.size() == 0 and get_tree():
		var grupo = get_tree().get_nodes_in_group("pontos_item")
		for p in grupo:
			if p is Node2D and p.get_parent() == self:
				pontos.append(p)
				
	if pontos.size() == 0:
		return
		
	pontos.shuffle()
	var pai = get_parent()
	if pai == null:
		pai = self
		
	var total_spawnados = 0
	for p in pontos:
		if randf() <= chance_spawn:
			var item_inst = cena_para_instanciar.instantiate()
			pai.add_child(item_inst)
			item_inst.global_position = p.global_position
			total_spawnados += 1
			
	# se nenhum ponto deu certo, mas precisa de pelo menos 1
	if total_spawnados == 0 and garantir_ao_menos_um and pontos.size() > 0:
		var p_sorteado = pontos.pick_random()
		var item_inst = cena_para_instanciar.instantiate()
		pai.add_child(item_inst)
		item_inst.global_position = p_sorteado.global_position
		total_spawnados = 1

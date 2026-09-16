extends Node2D
class_name GerenciadorSpawnBaus

## ==============================================================================
## GERENCIADOR INTELIGENTE DE SPAWN DE BAÚS E MÍMICOS (ARMADILHAS)
## Sorteia dinamicamente os baús reais e armadilhas entre os pontos de spawn.
## Impede que o jogador decore a posição do baú troll entre jogadas!
## ==============================================================================

@export_group("Regras de Spawn")
## Quantidade de baús verdadeiros com recompensas/desafios a spawnar nesta sala
@export_range(1, 5) var qtd_baus_reais: int = 1

## Chance de spawnar um Mímico (Baú Troll) em um dos pontos restantes (0.0 = nunca, 0.4 = 40%, 1.0 = sempre)
@export_range(0.0, 1.0, 0.05) var chance_mimico: float = 0.40

## Dano calibrado do Mímico para não dar instakill (0 = usa o padrão de 70 do mímico)
@export var dano_mimico_custom: float = 35.0

@export_group("Cenas dos Objetos")
## Cena do Baú Real (bau1, bau2, bau3 ou bau_runico)
@export var cena_bau: PackedScene = preload("res://scenes/Objetos/bau1.tscn")

## Cena do Mímico (Baú Troll que morde ao interagir)
@export var cena_mimico: PackedScene = preload("res://scenes/Objetos/mimico.tscn")

@export_group("Configuração do Baú Real")
## 0 = Desafio da Memória Arcana, 1 = Pergaminho de Dicas
@export_enum("Desafio da Memória Arcana", "Pergaminho de Dicas") var modo_conteudo: int = 0
## 0 = Automático (detecta pela sala), 1 = Química, 2 = Física, 3 = Biologia
@export_enum("Automático", "Química", "Física", "Biologia") var forcar_andar: int = 0
@export var recompensa_moedas: int = 30
@export var recompensa_pocao: String = "Poção de Cura"

func _ready() -> void:
	# Só executa o sorteio em tempo de jogo real (não no editor)
	if Engine.is_editor_hint():
		return
		
	# Limpa qualquer resquício de nós antigos se houver
	_limpar_residuos()
	
	# Espera um frame para garantir que a sala esteja completamente carregada
	call_deferred("_executar_spawn_aleatorio")

func _limpar_residuos() -> void:
	for child in get_children():
		for sub in child.get_children():
			if sub.name.begins_with("Preview"):
				sub.queue_free()

func _executar_spawn_aleatorio() -> void:
	randomize()
	_limpar_residuos()
	
	# 1. Coleta os pontos disponíveis
	var pontos_disponiveis: Array[Node2D] = []
	
	# Primeiro busca nos filhos diretos deste gerenciador
	for child in get_children():
		if (child is Marker2D or child is Node2D) and not child.name.begins_with("Preview"):
			pontos_disponiveis.append(child)
			
	# Se não tiver filhos, busca pontos espalhados na cena pelo grupo "pontos_bau"
	if pontos_disponiveis.size() == 0 and get_tree():
		var grupo = get_tree().get_nodes_in_group("pontos_bau")
		for p in grupo:
			if p is Node2D and not p in pontos_disponiveis:
				pontos_disponiveis.append(p)
			
	if pontos_disponiveis.size() == 0:
		push_warning("[GerenciadorSpawnBaus] Nenhum ponto de spawn encontrado para %s!" % name)
		return
		
	# 2. Embaralha os pontos
	pontos_disponiveis.shuffle()
	
	var pontos_ocupados: Array[Node2D] = []
	var pai = get_parent()
	if pai == null:
		pai = self
		
	# 3. Spawna os Baús Reais nos primeiros pontos sorteados
	var total_reais = min(qtd_baus_reais, pontos_disponiveis.size())
	for i in range(total_reais):
		var ponto = pontos_disponiveis[i]
		if cena_bau != null:
			var bau_inst = cena_bau.instantiate()
			bau_inst.global_position = ponto.global_position
			
			if "modo_conteudo" in bau_inst:
				bau_inst.modo_conteudo = modo_conteudo
			if "forcar_andar" in bau_inst:
				bau_inst.forcar_andar = forcar_andar
			if "recompensa_moedas" in bau_inst:
				bau_inst.recompensa_moedas = recompensa_moedas
			if "recompensa_pocao" in bau_inst:
				bau_inst.recompensa_pocao = recompensa_pocao
				
			pai.add_child(bau_inst)
			pontos_ocupados.append(ponto)
			
	# 4. Filtra os pontos restantes onde NÃO há baú real
	var pontos_restantes: Array[Node2D] = []
	for p in pontos_disponiveis:
		if not p in pontos_ocupados:
			pontos_restantes.append(p)
			
	# 5. Sorteia se o Mímico vai surgir em um dos pontos livres
	if pontos_restantes.size() > 0 and cena_mimico != null:
		var chance_sorteada = randf()
		if chance_sorteada < chance_mimico:
			var ponto_mimico = pontos_restantes.pick_random()
			var mimico_inst = cena_mimico.instantiate()
			mimico_inst.global_position = ponto_mimico.global_position
			
			if dano_mimico_custom > 0 and "dano" in mimico_inst:
				mimico_inst.dano = dano_mimico_custom
				
			pai.add_child(mimico_inst)
			pontos_ocupados.append(ponto_mimico)

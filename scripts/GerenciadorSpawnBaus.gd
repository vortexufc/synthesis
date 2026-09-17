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

func _executar_spawn_aleatorio() -> void:
	randomize()
	_limpar_residuos()
	
	# pega todos os pontos marcados na sala
	var pontos_disponiveis: Array[Node2D] = []
	
	for child in get_children():
		if (child is Marker2D or child is Node2D) and not child.name.begins_with("Preview"):
			pontos_disponiveis.append(child)
			
	if pontos_disponiveis.size() == 0 and get_tree():
		var grupo = get_tree().get_nodes_in_group("pontos_bau")
		for p in grupo:
			if p is Node2D and not p in pontos_disponiveis:
				pontos_disponiveis.append(p)
			
	if pontos_disponiveis.size() == 0:
		push_warning("[GerenciadorSpawnBaus] Nenhum ponto de spawn encontrado para %s!" % name)
		return
		
	# embaralha os pontos
	pontos_disponiveis.shuffle()
	
	var pontos_ocupados: Array[Node2D] = []
	var pai = get_parent()
	if pai == null:
		pai = self
		
	# instancia os baús normais
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
			
	# pontos que sobraram
	var pontos_restantes: Array[Node2D] = []
	for p in pontos_disponiveis:
		if not p in pontos_ocupados:
			pontos_restantes.append(p)
			
	# chance de colocar um mímico em um ponto que sobrou
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

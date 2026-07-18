extends Node

var hub_geral = "res://scenes/Salas/Hub_Geral.tscn"
var sala_inicial = "res://scenes/Salas/Salas_BuildTGXP/Corredor.tscn"
var sala_01 = "res://scenes/Salas/Salas_BuildTGXP/Sala01.tscn"

# Pool das 12 novas salas aleatórias
var salas_alquimia: Array = [
	"res://scenes/Salas/Salas_Quimica/Sala_Alquimia01.tscn",
	"res://scenes/Salas/Salas_Quimica/Sala_Alquimia02.tscn",
	"res://scenes/Salas/Salas_Quimica/Sala_Alquimia03.tscn",
	"res://scenes/Salas/Salas_Quimica/Sala_Alquimia04.tscn",
	"res://scenes/Salas/Salas_Quimica/Sala_Alquimia05.tscn",
	"res://scenes/Salas/Salas_Quimica/Sala_Alquimia06.tscn",
	"res://scenes/Salas/Salas_Quimica/Sala_Alquimia07.tscn",
	"res://scenes/Salas/Salas_Quimica/Sala_Alquimia08.tscn",
	"res://scenes/Salas/Salas_Quimica/Sala_Alquimia09.tscn",
	"res://scenes/Salas/Salas_Quimica/Sala_Alquimia10.tscn",
	"res://scenes/Salas/Salas_Quimica/Sala_Alquimia11.tscn",
	"res://scenes/Salas/Salas_Quimica/Sala_Alquimia12.tscn"
]

# O percurso completo gerado para a corrida atual
var percurso_salas: Array = []

# Rastreia numericamente onde o jogador está para evitar bugs com salas duplicadas
var indice_atual: int = 0

# Diz se o jogador acabou de voltar para a sala anterior
var vindo_de_porta_de_retorno: bool = false

# Array contendo identificadores de inimigos derrotados nesta masmorra
var inimigos_derrotados: Array = []

func _ready():
	randomize()
	resetar_masmorra()

func get_index_da_cena(cena: String) -> int:
	var cena_lower = cena.to_lower()
	for i in range(percurso_salas.size()):
		if percurso_salas[i].to_lower() == cena_lower:
			return i
	return -1

func get_proxima_sala(arquivo_cena_atual: String = "") -> String:
	var cena_atual = arquivo_cena_atual
	if cena_atual == "" and get_tree().current_scene:
		cena_atual = get_tree().current_scene.scene_file_path
		
	# Proteção para salas repetidas: se o índice atual bate com a cena onde o player está, mantemos a sincronia
	if indice_atual < percurso_salas.size() and percurso_salas[indice_atual].to_lower() == cena_atual.to_lower():
		print("[DungeonGenerator] Avanço sincronizado no índice: ", indice_atual)
	else:
		# Fallback de segurança caso o jogador mude de cena por fora do sistema de portas
		indice_atual = get_index_da_cena(cena_atual)
		
	print("[DungeonGenerator] Tentando AVANÇAR de: ", cena_atual, " | Index atual: ", indice_atual)
	
	if indice_atual != -1 and indice_atual + 1 < percurso_salas.size():
		indice_atual += 1
		return percurso_salas[indice_atual]
		
	return hub_geral

func get_sala_anterior(arquivo_cena_atual: String = "") -> String:
	var cena_atual = arquivo_cena_atual
	if cena_atual == "" and get_tree().current_scene:
		cena_atual = get_tree().current_scene.scene_file_path
		
	# Sincronia de índice para o retorno seguro pelas portas
	if indice_atual < percurso_salas.size() and percurso_salas[indice_atual].to_lower() == cena_atual.to_lower():
		print("[DungeonGenerator] Retorno sincronizado no índice: ", indice_atual)
	else:
		indice_atual = get_index_da_cena(cena_atual)
		
	print("[DungeonGenerator] Tentando VOLTAR de: ", cena_atual, " | Index atual: ", indice_atual)
	
	if indice_atual > 0:
		indice_atual -= 1
		return percurso_salas[indice_atual]
		
	return hub_geral

func registrar_inimigo_derrotado(key: String) -> void:
	if not (key in inimigos_derrotados):
		inimigos_derrotados.append(key)
		print("[DungeonGenerator] Inimigo registrado como derrotado: ", key)

func is_inimigo_derrotado(key: String) -> bool:
	return key in inimigos_derrotados

func resetar_masmorra() -> void:
	percurso_salas.clear()
	inimigos_derrotados.clear()
	indice_atual = 0 # Reinicia o ponteiro do progresso
	
	# 1. Injeta a sequência fixa e linear do Hub nas primeiras posições
	percurso_salas.append(hub_geral)      # Índice 0
	percurso_salas.append(sala_inicial)   # Índice 1 (Corredor)
	percurso_salas.append(sala_inicial)   # Índice 2 (Corredor novamente)
	percurso_salas.append(sala_01)        # Índice 3 (Sala 01)
	
	# 2. Pega as 12 salas arcanas e embaralha para o resto do percurso
	var rooms_embaralhadas = salas_alquimia.duplicate()
	rooms_embaralhadas.shuffle()
	
	# 3. Consolida o restante do trajeto de forma aleatória
	percurso_salas.append_array(rooms_embaralhadas)
	
	print("[DungeonGenerator] Nova Masmorra Gerada com Sucesso!")
	print("[DungeonGenerator] Sequência: Hub Geral -> Corredor -> Corredor -> Sala01 -> [12 Salas de Alquimia Aleatórias]")
	print("[DungeonGenerator] Total de estágios na fila: ", percurso_salas.size())

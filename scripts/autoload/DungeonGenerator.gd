extends Node

var sala_inicial = "res://scenes/Salas/Salas_BuildTGXP/Corredor.tscn"
var sala_01 = "res://scenes/Salas/Salas_BuildTGXP/Sala01.tscn"

# Pool das 12 novas salas aleatórias
var salas_alquimia: Array = [
	"res://scenes/Salas/Salas_Geral/Sala_Alquimia01.tscn",
	"res://scenes/Salas/Salas_Geral/Sala_Alquimia02.tscn",
	"res://scenes/Salas/Salas_Geral/Sala_Alquimia03.tscn",
	"res://scenes/Salas/Salas_Geral/Sala_Alquimia04.tscn",
	"res://scenes/Salas/Salas_Geral/Sala_Alquimia05.tscn",
	"res://scenes/Salas/Salas_Geral/Sala_Alquimia06.tscn",
	"res://scenes/Salas/Salas_Geral/Sala_Alquimia07.tscn",
	"res://scenes/Salas/Salas_Geral/Sala_Alquimia08.tscn",
	"res://scenes/Salas/Salas_Geral/Sala_Alquimia09.tscn",
	"res://scenes/Salas/Salas_Geral/Sala_Alquimia10.tscn",
	"res://scenes/Salas/Salas_Geral/Sala_Alquimia11.tscn",
	"res://scenes/Salas/Salas_Geral/Sala_Alquimia12.tscn"
]

# O percurso completo gerado para a corrida atual (da primeira à última sala)
var percurso_salas: Array = []

# Diz se o jogador acabou de voltar para a sala anterior
var vindo_de_porta_de_retorno: bool = false

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
		
	var index = get_index_da_cena(cena_atual)
	print("[DungeonGenerator] Tentando AVANÇAR de: ", cena_atual, " | Index encontrado: ", index)
	
	if index != -1 and index + 1 < percurso_salas.size():
		return percurso_salas[index + 1]
		
	return sala_inicial

func get_sala_anterior(arquivo_cena_atual: String = "") -> String:
	var cena_atual = arquivo_cena_atual
	if cena_atual == "" and get_tree().current_scene:
		cena_atual = get_tree().current_scene.scene_file_path
		
	var index = get_index_da_cena(cena_atual)
	print("[DungeonGenerator] Tentando VOLTAR de: ", cena_atual, " | Index encontrado: ", index)
	
	if index > 0:
		return percurso_salas[index - 1]
		
	return sala_inicial

func resetar_masmorra() -> void:
	percurso_salas.clear()
	percurso_salas.append(sala_inicial)
	percurso_salas.append(sala_01)
	
	# Pega as 12 salas e embaralha APENAS UMA VEZ
	var embaralhadas = salas_alquimia.duplicate()
	embaralhadas.shuffle()
	
	# Adiciona as salas embaralhadas no percurso fixo da corrida
	percurso_salas.append_array(embaralhadas)
	print("[DungeonGenerator] Novo percurso gerado! Total de salas: ", percurso_salas.size())

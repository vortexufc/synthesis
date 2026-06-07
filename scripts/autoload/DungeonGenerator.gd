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

func _ready():
	randomize()

func get_proxima_sala(arquivo_cena_atual: String = "") -> String:
	var cena_atual = arquivo_cena_atual
	if cena_atual == "" and get_tree().current_scene:
		cena_atual = get_tree().current_scene.scene_file_path
		
	# Lógica da progressão: Corredor -> Sala 01 -> Salas Aleatórias
	if cena_atual == sala_inicial:
		return sala_01
	else:
		# Se não estiver no Corredor (ou seja, se já estiver na Sala01 ou numa sala aleatória), sorteia a próxima!
		return get_sala_aleatoria()

func get_sala_aleatoria() -> String:
	return salas_alquimia[randi() % salas_alquimia.size()]

func resetar_masmorra() -> void:
	pass

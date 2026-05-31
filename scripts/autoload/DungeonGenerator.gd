extends Node

# Fila estática de salas (caminho da masmorra)
# [Level-4] - Caminho: Início -> Sala Desafio A -> Sala Desafio B -> Sala Boss
var rotas_da_masmorra: Array = [
	"res://scenes/Salas/Salas_BuildTGXP/Corredor.tscn",
	"res://scenes/Salas/Salas_BuildTGXP/Sala01.tscn",
	"res://scenes/Salas/Salas_BuildTGXP/Sala02.tscn",
	"res://scenes/ui/parabens_ui.tscn" # Representando a finalização/Boss temporariamente
]

var indice_sala_atual: int = 0

func get_proxima_sala(arquivo_cena_atual: String = "") -> String:
	var cena_atual = arquivo_cena_atual
	if cena_atual == "" and get_tree().current_scene:
		cena_atual = get_tree().current_scene.scene_file_path
		
	var idx = rotas_da_masmorra.find(cena_atual)
	
	if idx != -1 and idx < rotas_da_masmorra.size() - 1:
		return rotas_da_masmorra[idx + 1]
	elif idx == rotas_da_masmorra.size() - 1:
		return rotas_da_masmorra[-1] # Trava na última sala (ou Boss)
	else:
		# Fallback se tiver rodado o jogo do meio de uma sala que não tá na lista
		return rotas_da_masmorra[1]

func resetar_masmorra() -> void:
	pass

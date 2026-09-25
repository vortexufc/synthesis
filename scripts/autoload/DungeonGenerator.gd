extends Node

var hub_geral = "res://scenes/Salas/Comum/Hub_Geral.tscn"

# salas do andar de quimica
var sala_inicial = "res://scenes/Salas/Salas_Quimica/Corredor.tscn"
var sala_01 = "res://scenes/Salas/Salas_Quimica/Sala_Alquimia01.tscn"
var sala_boss_alquimia = "res://scenes/Salas/Salas_Quimica/Sala_BossAlquimia.tscn"

# salas intermediarias sorteadas a cada partida
var salas_alquimia_pool: Array = [
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
	"res://scenes/Salas/Salas_Quimica/Sala_Alquimia12.tscn",
	"res://scenes/Salas/Salas_Quimica/Sala_Alquimia13.tscn",
	"res://scenes/Salas/Salas_Quimica/Sala_Alquimia14.tscn"
]

# todas as salas de quimica
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
	"res://scenes/Salas/Salas_Quimica/Sala_Alquimia12.tscn",
	"res://scenes/Salas/Salas_Quimica/Sala_Alquimia13.tscn",
	"res://scenes/Salas/Salas_Quimica/Sala_Alquimia14.tscn",
	"res://scenes/Salas/Salas_Quimica/Sala_BossAlquimia.tscn"
]

# salas do andar de fisica
var sala_01_fisica = "res://scenes/Salas/Sala_Fisica/Sala_Física01.tscn"
var sala_boss_fisica = "res://scenes/Salas/Sala_Fisica/Sala_Física12.tscn"

# salas intermediarias sorteadas de fisica
var salas_fisica_pool: Array = [
	"res://scenes/Salas/Sala_Fisica/Sala_Física02.tscn",
	"res://scenes/Salas/Sala_Fisica/Sala_Física03.tscn",
	"res://scenes/Salas/Sala_Fisica/Sala_Física04.tscn",
	"res://scenes/Salas/Sala_Fisica/Sala_Física05.tscn",
	"res://scenes/Salas/Sala_Fisica/Sala_Física06.tscn",
	"res://scenes/Salas/Sala_Fisica/Sala_Física07.tscn",
	"res://scenes/Salas/Sala_Fisica/Sala_Física08.tscn",
	"res://scenes/Salas/Sala_Fisica/Sala_Física09.tscn",
	"res://scenes/Salas/Sala_Fisica/Sala_Física10.tscn",
	"res://scenes/Salas/Sala_Fisica/Sala_Física11.tscn"
]

# todas as salas de fisica
var salas_fisica: Array = [
	"res://scenes/Salas/Sala_Fisica/Sala_Física01.tscn",
	"res://scenes/Salas/Sala_Fisica/Sala_Física02.tscn",
	"res://scenes/Salas/Sala_Fisica/Sala_Física03.tscn",
	"res://scenes/Salas/Sala_Fisica/Sala_Física04.tscn",
	"res://scenes/Salas/Sala_Fisica/Sala_Física05.tscn",
	"res://scenes/Salas/Sala_Fisica/Sala_Física06.tscn",
	"res://scenes/Salas/Sala_Fisica/Sala_Física07.tscn",
	"res://scenes/Salas/Sala_Fisica/Sala_Física08.tscn",
	"res://scenes/Salas/Sala_Fisica/Sala_Física09.tscn",
	"res://scenes/Salas/Sala_Fisica/Sala_Física10.tscn",
	"res://scenes/Salas/Sala_Fisica/Sala_Física11.tscn",
	"res://scenes/Salas/Sala_Fisica/Sala_Física12.tscn"
]

# salas do andar de biologia
var sala_inicial_biologia = "res://scenes/Salas/Estufa_Biologia/Corredor_Estufa.tscn"
var sala_01_biologia = "res://scenes/Salas/Estufa_Biologia/Sala_Biologia01.tscn"
var salas_biologia_pool: Array = [
	"res://scenes/Salas/Estufa_Biologia/Sala_Biologia02.tscn",
	"res://scenes/Salas/Estufa_Biologia/Sala_Biologia03.tscn",
	"res://scenes/Salas/Estufa_Biologia/Sala_Biologia04.tscn"
]
var salas_biologia: Array = [
	"res://scenes/Salas/Estufa_Biologia/Corredor_Estufa.tscn",
	"res://scenes/Salas/Estufa_Biologia/Sala_Biologia01.tscn",
	"res://scenes/Salas/Estufa_Biologia/Sala_Biologia02.tscn",
	"res://scenes/Salas/Estufa_Biologia/Sala_Biologia03.tscn",
	"res://scenes/Salas/Estufa_Biologia/Sala_Biologia04.tscn"
]

# ordem das salas da corrida atual
var percurso_salas: Array = []

# indice da sala onde o jogador esta
var indice_atual: int = 0

# avisa se o player ta voltando de porta
var vindo_de_porta_de_retorno: bool = false

# guarda qual andar o player tava explorando
var masmorra_retorno_hub: String = ""

# toca cutscene do hub
var tocar_cutscene_inicial: bool = false

# lista de monstros derrotados na run
var inimigos_derrotados: Array = []

func _ready():
	randomize()
	resetar_masmorra()

func get_masmorra_da_cena(cena: String) -> String:
	var cena_lower = cena.to_lower()
	if "corredor" in cena_lower or "alquimia" in cena_lower or "quimica" in cena_lower or "sala01.tscn" in cena_lower or "sala02.tscn" in cena_lower:
		return "Química"
	elif "fisica" in cena_lower or "física" in cena_lower:
		return "Física"
	elif "biologia" in cena_lower:
		return "Biologia"
	return ""

func get_masmorra_do_percurso() -> String:
	if percurso_salas.size() > 1:
		return get_masmorra_da_cena(percurso_salas[1])
	return ""

func get_index_da_cena(cena: String) -> int:
	if percurso_salas.is_empty():
		resetar_masmorra()
		
	var cena_lower = cena.to_lower()
	var masmorra_da_cena = get_masmorra_da_cena(cena)
	
	# se mudou de materia na masmorra sorteia o percurso certo
	if masmorra_da_cena != "" and get_masmorra_do_percurso() != masmorra_da_cena:
		print("[DungeonGenerator] Cena fora do percurso (%s). Regenerando percurso para %s..." % [cena, masmorra_da_cena])
		resetar_masmorra(masmorra_da_cena)
		
	for i in range(percurso_salas.size()):
		if percurso_salas[i].to_lower() == cena_lower:
			return i
			
	# equivalencias de nomes de salas
	var masmorra_atual = get_masmorra_do_percurso()
	if masmorra_atual == "Química":
		if "sala01.tscn" in cena_lower or "sala_alquimia01.tscn" in cena_lower:
			return 1
		if "boss" in cena_lower:
			return percurso_salas.size() - 1
	elif masmorra_atual == "Física":
		if "sala_física01.tscn" in cena_lower or "sala_fisica01.tscn" in cena_lower:
			return 1
		if "fisica12" in cena_lower or "física12" in cena_lower or "boss" in cena_lower:
			return percurso_salas.size() - 1
	elif masmorra_atual == "Biologia":
		if "corredor" in cena_lower or "estufa" in cena_lower:
			return 1
		if "biologia01.tscn" in cena_lower:
			return 2
		if "biologia04.tscn" in cena_lower:
			return percurso_salas.size() - 1
				
	return -1

func get_proxima_sala(arquivo_cena_atual: String = "") -> String:
	var cena_atual = arquivo_cena_atual
	if cena_atual == "" and get_tree().current_scene:
		cena_atual = get_tree().current_scene.scene_file_path
		
	var cena_lower = cena_atual.to_lower()
	var masmorra_da_cena = get_masmorra_da_cena(cena_atual)
	
	# garante percurso da mesma materia
	if masmorra_da_cena != "" and get_masmorra_do_percurso() != masmorra_da_cena:
		print("[DungeonGenerator] get_proxima_sala: Matéria incompatível. Regenerando para: ", masmorra_da_cena)
		resetar_masmorra(masmorra_da_cena)
	
	# do corredor sempre vai pra sala 1
	if "corredor" in cena_lower:
		if "biologia" in masmorra_da_cena.to_lower() or "estufa" in cena_lower:
			if percurso_salas.size() > 2:
				indice_atual = 2
				return percurso_salas[2]
			return sala_01_biologia
		elif percurso_salas.size() > 1:
			indice_atual = 1
			print("[DungeonGenerator] Corredor -> Avançando para a primeira sala: ", percurso_salas[1])
			return percurso_salas[1]
		
	# sincroniza o indice da sala atual
	if indice_atual < percurso_salas.size() and percurso_salas[indice_atual].to_lower() == cena_lower:
		print("[DungeonGenerator] Avanço sincronizado no índice: ", indice_atual)
	else:
		# se trocou de sala por fora sincroniza o indice
		indice_atual = get_index_da_cena(cena_atual)
		
	print("[DungeonGenerator] Tentando AVANÇAR de: ", cena_atual, " | Index atual: ", indice_atual)
	
	if indice_atual != -1 and indice_atual + 1 < percurso_salas.size():
		indice_atual += 1
		return percurso_salas[indice_atual]
		
	# Fallback inteligente para quando rodar uma cena avulsa direto no F6:
	if indice_atual == -1:
		var lista_completa: Array = []
		if masmorra_da_cena == "Química":
			lista_completa = salas_alquimia
		elif masmorra_da_cena == "Física":
			lista_completa = salas_fisica_pool
			
		for k in range(lista_completa.size()):
			if lista_completa[k].to_lower() == cena_lower:
				if k + 1 < lista_completa.size():
					print("[DungeonGenerator] Modo Teste F6: Avançando sequencialmente de %s para %s" % [cena_atual, lista_completa[k + 1]])
					return lista_completa[k + 1]
				elif masmorra_da_cena == "Química":
					return sala_boss_alquimia
				elif masmorra_da_cena == "Física":
					return sala_boss_fisica
				break
		
	return hub_geral

func get_sala_anterior(arquivo_cena_atual: String = "") -> String:
	var cena_atual = arquivo_cena_atual
	if cena_atual == "" and get_tree().current_scene:
		cena_atual = get_tree().current_scene.scene_file_path
		
	var cena_lower = cena_atual.to_lower()
	var masmorra_da_cena = get_masmorra_da_cena(cena_atual)
	
	# pega a materia da sala
	if masmorra_da_cena != "":
		masmorra_retorno_hub = masmorra_da_cena
		if get_node_or_null("/root/DatabaseManager"):
			DatabaseManager.active_dungeon = masmorra_da_cena
		if get_masmorra_do_percurso() != masmorra_da_cena:
			resetar_masmorra(masmorra_da_cena)

	# voltando do corredor vai pro hub
	if "corredor.tscn" in cena_lower:
		indice_atual = 0
		return hub_geral

	# voltando da sala 1 de quimica vai pro corredor
	if "sala01.tscn" in cena_lower or "sala_alquimia01.tscn" in cena_lower:
		if not (sala_inicial.to_lower() in percurso_salas):
			resetar_masmorra("Química")
		indice_atual = 1
		return sala_inicial

	# voltando da sala 1 de fisica vai pro hub
	if "sala_física01.tscn" in cena_lower or "sala_fisica01.tscn" in cena_lower:
		indice_atual = 0
		return hub_geral

	# voltando da sala 1 de biologia vai pro corredor da estufa
	if "biologia01.tscn" in cena_lower:
		indice_atual = 1
		return sala_inicial_biologia

	# volta um indice no percurso
	if indice_atual < percurso_salas.size() and percurso_salas[indice_atual].to_lower() == cena_lower:
		print("[DungeonGenerator] Retorno sincronizado no índice: ", indice_atual)
	else:
		indice_atual = get_index_da_cena(cena_atual)
		
	print("[DungeonGenerator] Tentando VOLTAR de: ", cena_atual, " | Index atual: ", indice_atual)
	
	if indice_atual > 0:
		indice_atual -= 1
		return percurso_salas[indice_atual]
		
	# Fallback inteligente para retorno quando rodar via F6:
	if indice_atual == -1:
		var lista_completa: Array = []
		if masmorra_da_cena == "Química":
			lista_completa = salas_alquimia
		elif masmorra_da_cena == "Física":
			lista_completa = salas_fisica_pool
			
		for k in range(lista_completa.size()):
			if lista_completa[k].to_lower() == cena_lower:
				if k > 0:
					return lista_completa[k - 1]
				elif masmorra_da_cena == "Química":
					return sala_inicial
				elif masmorra_da_cena == "Física":
					return sala_01_fisica
				break
		
	return hub_geral

func sincronizar_cena(cena: String) -> void:
	var masmorra_da_cena = get_masmorra_da_cena(cena)
	if masmorra_da_cena != "" and get_masmorra_do_percurso() != masmorra_da_cena:
		resetar_masmorra(masmorra_da_cena)
	var idx = get_index_da_cena(cena)
	if idx != -1:
		indice_atual = idx
		print("[DungeonGenerator] Sincronizado para: ", cena, " no índice: ", indice_atual)

func registrar_inimigo_derrotado(key: String) -> void:
	if not (key in inimigos_derrotados):
		inimigos_derrotados.append(key)
		print("[DungeonGenerator] Inimigo registrado como derrotado: ", key)

func is_inimigo_derrotado(key: String) -> bool:
	return key in inimigos_derrotados

func is_sala_boss(arquivo_cena: String = "") -> bool:
	var cena_lower = arquivo_cena.to_lower()
	if cena_lower == "" and get_tree() and get_tree().current_scene:
		cena_lower = get_tree().current_scene.scene_file_path.to_lower()
	if "boss" in cena_lower or "fisica12" in cena_lower or "física12" in cena_lower:
		return true
	if percurso_salas.size() > 1 and indice_atual == percurso_salas.size() - 1:
		return true
	return false

func resetar_masmorra(forcar_dungeon: String = "") -> void:
	percurso_salas.clear()
	inimigos_derrotados.clear()
	indice_atual = 0 # Reinicia o ponteiro do progresso
	
	var active = ""
	if forcar_dungeon != "":
		active = forcar_dungeon
		masmorra_retorno_hub = forcar_dungeon
		if get_node_or_null("/root/DatabaseManager"):
			DatabaseManager.active_dungeon = forcar_dungeon
			if DatabaseManager.has_method("salvar_progresso"):
				DatabaseManager.salvar_progresso()
	elif get_node_or_null("/root/DatabaseManager") and DatabaseManager.active_dungeon != "":
		active = DatabaseManager.active_dungeon
		masmorra_retorno_hub = active
	else:
		masmorra_retorno_hub = ""
		active = ""
	
	# coloca o hub no inicio
	percurso_salas.append(hub_geral)
	
	if active == "Física":
		# comeca na sala 1
		percurso_salas.append(sala_01_fisica)
		
		# sorteia 6 salas do meio sem repetir
		var intermediarias = salas_fisica_pool.duplicate()
		intermediarias.shuffle()
		for i in range(min(6, intermediarias.size())):
			percurso_salas.append(intermediarias[i])
		
		# ultima sala: boss robo
		percurso_salas.append(sala_boss_fisica)
		print("[DungeonGenerator] Masmorra de Física gerada com %d salas (Sala 01 -> 6 sorteadas -> Boss 12)." % [percurso_salas.size() - 1])
	elif active == "Química":
		# andar de quimica:
		# comeca na sala 1
		percurso_salas.append(sala_01)
		
		# sorteia 6 salas do meio sem repetir
		var intermediarias = salas_alquimia_pool.duplicate()
		intermediarias.shuffle()
		for i in range(min(6, intermediarias.size())):
			percurso_salas.append(intermediarias[i])
		
		# ultima sala: boss slime
		percurso_salas.append(sala_boss_alquimia)
		print("[DungeonGenerator] Masmorra de Química gerada com %d salas (Sala 01 -> 6 sorteadas -> Boss Alquimia)." % [percurso_salas.size() - 1])
	elif active == "Biologia":
		# andar de biologia (Estufa)
		percurso_salas.append(sala_inicial_biologia)
		percurso_salas.append(sala_01_biologia)
		percurso_salas.append("res://scenes/Salas/Estufa_Biologia/Sala_Biologia02.tscn")
		percurso_salas.append("res://scenes/Salas/Estufa_Biologia/Sala_Biologia03.tscn")
		percurso_salas.append("res://scenes/Salas/Estufa_Biologia/Sala_Biologia04.tscn")
		print("[DungeonGenerator] Masmorra de Biologia gerada com %d salas (Corredor -> Salas 01 a 04)." % [percurso_salas.size() - 1])
	else:
		print("[DungeonGenerator] Nenhuma expedição ativa (Aguardando escolha de porta no Hub).")

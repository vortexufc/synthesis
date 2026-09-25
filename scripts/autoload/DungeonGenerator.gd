extends Node

var hub_geral = "res://scenes/Salas/Comum/Hub_Geral.tscn"

# salas do andar de quimica
var sala_inicial = "res://scenes/Salas/Laboratório_Alquimia/Corredor_Alquimia.tscn"
var sala_01 = "res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia01.tscn"
var sala_boss_alquimia = "res://scenes/Salas/Laboratório_Alquimia/Sala_BossAlquimia.tscn"

# pools de salas de quimica separados por dificuldade
# Tier 1 (Azul) - slimes pequenos azuis (8 salas intermediárias nativamente azuis)
var salas_alquimia_tier1: Array = [
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia02.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia03.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia09.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia10.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia11.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia12.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia13.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia14.tscn"
]
# Tier 2 (Verde) - slimes verdes (2 salas nativamente verdes)
var salas_alquimia_tier2: Array = [
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia04.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia05.tscn"
]
# Tier 3 (Vermelho/Laranja) - slimes laranjas/vermelhos (2 salas nativamente vermelhas)
var salas_alquimia_tier3: Array = [
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia06.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia07.tscn"
]

# pool legado (todas as intermediarias) para fallback
var salas_alquimia_pool: Array = [
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia02.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia03.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia04.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia05.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia06.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia07.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia08.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia09.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia10.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia11.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia12.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia13.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia14.tscn"
]

# todas as salas de quimica
var salas_alquimia: Array = [
	"res://scenes/Salas/Laboratório_Alquimia/Corredor_Alquimia.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia01.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia02.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia03.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia04.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia05.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia06.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia07.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia08.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia09.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia10.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia11.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia12.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia13.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia14.tscn",
	"res://scenes/Salas/Laboratório_Alquimia/Sala_BossAlquimia.tscn"
]

# salas do andar de fisica
var sala_inicial_fisica = "res://scenes/Salas/Oficina_Física/Corredor_Física.tscn"
var sala_01_fisica = "res://scenes/Salas/Oficina_Física/Sala_Física01.tscn"
var sala_boss_fisica = "res://scenes/Salas/Oficina_Física/Sala_Física12.tscn"

# salas intermediarias sorteadas de fisica
var salas_fisica_pool: Array = [
	"res://scenes/Salas/Oficina_Física/Sala_Física02.tscn",
	"res://scenes/Salas/Oficina_Física/Sala_Física03.tscn",
	"res://scenes/Salas/Oficina_Física/Sala_Física04.tscn",
	"res://scenes/Salas/Oficina_Física/Sala_Física05.tscn",
	"res://scenes/Salas/Oficina_Física/Sala_Física06.tscn",
	"res://scenes/Salas/Oficina_Física/Sala_Física07.tscn",
	"res://scenes/Salas/Oficina_Física/Sala_Física08.tscn",
	"res://scenes/Salas/Oficina_Física/Sala_Física09.tscn",
	"res://scenes/Salas/Oficina_Física/Sala_Física10.tscn",
	"res://scenes/Salas/Oficina_Física/Sala_Física11.tscn"
]

# todas as salas de fisica
var salas_fisica: Array = [
	"res://scenes/Salas/Oficina_Física/Corredor_Física.tscn",
	"res://scenes/Salas/Oficina_Física/Sala_Física01.tscn",
	"res://scenes/Salas/Oficina_Física/Sala_Física02.tscn",
	"res://scenes/Salas/Oficina_Física/Sala_Física03.tscn",
	"res://scenes/Salas/Oficina_Física/Sala_Física04.tscn",
	"res://scenes/Salas/Oficina_Física/Sala_Física05.tscn",
	"res://scenes/Salas/Oficina_Física/Sala_Física06.tscn",
	"res://scenes/Salas/Oficina_Física/Sala_Física07.tscn",
	"res://scenes/Salas/Oficina_Física/Sala_Física08.tscn",
	"res://scenes/Salas/Oficina_Física/Sala_Física09.tscn",
	"res://scenes/Salas/Oficina_Física/Sala_Física10.tscn",
	"res://scenes/Salas/Oficina_Física/Sala_Física11.tscn",
	"res://scenes/Salas/Oficina_Física/Sala_Física12.tscn"
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
# lista de portas destrancadas na run
var portas_destrancadas: Array = []

# salas que vão ter a mecânica da chave nesta run (2 por andar)
var salas_com_chave: Array = []

# dicionario que mapeia caminho da sala -> tier desejado dos inimigos
# tier 1 = azul, 2 = verde, 3 = vermelho/laranja
# usado quando uma sala precisa ter inimigos de tier diferente do nativo
var tier_override: Dictionary = {}

func _ready():
	randomize()
	resetar_masmorra()

func get_masmorra_da_cena(cena: String) -> String:
	var cena_lower = cena.to_lower()
	if "biologia" in cena_lower or "estufa" in cena_lower:
		return "Biologia"
	elif "fisica" in cena_lower or "física" in cena_lower or "oficina" in cena_lower:
		return "Física"
	elif "alquimia" in cena_lower or "quimica" in cena_lower or "química" in cena_lower or "laborat" in cena_lower:
		return "Química"
	elif "corredor_alquimia" in cena_lower or "sala01.tscn" in cena_lower or "sala02.tscn" in cena_lower:
		return "Química"
	elif "corredor_física" in cena_lower or "corredor_fisica" in cena_lower:
		return "Física"
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
		
	var cena_file = cena_lower.get_file()
	for i in range(percurso_salas.size()):
		var p_lower = percurso_salas[i].to_lower()
		if p_lower == cena_lower or (cena_file != "" and p_lower.get_file() == cena_file):
			return i
			
	# equivalencias de nomes de salas
	var masmorra_atual = get_masmorra_do_percurso()
	if masmorra_atual == "Química":
		if "corredor" in cena_lower:
			return 1
		if "sala01.tscn" in cena_lower or "sala_alquimia01.tscn" in cena_lower:
			return 2
		if "boss" in cena_lower:
			return percurso_salas.size() - 1
	elif masmorra_atual == "Física":
		if "corredor" in cena_lower:
			return 1
		if "sala_física01.tscn" in cena_lower or "sala_fisica01.tscn" in cena_lower:
			return 2
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
	var cena_file = cena_lower.get_file()
	var masmorra_da_cena = get_masmorra_da_cena(cena_atual)
	
	# garante percurso da mesma materia
	if masmorra_da_cena != "" and get_masmorra_do_percurso() != masmorra_da_cena:
		print("[DungeonGenerator] get_proxima_sala: Matéria incompatível. Regenerando para: ", masmorra_da_cena)
		resetar_masmorra(masmorra_da_cena)
	
	# do corredor sempre vai pra primeira sala real (sala 01, indice 2)
	if "corredor" in cena_lower:
		if percurso_salas.size() > 2:
			indice_atual = 2
			print("[DungeonGenerator] Corredor -> Avançando para a primeira sala: ", percurso_salas[2])
			return percurso_salas[2]
		elif masmorra_da_cena == "Biologia":
			return sala_01_biologia
		elif masmorra_da_cena == "Física":
			return sala_01_fisica
		elif masmorra_da_cena == "Química":
			return sala_01
		
	# sincroniza o indice da sala atual
	if indice_atual < percurso_salas.size() and (percurso_salas[indice_atual].to_lower() == cena_lower or (cena_file != "" and percurso_salas[indice_atual].to_lower().get_file() == cena_file)):
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
		elif masmorra_da_cena == "Biologia":
			lista_completa = salas_biologia_pool
			
		for k in range(lista_completa.size()):
			if lista_completa[k].to_lower() == cena_lower:
				if k + 1 < lista_completa.size():
					print("[DungeonGenerator] Modo Teste F6: Avançando sequencialmente de %s para %s" % [cena_atual, lista_completa[k + 1]])
					return lista_completa[k + 1]
				elif masmorra_da_cena == "Química":
					return sala_boss_alquimia
				elif masmorra_da_cena == "Física":
					return sala_boss_fisica
				elif masmorra_da_cena == "Biologia":
					return "res://scenes/Salas/Estufa_Biologia/Sala_Biologia04.tscn"
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
	if "corredor" in cena_lower:
		indice_atual = 0
		return hub_geral

	# voltando da sala 1 de quimica vai pro corredor de alquimia
	if "sala01.tscn" in cena_lower or "sala_alquimia01.tscn" in cena_lower:
		if not (sala_inicial.to_lower() in percurso_salas):
			resetar_masmorra("Química")
		indice_atual = 1
		return sala_inicial

	# voltando da sala 1 de fisica vai pro corredor de fisica
	if "sala_física01.tscn" in cena_lower or "sala_fisica01.tscn" in cena_lower:
		if not (sala_inicial_fisica.to_lower() in percurso_salas):
			resetar_masmorra("Física")
		indice_atual = 1
		return sala_inicial_fisica

	# voltando da sala 1 de biologia vai pro corredor da estufa
	if "biologia01.tscn" in cena_lower:
		if not (sala_inicial_biologia.to_lower() in percurso_salas):
			resetar_masmorra("Biologia")
		indice_atual = 1
		return sala_inicial_biologia

	# volta um indice no percurso
	var cena_file = cena_lower.get_file()
	if indice_atual < percurso_salas.size() and (percurso_salas[indice_atual].to_lower() == cena_lower or (cena_file != "" and percurso_salas[indice_atual].to_lower().get_file() == cena_file)):
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
		elif masmorra_da_cena == "Biologia":
			lista_completa = salas_biologia_pool
			
		for k in range(lista_completa.size()):
			if lista_completa[k].to_lower() == cena_lower or (cena_file != "" and lista_completa[k].to_lower().get_file() == cena_file):
				if k > 0:
					return lista_completa[k - 1]
				elif masmorra_da_cena == "Química":
					return sala_inicial
				elif masmorra_da_cena == "Física":
					return sala_inicial_fisica
				elif masmorra_da_cena == "Biologia":
					return sala_inicial_biologia
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

func registrar_porta_destrancada(key: String) -> void:
	if not (key in portas_destrancadas):
		portas_destrancadas.append(key)
		print("[DungeonGenerator] Porta registrada como destrancada: ", key)

func is_porta_destrancada(key: String) -> bool:
	return key in portas_destrancadas

# retorna se a sala atual deve usar a mecânica de chave
# chama essa funcao no _ready de cada sala para setar dropar_chave_no_ultimo_monstro
func sala_usa_chave(arquivo_cena: String = "") -> bool:
	var cena = arquivo_cena
	if cena == "" and get_tree() and get_tree().current_scene:
		cena = get_tree().current_scene.scene_file_path
	if cena == "":
		return false
	var cena_lower = cena.to_lower()
	var cena_file = cena_lower.get_file()
	# busca exata no array de salas com chave
	for s in salas_com_chave:
		var s_lower = s.to_lower()
		if s_lower == cena_lower or (cena_file != "" and s_lower.get_file() == cena_file):
			return true
	return false

func is_sala_boss(arquivo_cena: String = "") -> bool:
	var cena_lower = arquivo_cena.to_lower()
	if cena_lower == "" and get_tree() and get_tree().current_scene:
		cena_lower = get_tree().current_scene.scene_file_path.to_lower()
	if "boss" in cena_lower or "fisica12" in cena_lower or "física12" in cena_lower or "biologia04" in cena_lower:
		return true
	if percurso_salas.size() > 1 and indice_atual == percurso_salas.size() - 1:
		return true
	return false

func resetar_masmorra(forcar_dungeon: String = "") -> void:
	percurso_salas.clear()
	inimigos_derrotados.clear()
	portas_destrancadas.clear()
	salas_com_chave.clear()
	tier_override.clear()
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
	
	# coloca o hub no inicio (indice 0)
	percurso_salas.append(hub_geral)
	
	if active == "Física":
		# comeca no corredor de fisica (indice 1)
		percurso_salas.append(sala_inicial_fisica)
		# sala 01 (indice 2)
		percurso_salas.append(sala_01_fisica)
		
		# sorteia 6 salas do meio sem repetir
		var intermediarias = salas_fisica_pool.duplicate()
		intermediarias.shuffle()
		var salas_intermediarias_escolhidas: Array = []
		for i in range(min(6, intermediarias.size())):
			percurso_salas.append(intermediarias[i])
			salas_intermediarias_escolhidas.append(intermediarias[i])
		
		# ultima sala: boss robo
		percurso_salas.append(sala_boss_fisica)
		
		# sorteia 2 salas intermediárias para ter mecânica de chave
		_sortear_salas_com_chave(salas_intermediarias_escolhidas, 2)
		print("[DungeonGenerator] Masmorra de Física gerada com %d salas. Salas com chave: %s" % [percurso_salas.size() - 1, str(salas_com_chave)])
	elif active == "Química":
		# andar de quimica com progressão ordenada:
		# Corredor -> 3 azuis (Sala 01 fixa + 2 intermediárias azuis) -> 2 verdes -> 2 vermelhas -> Boss
		percurso_salas.append(sala_inicial)
		percurso_salas.append(sala_01)
		
		var salas_candidatas_chave: Array = [sala_01]
		
		# --- TIER 1: 2 salas azuis (sala_01 já é a 1ª azul, totalizando 3 azuis na run) ---
		var pool_azul = salas_alquimia_tier1.duplicate()
		pool_azul.shuffle()
		var qtd_azul = min(2, pool_azul.size())
		for i in range(qtd_azul):
			percurso_salas.append(pool_azul[i])
			salas_candidatas_chave.append(pool_azul[i])
		
		# --- TIER 2: 2 salas verdes nativas (Sala 04 e Sala 05) ---
		var pool_verde = salas_alquimia_tier2.duplicate()
		pool_verde.shuffle()
		var qtd_verde = min(2, pool_verde.size())
		for i in range(qtd_verde):
			percurso_salas.append(pool_verde[i])
			salas_candidatas_chave.append(pool_verde[i])
		
		# --- TIER 3: 2 salas vermelhas/laranjas nativas (Sala 06 e Sala 07) ---
		var pool_vermelho = salas_alquimia_tier3.duplicate()
		pool_vermelho.shuffle()
		var qtd_vermelho = min(2, pool_vermelho.size())
		for i in range(qtd_vermelho):
			percurso_salas.append(pool_vermelho[i])
			salas_candidatas_chave.append(pool_vermelho[i])
		
		# ultima sala: boss slime
		percurso_salas.append(sala_boss_alquimia)
		
		# sorteia exatamente 2 salas para ter mecânica de chave
		_sortear_salas_com_chave(salas_candidatas_chave, 2)
		print("[DungeonGenerator] Masmorra de Química gerada com progressão: 3 azuis -> 2 verdes -> 2 vermelhas -> Boss")
		print("[DungeonGenerator] Percurso: %s" % str(percurso_salas))
		print("[DungeonGenerator] Salas com chave: %s" % str(salas_com_chave))
	elif active == "Biologia":
		# andar de biologia (Estufa)
		percurso_salas.append(sala_inicial_biologia)
		percurso_salas.append(sala_01_biologia)
		var salas_bio_inter: Array = [
			"res://scenes/Salas/Estufa_Biologia/Sala_Biologia02.tscn",
			"res://scenes/Salas/Estufa_Biologia/Sala_Biologia03.tscn"
		]
		for s in salas_bio_inter:
			percurso_salas.append(s)
		percurso_salas.append("res://scenes/Salas/Estufa_Biologia/Sala_Biologia04.tscn")
		
		# sorteia 2 salas intermediárias para ter mecânica de chave
		# inclui sala_01 nas candidatas (não é corredor nem boss)
		var candidatas_bio: Array = [sala_01_biologia]
		candidatas_bio.append_array(salas_bio_inter)
		_sortear_salas_com_chave(candidatas_bio, 2)
		print("[DungeonGenerator] Masmorra de Biologia gerada com %d salas. Salas com chave: %s" % [percurso_salas.size() - 1, str(salas_com_chave)])
	else:
		print("[DungeonGenerator] Nenhuma expedição ativa (Aguardando escolha de porta no Hub).")

# sorteia N salas de uma lista para terem a mecânica de chave
func _sortear_salas_com_chave(candidatas: Array, quantidade: int) -> void:
	var pool = candidatas.duplicate()
	pool.shuffle()
	var qtd = min(quantidade, pool.size())
	for i in range(qtd):
		salas_com_chave.append(pool[i])
	print("[DungeonGenerator] Salas sorteadas para mecânica de chave: ", salas_com_chave)

# retorna o tier de override para a sala (0 = sem override, usa nativo)
func get_tier_override(arquivo_cena: String = "") -> int:
	var cena = arquivo_cena
	if cena == "" and get_tree() and get_tree().current_scene:
		cena = get_tree().current_scene.scene_file_path
	if cena == "":
		return 0
	# busca exata
	if tier_override.has(cena):
		return tier_override[cena]
	# busca case-insensitive
	for key in tier_override:
		if key.to_lower() == cena.to_lower():
			return tier_override[key]
	return 0


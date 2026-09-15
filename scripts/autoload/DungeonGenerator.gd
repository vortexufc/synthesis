extends Node

var hub_geral = "res://scenes/Salas/Comum/Hub_Geral.tscn"
var sala_inicial = "res://scenes/Salas/Salas_Quimica/Salas_Ativas/Corredor.tscn"
var sala_01 = "res://scenes/Salas/Salas_Quimica/Salas_Ativas/Sala_Alquimia01.tscn"
var sala_boss_alquimia = "res://scenes/Salas/Salas_Quimica/Salas_Ativas/Sala_BossAlquimia.tscn"

# Pools organizadas por dificuldade TRI do ENEM para o Andar de Química (Limite de 8 salas):
# 3 Fáceis (Slime Azul) + 2 Médias (Slime Verde) + 2 Difíceis (Slime Laranja) + 1 Boss Final (Slime Grandão Roxo)
var salas_quimica_faceis: Array = [
	"res://scenes/Salas/Salas_Quimica/Salas_Ativas/Sala_Alquimia01.tscn",
	"res://scenes/Salas/Salas_Quimica/Salas_Ativas/Sala_Alquimia02.tscn",
	"res://scenes/Salas/Salas_Quimica/Salas_Ativas/Sala_Alquimia03.tscn"
]

var salas_quimica_medias: Array = [
	"res://scenes/Salas/Salas_Quimica/Salas_Ativas/Sala_Alquimia04.tscn",
	"res://scenes/Salas/Salas_Quimica/Salas_Ativas/Sala_Alquimia05.tscn"
]

var salas_quimica_dificeis: Array = [
	"res://scenes/Salas/Salas_Quimica/Salas_Ativas/Sala_Alquimia06.tscn",
	"res://scenes/Salas/Salas_Quimica/Salas_Ativas/Sala_Alquimia07.tscn"
]

# Pool completa com as 8 salas ativas de Química (7 normais + 1 boss final)
var salas_alquimia: Array = [
	"res://scenes/Salas/Salas_Quimica/Salas_Ativas/Sala_Alquimia01.tscn",
	"res://scenes/Salas/Salas_Quimica/Salas_Ativas/Sala_Alquimia02.tscn",
	"res://scenes/Salas/Salas_Quimica/Salas_Ativas/Sala_Alquimia03.tscn",
	"res://scenes/Salas/Salas_Quimica/Salas_Ativas/Sala_Alquimia04.tscn",
	"res://scenes/Salas/Salas_Quimica/Salas_Ativas/Sala_Alquimia05.tscn",
	"res://scenes/Salas/Salas_Quimica/Salas_Ativas/Sala_Alquimia06.tscn",
	"res://scenes/Salas/Salas_Quimica/Salas_Ativas/Sala_Alquimia07.tscn",
	"res://scenes/Salas/Salas_Quimica/Salas_Ativas/Sala_BossAlquimia.tscn"
]

# Pool das 12 salas de Física
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

# O percurso completo gerado para a corrida atual
var percurso_salas: Array = []

# Rastreia numericamente onde o jogador está para evitar bugs com salas duplicadas
var indice_atual: int = 0

# Diz se o jogador acabou de voltar para a sala anterior
var vindo_de_porta_de_retorno: bool = false

# Guarda qual masmorra o jogador estava explorando antes de retornar ao Hub
var masmorra_retorno_hub: String = ""

# Flag que indica se deve reproduzir a cutscene de introdução no Hub
var tocar_cutscene_inicial: bool = false

# Array contendo identificadores de inimigos derrotados nesta masmorra
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
	
	# Se a cena informada pertence a uma masmorra e o percurso atual é de outra matéria,
	# regenera o percurso para a matéria correta antes de qualquer indexação!
	if masmorra_da_cena != "" and get_masmorra_do_percurso() != masmorra_da_cena:
		print("[DungeonGenerator] Cena fora do percurso (%s). Regenerando percurso para %s..." % [cena, masmorra_da_cena])
		resetar_masmorra(masmorra_da_cena)
		
	for i in range(percurso_salas.size()):
		if percurso_salas[i].to_lower() == cena_lower:
			return i
			
	# Mapeamento de equivalências para nomes de sala e protótipos (apenas dentro da mesma matéria!)
	var masmorra_atual = get_masmorra_do_percurso()
	if masmorra_atual == "Química":
		if "sala01.tscn" in cena_lower or "sala_alquimia01.tscn" in cena_lower or "sala_alquimia13.tscn" in cena_lower:
			return 1
		if "sala_alquimia08.tscn" in cena_lower or "boss" in cena_lower:
			return percurso_salas.size() - 1
	elif masmorra_atual == "Física":
		if "sala_física01.tscn" in cena_lower or "sala_fisica01.tscn" in cena_lower:
			return 1
		if "fisica12" in cena_lower or "física12" in cena_lower or "boss" in cena_lower:
			return percurso_salas.size() - 1
				
	return -1

func get_proxima_sala(arquivo_cena_atual: String = "") -> String:
	var cena_atual = arquivo_cena_atual
	if cena_atual == "" and get_tree().current_scene:
		cena_atual = get_tree().current_scene.scene_file_path
		
	var cena_lower = cena_atual.to_lower()
	var masmorra_da_cena = get_masmorra_da_cena(cena_atual)
	
	# Garante que percurso_salas seja estritamente da mesma matéria da cena de onde o jogador está saindo
	if masmorra_da_cena != "" and get_masmorra_do_percurso() != masmorra_da_cena:
		print("[DungeonGenerator] get_proxima_sala: Matéria incompatível. Regenerando para: ", masmorra_da_cena)
		resetar_masmorra(masmorra_da_cena)
	
	# Se a cena atual for o Corredor de Química, a próxima sala é sempre a primeira sala ativa (índice 1)
	if "corredor.tscn" in cena_lower:
		if percurso_salas.size() > 1:
			indice_atual = 1
			print("[DungeonGenerator] Corredor -> Avançando para a primeira sala: ", percurso_salas[1])
			return percurso_salas[1]
		
	# Proteção para manter sincronia: se o índice atual bate com a cena onde o player está
	if indice_atual < percurso_salas.size() and percurso_salas[indice_atual].to_lower() == cena_lower:
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
		
	var cena_lower = cena_atual.to_lower()
	var masmorra_da_cena = get_masmorra_da_cena(cena_atual)
	
	# Identifica a matéria da sala de onde estamos voltando
	if masmorra_da_cena != "":
		masmorra_retorno_hub = masmorra_da_cena
		if get_node_or_null("/root/DatabaseManager"):
			DatabaseManager.active_dungeon = masmorra_da_cena
		if get_masmorra_do_percurso() != masmorra_da_cena:
			resetar_masmorra(masmorra_da_cena)

	# Se estiver no Corredor e voltar, vai sempre para o Hub Geral
	if "corredor.tscn" in cena_lower:
		indice_atual = 0
		return hub_geral

	# Se estiver na Sala 01 de Química e voltar, vai sempre para o Corredor
	if "sala01.tscn" in cena_lower or "sala_alquimia01.tscn" in cena_lower or "sala_alquimia13.tscn" in cena_lower:
		if not (sala_inicial.to_lower() in percurso_salas):
			resetar_masmorra("Química")
		indice_atual = 1
		return sala_inicial

	# Se estiver na Sala 01 de Física e voltar, vai sempre para o Hub Geral
	if "sala_física01.tscn" in cena_lower or "sala_fisica01.tscn" in cena_lower:
		indice_atual = 0
		return hub_geral

	# Sincronia de índice para o retorno seguro pelas portas
	if indice_atual < percurso_salas.size() and percurso_salas[indice_atual].to_lower() == cena_lower:
		print("[DungeonGenerator] Retorno sincronizado no índice: ", indice_atual)
	else:
		indice_atual = get_index_da_cena(cena_atual)
		
	print("[DungeonGenerator] Tentando VOLTAR de: ", cena_atual, " | Index atual: ", indice_atual)
	
	if indice_atual > 0:
		indice_atual -= 1
		return percurso_salas[indice_atual]
		
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
	
	var active = "Química"
	if forcar_dungeon != "":
		active = forcar_dungeon
		masmorra_retorno_hub = forcar_dungeon
		if get_node_or_null("/root/DatabaseManager"):
			DatabaseManager.active_dungeon = forcar_dungeon
	elif get_node_or_null("/root/DatabaseManager") and DatabaseManager.active_dungeon != "":
		active = DatabaseManager.active_dungeon
		masmorra_retorno_hub = active
	else:
		masmorra_retorno_hub = "Química"
		if get_node_or_null("/root/DatabaseManager"):
			DatabaseManager.active_dungeon = "Química"
	
	# 1. Injeta a sequência fixa do Hub nas primeiras posições
	percurso_salas.append(hub_geral)
	
	if active == "Física":
		# Sala 01 de Física é fixa no início do percurso (conectada diretamente ao Hub)
		percurso_salas.append("res://scenes/Salas/Sala_Fisica/Sala_Física01.tscn")
		
		# Salas intermediárias (02 a 11) embaralhadas
		var intermediarias = [
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
		intermediarias.shuffle()
		percurso_salas.append_array(intermediarias)
		
		# Sala 12 final com o Boss Robô
		percurso_salas.append("res://scenes/Salas/Sala_Fisica/Sala_Física12.tscn")
		print("[DungeonGenerator] Masmorra de Física gerada com ", percurso_salas.size(), " salas (Sala 01 -> intermediárias -> Boss 12).")
	else:
		# Padrão: Química (Alquimia)
		# Estrutura de 8 salas no andar (7 normais + 1 boss final) conforme TRI:
		# 1. Três primeiras salas: Questões Fáceis (Slime Azul)
		# Fixa a sala_01 na primeira posição (conectada à porta do Corredor) e adiciona as outras fáceis
		percurso_salas.append(sala_01)
		var outras_faceis = [
			"res://scenes/Salas/Salas_Quimica/Salas_Ativas/Sala_Alquimia02.tscn",
			"res://scenes/Salas/Salas_Quimica/Salas_Ativas/Sala_Alquimia03.tscn"
		]
		outras_faceis.shuffle()
		percurso_salas.append_array(outras_faceis)
		
		# 2. Duas salas intermediárias: Questões Médias (Slime Verde)
		var medias = salas_quimica_medias.duplicate()
		medias.shuffle()
		percurso_salas.append_array(medias)
		
		# 3. Duas salas avançadas: Questões Difíceis (Slime Laranja)
		var dificeis = salas_quimica_dificeis.duplicate()
		dificeis.shuffle()
		percurso_salas.append_array(dificeis)
		
		# 4. Sala Final: Desafio do Boss (Slime Grandão Roxo)
		percurso_salas.append(sala_boss_alquimia)
		print("[DungeonGenerator] Masmorra de Química gerada com exatamente ", percurso_salas.size() - 1, " salas (7 normais + 1 boss).")

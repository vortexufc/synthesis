extends Node

const RANKING_FILE = "user://ranking.json"

var ranking_geral: Array = []
var ranking_clas: Array = []

func _ready():
	load_ranking()

# ---- SALVAMENTO E CARREGAMENTO LOCAL ----
func load_ranking() -> void:
	if not FileAccess.file_exists(RANKING_FILE):
		# Cria dados fictícios padrão para não ficar vazio no início
		_criar_ranking_padrao()
		return
		
	var file = FileAccess.open(RANKING_FILE, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	# [Wipe Force] Se o arquivo contém os nomes antigos, apaga tudo e salva limpo
	if content.contains("Rafael_Ivo"):
		_criar_ranking_padrao()
		return
	
	var json = JSON.new()
	if json.parse(content) == OK:
		var data = json.data
		if typeof(data) == TYPE_DICTIONARY:
			ranking_geral = data.get("geral", [])
			ranking_clas = data.get("clas", [])
			return
			
	# Se deu erro no parse, reseta para padrão
	_criar_ranking_padrao()

func save_ranking() -> void:
	var data = {
		"geral": ranking_geral,
		"clas": ranking_clas
	}
	var file = FileAccess.open(RANKING_FILE, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

# ---- ATUALIZAR PONTUAÇÕES ----
func add_score(player_name: String, cla: String, score: int) -> void:
	# Atualiza o ranking geral
	var novo_dado_geral = {"name": player_name, "score": score}
	ranking_geral.append(novo_dado_geral)
	
	# Ordena do maior pro menor
	ranking_geral.sort_custom(func(a, b): return a["score"] > b["score"])
	
	# Limita ao Top 10 pra não estourar arquivo
	if ranking_geral.size() > 10:
		ranking_geral.resize(10)
		
	# Atualiza ranking de Clãs (soma pontos para a equipe)
	_update_cla_score(cla, score)
	
	# Sincroniza com a persistência de clãs se existir o singleton
	if has_node("/root/ClanManager"):
		get_node("/root/ClanManager").adicionar_pontos_cla(cla, player_name, score)
	
	save_ranking()

func _update_cla_score(cla: String, score: int) -> void:
	# Ignora se não tiver clã
	if cla == "" or cla == "Nenhum":
		return
		
	var achou = false
	for c in ranking_clas:
		if c["name"] == cla:
			c["score"] += score
			achou = true
			break
			
	if not achou:
		ranking_clas.append({"name": cla, "score": score})
		
	# Ordena do maior pro menor
	ranking_clas.sort_custom(func(a, b): return a["score"] > b["score"])

func _criar_ranking_padrao() -> void:
	ranking_geral = []
	ranking_clas = []
	save_ranking()

# ---- SISTEMA DE JOGADOR OFFLINE (GUEST) ----
const GUEST_FILE = "user://guest_config.json"
var local_guest_nick: String = ""

func get_local_nick() -> String:
	if local_guest_nick != "":
		return local_guest_nick
		
	# Tenta ler o nick salvo na máquina
	if FileAccess.file_exists(GUEST_FILE):
		var file = FileAccess.open(GUEST_FILE, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		if json.parse(content) == OK and typeof(json.data) == TYPE_DICTIONARY:
			if json.data.has("guest_nick"):
				local_guest_nick = json.data["guest_nick"]
				return local_guest_nick
				
	# Se nunca jogou neste PC/Celular, cria um nick permanente de visitante
	randomize()
	local_guest_nick = "Mago_" + str(randi() % 9000 + 1000) # Ex: Mago_4821
	
	# Salva para sempre neste dispositivo
	var file_out = FileAccess.open(GUEST_FILE, FileAccess.WRITE)
	file_out.store_string(JSON.stringify({"guest_nick": local_guest_nick}))
	file_out.close()
	
	return local_guest_nick

func fundir_conta_guest(nick_real: String, cla_real: String) -> void:
	if local_guest_nick == "":
		get_local_nick() # Puxa o nick visitante dessa máquina
		
	var salvou = false
	
	# Varre o ranking atrás dos pontos antigos do Guest e transfere pro novo Nick Oficial
	for item in ranking_geral:
		if item["name"] == local_guest_nick:
			item["name"] = nick_real
			salvou = true
			
	# Atualiza o Clã
	if cla_real != "" and cla_real != "Nenhum":
		for item in ranking_geral:
			if item["name"] == nick_real:
				_update_cla_score(cla_real, item["score"])
				
	if salvou:
		save_ranking()
		
	# [Segurança] Mata o Guest atual para o usuário não abusar duplicando a conta!
	local_guest_nick = ""
	if FileAccess.file_exists(GUEST_FILE):
		DirAccess.remove_absolute(GUEST_FILE)

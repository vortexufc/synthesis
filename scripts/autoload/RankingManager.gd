extends Node

# ranking dos jogadores online

signal ranking_atualizado

var ranking_geral: Array = []   # [{ "name": "Andin", "score": 1500 }, ...]
var ranking_clas: Array = []    # populado pelo ClanManager via get_top_clans()
var ranking_diario: Array = []   # score_diario
var ranking_semanal: Array = [] # score_semanal
var ranking_mensal: Array = []  # score_mensal

# salva offline se tiver sem net
const RANKING_FILE = "user://ranking.json"
const PENDING_SYNC_FILE = "user://pending_sync.json"

# dados de conta de visitante
const GUEST_FILE = "user://guest_config.json"
var local_guest_nick: String = ""

func _ready() -> void:
	await get_tree().create_timer(0.3).timeout
	await load_ranking()
	await load_ranking_periodo("quimica")
	await load_ranking_periodo("fisica")
	await load_ranking_periodo("biologia")

# busca o ranking no supabase
func load_ranking() -> void:
	print("[RankingManager] Buscando ranking online...")
	var res = await DatabaseManager.request_async(
		"/rest/v1/rankinggeral?select=*&order=score.desc&limit=20",
		HTTPClient.METHOD_GET
	)

	print("[RankingManager] Resposta: success=%s | code=%s" % [res["success"], res.get("code", "?")])

	if res["success"] and res["data"] is Array:
		# se deu certo, aproveita pra mandar as pontuacoes pendentes
		if not DatabaseManager.user_token.is_empty():
			await sync_pending_scores()
			
		ranking_geral = []
		for row in res["data"]:
			ranking_geral.append({
				"name": row.get("player_name", "?"),
				"score": int(row.get("score", 0)),
				"score_diario": int(row.get("score_diario", 0)),
				"score_semanal": int(row.get("score_semanal", 0)),
				"score_mensal": int(row.get("score_mensal", 0)),
				"insignias": row.get("insignias", [])
			})
		
		# poe o visitante local na lista pra aparecer na tela
		_injetar_guest_no_ranking()
		
		ranking_atualizado.emit()
		print("[RankingManager] Ranking online: %d players (incl. guest)." % ranking_geral.size())
	else:
		# se der erro carrega do arquivo local
		print("[RankingManager] ERRO: %s — usando cache local." % res.get("message", "sem detalhes"))
		_carregar_local()

# busca rankings por periodo
func load_ranking_periodo(periodo: String) -> void:
	var coluna: String
	match periodo:
		"quimica":  coluna = "score_diario"
		"fisica": coluna = "score_semanal"
		"biologia":  coluna = "score_mensal"
		_: return
	
	var res = await DatabaseManager.request_async(
		"/rest/v1/rankinggeral?select=*&order=%s.desc&limit=20" % coluna,
		HTTPClient.METHOD_GET
	)
	if not (res["success"] and res["data"] is Array):
		return
	
	var lista: Array = []
	for row in res["data"]:
		var pts = int(row.get(coluna, 0))
		if pts > 0:
			lista.append({
				"name": row.get("player_name", "?"),
				"score": pts,
				"score_diario": int(row.get("score_diario", 0)),
				"score_semanal": int(row.get("score_semanal", 0)),
				"score_mensal": int(row.get("score_mensal", 0)),
				"insignias": row.get("insignias", [])
			})
	
	match periodo:
		"quimica":  ranking_diario  = lista
		"fisica": ranking_semanal = lista
		"biologia":  ranking_mensal  = lista
	
	ranking_atualizado.emit()
	
# pega o ranking pelo periodo
func get_ranking_por_periodo(periodo: String) -> Array:
	match periodo:
		"quimica":  return ranking_diario
		"fisica": return ranking_semanal
		"biologia":  return ranking_mensal
		_: return ranking_geral

# salva ou atualiza a pontuacao
func add_score(player_name: String, cla: String, pontos: int) -> void:
	if player_name.is_empty():
		return

	# salva no banco se tiver logado
	if not DatabaseManager.user_token.is_empty():
		var success = await _upsert_score_online(player_name, pontos)
		if success:
			# se enviou, tenta mandar os pendentes
			await sync_pending_scores()
		else:
			# se der erro salva local e poe na fila
			_add_pending_score(player_name, pontos)
			_add_score_local(player_name, pontos)
	else:
		# offline: salva so no arquivo local
		_add_score_local(player_name, pontos)

	# atualiza os pontos do cla
	if not cla.is_empty() and cla != "Nenhum" and not DatabaseManager.user_token.is_empty():
		if ClanManager.has_method("adicionar_pontos_cla"):
			await ClanManager.adicionar_pontos_cla(cla, player_name, pontos)

	# recarrega a lista
	await load_ranking()

func _upsert_score_online(player_name: String, pontos_novos: int) -> bool:
	# ve quanto o player ja tem no banco
	var end_player = "/rest/v1/rankinggeral?player_name=eq." + player_name.uri_encode() + "&select=*"
	var res = await DatabaseManager.request_async(end_player, HTTPClient.METHOD_GET)

	if not res["success"]:
		print("[RankingManager] Erro ao buscar score online de %s. Possivelmente offline." % player_name)
		return false

	var score_atual: int = 0
	var score_diario_atual: int = 0
	var score_semanal_atual: int = 0
	var score_mensal_atual: int = 0
	var existe: bool = false

	if res["data"] is Array and res["data"].size() > 0:
		var row = res["data"][0]
		score_atual         = int(row.get("score", 0))
		score_diario_atual  = int(row.get("score_diario", 0))
		score_semanal_atual = int(row.get("score_semanal", 0))
		score_mensal_atual  = int(row.get("score_mensal", 0))
		existe = true

	var subj = ""
	if "active_dungeon" in DatabaseManager:
		subj = DatabaseManager.active_dungeon
		
	var novo_score:         int = score_atual + pontos_novos
	var novo_score_diario:  int = score_diario_atual + (pontos_novos if subj == "Química" else 0)
	var novo_score_semanal: int = score_semanal_atual + (pontos_novos if subj == "Física" else 0)
	var novo_score_mensal:  int = score_mensal_atual + (pontos_novos if subj == "Biologia" else 0)
	var res_update: Dictionary

	if existe:
		# se ja existe atualiza
		res_update = await DatabaseManager.request_async(
			"/rest/v1/rankinggeral?player_name=eq." + player_name.uri_encode(),
			HTTPClient.METHOD_PATCH,
			{"score": novo_score, "score_diario": novo_score_diario,
			 "score_semanal": novo_score_semanal, "score_mensal": novo_score_mensal,
			 "updated_at": "now()"}
		)
	else:
		# senao cria novo registro
		res_update = await DatabaseManager.request_async(
			"/rest/v1/rankinggeral",
			HTTPClient.METHOD_POST,
			{"player_name": player_name, "score": novo_score,
			 "score_diario": novo_score_diario, "score_semanal": novo_score_semanal,
			 "score_mensal": novo_score_mensal}
		)

	if res_update["success"]:
		print("[RankingManager] Score online de '%s' atualizado para %d." % [player_name, novo_score])
		return true
	else:
		print("[RankingManager] Erro ao salvar score online de %s." % player_name)
		return false

# funcoes de cache local
func _add_score_local(player_name: String, pontos: int) -> void:
	# abre o json local
	var local_data = {"geral": []}
	if FileAccess.file_exists(RANKING_FILE):
		var file_r = FileAccess.open(RANKING_FILE, FileAccess.READ)
		var content = file_r.get_as_text()
		file_r.close()
		var json = JSON.new()
		if json.parse(content) == OK and typeof(json.data) == TYPE_DICTIONARY:
			local_data = json.data

	# acha o player e atualiza os pontos
	var list_geral = local_data.get("geral", [])
	var score_atual = 0
	var achou_no_arquivo = false
	for item in list_geral:
		if item.get("name", "") == player_name:
			score_atual = int(item.get("score", 0))
			item["score"] = score_atual + pontos
			achou_no_arquivo = true
			break
	if not achou_no_arquivo:
		list_geral.append({"name": player_name, "score": pontos})

	local_data["geral"] = list_geral

	# salva no arquivo
	var file_w = FileAccess.open(RANKING_FILE, FileAccess.WRITE)
	if file_w:
		file_w.store_string(JSON.stringify(local_data, "\t"))
		file_w.close()

	# reordena a lista na memoria
	var achou_na_memoria = false
	var novo_score = score_atual + pontos
	for item in ranking_geral:
		if item["name"] == player_name:
			item["score"] = novo_score
			achou_na_memoria = true
			break
	if not achou_na_memoria:
		ranking_geral.append({"name": player_name, "score": novo_score})

	ranking_geral.sort_custom(func(a, b): return a["score"] > b["score"])
	ranking_atualizado.emit()

func _ler_score_guest_local(player_name: String) -> int:
	if not FileAccess.file_exists(RANKING_FILE):
		return 0
	var file = FileAccess.open(RANKING_FILE, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(content) == OK and typeof(json.data) == TYPE_DICTIONARY:
		for item in json.data.get("geral", []):
			if item.get("name", "") == player_name:
				return int(item.get("score", 0))
	return 0

func _remover_player_local(player_name: String) -> void:
	if not FileAccess.file_exists(RANKING_FILE):
		return
	var file = FileAccess.open(RANKING_FILE, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(content) == OK and typeof(json.data) == TYPE_DICTIONARY:
		var geral = json.data.get("geral", [])
		var novo_geral = []
		for item in geral:
			if item.get("name", "") != player_name:
				novo_geral.append(item)
		json.data["geral"] = novo_geral
		var file_w = FileAccess.open(RANKING_FILE, FileAccess.WRITE)
		if file_w:
			file_w.store_string(JSON.stringify(json.data, "\t"))
			file_w.close()

func _injetar_guest_no_ranking() -> void:
	# se nao tem visitante ignora
	var nick_guest = get_local_nick()
	if nick_guest.is_empty():
		return
	
	# se ja ta logado nao precisa de visitante
	if not DatabaseManager.user_token.is_empty():
		return
	
	# le os pontos salvos do visitante
	var score_guest = _ler_score_guest_local(nick_guest)
	if score_guest <= 0:
		return
	
	# adiciona o visitante na lista
	for item in ranking_geral:
		if item["name"] == nick_guest:
			return # já está
	
	ranking_geral.append({"name": nick_guest, "score": score_guest})
	ranking_geral.sort_custom(func(a, b): return a["score"] > b["score"])

func _salvar_local() -> void:
	var data = {"geral": ranking_geral}
	var file = FileAccess.open(RANKING_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func _carregar_local() -> void:
	if not FileAccess.file_exists(RANKING_FILE):
		ranking_geral = []
		return

	var file = FileAccess.open(RANKING_FILE, FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(content) == OK and typeof(json.data) == TYPE_DICTIONARY:
		ranking_geral = json.data.get("geral", [])
	else:
		ranking_geral = []

	ranking_atualizado.emit()

# fila de pontuacoes pendentes pra sincronizar
func _add_pending_score(player_name: String, pontos: int) -> void:
	var pending = _load_pending_scores()
	var current = pending.get(player_name, 0)
	pending[player_name] = current + pontos
	_save_pending_scores(pending)
	print("[RankingManager] %d pontos salvos como pendentes para %s." % [pontos, player_name])

func _load_pending_scores() -> Dictionary:
	if not FileAccess.file_exists(PENDING_SYNC_FILE):
		return {}
	var file = FileAccess.open(PENDING_SYNC_FILE, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(content) == OK and json.data is Dictionary:
		return json.data
	return {}

func _save_pending_scores(pending: Dictionary) -> void:
	var file = FileAccess.open(PENDING_SYNC_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(pending, "\t"))
		file.close()

func sync_pending_scores() -> void:
	if DatabaseManager.user_token.is_empty():
		return # Não pode sincronizar se não estiver logado

	var pending = _load_pending_scores()
	if pending.is_empty():
		return

	print("[RankingManager] Tentando sincronizar pontos pendentes: ", pending)
	var players_to_remove = []
	for player_name in pending.keys():
		var pontos = pending[player_name]
		if pontos <= 0:
			players_to_remove.append(player_name)
			continue
		
		var success = await _upsert_score_online(player_name, pontos)
		if success:
			players_to_remove.append(player_name)
		else:
			# se der erro para pra nao travar
			print("[RankingManager] Sincronização falhou. Parando por enquanto.")
			break

	# tira os que ja sincronizou
	var changed = false
	for player in players_to_remove:
		pending.erase(player)
		changed = true

	if changed:
		_save_pending_scores(pending)

# controle da conta de convidado
func get_local_nick() -> String:
	if local_guest_nick != "":
		return local_guest_nick

	if FileAccess.file_exists(GUEST_FILE):
		var file_read = FileAccess.open(GUEST_FILE, FileAccess.READ)
		var content = file_read.get_as_text()
		file_read.close()
		var json = JSON.new()
		if json.parse(content) == OK and typeof(json.data) == TYPE_DICTIONARY:
			if json.data.has("guest_nick"):
				local_guest_nick = json.data["guest_nick"]
				return local_guest_nick

	# id do visitante pra este pc
	randomize()
	local_guest_nick = "Mago_" + str(randi() % 9000 + 1000)
	var file = FileAccess.open(GUEST_FILE, FileAccess.WRITE)
	file.store_string(JSON.stringify({"guest_nick": local_guest_nick}))
	file.close()

	return local_guest_nick

# passa os pontos do visitante pra conta oficial no login
func fundir_conta_guest(nick_real: String, cla_real: String) -> void:
	if local_guest_nick == "":
		get_local_nick()

	if local_guest_nick.is_empty():
		return

	# le o score do json local
	var score_acumulado: int = _ler_score_guest_local(local_guest_nick)

	if score_acumulado > 0:
		print("[RankingManager] Migrando %d pts de '%s' para '%s'..." % [score_acumulado, local_guest_nick, nick_real])
		
		# manda pro supabase com o nick da conta
		var success = await _upsert_score_online(nick_real, score_acumulado)

		if not success:
			# se der erro poe na fila sob o nick real
			_add_pending_score(nick_real, score_acumulado)
			# e salva local com o nick novo
			_add_score_local(nick_real, score_acumulado)

		# atualiza os pontos do cla
		if not cla_real.is_empty() and cla_real != "Nenhum":
			if ClanManager.has_method("adicionar_pontos_cla"):
				await ClanManager.adicionar_pontos_cla(cla_real, nick_real, score_acumulado)

	# remove o visitante do arquivo
	_remover_player_local(local_guest_nick)

	# limpa o visitante pra nao duplicar
	if FileAccess.file_exists(GUEST_FILE):
		DirAccess.remove_absolute(GUEST_FILE)
	local_guest_nick = ""

	await load_ranking()

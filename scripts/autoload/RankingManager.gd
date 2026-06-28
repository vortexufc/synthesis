extends Node

# ============================================================
# RankingManager — Ranking de Players Online (Supabase)
# Segue o mesmo padrão do ClanManager.gd para consistência.
# ============================================================

signal ranking_atualizado

var ranking_geral: Array = []   # [{ "name": "Andin", "score": 1500 }, ...]
var ranking_clas: Array = []    # populado pelo ClanManager via get_top_clans()

# ---- ARQUIVO LOCAL (Fallback offline) ----
const RANKING_FILE = "user://ranking.json"
const PENDING_SYNC_FILE = "user://pending_sync.json"

# ---- CONTA VISITANTE (Guest) ----
const GUEST_FILE = "user://guest_config.json"
var local_guest_nick: String = ""

func _ready() -> void:
	await get_tree().create_timer(0.3).timeout
	await load_ranking()

# ============================================================
# CARREGAR DO SUPABASE
# ============================================================
func load_ranking() -> void:
	print("[RankingManager] Buscando ranking online...")
	var res = await DatabaseManager.request_async(
		"/rest/v1/rankinggeral?select=*&order=score.desc&limit=20",
		HTTPClient.METHOD_GET
	)

	print("[RankingManager] Resposta: success=%s | code=%s" % [res["success"], res.get("code", "?")])

	if res["success"] and res["data"] is Array:
		# Se a requisição teve sucesso, significa que temos internet!
		# Tenta sincronizar qualquer pontuação pendente antes de reconstruir o ranking
		if not DatabaseManager.user_token.is_empty():
			await sync_pending_scores()
			
		ranking_geral = []
		for row in res["data"]:
			ranking_geral.append({
				"name": row.get("player_name", "?"),
				"score": int(row.get("score", 0))
			})
		
		# Injeta o score do visitante local para ele aparecer no ranking
		# mesmo sem ter conta, junto com os players online!
		_injetar_guest_no_ranking()
		
		ranking_atualizado.emit()
		print("[RankingManager] Ranking online: %d players (incl. guest)." % ranking_geral.size())
	else:
		# Supabase falhou → carrega o cache local como fallback
		print("[RankingManager] ERRO: %s — usando cache local." % res.get("message", "sem detalhes"))
		_carregar_local()

# ============================================================
# SALVAR / ATUALIZAR PONTUAÇÃO DO PLAYER
# ============================================================
func add_score(player_name: String, cla: String, pontos: int) -> void:
	if player_name.is_empty():
		return

	# --- ONLINE: Upsert no Supabase se estiver logado ---
	if not DatabaseManager.user_token.is_empty():
		var success = await _upsert_score_online(player_name, pontos)
		if success:
			# Se conseguiu, tenta sincronizar outros pendentes
			await sync_pending_scores()
		else:
			# Se falhou, salva como pendente e no ranking local
			_add_pending_score(player_name, pontos)
			_add_score_local(player_name, pontos)
	else:
		# --- OFFLINE: só salva localmente ---
		_add_score_local(player_name, pontos)

	# Atualiza os pontos do clã (já feito pelo ClanManager quando ativo)
	if not cla.is_empty() and cla != "Nenhum" and not DatabaseManager.user_token.is_empty():
		if ClanManager.has_method("adicionar_pontos_cla"):
			await ClanManager.adicionar_pontos_cla(cla, player_name, pontos)

	# Recarrega o ranking mais recente
	await load_ranking()

func _upsert_score_online(player_name: String, pontos_novos: int) -> bool:
	# 1. Pega o score atual do player no banco
	var end_player = "/rest/v1/rankinggeral?player_name=eq." + player_name.uri_encode() + "&select=*"
	var res = await DatabaseManager.request_async(end_player, HTTPClient.METHOD_GET)

	if not res["success"]:
		print("[RankingManager] Erro ao buscar score online de %s. Possivelmente offline." % player_name)
		return false

	var score_atual: int = 0
	var existe: bool = false

	if res["data"] is Array and res["data"].size() > 0:
		score_atual = int(res["data"][0].get("score", 0))
		existe = true

	var novo_score: int = score_atual + pontos_novos
	var res_update: Dictionary

	if existe:
		# PATCH: atualiza
		res_update = await DatabaseManager.request_async(
			"/rest/v1/rankinggeral?player_name=eq." + player_name.uri_encode(),
			HTTPClient.METHOD_PATCH,
			{"score": novo_score, "updated_at": "now()"}
		)
	else:
		# POST: insere novo jogador
		res_update = await DatabaseManager.request_async(
			"/rest/v1/rankinggeral",
			HTTPClient.METHOD_POST,
			{"player_name": player_name, "score": novo_score}
		)

	if res_update["success"]:
		print("[RankingManager] Score online de '%s' atualizado para %d." % [player_name, novo_score])
		return true
	else:
		print("[RankingManager] Erro ao salvar score online de %s." % player_name)
		return false

# ============================================================
# CACHE LOCAL (Fallback + Convidados)
# ============================================================
func _add_score_local(player_name: String, pontos: int) -> void:
	# 1. Carrega todas as entradas existentes do arquivo local
	var local_data = {"geral": []}
	if FileAccess.file_exists(RANKING_FILE):
		var file_r = FileAccess.open(RANKING_FILE, FileAccess.READ)
		var content = file_r.get_as_text()
		file_r.close()
		var json = JSON.new()
		if json.parse(content) == OK and typeof(json.data) == TYPE_DICTIONARY:
			local_data = json.data

	# 2. Encontra o player e atualiza, ou adiciona se não existir
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

	# 3. Salva de volta
	var file_w = FileAccess.open(RANKING_FILE, FileAccess.WRITE)
	if file_w:
		file_w.store_string(JSON.stringify(local_data, "\t"))
		file_w.close()

	# 4. Atualiza também a memória ranking_geral e reordena
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
	# Se não há guest nesta máquina, nada a fazer
	var nick_guest = get_local_nick()
	if nick_guest.is_empty():
		return
	
	# Evita duplicar se já está logado (aí o guest sumiu)
	if not DatabaseManager.user_token.is_empty():
		return
	
	# Lê o score salvo localmente
	var score_guest = _ler_score_guest_local(nick_guest)
	if score_guest <= 0:
		return
	
	# Adiciona o guest na lista (sem duplicar)
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

# ============================================================
# FILA DE PENDÊNCIAS OFFLINE
# ============================================================
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
			# Se falhar uma vez, interrompe (provavelmente ainda sem conexão)
			print("[RankingManager] Sincronização falhou. Parando por enquanto.")
			break

	# Remove os jogadores que foram sincronizados com sucesso
	var changed = false
	for player in players_to_remove:
		pending.erase(player)
		changed = true

	if changed:
		_save_pending_scores(pending)

# ============================================================
# SISTEMA DE CONTA VISITANTE (Guest)
# ============================================================
func get_local_nick() -> String:
	if local_guest_nick != "":
		return local_guest_nick

	if FileAccess.file_exists(GUEST_FILE):
		var file = FileAccess.open(GUEST_FILE, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(content) == OK and typeof(json.data) == TYPE_DICTIONARY:
			if json.data.has("guest_nick"):
				local_guest_nick = json.data["guest_nick"]
				return local_guest_nick

	# Cria um ID permanente de visitante para este dispositivo
	randomize()
	local_guest_nick = "Mago_" + str(randi() % 9000 + 1000)
	var file = FileAccess.open(GUEST_FILE, FileAccess.WRITE)
	file.store_string(JSON.stringify({"guest_nick": local_guest_nick}))
	file.close()

	return local_guest_nick

# ============================================================
# MIGRAÇÃO: Conta Guest → Conta Oficial ao fazer Login
# ============================================================
func fundir_conta_guest(nick_real: String, cla_real: String) -> void:
	if local_guest_nick == "":
		get_local_nick()

	if local_guest_nick.is_empty():
		return

	# Lê o score diretamente do ARQUIVO LOCAL (fonte confiável)
	var score_acumulado: int = _ler_score_guest_local(local_guest_nick)

	if score_acumulado > 0:
		print("[RankingManager] Migrando %d pts de '%s' para '%s'..." % [score_acumulado, local_guest_nick, nick_real])
		
		# Envia para o Supabase com o nick oficial
		var success = await _upsert_score_online(nick_real, score_acumulado)

		if not success:
			# Se falhou, salva como pontos pendentes para o nick real!
			_add_pending_score(nick_real, score_acumulado)
			# E também adiciona localmente sob o nick real
			_add_score_local(nick_real, score_acumulado)

		# Atualiza os pontos do clã se tiver
		if not cla_real.is_empty() and cla_real != "Nenhum":
			if ClanManager.has_method("adicionar_pontos_cla"):
				await ClanManager.adicionar_pontos_cla(cla_real, nick_real, score_acumulado)

	# [Segurança] Destrói o Guest para evitar duplicação
	local_guest_nick = ""
	if FileAccess.file_exists(GUEST_FILE):
		DirAccess.remove_absolute(GUEST_FILE)
	
	# E remove a entrada do guest do RANKING_FILE, mas mantém o resto!
	_remover_player_local(local_guest_nick)

	await load_ranking()

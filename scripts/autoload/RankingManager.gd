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
		await _upsert_score_online(player_name, pontos)
	else:
		# --- OFFLINE: só salva localmente ---
		_add_score_local(player_name, pontos)

	# Atualiza os pontos do clã (já feito pelo ClanManager quando ativo)
	if not cla.is_empty() and cla != "Nenhum" and not DatabaseManager.user_token.is_empty():
		if ClanManager.has_method("adicionar_pontos_cla"):
			await ClanManager.adicionar_pontos_cla(cla, player_name, pontos)

	# Recarrega o ranking mais recente
	await load_ranking()

func _upsert_score_online(player_name: String, pontos_novos: int) -> void:
	# 1. Pega o score atual do player no banco
	var end_player = "/rest/v1/rankinggeral?player_name=eq." + player_name.uri_encode() + "&select=*"
	var res = await DatabaseManager.request_async(end_player, HTTPClient.METHOD_GET)

	var score_atual: int = 0
	var existe: bool = false

	if res["success"] and res["data"] is Array and res["data"].size() > 0:
		score_atual = int(res["data"][0].get("score", 0))
		existe = true

	var novo_score: int = score_atual + pontos_novos

	if existe:
		# PATCH: atualiza
		await DatabaseManager.request_async(
			"/rest/v1/rankinggeral?player_name=eq." + player_name.uri_encode(),
			HTTPClient.METHOD_PATCH,
			{"score": novo_score, "updated_at": "now()"}
		)
	else:
		# POST: insere novo jogador
		await DatabaseManager.request_async(
			"/rest/v1/rankinggeral",
			HTTPClient.METHOD_POST,
			{"player_name": player_name, "score": novo_score}
		)

	print("[RankingManager] Score online de '%s' atualizado para %d." % [player_name, novo_score])

# ============================================================
# CACHE LOCAL (Fallback + Convidados)
# ============================================================
func _add_score_local(player_name: String, pontos: int) -> void:
	# Lê o score atual do arquivo (fonte da verdade para o guest)
	var score_atual = _ler_score_guest_local(player_name)
	var novo_score = score_atual + pontos
	
	# Salva o novo score no arquivo local do guest
	var data_guest = {"name": player_name, "score": novo_score}
	var file = FileAccess.open(RANKING_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"geral": [data_guest]}, "\t"))
		file.close()
	
	# Atualiza também a memória e reordena
	var achou = false
	for item in ranking_geral:
		if item["name"] == player_name:
			item["score"] = novo_score
			achou = true
			break
	if not achou:
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
	# Não usa ranking_geral pois ele pode ter sido sobrescrito pelos dados online
	var score_acumulado: int = _ler_score_guest_local(local_guest_nick)

	if score_acumulado > 0:
		print("[RankingManager] Migrando %d pts de '%s' para '%s'..." % [score_acumulado, local_guest_nick, nick_real])
		
		# Envia para o Supabase com o nick oficial
		await _upsert_score_online(nick_real, score_acumulado)

		# Atualiza os pontos do clã se tiver
		if not cla_real.is_empty() and cla_real != "Nenhum":
			if ClanManager.has_method("adicionar_pontos_cla"):
				await ClanManager.adicionar_pontos_cla(cla_real, nick_real, score_acumulado)

	# [Segurança] Destrói o Guest para evitar duplicação
	local_guest_nick = ""
	if FileAccess.file_exists(GUEST_FILE):
		DirAccess.remove_absolute(GUEST_FILE)
	if FileAccess.file_exists(RANKING_FILE):
		DirAccess.remove_absolute(RANKING_FILE)

	await load_ranking()

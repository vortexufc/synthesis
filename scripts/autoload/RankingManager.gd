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
const RANKING_STORAGE_KEY = "synthesis_ranking_local"
const PENDING_STORAGE_KEY = "synthesis_pending_sync"

# dados de conta de visitante
const GUEST_FILE = "user://guest_config.json"
const GUEST_STORAGE_KEY = "synthesis_guest_config"
var local_guest_nick: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_local_nick()
	DatabaseManager.sessao_escola_alterada.connect(func(_id, _nome):
		load_ranking()
		load_ranking_periodo("quimica")
		load_ranking_periodo("fisica")
		load_ranking_periodo("biologia")
	)
	await get_tree().create_timer(0.3).timeout
	await load_ranking()
	await load_ranking_periodo("quimica")
	await load_ranking_periodo("fisica")
	await load_ranking_periodo("biologia")

## Lê JSON de arquivo local com fallback síncrono do localStorage (Web).
func _ler_json_persistente(file_path: String, web_key: String) -> Dictionary:
	var data_file: Dictionary = {}
	if FileAccess.file_exists(file_path):
		var f = FileAccess.open(file_path, FileAccess.READ)
		if f:
			var json = JSON.new()
			if json.parse(f.get_as_text()) == OK and typeof(json.data) == TYPE_DICTIONARY:
				data_file = json.data
			f.close()

	var data_web: Dictionary = {}
	var db = get_node_or_null("/root/DatabaseManager")
	if db and db.has_method("web_storage_get"):
		var raw_web: String = db.web_storage_get(web_key)
		if not raw_web.is_empty():
			var json_w = JSON.new()
			if json_w.parse(raw_web) == OK and typeof(json_w.data) == TYPE_DICTIONARY:
				data_web = json_w.data

	if not data_web.is_empty() and data_file.is_empty():
		return data_web
	if not data_file.is_empty() and data_web.is_empty():
		return data_file
	if not data_web.is_empty() and not data_file.is_empty():
		var ts_file: int = int(data_file.get("_saved_at_ms", 0))
		var ts_web: int = int(data_web.get("_saved_at_ms", 0))
		return data_web if ts_web >= ts_file else data_file
	return {}

## Salva Dictionary em JSON no arquivo local e espelha no localStorage (Web).
func _salvar_json_persistente(file_path: String, web_key: String, data: Dictionary) -> void:
	var copy := data.duplicate()
	copy["_saved_at_ms"] = int(Time.get_unix_time_from_system() * 1000.0)
	var txt := JSON.stringify(copy, "\t")
	var f = FileAccess.open(file_path, FileAccess.WRITE)
	if f:
		f.store_string(txt)
		f.close()
	var db = get_node_or_null("/root/DatabaseManager")
	if db and db.has_method("web_storage_set"):
		db.web_storage_set(web_key, JSON.stringify(copy))

# busca o ranking no supabase
func load_ranking() -> void:
	print("[RankingManager] Buscando ranking online...")
	var esc_id = DatabaseManager.escola_ativa_id
	var endpoint = "/rest/v1/rankinggeral?select=*&order=score.desc&limit=20"
	if esc_id == "geral":
		endpoint = "/rest/v1/rankinggeral?or=(escola_id.eq.geral,escola_id.is.null)&select=*&order=score.desc&limit=20"
	elif esc_id != "todas" and not esc_id.is_empty():
		endpoint = "/rest/v1/rankinggeral?escola_id=eq." + esc_id.uri_encode() + "&select=*&order=score.desc&limit=20"
		
	var res = await DatabaseManager.request_async(endpoint, HTTPClient.METHOD_GET)
	if not res.get("success", false) and res.get("code", 0) == 400:
		res = await DatabaseManager.request_async("/rest/v1/rankinggeral?select=*&order=score.desc&limit=20", HTTPClient.METHOD_GET)

	print("[RankingManager] Resposta: success=%s | code=%s" % [res["success"], res.get("code", "?")])

	if res["success"] and res["data"] is Array:
		# se deu certo, aproveita pra mandar as pontuacoes pendentes
		await sync_pending_scores()
			
		ranking_geral = []
		for row in res["data"]:
			var p_name = str(row.get("player_name", "?")).strip_edges()
			if p_name.to_lower() == "admin":
				continue
			ranking_geral.append({
				"name": p_name,
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
func _calcular_pts_andar(row: Dictionary, _periodo: String, coluna: String) -> int:
	return int(row.get(coluna, 0))

# busca rankings por periodo
func load_ranking_periodo(periodo: String) -> void:
	var coluna: String
	match periodo:
		"quimica":  coluna = "score_diario"
		"fisica":   coluna = "score_semanal"
		"biologia": coluna = "score_mensal"
		_: return
	
	var esc_id = DatabaseManager.escola_ativa_id
	var endpoint = "/rest/v1/rankinggeral?%s=gt.0&select=*&order=%s.desc,score.desc&limit=20" % [coluna, coluna]
	if esc_id == "geral":
		endpoint = "/rest/v1/rankinggeral?%s=gt.0&or=(escola_id.eq.geral,escola_id.is.null)&select=*&order=%s.desc,score.desc&limit=20" % [coluna, coluna]
	elif esc_id != "todas" and not esc_id.is_empty():
		endpoint = "/rest/v1/rankinggeral?%s=gt.0&escola_id=eq.%s&select=*&order=%s.desc,score.desc&limit=20" % [coluna, esc_id.uri_encode(), coluna]
		
	var res = await DatabaseManager.request_async(endpoint, HTTPClient.METHOD_GET)
	if not res.get("success", false) and res.get("code", 0) == 400:
		res = await DatabaseManager.request_async("/rest/v1/rankinggeral?select=*&order=%s.desc,score.desc&limit=20" % coluna, HTTPClient.METHOD_GET)
	if not (res["success"] and res["data"] is Array):
		return
	
	var lista: Array = []
	for row in res["data"]:
		var p_name = str(row.get("player_name", "?")).strip_edges()
		if p_name.to_lower() == "admin":
			continue
		var pts = _calcular_pts_andar(row, periodo, coluna)
			
		if pts > 0:
			lista.append({
				"name": p_name,
				"score": pts,
				"score_diario": int(row.get("score_diario", 0)),
				"score_semanal": int(row.get("score_semanal", 0)),
				"score_mensal": int(row.get("score_mensal", 0)),
				"insignias": row.get("insignias", [])
			})
	
	# Injeta o visitante local caso não esteja logado e tenha pontuação registrada neste andar
	var nick_guest = get_local_nick()
	if not nick_guest.is_empty() and DatabaseManager.user_token.is_empty():
		var score_guest = _ler_score_guest_local(nick_guest, coluna)
		if score_guest > 0:
			var ja_tem = false
			for item in lista:
				if item["name"] == nick_guest:
					ja_tem = true
					break
			if not ja_tem:
				lista.append({
					"name": nick_guest,
					"score": score_guest,
					"score_diario": int(score_guest if periodo == "quimica" else 0),
					"score_semanal": int(score_guest if periodo == "fisica" else 0),
					"score_mensal": int(score_guest if periodo == "biologia" else 0),
					"insignias": []
				})

	lista.sort_custom(func(a, b): return int(a.get("score", 0)) > int(b.get("score", 0)))
	
	match periodo:
		"quimica":  ranking_diario  = lista
		"fisica":   ranking_semanal = lista
		"biologia": ranking_mensal  = lista
	
	ranking_atualizado.emit()
	
# pega o ranking pelo periodo
func get_ranking_por_periodo(periodo: String) -> Array:
	match periodo:
		"quimica":
			return ranking_diario
		"fisica":
			return ranking_semanal
		"biologia":
			return ranking_mensal
		_:
			return ranking_geral

# salva ou atualiza a pontuacao
func add_score(player_name: String, cla: String, pontos: int) -> void:
	if player_name.is_empty() or player_name.strip_edges().to_lower() == "admin" or DatabaseManager.is_admin:
		return

	# Sempre tenta salvar online (anon key + RLS aberto permite INSERT sem login)
	# Visitantes tambem tem seus pontos enviados ao Supabase com seu nick local unico
	var success = await _upsert_score_online(player_name, pontos)
	if success:
		# se enviou, tenta mandar os pendentes
		if not DatabaseManager.user_token.is_empty():
			await sync_pending_scores()
	else:
		# se der erro salva local e poe na fila para reenvio posterior
		_add_pending_score(player_name, pontos)
		_add_score_local(player_name, pontos)

	# atualiza os pontos do cla
	if not cla.is_empty() and cla != "Nenhum" and not DatabaseManager.user_token.is_empty():
		if ClanManager.has_method("adicionar_pontos_cla"):
			await ClanManager.adicionar_pontos_cla(cla, player_name, pontos)

	# recarrega a lista
	await load_ranking()
	await load_ranking_periodo("quimica")
	await load_ranking_periodo("fisica")
	await load_ranking_periodo("biologia")

func _upsert_score_online(player_name: String, pontos_novos: int) -> bool:
	if player_name.strip_edges().to_lower() == "admin" or DatabaseManager.is_admin:
		return false
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
	if "active_dungeon" in DatabaseManager and DatabaseManager.active_dungeon != null:
		subj = str(DatabaseManager.active_dungeon).to_lower()
		
	var eh_quimica = ("quim" in subj) or ("alquim" in subj)
	var eh_fisica = ("fis" in subj) or ("fís" in subj)
	var eh_biologia = ("bio" in subj) or ("estufa" in subj)
	
	if not eh_quimica and not eh_fisica and not eh_biologia:
		var qm = get_node_or_null("/root/QuizManager")
		if qm and "_andar_atual" in qm:
			if qm._andar_atual == 1: eh_quimica = true
			elif qm._andar_atual == 2: eh_fisica = true
			elif qm._andar_atual == 3: eh_biologia = true
			
	var novo_score:         int = score_atual + pontos_novos
	var novo_score_diario:  int = score_diario_atual + (pontos_novos if eh_quimica else 0)
	var novo_score_semanal: int = score_semanal_atual + (pontos_novos if eh_fisica else 0)
	var novo_score_mensal:  int = score_mensal_atual + (pontos_novos if eh_biologia else 0)
	var ps = get_node_or_null("/root/PlayerStats")
	var ins_atuais: Array = ps.vinhetas_desbloqueadas.duplicate() if ps else []

	var payload_update: Dictionary = {
		"score": novo_score,
		"score_diario": novo_score_diario,
		"score_semanal": novo_score_semanal,
		"score_mensal": novo_score_mensal,
		"insignias": ins_atuais,
		"updated_at": Time.get_datetime_string_from_system(true) + "Z"
	}
	var payload_insert: Dictionary = {
		"player_name": player_name,
		"score": novo_score,
		"score_diario": novo_score_diario,
		"score_semanal": novo_score_semanal,
		"score_mensal": novo_score_mensal,
		"insignias": ins_atuais
	}
	var esc_id = DatabaseManager.escola_ativa_id
	if esc_id != "geral" and not esc_id.is_empty():
		payload_update["escola_id"] = esc_id
		payload_insert["escola_id"] = esc_id

	var res_update: Dictionary = {}
	if existe:
		# se ja existe atualiza
		res_update = await DatabaseManager.request_async(
			"/rest/v1/rankinggeral?player_name=eq." + player_name.uri_encode(),
			HTTPClient.METHOD_PATCH,
			payload_update
		)
		if not res_update.get("success", false) and res_update.get("code", 0) == 400:
			if payload_update.has("insignias"):
				payload_update.erase("insignias")
			res_update = await DatabaseManager.request_async(
				"/rest/v1/rankinggeral?player_name=eq." + player_name.uri_encode(),
				HTTPClient.METHOD_PATCH,
				payload_update
			)
			if not res_update.get("success", false) and res_update.get("code", 0) == 400 and payload_update.has("escola_id"):
				payload_update.erase("escola_id")
				res_update = await DatabaseManager.request_async(
					"/rest/v1/rankinggeral?player_name=eq." + player_name.uri_encode(),
					HTTPClient.METHOD_PATCH,
					payload_update
				)
			if not res_update.get("success", false) and res_update.get("code", 0) == 400:
				res_update = await DatabaseManager.request_async(
					"/rest/v1/rankinggeral?player_name=eq." + player_name.uri_encode(),
					HTTPClient.METHOD_PATCH,
					{"score": novo_score}
				)
	else:
		# senao cria novo registro
		res_update = await DatabaseManager.request_async(
			"/rest/v1/rankinggeral",
			HTTPClient.METHOD_POST,
			payload_insert
		)
		if not res_update.get("success", false) and res_update.get("code", 0) == 400:
			if payload_insert.has("insignias"):
				payload_insert.erase("insignias")
			res_update = await DatabaseManager.request_async(
				"/rest/v1/rankinggeral",
				HTTPClient.METHOD_POST,
				payload_insert
			)
			if not res_update.get("success", false) and res_update.get("code", 0) == 400 and payload_insert.has("escola_id"):
				payload_insert.erase("escola_id")
				res_update = await DatabaseManager.request_async(
					"/rest/v1/rankinggeral",
					HTTPClient.METHOD_POST,
					payload_insert
				)
			if not res_update.get("success", false) and res_update.get("code", 0) == 400:
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

func sincronizar_insignias_online() -> void:
	if DatabaseManager.user_token.is_empty():
		return
	var nick = DatabaseManager.user_nick
	if nick.is_empty():
		return
	var ps = get_node_or_null("/root/PlayerStats")
	var ins_atuais: Array = ps.vinhetas_desbloqueadas.duplicate() if ps else []
	
	var payload = {
		"insignias": ins_atuais,
		"updated_at": Time.get_datetime_string_from_system(true) + "Z"
	}
	var res = await DatabaseManager.request_async(
		"/rest/v1/rankinggeral?player_name=eq." + nick.uri_encode(),
		HTTPClient.METHOD_PATCH,
		payload
	)
	if res.get("success", false):
		print("[RankingManager] Insígnias online de '%s' sincronizadas: %s" % [nick, str(ins_atuais)])

# funcoes de cache local
func _add_score_local(player_name: String, pontos: int) -> void:
	# abre o json local (com fallback no localStorage web)
	var local_data = _ler_json_persistente(RANKING_FILE, RANKING_STORAGE_KEY)
	if not local_data.has("geral"):
		local_data["geral"] = []

	var subj = ""
	if "active_dungeon" in DatabaseManager and DatabaseManager.active_dungeon != null:
		subj = str(DatabaseManager.active_dungeon).to_lower()
	var eh_quimica = ("quim" in subj) or ("alquim" in subj)
	var eh_fisica = ("fis" in subj) or ("fís" in subj)
	var eh_biologia = ("bio" in subj) or ("estufa" in subj)
	if not eh_quimica and not eh_fisica and not eh_biologia:
		var qm = get_node_or_null("/root/QuizManager")
		if qm and "_andar_atual" in qm:
			if qm._andar_atual == 1: eh_quimica = true
			elif qm._andar_atual == 2: eh_fisica = true
			elif qm._andar_atual == 3: eh_biologia = true

	# acha o player e atualiza os pontos
	var list_geral = local_data.get("geral", [])
	var score_atual = 0
	var achou_no_arquivo = false
	for item in list_geral:
		if item.get("name", "") == player_name:
			score_atual = int(item.get("score", 0))
			item["score"] = score_atual + pontos
			item["score_diario"] = int(item.get("score_diario", 0)) + (pontos if eh_quimica else 0)
			item["score_semanal"] = int(item.get("score_semanal", 0)) + (pontos if eh_fisica else 0)
			item["score_mensal"] = int(item.get("score_mensal", 0)) + (pontos if eh_biologia else 0)
			achou_no_arquivo = true
			break
	if not achou_no_arquivo:
		list_geral.append({
			"name": player_name,
			"score": pontos,
			"score_diario": pontos if eh_quimica else 0,
			"score_semanal": pontos if eh_fisica else 0,
			"score_mensal": pontos if eh_biologia else 0
		})

	local_data["geral"] = list_geral
	_salvar_json_persistente(RANKING_FILE, RANKING_STORAGE_KEY, local_data)

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

func _ler_score_guest_local(player_name: String, coluna: String = "") -> int:
	var data = _ler_json_persistente(RANKING_FILE, RANKING_STORAGE_KEY)
	for item in data.get("geral", []):
		if item is Dictionary and item.get("name", "") == player_name:
			if not coluna.is_empty():
				return int(item.get(coluna, 0))
			return int(item.get("score", 0))
	return 0

func _remover_player_local(player_name: String) -> void:
	var data = _ler_json_persistente(RANKING_FILE, RANKING_STORAGE_KEY)
	if data.is_empty():
		return
	var geral = data.get("geral", [])
	var novo_geral = []
	for item in geral:
		if item is Dictionary and item.get("name", "") != player_name:
			novo_geral.append(item)
	data["geral"] = novo_geral
	_salvar_json_persistente(RANKING_FILE, RANKING_STORAGE_KEY, data)

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
	
	var ps = get_node_or_null("/root/PlayerStats")
	var ins = ps.vinhetas_desbloqueadas.duplicate() if ps else []
	ranking_geral.append({
		"name": nick_guest,
		"score": score_guest,
		"score_diario": _ler_score_guest_local(nick_guest, "score_diario"),
		"score_semanal": _ler_score_guest_local(nick_guest, "score_semanal"),
		"score_mensal": _ler_score_guest_local(nick_guest, "score_mensal"),
		"insignias": ins
	})
	ranking_geral.sort_custom(func(a, b): return a["score"] > b["score"])

func _salvar_local() -> void:
	_salvar_json_persistente(RANKING_FILE, RANKING_STORAGE_KEY, {"geral": ranking_geral})

func _carregar_local() -> void:
	var data = _ler_json_persistente(RANKING_FILE, RANKING_STORAGE_KEY)
	if not data.is_empty():
		var raw_geral = data.get("geral", [])
		ranking_geral = []
		for item in raw_geral:
			if item is Dictionary:
				var n = str(item.get("name", "")).strip_edges()
				if not n.is_empty() and n.to_lower() != "admin":
					ranking_geral.append(item)
	else:
		ranking_geral = []

	ranking_atualizado.emit()

func remover_admin_do_ranking() -> void:
	print("[RankingManager] Removendo conta de Admin do ranking online e local...")
	await DatabaseManager.request_async("/rest/v1/rankinggeral?player_name=ilike.admin", HTTPClient.METHOD_DELETE)
	
	var novo_geral: Array = []
	for r in ranking_geral:
		if str(r.get("name", "")).strip_edges().to_lower() != "admin":
			novo_geral.append(r)
	ranking_geral = novo_geral
	
	var novo_diario: Array = []
	for r in ranking_diario:
		if str(r.get("name", "")).strip_edges().to_lower() != "admin":
			novo_diario.append(r)
	ranking_diario = novo_diario
	
	var novo_semanal: Array = []
	for r in ranking_semanal:
		if str(r.get("name", "")).strip_edges().to_lower() != "admin":
			novo_semanal.append(r)
	ranking_semanal = novo_semanal
	
	var novo_mensal: Array = []
	for r in ranking_mensal:
		if str(r.get("name", "")).strip_edges().to_lower() != "admin":
			novo_mensal.append(r)
	ranking_mensal = novo_mensal
	
	_salvar_local()
	ranking_atualizado.emit()

# fila de pontuacoes pendentes pra sincronizar
func _add_pending_score(player_name: String, pontos: int) -> void:
	var pending = _load_pending_scores()
	var current = pending.get(player_name, 0)
	pending[player_name] = current + pontos
	_save_pending_scores(pending)
	print("[RankingManager] %d pontos salvos como pendentes para %s." % [pontos, player_name])

func _load_pending_scores() -> Dictionary:
	var raw = _ler_json_persistente(PENDING_SYNC_FILE, PENDING_STORAGE_KEY)
	raw.erase("_saved_at_ms")
	return raw

func _save_pending_scores(pending: Dictionary) -> void:
	var limpo = pending.duplicate()
	limpo.erase("_saved_at_ms")
	_salvar_json_persistente(PENDING_SYNC_FILE, PENDING_STORAGE_KEY, limpo)

func sync_pending_scores() -> void:
	var pending = _load_pending_scores()
	if pending.is_empty():
		return

	print("[RankingManager] Tentando sincronizar pontos pendentes: ", pending)
	var players_to_remove = []
	for player_name in pending.keys():
		var pontos = int(pending[player_name])
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
func _salvar_guest_config(nick: String, updated_at_ms: int = 0) -> void:
	var limpo := nick.strip_edges()
	if limpo.is_empty():
		return
	var ts := updated_at_ms if updated_at_ms > 0 else int(Time.get_unix_time_from_system() * 1000.0)
	var payload := {"guest_nick": limpo, "updated_at": ts}
	var json_str := JSON.stringify(payload)
	var file = FileAccess.open(GUEST_FILE, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
	var db = get_node_or_null("/root/DatabaseManager")
	if db and db.has_method("web_storage_set"):
		db.web_storage_set(GUEST_STORAGE_KEY, json_str)

func _ler_guest_dict_arquivo() -> Dictionary:
	if not FileAccess.file_exists(GUEST_FILE):
		return {}
	var file_read = FileAccess.open(GUEST_FILE, FileAccess.READ)
	if not file_read:
		return {}
	var content = file_read.get_as_text()
	file_read.close()
	var json = JSON.new()
	if json.parse(content) == OK and typeof(json.data) == TYPE_DICTIONARY:
		return json.data
	return {}

func _ler_guest_dict_web() -> Dictionary:
	var db = get_node_or_null("/root/DatabaseManager")
	if not db or not db.has_method("web_storage_get"):
		return {}
	var raw: String = db.web_storage_get(GUEST_STORAGE_KEY)
	if raw.is_empty():
		return {}
	var json = JSON.new()
	if json.parse(raw) == OK and typeof(json.data) == TYPE_DICTIONARY:
		return json.data
	return {}

func get_local_nick() -> String:
	if not local_guest_nick.strip_edges().is_empty():
		return local_guest_nick

	var d_file := _ler_guest_dict_arquivo()
	var d_web := _ler_guest_dict_web()

	var n_file := str(d_file.get("guest_nick", "")).strip_edges()
	var n_web := str(d_web.get("guest_nick", "")).strip_edges()
	var ts_file: int = int(d_file.get("updated_at", 0))
	var ts_web: int = int(d_web.get("updated_at", 0))

	var escolhido := ""
	var ts_escolhido := 0

	if not n_file.is_empty() and n_web.is_empty():
		escolhido = n_file
		ts_escolhido = ts_file
	elif not n_web.is_empty() and n_file.is_empty():
		escolhido = n_web
		ts_escolhido = ts_web
	elif not n_file.is_empty() and not n_web.is_empty():
		# Prioriza o registro mais recente; em empate, prioriza nick personalizado (não Mago_XXXX)
		if ts_web > ts_file:
			escolhido = n_web
			ts_escolhido = ts_web
		elif ts_file > ts_web:
			escolhido = n_file
			ts_escolhido = ts_file
		elif n_file.begins_with("Mago_") and not n_web.begins_with("Mago_"):
			escolhido = n_web
			ts_escolhido = ts_web
		else:
			escolhido = n_file
			ts_escolhido = ts_file

	if not escolhido.is_empty():
		local_guest_nick = escolhido
		# Ressincroniza arquivo + localStorage caso um dos dois tenha se perdido
		if escolhido != n_file or escolhido != n_web or not FileAccess.file_exists(GUEST_FILE):
			_salvar_guest_config(local_guest_nick, ts_escolhido)
		return local_guest_nick

	# id do visitante pra este dispositivo (primeira execução real)
	randomize()
	local_guest_nick = "Mago_" + str(randi() % 9000 + 1000)
	_salvar_guest_config(local_guest_nick)
	return local_guest_nick

func set_local_nick(novo_nick: String) -> void:
	var limpo := novo_nick.strip_edges()
	if limpo.is_empty():
		return
	local_guest_nick = limpo
	_salvar_guest_config(local_guest_nick)

func _migrar_nick_cache_local(nick_antigo: String, novo_nick: String) -> void:
	# 1. Ranking local (user://ranking.json + Web storage)
	var data = _ler_json_persistente(RANKING_FILE, RANKING_STORAGE_KEY)
	if not data.is_empty():
		var geral: Array = data.get("geral", [])
		var item_antigo: Dictionary = {}
		var item_novo: Dictionary = {}
		var restante: Array = []
		for item in geral:
			if not (item is Dictionary):
				continue
			var n = str(item.get("name", ""))
			if n == nick_antigo:
				item_antigo = item
			elif n == novo_nick:
				item_novo = item
			else:
				restante.append(item)
		if not item_antigo.is_empty():
			if item_novo.is_empty():
				item_antigo["name"] = novo_nick
				restante.append(item_antigo)
			else:
				item_novo["score"] = int(item_novo.get("score", 0)) + int(item_antigo.get("score", 0))
				item_novo["score_diario"] = int(item_novo.get("score_diario", 0)) + int(item_antigo.get("score_diario", 0))
				item_novo["score_semanal"] = int(item_novo.get("score_semanal", 0)) + int(item_antigo.get("score_semanal", 0))
				item_novo["score_mensal"] = int(item_novo.get("score_mensal", 0)) + int(item_antigo.get("score_mensal", 0))
				restante.append(item_novo)
			data["geral"] = restante
			_salvar_json_persistente(RANKING_FILE, RANKING_STORAGE_KEY, data)

	# 2. Fila de sincronização pendente
	var pending = _load_pending_scores()
	if pending.has(nick_antigo):
		var pts = int(pending[nick_antigo])
		pending.erase(nick_antigo)
		pending[novo_nick] = int(pending.get(novo_nick, 0)) + pts
		_save_pending_scores(pending)

	# 3. Atualiza listas em memória para feedback imediato na UI
	for lista in [ranking_geral, ranking_diario, ranking_semanal, ranking_mensal]:
		for item in lista:
			if item is Dictionary and item.get("name", "") == nick_antigo:
				item["name"] = novo_nick
	ranking_atualizado.emit()

func renomear_guest_async(novo_nick: String) -> void:
	var limpo := novo_nick.strip_edges()
	if limpo.is_empty():
		return
	var nick_antigo := get_local_nick()
	set_local_nick(limpo)
	if nick_antigo.is_empty() or nick_antigo == limpo:
		return

	_migrar_nick_cache_local(nick_antigo, limpo)

	# Migra no Supabase rankinggeral se o nick antigo possuir registro online e o novo ainda não existir
	var db = get_node_or_null("/root/DatabaseManager")
	if db:
		var res_old = await db.request_async("/rest/v1/rankinggeral?player_name=eq." + nick_antigo.uri_encode() + "&select=player_name,score", HTTPClient.METHOD_GET)
		if res_old.get("success", false) and res_old.get("data") is Array and not res_old["data"].is_empty():
			var res_new = await db.request_async("/rest/v1/rankinggeral?player_name=eq." + limpo.uri_encode() + "&select=player_name", HTTPClient.METHOD_GET)
			if res_new.get("success", false) and res_new.get("data") is Array and res_new["data"].is_empty():
				await db.request_async(
					"/rest/v1/rankinggeral?player_name=eq." + nick_antigo.uri_encode(),
					HTTPClient.METHOD_PATCH,
					{
						"player_name": limpo,
						"updated_at": Time.get_datetime_string_from_system(true) + "Z"
					}
				)
		await load_ranking()
		await load_ranking_periodo("quimica")
		await load_ranking_periodo("fisica")
		await load_ranking_periodo("biologia")

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
	var db = get_node_or_null("/root/DatabaseManager")
	if db and db.has_method("web_storage_remove"):
		db.web_storage_remove(GUEST_STORAGE_KEY)
	local_guest_nick = ""

	await load_ranking()

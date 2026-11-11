extends Node

# chaves do nosso banco no supabase
var supabase_url: String = "https://uszmgqludyymspsarciw.supabase.co"
# chave do supabase via project settings
var supabase_key: String = ProjectSettings.get_setting("application/config/supabase_key", "")

# dados do jogador logado
var user_token: String = ""
var user_refresh_token: String = ""
var user_nick: String = ""
var user_cla: String = "Nenhum"
var user_id: String = ""
var active_dungeon: String = "" # Registra a masmorra escolhida no hub
var is_admin: bool = false # Define se a conta atual é um professor/pesquisador

func get_active_nick() -> String:
	var n = user_nick.strip_edges()
	if not n.is_empty() and n != "Mago" and n != "Mago Desconhecido" and not n.to_lower().contains("anonimo") and not n.to_lower().contains("anônimo"):
		return n
	if RankingManager and RankingManager.has_method("get_local_nick"):
		var lg = RankingManager.get_local_nick().strip_edges()
		if not lg.is_empty():
			return lg
	return "Mago_" + str(randi() % 9000 + 1000)

# chave usada para salvar sessao no localStorage (web) e fallback desktop
const SESSION_KEY := "synthesis_session"
const SESSION_FILE := "user://session.json"
const PROGRESSO_STORAGE_KEY := "synthesis_progresso_data"

var _ultimo_refresh_rejeitado: bool = false


# sinal pra avisar outras partes do jogo q a resposta chegou
signal dados_recebidos(dados)
signal perguntas_recebidas(perguntas: Array)

# sinais para a tela de login e cadastro
signal auth_sucesso(token: String)
signal auth_erro(mensagem: String)
signal sessao_encerrada()
signal reset_senha_enviado()
signal nick_alterado(novo_nick: String)
signal telemetria_sincronizada(total_itens: int)

# Controle de taxa e tentativas (Rate limiting)
const MAX_TENTATIVAS_LOGIN: int = 5
const TEMPO_BLOQUEIO_LOGIN: int = 60 # segundos
const COOLDOWN_RESET_SENHA: int = 60 # segundos

var tentativas_login_falhas: int = 0
var bloqueio_login_ate: int = 0
var _ultimo_reset_senha_timestamp: int = 0
var _sincronizando_offline: bool = false

# no de requisicoes http
var http_request: HTTPRequest

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# cria o no http
	http_request = HTTPRequest.new()
	http_request.accept_gzip = false
	http_request.timeout = 10.0
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	carregar_progresso()
	print("banco carregado!")
	
	# 1. Restaura sessão salva no localStorage (web) antes de qualquer outra coisa
	_restaurar_sessao_web()
	
	# 2. Verifica parâmetro de URL (?turma= ou ?escola=) no navegador Web
	_verificar_parametro_url_web()
	
	# 3. Sincroniza sessão ativa global no Supabase (para clientes Desktop e Web)
	sincronizar_sessao_global_supabase()
	
	# 4. Timer periódico para sincronização automática de telemetria pendente (buffer offline -> Supabase)
	var timer_sync = Timer.new()
	timer_sync.name = "TimerSyncOffline"
	timer_sync.wait_time = 35.0
	timer_sync.autostart = true
	timer_sync.one_shot = false
	timer_sync.timeout.connect(func(): sincronizar_telemetria_pendente_async())
	add_child(timer_sync)

# progresso salvo localmente
const SAVE_FILE = "user://progresso.json"
const SESSOES_FILE = "user://sessoes_escolas.json"
const SESSOES_EXCLUIDAS_FILE = "user://sessoes_excluidas.json"
const ANALYTICS_FILE = "user://pesquisa_analytics.json"
const MINIGAMES_ANALYTICS_FILE = "user://minigames_analytics.json"
const GAMEPLAY_TELEMETRIA_FILE = "user://gameplay_telemetria.json"
const OFFLINE_SYNC_QUEUE_FILE = "user://telemetria_sync_queue.json"
const ANALYTICS_STORAGE_KEY = "synthesis_pesquisa_analytics"
const MINIGAMES_STORAGE_KEY = "synthesis_minigames_analytics"
const GAMEPLAY_TELEMETRIA_STORAGE_KEY = "synthesis_gameplay_telemetria"
const OFFLINE_SYNC_STORAGE_KEY = "synthesis_telemetria_sync_queue"

var escola_ativa_id: String = "geral"
var escola_ativa_nome: String = "Geral (Padrão)"

signal sessao_escola_alterada(id_escola: String, nome_escola: String)
signal sessao_escola_removida(id_escola: String)

## Helpers seguros para persistência síncrona no localStorage (Web) usando Base64 UTF-8.
func web_storage_set(key: String, value_str: String) -> void:
	if not OS.has_feature("web") or not ClassDB.class_exists("JavaScriptBridge"):
		return
	var b64 := Marshalls.utf8_to_base64(value_str)
	var js := """
	(function(k, b64) {
		try {
			var bin = atob(b64);
			var bytes = new Uint8Array(bin.length);
			for (var i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
			localStorage.setItem(k, new TextDecoder('utf-8').decode(bytes));
		} catch (e) {}
	})('%s', '%s');
	""" % [key.replace("'", ""), b64]
	JavaScriptBridge.eval(js)

func web_storage_get(key: String) -> String:
	if not OS.has_feature("web") or not ClassDB.class_exists("JavaScriptBridge"):
		return ""
	var raw = JavaScriptBridge.eval("(function(k){ try { return localStorage.getItem(k) || ''; } catch(e) { return ''; } })('%s');" % key.replace("'", ""))
	if raw == null:
		return ""
	var s := str(raw)
	if s == "null" or s == "undefined":
		return ""
	return s

func web_storage_remove(key: String) -> void:
	if not OS.has_feature("web") or not ClassDB.class_exists("JavaScriptBridge"):
		return
	JavaScriptBridge.eval("(function(k){ try { localStorage.removeItem(k); } catch(e) {} })('%s');" % key.replace("'", ""))

func salvar_progresso() -> void:
	var data = {
		"active_dungeon": active_dungeon,
		"escola_ativa_id": escola_ativa_id,
		"escola_ativa_nome": escola_ativa_nome,
		"_saved_at_ms": int(Time.get_unix_time_from_system() * 1000.0)
	}
	var json_str := JSON.stringify(data)
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
	web_storage_set(PROGRESSO_STORAGE_KEY, json_str)

func carregar_progresso() -> void:
	var data_file: Dictionary = {}
	if FileAccess.file_exists(SAVE_FILE):
		var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
				data_file = json.data
			file.close()

	var data_web: Dictionary = {}
	var raw_web := web_storage_get(PROGRESSO_STORAGE_KEY)
	if not raw_web.is_empty():
		var json_w = JSON.new()
		if json_w.parse(raw_web) == OK and json_w.data is Dictionary:
			data_web = json_w.data

	var data: Dictionary = {}
	if not data_web.is_empty() and data_file.is_empty():
		data = data_web
	elif not data_file.is_empty() and data_web.is_empty():
		data = data_file
	elif not data_web.is_empty() and not data_file.is_empty():
		var ts_file: int = int(data_file.get("_saved_at_ms", 0))
		var ts_web: int = int(data_web.get("_saved_at_ms", 0))
		data = data_web if ts_web >= ts_file else data_file

	if data.is_empty():
		return

	active_dungeon = data.get("active_dungeon", "")
	escola_ativa_id = data.get("escola_ativa_id", "geral")
	escola_ativa_nome = data.get("escola_ativa_nome", "Geral (Padrão)")

	# Mantém arquivo e web sincronizados após recuperação
	if not FileAccess.file_exists(SAVE_FILE) and not data_web.is_empty():
		var f_sync = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
		if f_sync:
			f_sync.store_string(JSON.stringify(data))
			f_sync.close()

func resetar_expedicao_ativa() -> void:
	active_dungeon = ""
	salvar_progresso()
	print("[DatabaseManager] Expedição ativa resetada com sucesso!")

# --- GESTÃO DE SESSÕES / ESCOLAS (AVALIAÇÃO PEDAGÓGICA) ---

func _verificar_parametro_url_web() -> void:
	if not OS.has_feature("web"):
		return
	if not ClassDB.class_exists("JavaScriptBridge"):
		return
	var js_window = JavaScriptBridge.get_interface("window")
	if js_window and js_window.location and js_window.location.search:
		var search = str(js_window.location.search)
		if not search.is_empty():
			var params = search.trim_prefix("?").split("&")
			for p in params:
				var partes = p.split("=")
				if partes.size() == 2:
					var chave = partes[0].to_lower()
					var valor = partes[1].strip_edges()
					if (chave == "escola" or chave == "turma" or chave == "sessao") and not valor.is_empty():
						escola_ativa_id = valor.to_lower()
						escola_ativa_nome = valor.capitalize().replace("_", " ")
						set_meta("escola_fixada_por_url", true)
						salvar_progresso()
						sessao_escola_alterada.emit(escola_ativa_id, escola_ativa_nome)
						print("[DatabaseManager] Sessão forçada via URL Web: %s (%s)" % [escola_ativa_nome, escola_ativa_id])
						return

func carregar_sessoes_excluidas() -> Dictionary:
	var excluidos: Dictionary = {}
	if not FileAccess.file_exists(SESSOES_EXCLUIDAS_FILE):
		return excluidos
	var f = FileAccess.open(SESSOES_EXCLUIDAS_FILE, FileAccess.READ)
	if f:
		var json = JSON.new()
		if json.parse(f.get_as_text()) == OK:
			if json.data is Dictionary:
				excluidos = json.data
			elif json.data is Array:
				for id_item in json.data:
					excluidos[str(id_item)] = true
		f.close()
	return excluidos

func salvar_sessoes_excluidas_dict(excluidos: Dictionary) -> void:
	var f = FileAccess.open(SESSOES_EXCLUIDAS_FILE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(excluidos, "\t"))
		f.close()

func registrar_sessao_excluida(id_codigo: String) -> void:
	var clean_id = id_codigo.strip_edges()
	if clean_id.is_empty() or clean_id == "geral":
		return
	var excluidos = carregar_sessoes_excluidas()
	excluidos[clean_id] = true
	salvar_sessoes_excluidas_dict(excluidos)

func desregistrar_sessao_excluida(id_codigo: String) -> void:
	var clean_id = id_codigo.strip_edges()
	var excluidos = carregar_sessoes_excluidas()
	if excluidos.has(clean_id):
		excluidos.erase(clean_id)
		salvar_sessoes_excluidas_dict(excluidos)

func sincronizar_sessao_global_supabase() -> void:
	if has_meta("escola_fixada_por_url"):
		return
	var res = await request_async("/rest/v1/sessoes_escolas?ativa=eq.true&select=*&limit=1", HTTPClient.METHOD_GET)
	if res.get("success", false) and res.get("data") is Array and not res["data"].is_empty():
		var row = res["data"][0]
		var s_id = str(row.get("id", "geral")).strip_edges()
		var s_nome = str(row.get("nome", "Geral")).strip_edges()
		var excluidos = carregar_sessoes_excluidas()
		if excluidos.has(s_id) or s_nome.begins_with("[EXCLUID") or s_nome.begins_with("[DELETAD"):
			if escola_ativa_id != "geral":
				escola_ativa_id = "geral"
				escola_ativa_nome = "Geral (Padrão / Lançamento)"
				salvar_progresso()
				sessao_escola_alterada.emit(escola_ativa_id, escola_ativa_nome)
			return
		if not s_id.is_empty() and (s_id != escola_ativa_id or s_nome != escola_ativa_nome):
			escola_ativa_id = s_id
			escola_ativa_nome = s_nome
			salvar_progresso()
			sessao_escola_alterada.emit(escola_ativa_id, escola_ativa_nome)
			print("[DatabaseManager] Sessão global sincronizada do Supabase: %s (%s)" % [escola_ativa_nome, escola_ativa_id])

func carregar_sessoes_escolas() -> Array[Dictionary]:
	var excluidos = carregar_sessoes_excluidas()
	var lista: Array[Dictionary] = [
		{"id": "geral", "nome": "Geral (Padrão / Lançamento)", "data_criacao": "2026-01-01"}
	]
	if not FileAccess.file_exists(SESSOES_FILE):
		return lista
	var f = FileAccess.open(SESSOES_FILE, FileAccess.READ)
	if f:
		var json = JSON.new()
		if json.parse(f.get_as_text()) == OK and json.data is Array:
			var carregadas: Array = json.data
			var ids_existentes = {"geral": true}
			for item in carregadas:
				if item is Dictionary and item.has("id") and item.has("nome"):
					var sid = str(item["id"]).strip_edges()
					var snome = str(item["nome"]).strip_edges()
					if excluidos.has(sid) or snome.begins_with("[EXCLUID") or snome.begins_with("[DELETAD"):
						continue
					if not ids_existentes.has(sid):
						lista.append(item)
						ids_existentes[sid] = true
		f.close()
	return lista

func carregar_sessoes_escolas_async() -> Array[Dictionary]:
	var excluidos = carregar_sessoes_excluidas()
	var lista_local = carregar_sessoes_escolas()
	var res = await request_async("/rest/v1/sessoes_escolas?select=*&order=data_criacao.asc.nullslast", HTTPClient.METHOD_GET)
	if not res.get("success", false) or not (res.get("data") is Array):
		# Fallback se a ordenação der algum erro de parâmetro: tenta sem order
		res = await request_async("/rest/v1/sessoes_escolas?select=*", HTTPClient.METHOD_GET)
	
	if res.get("success", false) and res.get("data") is Array:
		var lista: Array[Dictionary] = []
		var ids_existentes = {}
		var excluidos_alterados = false
		
		# 1. Popula a lista com todas as sessões registradas no Supabase (filtrando excluídas)
		for item in res["data"]:
			if item is Dictionary and item.has("id") and item.has("nome"):
				var sid = str(item["id"]).strip_edges()
				var snome = str(item["nome"]).strip_edges()
				
				# Se no Supabase a sessão tiver marcação de excluída ou estiver no registro de excluídas
				if excluidos.has(sid) or snome.begins_with("[EXCLUID") or snome.begins_with("[DELETAD"):
					if not excluidos.has(sid):
						excluidos[sid] = true
						excluidos_alterados = true
					continue
					
				if ids_existentes.has(sid):
					continue
				ids_existentes[sid] = true
				var eh_ativa = bool(item.get("ativa", false))
				lista.append({
					"id": sid,
					"nome": snome,
					"data_criacao": str(item.get("data_criacao", "")),
					"ativa": eh_ativa
				})
				if eh_ativa and not has_meta("escola_fixada_por_url"):
					if sid != escola_ativa_id or snome != escola_ativa_nome:
						escola_ativa_id = sid
						escola_ativa_nome = snome
						salvar_progresso()
						sessao_escola_alterada.emit(escola_ativa_id, escola_ativa_nome)
		
		if excluidos_alterados:
			salvar_sessoes_excluidas_dict(excluidos)
			
		# 2. Garante que 'geral' sempre conste como opção base
		if not ids_existentes.has("geral"):
			lista.insert(0, {
				"id": "geral",
				"nome": "Geral (Padrão / Lançamento)",
				"data_criacao": "2026-01-01",
				"ativa": (escola_ativa_id == "geral")
			})
			ids_existentes["geral"] = true
			
		# Se a escola_ativa_id atual não existe mais nas opções, reverte com segurança para geral
		if not ids_existentes.has(escola_ativa_id) and not has_meta("escola_fixada_por_url"):
			escola_ativa_id = "geral"
			escola_ativa_nome = "Geral (Padrão / Lançamento)"
			salvar_progresso()
			sessao_escola_alterada.emit(escola_ativa_id, escola_ativa_nome)
			
		# 3. Preserva sessões criadas localmente que ainda não subiram à nuvem (e não excluídas)
		for item_local in lista_local:
			if item_local is Dictionary and item_local.has("id"):
				var lid = str(item_local["id"]).strip_edges()
				var lnome = str(item_local.get("nome", "")).strip_edges()
				if excluidos.has(lid) or lnome.begins_with("[EXCLUID") or lnome.begins_with("[DELETAD"):
					continue
				if not ids_existentes.has(lid):
					lista.append(item_local)
					ids_existentes[lid] = true
					_enviar_nova_sessao_supabase(item_local)
					
		salvar_sessoes_escolas(lista)
		return lista
	return lista_local

func salvar_sessoes_escolas(sessoes: Array) -> void:
	var f = FileAccess.open(SESSOES_FILE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(sessoes, "\t"))
		f.close()

func adicionar_sessao_escola(nome: String, id_codigo: String = "") -> Dictionary:
	var clean_id = id_codigo.strip_edges().to_lower().replace(" ", "_")
	if clean_id.is_empty():
		clean_id = "escola_" + str(Time.get_unix_time_from_system())
		
	desregistrar_sessao_excluida(clean_id)
	var sessoes = carregar_sessoes_escolas()
	for s in sessoes:
		if s["id"] == clean_id:
			return s # Já existe
			
	var nova = {
		"id": clean_id,
		"nome": nome.strip_edges(),
		"data_criacao": Time.get_datetime_string_from_system()
	}
	sessoes.append(nova)
	salvar_sessoes_escolas(sessoes)
	
	# Propaga criação de fundo para o Supabase
	_enviar_nova_sessao_supabase(nova)
	return nova

func adicionar_sessao_escola_async(nome: String, id_codigo: String = "") -> Dictionary:
	var clean_id = id_codigo.strip_edges().to_lower().replace(" ", "_")
	if clean_id.is_empty():
		clean_id = "escola_" + str(Time.get_unix_time_from_system())
		
	desregistrar_sessao_excluida(clean_id)
	var sessoes = carregar_sessoes_escolas()
	for s in sessoes:
		if s["id"] == clean_id:
			return s # Já existe
			
	var nova = {
		"id": clean_id,
		"nome": nome.strip_edges(),
		"data_criacao": Time.get_datetime_string_from_system()
	}
	sessoes.append(nova)
	salvar_sessoes_escolas(sessoes)
	
	await _enviar_nova_sessao_supabase(nova)
	return nova

func _enviar_nova_sessao_supabase(nova_sessao: Dictionary) -> void:
	await request_async("/rest/v1/sessoes_escolas", HTTPClient.METHOD_POST, {
		"id": nova_sessao["id"],
		"nome": nova_sessao["nome"],
		"ativa": false,
		"data_criacao": nova_sessao.get("data_criacao", Time.get_datetime_string_from_system())
	})

func definir_sessao_ativa(id_codigo: String, nome: String) -> void:
	escola_ativa_id = id_codigo
	escola_ativa_nome = nome
	salvar_progresso()
	sessao_escola_alterada.emit(escola_ativa_id, escola_ativa_nome)
	print("[DatabaseManager] Sessão ativa alterada para: %s (%s)" % [escola_ativa_nome, escola_ativa_id])
	_propagar_ativacao_sessao_supabase(id_codigo, nome)

func definir_sessao_ativa_async(id_codigo: String, nome: String) -> void:
	escola_ativa_id = id_codigo
	escola_ativa_nome = nome
	salvar_progresso()
	sessao_escola_alterada.emit(escola_ativa_id, escola_ativa_nome)
	print("[DatabaseManager] Sessão ativa alterada para: %s (%s)" % [escola_ativa_nome, escola_ativa_id])
	await _propagar_ativacao_sessao_supabase(id_codigo, nome)

func _propagar_ativacao_sessao_supabase(id_codigo: String, nome: String) -> void:
	# 1. Desmarca qualquer sessão ativa anterior
	await request_async("/rest/v1/sessoes_escolas?ativa=eq.true", HTTPClient.METHOD_PATCH, {"ativa": false})
	
	# 2. Marca a sessão alvo como ativa
	var res_patch = await request_async("/rest/v1/sessoes_escolas?id=eq." + id_codigo.uri_encode(), HTTPClient.METHOD_PATCH, {
		"ativa": true,
		"nome": nome,
		"data_ativacao": Time.get_datetime_string_from_system()
	})
	
	# 3. Se a sessão ainda não existia na nuvem, insere diretamente
	if not res_patch.get("success", false) or (res_patch.get("data") is Array and res_patch["data"].is_empty()):
		await request_async("/rest/v1/sessoes_escolas", HTTPClient.METHOD_POST, {
			"id": id_codigo,
			"nome": nome,
			"ativa": true,
			"data_ativacao": Time.get_datetime_string_from_system()
		})
	print("[DatabaseManager] Sessão global propagada no Supabase: %s (%s)" % [nome, id_codigo])

func remover_sessao_escola(id_codigo: String) -> bool:
	var clean_id = id_codigo.strip_edges()
	if clean_id.is_empty() or clean_id == "geral":
		return false
	registrar_sessao_excluida(clean_id)
	var sessoes = carregar_sessoes_escolas()
	var removido = false
	for i in range(sessoes.size() - 1, -1, -1):
		if str(sessoes[i].get("id", "")).strip_edges() == clean_id:
			sessoes.remove_at(i)
			removido = true
	if removido:
		salvar_sessoes_escolas(sessoes)
		resetar_analytics_sessao(clean_id)
		if escola_ativa_id == clean_id:
			definir_sessao_ativa("geral", "Geral (Padrão / Lançamento)")
		sessao_escola_removida.emit(clean_id)
	return removido

func remover_sessao_escola_async(id_codigo: String) -> bool:
	var clean_id = id_codigo.strip_edges()
	if clean_id.is_empty() or clean_id == "geral":
		return false
		
	# 1. Registra localmente como excluída para impedir qualquer re-sincronização
	registrar_sessao_excluida(clean_id)
	
	# 2. Remove da lista local e persiste no arquivo
	var sessoes = carregar_sessoes_escolas()
	var removido_local = false
	var nome_sessao = ""
	for i in range(sessoes.size() - 1, -1, -1):
		if str(sessoes[i].get("id", "")).strip_edges() == clean_id:
			nome_sessao = str(sessoes[i].get("nome", ""))
			sessoes.remove_at(i)
			removido_local = true
	if removido_local:
		salvar_sessoes_escolas(sessoes)
		
	# 3. Se a sessão excluída for a ativa, reverte imediatamente para Geral
	if escola_ativa_id == clean_id:
		await definir_sessao_ativa_async("geral", "Geral (Padrão / Lançamento)")
		
	# 4. Limpa registros analíticos locais vinculados a esta sessão
	resetar_analytics_sessao(clean_id)
	
	# 5. Soft-delete na nuvem via PATCH: marca nome como [EXCLUIDA] e desativa
	# Como o Supabase restringe HTTP DELETE por padrão quando há RLS sem política de DELETE,
	# o PATCH garante que outros painéis e clientes ignorem esta sessão imediatamente
	var nome_marcado = "[EXCLUIDA] " + (nome_sessao if not nome_sessao.is_empty() else clean_id)
	var res_patch = await request_async("/rest/v1/sessoes_escolas?id=eq." + clean_id.uri_encode(), HTTPClient.METHOD_PATCH, {
		"nome": nome_marcado,
		"ativa": false
	})
	
	# 6. Tenta DELETE hard no Supabase (funciona caso a política DELETE esteja configurada)
	var res_delete = await request_async("/rest/v1/sessoes_escolas?id=eq." + clean_id.uri_encode(), HTTPClient.METHOD_DELETE)
	
	# 7. Remove rankings e respostas vinculadas a esta escola no Supabase
	var query_filtro = "escola_id=eq." + clean_id.uri_encode()
	await request_async("/rest/v1/rankinggeral?" + query_filtro, HTTPClient.METHOD_DELETE)
	await request_async("/rest/v1/respostas?" + query_filtro, HTTPClient.METHOD_DELETE)
	await request_async("/rest/v1/minigames_respostas?" + query_filtro, HTTPClient.METHOD_DELETE)
	await request_async("/rest/v1/telemetria_gameplay?" + query_filtro, HTTPClient.METHOD_DELETE)
	
	sessao_escola_removida.emit(clean_id)
	print("[DatabaseManager] Sessão '%s' removida. Local: %s, Patch: %s, Delete: %s" % [
		clean_id, str(removido_local), str(res_patch.get("success", false)), str(res_delete.get("success", false))
	])
	return true

# --- ARMAZENAMENTO E CONSULTA DE ANALYTICS EDUCACIONAIS ---

func _ler_array_persistente(file_path: String, storage_key: String) -> Array:
	if FileAccess.file_exists(file_path):
		var f = FileAccess.open(file_path, FileAccess.READ)
		if f:
			var json = JSON.new()
			var ok = (json.parse(f.get_as_text()) == OK and json.data is Array)
			f.close()
			if ok:
				return json.data
	if not storage_key.is_empty():
		var raw_web := web_storage_get(storage_key)
		if not raw_web.is_empty():
			var json_w = JSON.new()
			if json_w.parse(raw_web) == OK and json_w.data is Array:
				return json_w.data
	return []

func _salvar_array_persistente(file_path: String, storage_key: String, lista: Array) -> void:
	var f_write = FileAccess.open(file_path, FileAccess.WRITE)
	if f_write:
		f_write.store_string(JSON.stringify(lista, "\t"))
		f_write.close()
	if not storage_key.is_empty():
		var inicio := maxi(0, lista.size() - 500)
		web_storage_set(storage_key, JSON.stringify(lista.slice(inicio)))

func _filtrar_array_por_escola(todas: Array, filtro_escola_id: String) -> Array:
	if filtro_escola_id.is_empty() or filtro_escola_id == "todas":
		return todas
	var arr: Array = []
	for r in todas:
		if r is Dictionary and str(r.get("escola_id", "geral")) == filtro_escola_id:
			arr.append(r)
	return arr

func registrar_resposta_analytics(dados: Dictionary) -> void:
	var n_aluno = str(dados.get("aluno_nick", "")).strip_edges()
	if n_aluno.is_empty() or n_aluno == "Mago" or n_aluno == "Mago Desconhecido" or n_aluno == "Visitante" or n_aluno.to_lower().contains("anonimo") or n_aluno.to_lower().contains("anônimo"):
		dados["aluno_nick"] = get_active_nick()
		
	var respostas: Array = _ler_array_persistente(ANALYTICS_FILE, ANALYTICS_STORAGE_KEY)
	respostas.append(dados)
	_salvar_array_persistente(ANALYTICS_FILE, ANALYTICS_STORAGE_KEY, respostas)

func obter_respostas_analytics(filtro_escola_id: String = "") -> Array:
	return _filtrar_array_por_escola(_ler_array_persistente(ANALYTICS_FILE, ANALYTICS_STORAGE_KEY), filtro_escola_id)

func resetar_analytics_sessao(filtro_escola_id: String) -> void:
	print("[DatabaseManager] Resetando analytics locais da sessão: ", filtro_escola_id)
	var arquivos_cfg = [
		{"file": ANALYTICS_FILE, "key": ANALYTICS_STORAGE_KEY},
		{"file": MINIGAMES_ANALYTICS_FILE, "key": MINIGAMES_STORAGE_KEY},
		{"file": GAMEPLAY_TELEMETRIA_FILE, "key": GAMEPLAY_TELEMETRIA_STORAGE_KEY}
	]
	for cfg in arquivos_cfg:
		var arq: String = cfg["file"]
		var skey: String = cfg["key"]
		var dados := _ler_array_persistente(arq, skey)
		if dados.is_empty() and not FileAccess.file_exists(arq):
			if filtro_escola_id == "todas":
				web_storage_remove(skey)
			continue
		var mantidos: Array = []
		for item in dados:
			if item is Dictionary:
				var esc = str(item.get("escola_id", "geral"))
				if filtro_escola_id == "todas" or esc == filtro_escola_id:
					continue
				mantidos.append(item)
		_salvar_array_persistente(arq, skey, mantidos)

# --- ANALYTICS DE MINIGAMES (MEMÓRIA, LIGAR PARES, MURAL) ---

func salvar_minigame_analytics(tipo_minigame: String, andar_id: int, vitoria: bool, tempo_gasto: float, detalhes: Dictionary = {}) -> void:
	var nick: String = get_active_nick()
	var reg = {
		"aluno_nick": nick,
		"escola_id": escola_ativa_id,
		"andar_id": andar_id,
		"tipo_minigame": tipo_minigame, # "jogo_memoria", "ligar_pares", "mural_formulas"
		"vitoria": vitoria,
		"tempo_gasto": snapped(tempo_gasto, 0.1),
		"detalhes": detalhes,
		"cla_aluno": user_cla if not user_cla.is_empty() else "Nenhum",
		"timestamp": Time.get_datetime_string_from_system(true) + "Z"
	}
	
	var lista: Array = _ler_array_persistente(MINIGAMES_ANALYTICS_FILE, MINIGAMES_STORAGE_KEY)
	lista.append(reg)
	_salvar_array_persistente(MINIGAMES_ANALYTICS_FILE, MINIGAMES_STORAGE_KEY, lista)
		
	# Envia para o Supabase sempre (anon key + RLS aberto = funciona sem login)
	var res_mini = await request_async("/rest/v1/minigames_respostas", HTTPClient.METHOD_POST, reg)
	if not res_mini.get("success", false):
		enfileirar_sync_offline("/rest/v1/minigames_respostas", reg)
	print("[Analytics] Minigame '%s' registrado: vitória=%s | tempo=%.1fs" % [tipo_minigame, str(vitoria), tempo_gasto])

func obter_minigames_analytics(filtro_escola_id: String = "") -> Array:
	return _filtrar_array_por_escola(_ler_array_persistente(MINIGAMES_ANALYTICS_FILE, MINIGAMES_STORAGE_KEY), filtro_escola_id)

# --- TELEMETRIA DE GAMEPLAY (MORTES, POÇÕES, TEMPO POR ANDAR) ---

func salvar_telemetria_gameplay(tipo_evento: String, andar_id: int, valor: float = 1.0) -> void:
	var nick: String = get_active_nick()
	var reg = {
		"aluno_nick": nick,
		"escola_id": escola_ativa_id,
		"andar_id": andar_id,
		"tipo_evento": tipo_evento, # "morte", "pocao", "tempo_andar"
		"valor": valor,
		"timestamp": Time.get_datetime_string_from_system(true) + "Z"
	}
	var lista: Array = _ler_array_persistente(GAMEPLAY_TELEMETRIA_FILE, GAMEPLAY_TELEMETRIA_STORAGE_KEY)
	lista.append(reg)
	_salvar_array_persistente(GAMEPLAY_TELEMETRIA_FILE, GAMEPLAY_TELEMETRIA_STORAGE_KEY, lista)
		
	# Envia para o Supabase sempre (anon key funciona para INSERT com RLS aberto)
	var res_tele = await request_async("/rest/v1/telemetria_gameplay", HTTPClient.METHOD_POST, reg)
	if not res_tele.get("success", false):
		enfileirar_sync_offline("/rest/v1/telemetria_gameplay", reg)

func obter_telemetria_gameplay(filtro_escola_id: String = "") -> Array:
	return _filtrar_array_por_escola(_ler_array_persistente(GAMEPLAY_TELEMETRIA_FILE, GAMEPLAY_TELEMETRIA_STORAGE_KEY), filtro_escola_id)

# --- RESPOSTAS DE V OU F (FÚRIA DO CHEFE) ---

func salvar_resposta_vf(afirmacao_texto: String, resposta_aluno: bool, resposta_correta: bool, acertou: bool, tempo_resposta: float, andar_id: int) -> void:
	var nick: String = get_active_nick()
	var data_resp = {
		"pergunta_id": 9000 + (andar_id * 100),
		"acertou": acertou,
		"andar_id": andar_id,
		"aluno_nick": nick,
		"escola_id": escola_ativa_id,
		"tempo_resposta": snapped(tempo_resposta, 0.1),
		"alternativa_marcada": "V" if resposta_aluno else "F",
		"alternativa_correta": "V" if resposta_correta else "F",
		"cla_aluno": user_cla,
		"consultas_grimorio": 0,
		"tipo": "furia_boss_vf",
		"enunciado": afirmacao_texto,
		"timestamp": Time.get_datetime_string_from_system(true) + "Z"
	}
	registrar_resposta_analytics(data_resp)
	enviar_resposta_supabase(data_resp)
	print("[Analytics] Resposta V/F do Boss gravada: %s (Acertou: %s)" % [afirmacao_texto.substr(0, 30), str(acertou)])

func enviar_resposta_supabase(data_resp_completo: Dictionary) -> void:
	# Garante nick unico para visitantes - nunca sobrescreve "Mago" generico nem "Mago Anonimo"
	var nick_final: String = str(data_resp_completo.get("aluno_nick", "")).strip_edges()
	if nick_final.is_empty() or nick_final == "Mago" or nick_final == "Mago Desconhecido" or nick_final == "Visitante" or nick_final.to_lower().contains("anonimo") or nick_final.to_lower().contains("anônimo"):
		nick_final = get_active_nick()
		data_resp_completo["aluno_nick"] = nick_final
	
	# Payload completo - todas as colunas que existem no banco
	var payload_servidor = {
		"pergunta_id": data_resp_completo.get("pergunta_id", 0),
		"acertou": data_resp_completo.get("acertou", false),
		"andar_id": data_resp_completo.get("andar_id", 1),
		"aluno_nick": nick_final,
		"escola_id": data_resp_completo.get("escola_id", escola_ativa_id),
		"tempo_resposta": data_resp_completo.get("tempo_resposta", 0.0),
		"alternativa_marcada": data_resp_completo.get("alternativa_marcada", ""),
		"cla_aluno": data_resp_completo.get("cla_aluno", user_cla if not user_cla.is_empty() else "Nenhum"),
		"consultas_grimorio": data_resp_completo.get("consultas_grimorio", 0)
	}
	
	# Envia para o Supabase sempre (anon key + RLS aberto = funciona sem login)
	var res = await request_async("/rest/v1/respostas", HTTPClient.METHOD_POST, payload_servidor)
	
	if res.get("success", false):
		return # Enviado com sucesso!
		
	var code = res.get("code", 0)
	if code == 0:
		# Sem rede / timeout - enfileira para reenvio posterior
		enfileirar_sync_offline("/rest/v1/respostas", payload_servidor)
		return
		
	if code == 400:
		# Alguma coluna pode nao existir ainda (banco antigo). Tenta versao reduzida.
		push_warning("[DatabaseManager] Erro 400 ao enviar resposta. Msg: " + res.get("message", "?") + " - tentando payload reduzido.")
		var payload_minimo = {
			"pergunta_id": payload_servidor["pergunta_id"],
			"acertou": payload_servidor["acertou"],
			"andar_id": payload_servidor["andar_id"],
			"aluno_nick": payload_servidor["aluno_nick"],
			"escola_id": payload_servidor["escola_id"]
		}
		var res2 = await request_async("/rest/v1/respostas", HTTPClient.METHOD_POST, payload_minimo)
		if res2.get("success", false):
			return
		# Ainda falhou - enfileira para reenvio com payload completo
		enfileirar_sync_offline("/rest/v1/respostas", payload_servidor)
		return
	
	# Qualquer outro erro (401, 500...) - enfileira para reenvio
	enfileirar_sync_offline("/rest/v1/respostas", payload_servidor)

# --- SISTEMA DE FILA E CACHE OFFLINE (RESILIÊNCIA EM REDES INSTÁVEIS) ---

func enfileirar_sync_offline(endpoint: String, payload: Dictionary) -> void:
	var queue: Array = _ler_array_persistente(OFFLINE_SYNC_QUEUE_FILE, OFFLINE_SYNC_STORAGE_KEY)
			
	var item = {
		"id": str(Time.get_unix_time_from_system()) + "_" + str(randi() % 10000),
		"endpoint": endpoint,
		"payload": payload,
		"tentativas": 0,
		"timestamp": Time.get_datetime_string_from_system()
	}
	# Limita a 500 registros para proteger o armazenamento do navegador/disco
	if queue.size() >= 500:
		queue.pop_front()
	queue.append(item)
	
	_salvar_array_persistente(OFFLINE_SYNC_QUEUE_FILE, OFFLINE_SYNC_STORAGE_KEY, queue)
	print("[Sync Offline] Evento enfileirado no buffer local: %s (Total pendente: %d)" % [endpoint, queue.size()])

func obter_tamanho_fila_sync() -> int:
	return _ler_array_persistente(OFFLINE_SYNC_QUEUE_FILE, OFFLINE_SYNC_STORAGE_KEY).size()

func sincronizar_telemetria_pendente_async() -> void:
	if _sincronizando_offline:
		return
	var queue: Array = _ler_array_persistente(OFFLINE_SYNC_QUEUE_FILE, OFFLINE_SYNC_STORAGE_KEY)
	if queue.is_empty():
		return
		
	_sincronizando_offline = true
	var itens_restantes: Array = []
	var sincronizados_com_sucesso = 0
	var conexao_ativa = true
	
	for item in queue:
		if not item is Dictionary:
			continue
		
		# Se já sabemos que a conexão caiu nesta rodada, preserva o restante na fila
		if not conexao_ativa:
			itens_restantes.append(item)
			continue
			
		var endpoint: String = item.get("endpoint", "")
		var payload: Dictionary = item.get("payload", {})
		var tentativas: int = int(item.get("tentativas", 0)) + 1
		
		var res = await request_async(endpoint, HTTPClient.METHOD_POST, payload)
		if res.get("success", false):
			sincronizados_com_sucesso += 1
		else:
			var code = res.get("code", 0)
			if code == 0:
				conexao_ativa = false
				item["tentativas"] = tentativas
				itens_restantes.append(item)
			elif code == 400 and endpoint == "/rest/v1/respostas":
				var baseline_minimo = {
					"pergunta_id": payload.get("pergunta_id", 0),
					"acertou": payload.get("acertou", false),
					"andar_id": payload.get("andar_id", 1),
					"aluno_nick": payload.get("aluno_nick", get_active_nick())
				}
				var res_fallback = await request_async("/rest/v1/respostas", HTTPClient.METHOD_POST, baseline_minimo)
				if res_fallback.get("success", false):
					sincronizados_com_sucesso += 1
				else:
					if tentativas < 3:
						item["tentativas"] = tentativas
						itens_restantes.append(item)
			elif code == 404:
				# Tabela opcional não configurada no Supabase, descarta para não congestionar a fila
				pass
			else:
				if tentativas < 3:
					item["tentativas"] = tentativas
					itens_restantes.append(item)
					
	_salvar_array_persistente(OFFLINE_SYNC_QUEUE_FILE, OFFLINE_SYNC_STORAGE_KEY, itens_restantes)
		
	_sincronizando_offline = false
	
	if sincronizados_com_sucesso > 0:
		print("[Sync Offline] %d registros pendentes sincronizados com o Supabase! Restantes na fila: %d" % [sincronizados_com_sucesso, itens_restantes.size()])
		telemetria_sincronizada.emit(sincronizados_com_sucesso)


# monta o header e envia requisicao pro supabase
# exemplo: /rest/v1/alunos
func make_request(endpoint: String, method: HTTPClient.Method, data: Dictionary = {}) -> void:
	var url: String = supabase_url + endpoint
	
	var http := HTTPRequest.new()
	http.accept_gzip = false
	http.timeout = 5.0
	add_child(http)
	
	# headers obrigatorios
	var auth_bearer = user_token if not user_token.is_empty() else supabase_key
	var headers: PackedStringArray = [
		"apikey: " + supabase_key,
		"Authorization: Bearer " + auth_bearer,
		"Content-Type: application/json",
		"Prefer: return=representation"
	]
	
	var body: String = ""
	# converte pra json se tiver corpo
	if not data.is_empty():
		body = JSON.stringify(data)

	http.request_completed.connect(func(result: int, response_code: int, res_headers: PackedStringArray, res_body: PackedByteArray):
		_on_request_completed(result, response_code, res_headers, res_body)
		http.queue_free()
	)

	# dispara requisicao
	var error = http.request(url, headers, method, body)
	
	if error != OK:
		push_error("deu ruim na req pra: " + url + " - erro: " + str(error))
		http.queue_free()
		auth_erro.emit("Falha de conexão com o servidor (" + str(error) + ")")

# retorno do supabase
func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var body_text = body.get_string_from_utf8()
	var json: JSON = JSON.new()
	var erro_json = json.parse(body_text)
	
	if erro_json != OK:
		push_error("erro no parse do json: " + body_text)
		if response_code < 200 or response_code >= 300:
			auth_erro.emit("Erro no servidor (%d)" % response_code)
		return
		
	var dados = json.data
	
	if response_code >= 200 and response_code < 300:
		# sucesso na auth (login ou token)
		if dados is Dictionary and dados.has("access_token"):
			print("usuario logou com sucesso!")
			
			# Salvando os dados locais do player na memoria
			user_token = dados.access_token
			user_refresh_token = str(dados.get("refresh_token", user_refresh_token))
			
			if dados.has("user") and dados.user is Dictionary:
				var u = dados.user
				user_id = str(u.get("id", ""))
				if u.has("email") and u.email.to_lower() == "admin@synthesis.com":
					is_admin = true
					print("👑 Bem-vindo, Administrador!")
				else:
					is_admin = false
					
				if u.has("user_metadata") and u.user_metadata is Dictionary:
					user_nick = u.user_metadata.get("nick", "Admin" if is_admin else "Mago Desconhecido")
					user_cla = u.user_metadata.get("cla", "Nenhum")
				else:
					user_nick = "Admin" if is_admin else "Mago Desconhecido"
					user_cla = "Nenhum"
				
				# transfere o progresso de convidado ao logar
				if RankingManager.has_method("fundir_conta_guest"):
					RankingManager.fundir_conta_guest(user_nick, user_cla)
				
			# Reseta contador de tentativas falhas de login
			tentativas_login_falhas = 0
			bloqueio_login_ate = 0
			
			# Persiste sessão no localStorage para sobreviver a recarregamentos
			_salvar_sessao_web()
			
			auth_sucesso.emit(user_token)
			
			# Aciona sincronização de eventos que estavam guardados na fila offline
			sincronizar_telemetria_pendente_async()
		elif typeof(dados) == TYPE_DICTIONARY and (dados.has("user") or dados.has("email")):
			print("usuario cadastrado ou atualizado com sucesso!")
			var user_data = dados.get("user", dados)
			if user_data is Dictionary and user_data.has("user_metadata") and user_data.user_metadata is Dictionary:
				user_nick = user_data.user_metadata.get("nick", user_nick)
				user_cla = user_data.user_metadata.get("cla", user_cla)
				print("Metadata do usuario atualizada! Nick: ", user_nick, " Cla: ", user_cla)
			
			# avisa se o login ou cadastro deu certo
			if dados.has("user") and not dados.has("access_token") and user_token.is_empty():
				auth_sucesso.emit("cadastrado_ok")
			else:
				dados_recebidos.emit(dados)
		elif body_text == "{}" or body_text == "":
			# recuperacao de senha retorna body vazio
			print("Email de recuperacao enviado!")
			reset_senha_enviado.emit()
		else:
			if typeof(dados) == TYPE_ARRAY and dados.size() > 0 and dados[0].has("question"):
				print("Perguntas carregadas do banco!")
				perguntas_recebidas.emit(dados)
			else:
				print("dados gerais chegaram.")
				dados_recebidos.emit(dados)
	else:
		# caso de erro
		var msg_erro = "Erro da API"
		if typeof(dados) == TYPE_DICTIONARY:
			if dados.has("error_description"):
				msg_erro = dados["error_description"]
			elif dados.has("msg"):
				msg_erro = dados["msg"]
			elif dados.has("message"):
				msg_erro = dados["message"]
		
		# Limite de tentativas de login (Rate limiting)
		var msg_lower = msg_erro.to_lower()
		if "invalid login credentials" in msg_lower or "invalid credentials" in msg_lower:
			tentativas_login_falhas += 1
			if tentativas_login_falhas >= MAX_TENTATIVAS_LOGIN:
				bloqueio_login_ate = int(Time.get_unix_time_from_system()) + TEMPO_BLOQUEIO_LOGIN
				tentativas_login_falhas = 0
				msg_erro = "Limite de tentativas incorretas excedido!\nAcesso temporariamente bloqueado por %d segundos." % TEMPO_BLOQUEIO_LOGIN
			else:
				var restam = MAX_TENTATIVAS_LOGIN - tentativas_login_falhas
				msg_erro = "E-mail ou senha incorretos!\n(Tentativas restantes antes do bloqueio: %d)" % restam
		
		push_error("erro http: " + str(response_code) + " | " + msg_erro)
		auth_erro.emit(msg_erro)

# --- PERSISTÊNCIA DE SESSÃO (localStorage Web + arquivo local Desktop) ---

func _salvar_sessao_web() -> void:
	var dados_sessao = JSON.stringify({
		"token": user_token,
		"refresh_token": user_refresh_token,
		"nick": user_nick,
		"cla": user_cla,
		"user_id": user_id,
		"is_admin": is_admin
	})
	web_storage_set(SESSION_KEY, dados_sessao)
	var f = FileAccess.open(SESSION_FILE, FileAccess.WRITE)
	if f:
		f.store_string(dados_sessao)
		f.close()
	print("[DatabaseManager] Sessão salva localmente para: ", user_nick)

func _restaurar_sessao_web() -> void:
	var raw: String = web_storage_get(SESSION_KEY)
	if raw.is_empty() and FileAccess.file_exists(SESSION_FILE):
		var f = FileAccess.open(SESSION_FILE, FileAccess.READ)
		if f:
			raw = f.get_as_text()
			f.close()
	if raw.is_empty():
		print("[DatabaseManager] Nenhuma sessão salva encontrada.")
		return
	var json = JSON.new()
	if json.parse(raw) != OK:
		print("[DatabaseManager] Sessão salva corrompida. Ignorando.")
		_limpar_sessao_web()
		return
	var d = json.data
	if not (d is Dictionary) or not d.has("token") or str(d["token"]).is_empty():
		print("[DatabaseManager] Sessão salva inválida. Ignorando.")
		_limpar_sessao_web()
		return
	user_token = str(d.get("token", ""))
	user_refresh_token = str(d.get("refresh_token", ""))
	user_nick  = str(d.get("nick",  "Mago Desconhecido"))
	user_cla   = str(d.get("cla",   "Nenhum"))
	user_id    = str(d.get("user_id", ""))
	is_admin   = bool(d.get("is_admin", false))
	print("[DatabaseManager] Sessão restaurada para: ", user_nick)
	# Verifica silenciosamente se o token ainda é válido no Supabase
	_verificar_token_restaurado()

func renovar_sessao_async() -> bool:
	_ultimo_refresh_rejeitado = false
	if user_refresh_token.is_empty():
		_ultimo_refresh_rejeitado = true
		return false
	print("[DatabaseManager] Solicitando novo access_token com refresh_token...")
	var res = await request_async("/auth/v1/token?grant_type=refresh_token", HTTPClient.METHOD_POST, {
		"refresh_token": user_refresh_token
	})
	if res.get("success", false) and res.get("data") is Dictionary:
		var dados = res["data"]
		if dados.has("access_token"):
			user_token = dados["access_token"]
			user_refresh_token = str(dados.get("refresh_token", user_refresh_token))
			if dados.has("user") and dados["user"] is Dictionary:
				var u = dados["user"]
				user_id = str(u.get("id", user_id))
				if u.has("user_metadata") and u["user_metadata"] is Dictionary:
					user_nick = u["user_metadata"].get("nick", user_nick)
					user_cla  = u["user_metadata"].get("cla",  user_cla)
			_salvar_sessao_web()
			print("[DatabaseManager] Sessão renovada com sucesso! Nick: ", user_nick)
			return true
	var code: int = int(res.get("code", 0))
	if code in [400, 401, 403]:
		_ultimo_refresh_rejeitado = true
	print("[DatabaseManager] Falha ao renovar sessão com refresh_token (code=%d)." % code)
	return false

func _verificar_token_restaurado() -> void:
	var res = await request_async("/auth/v1/user", HTTPClient.METHOD_GET)
	if res.get("success", false) and res.get("data") is Dictionary:
		var u = res["data"]
		# Atualiza metadados frescos do servidor
		if u.has("user_metadata") and u.user_metadata is Dictionary:
			user_nick = u.user_metadata.get("nick", user_nick)
			user_cla  = u.user_metadata.get("cla",  user_cla)
		if u.has("email") and u.email.to_lower() == "admin@synthesis.com":
			is_admin = true
		user_id = str(u.get("id", user_id))
		_salvar_sessao_web() # Atualiza localStorage e arquivo local com dados frescos
		print("[DatabaseManager] Token restaurado validado com sucesso.")
		auth_sucesso.emit(user_token)
	else:
		var code: int = int(res.get("code", 0))
		# Falha de rede/timeout (code == 0 ou 5xx): mantém a sessão restaurada localmente sem deslogar!
		if code == 0 or code >= 500:
			print("[DatabaseManager] Servidor inacessível no momento (code=%d). Mantendo sessão local de '%s'." % [code, user_nick])
			auth_sucesso.emit(user_token)
			return
		# Se o access_token expirou (401/403), tenta renovar silenciosamente usando o refresh_token
		if not user_refresh_token.is_empty():
			print("[DatabaseManager] Token expirado. Tentando renovar com refresh_token...")
			var renovou = await renovar_sessao_async()
			if renovou:
				auth_sucesso.emit(user_token)
				return
			if not _ultimo_refresh_rejeitado:
				print("[DatabaseManager] Renovação falhou por conexão. Mantendo sessão local de '%s'." % user_nick)
				auth_sucesso.emit(user_token)
				return
		# Apenas encerra sessão se o servidor explicitamente rejeitou o token e o refresh_token
		print("[DatabaseManager] Token restaurado rejeitado pelo servidor. Fazendo logout.")
		logout()

func _limpar_sessao_web() -> void:
	web_storage_remove(SESSION_KEY)
	if FileAccess.file_exists(SESSION_FILE):
		DirAccess.remove_absolute(SESSION_FILE)

func logout() -> void:
	user_token = ""
	user_refresh_token = ""
	user_nick  = ""
	user_cla   = "Nenhum"
	user_id    = ""
	is_admin   = false
	_limpar_sessao_web()
	sessao_encerrada.emit()
	print("[DatabaseManager] Logout realizado. Sessão encerrada.")

# funcoes de login e cadastro

func cadastrar_usuario(email: String, senha: String, nick: String) -> void:
	print("tentando cadastrar: ", email)
	var data = {
		"email": email,
		"password": senha,
		"data": {
			"nick": nick,
			"cla": "Nenhum"
		}
	}
	# rota pra criar conta
	make_request("/auth/v1/signup", HTTPClient.METHOD_POST, data)

func tempo_restante_bloqueio_login() -> int:
	var agora = int(Time.get_unix_time_from_system())
	if agora < bloqueio_login_ate:
		return bloqueio_login_ate - agora
	return 0

func tempo_restante_recuperacao() -> int:
	var agora = int(Time.get_unix_time_from_system())
	var decorrido = agora - _ultimo_reset_senha_timestamp
	if decorrido < COOLDOWN_RESET_SENHA:
		return COOLDOWN_RESET_SENHA - decorrido
	return 0

func fazer_login(email: String, senha: String) -> void:
	var resto = tempo_restante_bloqueio_login()
	if resto > 0:
		auth_erro.emit("Muitas tentativas incorretas!\nAcesso temporariamente bloqueado por mais %d segundos." % resto)
		return
		
	print("tentando logar: ", email)
	var data = {
		"email": email,
		"password": senha
	}
	# rota de login com token
	make_request("/auth/v1/token?grant_type=password", HTTPClient.METHOD_POST, data)

func recuperar_senha(email: String) -> void:
	var resto = tempo_restante_recuperacao()
	if resto > 0:
		auth_erro.emit("Aguarde %d segundos antes de solicitar um novo e-mail de recuperação." % resto)
		return
		
	_ultimo_reset_senha_timestamp = int(Time.get_unix_time_from_system())
	print("Pedindo reset de senha para: ", email)
	var data = {
		"email": email
	}
	# rota pra recuperar senha
	make_request("/auth/v1/recover", HTTPClient.METHOD_POST, data)

# --- VALIDAÇÃO DE NICK E FILTRO DE TERMOS INAPROPRIADOS (+18) ---

const TERMOS_PROIBIDOS_SUBSTRING: Array[String] = [
	"puta", "puto", "putaria", "porra", "caralho", "caralh", "cacete",
	"arrombado", "arrombada", "buceta", "boceta", "bucet", "pica", "piroca",
	"penis", "pauzao", "vagina", "viado", "veado", "viadinho", "merda", "bosta",
	"vadia", "foder", "foda", "fude", "transar", "punheta", "siririca",
	"boquete", "orgasmo", "pedofilo", "pedofilia", "estupro", "nazista", "hitler",
	"prostituta", "prostituto", "cocaina", "maconha", "fuck", "bitch",
	"cunt", "nigger", "dick", "pussy", "asshole", "blowjob", "hentai", "porn"
]

const TERMOS_PROIBIDOS_EXATOS: Array[String] = [
	"cu", "krl", "vtnc", "fdp", "sexo", "anus", "nude", "rola"
]

func normalizar_texto_seguro(texto: String) -> String:
	var s = texto.to_lower().strip_edges()
	var acentos = {
		"á": "a", "à": "a", "ã": "a", "â": "a", "ä": "a",
		"é": "e", "è": "e", "ê": "e", "ë": "e",
		"í": "i", "ì": "i", "î": "i", "ï": "i",
		"ó": "o", "ò": "o", "õ": "o", "ô": "o", "ö": "o",
		"ú": "u", "ù": "u", "û": "u", "ü": "u",
		"ç": "c"
	}
	for k in acentos.keys():
		s = s.replace(k, acentos[k])
		
	var leet = {
		"@": "a", "4": "a", "3": "e", "1": "i", "!": "i",
		"0": "o", "5": "s", "$": "s", "7": "t", "+": "t",
		"8": "b"
	}
	for k in leet.keys():
		s = s.replace(k, leet[k])
		
	return s

func validar_nick(nick: String) -> Dictionary:
	var limpo = nick.strip_edges()
	if limpo.is_empty():
		return {"valido": false, "erro": "O nome não pode estar vazio!"}
		
	if limpo.length() < 3:
		return {"valido": false, "erro": "O nome deve ter no mínimo 3 caracteres."}
		
	if limpo.length() > 16:
		return {"valido": false, "erro": "O nome deve ter no máximo 16 caracteres."}
		
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9_ ]+$")
	if not regex.search(limpo):
		return {"valido": false, "erro": "O nome pode conter apenas letras, números e espaços."}
		
	if limpo.to_lower() == "admin":
		return {"valido": false, "erro": "O nome 'Admin' é reservado ao sistema."}

	var norm = normalizar_texto_seguro(limpo)
	var sem_separadores = norm.replace(" ", "").replace("_", "").replace(".", "").replace("-", "")
	
	for termo in TERMOS_PROIBIDOS_SUBSTRING:
		if sem_separadores.find(termo) != -1 or norm.find(termo) != -1:
			return {"valido": false, "erro": "O nome contém termos inapropriados para ambiente escolar."}
			
	var palavras = norm.replace("_", " ").split(" ", false)
	for p in palavras:
		var p_limpa = p.strip_edges()
		for termo_exato in TERMOS_PROIBIDOS_EXATOS:
			if p_limpa == termo_exato:
				return {"valido": false, "erro": "O nome contém termos inapropriados para ambiente escolar."}
				
	return {"valido": true, "erro": ""}

func _migrar_nick_analytics_locais(nick_antigo: String, novo_nick: String) -> void:
	if nick_antigo.is_empty() or novo_nick.is_empty() or nick_antigo == novo_nick:
		return

	var arquivos_planos = [
		{"file": ANALYTICS_FILE, "key": ANALYTICS_STORAGE_KEY},
		{"file": MINIGAMES_ANALYTICS_FILE, "key": MINIGAMES_STORAGE_KEY},
		{"file": GAMEPLAY_TELEMETRIA_FILE, "key": GAMEPLAY_TELEMETRIA_STORAGE_KEY}
	]
	for cfg in arquivos_planos:
		var lista: Array = _ler_array_persistente(cfg["file"], cfg["key"])
		if lista.is_empty():
			continue
		var alterou := false
		for item in lista:
			if item is Dictionary and str(item.get("aluno_nick", "")).strip_edges() == nick_antigo:
				item["aluno_nick"] = novo_nick
				alterou = true
		if alterou:
			_salvar_array_persistente(cfg["file"], cfg["key"], lista)

	# Fila offline pendente também pode conter eventos ainda não enviados do nick antigo
	var queue: Array = _ler_array_persistente(OFFLINE_SYNC_QUEUE_FILE, OFFLINE_SYNC_STORAGE_KEY)
	if not queue.is_empty():
		var alt_fila := false
		for item in queue:
			if item is Dictionary and item.get("payload") is Dictionary:
				var p: Dictionary = item["payload"]
				if str(p.get("aluno_nick", "")).strip_edges() == nick_antigo:
					p["aluno_nick"] = novo_nick
					alt_fila = true
				if str(p.get("player_name", "")).strip_edges() == nick_antigo:
					p["player_name"] = novo_nick
					alt_fila = true
		if alt_fila:
			_salvar_array_persistente(OFFLINE_SYNC_QUEUE_FILE, OFFLINE_SYNC_STORAGE_KEY, queue)

## Migra TODOS os dados do nick antigo para o novo (analytics locais, fila offline, ranking, respostas, minigames, telemetria e clã).
func migrar_dados_nick_async(nick_antigo: String, novo_nick: String) -> void:
	var antigo := nick_antigo.strip_edges()
	var limpo := novo_nick.strip_edges()
	if antigo.is_empty() or limpo.is_empty() or antigo == limpo:
		return
	if antigo.to_lower() == "admin" or limpo.to_lower() == "admin":
		return

	# 1. Migra todos os arquivos analíticos locais + fila offline + localStorage Web
	_migrar_nick_analytics_locais(antigo, limpo)

	var rm = get_node_or_null("/root/RankingManager")
	if rm and rm.has_method("_migrar_nick_cache_local"):
		rm._migrar_nick_cache_local(antigo, limpo)

	# 2. Tenta migração atômica no Supabase via função RPC (migra tudo e mescla duplicatas)
	var rpc_payload := {"p_nick_antigo": antigo, "p_nick_novo": limpo}
	var res_rpc := await request_async("/rest/v1/rpc/migrar_nick_jogador", HTTPClient.METHOD_POST, rpc_payload)

	if not res_rpc.get("success", false):
		var code: int = int(res_rpc.get("code", 0))
		if code == 0:
			# Sem internet no momento: enfileira para executar automaticamente quando voltar
			enfileirar_sync_offline("/rest/v1/rpc/migrar_nick_jogador", rpc_payload)
		else:
			# Fallback REST caso a RPC ainda não tenha sido aplicada no banco
			if rm and rm.has_method("_migrar_ranking_online_async"):
				await rm._migrar_ranking_online_async(antigo, limpo)
			var antigo_enc := antigo.uri_encode()
			await request_async("/rest/v1/respostas?aluno_nick=eq." + antigo_enc, HTTPClient.METHOD_PATCH, {"aluno_nick": limpo})
			await request_async("/rest/v1/minigames_respostas?aluno_nick=eq." + antigo_enc, HTTPClient.METHOD_PATCH, {"aluno_nick": limpo})
			await request_async("/rest/v1/telemetria_gameplay?aluno_nick=eq." + antigo_enc, HTTPClient.METHOD_PATCH, {"aluno_nick": limpo})
			if not user_token.is_empty():
				await request_async("/rest/v1/MembrosCla?player_name=eq." + antigo_enc, HTTPClient.METHOD_PATCH, {"player_name": limpo})
				await request_async("/rest/v1/Clas?lider=eq." + antigo_enc, HTTPClient.METHOD_PATCH, {"lider": limpo})

	# 3. Recarrega rankings e clãs para refletir imediatamente na interface
	if rm:
		await rm.load_ranking()
		await rm.load_ranking_periodo("quimica")
		await rm.load_ranking_periodo("fisica")
		await rm.load_ranking_periodo("biologia")

	var cm = get_node_or_null("/root/ClanManager")
	if cm and cm.has_method("load_clans"):
		await cm.load_clans()

	print("[DatabaseManager] Dados migrados de '%s' para '%s'." % [antigo, limpo])

func atualizar_nick_usuario_async(novo_nick: String) -> Dictionary:
	var limpo: String = novo_nick.strip_edges()
	var validacao = validar_nick(limpo)
	if not validacao["valido"]:
		return validacao

	if is_admin:
		return {"valido": false, "erro": "A conta de Administrador possui nome exclusivo e fixo."}

	var rm = get_node_or_null("/root/RankingManager")

	# Jogador visitante (sem conta): salva novo nick e migra TODOS os dados locais e online
	if user_token.is_empty():
		var nick_antigo: String = rm.get_local_nick() if rm and rm.has_method("get_local_nick") else get_active_nick()
		if rm and rm.has_method("set_local_nick"):
			rm.set_local_nick(limpo)
		if not nick_antigo.is_empty() and nick_antigo != limpo:
			await migrar_dados_nick_async(nick_antigo, limpo)
		print("[DatabaseManager] Nick de visitante atualizado de '%s' para '%s'!" % [nick_antigo, limpo])
		nick_alterado.emit(limpo)
		return {"valido": true, "erro": ""}

	var nick_antigo = user_nick
	user_nick = limpo
	_salvar_sessao_web()

	# 1. Atualiza user_metadata no Supabase Auth
	var payload_auth = {
		"data": {
			"nick": limpo
		}
	}
	await request_async("/auth/v1/user", HTTPClient.METHOD_PUT, payload_auth)

	# 2. Migra todos os dados (ranking, respostas, minigames, telemetria, clãs e cache local)
	if not nick_antigo.is_empty() and nick_antigo != limpo:
		await migrar_dados_nick_async(nick_antigo, limpo)

	print("[DatabaseManager] Nick alterado de '%s' para '%s' com sucesso!" % [nick_antigo, limpo])
	nick_alterado.emit(limpo)
	return {"valido": true, "erro": ""}

# busca perguntas do jogo

# puxa perguntas do banco
func puxar_alunos() -> void:
	print("tentando buscar os alunos no banco...")
	# rota da tabela no supabase
	make_request("/rest/v1/alunos?select=*", HTTPClient.METHOD_GET)

func puxar_perguntas(andar_id: int = 1) -> void:
	print("buscando perguntas do andar: ", andar_id, "...")
	var query = "/rest/v1/perguntas?select=*"
	if andar_id > 0:
		query += "&andar_id=eq." + str(andar_id)
	_puxar_perguntas_async(query, andar_id)

func _puxar_perguntas_async(query: String, andar_id: int) -> void:
	var res = await request_async(query, HTTPClient.METHOD_GET)
	if res["success"] and res["data"] is Array and res["data"].size() > 0:
		print("Perguntas carregadas do banco via async!")
		perguntas_recebidas.emit(res["data"])
	else:
		print("Falha ao puxar perguntas online (offline?). Carregando fallback local...")
		var locais = carregar_perguntas_locais(andar_id)
		perguntas_recebidas.emit(locais)

func carregar_perguntas_locais(andar_id: int = 0) -> Array:
	var path = "res://data/questions.json"
	if not FileAccess.file_exists(path):
		push_error("Arquivo local de perguntas nao encontrado em: " + path)
		return []
		
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(content) == OK and json.data is Array:
		var todas: Array = json.data
		if andar_id <= 0:
			return todas
		var filtradas = []
		for p in todas:
			if p is Dictionary and int(p.get("andar_id", 0)) == andar_id:
				filtradas.append(p)
		return filtradas
	else:
		push_error("Erro ao fazer parse de data/questions.json")
		return []

# funcoes de cla no banco

func atualizar_cla_usuario(novo_cla: String) -> void:
	print("tentando atualizar cla do usuario para: ", novo_cla)
	user_cla = novo_cla
	_salvar_sessao_web()
	
	if user_token.is_empty():
		print("jogador offline. atualizado localmente.")
		return
		
	var data = {
		"data": {
			"cla": novo_cla
		}
	}
	make_request("/auth/v1/user", HTTPClient.METHOD_PUT, data)

# faz requisicao http e espera resposta
func request_async(endpoint: String, method: HTTPClient.Method, data: Dictionary = {}, retry_auth: bool = true, force_anon: bool = false) -> Dictionary:
	var url: String = supabase_url + endpoint
	var http: HTTPRequest = HTTPRequest.new()
	http.accept_gzip = false
	http.timeout = 10.0
	add_child(http)
	
	var auth_bearer: String = supabase_key if (force_anon or user_token.is_empty()) else user_token
	var headers: PackedStringArray = [
		"apikey: " + supabase_key,
		"Authorization: Bearer " + auth_bearer,
		"Content-Type: application/json",
		"Prefer: return=representation"
	]
	
	var body: String = ""
	if not data.is_empty():
		body = JSON.stringify(data)
		
	var err = http.request(url, headers, method, body)
	if err != OK:
		http.queue_free()
		return {"success": false, "code": 0, "message": "Falha ao iniciar requisição HTTP"}
		
	var response = await http.request_completed
	http.queue_free()
	
	var result_status: int = response[0]
	var response_code: int = response[1]
	var response_body: PackedByteArray = response[3]
	
	if result_status != HTTPRequest.RESULT_SUCCESS:
		return {"success": false, "code": response_code, "message": "Falha de conexão ou tempo limite excedido"}
	
	var body_text: String = response_body.get_string_from_utf8()
	var json: JSON = JSON.new()
	var parse_err = json.parse(body_text)
	
	var res_data = json.data if parse_err == OK else null
	
	if response_code >= 200 and response_code < 300:
		return {"success": true, "code": response_code, "data": res_data}
	
	if response_code == 401 and retry_auth and not force_anon and not user_token.is_empty() and not endpoint.begins_with("/auth/v1/"):
		var renovou := await renovar_sessao_async()
		if renovou:
			return await request_async(endpoint, method, data, false, false)
		var eh_endpoint_publico := (method == HTTPClient.METHOD_GET) or endpoint.begins_with("/rest/v1/respostas") or endpoint.begins_with("/rest/v1/minigames_respostas") or endpoint.begins_with("/rest/v1/telemetria_gameplay") or endpoint.begins_with("/rest/v1/rankinggeral")
		if eh_endpoint_publico:
			return await request_async(endpoint, method, data, false, true)
	
	var error_msg: String = "Erro da API Supabase"
	if res_data is Dictionary:
		error_msg = res_data.get("error_description", res_data.get("msg", res_data.get("message", "Erro desconhecido")))
	elif res_data is Array and res_data.size() > 0 and res_data[0] is Dictionary:
		error_msg = res_data[0].get("message", "Erro desconhecido")
	return {"success": false, "code": response_code, "message": error_msg}

func request_select_all_async(base_endpoint: String, page_size: int = 1000, max_rows: int = 20000) -> Dictionary:
	var acumulado: Array = []
	var offset: int = 0
	var sep: String = "&" if base_endpoint.contains("?") else "?"
	while offset < max_rows:
		var ep := "%s%slimit=%d&offset=%d" % [base_endpoint, sep, page_size, offset]
		var res := await request_async(ep, HTTPClient.METHOD_GET)
		if not res.get("success", false) or not (res.get("data") is Array):
			if acumulado.is_empty():
				return res
			break
		var lote: Array = res["data"]
		acumulado.append_array(lote)
		if lote.size() < page_size:
			break
		offset += page_size
	return {"success": true, "code": 200, "data": acumulado}

# deleta pergunta no supabase e no json local
func remover_pergunta(pergunta_id: int) -> Dictionary:
	print("[DatabaseManager] Solicitando exclusao da pergunta #", pergunta_id)
	# remove respostas vinculadas primeiro
	await request_async("/rest/v1/respostas?pergunta_id=eq." + str(pergunta_id), HTTPClient.METHOD_DELETE)
	
	# deleta a pergunta no banco
	var res = await request_async("/rest/v1/perguntas?id=eq." + str(pergunta_id), HTTPClient.METHOD_DELETE)
	
	# remove do json local
	remover_pergunta_local(pergunta_id)
	
	# remove da memoria
	if QuizManager:
		var nova_lista = []
		for q in QuizManager.questions:
			if q is Dictionary and int(q.get("id", -1)) == pergunta_id:
				continue
			nova_lista.append(q)
		QuizManager.questions = nova_lista
		QuizManager.reset_questions()
		
	return res

# tira questao do questions.json local
func remover_pergunta_local(pergunta_id: int) -> bool:
	var path = "res://data/questions.json"
	if not FileAccess.file_exists(path):
		return false
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return false
	var content = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(content) == OK and json.data is Array:
		var todas: Array = json.data
		var nova_lista = []
		var encontrada = false
		for p in todas:
			if p is Dictionary and int(p.get("id", -1)) == pergunta_id:
				encontrada = true
				continue
			nova_lista.append(p)
		if encontrada:
			var wfile = FileAccess.open(path, FileAccess.WRITE)
			if wfile:
				wfile.store_string(JSON.stringify(nova_lista, "\t"))
				wfile.close()
				print("[DatabaseManager] Pergunta #", pergunta_id, " removida de ", path)
				return true
	return false

# salva questao no questions.json local
func salvar_pergunta_local(dados: Dictionary) -> bool:
	var path = "res://data/questions.json"
	var todas: Array = []
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(content) == OK and json.data is Array:
				todas = json.data
				
	var p_id = int(dados.get("id", -1))
	var atualizou = false
	if p_id > 0:
		for i in range(todas.size()):
			if todas[i] is Dictionary and int(todas[i].get("id", -1)) == p_id:
				todas[i] = dados
				atualizou = true
				break
	if not atualizou:
		todas.append(dados)
		
	var wfile = FileAccess.open(path, FileAccess.WRITE)
	if wfile:
		wfile.store_string(JSON.stringify(todas, "\t"))
		wfile.close()
		print("[DatabaseManager] Pergunta sincronizada também no questions.json local.")
		return true
	return false

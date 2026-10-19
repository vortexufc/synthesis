extends Node

# chaves do nosso banco no supabase
var supabase_url: String = "https://uszmgqludyymspsarciw.supabase.co"
# chave do supabase via project settings
var supabase_key: String = ProjectSettings.get_setting("application/config/supabase_key", "")

# dados do jogador logado
var user_token: String = ""
var user_nick: String = ""
var user_cla: String = "Nenhum"
var active_dungeon: String = "" # Registra a masmorra escolhida no hub
var is_admin: bool = false # Define se a conta atual é um professor/pesquisador


# sinal pra avisar outras partes do jogo q a resposta chegou
signal dados_recebidos(dados: Array)
signal perguntas_recebidas(perguntas: Array)

# sinais para a tela de login e cadastro
signal auth_sucesso(token: String)
signal auth_erro(mensagem: String)
signal reset_senha_enviado()

# no de requisicoes http
var http_request: HTTPRequest

func _ready() -> void:
	# cria o no http
	http_request = HTTPRequest.new()
	http_request.accept_gzip = false
	http_request.timeout = 5.0
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	carregar_progresso()
	print("banco carregado!")
	
	# 1. Verifica parâmetro de URL (?turma= ou ?escola=) no navegador Web
	_verificar_parametro_url_web()
	
	# 2. Sincroniza sessão ativa global no Supabase (para clientes Desktop e Web)
	sincronizar_sessao_global_supabase()

# progresso salvo localmente
const SAVE_FILE = "user://progresso.json"
const SESSOES_FILE = "user://sessoes_escolas.json"
const ANALYTICS_FILE = "user://pesquisa_analytics.json"

var escola_ativa_id: String = "geral"
var escola_ativa_nome: String = "Geral (Padrão)"

signal sessao_escola_alterada(id_escola: String, nome_escola: String)

func salvar_progresso() -> void:
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	var data = {
		"active_dungeon": active_dungeon,
		"escola_ativa_id": escola_ativa_id,
		"escola_ativa_nome": escola_ativa_nome
	}
	file.store_string(JSON.stringify(data))
	file.close()

func carregar_progresso() -> void:
	if not FileAccess.file_exists(SAVE_FILE):
		return
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	var json = JSON.new()
	if json.parse(file.get_as_text()) == OK:
		var data = json.data
		if data is Dictionary:
			active_dungeon = data.get("active_dungeon", "")
			escola_ativa_id = data.get("escola_ativa_id", "geral")
			escola_ativa_nome = data.get("escola_ativa_nome", "Geral (Padrão)")
	file.close()

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

func sincronizar_sessao_global_supabase() -> void:
	if has_meta("escola_fixada_por_url"):
		return
	var res = await request_async("/rest/v1/sessoes_escolas?ativa=eq.true&select=*&limit=1", HTTPClient.METHOD_GET)
	if res.get("success", false) and res.get("data") is Array and not res["data"].is_empty():
		var row = res["data"][0]
		var s_id = str(row.get("id", "geral")).strip_edges()
		var s_nome = str(row.get("nome", "Geral")).strip_edges()
		if not s_id.is_empty() and (s_id != escola_ativa_id or s_nome != escola_ativa_nome):
			escola_ativa_id = s_id
			escola_ativa_nome = s_nome
			salvar_progresso()
			sessao_escola_alterada.emit(escola_ativa_id, escola_ativa_nome)
			print("[DatabaseManager] Sessão global sincronizada do Supabase: %s (%s)" % [escola_ativa_nome, escola_ativa_id])

func carregar_sessoes_escolas() -> Array[Dictionary]:
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
					if not ids_existentes.has(item["id"]):
						lista.append(item)
						ids_existentes[item["id"]] = true
		f.close()
	return lista

func carregar_sessoes_escolas_async() -> Array[Dictionary]:
	var lista = carregar_sessoes_escolas()
	var res = await request_async("/rest/v1/sessoes_escolas?select=*&order=created_at.asc", HTTPClient.METHOD_GET)
	if res.get("success", false) and res.get("data") is Array:
		var ids_existentes = {}
		for item in lista:
			ids_existentes[item["id"]] = true
		var mudou = false
		for item in res["data"]:
			if item is Dictionary and item.has("id") and item.has("nome"):
				var sid = str(item["id"]).strip_edges()
				var snome = str(item["nome"]).strip_edges()
				if not ids_existentes.has(sid):
					lista.append({
						"id": sid,
						"nome": snome,
						"data_criacao": str(item.get("data_criacao", item.get("created_at", ""))),
						"ativa": bool(item.get("ativa", false))
					})
					ids_existentes[sid] = true
					mudou = true
				if bool(item.get("ativa", false)) and not has_meta("escola_fixada_por_url"):
					if sid != escola_ativa_id:
						escola_ativa_id = sid
						escola_ativa_nome = snome
						salvar_progresso()
						sessao_escola_alterada.emit(escola_ativa_id, escola_ativa_nome)
		if mudou:
			salvar_sessoes_escolas(lista)
	return lista

func salvar_sessoes_escolas(sessoes: Array) -> void:
	var f = FileAccess.open(SESSOES_FILE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(sessoes, "\t"))
		f.close()

func adicionar_sessao_escola(nome: String, id_codigo: String = "") -> Dictionary:
	var sessoes = carregar_sessoes_escolas()
	var clean_id = id_codigo.strip_edges().to_lower().replace(" ", "_")
	if clean_id.is_empty():
		clean_id = "escola_" + str(Time.get_unix_time_from_system())
		
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
	var nova = adicionar_sessao_escola(nome, id_codigo)
	await _enviar_nova_sessao_supabase(nova)
	return nova

func _enviar_nova_sessao_supabase(nova_sessao: Dictionary) -> void:
	await request_async("/rest/v1/sessoes_escolas", HTTPClient.METHOD_POST, {
		"id": nova_sessao["id"],
		"nome": nova_sessao["nome"],
		"ativa": false
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

# --- ARMAZENAMENTO E CONSULTA DE ANALYTICS EDUCACIONAIS ---

func registrar_resposta_analytics(dados: Dictionary) -> void:
	var respostas: Array = []
	if FileAccess.file_exists(ANALYTICS_FILE):
		var f_read = FileAccess.open(ANALYTICS_FILE, FileAccess.READ)
		if f_read:
			var json = JSON.new()
			if json.parse(f_read.get_as_text()) == OK and json.data is Array:
				respostas = json.data
			f_read.close()
			
	respostas.append(dados)
	var f_write = FileAccess.open(ANALYTICS_FILE, FileAccess.WRITE)
	if f_write:
		f_write.store_string(JSON.stringify(respostas, "\t"))
		f_write.close()

func obter_respostas_analytics(filtro_escola_id: String = "") -> Array:
	if not FileAccess.file_exists(ANALYTICS_FILE):
		return []
	var f = FileAccess.open(ANALYTICS_FILE, FileAccess.READ)
	if not f: return []
	var json = JSON.new()
	var arr: Array = []
	if json.parse(f.get_as_text()) == OK and json.data is Array:
		var todas: Array = json.data
		if filtro_escola_id.is_empty() or filtro_escola_id == "todas":
			arr = todas
		else:
			for r in todas:
				if r is Dictionary and r.get("escola_id", "geral") == filtro_escola_id:
					arr.append(r)
	f.close()
	return arr

func enviar_resposta_supabase(data_resp_completo: Dictionary) -> void:
	# Envia payload enriquecido para o Supabase
	var payload_servidor = {
		"pergunta_id": data_resp_completo.get("pergunta_id", 0),
		"acertou": data_resp_completo.get("acertou", false),
		"andar_id": data_resp_completo.get("andar_id", 1),
		"aluno_nick": data_resp_completo.get("aluno_nick", "Mago")
	}
	
	# Se a tabela tiver colunas extras adicionadas via migração SQL
	if data_resp_completo.has("tempo_resposta"):
		payload_servidor["tempo_resposta"] = data_resp_completo["tempo_resposta"]
	if data_resp_completo.has("escola_id"):
		payload_servidor["escola_id"] = data_resp_completo["escola_id"]
	if data_resp_completo.has("alternativa_marcada"):
		payload_servidor["alternativa_marcada"] = data_resp_completo["alternativa_marcada"]
	if data_resp_completo.has("cla_aluno"):
		payload_servidor["cla_aluno"] = data_resp_completo["cla_aluno"]
	if data_resp_completo.has("consultas_grimorio"):
		payload_servidor["consultas_grimorio"] = data_resp_completo["consultas_grimorio"]
		
	var res = await request_async("/rest/v1/respostas", HTTPClient.METHOD_POST, payload_servidor)
	
	# Se falhar com erro 400 (ex: colunas extras ainda não criadas no Supabase), faz fallback para as 4 colunas padrão
	if not res.get("success", false) and res.get("code", 0) == 400:
		var baseline = {
			"pergunta_id": data_resp_completo.get("pergunta_id", 0),
			"acertou": data_resp_completo.get("acertou", false),
			"andar_id": data_resp_completo.get("andar_id", 1),
			"aluno_nick": data_resp_completo.get("aluno_nick", "Mago")
		}
		await request_async("/rest/v1/respostas", HTTPClient.METHOD_POST, baseline)


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
			
			if dados.has("user") and dados.user is Dictionary:
				var u = dados.user
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
				
			auth_sucesso.emit(user_token)
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
		push_error("erro http: " + str(response_code) + " | " + msg_erro)
		auth_erro.emit(msg_erro)

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

func fazer_login(email: String, senha: String) -> void:
	print("tentando logar: ", email)
	var data = {
		"email": email,
		"password": senha
	}
	# rota de login com token
	make_request("/auth/v1/token?grant_type=password", HTTPClient.METHOD_POST, data)

func recuperar_senha(email: String) -> void:
	print("Pedindo reset de senha para: ", email)
	var data = {
		"email": email
	}
	# rota pra recuperar senha
	make_request("/auth/v1/recover", HTTPClient.METHOD_POST, data)

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
func request_async(endpoint: String, method: HTTPClient.Method, data: Dictionary = {}) -> Dictionary:
	var url: String = supabase_url + endpoint
	var http: HTTPRequest = HTTPRequest.new()
	http.accept_gzip = false
	http.timeout = 5.0
	add_child(http)
	
	var auth_bearer: String = user_token if not user_token.is_empty() else supabase_key
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
	else:
		var error_msg: String = "Erro da API Supabase"
		if res_data is Dictionary:
			error_msg = res_data.get("error_description", res_data.get("msg", res_data.get("message", "Erro desconhecido")))
		elif res_data is Array and res_data.size() > 0 and res_data[0] is Dictionary:
			error_msg = res_data[0].get("message", "Erro desconhecido")
		return {"success": false, "code": response_code, "message": error_msg}

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

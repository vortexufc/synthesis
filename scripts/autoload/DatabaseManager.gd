extends Node

# chaves do nosso banco no supabase
var supabase_url: String = "https://uszmgqludyymspsarciw.supabase.co"
# chave lida do ProjectSettings pra nao ficar exposta no codigo
var supabase_key: String = ProjectSettings.get_setting("application/config/supabase_key", "")

# ---- SESSAO ATIVA DO JOGADOR ----
var user_token: String = ""
var user_nick: String = ""
var user_cla: String = "Nenhum"
# ---------------------------------

# sinal pra avisar outras partes do jogo q a resposta chegou
signal dados_recebidos(dados: Array)
signal perguntas_recebidas(perguntas: Array)

# sinais para a tela de login e cadastro
signal auth_sucesso(token: String)
signal auth_erro(mensagem: String)
signal reset_senha_enviado()

# no q cuida das requisições
var http_request: HTTPRequest

func _ready() -> void:
	# cria e add o http na cena
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	print("banco carregado!")

# funcao pra montar o header e mandar o get/post...
# endpoint tipo: "/rest/v1/alunos"
func make_request(endpoint: String, method: HTTPClient.Method, data: Dictionary = {}) -> void:
	var url: String = supabase_url + endpoint
	
	# headers q o supabase pede
	var auth_bearer = user_token if not user_token.is_empty() else supabase_key
	var headers: PackedStringArray = [
		"apikey: " + supabase_key,
		"Authorization: Bearer " + auth_bearer,
		"Content-Type: application/json",
		"Prefer: return=representation"
	]
	
	var body: String = ""
	# converte pra json se tiver data
	if not data.is_empty():
		body = JSON.stringify(data)

	# manda a req asincrona
	var error = http_request.request(url, headers, method, body)
	
	if error != OK:
		push_error("deu ruim na req pra: " + url)

# quando o supabase responde cai aqui
func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var body_text = body.get_string_from_utf8()
	var json: JSON = JSON.new()
	var erro_json = json.parse(body_text)
	
	if erro_json != OK:
		push_error("erro no parse do json: " + body_text)
		return
		
	var dados = json.data
	
	if response_code >= 200 and response_code < 300:
		# sucesso na auth (login ou token)
		if dados is Dictionary and dados.has("access_token"):
			print("usuario logou com sucesso!")
			
			# Salvando os dados locais do player na memoria
			user_token = dados.access_token
			
			if dados.has("user") and dados.user.has("user_metadata"):
				user_nick = dados.user.user_metadata.get("nick", "Mago Desconhecido")
				user_cla = dados.user.user_metadata.get("cla", "Nenhum")
				
				# Funde o progresso de Convidado assim que logar ou se registrar!
				if RankingManager.has_method("fundir_conta_guest"):
					RankingManager.fundir_conta_guest(user_nick, user_cla)
				
			auth_sucesso.emit(user_token)
		elif typeof(dados) == TYPE_DICTIONARY and (dados.has("user") or dados.has("email")):
			print("usuario cadastrado ou atualizado com sucesso!")
			var user_data = dados.get("user", dados)
			if user_data is Dictionary and user_data.has("user_metadata"):
				user_nick = user_data.user_metadata.get("nick", user_nick)
				user_cla = user_data.user_metadata.get("cla", user_cla)
				print("Metadata do usuario atualizada! Nick: ", user_nick, " Cla: ", user_cla)
			
			# Se veio de cadastrar (sem token de sessao ativa), emite sucesso. Senao, avisa dados_recebidos.
			if dados.has("user") and not dados.has("access_token") and user_token.is_empty():
				auth_sucesso.emit("cadastrado_ok")
			else:
				dados_recebidos.emit(dados)
		elif body_text == "{}" or body_text == "":
			# a rota de recuperar senha da 200 mas retorna body vazio
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
		# qndo da erro (senha errada, etc)
		var msg_erro = "Erro da API"
		if typeof(dados) == TYPE_DICTIONARY:
			if dados.has("error_description"):
				msg_erro = dados["error_description"]
			elif dados.has("msg"):
				msg_erro = dados["msg"]
		push_error("erro http: " + str(response_code) + " | " + msg_erro)
		auth_erro.emit(msg_erro)

# --- FUNCOES DA TASK 3 (AUTH) ---

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
	# endpoint do supabase pra criar conta
	make_request("/auth/v1/signup", HTTPClient.METHOD_POST, data)

func fazer_login(email: String, senha: String) -> void:
	print("tentando logar: ", email)
	var data = {
		"email": email,
		"password": senha
	}
	# endpoint do supabase pra pegar o token de login
	make_request("/auth/v1/token?grant_type=password", HTTPClient.METHOD_POST, data)

func recuperar_senha(email: String) -> void:
	print("Pedindo reset de senha para: ", email)
	var data = {
		"email": email
	}
	# endpoint do supabase pra mandar o email de reset
	make_request("/auth/v1/recover", HTTPClient.METHOD_POST, data)

# --- FUNCOES DA TASK 2 ---

# testa puxar geral da tabela de alunos
func puxar_alunos() -> void:
	print("tentando buscar os alunos no banco...")
	# "/rest/v1/nome_tabela" -> o select=* puxa todas colunas
	make_request("/rest/v1/alunos?select=*", HTTPClient.METHOD_GET)

func puxar_perguntas(andar_id: int = 1) -> void:
	print("buscando perguntas do andar: ", andar_id, "...")
	# [PROG-02] Ordena por nivel_progresso para progressão didática (1=Fácil → 3=Difícil)
	var query = "/rest/v1/perguntas?select=*"
	if andar_id > 0:
		query += "&andar_id=eq." + str(andar_id)
	query += "&order=nivel_progresso.asc"
	make_request(query, HTTPClient.METHOD_GET)

# --- FUNCOES DO CLÃ ---

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

# Realiza uma requisição HTTP assíncrona ao Supabase e aguarda seu retorno
func request_async(endpoint: String, method: HTTPClient.Method, data: Dictionary = {}) -> Dictionary:
	var url: String = supabase_url + endpoint
	var http: HTTPRequest = HTTPRequest.new()
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
	
	var response_code: int = response[1]
	var response_body: PackedByteArray = response[3]
	
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

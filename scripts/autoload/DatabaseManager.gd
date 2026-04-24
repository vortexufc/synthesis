extends Node

# chaves do nosso banco no supabase
var supabase_url: String = "https://uszmgqludyymspsarciw.supabase.co"
var supabase_key: String = "sb_publishable_mpz-s86wXECtwvBd0TnYoQ_qWQauy2S"

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
	var headers: PackedStringArray = [
		"apikey: " + supabase_key,
		"Authorization: Bearer " + supabase_key,
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
				
			auth_sucesso.emit(user_token)
		elif typeof(dados) == TYPE_DICTIONARY and dados.has("user"):
			print("usuario cadastrado com sucesso!")
			# o auth do supabase envia um "user" no signup
			auth_sucesso.emit("cadastrado_ok")
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
	var query = "/rest/v1/perguntas?select=*"
	if andar_id > 0:
		query += "&andar_id=eq." + str(andar_id)
	make_request(query, HTTPClient.METHOD_GET)

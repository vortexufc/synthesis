extends Node

signal clan_updated
signal clan_list_updated

var clans_list: Array = []

func _ready() -> void:
	# Sincroniza o clã do jogador local com a lista de clãs global após um breve delay 
	# para garantir que os outros autoloads (DatabaseManager, RankingManager) estejam prontos.
	await get_tree().create_timer(0.2).timeout
	await load_clans()
	await check_membership_sync()

# requisicoes de cla no supabase
func load_clans() -> bool:
	var res = await DatabaseManager.request_async("/rest/v1/Clas?select=*,MembrosCla(*)", HTTPClient.METHOD_GET)
	if not res["success"]:
		push_error("Erro ao carregar clãs do Supabase: " + res["message"])
		return false
		
	var api_clans = res["data"]
	if not api_clans is Array:
		return false
		
	var parsed_list: Array = []
	for c in api_clans:
		var members_list: Array = []
		if c.has("MembrosCla") and c["MembrosCla"] is Array:
			for m in c["MembrosCla"]:
				members_list.append({
					"name": m.get("player_name", "Desconhecido"),
					"role": m.get("cargo", "Membro"),
					"score": int(m.get("score_individual", 0))
				})
				
		# ordena membros: lider primeiro e depois pontuacao
		members_list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			if a["role"] == "Líder" and b["role"] != "Líder":
				return true
			if b["role"] == "Líder" and a["role"] != "Líder":
				return false
			return a["score"] > b["score"]
		)
		
		parsed_list.append({
			"name": c.get("nome", ""),
			"tag": c.get("tag", ""),
			"description": c.get("descricao", ""),
			"leader": c.get("lider", ""),
			"score": int(c.get("score", 0)),
			"members": members_list
		})
		
	clans_list = parsed_list
	clan_list_updated.emit()
	clan_updated.emit()
	return true

# filtros e buscas
func get_player_nick() -> String:
	if not DatabaseManager.user_token.is_empty():
		return DatabaseManager.user_nick
	else:
		return RankingManager.get_local_nick()

func get_player_score() -> int:
	var nick = get_player_nick()
	for item in RankingManager.ranking_geral:
		if item["name"] == nick:
			return item["score"]
	return 0

func get_clan_info(clan_name: String) -> Dictionary:
	for c in clans_list:
		if c["name"] == clan_name:
			return c
	return {}

# lista de clas por score pro ranking
func get_top_clans() -> Array:
	var list: Array = clans_list.duplicate(true)
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["score"] > b["score"])
	return list

# sugestoes de clas embaralhadas pra tela de clas
func get_sugestoes_clas() -> Array:
	var disponiveis: Array = []
	var meu_cla: String = DatabaseManager.user_cla
	
	# so mostra clas que o player nao esta
	for c in clans_list:
		if c["name"] != meu_cla:
			disponiveis.append(c.duplicate(true))
			
	# embaralha a lista
	randomize()
	for i in range(disponiveis.size() - 1, 0, -1):
		var j: int = randi() % (i + 1)
		var tmp = disponiveis[i]
		disponiveis[i] = disponiveis[j]
		disponiveis[j] = tmp
		
	return disponiveis

# procura por nome ou tag
func search_clans(query: String) -> Array:
	var q: String = query.strip_edges().to_lower()
	if q.is_empty():
		return get_sugestoes_clas()
		
	var filtered: Array = []
	for c in clans_list:
		if c["name"].to_lower().contains(q) or c["tag"].to_lower().contains(q):
			filtered.append(c)
	return filtered

# operacoes de membros
func check_membership_sync() -> void:
	var nick: String = get_player_nick()
	if nick.is_empty():
		return
		
	# checa se o jogador ta em algum cla
	var endpoint = "/rest/v1/MembrosCla?player_name=eq." + nick.uri_encode() + "&select=*"
	var res = await DatabaseManager.request_async(endpoint, HTTPClient.METHOD_GET)
	if not res["success"]:
		return
		
	var data = res["data"]
	if data is Array and data.size() > 0:
		var member_info = data[0]
		var cla_nome = member_info.get("cla_nome", "Nenhum")
		if DatabaseManager.user_cla != cla_nome:
			DatabaseManager.atualizar_cla_usuario(cla_nome)
	else:
		# se nao achou nada ta sem cla
		if DatabaseManager.user_cla != "Nenhum":
			DatabaseManager.atualizar_cla_usuario("Nenhum")

func create_clan(clan_name: String, tag: String, description: String) -> Dictionary:
	var name_clean: String = clan_name.strip_edges()
	var tag_clean: String = tag.strip_edges().to_upper()
	
	if name_clean.length() < 3:
		return {"success": false, "message": "O nome do clã deve ter pelo menos 3 caracteres!"}
	if tag_clean.length() < 2 or tag_clean.length() > 5:
		return {"success": false, "message": "A TAG deve ter entre 2 e 5 letras!"}
	if description.is_empty():
		return {"success": false, "message": "A descrição não pode ser vazia!"}
		
	var nick: String = get_player_nick()
	if nick.is_empty() or nick == "NÃO LOGADO":
		return {"success": false, "message": "Você precisa estar logado para criar um clã!"}
		
	var score: int = get_player_score()
	
	# tenta criar o cla no banco
	var clan_data = {
		"nome": name_clean,
		"tag": tag_clean,
		"descricao": description,
		"lider": nick,
		"score": score
	}
	
	var res_clan = await DatabaseManager.request_async("/rest/v1/Clas", HTTPClient.METHOD_POST, clan_data)
	if not res_clan["success"]:
		var msg = res_clan["message"]
		if msg.contains("duplicate key") or msg.contains("already exists"):
			msg = "Nome ou TAG de clã já estão em uso!"
		return {"success": false, "message": msg}
		
	# coloca o jogador como lider
	var member_data = {
		"player_name": nick,
		"cla_nome": name_clean,
		"cargo": "Líder",
		"score_individual": score
	}
	var res_member = await DatabaseManager.request_async("/rest/v1/MembrosCla", HTTPClient.METHOD_POST, member_data)
	if not res_member["success"]:
		# se der erro ao criar lider apaga o cla
		await DatabaseManager.request_async("/rest/v1/Clas?nome=eq." + name_clean.uri_encode(), HTTPClient.METHOD_DELETE)
		return {"success": false, "message": "Erro ao registrar líder do clã: " + res_member["message"]}
		
	# sincroniza a lista de clas
	DatabaseManager.atualizar_cla_usuario(name_clean)
	await load_clans()
	return {"success": true, "message": "Clã criado com sucesso!"}

func join_clan(clan_name: String) -> Dictionary:
	var nick: String = get_player_nick()
	if nick.is_empty() or nick == "NÃO LOGADO":
		return {"success": false, "message": "Você precisa estar logado para entrar em um clã!"}
	
	# bloqueia se ja tiver cla
	if DatabaseManager.user_cla != "Nenhum" and not DatabaseManager.user_cla.is_empty():
		return {"success": false, "message": "Você já faz parte de um clã!"}
		
	var score: int = get_player_score()
	var member_data = {
		"player_name": nick,
		"cla_nome": clan_name,
		"cargo": "Membro",
		"score_individual": score
	}
	
	# adiciona o player na tabela de membros
	var res_member = await DatabaseManager.request_async("/rest/v1/MembrosCla", HTTPClient.METHOD_POST, member_data)
	if not res_member["success"]:
		return {"success": false, "message": "Erro ao se juntar ao clã: " + res_member["message"]}
		
	# busca membros pra somar o score
	var res_all = await DatabaseManager.request_async("/rest/v1/MembrosCla?cla_nome=eq." + clan_name.uri_encode(), HTTPClient.METHOD_GET)
	var novo_score: int = score
	if res_all["success"] and res_all["data"] is Array:
		novo_score = 0
		for m in res_all["data"]:
			novo_score += int(m.get("score_individual", 0))
			
	# atualiza os pontos do cla
	await DatabaseManager.request_async("/rest/v1/Clas?nome=eq." + clan_name.uri_encode(), HTTPClient.METHOD_PATCH, {"score": novo_score})
	
	DatabaseManager.atualizar_cla_usuario(clan_name)
	await load_clans()
	return {"success": true, "message": "Entrou no clã com sucesso!"}

func leave_clan() -> Dictionary:
	var nick: String = get_player_nick()
	var clan_name: String = DatabaseManager.user_cla
	
	if clan_name == "Nenhum" or clan_name.is_empty():
		return {"success": false, "message": "Você não pertence a nenhum clã!"}
		
	# busca quem esta no cla
	var res_members = await DatabaseManager.request_async("/rest/v1/MembrosCla?cla_nome=eq." + clan_name.uri_encode(), HTTPClient.METHOD_GET)
	if not res_members["success"] or not res_members["data"] is Array:
		return {"success": false, "message": "Erro ao ler membros do clã no Supabase: " + res_members["message"]}
		
	var members: Array = res_members["data"]
	
	# acha a linha do jogador
	var member_row = null
	for m in members:
		if m.get("player_name", "") == nick:
			member_row = m
			break
			
	if member_row == null:
		DatabaseManager.atualizar_cla_usuario("Nenhum")
		return {"success": true, "message": "Você já foi removido do clã!"}
		
	var cargo = member_row.get("cargo", "Membro")
	
	if cargo == "Líder":
		if members.size() <= 1:
			# se for o unico membro deleta o cla
			var res_del = await DatabaseManager.request_async("/rest/v1/Clas?nome=eq." + clan_name.uri_encode(), HTTPClient.METHOD_DELETE)
			if not res_del["success"]:
				return {"success": false, "message": "Erro ao desfazer o clã: " + res_del["message"]}
		else:
			# passa a lideranca pro proximo com maior pontuacao
			var candidatos: Array = []
			for m in members:
				if m.get("player_name", "") != nick:
					candidatos.append(m)
					
			candidatos.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				return int(a.get("score_individual", 0)) > int(b.get("score_individual", 0))
			)
			var novo_lider: String = candidatos[0].get("player_name", "")
			
			# atualiza o lider em MembrosCla
			await DatabaseManager.request_async("/rest/v1/MembrosCla?player_name=eq." + novo_lider.uri_encode(), HTTPClient.METHOD_PATCH, {"cargo": "Líder"})
			
			# atualiza o lider em Clas
			await DatabaseManager.request_async("/rest/v1/Clas?nome=eq." + clan_name.uri_encode(), HTTPClient.METHOD_PATCH, {"lider": novo_lider})
			
			# remove o jogador
			await DatabaseManager.request_async("/rest/v1/MembrosCla?player_name=eq." + nick.uri_encode(), HTTPClient.METHOD_DELETE)
			
			# recalcula pontuacao total
			var novo_score: int = 0
			for m in candidatos:
				novo_score += int(m.get("score_individual", 0))
			await DatabaseManager.request_async("/rest/v1/Clas?nome=eq." + clan_name.uri_encode(), HTTPClient.METHOD_PATCH, {"score": novo_score})
	else:
		# remove da tabela de membros
		var res_del = await DatabaseManager.request_async("/rest/v1/MembrosCla?player_name=eq." + nick.uri_encode(), HTTPClient.METHOD_DELETE)
		if not res_del["success"]:
			return {"success": false, "message": "Erro ao sair do clã: " + res_del["message"]}
			
		# recalcula pontos
		var novo_score: int = 0
		for m in members:
			if m.get("player_name", "") != nick:
				novo_score += int(m.get("score_individual", 0))
		await DatabaseManager.request_async("/rest/v1/Clas?nome=eq." + clan_name.uri_encode(), HTTPClient.METHOD_PATCH, {"score": novo_score})
		
	DatabaseManager.atualizar_cla_usuario("Nenhum")
	await load_clans()
	return {"success": true, "message": "Saiu do clã com sucesso!"}

func expel_member(member_name: String) -> Dictionary:
	var clan_name: String = DatabaseManager.user_cla
	if clan_name == "Nenhum" or clan_name.is_empty():
		return {"success": false, "message": "Você não pertence a nenhum clã!"}
		
	var clan: Dictionary = get_clan_info(clan_name)
	if clan.is_empty() or clan["leader"] != get_player_nick():
		return {"success": false, "message": "Apenas o líder do clã pode expulsar membros!"}
		
	if member_name == get_player_nick():
		return {"success": false, "message": "Você não pode expulsar a si mesmo!"}
		
	# deleta o membro do banco
	var res_del = await DatabaseManager.request_async("/rest/v1/MembrosCla?player_name=eq." + member_name.uri_encode(), HTTPClient.METHOD_DELETE)
	if not res_del["success"]:
		return {"success": false, "message": "Erro ao expulsar membro do Supabase: " + res_del["message"]}
		
	# recalcula pontos
	var novo_score: int = 0
	for m in clan["members"]:
		if m["name"] != member_name:
			novo_score += int(m["score"])
			
	await DatabaseManager.request_async("/rest/v1/Clas?nome=eq." + clan_name.uri_encode(), HTTPClient.METHOD_PATCH, {"score": novo_score})
	await load_clans()
	return {"success": true, "message": "Membro expulso com sucesso!"}

func adicionar_pontos_cla(clan_name: String, member_name: String, pontos: int) -> void:
	if clan_name == "Nenhum" or clan_name.is_empty():
		return
		
	# pega dados do membro no banco
	var end_memb = "/rest/v1/MembrosCla?player_name=eq." + member_name.uri_encode() + "&select=*"
	var res_memb = await DatabaseManager.request_async(end_memb, HTTPClient.METHOD_GET)
	var score_atual: int = 0
	if res_memb["success"] and res_memb["data"] is Array and res_memb["data"].size() > 0:
		score_atual = int(res_memb["data"][0].get("score_individual", 0))
		
	# atualiza o score individual
	var novo_score_ind = score_atual + pontos
	await DatabaseManager.request_async(end_memb, HTTPClient.METHOD_PATCH, {"score_individual": novo_score_ind})
	
	# pega pontuacao do cla
	var end_clan = "/rest/v1/Clas?nome=eq." + clan_name.uri_encode() + "&select=*"
	var res_clan = await DatabaseManager.request_async(end_clan, HTTPClient.METHOD_GET)
	var score_clan_atual: int = 0
	if res_clan["success"] and res_clan["data"] is Array and res_clan["data"].size() > 0:
		score_clan_atual = int(res_clan["data"][0].get("score", 0))
		
	# salva nova pontuacao do cla
	var novo_score_clan = score_clan_atual + pontos
	await DatabaseManager.request_async(end_clan, HTTPClient.METHOD_PATCH, {"score": novo_score_clan})
	
	await load_clans()

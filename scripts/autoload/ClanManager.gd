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

# ---- CARREGAR E SALVAR DADOS NO SUPABASE ----
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
				
		# Ordena os membros (Líder primeiro, depois por score)
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

# ---- SELETORES DE INFORMAÇÃO ----
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

# Retorna os clãs ordenados por score — usado apenas pela aba de Ranking
func get_top_clans() -> Array:
	var list: Array = clans_list.duplicate(true)
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["score"] > b["score"])
	return list

# Retorna sugestões de clãs EMBARALHADAS (sem ordem por ranking) — usado pela TelaClas.
# Garante pelo menos MIN_SUGESTOES opções exibindo os clãs semente duplicados se necessário.
func get_sugestoes_clas() -> Array:
	const MIN_SUGESTOES: int = 5
	var disponiveis: Array = []
	var meu_cla: String = DatabaseManager.user_cla
	
	# Inclui apenas clãs que o jogador ainda não participa
	for c in clans_list:
		if c["name"] != meu_cla:
			disponiveis.append(c.duplicate(true))
			
	# Se não há clãs suficientes, preenche repetindo os disponíveis até atingir MIN_SUGESTOES
	if disponiveis.is_empty():
		return disponiveis
		
	var resultado: Array = disponiveis.duplicate(true)
	var idx: int = 0
	while resultado.size() < MIN_SUGESTOES:
		resultado.append(disponiveis[idx % disponiveis.size()].duplicate(true))
		idx += 1
		
	# Embaralha usando Fisher-Yates
	randomize()
	for i in range(resultado.size() - 1, 0, -1):
		var j: int = randi() % (i + 1)
		var tmp = resultado[i]
		resultado[i] = resultado[j]
		resultado[j] = tmp
		
	return resultado

# Busca por nome/tag
func search_clans(query: String) -> Array:
	var q: String = query.strip_edges().to_lower()
	if q.is_empty():
		return get_sugestoes_clas()
		
	var filtered: Array = []
	for c in clans_list:
		if c["name"].to_lower().contains(q) or c["tag"].to_lower().contains(q):
			filtered.append(c)
	return filtered

# ---- OPERAÇÕES DE MEMBRO E CONTROLE ONLINE ----
func check_membership_sync() -> void:
	var nick: String = get_player_nick()
	if nick.is_empty():
		return
		
	# Consulta na tabela MembrosCla se o jogador está cadastrado em algum clã
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
		# Se não retornou nada, ele não está em clã
		if DatabaseManager.user_cla != "Nenhum":
			DatabaseManager.atualizar_cla_usuario("Nenhum")

func create_clan(clan_name: String, tag: String, description: String) -> bool:
	var name_clean: String = clan_name.strip_edges()
	var tag_clean: String = tag.strip_edges().to_upper()
	
	if name_clean.is_empty() or tag_clean.is_empty():
		return false
		
	var nick: String = get_player_nick()
	var score: int = get_player_score()
	
	# 1. Tenta criar o clã na tabela Clas
	var clan_data = {
		"nome": name_clean,
		"tag": tag_clean,
		"descricao": description,
		"lider": nick,
		"score": score
	}
	
	var res_clan = await DatabaseManager.request_async("/rest/v1/Clas", HTTPClient.METHOD_POST, clan_data)
	if not res_clan["success"]:
		push_error("Erro ao criar clã no Supabase: " + res_clan["message"])
		return false
		
	# 2. Tenta inserir o líder na tabela MembrosCla
	var member_data = {
		"player_name": nick,
		"cla_nome": name_clean,
		"cargo": "Líder",
		"score_individual": score
	}
	var res_member = await DatabaseManager.request_async("/rest/v1/MembrosCla", HTTPClient.METHOD_POST, member_data)
	if not res_member["success"]:
		# Exclui o clã caso não registre o líder para evitar orfandade
		await DatabaseManager.request_async("/rest/v1/Clas?nome=eq." + name_clean.uri_encode(), HTTPClient.METHOD_DELETE)
		push_error("Erro ao registrar líder do clã: " + res_member["message"])
		return false
		
	# 3. Sincroniza local e carrega lista
	DatabaseManager.atualizar_cla_usuario(name_clean)
	await load_clans()
	return true

func join_clan(clan_name: String) -> bool:
	var nick: String = get_player_nick()
	
	# Impede se já pertencer a um clã
	if DatabaseManager.user_cla != "Nenhum" and not DatabaseManager.user_cla.is_empty():
		return false
		
	var score: int = get_player_score()
	var member_data = {
		"player_name": nick,
		"cla_nome": clan_name,
		"cargo": "Membro",
		"score_individual": score
	}
	
	# 1. Tenta inserir na tabela de membros
	var res_member = await DatabaseManager.request_async("/rest/v1/MembrosCla", HTTPClient.METHOD_POST, member_data)
	if not res_member["success"]:
		push_error("Erro ao se juntar ao clã no Supabase: " + res_member["message"])
		return false
		
	# 2. Obter membros atuais para atualizar o score do clã
	var res_all = await DatabaseManager.request_async("/rest/v1/MembrosCla?cla_nome=eq." + clan_name.uri_encode(), HTTPClient.METHOD_GET)
	var novo_score: int = score
	if res_all["success"] and res_all["data"] is Array:
		novo_score = 0
		for m in res_all["data"]:
			novo_score += int(m.get("score_individual", 0))
			
	# 3. Patch no score do clã
	await DatabaseManager.request_async("/rest/v1/Clas?nome=eq." + clan_name.uri_encode(), HTTPClient.METHOD_PATCH, {"score": novo_score})
	
	DatabaseManager.atualizar_cla_usuario(clan_name)
	await load_clans()
	return true

func leave_clan() -> bool:
	var nick: String = get_player_nick()
	var clan_name: String = DatabaseManager.user_cla
	
	if clan_name == "Nenhum" or clan_name.is_empty():
		return false
		
	# 1. Puxa os membros atuais do clã
	var res_members = await DatabaseManager.request_async("/rest/v1/MembrosCla?cla_nome=eq." + clan_name.uri_encode(), HTTPClient.METHOD_GET)
	if not res_members["success"] or not res_members["data"] is Array:
		return false
		
	var members: Array = res_members["data"]
	
	# Achar a linha do jogador atual
	var member_row = null
	for m in members:
		if m.get("player_name", "") == nick:
			member_row = m
			break
			
	if member_row == null:
		DatabaseManager.atualizar_cla_usuario("Nenhum")
		return true
		
	var cargo = member_row.get("cargo", "Membro")
	
	if cargo == "Líder":
		if members.size() <= 1:
			# Único membro e líder: desfaz o clã
			var res_del = await DatabaseManager.request_async("/rest/v1/Clas?nome=eq." + clan_name.uri_encode(), HTTPClient.METHOD_DELETE)
			if not res_del["success"]:
				push_error("Erro ao desfazer o clã no Supabase: " + res_del["message"])
				return false
		else:
			# Promove o próximo membro com maior pontuação (excluindo a si mesmo)
			var candidatos: Array = []
			for m in members:
				if m.get("player_name", "") != nick:
					candidatos.append(m)
					
			candidatos.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				return int(a.get("score_individual", 0)) > int(b.get("score_individual", 0))
			)
			var novo_lider: String = candidatos[0].get("player_name", "")
			
			# 1. Promove em MembrosCla
			await DatabaseManager.request_async("/rest/v1/MembrosCla?player_name=eq." + novo_lider.uri_encode(), HTTPClient.METHOD_PATCH, {"cargo": "Líder"})
			
			# 2. Atualiza líder em Clas
			await DatabaseManager.request_async("/rest/v1/Clas?nome=eq." + clan_name.uri_encode(), HTTPClient.METHOD_PATCH, {"lider": novo_lider})
			
			# 3. Deleta o jogador atual
			await DatabaseManager.request_async("/rest/v1/MembrosCla?player_name=eq." + nick.uri_encode(), HTTPClient.METHOD_DELETE)
			
			# 4. Recalcula score total do clã
			var novo_score: int = 0
			for m in candidatos:
				novo_score += int(m.get("score_individual", 0))
			await DatabaseManager.request_async("/rest/v1/Clas?nome=eq." + clan_name.uri_encode(), HTTPClient.METHOD_PATCH, {"score": novo_score})
	else:
		# Apenas deleta de MembrosCla
		var res_del = await DatabaseManager.request_async("/rest/v1/MembrosCla?player_name=eq." + nick.uri_encode(), HTTPClient.METHOD_DELETE)
		if not res_del["success"]:
			push_error("Erro ao sair do clã no Supabase: " + res_del["message"])
			return false
			
		# Recalcula score total
		var novo_score: int = 0
		for m in members:
			if m.get("player_name", "") != nick:
				novo_score += int(m.get("score_individual", 0))
		await DatabaseManager.request_async("/rest/v1/Clas?nome=eq." + clan_name.uri_encode(), HTTPClient.METHOD_PATCH, {"score": novo_score})
		
	DatabaseManager.atualizar_cla_usuario("Nenhum")
	await load_clans()
	return true

func expel_member(member_name: String) -> bool:
	var clan_name: String = DatabaseManager.user_cla
	if clan_name == "Nenhum" or clan_name.is_empty():
		return false
		
	var clan: Dictionary = get_clan_info(clan_name)
	if clan.is_empty() or clan["leader"] != get_player_nick():
		return false
		
	if member_name == get_player_nick():
		return false
		
	# 1. Deleta a linha do jogador na tabela MembrosCla
	var res_del = await DatabaseManager.request_async("/rest/v1/MembrosCla?player_name=eq." + member_name.uri_encode(), HTTPClient.METHOD_DELETE)
	if not res_del["success"]:
		push_error("Erro ao expulsar membro do Supabase: " + res_del["message"])
		return false
		
	# 2. Recalcula o score total
	var novo_score: int = 0
	for m in clan["members"]:
		if m["name"] != member_name:
			novo_score += int(m["score"])
			
	await DatabaseManager.request_async("/rest/v1/Clas?nome=eq." + clan_name.uri_encode(), HTTPClient.METHOD_PATCH, {"score": novo_score})
	await load_clans()
	return true

func adicionar_pontos_cla(clan_name: String, member_name: String, pontos: int) -> void:
	if clan_name == "Nenhum" or clan_name.is_empty():
		return
		
	# 1. Busca os dados atuais do membro no banco
	var end_memb = "/rest/v1/MembrosCla?player_name=eq." + member_name.uri_encode() + "&select=*"
	var res_memb = await DatabaseManager.request_async(end_memb, HTTPClient.METHOD_GET)
	var score_atual: int = 0
	if res_memb["success"] and res_memb["data"] is Array and res_memb["data"].size() > 0:
		score_atual = int(res_memb["data"][0].get("score_individual", 0))
		
	# 2. Atualiza o score_individual dele
	var novo_score_ind = score_atual + pontos
	await DatabaseManager.request_async(end_memb, HTTPClient.METHOD_PATCH, {"score_individual": novo_score_ind})
	
	# 3. Busca o score atual do clã
	var end_clan = "/rest/v1/Clas?nome=eq." + clan_name.uri_encode() + "&select=*"
	var res_clan = await DatabaseManager.request_async(end_clan, HTTPClient.METHOD_GET)
	var score_clan_atual: int = 0
	if res_clan["success"] and res_clan["data"] is Array and res_clan["data"].size() > 0:
		score_clan_atual = int(res_clan["data"][0].get("score", 0))
		
	# 4. Atualiza o score total do clã
	var novo_score_clan = score_clan_atual + pontos
	await DatabaseManager.request_async(end_clan, HTTPClient.METHOD_PATCH, {"score": novo_score_clan})
	
	await load_clans()

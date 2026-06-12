extends Node

signal clan_updated
signal clan_list_updated

const CLANS_FILE = "user://clans.json"

var clans_list: Array = []

func _ready() -> void:
	load_clans()
	# Sincroniza o clã do jogador local com a lista de clãs global após um breve delay 
	# para garantir que os outros autoloads (DatabaseManager, RankingManager) estejam prontos.
	await get_tree().create_timer(0.2).timeout
	check_membership_sync()

# ---- CARREGAR E SALVAR DADOS ----
func load_clans() -> void:
	if not FileAccess.file_exists(CLANS_FILE):
		_criar_clans_padrao()
		return
		
	var file = FileAccess.open(CLANS_FILE, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(content) == OK:
		if json.data is Array:
			clans_list = json.data
			return
			
	# Se deu erro no parse, reseta para padrão
	_criar_clans_padrao()

func save_clans() -> void:
	var file = FileAccess.open(CLANS_FILE, FileAccess.WRITE)
	file.store_string(JSON.stringify(clans_list, "\t"))
	file.close()
	clan_list_updated.emit()
	clan_updated.emit()

func _criar_clans_padrao() -> void:
	clans_list = [
		{
			"name": "Magos Supremos",
			"tag": "MSUP",
			"description": "Os magos mais experientes e poderosos do reino.",
			"leader": "Merlin",
			"score": 2500,
			"members": [
				{"name": "Merlin", "role": "Líder", "score": 1200},
				{"name": "Morgana", "role": "Oficial", "score": 800},
				{"name": "Gandalf", "role": "Membro", "score": 500}
			]
		},
		{
			"name": "Alquimistas de Ferro",
			"tag": "ALQ",
			"description": "Focados na transmutação e criação de poções raras.",
			"leader": "Nicolas_Flamel",
			"score": 1800,
			"members": [
				{"name": "Nicolas_Flamel", "role": "Líder", "score": 1000},
				{"name": "Elric", "role": "Membro", "score": 800}
			]
		},
		{
			"name": "Ordem Arcana",
			"tag": "OA",
			"description": "Estudiosos dos mistérios antigos e runas perdidas.",
			"leader": "Alvo_Dumbledore",
			"score": 1200,
			"members": [
				{"name": "Alvo_Dumbledore", "role": "Líder", "score": 900},
				{"name": "Harry_P", "role": "Membro", "score": 300}
			]
		}
	]
	save_clans()

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
	# (isso cobre o caso de existir apenas 1 ou 2 clãs criados)
	if disponiveis.is_empty():
		return disponiveis
		
	var resultado: Array = disponiveis.duplicate(true)
	var idx: int = 0
	while resultado.size() < MIN_SUGESTOES:
		resultado.append(disponiveis[idx % disponiveis.size()].duplicate(true))
		idx += 1
		
	# Embaralha usando Fisher-Yates para que a ordem seja aleatória a cada abertura
	randomize()
	for i in range(resultado.size() - 1, 0, -1):
		var j: int = randi() % (i + 1)
		var tmp = resultado[i]
		resultado[i] = resultado[j]
		resultado[j] = tmp
		
	return resultado

# Busca por nome/tag — retorna em ordem de inserção (sem ranking de score)
func search_clans(query: String) -> Array:
	var q: String = query.strip_edges().to_lower()
	if q.is_empty():
		return get_sugestoes_clas()
		
	var filtered: Array = []
	for c in clans_list:
		if c["name"].to_lower().contains(q) or c["tag"].to_lower().contains(q):
			filtered.append(c)
	return filtered

# ---- OPERAÇÕES DE MEMBRO E CONTROLE ----
func check_membership_sync() -> void:
	var current_cla = DatabaseManager.user_cla
	if current_cla == "Nenhum" or current_cla.is_empty():
		return
		
	var clan = get_clan_info(current_cla)
	if clan.is_empty():
		# O clã não existe mais (foi deletado)
		DatabaseManager.atualizar_cla_usuario("Nenhum")
		return
		
	var nick = get_player_nick()
	var esta_no_cla = false
	for m in clan["members"]:
		if m["name"] == nick:
			esta_no_cla = true
			break
			
	if not esta_no_cla:
		# Jogador foi expulso do clã
		DatabaseManager.atualizar_cla_usuario("Nenhum")

func create_clan(clan_name: String, tag: String, description: String) -> bool:
	var name_clean = clan_name.strip_edges()
	var tag_clean = tag.strip_edges().to_upper()
	
	if name_clean.is_empty() or tag_clean.is_empty():
		return false
		
	# Valida se clã já existe
	for c in clans_list:
		if c["name"].to_lower() == name_clean.to_lower() or c["tag"] == tag_clean:
			return false
			
	var nick = get_player_nick()
	var score = get_player_score()
	
	var novo_cla = {
		"name": name_clean,
		"tag": tag_clean,
		"description": description,
		"leader": nick,
		"score": score,
		"members": [
			{"name": nick, "role": "Líder", "score": score}
		]
	}
	
	clans_list.append(novo_cla)
	DatabaseManager.atualizar_cla_usuario(name_clean)
	save_clans()
	return true

func join_clan(clan_name: String) -> bool:
	var nick = get_player_nick()
	
	# Verifica se já está em um clã
	if DatabaseManager.user_cla != "Nenhum" and not DatabaseManager.user_cla.is_empty():
		return false
		
	for c in clans_list:
		if c["name"] == clan_name:
			# Verifica se já está lá de alguma forma
			for m in c["members"]:
				if m["name"] == nick:
					return false
					
			var score = get_player_score()
			c["members"].append({"name": nick, "role": "Membro", "score": score})
			
			# Recalcula pontos
			var total_score = 0
			for m in c["members"]:
				total_score += m["score"]
			c["score"] = total_score
			
			# Ordena os membros
			c["members"].sort_custom(func(a, b): 
				if a["role"] == "Líder" and b["role"] != "Líder":
					return true
				if b["role"] == "Líder" and a["role"] != "Líder":
					return false
				return a["score"] > b["score"]
			)
			
			DatabaseManager.atualizar_cla_usuario(clan_name)
			save_clans()
			return true
			
	return false

func leave_clan() -> bool:
	var nick = get_player_nick()
	var clan_name = DatabaseManager.user_cla
	
	if clan_name == "Nenhum" or clan_name.is_empty():
		return false
		
	var clan_index = -1
	for i in range(clans_list.size()):
		if clans_list[i]["name"] == clan_name:
			clan_index = i
			break
			
	if clan_index == -1:
		DatabaseManager.atualizar_cla_usuario("Nenhum")
		return false
		
	var clan = clans_list[clan_index]
	var member_index = -1
	for j in range(clan["members"].size()):
		if clan["members"][j]["name"] == nick:
			member_index = j
			break
			
	if member_index != -1:
		clan["members"].remove_at(member_index)
		
	# Se o clã esvaziou ou o líder saiu, vamos lidar com a liderança
	if clan["leader"] == nick:
		if clan["members"].size() > 0:
			# Passa liderança para o membro de maior pontuação
			clan["members"].sort_custom(func(a, b): return a["score"] > b["score"])
			clan["members"][0]["role"] = "Líder"
			clan["leader"] = clan["members"][0]["name"]
			
			# Recalcula score
			var total_score = 0
			for m in clan["members"]:
				total_score += m["score"]
			clan["score"] = total_score
		else:
			# Disolve o clã
			clans_list.remove_at(clan_index)
	else:
		# Apenas recalcula score
		var total_score = 0
		for m in clan["members"]:
			total_score += m["score"]
		clan["score"] = total_score
		
	DatabaseManager.atualizar_cla_usuario("Nenhum")
	save_clans()
	return true

func expel_member(member_name: String) -> bool:
	var clan_name = DatabaseManager.user_cla
	if clan_name == "Nenhum" or clan_name.is_empty():
		return false
		
	var clan = get_clan_info(clan_name)
	if clan.is_empty():
		return false
		
	# Apenas o líder pode expulsar
	if clan["leader"] != get_player_nick():
		return false
		
	# Não pode se expulsar (deve usar leave_clan)
	if member_name == get_player_nick():
		return false
		
	var member_index = -1
	for i in range(clan["members"].size()):
		if clan["members"][i]["name"] == member_name:
			member_index = i
			break
			
	if member_index != -1:
		clan["members"].remove_at(member_index)
		
		# Recalcula score
		var total_score = 0
		for m in clan["members"]:
			total_score += m["score"]
		clan["score"] = total_score
		
		save_clans()
		return true
		
	return false

func adicionar_pontos_cla(clan_name: String, member_name: String, pontos: int) -> void:
	if clan_name == "Nenhum" or clan_name.is_empty():
		return
		
	for c in clans_list:
		if c["name"] == clan_name:
			# Adiciona na pontuação do clã
			c["score"] += pontos
			
			# Adiciona na pontuação individual do membro no clã
			var achou_membro = false
			for m in c["members"]:
				if m["name"] == member_name:
					m["score"] += pontos
					achou_membro = true
					break
			
			if not achou_membro:
				c["members"].append({"name": member_name, "role": "Membro", "score": pontos})
				
			# Ordena os membros
			c["members"].sort_custom(func(a, b): 
				if a["role"] == "Líder" and b["role"] != "Líder":
					return true
				if b["role"] == "Líder" and a["role"] != "Líder":
					return false
				return a["score"] > b["score"]
			)
			save_clans()
			return


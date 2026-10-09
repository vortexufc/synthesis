extends Node

# vida
var vida_maxima_jogador: float = 100.0
var vida_atual_jogador: float = 100.0

# pocoes pra curar
var pocoes: Array = []

# itens normais
var itens: Array = []

# paginas do livro
var grimorio: Array = []

var chaves: int = 0
var moedas: int = 0
var vinhetas_desbloqueadas: Array = []

# buff temporario de escudo
var buff_escudo_salas_restantes: int = 0
var bonus_vida_escudo: float = 10.0
var tem_buff_escudo: bool = false

# registro de quests concluidas (ex: {"cientista_quest1": true})
var quests_concluidas: Dictionary = {}

# registro de quests aceitas mas nao concluidas
var quests_ativas: Dictionary = {}

# persistencia de mundo e salas
var baus_abertos: Dictionary = {}
var baus_spawnados: Dictionary = {}
var pergaminhos_coletados: Dictionary = {}
var itens_coletados: Dictionary = {}
var spawners_sorteados: Dictionary = {}
var portas_destrancadas: Array = []
var inimigos_derrotados: Array = []

# Localizacao do jogador e percurso para continuar jogo
var cena_salva: String = ""
var pos_salva_x: float = 0.0
var pos_salva_y: float = 0.0
var tem_pos_salva: bool = false
var percurso_salas_salvo: Array = []
var indice_sala_salvo: int = 0
var restaurando_posicao_save: bool = false
var cutscene_inicial_vista: bool = false
var fade_spawn_player: bool = false


signal vida_alterada(atual, maxima)
@warning_ignore("unused_signal")
signal quests_atualizadas()
signal insignias_atualizadas()

const SAVE_PATH = "user://save.json"

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	carregar()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		salvar()

func _eh_cena_de_menu(caminho: String) -> bool:
	var p = caminho.to_lower()
	return ("main_menu" in p or "login" in p or "cadastro" in p or "auth" in p or "game_over" in p or "ranking" in p or "clas" in p)

func _inicializar_dados_padrao():
	vida_atual_jogador = vida_maxima_jogador
	pocoes.clear()
	itens.clear()
	grimorio.clear()
	chaves = 0
	moedas = 0
	vinhetas_desbloqueadas.clear()
	buff_escudo_salas_restantes = 0
	tem_buff_escudo = false
	quests_concluidas.clear()
	quests_ativas.clear()
	baus_abertos.clear()
	baus_spawnados.clear()
	pergaminhos_coletados.clear()
	itens_coletados.clear()
	spawners_sorteados.clear()
	portas_destrancadas.clear()
	inimigos_derrotados.clear()
	cena_salva = ""
	pos_salva_x = 0.0
	pos_salva_y = 0.0
	tem_pos_salva = false
	percurso_salas_salvo.clear()
	indice_sala_salvo = 0
	restaurando_posicao_save = false
	cutscene_inicial_vista = false
	fade_spawn_player = false
	
	# itens iniciais pra testar (apenas pocoes, grimorio comeca totalmente vazio)
	pocoes.append({"nome": "Poção Grande", "qtd": 2, "cura": 50, "desc": "Cura 50 HP"})
	salvar(true)

func salvar(ignorar_posicao_em_jogo: bool = false):
	_normalizar_itens()
	
	# Grava a posicao e a cena atual se estiver em jogo e vivo
	if not ignorar_posicao_em_jogo and is_inside_tree() and get_tree():
		var cena_atual = get_tree().current_scene
		if cena_atual and is_instance_valid(cena_atual):
			var caminho = cena_atual.scene_file_path
			if caminho != "" and not _eh_cena_de_menu(caminho):
				var player = get_tree().get_first_node_in_group("player")
				if player and is_instance_valid(player) and vida_atual_jogador > 0:
					cena_salva = caminho
					pos_salva_x = player.global_position.x
					pos_salva_y = player.global_position.y
					tem_pos_salva = true

	var dg = get_node_or_null("/root/DungeonGenerator") if is_inside_tree() else null
	if dg and not ignorar_posicao_em_jogo:
		for p in dg.portas_destrancadas:
			if not (p in portas_destrancadas):
				portas_destrancadas.append(p)
		for i in dg.inimigos_derrotados:
			if not (i in inimigos_derrotados):
				inimigos_derrotados.append(i)
		if dg.percurso_salas.size() > 0:
			percurso_salas_salvo = dg.percurso_salas.duplicate()
			indice_sala_salvo = dg.indice_atual
			
	var save_dict = {
		"vida_atual_jogador": vida_atual_jogador,
		"pocoes": pocoes,
		"itens": itens,
		"grimorio": grimorio,
		"chaves": chaves,
		"moedas": moedas,
		"vinhetas_desbloqueadas": vinhetas_desbloqueadas,
		"quests_concluidas": quests_concluidas,
		"quests_ativas": quests_ativas,
		"baus_abertos": baus_abertos,
		"baus_spawnados": baus_spawnados,
		"pergaminhos_coletados": pergaminhos_coletados,
		"itens_coletados": itens_coletados,
		"spawners_sorteados": spawners_sorteados,
		"portas_destrancadas": portas_destrancadas,
		"inimigos_derrotados": inimigos_derrotados,
		"cena_salva": cena_salva,
		"pos_salva_x": pos_salva_x,
		"pos_salva_y": pos_salva_y,
		"tem_pos_salva": tem_pos_salva,
		"percurso_salas_salvo": percurso_salas_salvo,
		"indice_sala_salvo": indice_sala_salvo,
		"cutscene_inicial_vista": cutscene_inicial_vista
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_dict))

func carregar():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var content = file.get_as_text()
		var json = JSON.new()
		if json.parse(content) == OK:
			var data = json.data
			vida_atual_jogador = vida_maxima_jogador # reseta hp inicial
			pocoes = data.get("pocoes", [])
			itens = data.get("itens", [])
			grimorio = data.get("grimorio", [])
			chaves = int(data.get("chaves", 0))
			moedas = int(data.get("moedas", 0))
			vinhetas_desbloqueadas = []
			for v in data.get("vinhetas_desbloqueadas", []):
				var v_int = int(v)
				if not vinhetas_desbloqueadas.has(v_int):
					vinhetas_desbloqueadas.append(v_int)
			quests_concluidas = data.get("quests_concluidas", {})
			quests_ativas = data.get("quests_ativas", {})
			baus_abertos = data.get("baus_abertos", {})
			baus_spawnados = data.get("baus_spawnados", {})
			pergaminhos_coletados = data.get("pergaminhos_coletados", {})
			itens_coletados = data.get("itens_coletados", {})
			spawners_sorteados = data.get("spawners_sorteados", {})
			portas_destrancadas = data.get("portas_destrancadas", [])
			inimigos_derrotados = data.get("inimigos_derrotados", [])
			cena_salva = data.get("cena_salva", "")
			pos_salva_x = float(data.get("pos_salva_x", 0.0))
			pos_salva_y = float(data.get("pos_salva_y", 0.0))
			tem_pos_salva = bool(data.get("tem_pos_salva", false))
			percurso_salas_salvo = data.get("percurso_salas_salvo", [])
			indice_sala_salvo = int(data.get("indice_sala_salvo", 0))
			
			if data.has("cutscene_inicial_vista"):
				cutscene_inicial_vista = bool(data.get("cutscene_inicial_vista", false))
			
			# Se já existia progresso anterior no save, garante que a cutscene seja considerada já vista
			if not cutscene_inicial_vista and (grimorio.size() > 0 or moedas > 0 or quests_concluidas.size() > 0 or baus_abertos.size() > 0 or tem_pos_salva or percurso_salas_salvo.size() > 0):
				cutscene_inicial_vista = true

			
			var dg_load = get_node_or_null("/root/DungeonGenerator") if is_inside_tree() else null
			if dg_load:
				if "portas_destrancadas" in dg_load and dg_load.portas_destrancadas != null:
					for p in portas_destrancadas:
						if not (p in dg_load.portas_destrancadas):
							dg_load.portas_destrancadas.append(p)
				if "inimigos_derrotados" in dg_load and dg_load.inimigos_derrotados != null:
					for i in inimigos_derrotados:
						if not (i in dg_load.inimigos_derrotados):
							dg_load.inimigos_derrotados.append(i)
			
			_normalizar_itens()
			vida_alterada.emit(vida_atual_jogador, vida_maxima_jogador)
		else:
			_inicializar_dados_padrao()
	else:
		_inicializar_dados_padrao()

func tem_progresso_salvo() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	return cutscene_inicial_vista or tem_pos_salva or (cena_salva != "" and not _eh_cena_de_menu(cena_salva)) or moedas > 0 or itens.size() > 0 or grimorio.size() > 0 or quests_ativas.size() > 0 or quests_concluidas.size() > 0 or baus_abertos.size() > 0 or inimigos_derrotados.size() > 0

# --- Metodos de Persistencia de Mundo e Salas ---
func is_bau_aberto(id: String) -> bool:
	if id == "": return false
	return baus_abertos.has(id)

func registrar_bau_aberto(id: String) -> void:
	if id == "": return
	baus_abertos[id] = true
	salvar()
	print("[PlayerStats] Bau registrado como aberto: ", id)

func get_bau_spawnado(id_spawner: String) -> Dictionary:
	return baus_spawnados.get(id_spawner, {})

func registrar_bau_spawnado(id_spawner: String, dados: Dictionary) -> void:
	baus_spawnados[id_spawner] = dados
	salvar()

func is_pergaminho_coletado(id: String) -> bool:
	if id == "": return false
	return pergaminhos_coletados.has(id) or itens_coletados.has(id)

func registrar_pergaminho_coletado(id: String) -> void:
	if id == "": return
	pergaminhos_coletados[id] = true
	itens_coletados[id] = true
	salvar()
	print("[PlayerStats] Pergaminho registrado como coletado: ", id)

func is_item_coletado(id: String) -> bool:
	if id == "": return false
	return itens_coletados.has(id)

func registrar_item_coletado(id: String) -> void:
	if id == "": return
	itens_coletados[id] = true
	salvar()
	print("[PlayerStats] Item registrado como coletado: ", id)

func has_spawner_sorteio(id_spawner: String) -> bool:
	return spawners_sorteados.has(id_spawner)

func get_spawner_sorteio(id_spawner: String) -> Array:
	return spawners_sorteados.get(id_spawner, [])

func registrar_spawner_sorteio(id_spawner: String, pontos: Array) -> void:
	spawners_sorteados[id_spawner] = pontos
	salvar()

func resetar_progresso_mundo() -> void:
	baus_abertos.clear()
	baus_spawnados.clear()
	pergaminhos_coletados.clear()
	itens_coletados.clear()
	spawners_sorteados.clear()
	portas_destrancadas.clear()
	inimigos_derrotados.clear()
	var dg = get_node_or_null("/root/DungeonGenerator") if is_inside_tree() else null
	if dg:
		dg.portas_destrancadas.clear()
		dg.inimigos_derrotados.clear()
	salvar()
	print("[PlayerStats] Progresso de salas e mundo resetado!")

func limpar_posicao_salva() -> void:
	cena_salva = ""
	pos_salva_x = 0.0
	pos_salva_y = 0.0
	tem_pos_salva = false
	percurso_salas_salvo.clear()
	indice_sala_salvo = 0
	restaurando_posicao_save = false
	salvar(true)
	print("[PlayerStats] Posição salva do jogador foi limpa!")

func resetar_salvamento_completo() -> void:
	var dg = get_node_or_null("/root/DungeonGenerator") if is_inside_tree() else null
	if dg:
		dg.portas_destrancadas.clear()
		dg.inimigos_derrotados.clear()
		dg.percurso_salas.clear()
		dg.indice_atual = 0
		dg.tocar_cutscene_inicial = true
		if dg.has_method("resetar_masmorra"):
			dg.resetar_masmorra()
			
	var db = get_node_or_null("/root/DatabaseManager") if is_inside_tree() else null
	if db and db.has_method("resetar_expedicao_ativa"):
		db.resetar_expedicao_ativa()
		
	var qm = get_node_or_null("/root/QuizManager") if is_inside_tree() else null
	if qm and qm.has_method("resetar_historico_perguntas"):
		qm.resetar_historico_perguntas()

	_inicializar_dados_padrao()
	
	vida_alterada.emit(vida_atual_jogador, vida_maxima_jogador)
	quests_atualizadas.emit()
	insignias_atualizadas.emit()
	print("[PlayerStats] Save completamente resetado para o padrão de fábrica!")

func marcar_cutscene_inicial_vista() -> void:
	cutscene_inicial_vista = true
	salvar()
	print("[PlayerStats] Cutscene inicial marcada como vista!")


# garante que fragmentos gelatinosos sejam identificados individualmente pela cor
func _normalizar_itens() -> void:
	for it in itens:
		if not it is Dictionary: continue
		var nome = it.get("nome", "")
		var cor = it.get("cor", "")
		if nome == "Fragmento de Gelatina" or "Gelatina" in nome or cor != "":
			if cor == "":
				cor = "azul"
			if cor == "verde" or "verde" in nome.to_lower():
				it["nome"] = "Fragmento Gelatinoso Verde"
				it["cor"] = "verde"
				it["descricao"] = "Um fragmento pegajoso e ácido deixado por um slime verde."
			elif cor == "vermelho" or "vermelh" in nome.to_lower() or "laranja" in nome.to_lower():
				it["nome"] = "Fragmento Gelatinoso Vermelho"
				it["cor"] = "vermelho"
				it["descricao"] = "Um fragmento pegajoso e incandescente deixado por um slime vermelho."
			else:
				it["nome"] = "Fragmento Gelatinoso Azul"
				it["cor"] = "azul"
				it["descricao"] = "Um fragmento pegajoso e translúcido deixado por um slime azul."

func desbloquear_vinheta(andar_id: int) -> void:
	if not vinhetas_desbloqueadas.has(andar_id):
		vinhetas_desbloqueadas.append(andar_id)
		salvar()
		insignias_atualizadas.emit()
		print("[PlayerStats] Nova Vinheta/Insígnia Desbloqueada para o Andar %d!" % andar_id)

func tem_insignia(andar_id: int) -> bool:
	return vinhetas_desbloqueadas.has(andar_id)

func resetar_insignias() -> void:
	vinhetas_desbloqueadas.clear()
	salvar()
	insignias_atualizadas.emit()
	print("[PlayerStats] Insígnias resetadas!")

func desbloquear_todas_insignias() -> void:
	for i in [1, 2, 3]:
		if not vinhetas_desbloqueadas.has(i):
			vinhetas_desbloqueadas.append(i)
	salvar()
	insignias_atualizadas.emit()
	print("[PlayerStats] Todas as insígnias foram desbloqueadas!")


# limpa os pergaminhos lidos
func limpar_grimorio() -> void:
	grimorio.clear()
	salvar()

# limpa a mochila inteira (pra testes)
func limpar_inventario_e_moedas() -> void:
	itens.clear()
	pocoes.clear()
	grimorio.clear()
	chaves = 0
	moedas = 0
	salvar()
	quests_atualizadas.emit()
	print("[PlayerStats] Inventário, grimório, chaves e moedas foram completamente esvaziados!")


# funcao pra healar
func curar_vida(valor: float) -> void:
	vida_atual_jogador += valor
	if vida_atual_jogador > vida_maxima_jogador:
		vida_atual_jogador = vida_maxima_jogador
	vida_alterada.emit(vida_atual_jogador, vida_maxima_jogador)
	salvar()

# da moedas pro player
func adicionar_moedas(quantidade: int) -> void:
	moedas += quantidade
	salvar()
	quests_atualizadas.emit()
	print("[PlayerStats] +%d moedas adicionadas. Total: %d" % [quantidade, moedas])

# guarda pocao na bolsa
func adicionar_pocao(nome: String = "Poção de Cura", cura: int = 40, desc: String = "Cura 40 HP", qtd: int = 1) -> void:
	for p in pocoes:
		if p is Dictionary and p.get("nome") == nome:
			p["qtd"] = int(p.get("qtd", 1)) + qtd
			salvar()
			quests_atualizadas.emit()
			print("[PlayerStats] Quantidade da poção '%s' aumentada para %d" % [nome, p["qtd"]])
			return
	pocoes.append({
		"nome": nome,
		"qtd": qtd,
		"cura": cura,
		"desc": desc
	})
	salvar()
	quests_atualizadas.emit()
	print("[PlayerStats] Nova poção adicionada: ", nome)

# da escudo temporario pro player
func aplicar_buff_escudo(salas: int = 2, bonus_hp: float = 10.0) -> void:
	bonus_vida_escudo = bonus_hp
	buff_escudo_salas_restantes = salas
	if not tem_buff_escudo:
		tem_buff_escudo = true
		vida_maxima_jogador += bonus_vida_escudo
		vida_atual_jogador += bonus_vida_escudo
	vida_alterada.emit(vida_atual_jogador, vida_maxima_jogador)
	print("[PlayerStats] Buff de Escudo Arcano ativo! +%.0f Vida Máxima por %d salas." % [bonus_vida_escudo, buff_escudo_salas_restantes])

# gasta 1 sala da duracao do escudo
func decrementar_buff_escudo() -> void:
	if not tem_buff_escudo:
		return
	buff_escudo_salas_restantes -= 1
	print("[PlayerStats] Buff de Escudo Arcano: %d salas restantes." % buff_escudo_salas_restantes)
	if buff_escudo_salas_restantes <= 0:
		remover_buff_escudo()

# tira o escudo e volta a vida normal
func remover_buff_escudo() -> void:
	if not tem_buff_escudo:
		return
	tem_buff_escudo = false
	buff_escudo_salas_restantes = 0
	vida_maxima_jogador = max(100.0, vida_maxima_jogador - bonus_vida_escudo)
	if vida_atual_jogador > vida_maxima_jogador:
		vida_atual_jogador = vida_maxima_jogador
	vida_alterada.emit(vida_atual_jogador, vida_maxima_jogador)
	print("[PlayerStats] Buff de Escudo Arcano expirou!")

# salva pergaminho no grimorio
func adicionar_pergaminho(titulo: String, paginas: Array[String], desc: String = "") -> void:
	# checa se ja tem pra nao duplicar
	for item in grimorio:
		if item.get("titulo") == titulo:
			# atualiza as paginas
			item["paginas"] = paginas
			salvar()
			return
			
	var texto_completo = ""
	for i in range(paginas.size()):
		texto_completo += "-- PÁGINA " + str(i + 1) + " --\n" + paginas[i] + "\n\n"
		
	grimorio.append({
		"titulo": titulo,
		"texto": texto_completo,
		"paginas": paginas,
		"desc": desc if desc != "" else "Um pergaminho antigo contendo dicas arcanas."
	})
	salvar()
	print("[PlayerStats] Pergaminho adicionado ao Grimório: ", titulo)

# salva o mural que o player leu
func adicionar_codice_mural(id_codice: String, titulo: String, andar: int, desc: String = "") -> bool:
	for item in grimorio:
		if item is Dictionary and (item.get("id_codice") == id_codice or item.get("titulo") == titulo):
			return false # Já possui
	grimorio.append({
		"id_codice": id_codice,
		"titulo": titulo,
		"tipo_codice": "mural",
		"andar": andar,
		"desc": desc,
		"texto": "Códice Acadêmico Ancestral: " + titulo
	})
	salvar()
	quests_atualizadas.emit()
	print("[PlayerStats] Novo Códice Científico adicionado ao Grimório: ", titulo)
	return true

# checa se ja leu o mural
func possui_codice(id_codice: String) -> bool:
	for item in grimorio:
		if item is Dictionary and item.get("id_codice") == id_codice:
			return true
	return false


# funcao para resetar a vida após Game Over
func resetar_vida() -> void:
	vida_atual_jogador = vida_maxima_jogador
	vida_alterada.emit(vida_atual_jogador, vida_maxima_jogador)
	salvar()

# funcao de tomar dano
func sofrer_dano(valor: float) -> void:
	# se tiver invencivel nao toma dano
	var dev_mgr = get_node_or_null("/root/DevManager")
	if dev_mgr and dev_mgr.DEV_MODE_ENABLED and dev_mgr.invencivel:
		print("dano bloqueado pela invencibilidade: ", valor)
		return

	# Se o jogador já está sem vida (0 HP), ignora danos extras para evitar repetição de sons e loop de Game Over
	if vida_atual_jogador <= 0.0:
		return

	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("tocar_som_dano"):
		audio.tocar_som_dano()

	vida_atual_jogador -= valor
	if vida_atual_jogador < 0:
		vida_atual_jogador = 0
	vida_alterada.emit(vida_atual_jogador, vida_maxima_jogador)
	salvar()

	if vida_atual_jogador <= 0:
		var gs = get_node_or_null("/root/GlobalSignals")
		if gs:
			gs.fim_de_jogo.emit(false, {"dano": valor, "causa": "Armadilha"})

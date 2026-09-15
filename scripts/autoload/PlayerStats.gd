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

# Buff temporário de masmorra (Escudo Arcano)
var buff_escudo_salas_restantes: int = 0
var bonus_vida_escudo: float = 10.0
var tem_buff_escudo: bool = false

# registro de quests concluidas (ex: {"cientista_quest1": true})
var quests_concluidas: Dictionary = {}

# registro de quests aceitas mas nao concluidas
var quests_ativas: Dictionary = {}

signal vida_alterada(atual, maxima)
@warning_ignore("unused_signal")
signal quests_atualizadas()

const SAVE_PATH = "user://save.json"

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	carregar()

func _inicializar_dados_padrao():
	vida_atual_jogador = vida_maxima_jogador
	pocoes.clear()
	itens.clear()
	grimorio.clear()
	chaves = 0
	moedas = 0
	vinhetas_desbloqueadas.clear()
	quests_concluidas.clear()
	quests_ativas.clear()
	
	# itens iniciais pra testar (apenas pocoes, grimorio comeca totalmente vazio)
	pocoes.append({"nome": "Poção Grande", "qtd": 2, "cura": 50, "desc": "Cura 50 HP"})
	salvar()

func salvar():
	var save_dict = {
		"vida_atual_jogador": vida_atual_jogador,
		"pocoes": pocoes,
		"itens": itens,
		"grimorio": grimorio,
		"chaves": chaves,
		"moedas": moedas,
		"vinhetas_desbloqueadas": vinhetas_desbloqueadas,
		"quests_concluidas": quests_concluidas,
		"quests_ativas": quests_ativas
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
			vinhetas_desbloqueadas = data.get("vinhetas_desbloqueadas", [])
			quests_concluidas = data.get("quests_concluidas", {})
			quests_ativas = data.get("quests_ativas", {})
			
			vida_alterada.emit(vida_atual_jogador, vida_maxima_jogador)
		else:
			_inicializar_dados_padrao()
	else:
		_inicializar_dados_padrao()

func desbloquear_vinheta(andar_id: int) -> void:
	if not vinhetas_desbloqueadas.has(andar_id):
		vinhetas_desbloqueadas.append(andar_id)
		salvar()
		print("[PlayerStats] Nova Vinheta Desbloqueada para o Andar %d!" % andar_id)


## Limpa todos os pergaminhos salvos no Grimório
func limpar_grimorio() -> void:
	grimorio.clear()
	salvar()

## [DEV / GOD MODE] Limpa completamente o inventário (itens, poções, grimório, chaves e moedas)
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

## Adiciona moedas de ouro e emite atualização
func adicionar_moedas(quantidade: int) -> void:
	moedas += quantidade
	salvar()
	quests_atualizadas.emit()
	print("[PlayerStats] +%d moedas adicionadas. Total: %d" % [quantidade, moedas])

## Adiciona uma poção ao inventário (acumula se já existir)
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

## Aplica o Buff de Escudo Arcano (+HP Máximo temporário que dura por X salas)
func aplicar_buff_escudo(salas: int = 2, bonus_hp: float = 10.0) -> void:
	bonus_vida_escudo = bonus_hp
	buff_escudo_salas_restantes = salas
	if not tem_buff_escudo:
		tem_buff_escudo = true
		vida_maxima_jogador += bonus_vida_escudo
		vida_atual_jogador += bonus_vida_escudo
	vida_alterada.emit(vida_atual_jogador, vida_maxima_jogador)
	print("[PlayerStats] Buff de Escudo Arcano ativo! +%.0f Vida Máxima por %d salas." % [bonus_vida_escudo, buff_escudo_salas_restantes])

## Decrementa 1 sala de duração do Buff de Escudo ao entrar em nova sala da dungeon
func decrementar_buff_escudo() -> void:
	if not tem_buff_escudo:
		return
	buff_escudo_salas_restantes -= 1
	print("[PlayerStats] Buff de Escudo Arcano: %d salas restantes." % buff_escudo_salas_restantes)
	if buff_escudo_salas_restantes <= 0:
		remover_buff_escudo()

## Remove o Buff de Escudo Arcano e restaura a vida máxima padrão
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

## Adiciona um pergaminho coletado ao Grimório do jogador
func adicionar_pergaminho(titulo: String, paginas: Array[String], desc: String = "") -> void:
	# Verifica se já possui o pergaminho para não duplicar
	for item in grimorio:
		if item.get("titulo") == titulo:
			# Atualiza as páginas se já existia
			item["paginas"] = paginas
			salvar()
			return
			
	var texto_completo = ""
	for i in range(paginas.size()):
		texto_completo += "── PÁGINA " + str(i + 1) + " ──\n" + paginas[i] + "\n\n"
		
	grimorio.append({
		"titulo": titulo,
		"texto": texto_completo,
		"paginas": paginas,
		"desc": desc if desc != "" else "Um pergaminho antigo contendo dicas arcanas."
	})
	salvar()
	print("[PlayerStats] Pergaminho adicionado ao Grimório: ", titulo)

## Adiciona um Códice Científico/Mural Interativo ao Grimório do jogador
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

## Verifica se o jogador já possui um Códice específico no Grimório
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
	# [GOD MODE / DEV TOOL] Ignora dano se o modo invencível estiver ativo
	var dev_mgr = get_node_or_null("/root/DevManager")
	if dev_mgr and dev_mgr.DEV_MODE_ENABLED and dev_mgr.invencivel:
		print("[DevManager] Dano de %.0f bloqueado pela invencibilidade!" % valor)
		return

	AudioManager.tocar_som_dano()
	vida_atual_jogador -= valor
	if vida_atual_jogador < 0:
		vida_atual_jogador = 0
	vida_alterada.emit(vida_atual_jogador, vida_maxima_jogador)
	salvar()

	if vida_atual_jogador <= 0:
		if get_tree() and not get_tree().paused:
			GlobalSignals.fim_de_jogo.emit(false, {"dano": valor, "causa": "Armadilha"})

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

signal vida_alterada(atual, maxima)

const SAVE_PATH = "user://save.json"

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	carregar()

func _inicializar_dados_padrao():
	vida_atual_jogador = vida_maxima_jogador
	pocoes.clear()
	itens.clear()
	grimorio.clear()
	
	# itens iniciais pra testar (apenas pocoes, grimorio comeca totalmente vazio)
	pocoes.append({"nome": "Poção de Vida", "qtd": 2, "cura": 50, "desc": "Cura 50 HP"})
	salvar()

func salvar():
	var save_dict = {
		"vida_atual_jogador": vida_atual_jogador,
		"pocoes": pocoes,
		"itens": itens,
		"grimorio": grimorio
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
			
			# Limpa o grimório para remover quaisquer pergaminhos antigos salvos anteriormente
			grimorio.clear()
			salvar()
			
			vida_alterada.emit(vida_atual_jogador, vida_maxima_jogador)
		else:
			_inicializar_dados_padrao()
	else:
		_inicializar_dados_padrao()


## Limpa todos os pergaminhos salvos no Grimório
func limpar_grimorio() -> void:
	grimorio.clear()
	salvar()


# funcao pra healar
func curar_vida(valor: float) -> void:
	vida_atual_jogador += valor
	if vida_atual_jogador > vida_maxima_jogador:
		vida_atual_jogador = vida_maxima_jogador
	vida_alterada.emit(vida_atual_jogador, vida_maxima_jogador)
	salvar()

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

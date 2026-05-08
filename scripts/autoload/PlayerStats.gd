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
	
	# itens iniciais pra testar
	pocoes.append({"nome": "Poção de Vida", "qtd": 2, "cura": 50, "desc": "Cura 50 HP"})
	grimorio.append({
		"titulo": "Anotação de um Aluno", 
		"texto": "Pelo visto, a magia dessa torre tem muito a ver com a Física do colégio... Percebi que os Golems de pedra ficam mais lentos quando a gravidade aumenta. Preciso revisar minhas anotações de Dinâmica antes de subir pro próximo andar!"
	})
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
			vida_atual_jogador = data.get("vida_atual_jogador", vida_maxima_jogador)
			
			# Se morreu no save anterior, ressuscita pra não ficar travado!
			if vida_atual_jogador <= 0:
				vida_atual_jogador = vida_maxima_jogador
				
			pocoes = data.get("pocoes", [])
			itens = data.get("itens", [])
			grimorio = data.get("grimorio", [])
			vida_alterada.emit(vida_atual_jogador, vida_maxima_jogador)
		else:
			_inicializar_dados_padrao()
	else:
		_inicializar_dados_padrao()

# funcao pra healar
func curar_vida(valor: float) -> void:
	vida_atual_jogador += valor
	if vida_atual_jogador > vida_maxima_jogador:
		vida_atual_jogador = vida_maxima_jogador
	vida_alterada.emit(vida_atual_jogador, vida_maxima_jogador)
	salvar()

# funcao de tomar dano
func sofrer_dano(valor: float) -> void:
	vida_atual_jogador -= valor
	if vida_atual_jogador < 0:
		vida_atual_jogador = 0
	vida_alterada.emit(vida_atual_jogador, vida_maxima_jogador)
	salvar()

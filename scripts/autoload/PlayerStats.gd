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

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# itens iniciais pra testar
	pocoes.append({"nome": "Poção de Vida", "qtd": 2, "cura": 50, "desc": "Cura 50 HP"})
	
	grimorio.append({
		"titulo": "Anotação de um Aluno", 
		"texto": "Pelo visto, a magia dessa torre tem muito a ver com a Física do colégio... Percebi que os Golems de pedra ficam mais lentos quando a gravidade aumenta. Preciso revisar minhas anotações de Dinâmica antes de subir pro próximo andar!"
	})

# funcao pra healar
func curar_vida(valor: float) -> void:
	vida_atual_jogador += valor
	if vida_atual_jogador > vida_maxima_jogador:
		vida_atual_jogador = vida_maxima_jogador
	vida_alterada.emit(vida_atual_jogador, vida_maxima_jogador)

# funcao de tomar dano
func sofrer_dano(valor: float) -> void:
	vida_atual_jogador -= valor
	if vida_atual_jogador < 0:
		vida_atual_jogador = 0
	vida_alterada.emit(vida_atual_jogador, vida_maxima_jogador)

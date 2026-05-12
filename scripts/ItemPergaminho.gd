extends Area2D

# Textos do pergaminho
@export_multiline var paginas: Array[String] = [
	"Página 1 do pergaminho...",
	"Página 2 do pergaminho..."
]

# Referência da interface
@onready var ui = get_node("/root/Teste Player/ParchmentUI")


func _ready() -> void:
	connect("body_entered", _quando_corpo_entra)


func _quando_corpo_entra(corpo: Node2D) -> void:

	# Verifica se quem entrou foi o Player
	if corpo.name != "Player":
		return

	# Trava o movimento do Player
	corpo.travado = true

	# Abre o pergaminho na tela
	if ui:
		ui.abrir_pergaminho(paginas, corpo)

	# Remove o pergaminho do mapa
	queue_free()

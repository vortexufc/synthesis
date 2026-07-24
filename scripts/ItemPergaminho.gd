extends Area2D

# Textos do pergaminho
@export var titulo_pergaminho: String = "Pergaminho Encontrado"
@export_multiline var paginas: Array[String] = [
	"Página 1 do pergaminho...",
	"Página 2 do pergaminho..."
]

func _ready() -> void:
	body_entered.connect(_quando_corpo_entra)

func _quando_corpo_entra(corpo: Node2D) -> void:
	# Verifica se quem entrou foi o Player
	if not corpo.is_in_group("player") and corpo.name != "Player":
		return

	# Salva no Inventário
	if get_node_or_null("/root/PlayerStats"):
		PlayerStats.adicionar_pergaminho(titulo_pergaminho, paginas)

	# Abre o pergaminho na tela dinamicamente
	var ui = get_tree().get_first_node_in_group("parchment_ui")
	if ui == null and get_tree().current_scene:
		ui = get_tree().current_scene.find_child("ParchmentUI", true, false)

	if ui and ui.has_method("abrir_pergaminho"):
		ui.abrir_pergaminho(paginas, corpo)

	# Remove o pergaminho do mapa
	queue_free()


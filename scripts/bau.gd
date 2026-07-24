extends Area2D

## [Pergaminho/Baú] Componente de Baú com Pergaminhos Arcanos.
## Revela um pergaminho de até 4 páginas com dicas sobre as questões do andar/sala.
## Salva o pergaminho no inventário do jogador (Aba Grimório).

@export var titulo_pergaminho: String = "Pergaminho Arcano"
@export var usar_paginas_custom: bool = false
@export_multiline var paginas_custom: Array[String] = []
@export_range(1, 4) var num_paginas: int = 4

var ja_aberto: bool = false

@onready var sprite: Sprite2D = $BauSprite if has_node("BauSprite") else null

# Texturas da folha de sprite Alquimia/preto.png (32x32)
var tex_fechado: AtlasTexture
var tex_aberto: AtlasTexture

func _ready() -> void:
	# Prepara as texturas para o baú fechado e aberto
	var base_tex = load("res://assets/sprites/tilesets/Alquimia/preto.png")
	if base_tex:
		tex_fechado = AtlasTexture.new()
		tex_fechado.atlas = base_tex
		tex_fechado.region = Rect2(0, 128, 32, 32)
		
		tex_aberto = AtlasTexture.new()
		tex_aberto.atlas = base_tex
		tex_aberto.region = Rect2(32, 128, 32, 32)
		
		if sprite:
			sprite.texture = tex_fechado

	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if ja_aberto:
		return
	if not body.is_in_group("player") and body.name != "Player":
		return

	ja_aberto = true
	
	# Transiciona o sprite para o estado Aberto
	if sprite and tex_aberto:
		sprite.texture = tex_aberto

	# Toca efeito sonoro se disponível
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui-1")

	# Obtém as páginas do pergaminho (até 4 páginas)
	var paginas: Array[String] = []
	if usar_paginas_custom and paginas_custom.size() > 0:
		paginas = paginas_custom
	else:
		var andar_id = 1
		if get_node_or_null("/root/QuizManager"):
			andar_id = QuizManager._andar_atual
		paginas = PergaminhoManager.obter_paginas_dicas(andar_id, [], num_paginas)

	# Salva o pergaminho no Inventário (Aba Grimório)
	if get_node_or_null("/root/PlayerStats"):
		var nome_sala = ""
		if get_tree() and get_tree().current_scene:
			nome_sala = get_tree().current_scene.name
		var titulo_final = titulo_pergaminho
		if nome_sala != "":
			titulo_final += " (" + nome_sala + ")"
		PlayerStats.adicionar_pergaminho(titulo_final, paginas)

	# Localiza a UI do Pergaminho e abre
	var ui = get_tree().get_first_node_in_group("parchment_ui")
	if ui == null and get_tree().current_scene:
		ui = get_tree().current_scene.find_child("ParchmentUI", true, false)

	if ui and ui.has_method("abrir_pergaminho"):
		ui.abrir_pergaminho(paginas, body)
	else:
		push_warning("[Bau] ParchmentUI não foi encontrado na cena!")

extends Control

@onready var label_posicao = $HBox/LblPosicao
@onready var icone_medalha = $HBox/IconeMedalha
@onready var icone_mago = $HBox/IconeMago
@onready var label_nome = $HBox/LblNome
@onready var label_score = $HBox/LblScore

var tex_ouro = load("res://assets/sprites/ui/ranking/medalha_ouro.png")
var tex_prata = load("res://assets/sprites/ui/ranking/medalha_prata.png")
var tex_bronze = load("res://assets/sprites/ui/ranking/medalha_bronze.png")
var tex_mago = load("res://assets/sprites/ui/ranking/icone_mago.png")

func _ready():
	_aplicar_visual()

func _aplicar_visual():
	var font = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf")
	
	# Zera o fundo de cada jogador para que as linhas do "MENU Quadrado" que estão lá atrás apareçam
	var style_vazio = StyleBoxEmpty.new()
	add_theme_stylebox_override("panel", style_vazio)
	
	# Aplica o mago
	if tex_mago:
		icone_mago.texture = tex_mago
	
	# Aplica fonte nas labels
	if font:
		label_posicao.add_theme_font_override("font", font)
		label_nome.add_theme_font_override("font", font)
		label_score.add_theme_font_override("font", font)

func set_info(posicao: int, nome: String, score: int, eh_cla: bool = false) -> void:
	if not is_node_ready():
		await ready
		
	# Textos básicos
	label_nome.text = nome
	label_score.text = str(score) + " PTS"
	
	# Esconde o capuz se for aba de clã
	if eh_cla:
		icone_mago.hide()
	else:
		icone_mago.show()
	
	# Faz com que a label e a medalha ocupem exatamente a mesma largura, para o Capuz não "pular"
	label_posicao.custom_minimum_size.x = 60
	icone_medalha.custom_minimum_size.x = 60
	
	# Medalhas originais do figma substituindo o número nas primeiras posições
	if posicao == 1:
		label_posicao.hide()
		icone_medalha.show()
		icone_medalha.texture = tex_ouro
	elif posicao == 2:
		label_posicao.hide()
		icone_medalha.show()
		icone_medalha.texture = tex_prata
	elif posicao == 3:
		label_posicao.hide()
		icone_medalha.show()
		icone_medalha.texture = tex_bronze
	else:
		icone_medalha.hide() # Esconde a área da medalha
		label_posicao.show() # Mostra apenas o texto 4º, 5º...
		label_posicao.text = str(posicao) + "º"


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
	
	# tira o fundo pra nao cobrir o painel
	var style_vazio = StyleBoxEmpty.new()
	add_theme_stylebox_override("panel", style_vazio)
	
	# icone do mago
	if tex_mago:
		icone_mago.texture = tex_mago
	
	var font_num = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	
	label_posicao.add_theme_font_override("font", font_num)
	label_score.add_theme_font_override("font", font_num)
	if font:
		label_nome.add_theme_font_override("font", font)

func set_info(posicao: int, nome: String, score: int, eh_cla: bool = false) -> void:
	if not is_node_ready():
		await ready
		
	# preenche os textos
	label_nome.text = nome
	label_score.text = str(score) + " PTS"
	
	# esconde o capuz na aba de clas
	if eh_cla:
		icone_mago.hide()
	else:
		icone_mago.show()
	
	# alinha o espaco da medalha
	label_posicao.custom_minimum_size.x = 60
	icone_medalha.custom_minimum_size.x = 60
	
	# medalhas do top 3
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


extends Control

@onready var container_lista = $PainelCentro/VBoxLista/ScrollContainer/ListaContent
@onready var btn_geral = $PainelCentro/HBoxAbas/BtnGeral
@onready var btn_clas = $PainelCentro/HBoxAbas/BtnClas
@onready var btn_voltar = $PainelCentro/BtnVoltar

# Vamos usar uma cena separada para cada linha (jogador/clã) do ranking
# Você deve salvar essa mini-cena em res://scenes/ui/ranking_item.tscn
var item_cena = preload("res://scenes/ui/ranking_item.tscn")

enum ModoRanking { GERAL, CLAS }
var modo_atual = ModoRanking.GERAL

func _ready():
	_aplicar_visual()
	
	btn_geral.pressed.connect(_on_btn_geral_pressed)
	btn_clas.pressed.connect(_on_btn_clas_pressed)
	btn_voltar.pressed.connect(_on_btn_voltar_pressed)
	
	# Pede ao Autoload para carregar do disco (json)
	RankingManager.load_ranking()
	_atualizar_lista()

func _aplicar_visual():
	# Carrega as imagens e fontes
	var tex_fundo_tela = load("res://assets/sprites/ui/ranking/painel_fundo.png") # o fundo com árvores/torre
	var tex_painel_central = load("res://assets/sprites/ui/ranking/item_fundo.png") # o "MENU quadrado" azul
	var font = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf")
	
	# Substitui o ColorRect genérico pelo fundo pintado da tela toda
	if get_node_or_null("ColorRect"):
		$ColorRect.hide()
		
	var rect_fundo = TextureRect.new()
	rect_fundo.texture = tex_fundo_tela
	rect_fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect_fundo.ignore_texture_size = true
	add_child(rect_fundo)
	move_child(rect_fundo, 0)
	
	# Aplica a imagem azul do Figma apenas no Painel Central
	var style_centro = StyleBoxTexture.new()
	if tex_painel_central:
		style_centro.texture = tex_painel_central
	$PainelCentro.add_theme_stylebox_override("panel", style_centro)
	
	# Aplica a fonte e cor branca no título
	if font:
		$PainelCentro/LblTitulo.add_theme_font_override("font", font)
		$PainelCentro/LblTitulo.add_theme_font_size_override("font_size", 32)
		$PainelCentro/LblTitulo.add_theme_color_override("font_color", Color.WHITE)
		btn_geral.add_theme_font_override("font", font)
		btn_clas.add_theme_font_override("font", font)
		btn_voltar.add_theme_font_override("font", font)
		
	# Estilo do botão voltar (Azul escuro com borda azul vibrante)
	var style_voltar = StyleBoxFlat.new()
	style_voltar.bg_color = Color("142240")
	style_voltar.border_color = Color("0088ff")
	style_voltar.set_border_width_all(2)
	btn_voltar.add_theme_stylebox_override("normal", style_voltar)
	btn_voltar.add_theme_stylebox_override("hover", style_voltar)
	btn_voltar.add_theme_color_override("font_color", Color.WHITE)
	
	# Empurra o botão Voltar para baixo, totalmente fora do PainelCentral azul
	btn_voltar.position.y = 520
		
	_atualizar_botoes()

func _atualizar_botoes():
	# Estilo Azul (Ativo)
	var style_ativo = StyleBoxFlat.new()
	style_ativo.bg_color = Color("284eed")
	style_ativo.border_color = Color("686ff8")
	style_ativo.set_border_width_all(3)
	
	# Estilo Branco/Cinza (Inativo)
	var style_inativo = StyleBoxFlat.new()
	style_inativo.bg_color = Color("d9d9d9")
	style_inativo.border_color = Color("686ff8")
	style_inativo.set_border_width_all(3)
	
	if modo_atual == ModoRanking.GERAL:
		btn_geral.add_theme_stylebox_override("normal", style_ativo)
		btn_geral.add_theme_stylebox_override("hover", style_ativo)
		btn_geral.add_theme_color_override("font_color", Color.WHITE)
		btn_geral.add_theme_color_override("font_hover_color", Color.WHITE)
		
		btn_clas.add_theme_stylebox_override("normal", style_inativo)
		btn_clas.add_theme_stylebox_override("hover", style_inativo)
		btn_clas.add_theme_color_override("font_color", Color.BLACK)
		btn_clas.add_theme_color_override("font_hover_color", Color.BLACK)
	else:
		btn_geral.add_theme_stylebox_override("normal", style_inativo)
		btn_geral.add_theme_stylebox_override("hover", style_inativo)
		btn_geral.add_theme_color_override("font_color", Color.BLACK)
		btn_geral.add_theme_color_override("font_hover_color", Color.BLACK)
		
		btn_clas.add_theme_stylebox_override("normal", style_ativo)
		btn_clas.add_theme_stylebox_override("hover", style_ativo)
		btn_clas.add_theme_color_override("font_color", Color.WHITE)
		btn_clas.add_theme_color_override("font_hover_color", Color.WHITE)

func _on_btn_geral_pressed():
	modo_atual = ModoRanking.GERAL
	_atualizar_lista()
	_atualizar_botoes()

func _on_btn_clas_pressed():
	modo_atual = ModoRanking.CLAS
	_atualizar_lista()
	_atualizar_botoes()

func _on_btn_voltar_pressed():
	TransitionScreen.change_scene("res://scenes/ui/main_menu.tscn")

func _atualizar_lista():
	# Limpa a lista atual
	for child in container_lista.get_children():
		child.queue_free()
		
	var lista_dados = []
	var eh_cla = false
	if modo_atual == ModoRanking.GERAL:
		lista_dados = RankingManager.ranking_geral
	else:
		lista_dados = ClanManager.get_top_clans()
		eh_cla = true
		
	# Adiciona os itens na UI
	var pos = 1
	for item in lista_dados:
		var node = item_cena.instantiate()
		container_lista.add_child(node)
		node.set_info(pos, item["name"], item["score"], eh_cla)
		pos += 1

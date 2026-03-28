extends Control

@onready var btn_jogar = $MarginContainer/VBoxButtons/BtnJogar
@onready var btn_ranking = $MarginContainer/VBoxButtons/BtnRanking
@onready var btn_vestiario = $MarginContainer/VBoxButtons/BtnVestiario
@onready var btn_config = $MarginContainer/VBoxButtons/BtnConfig

func _ready() -> void:
	# Conectando os sinais 'pressed' aos seus respectivos callbacks
	btn_jogar.pressed.connect(_on_btn_jogar_pressed)
	btn_ranking.pressed.connect(_on_btn_ranking_pressed)
	btn_vestiario.pressed.connect(_on_btn_vestiario_pressed)
	btn_config.pressed.connect(_on_btn_config_pressed)
	
	# ========= SISTEMA DE PERFIL (BACKEND-6) =========
	var hbox_perfil = HBoxContainer.new()
	hbox_perfil.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hbox_perfil.position = Vector2(24, 24)
	hbox_perfil.add_theme_constant_override("separation", 12)
	
	var btn_avatar = TextureButton.new()
	var tex = load("res://avatar.png.png") as Texture2D
	
	if tex == null:
		tex = load("res://avatar.png") as Texture2D
		
	if tex == null:
		tex = PlaceholderTexture2D.new()
		tex.size = Vector2(48, 48)
		
	btn_avatar.texture_normal = tex
	btn_avatar.ignore_texture_size = true
	btn_avatar.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn_avatar.custom_minimum_size = Vector2(48, 48)
	
	var lbl_nome = Label.new()
	var font = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf")
	if font: lbl_nome.add_theme_font_override("font", font)
	lbl_nome.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	if DatabaseManager.user_token == "":
		lbl_nome.text = "NÃO LOGADO"
		btn_avatar.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/cadastro.tscn"))
	else:
		lbl_nome.text = DatabaseManager.user_nick.to_upper() + "\nCLÃ: " + DatabaseManager.user_cla.to_upper()
		# Tenta pintar de outra cor pra simular o avatar do mago por enquanto
		btn_avatar.modulate = Color(0.2, 0.5, 1.0) # Azul mágico!
		
	hbox_perfil.add_child(btn_avatar)
	hbox_perfil.add_child(lbl_nome)
	add_child(hbox_perfil)
	# =================================================

func _on_btn_jogar_pressed() -> void:
	print("Botão JOGAR pressionado")
	# Exemplo de navegação para tela de login ou quiz
	# get_tree().change_scene_to_file("res://scenes/ui/login.tscn")

func _on_btn_ranking_pressed() -> void:
	print("Botão RANKING pressionado")

func _on_btn_vestiario_pressed() -> void:
	print("Botão VESTIÁRIO pressionado")

func _on_btn_config_pressed() -> void:
	print("Botão CONFIGURAÇÕES pressionado")
	get_tree().change_scene_to_file("res://scenes/ui/configuracoes.tscn")

# ---------------------------------------------------------
# LIDERANÇA DA SEMANA (Leaderboard) - PRONTO PARA SUPABASE
# ---------------------------------------------------------

# Exemplo de como você vai receber os dados do Supabase depois e preencher:
func update_leaderboard(top_3_clans: Array) -> void:
	# Supondo que top_3_clans seja um array de dicionários: 
	# [{ "nome": "...", "pontos": 1200, "foto_url": "..." }, ...]
	
	for i in range(min(top_3_clans.size(), 3)):
		var clan_node = $LeaderboardPanel/MarginContainer/VBoxContainer.get_node("Clan" + str(i + 1))
		var clan_data = top_3_clans[i]
		
		# Atualiza nome e pontos
		clan_node.get_node("VBoxInfo/Name").text = clan_data["nome"].to_upper()
		clan_node.get_node("VBoxInfo/Pts").text = "PONTOS: " + str(clan_data["pontos"])
		
		# TODO: Aqui entrará a lógica para baixar a foto do clan via HTTPRequest e aplicar na TextureRect:
		# var logo_texture = clan_node.get_node("LogoPanel/LogoTexture")
		# download_and_set_texture(clan_data["foto_url"], logo_texture)


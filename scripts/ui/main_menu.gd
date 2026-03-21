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


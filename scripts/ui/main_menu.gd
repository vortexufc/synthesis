extends Control

@onready var btn_jogar = $MarginContainer/VBoxButtons/BtnJogar
@onready var btn_ranking = $MarginContainer/VBoxButtons/BtnRanking
@onready var btn_clas = $MarginContainer/VBoxButtons/BtnClas
@onready var btn_config = $MarginContainer/VBoxButtons/BtnConfig

# Guardamos referências para poder atualizar dinamicamente
var _lbl_nome: Label = null
var _btn_avatar: TextureButton = null

func _ready() -> void:
	# Conectando os sinais 'pressed' aos seus respectivos callbacks
	btn_jogar.pressed.connect(_on_btn_jogar_pressed)
	btn_ranking.pressed.connect(_on_btn_ranking_pressed)
	btn_clas.pressed.connect(_on_btn_clas_pressed)
	btn_config.pressed.connect(_on_btn_config_pressed)
	
	# ========= SISTEMA DE PERFIL (BACKEND-6) =========
	var hbox_perfil = HBoxContainer.new()
	hbox_perfil.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hbox_perfil.position = Vector2(24, 24)
	hbox_perfil.add_theme_constant_override("separation", 12)
	
	_btn_avatar = TextureButton.new()
	var tex = load("res://avatar.png.png") as Texture2D
	
	if tex == null:
		tex = load("res://avatar.png") as Texture2D
		
	if tex == null:
		tex = PlaceholderTexture2D.new()
		tex.size = Vector2(48, 48)
		
	_btn_avatar.texture_normal = tex
	_btn_avatar.ignore_texture_size = true
	_btn_avatar.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_btn_avatar.custom_minimum_size = Vector2(80, 80)
	
	_lbl_nome = Label.new()
	var font = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf")
	if font: _lbl_nome.add_theme_font_override("font", font)
	_lbl_nome.add_theme_font_size_override("font_size", 24)
	_lbl_nome.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	if DatabaseManager.user_token == "":
		_lbl_nome.text = "NÃO LOGADO"
		_btn_avatar.pressed.connect(func(): TransitionScreen.change_scene("res://scenes/ui/login.tscn"))
	else:
		_atualizar_perfil()
		
	hbox_perfil.add_child(_btn_avatar)
	hbox_perfil.add_child(_lbl_nome)
	add_child(hbox_perfil)
	# =================================================
	
	# ========= LEADERBOARD COM PERÍODOS (ONLINE) =========
	_inicializar_leaderboard()
	# Re-atualiza quando ClanManager ou RankingManager terminarem de carregar
	ClanManager.clan_list_updated.connect(_atualizar_leaderboard)
	RankingManager.ranking_atualizado.connect(_atualizar_leaderboard)
	# Atualiza o perfil quando o check_membership_sync corrigir um clã fantasma
	ClanManager.clan_updated.connect(_atualizar_perfil)
	# ====================================================

func _atualizar_perfil() -> void:
	if _lbl_nome == null or DatabaseManager.user_token == "":
		return
	_lbl_nome.text = DatabaseManager.user_nick.to_upper() + "\nCLÃ: " + DatabaseManager.user_cla.to_upper()
	# Carrega a foto do mago do ranking se ainda não foi carregada
	if _btn_avatar != null:
		var tex_mago = load("res://assets/sprites/ui/ranking/icone_mago.png") as Texture2D
		if tex_mago:
			_btn_avatar.texture_normal = tex_mago
		_btn_avatar.modulate = Color(1.0, 1.0, 1.0)

func _on_btn_jogar_pressed() -> void:
	print("Botão JOGAR pressionado")
	if get_node_or_null("/root/DungeonGenerator"):
		DungeonGenerator.resetar_masmorra()
	if get_node_or_null("/root/QuizManager"):
		QuizManager.resetar_historico_perguntas()
	# Muda para a cena do andar 1 (Corredor)
	TransitionScreen.change_scene("res://scenes/Salas/Salas_BuildTGXP/Corredor.tscn")

func _on_btn_ranking_pressed() -> void:
	print("Botão RANKING pressionado - abrindo RankingLocal")
	TransitionScreen.change_scene("res://scenes/ui/ranking_ui.tscn")

func _on_btn_clas_pressed() -> void:
	print("Botão CLÃS pressionado - abrindo TelaClas")
	TransitionScreen.change_scene("res://scenes/ui/TelaClas.tscn")

func _on_btn_config_pressed() -> void:
	print("Botão CONFIGURAÇÕES pressionado")
	TransitionScreen.change_scene("res://scenes/ui/configuracoes.tscn")

# ---------------------------------------------------------
# LIDERANÇA — Alimentada pelo ClanManager online
# Suporta 3 períodos: diario / semanal / mensal
# ---------------------------------------------------------

# Período atual exibido no painel
var _periodo_atual: String = "semanal"
var _periodos: Array = ["diario", "semanal", "mensal"]

# Referências aos nós do leaderboard (cacheadas para não re-buscar toda hora)
var _leaderboard_panel: PanelContainer = null
var _lbl_title: Label = null
var _btn_prev: Button = null
var _btn_next: Button = null

func _inicializar_leaderboard() -> void:
	_leaderboard_panel = get_node_or_null("LeaderboardPanel")
	if _leaderboard_panel == null:
		return
	_lbl_title = _leaderboard_panel.get_node_or_null("MarginContainer/VBoxContainer/HeaderHBox/LabelTitle")
	_btn_prev  = _leaderboard_panel.get_node_or_null("MarginContainer/VBoxContainer/HeaderHBox/HBoxDots/BtnPrev")
	_btn_next  = _leaderboard_panel.get_node_or_null("MarginContainer/VBoxContainer/HeaderHBox/HBoxDots/BtnNext")
	
	# ◄ vai para o período anterior (ciclo)
	if _btn_prev:
		_btn_prev.pressed.connect(func():
			var idx = _periodos.find(_periodo_atual)
			_trocar_periodo(_periodos[(idx - 1 + _periodos.size()) % _periodos.size()])
		)
	# ► vai para o próximo período (ciclo)
	if _btn_next:
		_btn_next.pressed.connect(func():
			var idx = _periodos.find(_periodo_atual)
			_trocar_periodo(_periodos[(idx + 1) % _periodos.size()])
		)
	
	_atualizar_leaderboard()

func _trocar_periodo(novo_periodo: String) -> void:
	_periodo_atual = novo_periodo
	_atualizar_leaderboard()

func _atualizar_leaderboard() -> void:
	if _leaderboard_panel == null:
		return
	
	# Atualiza o título
	if _lbl_title:
		match _periodo_atual:
			"diario":  _lbl_title.text = "LIDERANÇA DO DIA"
			"semanal": _lbl_title.text = "LIDERANÇA DA SEMANA"
			"mensal":  _lbl_title.text = "LIDERANÇA DO MÊS"
	
	# Atualiza o ranking de acordo com o período
	var lista: Array = RankingManager.get_ranking_por_periodo(_periodo_atual)
	
	for i in range(1, 4):
		var clan_node = _leaderboard_panel.get_node_or_null("MarginContainer/VBoxContainer/Clan" + str(i))
		if clan_node == null:
			continue
			
		var name_lbl = clan_node.get_node_or_null("VBoxInfo/Name")
		var pts_lbl  = clan_node.get_node_or_null("VBoxInfo/Pts")
		
		if name_lbl == null or pts_lbl == null:
			continue
			
		var idx = i - 1
		if idx < lista.size():
			name_lbl.text = lista[idx].get("name", "---").to_upper()
			pts_lbl.text  = "PONTOS: " + str(lista[idx].get("score", 0))
		else:
			name_lbl.text = "---"
			pts_lbl.text  = "PONTOS: 0"


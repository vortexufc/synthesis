extends Control

@onready var btn_jogar = $MarginContainer/VBoxButtons/BtnJogar
@onready var btn_ranking = $MarginContainer/VBoxButtons/BtnRanking
@onready var btn_clas = $MarginContainer/VBoxButtons/BtnClas
@onready var btn_config = $MarginContainer/VBoxButtons/BtnConfig

@onready var bg = find_child("Background", true, false) as TextureRect
@onready var logo = find_child("Logo", true, false) as TextureRect
@onready var vbox_buttons = find_child("VBoxButtons", true, false) as VBoxContainer
@onready var leaderboard_panel_node = find_child("LeaderboardPanel", true, false) as PanelContainer

# referencias dos nos da tela
var _lbl_nome: Label = null
var _btn_avatar: TextureButton = null

var _tempo_menu: float = 0.0
var _logo_base_y: float = 0.0
var _bg_base_pos: Vector2 = Vector2.ZERO
var _parallax_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	# toca musica do menu
	AudioManager.play_menu_music()
	
	if logo:
		_logo_base_y = logo.position.y
	if bg:
		_bg_base_pos = bg.position
	
	# conecta os cliques dos botoes
	btn_jogar.pressed.connect(_on_btn_jogar_pressed)
	btn_ranking.pressed.connect(_on_btn_ranking_pressed)
	btn_clas.pressed.connect(_on_btn_clas_pressed)
	btn_config.pressed.connect(_on_btn_config_pressed)
	
	if DatabaseManager.is_admin:
		var btn_admin = btn_jogar.duplicate()
		btn_admin.text = "PAINEL ADMIN"
		btn_admin.pressed.connect(func(): TransitionScreen.change_scene("res://scenes/ui/painel_admin.tscn"))
		var vbox = $MarginContainer/VBoxButtons
		vbox.add_child(btn_admin)
		vbox.move_child(btn_admin, 0) # Coloca no topo
		
	# animacoes dos botoes e particulas no fundo
	_criar_particulas_magicas()
	_configurar_animacoes_botoes()
	_animar_entrada_menu()
	
	# perfil do jogador
	var hbox_perfil = HBoxContainer.new()
	hbox_perfil.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hbox_perfil.position = Vector2(24, 24)
	hbox_perfil.add_theme_constant_override("separation", 12)
	
	_btn_avatar = TextureButton.new()
	var tex = load("res://assets/branding/avatar.png.png") as Texture2D
		
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
	
	
	# leaderboard online
	_inicializar_leaderboard()
	# atualiza quando carregar os clas e ranking
	ClanManager.clan_list_updated.connect(_atualizar_leaderboard)
	RankingManager.ranking_atualizado.connect(_atualizar_leaderboard)
	# atualiza o perfil se mudar de cla
	ClanManager.clan_updated.connect(_atualizar_perfil)

func _atualizar_perfil() -> void:
	if _lbl_nome == null or DatabaseManager.user_token == "":
		return
	_lbl_nome.text = DatabaseManager.user_nick.to_upper() + "\nCLÃ: " + DatabaseManager.user_cla.to_upper()
	# icone do mago no perfil
	if _btn_avatar != null:
		var tex_mago = load("res://assets/sprites/ui/ranking/icone_mago.png") as Texture2D
		if tex_mago:
			_btn_avatar.texture_normal = tex_mago
		_btn_avatar.modulate = Color(1.0, 1.0, 1.0)

func _on_btn_jogar_pressed() -> void:
	print("Botão JOGAR pressionado")
	
	# clique em jogar
	AudioManager.play_sfx("ui_5")
	
	if get_node_or_null("/root/DungeonGenerator"):
		DungeonGenerator.resetar_masmorra()
		DungeonGenerator.tocar_cutscene_inicial = true
	if get_node_or_null("/root/QuizManager"):
		QuizManager.resetar_historico_perguntas()
		
	# troca de cena pro hub
	AudioManager.play_sfx("transicao-1")
	TransitionScreen.change_scene("res://scenes/Salas/Comum/Hub_Geral.tscn")

func _on_btn_ranking_pressed() -> void:
	print("Botão RANKING pressionado - abrindo RankingLocal")
	
	# abre ranking
	AudioManager.play_sfx("ui_5")
	
	TransitionScreen.change_scene("res://scenes/ui/ranking_ui.tscn")

func _on_btn_clas_pressed() -> void:
	print("Botão CLÃS pressionado - abrindo TelaClas")
	
	# abre clas
	AudioManager.play_sfx("ui_5")
	
	TransitionScreen.change_scene("res://scenes/ui/TelaClas.tscn")

func _on_btn_config_pressed() -> void:
	print("Botão CONFIGURAÇÕES pressionado")
	
	# abre configuracoes
	AudioManager.play_sfx("ui_5")
	
	TransitionScreen.change_scene("res://scenes/ui/configuracoes.tscn")

# leaderboard com filtro de periodo

# periodo atual do filtro
var _periodo_atual: String = "quimica"
var _periodos: Array = ["quimica", "fisica", "biologia"]

# referencias dos nos da lista
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
	
	# volta periodo
	if _btn_prev:
		_btn_prev.pressed.connect(func():
			var idx = _periodos.find(_periodo_atual)
			_trocar_periodo(_periodos[(idx - 1 + _periodos.size()) % _periodos.size()])
		)
	# avanca periodo
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
	
	# atualiza o titulo
	if _lbl_title:
		match _periodo_atual:
			"quimica":  _lbl_title.text = "LIDERANÇA QUIMICA"
			"fisica": _lbl_title.text = "LIDERANÇA FISICA"
			"biologia":  _lbl_title.text = "LIDERANÇA BIOLOGIA"
	
	# busca o ranking do periodo
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

func _process(delta: float) -> void:
	_tempo_menu += delta
	
	# animacao de flutuar do logo
	if logo and is_instance_valid(logo):
		logo.position.y = _logo_base_y + sin(_tempo_menu * 1.7) * 5.5
		logo.rotation = sin(_tempo_menu * 0.85) * 0.012
		
	# parallax com o mouse
	if bg and is_instance_valid(bg):
		var vp_rect = get_viewport_rect()
		var mouse_pos = get_viewport().get_mouse_position()
		var center = vp_rect.size * 0.5
		if center.x > 0 and center.y > 0:
			var norm = Vector2(
				clamp((mouse_pos.x - center.x) / center.x, -1.0, 1.0),
				clamp((mouse_pos.y - center.y) / center.y, -1.0, 1.0)
			)
			_parallax_offset = _parallax_offset.lerp(norm * 14.0, delta * 3.5)
			bg.position = _bg_base_pos - _parallax_offset

func _configurar_animacoes_botoes() -> void:
	if vbox_buttons:
		for child in vbox_buttons.get_children():
			if child is Button:
				_animar_botao(child)

func _animar_botao(btn: Button) -> void:
	# centraliza o pivot
	btn.resized.connect(func(): btn.pivot_offset = btn.size * 0.5)
	btn.pivot_offset = btn.size * 0.5
	
	btn.mouse_entered.connect(func():
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("ui-1")
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.16)
		tw.tween_property(btn, "position:x", 8.0, 0.16)
	)
	
	btn.mouse_exited.connect(func():
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.18)
		tw.tween_property(btn, "position:x", 0.0, 0.18)
	)
	
	btn.button_down.connect(func():
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2(0.96, 0.96), 0.08)
	)
	
	btn.button_up.connect(func():
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.1)
	)

func _animar_entrada_menu() -> void:
	# animacao de entrada dos botoes
	if vbox_buttons:
		var delay = 0.04
		for child in vbox_buttons.get_children():
			if child is Button:
				child.modulate.a = 0.0
				child.position.x = -25.0
				var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				tw.tween_property(child, "modulate:a", 1.0, 0.35).set_delay(delay)
				tw.tween_property(child, "position:x", 0.0, 0.35).set_delay(delay)
				delay += 0.06
				
	# animacao de entrada da lista
	if leaderboard_panel_node:
		var base_x = leaderboard_panel_node.position.x
		leaderboard_panel_node.modulate.a = 0.0
		leaderboard_panel_node.position.x = base_x + 30.0
		var tw_lb = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw_lb.tween_property(leaderboard_panel_node, "modulate:a", 1.0, 0.45).set_delay(0.12)
		tw_lb.tween_property(leaderboard_panel_node, "position:x", base_x, 0.45).set_delay(0.12)

func _criar_textura_particula() -> Texture2D:
	var grad_tex = GradientTexture2D.new()
	var grad = Gradient.new()
	grad.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CUBIC
	grad.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.5),
		Color(1.0, 1.0, 1.0, 0.0)
	])
	grad_tex.gradient = grad
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(1.0, 0.5)
	grad_tex.width = 24
	grad_tex.height = 24
	return grad_tex

func _criar_particulas_magicas() -> void:
	var particles = CPUParticles2D.new()
	particles.name = "ParticulasMagicasMenu"
	particles.texture = _criar_textura_particula()
	particles.amount = 42
	particles.lifetime = 6.5
	particles.preprocess = 4.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(1000, 560)
	particles.position = Vector2(960, 540)
	particles.direction = Vector2(0.15, -1.0)
	particles.spread = 45.0
	particles.gravity = Vector2(0, -8)
	particles.initial_velocity_min = 18.0
	particles.initial_velocity_max = 48.0
	particles.scale_amount_min = 0.35
	particles.scale_amount_max = 0.85
	
	var grad = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.25, 0.75, 1.0])
	grad.colors = PackedColorArray([
		Color(0.2, 0.75, 1.0, 0.0),
		Color(0.3, 0.85, 1.0, 0.75),
		Color(1.0, 0.88, 0.45, 0.75),
		Color(0.85, 0.4, 1.0, 0.0)
	])
	particles.color_ramp = grad
	
	if bg:
		bg.add_sibling(particles)
	else:
		add_child(particles)
		move_child(particles, 1)

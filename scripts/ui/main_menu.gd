extends Control

const INSTAGRAM_URL: String = "https://www.instagram.com/vortexufc/"

@onready var btn_jogar = $MarginContainer/VBoxButtons/BtnJogar
@onready var btn_ranking = $MarginContainer/VBoxButtons/BtnRanking
@onready var btn_clas = $MarginContainer/VBoxButtons/BtnClas
@onready var btn_config = $MarginContainer/VBoxButtons/BtnConfig
@onready var btn_creditos = get_node_or_null("MarginContainer/VBoxButtons/BtnCreditos") as Button

@onready var bg = find_child("Background", true, false) as TextureRect
@onready var logo = find_child("Logo", true, false) as TextureRect
@onready var vbox_buttons = find_child("VBoxButtons", true, false) as VBoxContainer
@onready var leaderboard_panel_node = find_child("LeaderboardPanel", true, false) as PanelContainer
@onready var btn_instagram_node = find_child("BtnInstagram", true, false) as Button

# referencias dos nos da tela
var _lbl_nome: Label = null
var _btn_avatar: TextureButton = null

var _tempo_menu: float = 0.0
var _logo_base_y: float = 0.0
var _bg_base_pos: Vector2 = Vector2.ZERO
var _parallax_offset: Vector2 = Vector2.ZERO
static var _aviso_visitante_visto: bool = false

func _ready() -> void:
	# toca musica do menu
	AudioManager.play_menu_music()
	
	if logo:
		_logo_base_y = logo.position.y
		_iniciar_animacao_logo()
	if bg:
		_bg_base_pos = bg.position
	
	# conecta os cliques dos botoes
	btn_jogar.pressed.connect(_on_btn_jogar_pressed)
	btn_ranking.pressed.connect(_on_btn_ranking_pressed)
	btn_clas.pressed.connect(_on_btn_clas_pressed)
	btn_config.pressed.connect(_on_btn_config_pressed)
	if btn_creditos:
		btn_creditos.pressed.connect(_on_btn_creditos_pressed)
	_configurar_card_instagram()
	
	# Se tiver jogo salvo com localizacao, exibe CONTINUAR e VOLTAR AO INÍCIO
	if PlayerStats and PlayerStats.tem_pos_salva and PlayerStats.cena_salva != "":
		btn_jogar.text = "CONTINUAR"
		
		var btn_novo = btn_jogar.duplicate()
		btn_novo.name = "BtnNovoJogo"
		btn_novo.text = "VOLTAR AO INÍCIO"
		btn_novo.custom_minimum_size = Vector2(0, 36)
		btn_novo.add_theme_font_size_override("font_size", 16)
		btn_novo.pressed.connect(_on_btn_novo_jogo_pressed)
		var vbox = $MarginContainer/VBoxButtons
		vbox.add_child(btn_novo)
		vbox.move_child(btn_novo, 1)
	else:
		btn_jogar.text = "NOVO JOGO"

	if DatabaseManager.is_admin:
		var btn_admin = btn_jogar.duplicate()
		btn_admin.text = "PAINEL ADMIN"
		btn_admin.custom_minimum_size = Vector2(0, 36)
		btn_admin.add_theme_font_size_override("font_size", 16)
		btn_admin.pressed.connect(func(): TransitionScreen.change_scene("res://scenes/ui/painel_admin.tscn"))
		var vbox = $MarginContainer/VBoxButtons
		vbox.add_child(btn_admin)
		vbox.move_child(btn_admin, 0) # Coloca no topo
		
	# animacoes dos botoes e particulas no fundo
	_criar_particulas_magicas()
	_configurar_animacoes_botoes()
	_animar_entrada_menu()
	
	# Perfil do jogador (Pílula moderna e translúcida no topo esquerdo)
	var panel_perfil = PanelContainer.new()
	panel_perfil.position = Vector2(24, 20)
	panel_perfil.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var style_pill = StyleBoxFlat.new()
	style_pill.bg_color = Color(0.05, 0.08, 0.16, 0.72)
	style_pill.border_color = Color(0.25, 0.55, 0.85, 0.65)
	style_pill.set_border_width_all(1)
	style_pill.corner_radius_top_left = 18
	style_pill.corner_radius_top_right = 18
	style_pill.corner_radius_bottom_right = 18
	style_pill.corner_radius_bottom_left = 18
	style_pill.content_margin_left = 6
	style_pill.content_margin_top = 4
	style_pill.content_margin_right = 14
	style_pill.content_margin_bottom = 4
	panel_perfil.add_theme_stylebox_override("panel", style_pill)
	
	var hbox_perfil = HBoxContainer.new()
	hbox_perfil.add_theme_constant_override("separation", 8)
	
	_btn_avatar = TextureButton.new()
	var tex = load("res://assets/sprites/ui/ranking/icone_mago.png") as Texture2D
	if tex == null:
		tex = load("res://assets/branding/avatar.png.png") as Texture2D
	_btn_avatar.texture_normal = tex
	_btn_avatar.ignore_texture_size = true
	_btn_avatar.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_btn_avatar.custom_minimum_size = Vector2(28, 28)
	
	_lbl_nome = Label.new()
	var font_normal = SystemFont.new()
	font_normal.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_normal.font_weight = 600
	_lbl_nome.add_theme_font_override("font", font_normal)
	_lbl_nome.add_theme_font_size_override("font_size", 13)
	_lbl_nome.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var _ir_login = func():
		AudioManager.play_sfx("ui_5")
		TransitionScreen.change_scene("res://scenes/ui/login.tscn")
	
	var _ao_clicar_perfil = func():
		if DatabaseManager.user_token == "":
			_abrir_modal_aviso_visitante(false, false)
		else:
			_ir_login.call()
	
	if DatabaseManager.user_token == "":
		_lbl_nome.text = "VISITANTE  •  ENTRAR"
		_lbl_nome.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	else:
		_atualizar_perfil()
		
	panel_perfil.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_ao_clicar_perfil.call()
	)
	_btn_avatar.pressed.connect(_ao_clicar_perfil)
		
	# Efeito de hover no perfil
	panel_perfil.pivot_offset = Vector2(60, 18)
	panel_perfil.mouse_entered.connect(func():
		var tw = create_tween()
		tw.tween_property(panel_perfil, "scale", Vector2(1.03, 1.03), 0.12)
	)
	panel_perfil.mouse_exited.connect(func():
		var tw = create_tween()
		tw.tween_property(panel_perfil, "scale", Vector2.ONE, 0.12)
	)
		
	hbox_perfil.add_child(_btn_avatar)
	hbox_perfil.add_child(_lbl_nome)
	panel_perfil.add_child(hbox_perfil)
	add_child(panel_perfil)
	
	# leaderboard online
	_inicializar_leaderboard()
	# atualiza quando carregar os clas e ranking
	ClanManager.clan_list_updated.connect(_atualizar_leaderboard)
	RankingManager.ranking_atualizado.connect(_atualizar_leaderboard)
	# atualiza o perfil se mudar de cla
	ClanManager.clan_updated.connect(_atualizar_perfil)

func _exit_tree() -> void:
	if ClanManager and ClanManager.clan_list_updated.is_connected(_atualizar_leaderboard):
		ClanManager.clan_list_updated.disconnect(_atualizar_leaderboard)
	if RankingManager and RankingManager.ranking_atualizado.is_connected(_atualizar_leaderboard):
		RankingManager.ranking_atualizado.disconnect(_atualizar_leaderboard)
	if ClanManager and ClanManager.clan_updated.is_connected(_atualizar_perfil):
		ClanManager.clan_updated.disconnect(_atualizar_perfil)

func _atualizar_perfil() -> void:
	if not is_inside_tree() or _lbl_nome == null or DatabaseManager.user_token == "":
		return
	var cla_texto = ""
	if not DatabaseManager.user_cla.is_empty() and DatabaseManager.user_cla != "Nenhum":
		cla_texto = " [" + DatabaseManager.user_cla.to_upper() + "]"
	_lbl_nome.text = DatabaseManager.user_nick.to_upper() + cla_texto
	_lbl_nome.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	
	if _btn_avatar != null:
		var tex_mago = load("res://assets/sprites/ui/ranking/icone_mago.png") as Texture2D
		if tex_mago:
			_btn_avatar.texture_normal = tex_mago
		_btn_avatar.modulate = Color(1.0, 1.0, 1.0)

func _on_btn_jogar_pressed() -> void:
	AudioManager.play_sfx("ui_5")
	if DatabaseManager.user_token.is_empty() and not _aviso_visitante_visto:
		_abrir_modal_aviso_visitante(true, true)
		return
	_executar_continuar_ou_novo_jogo()

func _on_btn_novo_jogo_pressed() -> void:
	AudioManager.play_sfx("ui_5")
	if DatabaseManager.user_token.is_empty() and not _aviso_visitante_visto:
		_abrir_modal_aviso_visitante(true, false)
		return
	_iniciar_novo_jogo()

func _executar_continuar_ou_novo_jogo() -> void:
	# Se tiver jogo salvo com localizacao, continua de onde parou!
	if PlayerStats and PlayerStats.tem_pos_salva and PlayerStats.cena_salva != "":
		print("[MainMenu] Continuando jogo na cena: %s na posicao (%.0f, %.0f)" % [PlayerStats.cena_salva, PlayerStats.pos_salva_x, PlayerStats.pos_salva_y])
		PlayerStats.restaurando_posicao_save = true
		PlayerStats.fade_spawn_player = true
		
		var dg = get_node_or_null("/root/DungeonGenerator")
		if dg and PlayerStats.percurso_salas_salvo.size() > 0:
			dg.percurso_salas = PlayerStats.percurso_salas_salvo.duplicate()
			dg.indice_atual = PlayerStats.indice_sala_salvo
			
		TransitionScreen.change_scene(PlayerStats.cena_salva, false, true)
		return
		
	_iniciar_novo_jogo()

func _abrir_modal_aviso_visitante(iniciar_jogo: bool = false, continuar: bool = false) -> void:
	var modal_cena = preload("res://scenes/ui/ModalAvisoVisitante.tscn")
	if modal_cena:
		var modal = modal_cena.instantiate()
		add_child(modal)
		modal.continuar_como_visitante.connect(func():
			_aviso_visitante_visto = true
			if iniciar_jogo:
				if continuar:
					_executar_continuar_ou_novo_jogo()
				else:
					_iniciar_novo_jogo()
		)

func _iniciar_novo_jogo() -> void:
	if PlayerStats:
		PlayerStats.resetar_vida()
		PlayerStats.resetar_progresso_mundo()
		PlayerStats.limpar_posicao_salva()
		PlayerStats.fade_spawn_player = true
	if get_node_or_null("/root/DungeonGenerator"):
		DungeonGenerator.resetar_masmorra()
		if PlayerStats and not PlayerStats.cutscene_inicial_vista:
			DungeonGenerator.tocar_cutscene_inicial = true
		else:
			DungeonGenerator.tocar_cutscene_inicial = false
	if get_node_or_null("/root/QuizManager"):
		QuizManager.resetar_historico_perguntas()
		
	# troca de cena pro hub
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

func _on_btn_creditos_pressed() -> void:
	AudioManager.play_sfx("ui_5")
	var modal_cena = preload("res://scenes/ui/creditos_modal.tscn")
	if modal_cena:
		var modal = modal_cena.instantiate()
		add_child(modal)

func _configurar_card_instagram() -> void:
	if btn_instagram_node == null:
		return
	
	btn_instagram_node.pressed.connect(_abrir_modal_instagram)
	
	# Animação de hover suave no botão do Instagram
	btn_instagram_node.pivot_offset = Vector2(72, 17)
	btn_instagram_node.mouse_entered.connect(func():
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("ui-1")
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn_instagram_node, "scale", Vector2(1.05, 1.05), 0.15)
	)
	
	btn_instagram_node.mouse_exited.connect(func():
		var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn_instagram_node, "scale", Vector2.ONE, 0.15)
	)

func _abrir_modal_instagram() -> void:
	AudioManager.play_sfx("ui_5")
	var modal_cena = preload("res://scenes/ui/ModalInstagram.tscn")
	if modal_cena:
		var modal = modal_cena.instantiate()
		add_child(modal)

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

var _lb_tween: Tween = null

func _trocar_periodo(novo_periodo: String) -> void:
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui-1")
	_periodo_atual = novo_periodo
	
	if _leaderboard_panel:
		var vbox = _leaderboard_panel.get_node_or_null("MarginContainer/VBoxContainer") as VBoxContainer
		if vbox:
			if _lb_tween and _lb_tween.is_valid():
				_lb_tween.kill()
			_lb_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			_lb_tween.tween_property(vbox, "modulate:a", 0.25, 0.08)
			_lb_tween.tween_callback(func():
				_atualizar_leaderboard()
			)
			_lb_tween.tween_property(vbox, "modulate:a", 1.0, 0.14)
			return
			
	_atualizar_leaderboard()

func _atualizar_leaderboard() -> void:
	if not is_inside_tree() or _leaderboard_panel == null:
		return

	var font_normal = SystemFont.new()
	font_normal.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_normal.font_weight = 600

	# atualiza o titulo com fonte limpa e cor dourada
	if _lbl_title:
		_lbl_title.add_theme_font_override("font", font_normal)
		_lbl_title.add_theme_font_size_override("font_size", 12)
		_lbl_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
		match _periodo_atual:
			"quimica":  _lbl_title.text = "LIDERANÇA QUÍMICA"
			"fisica":   _lbl_title.text = "LIDERANÇA FÍSICA"
			"biologia": _lbl_title.text = "LIDERANÇA BIOLOGIA"
	
	# busca o ranking do periodo
	var lista: Array = RankingManager.get_ranking_por_periodo(_periodo_atual)
	
	var nick_local = ""
	if DatabaseManager and not DatabaseManager.user_nick.is_empty():
		nick_local = DatabaseManager.user_nick
	elif RankingManager:
		nick_local = RankingManager.get_local_nick()

	var tex_mago = preload("res://assets/sprites/ui/ranking/icone_mago.png")

	for i in range(1, 4):
		var clan_node = _leaderboard_panel.get_node_or_null("MarginContainer/VBoxContainer/Clan" + str(i))
		if clan_node == null:
			continue
			
		var name_lbl = clan_node.get_node_or_null("VBoxInfo/Name") as Label
		var pts_lbl  = clan_node.get_node_or_null("VBoxInfo/Pts") as Label
		var logo_tex = clan_node.get_node_or_null("LogoPanel/LogoTexture") as TextureRect
		
		if logo_tex and tex_mago:
			logo_tex.texture = tex_mago
		
		if name_lbl == null or pts_lbl == null:
			continue
			
		# Aplica fonte normal para clareza e proporção perfeita da referência
		name_lbl.add_theme_font_override("font", font_normal)
		pts_lbl.add_theme_font_override("font", font_normal)
		name_lbl.add_theme_font_size_override("font_size", 12)
		pts_lbl.add_theme_font_size_override("font_size", 11)
			
		var idx = i - 1
		if idx < lista.size():
			var item_nome = str(lista[idx].get("name", "---"))
			var item_score = int(lista[idx].get("score", 0))
			
			if (item_nome == nick_local or item_nome == "Você") and not nick_local.is_empty():
				name_lbl.text = "VOCÊ"
				name_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3))
			else:
				name_lbl.text = item_nome.to_upper()
				name_lbl.remove_theme_color_override("font_color")
				
			pts_lbl.text = "PONTOS: " + str(item_score)
		else:
			name_lbl.text = "---"
			name_lbl.remove_theme_color_override("font_color")
			pts_lbl.text  = "PONTOS: 0"

func _process(delta: float) -> void:
	_tempo_menu += delta
	
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

func _iniciar_animacao_logo() -> void:
	if not logo or not is_instance_valid(logo):
		return
	logo.pivot_offset = Vector2(250, 115)
	
	# Flutuacao vertical fluida e suave com curvas senoidais continuas
	var tween_y = create_tween().set_loops()
	tween_y.tween_property(logo, "position:y", _logo_base_y - 7.0, 2.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_y.tween_property(logo, "position:y", _logo_base_y + 7.0, 2.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Balanco organico suave (sem trancos ou aceleracoes bruscas)
	var tween_rot = create_tween().set_loops()
	tween_rot.tween_property(logo, "rotation", deg_to_rad(0.6), 2.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_rot.tween_property(logo, "rotation", deg_to_rad(-0.6), 2.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Respiracao sutil de escala para dar vitalidade e profundidade
	var tween_scale = create_tween().set_loops()
	tween_scale.tween_property(logo, "scale", Vector2(1.018, 1.018), 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_scale.tween_property(logo, "scale", Vector2(0.992, 0.992), 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

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
		
	# animacao de entrada do botao do instagram
	if btn_instagram_node:
		var base_x_insta = btn_instagram_node.position.x
		btn_instagram_node.modulate.a = 0.0
		btn_instagram_node.position.x = base_x_insta + 25.0
		var tw_insta = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw_insta.tween_property(btn_instagram_node, "modulate:a", 1.0, 0.40).set_delay(0.08)
		tw_insta.tween_property(btn_instagram_node, "position:x", base_x_insta, 0.40).set_delay(0.08)

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

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

func _mudar_cena(caminho: String, limpar_hist: bool = false, forcar_fade: bool = false) -> void:
	var ts = get_node_or_null("/root/TransitionScreen")
	if ts and ts.has_method("change_scene"):
		ts.change_scene(caminho, limpar_hist, forcar_fade)
	else:
		get_tree().change_scene_to_file(caminho)

func _tocar_sfx(nome_som: String) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx(nome_som)

func _ready() -> void:
	# toca musica do menu
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_menu_music"):
		am.play_menu_music()
	
	if logo:
		_logo_base_y = logo.position.y
		_iniciar_animacao_logo()
	if bg:
		_bg_base_pos = bg.position
	
	# conecta os cliques dos botoes
	btn_ranking.pressed.connect(_on_btn_ranking_pressed)
	btn_clas.pressed.connect(_on_btn_clas_pressed)
	btn_config.pressed.connect(_on_btn_config_pressed)
	if btn_creditos:
		btn_creditos.pressed.connect(_on_btn_creditos_pressed)
	_configurar_card_instagram()
	
	# Se já jogou antes, exibe CONTINUAR e NOVO JOGO. Se for primeira vez, exibe NOVO JOGO.
	var ps = get_node_or_null("/root/PlayerStats")
	var ja_jogou = ps and ps.tem_progresso_salvo()
	if ja_jogou:
		btn_jogar.text = "CONTINUAR"
		btn_jogar.pressed.connect(_on_btn_continuar_pressed)
		
		var btn_novo = btn_jogar.duplicate()
		btn_novo.name = "BtnNovoJogo"
		btn_novo.text = "NOVO JOGO"
		btn_novo.custom_minimum_size = Vector2(0, 36)
		btn_novo.add_theme_font_size_override("font_size", 16)
		btn_novo.pressed.connect(_on_btn_novo_jogo_pressed)
		var vbox = $MarginContainer/VBoxButtons
		vbox.add_child(btn_novo)
		vbox.move_child(btn_novo, 1)
	else:
		btn_jogar.text = "NOVO JOGO"
		btn_jogar.pressed.connect(_on_btn_novo_jogo_pressed)

	var db = get_node_or_null("/root/DatabaseManager")
	if db and db.is_admin:
		var btn_admin = btn_jogar.duplicate()
		btn_admin.text = "PAINEL ADMIN"
		btn_admin.custom_minimum_size = Vector2(0, 36)
		btn_admin.add_theme_font_size_override("font_size", 16)
		btn_admin.pressed.connect(func(): _mudar_cena("res://scenes/ui/painel_admin.tscn"))
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
		_tocar_sfx("ui_5")
		_mudar_cena("res://scenes/ui/login.tscn")
	
	var _ao_clicar_perfil = func():
		var db_click = get_node_or_null("/root/DatabaseManager")
		if db_click == null or db_click.user_token == "":
			_abrir_modal_aviso_visitante(Callable())
		else:
			_ir_login.call()
	
	if db == null or db.user_token == "":
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
	var cm = get_node_or_null("/root/ClanManager")
	var rm = get_node_or_null("/root/RankingManager")
	if cm:
		cm.clan_list_updated.connect(_atualizar_leaderboard)
		cm.clan_updated.connect(_atualizar_perfil)
	if rm:
		rm.ranking_atualizado.connect(_atualizar_leaderboard)

func _exit_tree() -> void:
	var cm = get_node_or_null("/root/ClanManager")
	var rm = get_node_or_null("/root/RankingManager")
	if cm and cm.clan_list_updated.is_connected(_atualizar_leaderboard):
		cm.clan_list_updated.disconnect(_atualizar_leaderboard)
	if rm and rm.ranking_atualizado.is_connected(_atualizar_leaderboard):
		rm.ranking_atualizado.disconnect(_atualizar_leaderboard)
	if cm and cm.clan_updated.is_connected(_atualizar_perfil):
		cm.clan_updated.disconnect(_atualizar_perfil)

func _atualizar_perfil() -> void:
	var db = get_node_or_null("/root/DatabaseManager")
	if not is_inside_tree() or _lbl_nome == null or db == null or db.user_token == "":
		return
	var cla_texto = ""
	if not db.user_cla.is_empty() and db.user_cla != "Nenhum":
		cla_texto = " [" + db.user_cla.to_upper() + "]"
	_lbl_nome.text = db.user_nick.to_upper() + cla_texto
	_lbl_nome.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	
	if _btn_avatar != null:
		var tex_mago = load("res://assets/sprites/ui/ranking/icone_mago.png") as Texture2D
		if tex_mago:
			_btn_avatar.texture_normal = tex_mago
		_btn_avatar.modulate = Color(1.0, 1.0, 1.0)

func _on_btn_continuar_pressed() -> void:
	_tocar_sfx("ui_5")
	var db = get_node_or_null("/root/DatabaseManager")
	if db and db.user_token.is_empty() and not _aviso_visitante_visto:
		_abrir_modal_aviso_visitante(_executar_continuar)
		return
	_executar_continuar()

func _on_btn_novo_jogo_pressed() -> void:
	_tocar_sfx("ui_5")
	var ps = get_node_or_null("/root/PlayerStats")
	var ja_jogou = ps and ps.tem_progresso_salvo()
	if ja_jogou:
		_abrir_modal_confirmar_novo_jogo()
	else:
		var db = get_node_or_null("/root/DatabaseManager")
		if db and db.user_token.is_empty() and not _aviso_visitante_visto:
			_abrir_modal_aviso_visitante(_iniciar_novo_jogo)
			return
		_iniciar_novo_jogo()

func _abrir_modal_confirmar_novo_jogo() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	
	var bg_overlay = ColorRect.new()
	bg_overlay.color = Color(0, 0, 0, 0.78)
	bg_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg_overlay)
	
	var panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.15, 0.96)
	sb.border_color = Color(0.95, 0.65, 0.22, 0.95)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.shadow_color = Color(0, 0, 0, 0.85)
	sb.shadow_size = 20
	sb.content_margin_left = 26
	sb.content_margin_right = 26
	sb.content_margin_top = 22
	sb.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", sb)
	
	panel.custom_minimum_size = Vector2(460, 230)
	var vp_size = get_viewport_rect().size
	panel.position = (vp_size - panel.custom_minimum_size) * 0.5
	panel.pivot_offset = panel.custom_minimum_size * 0.5
	canvas.add_child(panel)
	
	# Animação suave de entrada
	panel.scale = Vector2(0.88, 0.88)
	panel.modulate.a = 0.0
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.22)
	tw.tween_property(panel, "modulate:a", 1.0, 0.18)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)
	
	var font_pixel = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	var sf = SystemFont.new()
	sf.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	sf.font_weight = 600
	
	var lbl_tit = Label.new()
	lbl_tit.text = "✦ INICIAR NOVO JOGO ✦"
	if font_pixel: lbl_tit.add_theme_font_override("font", font_pixel)
	lbl_tit.add_theme_font_size_override("font_size", 20)
	lbl_tit.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	lbl_tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_tit)
	
	var lbl_msg = Label.new()
	lbl_msg.text = "Você já possui uma jornada em andamento!\n\nAo iniciar um novo jogo, sua expedição anterior será abandonada e todo o progresso (salas, itens e chaves) será reiniciado do zero.\n\nDeseja continuar?"
	lbl_msg.add_theme_font_override("font", sf)
	lbl_msg.add_theme_font_size_override("font_size", 13)
	lbl_msg.add_theme_color_override("font_color", Color(0.88, 0.90, 0.96))
	lbl_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lbl_msg)
	
	var hbox_btns = HBoxContainer.new()
	hbox_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_btns.add_theme_constant_override("separation", 16)
	
	var btn_cancelar = Button.new()
	btn_cancelar.text = "CANCELAR"
	btn_cancelar.custom_minimum_size = Vector2(140, 38)
	btn_cancelar.add_theme_font_override("font", sf)
	btn_cancelar.add_theme_font_size_override("font_size", 13)
	
	var sb_canc = StyleBoxFlat.new()
	sb_canc.bg_color = Color(0.12, 0.14, 0.20, 0.85)
	sb_canc.border_color = Color(0.4, 0.45, 0.6, 0.6)
	sb_canc.set_border_width_all(1)
	sb_canc.set_corner_radius_all(6)
	btn_cancelar.add_theme_stylebox_override("normal", sb_canc)
	
	var sb_canc_hov = sb_canc.duplicate() as StyleBoxFlat
	sb_canc_hov.bg_color = Color(0.18, 0.22, 0.30, 1.0)
	sb_canc_hov.border_color = Color(0.6, 0.7, 0.9, 0.9)
	btn_cancelar.add_theme_stylebox_override("hover", sb_canc_hov)
	btn_cancelar.add_theme_stylebox_override("pressed", sb_canc_hov)
	
	btn_cancelar.pressed.connect(func():
		_tocar_sfx("ui-1")
		canvas.queue_free()
	)
	hbox_btns.add_child(btn_cancelar)
	
	var btn_confirmar = Button.new()
	btn_confirmar.text = "SIM, NOVO JOGO"
	btn_confirmar.custom_minimum_size = Vector2(170, 38)
	btn_confirmar.add_theme_font_override("font", sf)
	btn_confirmar.add_theme_font_size_override("font_size", 13)
	
	var sb_conf = StyleBoxFlat.new()
	sb_conf.bg_color = Color(0.25, 0.12, 0.10, 0.95)
	sb_conf.border_color = Color(0.95, 0.45, 0.35, 0.9)
	sb_conf.set_border_width_all(1)
	sb_conf.set_corner_radius_all(6)
	btn_confirmar.add_theme_stylebox_override("normal", sb_conf)
	
	var sb_conf_hov = sb_conf.duplicate() as StyleBoxFlat
	sb_conf_hov.bg_color = Color(0.38, 0.16, 0.12, 1.0)
	sb_conf_hov.border_color = Color(1.0, 0.65, 0.45, 1.0)
	btn_confirmar.add_theme_stylebox_override("hover", sb_conf_hov)
	btn_confirmar.add_theme_stylebox_override("pressed", sb_conf_hov)
	btn_confirmar.add_theme_color_override("font_color", Color(1.0, 0.9, 0.8))
	btn_confirmar.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	
	btn_confirmar.pressed.connect(func():
		_tocar_sfx("ui_5")
		canvas.queue_free()
		var db_conf = get_node_or_null("/root/DatabaseManager")
		if db_conf and db_conf.user_token.is_empty() and not _aviso_visitante_visto:
			_abrir_modal_aviso_visitante(_iniciar_novo_jogo)
		else:
			_iniciar_novo_jogo()
	)
	hbox_btns.add_child(btn_confirmar)
	
	vbox.add_child(hbox_btns)
	
	panel.reset_size()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

func _executar_continuar() -> void:
	# Se tiver jogo salvo com localizacao, continua de onde parou na sala!
	var ps = get_node_or_null("/root/PlayerStats")
	if ps and ps.tem_pos_salva and ps.cena_salva != "":
		print("[MainMenu] Continuando jogo na cena: %s na posicao (%.0f, %.0f)" % [ps.cena_salva, ps.pos_salva_x, ps.pos_salva_y])
		ps.restaurando_posicao_save = true
		ps.fade_spawn_player = true
		
		var dg = get_node_or_null("/root/DungeonGenerator")
		if dg:
			if ps.percurso_salas_salvo.size() > 0:
				dg.percurso_salas = ps.percurso_salas_salvo.duplicate()
				dg.indice_atual = ps.indice_sala_salvo
			for i in ps.inimigos_derrotados:
				if not (i in dg.inimigos_derrotados):
					dg.inimigos_derrotados.append(i)
			for p in ps.portas_destrancadas:
				if not (p in dg.portas_destrancadas):
					dg.portas_destrancadas.append(p)
			
		_mudar_cena(ps.cena_salva, false, true)
		return
		
	# Caso não tenha posição de sala específica (ex: estava no Hub ou sem sala ativa), vai pro Hub!
	_executar_voltar_ao_inicio()

func _executar_voltar_ao_inicio() -> void:
	print("[MainMenu] Retornando ao Início (Hub Geral) com progresso salvo mantido!")
	var ps = get_node_or_null("/root/PlayerStats")
	if ps:
		ps.resetar_vida()
		ps.limpar_posicao_salva()
		ps.fade_spawn_player = true
	var dg = get_node_or_null("/root/DungeonGenerator")
	if dg:
		dg.resetar_masmorra()
	_mudar_cena("res://scenes/Salas/Comum/Hub_Geral.tscn")

func _abrir_modal_aviso_visitante(acao_apos: Callable = Callable()) -> void:
	var modal_cena = preload("res://scenes/ui/ModalAvisoVisitante.tscn")
	if modal_cena:
		var modal = modal_cena.instantiate()
		add_child(modal)
		modal.continuar_como_visitante.connect(func():
			_aviso_visitante_visto = true
			if acao_apos.is_valid():
				acao_apos.call()
		)

func _iniciar_novo_jogo() -> void:
	print("[MainMenu] Iniciando Novo Jogo - resetando salvamento antigo!")
	var ps = get_node_or_null("/root/PlayerStats")
	if ps:
		ps.resetar_salvamento_completo()
		ps.fade_spawn_player = true
	var dg = get_node_or_null("/root/DungeonGenerator")
	if dg:
		dg.resetar_masmorra()
		dg.tocar_cutscene_inicial = true
	var qm = get_node_or_null("/root/QuizManager")
	if qm and qm.has_method("resetar_historico_perguntas"):
		qm.resetar_historico_perguntas()
		
	# troca de cena pro hub
	_mudar_cena("res://scenes/Salas/Comum/Hub_Geral.tscn")

func _on_btn_ranking_pressed() -> void:
	print("Botão RANKING pressionado - abrindo RankingLocal")
	_tocar_sfx("ui_5")
	_mudar_cena("res://scenes/ui/ranking_ui.tscn")

func _on_btn_clas_pressed() -> void:
	print("Botão CLÃS pressionado - abrindo TelaClas")
	_tocar_sfx("ui_5")
	_mudar_cena("res://scenes/ui/TelaClas.tscn")

func _on_btn_config_pressed() -> void:
	print("Botão CONFIGURAÇÕES pressionado")
	_tocar_sfx("ui_5")
	_mudar_cena("res://scenes/ui/configuracoes.tscn")

func _on_btn_creditos_pressed() -> void:
	_tocar_sfx("ui_5")
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
		_tocar_sfx("ui-1")
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn_instagram_node, "scale", Vector2(1.05, 1.05), 0.15)
	)
	
	btn_instagram_node.mouse_exited.connect(func():
		var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn_instagram_node, "scale", Vector2.ONE, 0.15)
	)

func _abrir_modal_instagram() -> void:
	_tocar_sfx("ui_5")
	var modal_cena = preload("res://scenes/ui/ModalInstagram.tscn")
	if modal_cena:
		var modal = modal_cena.instantiate()
		add_child(modal)

# leaderboard com filtro de periodo
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
	_tocar_sfx("ui-1")
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
	var rm = get_node_or_null("/root/RankingManager")
	var lista: Array = rm.get_ranking_por_periodo(_periodo_atual) if rm else []
	
	var nick_local = ""
	var db = get_node_or_null("/root/DatabaseManager")
	if db and not db.user_nick.is_empty():
		nick_local = db.user_nick
	elif rm:
		nick_local = rm.get_local_nick()

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
		_tocar_sfx("ui-1")
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

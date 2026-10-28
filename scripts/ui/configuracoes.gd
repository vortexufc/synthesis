extends Control

@onready var slider_music = find_child("HSliderMusic", true, false) as HSlider
@onready var slider_sfx = find_child("HSliderSfx", true, false) as HSlider
@onready var btn_deslogar = find_child("BtnDeslogar", true, false) as Button
@onready var toggle_joystick = find_child("CheckJoystick", true, false) as CheckButton
@onready var hbox_tipo_controle = find_child("HBoxTipoControle", true, false) as HBoxContainer
@onready var btn_modo_analogico = find_child("BtnModoAnalogico", true, false) as Button
@onready var btn_modo_dpad = find_child("BtnModoDpad", true, false) as Button
@onready var btn_voltar = find_child("BtnVoltar", true, false) as Button
@onready var btn_menu_principal = find_child("BtnMenuPrincipal", true, false) as Button
@onready var bg_texture = find_child("Background", true, false) as TextureRect

@onready var popup_confirmacao = find_child("PopupConfirmacao", true, false) as ColorRect
@onready var btn_confirmar_sair = find_child("BtnConfirmarSair", true, false) as Button
@onready var btn_cancelar_sair = find_child("BtnCancelarSair", true, false) as Button
@onready var lbl_mensagem_confirm = find_child("MensagemConfirm", true, false) as Label

var modo_in_game: bool = false
var _acao_confirmacao: String = "" # "menu_principal" ou "deslogar"

var lbl_nick_val: Label
var btn_alterar_nick: Button
var popup_alterar_nick: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_criar_linha_alterar_nick()
	
	if slider_music:
		slider_music.value_changed.connect(_on_music_value_changed)
	if slider_sfx:
		slider_sfx.value_changed.connect(_on_sfx_value_changed)
		
	if btn_deslogar:
		btn_deslogar.pressed.connect(_on_deslogar_pressed)
	if toggle_joystick:
		var mcm = get_node_or_null("/root/MobileControlsManager")
		if mcm:
			toggle_joystick.set_pressed_no_signal(mcm.joystick_habilitado)
			mcm.joystick_toggled.connect(func(ativo: bool):
				if toggle_joystick and is_instance_valid(toggle_joystick):
					toggle_joystick.set_pressed_no_signal(ativo)
				_atualizar_botoes_modo_controle()
			)
			if mcm.has_signal("tipo_controle_alterado"):
				mcm.tipo_controle_alterado.connect(func(_tipo: String):
					_atualizar_botoes_modo_controle()
					_configurar_estilo_controles()
				)
		toggle_joystick.toggled.connect(_on_joystick_toggled)
		
	if btn_modo_analogico:
		btn_modo_analogico.pressed.connect(_on_modo_analogico_pressed)
	if btn_modo_dpad:
		btn_modo_dpad.pressed.connect(_on_modo_dpad_pressed)
		
	if btn_voltar:
		btn_voltar.pressed.connect(_on_voltar_pressed)
	if btn_menu_principal:
		btn_menu_principal.pressed.connect(_on_menu_principal_pressed)
		
	if btn_confirmar_sair:
		btn_confirmar_sair.pressed.connect(_on_confirmar_sair_pressed)
	if btn_cancelar_sair:
		btn_cancelar_sair.pressed.connect(_on_cancelar_sair_pressed)
		
	_fechar_confirmacao()
	_atualizar_status_conta()
	_atualizar_sliders()
	_atualizar_switch_joystick()
	_atualizar_botoes_modo_controle()
	_configurar_estilo_controles()
	
	var mcm_init = get_node_or_null("/root/MobileControlsManager")
	if mcm_init and mcm_init.has_signal("plataforma_detectada"):
		mcm_init.plataforma_detectada.connect(func(_eh_mob: bool):
			_configurar_estilo_controles()
			_atualizar_switch_joystick()
			_atualizar_botoes_modo_controle()
		)
	
	visibility_changed.connect(func():
		if visible:
			_atualizar_status_conta()
			_atualizar_sliders()
			_atualizar_switch_joystick()
			_atualizar_botoes_modo_controle()
			_configurar_estilo_controles()
	)

func _configurar_estilo_controles() -> void:
	var mcm = get_node_or_null("/root/MobileControlsManager")
	var eh_mobile = mcm and mcm.has_method("is_mobile") and mcm.is_mobile()
	var modo_dpad = (mcm and "tipo_controle" in mcm and mcm.tipo_controle == "dpad") if eh_mobile else false
	
	var lbl_controles = find_child("LabelControles", true, false) as Label
	if lbl_controles:
		lbl_controles.text = "CONTROLES (MOBILE / TOUCH)" if eh_mobile else "CONTROLES (TECLADO)"
		lbl_controles.add_theme_font_size_override("font_size", 14)
	
	var font_desc = SystemFont.new()
	font_desc.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_desc.font_weight = 500
	
	var mapa_desc = {
		"LblDescMov": ("Mover o Mago (D-Pad)" if modo_dpad else "Mover o Mago (Arrastar)") if eh_mobile else "Movimentar o Mago",
		"LblDescDash": "Dash (Esquiva / Avanço)",
		"LblDescInteragir": "Interagir / Coletar Itens",
		"LblDescGrimorio": "Inventário & Grimório" if eh_mobile else "Grimório de Fórmulas / Inventário",
		"LblDescPause": "Pausar Jogo (Menu)" if eh_mobile else "Pausar Jogo / Fechar Menus"
	}
	
	for node_name in mapa_desc.keys():
		var lbl = find_child(node_name, true, false) as Label
		if lbl:
			lbl.text = mapa_desc[node_name]
			lbl.add_theme_font_override("font", font_desc)
			lbl.add_theme_font_size_override("font_size", 14)
			lbl.add_theme_color_override("font_color", Color(0.9, 0.93, 0.98, 0.95))
			
	var font_keys = SystemFont.new()
	font_keys.font_names = PackedStringArray(["Consolas", "Courier New", "Segoe UI", "sans-serif"])
	font_keys.font_weight = 700
	
	var mapa_keys = {
		"LblKeyMov": ("[Botões Direcionais]" if modo_dpad else "[Analógico Virtual]") if eh_mobile else "[W, A, S, D] / [Setas]",
		"LblKeyDash": "[Botão DASH]" if eh_mobile else "[ESPAÇO]",
		"LblKeyInteragir": "[Botão INTERAGIR]" if eh_mobile else "[F]",
		"LblKeyGrimorio": "[Botão MOCHILA]" if eh_mobile else "[E]",
		"LblKeyPause": "[Botão ⏸ (Topo)]" if eh_mobile else "[ESC]"
	}
	
	for node_name in mapa_keys.keys():
		var lbl = find_child(node_name, true, false) as Label
		if lbl:
			lbl.text = mapa_keys[node_name]
			lbl.add_theme_font_override("font", font_keys)
			lbl.add_theme_font_size_override("font_size", 14)
			lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.35, 1)) # Amarelo/Dourado arcano

func configurar_modo_in_game(ativo: bool) -> void:
	modo_in_game = ativo
	_fechar_confirmacao()
	
	if btn_voltar:
		btn_voltar.text = "VOLTAR AO JOGO" if ativo else "VOLTAR"
	if btn_menu_principal:
		btn_menu_principal.visible = ativo
		
	if bg_texture:
		# Em modo in-game, esconde o fundo opaco do menu para desfocar a sala pausada do jogo
		bg_texture.visible = not ativo
		
	_atualizar_status_conta()
	_atualizar_sliders()
	_atualizar_switch_joystick()
	_atualizar_botoes_modo_controle()
	_configurar_estilo_controles()

func _atualizar_switch_joystick() -> void:
	if toggle_joystick:
		var mcm = get_node_or_null("/root/MobileControlsManager")
		if mcm:
			toggle_joystick.set_pressed_no_signal(mcm.joystick_habilitado)

func _on_modo_analogico_pressed() -> void:
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui-1")
	var mcm = get_node_or_null("/root/MobileControlsManager")
	if mcm and mcm.has_method("set_tipo_controle"):
		mcm.set_tipo_controle("analogico")
	_atualizar_botoes_modo_controle()
	_configurar_estilo_controles()

func _on_modo_dpad_pressed() -> void:
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui-1")
	var mcm = get_node_or_null("/root/MobileControlsManager")
	if mcm and mcm.has_method("set_tipo_controle"):
		mcm.set_tipo_controle("dpad")
	_atualizar_botoes_modo_controle()
	_configurar_estilo_controles()

func _atualizar_botoes_modo_controle() -> void:
	var mcm = get_node_or_null("/root/MobileControlsManager")
	var tipo = mcm.tipo_controle if mcm and "tipo_controle" in mcm else "analogico"
	var ativo = mcm.joystick_habilitado if mcm else false
	
	if hbox_tipo_controle:
		hbox_tipo_controle.modulate = Color.WHITE if ativo else Color(0.6, 0.6, 0.6, 0.45)
		
	if btn_modo_analogico:
		btn_modo_analogico.disabled = not ativo
		_aplicar_estilo_modo(btn_modo_analogico, tipo == "analogico")
	if btn_modo_dpad:
		btn_modo_dpad.disabled = not ativo
		_aplicar_estilo_modo(btn_modo_dpad, tipo == "dpad")

func _aplicar_estilo_modo(btn: Button, selecionado: bool) -> void:
	if btn == null or not is_instance_valid(btn):
		return
	if selecionado:
		btn.add_theme_color_override("font_color", Color(1, 0.92, 0.6, 1))
		var sb = StyleBoxFlat.new()
		sb.content_margin_left = 12.0
		sb.content_margin_top = 8.0
		sb.content_margin_right = 12.0
		sb.content_margin_bottom = 8.0
		sb.bg_color = Color(0.18, 0.42, 0.78, 0.95)
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = Color(0.4, 0.85, 1, 1)
		sb.corner_radius_top_left = 4
		sb.corner_radius_top_right = 4
		sb.corner_radius_bottom_right = 4
		sb.corner_radius_bottom_left = 4
		sb.shadow_color = Color(0.1, 0.5, 0.9, 0.45)
		sb.shadow_size = 6
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)
		btn.add_theme_stylebox_override("focus", sb)
	else:
		btn.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9, 0.7))
		var sb = StyleBoxFlat.new()
		sb.content_margin_left = 12.0
		sb.content_margin_top = 8.0
		sb.content_margin_right = 12.0
		sb.content_margin_bottom = 8.0
		sb.bg_color = Color(0.08, 0.12, 0.22, 0.7)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.2, 0.35, 0.55, 0.5)
		sb.corner_radius_top_left = 4
		sb.corner_radius_top_right = 4
		sb.corner_radius_bottom_right = 4
		sb.corner_radius_bottom_left = 4
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)
		btn.add_theme_stylebox_override("focus", sb)

func _atualizar_status_conta() -> void:
	if btn_deslogar == null:
		return
		
	var db = get_node_or_null("/root/DatabaseManager")
	var token_vazio = true
	if db and "user_token" in db:
		token_vazio = db.user_token.is_empty()
		
	if token_vazio:
		btn_deslogar.disabled = true
		btn_deslogar.text = "NÃO LOGADO"
		btn_deslogar.modulate = Color(0.5, 0.5, 0.5, 1)
	else:
		btn_deslogar.disabled = false
		btn_deslogar.text = "DESCONECTAR"
		btn_deslogar.modulate = Color(1.0, 0.3, 0.3)
		
	if lbl_nick_val:
		var n = ""
		if db and not db.user_nick.is_empty():
			n = db.user_nick
		else:
			var rm = get_node_or_null("/root/RankingManager")
			if rm: n = rm.get_local_nick()
		lbl_nick_val.text = n if not n.is_empty() else "Mago Desconhecido"

func _atualizar_sliders() -> void:
	var bus_m = AudioServer.get_bus_index("Music")
	if bus_m >= 0 and slider_music:
		var db_m = AudioServer.get_bus_volume_db(bus_m)
		var vol_m = db_to_linear(db_m) if db_m > -79.0 else 0.0
		slider_music.set_value_no_signal(clampf(vol_m, 0.0, 1.0))
		
	var bus_s = AudioServer.get_bus_index("SFX")
	if bus_s >= 0 and slider_sfx:
		var db_s = AudioServer.get_bus_volume_db(bus_s)
		var vol_s = db_to_linear(db_s) if db_s > -79.0 else 0.0
		slider_sfx.set_value_no_signal(clampf(vol_s, 0.0, 1.0))

func _on_music_value_changed(value: float) -> void:
	print("Volume da MÚSICA alterado para: ", value)
	var bus_idx = AudioServer.get_bus_index("Music")	
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, _slider_to_db(value))

func _on_sfx_value_changed(value: float) -> void:
	print("Volume dos EFEITOS SONOROS alterado para: ", value)
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, _slider_to_db(value))

func _on_joystick_toggled(button_pressed: bool) -> void:
	var mcm = get_node_or_null("/root/MobileControlsManager")
	if mcm:
		mcm.set_joystick_habilitado(button_pressed, true)
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui-1")
	_atualizar_botoes_modo_controle()


func _on_voltar_pressed() -> void:
	print("Botão VOLTAR pressionado")
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui_5")
	
	if modo_in_game:
		if get_node_or_null("/root/MenuPausaManager"):
			MenuPausaManager.fechar_menu()
		else:
			visible = false
			get_tree().paused = false
	else:
		TransitionScreen.change_scene("res://scenes/ui/main_menu.tscn")

func _on_menu_principal_pressed() -> void:
	if modo_in_game:
		# Exibe o popup de confirmação para evitar perdas acidentais de progresso
		_abrir_confirmacao(
			"menu_principal",
			"Tem certeza que deseja sair para o Menu Inicial?\nO progresso não salvo nesta sala será perdido."
		)
	else:
		TransitionScreen.change_scene("res://scenes/ui/main_menu.tscn")

func _on_deslogar_pressed() -> void:
	if modo_in_game:
		# No jogo, confirma antes de deslogar
		_abrir_confirmacao(
			"deslogar",
			"Deseja realmente desconectar da sua conta e retornar ao Menu Inicial?"
		)
	else:
		_executar_deslogar()

func _abrir_confirmacao(acao: String, mensagem: String) -> void:
	_acao_confirmacao = acao
	if lbl_mensagem_confirm:
		lbl_mensagem_confirm.text = mensagem
	if popup_confirmacao:
		popup_confirmacao.visible = true
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui_5")

func _fechar_confirmacao() -> void:
	_acao_confirmacao = ""
	if popup_confirmacao:
		popup_confirmacao.visible = false

func _on_cancelar_sair_pressed() -> void:
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui_5")
	_fechar_confirmacao()

func _on_confirmar_sair_pressed() -> void:
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui_4")
		
	if _acao_confirmacao == "deslogar":
		_executar_deslogar()
	else: # "menu_principal"
		if get_node_or_null("/root/PlayerStats"):
			PlayerStats.salvar()
			
		if get_node_or_null("/root/MenuPausaManager"):
			MenuPausaManager.fechar_menu_sem_som()
		else:
			get_tree().paused = false
			
		TransitionScreen.change_scene("res://scenes/ui/main_menu.tscn")

func _executar_deslogar() -> void:
	print("Deslogando usuário...")
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui_4")
	
	var db = get_node_or_null("/root/DatabaseManager")
	if db:
		db.user_token = ""
		db.user_nick = ""
		db.user_cla = "Nenhum"
	
	if modo_in_game:
		if get_node_or_null("/root/MenuPausaManager"):
			MenuPausaManager.fechar_menu_sem_som()
		else:
			get_tree().paused = false
			
	var ts = get_node_or_null("/root/TransitionScreen")
	if ts:
		ts.change_scene("res://scenes/ui/main_menu.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			# Se o modal de confirmação estiver aberto, ESC apenas fecha o modal sem sair do jogo
			if popup_confirmacao and popup_confirmacao.visible:
				_fechar_confirmacao()
				if get_node_or_null("/root/AudioManager"):
					AudioManager.play_sfx("ui_5")
			else:
				_on_voltar_pressed()

func _slider_to_db(value: float) -> float:
	if value <= 0.01:
		return -80.0
	return linear_to_db(value)

func _criar_linha_alterar_nick() -> void:
	var vbox = find_child("VBoxContainer", true, false) as VBoxContainer
	var hbox_conta = find_child("HBoxConta", true, false) as HBoxContainer
	if not vbox or not hbox_conta:
		return
		
	var hbox_nick = HBoxContainer.new()
	hbox_nick.name = "HBoxNick"
	hbox_nick.add_theme_constant_override("separation", 14)
	
	var lbl_tit = Label.new()
	lbl_tit.custom_minimum_size = Vector2(180, 0)
	lbl_tit.text = "MAGO"
	var font_press = load("res://assets/fonts/PressStart2P-Regular.ttf") as Font
	if font_press:
		lbl_tit.add_theme_font_override("font", font_press)
		lbl_tit.add_theme_font_size_override("font_size", 14)
	lbl_tit.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox_nick.add_child(lbl_tit)
	
	lbl_nick_val = Label.new()
	lbl_nick_val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_nick_val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_nick_val.add_theme_color_override("font_color", Color(0.95, 0.78, 0.35))
	var font_pixel = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	if font_pixel:
		lbl_nick_val.add_theme_font_override("font", font_pixel)
		lbl_nick_val.add_theme_font_size_override("font_size", 18)
	hbox_nick.add_child(lbl_nick_val)
	
	btn_alterar_nick = Button.new()
	btn_alterar_nick.text = "ALTERAR"
	btn_alterar_nick.custom_minimum_size = Vector2(120, 36)
	var sb_btn = StyleBoxFlat.new()
	sb_btn.bg_color = Color(0.18, 0.55, 0.85, 0.95)
	sb_btn.set_corner_radius_all(6)
	btn_alterar_nick.add_theme_stylebox_override("normal", sb_btn)
	btn_alterar_nick.add_theme_color_override("font_color", Color.WHITE)
	btn_alterar_nick.pressed.connect(_abrir_modal_alterar_nick)
	hbox_nick.add_child(btn_alterar_nick)
	
	vbox.add_child(hbox_nick)
	var idx = hbox_conta.get_index()
	vbox.move_child(hbox_nick, idx)

func _abrir_modal_alterar_nick() -> void:
	if popup_alterar_nick != null and is_instance_valid(popup_alterar_nick):
		popup_alterar_nick.queue_free()
		
	popup_alterar_nick = ColorRect.new()
	popup_alterar_nick.color = Color(0, 0, 0, 0.85)
	popup_alterar_nick.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(popup_alterar_nick)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 230)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.18, 0.98)
	sb.border_color = Color(0.95, 0.65, 0.22, 0.95)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 20
	sb.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", sb)
	popup_alterar_nick.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)
	
	var lbl_tit = Label.new()
	lbl_tit.text = "✦ ALTERAR NICK DO MAGO ✦"
	lbl_tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_tit.add_theme_color_override("font_color", Color(0.95, 0.78, 0.35))
	lbl_tit.add_theme_font_size_override("font_size", 14)
	vbox.add_child(lbl_tit)
	
	var lbl_desc = Label.new()
	lbl_desc.text = "Escolha seu novo nome (3 a 16 caracteres):"
	lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_desc.add_theme_color_override("font_color", Color(0.85, 0.90, 0.96))
	lbl_desc.add_theme_font_size_override("font_size", 12)
	vbox.add_child(lbl_desc)
	
	var input_nick = LineEdit.new()
	input_nick.max_length = 16
	var n_atual = ""
	var db = get_node_or_null("/root/DatabaseManager")
	if db and not db.user_nick.is_empty(): n_atual = db.user_nick
	else:
		var rm = get_node_or_null("/root/RankingManager")
		if rm: n_atual = rm.get_local_nick()
	input_nick.text = n_atual
	input_nick.placeholder_text = "Novo nome de mago..."
	input_nick.custom_minimum_size = Vector2(300, 36)
	vbox.add_child(input_nick)
	
	var lbl_erro = Label.new()
	lbl_erro.text = ""
	lbl_erro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_erro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_erro.add_theme_color_override("font_color", Color(0.95, 0.35, 0.35))
	lbl_erro.add_theme_font_size_override("font_size", 11)
	vbox.add_child(lbl_erro)
	
	var hbox_btns = HBoxContainer.new()
	hbox_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_btns.add_theme_constant_override("separation", 14)
	vbox.add_child(hbox_btns)
	
	var btn_canc = Button.new()
	btn_canc.text = "Cancelar"
	btn_canc.custom_minimum_size = Vector2(100, 34)
	btn_canc.pressed.connect(func(): popup_alterar_nick.queue_free())
	hbox_btns.add_child(btn_canc)
	
	var btn_salvar = Button.new()
	btn_salvar.text = "Salvar Nome"
	btn_salvar.custom_minimum_size = Vector2(130, 34)
	var sb_salvar = StyleBoxFlat.new()
	sb_salvar.bg_color = Color(0.15, 0.65, 0.35)
	sb_salvar.set_corner_radius_all(6)
	btn_salvar.add_theme_stylebox_override("normal", sb_salvar)
	btn_salvar.add_theme_color_override("font_color", Color.WHITE)
	
	btn_salvar.pressed.connect(func():
		var novo_n = input_nick.text.strip_edges()
		btn_salvar.disabled = true
		btn_salvar.text = "Salvando..."
		var res = await DatabaseManager.atualizar_nick_usuario_async(novo_n)
		if not res["valido"]:
			lbl_erro.text = res["erro"]
			btn_salvar.disabled = false
			btn_salvar.text = "Salvar Nome"
			return
		
		_atualizar_status_conta()
		popup_alterar_nick.queue_free()
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("ui-1")
	)
	input_nick.text_submitted.connect(func(_t): btn_salvar.emit_signal("pressed"))
	hbox_btns.add_child(btn_salvar)

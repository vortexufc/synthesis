extends Control

@onready var slider_music = find_child("HSliderMusic", true, false) as HSlider
@onready var slider_sfx = find_child("HSliderSfx", true, false) as HSlider
@onready var btn_deslogar = find_child("BtnDeslogar", true, false) as Button
@onready var toggle_joystick = find_child("CheckJoystick", true, false) as CheckButton
@onready var btn_voltar = find_child("BtnVoltar", true, false) as Button
@onready var btn_menu_principal = find_child("BtnMenuPrincipal", true, false) as Button
@onready var bg_texture = find_child("Background", true, false) as TextureRect

@onready var popup_confirmacao = find_child("PopupConfirmacao", true, false) as ColorRect
@onready var btn_confirmar_sair = find_child("BtnConfirmarSair", true, false) as Button
@onready var btn_cancelar_sair = find_child("BtnCancelarSair", true, false) as Button
@onready var lbl_mensagem_confirm = find_child("MensagemConfirm", true, false) as Label

var modo_in_game: bool = false
var _acao_confirmacao: String = "" # "menu_principal" ou "deslogar"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if slider_music:
		slider_music.value_changed.connect(_on_music_value_changed)
	if slider_sfx:
		slider_sfx.value_changed.connect(_on_sfx_value_changed)
		
	if btn_deslogar:
		btn_deslogar.pressed.connect(_on_deslogar_pressed)
	if toggle_joystick:
		toggle_joystick.toggled.connect(_on_joystick_toggled)
		
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

func _atualizar_status_conta() -> void:
	if btn_deslogar == null:
		return
		
	if DatabaseManager.user_token.is_empty():
		btn_deslogar.disabled = true
		btn_deslogar.text = "NÃO LOGADO"
		btn_deslogar.modulate = Color(0.5, 0.5, 0.5, 1)
	else:
		btn_deslogar.disabled = false
		btn_deslogar.text = "DESCONECTAR"
		btn_deslogar.modulate = Color(1.0, 0.3, 0.3)

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
	print("Joystick Virtual alterado para: ", "LIGADO" if button_pressed else "DESLIGADO")
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui-1")

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
	
	DatabaseManager.user_token = ""
	DatabaseManager.user_nick = ""
	DatabaseManager.user_cla = "Nenhum"
	
	if modo_in_game:
		if get_node_or_null("/root/MenuPausaManager"):
			MenuPausaManager.fechar_menu_sem_som()
		else:
			get_tree().paused = false
			
	TransitionScreen.change_scene("res://scenes/ui/main_menu.tscn")

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

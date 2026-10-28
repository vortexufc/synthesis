extends Control

@onready var email_input: LineEdit = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxEmail/EmailInput
@onready var password_input: LineEdit = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxPassword/HBoxPassword/PasswordInput
@onready var btn_show_password: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxPassword/HBoxPassword/BtnShowPassword
@onready var btn_login: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxButtons/BtnLogin
@onready var btn_back: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxButtons/BtnBack
@onready var link_register: LinkButton = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LinkRegister
@onready var link_esqueci_senha: LinkButton = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LinkEsqueciSenha

func _ready() -> void:
	btn_login.pressed.connect(_on_btn_login_pressed)
	btn_back.pressed.connect(_on_btn_back_pressed)
	link_register.pressed.connect(_on_link_register_pressed)
	link_esqueci_senha.pressed.connect(_on_esqueci_senha_pressed)
	btn_show_password.toggled.connect(_on_btn_show_password_toggled)
	
	email_input.text_submitted.connect(func(_t): _on_btn_login_pressed())
	password_input.text_submitted.connect(func(_t): _on_btn_login_pressed())
	
	# Escutando as respostas do banco
	DatabaseManager.auth_sucesso.connect(_on_auth_sucesso)
	DatabaseManager.auth_erro.connect(_on_auth_erro)
	DatabaseManager.reset_senha_enviado.connect(_on_reset_senha_enviado)

func _exit_tree() -> void:
	if DatabaseManager.auth_sucesso.is_connected(_on_auth_sucesso):
		DatabaseManager.auth_sucesso.disconnect(_on_auth_sucesso)
	if DatabaseManager.auth_erro.is_connected(_on_auth_erro):
		DatabaseManager.auth_erro.disconnect(_on_auth_erro)
	if DatabaseManager.reset_senha_enviado.is_connected(_on_reset_senha_enviado):
		DatabaseManager.reset_senha_enviado.disconnect(_on_reset_senha_enviado)

func _on_btn_show_password_toggled(button_pressed: bool) -> void:
	password_input.secret = !button_pressed
	
	if button_pressed:
		btn_show_password.text = " - "
	else:
		btn_show_password.text = " O "

func _on_btn_login_pressed() -> void:
	var tempo_bloqueio = DatabaseManager.tempo_restante_bloqueio_login()
	if tempo_bloqueio > 0:
		_show_error_popup("Muitas tentativas incorretas!\nAcesso temporariamente bloqueado por mais %d segundos." % tempo_bloqueio)
		return

	var email := email_input.text.strip_edges()
	var password := password_input.text.strip_edges()
	
	if email.is_empty() or password.is_empty():
		_show_error_popup("Preencha todos os campos!")
		return
		
	print("Tentando fazer login para: ", email)
	
	btn_login.disabled = true
	btn_login.text = "Entrando..."
	
	# Timeout de segurança de 8 segundos para evitar travamento da interface
	get_tree().create_timer(8.0).timeout.connect(func():
		if is_inside_tree() and btn_login and btn_login.disabled:
			btn_login.disabled = false
			btn_login.text = "Entrar"
			_show_error_popup("O servidor demorou para responder. Verifique sua conexão e tente novamente.")
	)
	
	# Chama o banco!
	DatabaseManager.fazer_login(email, password)

func _on_auth_sucesso(token: String) -> void:
	print("usuario logou com sucesso!")
	print("Logado com sucesso! Token Recebido:\n", token)
	btn_login.disabled = false
	btn_login.text = "Entrar"
	# Ir para o menu principal
	if TransitionScreen:
		TransitionScreen.change_scene("res://scenes/ui/main_menu.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_auth_erro(mensagem: String) -> void:
	print("Erro ao fazer login: ", mensagem)
	btn_login.disabled = false
	btn_login.text = "Entrar"
	var msg = mensagem
	var msg_lower = mensagem.to_lower()
	if "bloqueado por" in msg_lower or "tentativas restantes" in msg_lower:
		msg = mensagem
	elif "invalid login credentials" in msg_lower:
		msg = "E-mail ou senha incorretos!\nVerifique as credenciais digitadas e tente novamente."
	elif "email not confirmed" in msg_lower:
		msg = "E-mail ainda não confirmado!\nVerifique sua caixa de entrada para ativar a conta."
	elif "falha de conexão" in msg_lower or "cant_connect" in msg_lower:
		msg = "Não foi possível conectar ao servidor.\nVerifique sua conexão com a internet."
	_show_error_popup(msg)

var popup_recup_senha: Control

func _on_reset_senha_enviado() -> void:
	if popup_recup_senha and is_instance_valid(popup_recup_senha):
		popup_recup_senha.queue_free()
	_show_info_popup("E-mail de Recuperação Enviado!", "Se o e-mail informado estiver cadastrado, você receberá em instantes um link seguro para redefinir sua senha.\n\n(Verifique também sua caixa de Spam ou Lixo Eletrônico).")

# ---- FIM DOS SINAIS DE AUTH ----

func _on_esqueci_senha_pressed() -> void:
	_abrir_modal_recuperar_senha()

func _abrir_modal_recuperar_senha() -> void:
	if popup_recup_senha and is_instance_valid(popup_recup_senha):
		popup_recup_senha.queue_free()
		
	popup_recup_senha = ColorRect.new()
	popup_recup_senha.color = Color(0, 0, 0, 0.82)
	popup_recup_senha.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(popup_recup_senha)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 220)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.18, 0.98)
	sb.border_color = Color(0.20, 0.65, 0.90, 0.95)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 20
	sb.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", sb)
	popup_recup_senha.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)
	
	var lbl_tit = Label.new()
	lbl_tit.text = "✦ RECUPERAÇÃO DE SENHA ✦"
	lbl_tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_tit.add_theme_color_override("font_color", Color(0.20, 0.75, 0.95))
	lbl_tit.add_theme_font_size_override("font_size", 14)
	vbox.add_child(lbl_tit)
	
	var lbl_desc = Label.new()
	lbl_desc.text = "Digite o e-mail da sua conta para enviarmos o link de recuperação de senha:"
	lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_desc.add_theme_color_override("font_color", Color(0.85, 0.90, 0.96))
	lbl_desc.add_theme_font_size_override("font_size", 12)
	vbox.add_child(lbl_desc)
	
	var input_recup = LineEdit.new()
	input_recup.placeholder_text = "seu_email@exemplo.com"
	input_recup.text = email_input.text.strip_edges()
	input_recup.custom_minimum_size = Vector2(340, 36)
	vbox.add_child(input_recup)
	
	var lbl_feedback = Label.new()
	lbl_feedback.text = ""
	lbl_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_feedback.add_theme_color_override("font_color", Color(0.95, 0.35, 0.35))
	lbl_feedback.add_theme_font_size_override("font_size", 11)
	vbox.add_child(lbl_feedback)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 14)
	vbox.add_child(hbox)
	
	var btn_canc = Button.new()
	btn_canc.text = "Cancelar"
	btn_canc.custom_minimum_size = Vector2(100, 34)
	btn_canc.pressed.connect(func(): popup_recup_senha.queue_free())
	hbox.add_child(btn_canc)
	
	var btn_env = Button.new()
	btn_env.text = "Enviar E-mail"
	btn_env.custom_minimum_size = Vector2(140, 34)
	var sb_btn = StyleBoxFlat.new()
	sb_btn.bg_color = Color(0.18, 0.55, 0.85)
	sb_btn.set_corner_radius_all(6)
	btn_env.add_theme_stylebox_override("normal", sb_btn)
	btn_env.add_theme_color_override("font_color", Color.WHITE)
	
	# Rotina de atualização do cooldown no botão
	var _atualizar_cooldown_btn = func():
		if not is_instance_valid(btn_env): return
		var rest = DatabaseManager.tempo_restante_recuperacao()
		if rest > 0:
			btn_env.disabled = true
			btn_env.text = "Aguarde (%ds)" % rest
		else:
			btn_env.disabled = false
			btn_env.text = "Enviar E-mail"
	
	_atualizar_cooldown_btn.call()
	
	var timer_cooldown = Timer.new()
	timer_cooldown.wait_time = 1.0
	timer_cooldown.autostart = true
	timer_cooldown.timeout.connect(_atualizar_cooldown_btn)
	popup_recup_senha.add_child(timer_cooldown)
	
	btn_env.pressed.connect(func():
		var rest_agora = DatabaseManager.tempo_restante_recuperacao()
		if rest_agora > 0:
			lbl_feedback.text = "Aguarde %d segundos antes de solicitar novamente!" % rest_agora
			return
		var em = input_recup.text.strip_edges()
		if em.is_empty() or not ("@" in em and "." in em):
			lbl_feedback.text = "Digite um e-mail válido!"
			return
		lbl_feedback.text = ""
		btn_env.disabled = true
		btn_env.text = "Enviando..."
		DatabaseManager.recuperar_senha(em)
	)
	input_recup.text_submitted.connect(func(_t): btn_env.emit_signal("pressed"))
	hbox.add_child(btn_env)

func _on_btn_back_pressed() -> void:
	print("Voltar pressionado. Mudando de cena...")
	TransitionScreen.change_scene("res://scenes/ui/main_menu.tscn")

func _on_link_register_pressed() -> void:
	print("Ir para registro. Mudando de cena...")
	TransitionScreen.change_scene("res://scenes/ui/cadastro.tscn")

func _show_error_popup(mensagem: String) -> void:
	var dialog = AcceptDialog.new()
	dialog.dialog_text = mensagem
	dialog.title = "Atenção"
	add_child(dialog)
	dialog.popup_centered()

func _show_info_popup(titulo: String, mensagem: String) -> void:
	var dialog = AcceptDialog.new()
	dialog.title = titulo
	dialog.dialog_text = mensagem
	add_child(dialog)
	dialog.popup_centered()

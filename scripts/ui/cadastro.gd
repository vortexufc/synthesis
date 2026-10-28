extends Control

@onready var name_input: LineEdit = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxName/NameInput
@onready var email_input: LineEdit = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxEmail/EmailInput
@onready var password_input: LineEdit = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxPassword/HBoxPassword/PasswordInput
@onready var btn_show_password: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxPassword/HBoxPassword/BtnShowPassword
@onready var btn_create: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxButtons/BtnCreate
@onready var btn_back: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxButtons/BtnBack
@onready var link_login: LinkButton = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LinkLogin

func _ready() -> void:
	btn_create.pressed.connect(_on_btn_create_pressed)
	btn_back.pressed.connect(_on_btn_back_pressed)
	link_login.pressed.connect(_on_link_login_pressed)
	btn_show_password.toggled.connect(_on_btn_show_password_toggled)
	
	# Escutando as respostas do banco
	DatabaseManager.auth_sucesso.connect(_on_auth_sucesso)
	DatabaseManager.auth_erro.connect(_on_auth_erro)

func _on_btn_show_password_toggled(button_pressed: bool) -> void:
	password_input.secret = !button_pressed
	
	if button_pressed:
		# Efeito do botao show_password
		AudioManager.play_sfx("ui-1")
		
		btn_show_password.text = " - "
	else:
		# Efeito do botao show_password
		AudioManager.play_sfx("ui-1")
		
		btn_show_password.text = " O "

func _on_btn_create_pressed() -> void:
	var player_name := name_input.text.strip_edges()
	var email := email_input.text.strip_edges()
	var password := password_input.text.strip_edges()
	
	if player_name.is_empty() or email.is_empty() or password.is_empty():
		_show_error_popup("Preencha todos os campos!")
		return
		
	var validacao = DatabaseManager.validar_nick(player_name)
	if not validacao["valido"]:
		_show_error_popup(validacao["erro"])
		return
		
	print("Tentando criar conta para: ", player_name, " / ", email)
	
	btn_create.disabled = true
	# Chama o banco!
	DatabaseManager.cadastrar_usuario(email, password, player_name)

func _on_auth_sucesso(token: String) -> void:
	print("Conta criada com sucesso!")
	
	# cria o painel verde de confirmacao
	var panel = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.7, 0.3, 0.95) # Verde
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(380, 80)
	
	var label = Label.new()
	label.text = "CONTA CRIADA COM SUCESSO!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT) # centraliza total no panel
	
	var font = load("res://assets/fonts/PressStart2P-Regular.ttf")
	if font:
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", 11)
		
	panel.add_child(label)
	
	# Coloca o painel bem no centro da tela principal e adiciona na cena
	panel.set_anchors_preset(Control.PRESET_CENTER)
	add_child(panel)
	
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 2.0)
	
	await get_tree().create_timer(1.8).timeout
	TransitionScreen.change_scene("res://scenes/ui/login.tscn")

func _on_auth_erro(mensagem: String) -> void:
	print("Erro ao criar conta: ", mensagem)
	btn_create.disabled = false
	var msg = mensagem
	var msg_lower = mensagem.to_lower()
	if "already registered" in msg_lower or "user already exists" in msg_lower:
		msg = "Este e-mail já está cadastrado!\nTente fazer login."
	elif "password should be at least" in msg_lower:
		msg = "A senha é muito curta!\nDigite uma senha com pelo menos 6 caracteres."
	_show_error_popup(msg)

func _on_btn_back_pressed() -> void:
	print("Voltar pressionado. Mudando de cena...")
	TransitionScreen.change_scene("res://scenes/ui/login.tscn")

func _on_link_login_pressed() -> void:
	print("Ir para login. Mudando de cena...")
	TransitionScreen.change_scene("res://scenes/ui/login.tscn")

func _show_error_popup(mensagem: String) -> void:
	var dialog = AcceptDialog.new()
	dialog.dialog_text = mensagem
	dialog.title = "Atenção"
	add_child(dialog)
	dialog.popup_centered()

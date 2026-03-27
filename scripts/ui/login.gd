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
	
	# Escutando as respostas do banco
	DatabaseManager.auth_sucesso.connect(_on_auth_sucesso)
	DatabaseManager.auth_erro.connect(_on_auth_erro)
	DatabaseManager.reset_senha_enviado.connect(_on_reset_senha_enviado)

func _on_btn_show_password_toggled(button_pressed: bool) -> void:
	password_input.secret = !button_pressed
	
	if button_pressed:
		btn_show_password.text = " - "
	else:
		btn_show_password.text = " O "

func _on_btn_login_pressed() -> void:
	var email := email_input.text.strip_edges()
	var password := password_input.text
	
	if email.is_empty() or password.is_empty():
		_show_error_popup("Preencha todos os campos!")
		return
		
	print("Tentando fazer login para: ", email)
	
	btn_login.disabled = true
	# Chama o banco!
	DatabaseManager.fazer_login(email, password)

func _on_auth_sucesso(token: String) -> void:
	print("Logado com sucesso! Token Recebido: ", token)
	# salvar o token em alguma variavel pra lembrar depois se quiser
	# e vai pro jogo
	# get_tree().change_scene_to_file("res://scenes/levels/andar_1.tscn")

func _on_auth_erro(mensagem: String) -> void:
	print("Erro ao fazer login: ", mensagem)
	btn_login.disabled = false

func _on_reset_senha_enviado() -> void:
	print("Se o email existir, um link de recuperacao foi enviado!")

# ---- FIM DOS SINAIS DE AUTH ----

# (Para o User) Função pra chamar quando clicar no botão de Esqueci a Senha
func _on_esqueci_senha_pressed() -> void:
	var email := email_input.text.strip_edges()
	
	if email.is_empty():
		print("Preencha o seu e-mail na caixa de texto para recuperar a senha!")
		return
		
	print("Solicitando link de recuperação para: ", email)
	DatabaseManager.recuperar_senha(email)

func _on_btn_back_pressed() -> void:
	print("Voltar pressionado. Mudando de cena...")
	# get_tree().change_scene_to_file("res://scenes/ui/menu_principal.tscn")

func _on_link_register_pressed() -> void:
	print("Ir para registro. Mudando de cena...")
	get_tree().change_scene_to_file("res://scenes/ui/cadastro.tscn")

func _show_error_popup(mensagem: String) -> void:
	var dialog = AcceptDialog.new()
	dialog.dialog_text = mensagem
	dialog.title = "Atenção"
	add_child(dialog)
	dialog.popup_centered()

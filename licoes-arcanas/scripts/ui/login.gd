extends Control

@onready var email_input: LineEdit = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxEmail/EmailInput
@onready var password_input: LineEdit = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxPassword/HBoxPassword/PasswordInput
@onready var btn_show_password: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxPassword/HBoxPassword/BtnShowPassword
@onready var btn_login: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxButtons/BtnLogin
@onready var btn_back: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxButtons/BtnBack
@onready var link_register: LinkButton = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LinkRegister

func _ready() -> void:
	btn_login.pressed.connect(_on_btn_login_pressed)
	btn_back.pressed.connect(_on_btn_back_pressed)
	link_register.pressed.connect(_on_link_register_pressed)
	btn_show_password.toggled.connect(_on_btn_show_password_toggled)

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
		print("Preencha e-mail e senha!")
		return
		
	print("Tentando fazer login para: ", email)
	# Integrar com backend de autenticação

func _on_btn_back_pressed() -> void:
	print("Voltar pressionado. Mudando de cena...")
	# get_tree().change_scene_to_file("res://scenes/ui/menu_principal.tscn")

func _on_link_register_pressed() -> void:
	print("Ir para registro. Mudando de cena...")
	get_tree().change_scene_to_file("res://scenes/ui/cadastro.tscn")

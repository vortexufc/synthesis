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

func _on_btn_show_password_toggled(button_pressed: bool) -> void:
	password_input.secret = !button_pressed
	
	if button_pressed:
		btn_show_password.text = " - "
	else:
		btn_show_password.text = " O "

func _on_btn_create_pressed() -> void:
	var player_name := name_input.text.strip_edges()
	var email := email_input.text.strip_edges()
	var password := password_input.text
	
	if player_name.is_empty() or email.is_empty() or password.is_empty():
		print("Preencha todos os campos!")
		# Aqui você pode mostrar um Label de erro na UI
		return
		
	print("Tentando criar conta para: ", player_name, " / ", email)
	# Integrar com backend de autenticação

func _on_btn_back_pressed() -> void:
	print("Voltar pressionado. Mudando de cena...")
	# get_tree().change_scene_to_file("res://scenes/ui/menu_principal.tscn")

func _on_link_login_pressed() -> void:
	print("Ir para login. Mudando de cena...")
	get_tree().change_scene_to_file("res://scenes/ui/login.tscn")

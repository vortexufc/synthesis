extends Control

@onready var slider_music = $CenterContainer/Panel/VBoxContainer/VBoxMusic/HSliderMusic
@onready var slider_sfx = $CenterContainer/Panel/VBoxContainer/VBoxSfx/HSliderSfx
@onready var btn_deslogar = $CenterContainer/Panel/VBoxContainer/HBoxConta/BtnDeslogar
@onready var toggle_joystick = $CenterContainer/Panel/VBoxContainer/HBoxJoystick/CheckJoystick
@onready var btn_voltar = $BtnVoltar

func _ready() -> void:
	slider_music.value_changed.connect(_on_music_value_changed)
	slider_sfx.value_changed.connect(_on_sfx_value_changed)
	
	btn_deslogar.pressed.connect(_on_deslogar_pressed)
	
	toggle_joystick.toggled.connect(_on_joystick_toggled)
	btn_voltar.pressed.connect(_on_voltar_pressed)
	
	# Muda a cor para vermelho se tiver logado, senão desativa
	if DatabaseManager.user_token.is_empty():
		btn_deslogar.disabled = true
		btn_deslogar.text = "NÃO LOGADO"
		btn_deslogar.modulate = Color(0.5, 0.5, 0.5, 1) # Cinza
	else:
		btn_deslogar.modulate = Color(1.0, 0.3, 0.3) # Vermelho para chamar atenção

func _on_music_value_changed(value: float) -> void:
	print("Volume da MÚSICA alterado para: ", value)

func _on_sfx_value_changed(value: float) -> void:
	print("Volume dos EFEITOS SONOROS alterado para: ", value)

func _on_deslogar_pressed() -> void:
	print("Deslogando usuário...")
	# Limpa os dados do usuário no DatabaseManager
	DatabaseManager.user_token = ""
	DatabaseManager.user_nick = ""
	DatabaseManager.user_cla = "Nenhum"
	
	# Limpa também a sessão no Supabase localmente para garantir
	# E volta para o menu principal
	TransitionScreen.change_scene("res://scenes/ui/main_menu.tscn")

func _on_joystick_toggled(button_pressed: bool) -> void:
	print("Joystick Virtual alterado para: ", "LIGADO" if button_pressed else "DESLIGADO")

func _on_voltar_pressed() -> void:
	print("Botão VOLTAR pressionado")
	TransitionScreen.change_scene("res://scenes/ui/main_menu.tscn")

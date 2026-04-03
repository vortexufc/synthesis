extends Control

@onready var slider_music = $CenterContainer/Panel/VBoxContainer/VBoxMusic/HSliderMusic
@onready var slider_sfx = $CenterContainer/Panel/VBoxContainer/VBoxSfx/HSliderSfx
@onready var btn_lang_pt = $CenterContainer/Panel/VBoxContainer/HBoxLang/BtnPT
@onready var btn_lang_en = $CenterContainer/Panel/VBoxContainer/HBoxLang/BtnEN
@onready var toggle_joystick = $CenterContainer/Panel/VBoxContainer/HBoxJoystick/CheckJoystick
@onready var btn_voltar = $BtnVoltar

func _ready() -> void:
	slider_music.value_changed.connect(_on_music_value_changed)
	slider_sfx.value_changed.connect(_on_sfx_value_changed)
	
	btn_lang_pt.pressed.connect(_on_lang_pt_pressed)
	btn_lang_en.pressed.connect(_on_lang_en_pressed)
	
	toggle_joystick.toggled.connect(_on_joystick_toggled)
	btn_voltar.pressed.connect(_on_voltar_pressed)
	
	_update_language_buttons(true) # PT como padrão inicial

func _on_music_value_changed(value: float) -> void:
	print("Volume da MÚSICA alterado para: ", value)

func _on_sfx_value_changed(value: float) -> void:
	print("Volume dos EFEITOS SONOROS alterado para: ", value)

func _on_lang_pt_pressed() -> void:
	print("Idioma selecionado: PORTUGUÊS")
	_update_language_buttons(true)

func _on_lang_en_pressed() -> void:
	print("Idioma selecionado: INGLÊS")
	_update_language_buttons(false)

func _on_joystick_toggled(button_pressed: bool) -> void:
	print("Joystick Virtual alterado para: ", "LIGADO" if button_pressed else "DESLIGADO")

func _on_voltar_pressed() -> void:
	print("Botão VOLTAR pressionado")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _update_language_buttons(is_pt: bool) -> void:
	var inactive_color = Color(0.5, 0.5, 0.5, 1) # Cinza para inativo
	
	if is_pt:
		btn_lang_pt.modulate = Color.WHITE
		btn_lang_en.modulate = inactive_color
	else:
		btn_lang_pt.modulate = inactive_color
		btn_lang_en.modulate = Color.WHITE

extends CanvasLayer

@onready var titulo = $ColorRect/VBoxContainer/Titulo
@onready var stats = $ColorRect/VBoxContainer/Stats
@onready var btn_tentar_novamente = $ColorRect/VBoxContainer/HBoxContainer/BtnTentarNovamente
@onready var btn_menu_principal = $ColorRect/VBoxContainer/HBoxContainer/BtnMenuPrincipal
@onready var color_rect = $ColorRect

func _ready() -> void:
	hide()
	GlobalSignals.fim_de_jogo.connect(_on_fim_de_jogo)
	btn_tentar_novamente.pressed.connect(_on_tentar_novamente_pressed)
	btn_menu_principal.pressed.connect(_on_menu_principal_pressed)

func _on_fim_de_jogo(vitoria: bool) -> void:
	show()
	if vitoria:
		titulo.text = "VITÓRIA!"
		titulo.add_theme_color_override("font_color", Color.GREEN)
		color_rect.color = Color(0, 0.2, 0, 0.8) # Fundo verde escuro
	else:
		titulo.text = "DERROTA..."
		titulo.add_theme_color_override("font_color", Color.RED)
		color_rect.color = Color(0.2, 0, 0, 0.8) # Fundo vermelho escuro
	
	# Placeholder para os stats que serão preenchidos depois ou calculados
	stats.text = "Tempo Restante: --s\nPrecisão: --%"

func _on_tentar_novamente_pressed() -> void:
	hide()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_principal_pressed() -> void:
	hide()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

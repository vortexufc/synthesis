extends CanvasLayer

@onready var titulo = $ColorRect/VBoxContainer/Titulo
@onready var stats = $ColorRect/VBoxContainer/Stats
@onready var btn_container = $ColorRect/VBoxContainer/HBoxContainer
@onready var btn_tentar_novamente = $ColorRect/VBoxContainer/HBoxContainer/BtnTentarNovamente
@onready var btn_menu_principal = $ColorRect/VBoxContainer/HBoxContainer/BtnMenuPrincipal
@onready var color_rect = $ColorRect

var particulas: CPUParticles2D

func _ready() -> void:
	hide()
	GlobalSignals.fim_de_jogo.connect(_on_fim_de_jogo)
	btn_tentar_novamente.pressed.connect(_on_tentar_novamente_pressed)
	btn_menu_principal.pressed.connect(_on_menu_principal_pressed)
	
	# Criação das partículas via código para não precisar alterar a cena
	particulas = CPUParticles2D.new()
	particulas.emitting = false
	particulas.amount = 100
	particulas.lifetime = 2.0
	particulas.one_shot = false
	particulas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	
	# Usar o tamanho real da tela para que as partículas preencham tudo
	var screen_size = get_viewport().get_visible_rect().size
	particulas.emission_rect_extents = screen_size / 2.0
	particulas.position = screen_size / 2.0
	
	particulas.gravity = Vector2(0, 50)
	particulas.color = Color.GOLD
	particulas.scale_amount_min = 2.0
	particulas.scale_amount_max = 6.0
	add_child(particulas)

func _on_fim_de_jogo(vitoria: bool, dict_stats: Dictionary = {}) -> void:
	show()
	if vitoria:
		titulo.text = "VITÓRIA!"
		titulo.add_theme_color_override("font_color", Color.GOLD)
		color_rect.color = Color(0, 0, 0, 0.8) # Fundo escuro simples
		btn_container.hide() # Esconde botões para voltar rápido ao jogo
		particulas.emitting = true
	else:
		titulo.text = "DERROTA..."
		titulo.add_theme_color_override("font_color", Color.RED)
		color_rect.color = Color(0.2, 0, 0, 0.8) # Fundo vermelho escuro
		btn_container.show() # Mostra botões
		particulas.emitting = false
	
	if dict_stats.is_empty():
		stats.text = "Tempo Sobrevivido: --s\nPrecisão: --%\nDano Causado: --"
	else:
		stats.text = "Tempo Sobrevivido: %.1fs\nPrecisão: %d%%\nDano Causado: %d" % [
			dict_stats.get("tempo", 0.0),
			dict_stats.get("precisao", 0),
			dict_stats.get("dano", 0)
		]
	
	# Se for vitória, aguarda 3 segundos e volta pro jogo
	if vitoria:
		# usar process_always no timer pra funcionar com o jogo pausado
		await get_tree().create_timer(3.0, true).timeout
		hide()
		particulas.emitting = false
		get_tree().paused = false

func _on_tentar_novamente_pressed() -> void:
	hide()
	get_tree().paused = false
	PlayerStats.resetar_vida()
	TransitionScreen.change_scene("res://scenes/Salas/Salas_BuildTGXP/Corredor.tscn")

func _on_menu_principal_pressed() -> void:
	hide()
	get_tree().paused = false
	PlayerStats.resetar_vida()
	TransitionScreen.change_scene("res://scenes/ui/main_menu.tscn")


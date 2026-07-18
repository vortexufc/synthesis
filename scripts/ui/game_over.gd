extends CanvasLayer

@onready var titulo = $ColorRect/VBoxContainer/Titulo
@onready var stats = $ColorRect/VBoxContainer/Stats
@onready var btn_container = $ColorRect/VBoxContainer/HBoxContainer
@onready var btn_tentar_novamente = $ColorRect/VBoxContainer/HBoxContainer/BtnTentarNovamente
@onready var btn_menu_principal = $ColorRect/VBoxContainer/HBoxContainer/BtnMenuPrincipal
@onready var color_rect = $ColorRect

var particulas: CPUParticles2D
var _pode_pular_vitoria: bool = false

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
		AudioManager.restore_previous_music()
		AudioManager.play_sfx("fail")
		titulo.text = "VITÓRIA!"
		titulo.add_theme_color_override("font_color", Color.GOLD)
		color_rect.color = Color(0, 0, 0, 0.8) # Fundo escuro simples
		btn_container.hide() # Esconde botões para voltar rápido ao jogo
		particulas.emitting = true
		
		# Cria mensagem discreta para pular a animação de vitória
		var lbl_skip = Label.new()
		lbl_skip.name = "LblSkip"
		lbl_skip.text = "( Pressione ESPAÇO para pular )"
		lbl_skip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_skip.add_theme_font_size_override("font_size", 14)
		lbl_skip.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 0.8)) # Cinza discreto
		
		var font = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
		if font:
			lbl_skip.add_theme_font_override("font", font)
			
		$ColorRect/VBoxContainer.add_child(lbl_skip)
		_pode_pular_vitoria = true
	else:
		AudioManager.stop_battle_music()
		AudioManager.play_sfx("win")
		titulo.text = "DERROTA..."
		titulo.add_theme_color_override("font_color", Color.RED)
		color_rect.color = Color(0.2, 0, 0, 0.8) # Fundo vermelho escuro
		btn_container.show() # Mostra botões
		particulas.emitting = false
		_pode_pular_vitoria = false
	
	if dict_stats.is_empty():
		stats.text = "Tempo de Batalha: --s\nPrecisão: --%\nDano Causado: --"
	else:
		var tempo = dict_stats.get("tempo", 0.0)
		var precisao = dict_stats.get("precisao", 0)
		var dano = dict_stats.get("dano", 0)
		
		var pontos = 0
		if vitoria:
			# Matemágica do Ranking:
			# 10 pts por dano + (precisão * 5) + Bônus de rapidez (Até 300 segundos, sobra * 2)
			var bonus_tempo = max(0, (300 - tempo) * 2)
			pontos = int((dano * 10) + (precisao * 5) + bonus_tempo)
			
			var nick = DatabaseManager.user_nick
			var cla = DatabaseManager.user_cla
			
			# Se a pessoa não tiver logado, pega o ID único do dispositivo dela!
			if nick == "": 
				nick = RankingManager.get_local_nick()
			if cla == "": 
				cla = "Sem Clã"
			
			# Envia para salvar localmente no Top 5!
			RankingManager.add_score(nick, cla, pontos)
			
		stats.text = "Tempo: %.1fs\nPrecisão: %d%%\nDano: %d\n\n+ %d PONTOS" % [
			tempo, precisao, dano, pontos
		]
	
	# Se for vitória, aguarda 3 segundos e volta pro jogo
	if vitoria:
		# usar process_always no timer pra funcionar com o jogo pausado
		await get_tree().create_timer(3.0, true).timeout
		if _pode_pular_vitoria:
			_finalizar_vitoria()

func _input(event: InputEvent) -> void:
	if _pode_pular_vitoria:
		if event.is_action_pressed("ui_select") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
			get_viewport().set_input_as_handled()
			_finalizar_vitoria()

func _finalizar_vitoria() -> void:
	_pode_pular_vitoria = false
	hide()
	particulas.emitting = false
	get_tree().paused = false
	QuizManager.fechar_ui_batalha()
	if $ColorRect/VBoxContainer.has_node("LblSkip"):
		$ColorRect/VBoxContainer.get_node("LblSkip").queue_free()

func _on_tentar_novamente_pressed() -> void:
	hide()
	get_tree().paused = false
	AudioManager.play_sfx("ui-2")
	PlayerStats.resetar_vida()
	QuizManager.fechar_ui_batalha()
	if get_node_or_null("/root/DungeonGenerator"):
		DungeonGenerator.resetar_masmorra()
	if get_node_or_null("/root/QuizManager"):
		QuizManager.resetar_historico_perguntas()
	TransitionScreen.change_scene("res://scenes/Salas/Hub_Geral.tscn")

func _on_menu_principal_pressed() -> void:
	hide()
	get_tree().paused = false
	AudioManager.play_sfx("ui-2")
	PlayerStats.resetar_vida()
	QuizManager.fechar_ui_batalha()
	TransitionScreen.change_scene("res://scenes/ui/main_menu.tscn")

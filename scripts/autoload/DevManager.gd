extends Node

## FLAG MESTRE — Para desativar na versão final do jogo, basta mudar para false!
const DEV_MODE_ENABLED: bool = true

# Opções do GodMode / Dev Menu
var god_mode_resposta_a: bool = true      ## Resposta A sempre será a opção correta no Quiz
var invencivel: bool = true               ## Jogador não toma dano
var super_velocidade: bool = true         ## Acelera o jogador em 2.5x
var multiplicador_velocidade: float = 2.5
var passar_portas_trancadas: bool = true   ## Permite passar por portas trancadas/seladas por inimigos

# Referências da UI
var _canvas_layer: CanvasLayer = null
var _panel_container: PanelContainer = null
var _btn_toggle: Button = null

# Lista de salas disponíveis para teleporte
var _salas_teleporte = [
	{"nome": "🏰 Hub Geral", "path": "res://scenes/Salas/Hub_Geral.tscn"},
	{"nome": "🧪 Química - Sala 01", "path": "res://scenes/Salas/Salas_Quimica/Sala_Alquimia01.tscn"},
	{"nome": "🧪 Química - Sala 02", "path": "res://scenes/Salas/Salas_Quimica/Sala_Alquimia02.tscn"},
	{"nome": "🧪 Química - Sala 03", "path": "res://scenes/Salas/Salas_Quimica/Sala_Alquimia03.tscn"},
	{"nome": "🧪 Química - Sala 04", "path": "res://scenes/Salas/Salas_Quimica/Sala_Alquimia04.tscn"},
	{"nome": "🧪 Química - Sala 09", "path": "res://scenes/Salas/Salas_Quimica/Sala_Alquimia09.tscn"},
	{"nome": "🧪 Química - Sala 10", "path": "res://scenes/Salas/Salas_Quimica/Sala_Alquimia10.tscn"},
	{"nome": "🧪 Química - Sala 11", "path": "res://scenes/Salas/Salas_Quimica/Sala_Alquimia11.tscn"},
	{"nome": "🧪 Química - Sala 12", "path": "res://scenes/Salas/Salas_Quimica/Sala_Alquimia12.tscn"},
	{"nome": "⚡ Física - Sala 01", "path": "res://scenes/Salas/Sala_Fisica/Sala_Física01.tscn"},
	{"nome": "⚡ Física - Sala 02", "path": "res://scenes/Salas/Sala_Fisica/Sala_Física02.tscn"},
	{"nome": "⚡ Física - Sala 06", "path": "res://scenes/Salas/Sala_Fisica/Sala_Física06.tscn"},
	{"nome": "⚡ Física - Sala 12", "path": "res://scenes/Salas/Sala_Fisica/Sala_Física12.tscn"},
	{"nome": "👑 Sala do Boss (Alquimia)", "path": "res://scenes/Salas/Salas_Quimica/Sala_BossAlquimia.tscn"}
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if not DEV_MODE_ENABLED:
		return
		
	call_deferred("_criar_interface_dev")

func _unhandled_input(event: InputEvent) -> void:
	if not DEV_MODE_ENABLED:
		return
		
	# Atalho F1 para alternar visibilidade do painel Dev
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			_toggle_menu()

func _criar_interface_dev() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 120 # Fica por cima de qualquer outra UI
	add_child(_canvas_layer)
	
	# Botão flutuante no canto superior direito
	_btn_toggle = Button.new()
	_btn_toggle.text = "🛠️ DEV MENU"
	_btn_toggle.position = Vector2(1130, 10)
	_btn_toggle.custom_minimum_size = Vector2(130, 36)
	_btn_toggle.pressed.connect(_toggle_menu)
	_canvas_layer.add_child(_btn_toggle)
	
	# Painel Modal do Dev Menu
	_panel_container = PanelContainer.new()
	_panel_container.visible = false
	_panel_container.custom_minimum_size = Vector2(380, 420)
	_panel_container.position = Vector2(880, 55)
	
	# Estilização visual (escuro semi-transparente estilo glassmorphism)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.13, 0.95)
	style.set_corner_radius_all(12)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.5, 0.9, 0.8)
	style.content_margin_left = 16
	style.content_margin_top = 16
	style.content_margin_right = 16
	style.content_margin_bottom = 16
	_panel_container.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_panel_container.add_child(vbox)
	
	# Título do Menu
	var lbl_title = Label.new()
	lbl_title.text = "🛠️ DEV / GOD MODE"
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.add_theme_font_size_override("font_size", 18)
	lbl_title.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	vbox.add_child(lbl_title)
	
	var hs = HSeparator.new()
	vbox.add_child(hs)
	
	# Checkbox 1: Resposta A Sempre Correta
	var chk_resposta_a = CheckBox.new()
	chk_resposta_a.text = "🎯 Resposta A Sempre Correta (Quiz)"
	chk_resposta_a.button_pressed = god_mode_resposta_a
	chk_resposta_a.toggled.connect(func(t): god_mode_resposta_a = t)
	vbox.add_child(chk_resposta_a)
	
	# Checkbox 2: Invencibilidade
	var chk_invencivel = CheckBox.new()
	chk_invencivel.text = "🛡️ Invencibilidade (Vida Infinita)"
	chk_invencivel.button_pressed = invencivel
	chk_invencivel.toggled.connect(func(t): invencivel = t)
	vbox.add_child(chk_invencivel)
	
	# Checkbox 3: Super Velocidade
	var chk_velocidade = CheckBox.new()
	chk_velocidade.text = "⏩ Super Velocidade de Movimento (2.5x)"
	chk_velocidade.button_pressed = super_velocidade
	chk_velocidade.toggled.connect(func(t): super_velocidade = t)
	vbox.add_child(chk_velocidade)
	
	# Checkbox 4: Passar por Portas Trancadas / Seladas
	var chk_portas = CheckBox.new()
	chk_portas.text = "🚪 Ignorar Portas Trancadas / Seladas"
	chk_portas.button_pressed = passar_portas_trancadas
	chk_portas.toggled.connect(func(t): passar_portas_trancadas = t)
	vbox.add_child(chk_portas)
	
	var hs2 = HSeparator.new()
	vbox.add_child(hs2)
	
	# Botão 1: Derrotar Inimigo Atual (Auto-Win em Batalha)
	var btn_autowin = Button.new()
	btn_autowin.text = "⚡ Derrotar Monstro (Auto-Win)"
	btn_autowin.pressed.connect(_derrotar_monstro_atual)
	vbox.add_child(btn_autowin)
	
	# Botão 2: Curar 100% Vida
	var btn_heal = Button.new()
	btn_heal.text = "❤️ Curar Vida Total (HP Max)"
	btn_heal.pressed.connect(func():
		if get_node_or_null("/root/PlayerStats"):
			PlayerStats.curar_vida(100.0)
	)
	vbox.add_child(btn_heal)
	
	var hs3 = HSeparator.new()
	vbox.add_child(hs3)
	
	# Subtítulo Teleporte
	var lbl_teleport = Label.new()
	lbl_teleport.text = "🚪 Teleporte Rápido de Sala:"
	lbl_teleport.add_theme_font_size_override("font_size", 14)
	vbox.add_child(lbl_teleport)
	
	# Dropdown / OptionButton de Salas
	var opt_salas = OptionButton.new()
	for sala in _salas_teleporte:
		opt_salas.add_item(sala["nome"])
	vbox.add_child(opt_salas)
	
	var btn_teleport = Button.new()
	btn_teleport.text = "🚀 Ir para a Sala Selecionada"
	btn_teleport.pressed.connect(func():
		var idx = opt_salas.selected
		if idx >= 0 and idx < _salas_teleporte.size():
			var cena_path = _salas_teleporte[idx]["path"]
			print("[DevManager] Teleportando para: %s" % cena_path)
			_panel_container.visible = false
			get_tree().paused = false
			if get_node_or_null("/root/TransitionScreen"):
				TransitionScreen.change_scene(cena_path)
			else:
				get_tree().change_scene_to_file(cena_path)
	)
	vbox.add_child(btn_teleport)
	
	# Botão Fechar
	var btn_close = Button.new()
	btn_close.text = "❌ Fechar Painel (F1)"
	btn_close.pressed.connect(_toggle_menu)
	vbox.add_child(btn_close)
	
	_canvas_layer.add_child(_panel_container)

func _toggle_menu() -> void:
	if _panel_container:
		_panel_container.visible = not _panel_container.visible

func _derrotar_monstro_atual() -> void:
	if get_node_or_null("/root/QuizManager"):
		QuizManager.derrotar_inimigo_atual()

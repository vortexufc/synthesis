extends Node

# se mudar pra false desliga o dev menu
var DEV_MODE_ENABLED: bool = true

# opcoes do menu dev
var god_mode_resposta_a: bool = true      # resposta A sempre correta
var invencivel: bool = true               # jogador nao toma dano
var super_velocidade: bool = true         # acelera o boneco
var multiplicador_velocidade: float = 2.5
var passar_portas_trancadas: bool = false # ignora chaves/selos nas salas
var liberar_portas_hub: bool = false      # ignora bloqueio de andar no hub

# referencias da ui
var _canvas_layer: CanvasLayer = null
var _panel_container: PanelContainer = null

# salas pra teleportar
var _salas_teleporte = [
	{"nome": "🏰 Hub Geral", "path": "res://scenes/Salas/Comum/Hub_Geral.tscn"},
	{"nome": "🧪 Química - Corredor", "path": "res://scenes/Salas/Laboratório_Alquimia/Corredor_Alquimia.tscn"},
	{"nome": "🧪 Química - Sala 01", "path": "res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia01.tscn"},
	{"nome": "🧪 Química - Sala 02", "path": "res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia02.tscn"},
	{"nome": "🧪 Química - Sala 03", "path": "res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia03.tscn"},
	{"nome": "🧪 Química - Sala 04", "path": "res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia04.tscn"},
	{"nome": "🧪 Química - Sala 09", "path": "res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia09.tscn"},
	{"nome": "🧪 Química - Sala 10", "path": "res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia10.tscn"},
	{"nome": "🧪 Química - Sala 11", "path": "res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia11.tscn"},
	{"nome": "🧪 Química - Sala 12", "path": "res://scenes/Salas/Laboratório_Alquimia/Sala_Alquimia12.tscn"},
	{"nome": "👑 Sala do Boss (Alquimia)", "path": "res://scenes/Salas/Laboratório_Alquimia/Sala_BossAlquimia.tscn"},
	{"nome": "⚡ Física - Corredor", "path": "res://scenes/Salas/Oficina_Física/Corredor_Física.tscn"},
	{"nome": "⚡ Física - Sala 01", "path": "res://scenes/Salas/Oficina_Física/Sala_Física01.tscn"},
	{"nome": "⚡ Física - Sala 02", "path": "res://scenes/Salas/Oficina_Física/Sala_Física02.tscn"},
	{"nome": "⚡ Física - Sala 03", "path": "res://scenes/Salas/Oficina_Física/Sala_Física03.tscn"},
	{"nome": "⚡ Física - Sala 04", "path": "res://scenes/Salas/Oficina_Física/Sala_Física04.tscn"},
	{"nome": "⚡ Física - Sala 05", "path": "res://scenes/Salas/Oficina_Física/Sala_Física05.tscn"},
	{"nome": "⚡ Física - Sala 06", "path": "res://scenes/Salas/Oficina_Física/Sala_Física06.tscn"},
	{"nome": "⚡ Física - Sala 07", "path": "res://scenes/Salas/Oficina_Física/Sala_Física07.tscn"},
	{"nome": "⚡ Física - Sala 08", "path": "res://scenes/Salas/Oficina_Física/Sala_Física08.tscn"},
	{"nome": "⚡ Física - Sala 09", "path": "res://scenes/Salas/Oficina_Física/Sala_Física09.tscn"},
	{"nome": "⚡ Física - Sala 10", "path": "res://scenes/Salas/Oficina_Física/Sala_Física10.tscn"},
	{"nome": "⚡ Física - Sala 11", "path": "res://scenes/Salas/Oficina_Física/Sala_Física11.tscn"},
	{"nome": "⚡ Física - Sala 12", "path": "res://scenes/Salas/Oficina_Física/Sala_Física12.tscn"},
	{"nome": "🌿 Biologia - Corredor", "path": "res://scenes/Salas/Estufa_Biologia/Corredor_Estufa.tscn"},
	{"nome": "🌿 Biologia - Sala 01", "path": "res://scenes/Salas/Estufa_Biologia/Sala_Biologia01.tscn"},
	{"nome": "🌿 Biologia - Sala 02", "path": "res://scenes/Salas/Estufa_Biologia/Sala_Biologia02.tscn"},
	{"nome": "🌿 Biologia - Sala 03", "path": "res://scenes/Salas/Estufa_Biologia/Sala_Biologia03.tscn"},
	{"nome": "🌿 Biologia - Sala 04", "path": "res://scenes/Salas/Estufa_Biologia/Sala_Biologia04.tscn"}
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if not DEV_MODE_ENABLED:
		return
		
	call_deferred("_criar_interface_dev")

func _unhandled_input(event: InputEvent) -> void:
	if not DEV_MODE_ENABLED:
		return
		
	# f1 abre e fecha o menu dev
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			_toggle_menu()

func _criar_botao_dev(texto: String, cor_hover: Color = Color(0.2, 0.32, 0.48)) -> Button:
	var btn = Button.new()
	btn.text = texto
	btn.custom_minimum_size = Vector2(0, 32)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.15, 0.22, 0.95)
	sb.set_corner_radius_all(6)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.28, 0.38, 0.55, 0.85)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", sb)
	
	var sb_h = sb.duplicate()
	sb_h.bg_color = cor_hover
	sb_h.border_color = Color(0.45, 0.75, 1.0, 1.0)
	btn.add_theme_stylebox_override("hover", sb_h)
	
	var sb_p = sb.duplicate()
	sb_p.bg_color = Color(0.08, 0.1, 0.16, 0.95)
	btn.add_theme_stylebox_override("pressed", sb_p)
	
	return btn

func _criar_interface_dev() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 120 # Fica por cima de qualquer outra UI
	add_child(_canvas_layer)
	
	# painel do menu dev ancorado na lateral direita com margens seguras
	_panel_container = PanelContainer.new()
	_panel_container.visible = false
	_panel_container.anchor_left = 1.0
	_panel_container.anchor_right = 1.0
	_panel_container.anchor_top = 0.0
	_panel_container.anchor_bottom = 1.0
	_panel_container.offset_left = -440.0
	_panel_container.offset_right = -16.0
	_panel_container.offset_top = 16.0
	_panel_container.offset_bottom = -16.0
	_panel_container.custom_minimum_size = Vector2(420, 0)
	
	# fundo escuro do painel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.13, 0.96)
	style.set_corner_radius_all(10)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.5, 0.9, 0.85)
	style.content_margin_left = 14
	style.content_margin_top = 14
	style.content_margin_right = 14
	style.content_margin_bottom = 14
	style.shadow_color = Color(0, 0, 0, 0.7)
	style.shadow_size = 12
	_panel_container.add_theme_stylebox_override("panel", style)
	
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel_container.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)
	
	# titulo
	var lbl_title = Label.new()
	lbl_title.text = "🛠️ DEV / GOD MODE (F1)"
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.add_theme_font_size_override("font_size", 16)
	lbl_title.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	vbox.add_child(lbl_title)
	
	var hs = HSeparator.new()
	vbox.add_child(hs)
	
	# secao de checkboxes
	var lbl_cheats = Label.new()
	lbl_cheats.text = "⚡ MODOS ATIVOS (CHECKBOX):"
	lbl_cheats.add_theme_font_size_override("font_size", 12)
	lbl_cheats.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	vbox.add_child(lbl_cheats)
	
	var chk_resposta_a = CheckBox.new()
	chk_resposta_a.text = "🎯 Resposta A Sempre Correta (Quiz)"
	chk_resposta_a.button_pressed = god_mode_resposta_a
	chk_resposta_a.toggled.connect(func(t): god_mode_resposta_a = t)
	vbox.add_child(chk_resposta_a)
	
	var chk_invencivel = CheckBox.new()
	chk_invencivel.text = "🛡️ Invencibilidade (Vida Infinita)"
	chk_invencivel.button_pressed = invencivel
	chk_invencivel.toggled.connect(func(t): invencivel = t)
	vbox.add_child(chk_invencivel)
	
	var chk_velocidade = CheckBox.new()
	chk_velocidade.text = "⏩ Super Velocidade (2.5x)"
	chk_velocidade.button_pressed = super_velocidade
	chk_velocidade.toggled.connect(func(t): super_velocidade = t)
	vbox.add_child(chk_velocidade)
	
	var chk_portas = CheckBox.new()
	chk_portas.text = "🗝️ Ignorar Chaves e Selos nas Salas"
	chk_portas.button_pressed = passar_portas_trancadas
	chk_portas.toggled.connect(func(t): passar_portas_trancadas = t)
	vbox.add_child(chk_portas)

	var chk_hub = CheckBox.new()
	chk_hub.text = "🔓 Liberar Portas do Hub (Sem Bloqueio de Andar)"
	chk_hub.button_pressed = liberar_portas_hub
	chk_hub.toggled.connect(func(t): 
		liberar_portas_hub = t
		print("[DevManager] Liberar portas do Hub: ", t)
	)
	vbox.add_child(chk_hub)
	
	var hs2 = HSeparator.new()
	vbox.add_child(hs2)
	
	# acoes rapidas
	var lbl_acoes = Label.new()
	lbl_acoes.text = "⚙️ AÇÕES RÁPIDAS:"
	lbl_acoes.add_theme_font_size_override("font_size", 12)
	lbl_acoes.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	vbox.add_child(lbl_acoes)
	
	# resetar expedicao do hub
	var btn_reset_andar = _criar_botao_dev("🚪 Resetar Expedição Atual (Limpar Andar)", Color(0.42, 0.24, 0.12))
	btn_reset_andar.pressed.connect(func():
		if get_node_or_null("/root/DatabaseManager"):
			DatabaseManager.resetar_expedicao_ativa()
		if get_node_or_null("/root/DungeonGenerator"):
			DungeonGenerator.resetar_masmorra()
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("mostrar_mensagem"):
			hud.mostrar_mensagem("🚪 Expedição resetada! Portas do Hub liberadas.")
		elif hud and hud.has_method("mostrar_notificacao_quest"):
			hud.mostrar_notificacao_quest("🛠️ DEV MODE", "Expedição resetada! Portas liberadas.", Color(0.4, 0.9, 1.0), "ui-1")
		print("[DevManager] Expedição resetada!")
	)
	vbox.add_child(btn_reset_andar)
	
	var btn_autowin = _criar_botao_dev("⚡ Derrotar Monstro (Auto-Win)")
	btn_autowin.pressed.connect(_derrotar_monstro_atual)
	vbox.add_child(btn_autowin)
	
	var btn_heal = _criar_botao_dev("❤️ Curar Vida Total (HP Max)")
	btn_heal.pressed.connect(func():
		if get_node_or_null("/root/PlayerStats"):
			PlayerStats.curar_vida(100.0)
	)
	vbox.add_child(btn_heal)
	
	var btn_reset = _criar_botao_dev("🔄 Resetar Todas as Quests")
	btn_reset.pressed.connect(func():
		if get_node_or_null("/root/PlayerStats"):
			PlayerStats.quests_concluidas.clear()
			PlayerStats.quests_ativas.clear()
			PlayerStats.salvar()
			PlayerStats.quests_atualizadas.emit()
	)
	vbox.add_child(btn_reset)
	
	var btn_clear_inv = _criar_botao_dev("🗑️ Limpar Inventário e Moedas")
	btn_clear_inv.pressed.connect(_limpar_inventario_e_moedas)
	vbox.add_child(btn_clear_inv)
	
	var hs_ins = HSeparator.new()
	vbox.add_child(hs_ins)
	
	# gerenciador rapido de insignias
	var lbl_ins = Label.new()
	lbl_ins.text = "🏅 INSÍGNIAS DO RANKING:"
	lbl_ins.add_theme_font_size_override("font_size", 12)
	lbl_ins.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	vbox.add_child(lbl_ins)
	
	var hbox_insignias = HBoxContainer.new()
	hbox_insignias.add_theme_constant_override("separation", 6)
	
	var btn_unlock_insignias = _criar_botao_dev("🏅 Desbloquear Todas")
	btn_unlock_insignias.pressed.connect(func():
		if get_node_or_null("/root/PlayerStats"):
			PlayerStats.desbloquear_todas_insignias()
	)
	hbox_insignias.add_child(btn_unlock_insignias)
	
	var btn_reset_insignias = _criar_botao_dev("🔒 Bloquear Todas")
	btn_reset_insignias.pressed.connect(func():
		if get_node_or_null("/root/PlayerStats"):
			PlayerStats.resetar_insignias()
	)
	hbox_insignias.add_child(btn_reset_insignias)
	vbox.add_child(hbox_insignias)
	
	var hs_novos = HSeparator.new()
	vbox.add_child(hs_novos)

	var lbl_novos = Label.new()
	lbl_novos.text = "⚔️ FÚRIA DO CHEFE & VINHETAS:"
	lbl_novos.add_theme_font_size_override("font_size", 12)
	lbl_novos.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	vbox.add_child(lbl_novos)

	var btn_test_furia = _criar_botao_dev("⚡ Testar Fúria do Chefe (V/F QTE)")
	btn_test_furia.pressed.connect(func():
		_panel_container.visible = false
		var furia_cena = load("res://scenes/ui/furia_chefe_ui.tscn")
		if furia_cena:
			var furia_inst = furia_cena.instantiate()
			get_tree().root.add_child(furia_inst)
			furia_inst.iniciar_furia(1)
	)
	vbox.add_child(btn_test_furia)

	var hbox_vinhetas = HBoxContainer.new()
	hbox_vinhetas.add_theme_constant_override("separation", 6)
	
	var btn_v1 = _criar_botao_dev("📜 Cap. I")
	btn_v1.pressed.connect(func():
		_panel_container.visible = false
		var v_cena = load("res://scenes/ui/vinheta_historia.tscn")
		if v_cena:
			var v = v_cena.instantiate()
			get_tree().root.add_child(v)
			v.iniciar_vinheta(1)
	)
	hbox_vinhetas.add_child(btn_v1)

	var btn_v2 = _criar_botao_dev("📜 Cap. II")
	btn_v2.pressed.connect(func():
		_panel_container.visible = false
		var v_cena = load("res://scenes/ui/vinheta_historia.tscn")
		if v_cena:
			var v = v_cena.instantiate()
			get_tree().root.add_child(v)
			v.iniciar_vinheta(2)
	)
	hbox_vinhetas.add_child(btn_v2)

	var btn_v3 = _criar_botao_dev("📜 Cap. III")
	btn_v3.pressed.connect(func():
		_panel_container.visible = false
		var v_cena = load("res://scenes/ui/vinheta_historia.tscn")
		if v_cena:
			var v = v_cena.instantiate()
			get_tree().root.add_child(v)
			v.iniciar_vinheta(3)
	)
	hbox_vinhetas.add_child(btn_v3)
	vbox.add_child(hbox_vinhetas)

	var hs3 = HSeparator.new()
	vbox.add_child(hs3)
	
	# lista de teleporte
	var lbl_teleport = Label.new()
	lbl_teleport.text = "🚪 TELEPORTE DE SALA:"
	lbl_teleport.add_theme_font_size_override("font_size", 12)
	lbl_teleport.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	vbox.add_child(lbl_teleport)
	
	var opt_salas = OptionButton.new()
	opt_salas.custom_minimum_size = Vector2(0, 30)
	for sala in _salas_teleporte:
		opt_salas.add_item(sala["nome"])
	vbox.add_child(opt_salas)
	
	var btn_teleport = _criar_botao_dev("🚀 Ir para a Sala Selecionada", Color(0.2, 0.4, 0.3))
	btn_teleport.pressed.connect(func():
		var idx = opt_salas.selected
		if idx >= 0 and idx < _salas_teleporte.size():
			var cena_path = _salas_teleporte[idx]["path"]
			print("teleportando para: ", cena_path)
			_panel_container.visible = false
			get_tree().paused = false
			if get_node_or_null("/root/TransitionScreen"):
				TransitionScreen.change_scene(cena_path)
			else:
				get_tree().change_scene_to_file(cena_path)
	)
	vbox.add_child(btn_teleport)
	
	_canvas_layer.add_child(_panel_container)

func _toggle_menu() -> void:
	if _panel_container:
		_panel_container.visible = not _panel_container.visible

func _derrotar_monstro_atual() -> void:
	if get_node_or_null("/root/QuizManager"):
		QuizManager.derrotar_inimigo_atual()

func _limpar_inventario_e_moedas() -> void:
	if get_node_or_null("/root/PlayerStats"):
		PlayerStats.limpar_inventario_e_moedas()
		print("inventario e moedas zerados")
		
		# atualiza a mochila se tiver aberta
		var inv = get_tree().get_first_node_in_group("inventario_ui")
		if not inv:
			inv = get_tree().root.find_child("InventarioUI", true, false)
		if inv:
			if inv.has_method("_limpar_detalhes"):
				inv._limpar_detalhes()
			if inv.has_method("_atualizar_listas"):
				inv._atualizar_listas()
				
		# atualiza a loja se tiver aberta
		var loja = get_tree().root.find_child("LojaMercador", true, false)
		if loja and loja.has_method("_atualizar_interface"):
			loja._atualizar_interface()
				
		# aviso na hud
		var hud = get_tree().get_first_node_in_group("hud")
		if not hud:
			hud = get_tree().root.find_child("HUD", true, false)
		if hud and hud.has_method("mostrar_mensagem"):
			hud.mostrar_mensagem("🗑️ Inventário e Moedas Zerados!")
			
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("ui_5")

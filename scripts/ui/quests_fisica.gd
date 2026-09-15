extends CanvasLayer

var bg_rect: ColorRect
var painel: Panel
var lbl_titulo: Label
var lbl_desc: Label

var btn_quest1: Button
var btn_quest2: Button
var btn_cancel1: Button
var btn_cancel2: Button
var btn_fechar: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true # Pausa o jogo
	
	bg_rect = ColorRect.new()
	bg_rect.color = Color(0, 0, 0, 0.7)
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_rect)
	
	painel = Panel.new()
	painel.custom_minimum_size = Vector2(550, 380)
	var vp_size = get_viewport().get_visible_rect().size
	painel.position = (vp_size - painel.custom_minimum_size) * 0.5
	painel.pivot_offset = painel.custom_minimum_size * 0.5
	
	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = Color(0.15, 0.1, 0.1, 0.95)
	style_panel.border_width_left = 3
	style_panel.border_width_right = 3
	style_panel.border_width_top = 3
	style_panel.border_width_bottom = 3
	style_panel.border_color = Color(0.9, 0.6, 0.2, 1.0) # Laranja Mecânico/Elétrico
	style_panel.corner_radius_top_left = 12
	style_panel.corner_radius_top_right = 12
	style_panel.corner_radius_bottom_left = 12
	style_panel.corner_radius_bottom_right = 12
	style_panel.shadow_color = Color(0, 0, 0, 0.8)
	style_panel.shadow_size = 15
	painel.add_theme_stylebox_override("panel", style_panel)
	painel.scale = Vector2(0.88, 0.88)
	painel.modulate.a = 0.0
	var tw_open = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_open.tween_property(painel, "scale", Vector2(1.0, 1.0), 0.24)
	tw_open.tween_property(painel, "modulate:a", 1.0, 0.20)
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui_5")
	
	add_child(painel)
	
	var margin_c = MarginContainer.new()
	margin_c.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin_c.add_theme_constant_override("margin_top", 20)
	margin_c.add_theme_constant_override("margin_left", 25)
	margin_c.add_theme_constant_override("margin_right", 25)
	margin_c.add_theme_constant_override("margin_bottom", 20)
	painel.add_child(margin_c)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin_c.add_child(vbox)
	
	lbl_titulo = Label.new()
	lbl_titulo.text = "Engenheiro Maluco"
	lbl_titulo.add_theme_font_size_override("font_size", 24)
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_titulo)
	
	lbl_desc = Label.new()
	lbl_desc.text = ""
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(lbl_desc)
	
	var hs = HSeparator.new()
	vbox.add_child(hs)
	
	var hbox1 = HBoxContainer.new()
	vbox.add_child(hbox1)
	
	btn_quest1 = Button.new()
	btn_quest1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_quest1.pressed.connect(_tentar_entregar_quest1)
	hbox1.add_child(btn_quest1)
	
	btn_cancel1 = Button.new()
	btn_cancel1.text = " X "
	btn_cancel1.pressed.connect(func(): _cancelar_quest("fisica_quest1"))
	hbox1.add_child(btn_cancel1)
	
	var hbox2 = HBoxContainer.new()
	vbox.add_child(hbox2)
	
	btn_quest2 = Button.new()
	btn_quest2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_quest2.pressed.connect(_tentar_entregar_quest2)
	hbox2.add_child(btn_quest2)
	
	btn_cancel2 = Button.new()
	btn_cancel2.text = " X "
	btn_cancel2.pressed.connect(func(): _cancelar_quest("fisica_quest2"))
	hbox2.add_child(btn_cancel2)
	
	btn_fechar = Button.new()
	btn_fechar.text = "Fechar (F)"
	btn_fechar.pressed.connect(_fechar)
	vbox.add_child(btn_fechar)
	
	var font_pixel = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf")
	if font_pixel:
		lbl_titulo.add_theme_font_override("font", font_pixel)
		lbl_desc.add_theme_font_override("font", font_pixel)
	lbl_desc.add_theme_font_size_override("font_size", 16)
	lbl_desc.add_theme_color_override("font_color", Color(0.95, 0.94, 0.92))
	
	lbl_titulo.add_theme_color_override("font_color", Color(0.9, 0.6, 0.2))
	
	_estilizar_botao(btn_quest1)
	_estilizar_botao(btn_quest2)
	_estilizar_botao(btn_cancel1, true)
	_estilizar_botao(btn_cancel2, true)
	_estilizar_botao(btn_fechar)
	
	_atualizar_quests()

func _estilizar_botao(btn: Button, e_cancelar: bool = false) -> void:
	var font_pixel = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf")
	if font_pixel:
		btn.add_theme_font_override("font", font_pixel)
	btn.add_theme_font_size_override("font_size", 14)
	
	var sb_normal = StyleBoxFlat.new()
	if e_cancelar:
		sb_normal.bg_color = Color(0.4, 0.1, 0.1, 1) # Vermelho escuro pro 'X'
	else:
		sb_normal.bg_color = Color(0.2, 0.15, 0.15, 1)
		
	sb_normal.border_width_bottom = 2
	sb_normal.border_color = Color(0.9, 0.6, 0.2)
	sb_normal.corner_radius_top_left = 6
	sb_normal.corner_radius_top_right = 6
	sb_normal.corner_radius_bottom_left = 6
	sb_normal.corner_radius_bottom_right = 6
	sb_normal.content_margin_left = 10
	sb_normal.content_margin_right = 10
	sb_normal.content_margin_top = 10
	sb_normal.content_margin_bottom = 10
	
	var sb_hover = sb_normal.duplicate()
	sb_hover.bg_color = Color(0.3, 0.2, 0.2, 1)
	
	var sb_disabled = sb_normal.duplicate()
	sb_disabled.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	sb_disabled.border_color = Color(0.3, 0.3, 0.3)
	
	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("disabled", sb_disabled)
	btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))

func _atualizar_quests() -> void:
	var q1 = PlayerStats.quests_concluidas.get("fisica_quest1", false)
	var q2 = PlayerStats.quests_concluidas.get("fisica_quest2", false)
	var ativa1 = PlayerStats.quests_ativas.get("fisica_quest1", false)
	var ativa2 = PlayerStats.quests_ativas.get("fisica_quest2", false)
	
	if q1 and q2:
		_definir_texto_dialogo("Obrigado por consertar minhas máquinas! O andar de Física agora está operando com 100% de eficiência. Você tem um futuro brilhante como engenheiro, garoto!")
	elif not ativa1 and not ativa2:
		_definir_texto_dialogo("As máquinas pifaram e os robôs estão fora de controle! Você pode me ajudar a consertar tudo? Aceite uma missão abaixo:")
	else:
		_definir_texto_dialogo("Estou calibrando os sensores... Me avise assim que reunir os 5 materiais de cada missão!")
		
	if q1:
		btn_quest1.text = "Quest Concluída"
		btn_quest1.disabled = true
		btn_cancel1.hide()
	elif not ativa1:
		btn_quest1.text = "Aceitar Missão: Coletar Baterias"
		btn_quest1.disabled = false
		btn_cancel1.hide()
	else:
		var qtd_baterias = _contar_item("Bateria Elétrica")
		btn_quest1.text = "Entregar Baterias Elétricas (" + str(qtd_baterias) + "/5)\nRecompensa: 50 Moedas"
		btn_quest1.disabled = (qtd_baterias < 5)
		btn_cancel1.show()

	if q2:
		btn_quest2.text = "Quest Concluída"
		btn_quest2.disabled = true
		btn_cancel2.hide()
	elif not ativa2:
		btn_quest2.text = "Aceitar Missão: Destruir Robôs"
		btn_quest2.disabled = false
		btn_cancel2.hide()
	else:
		var qtd_chips = _contar_item("Fragmento de Chip")
		btn_quest2.text = "Entregar Fragmentos de Chip (" + str(qtd_chips) + "/5)\nRecompensa: 50 Moedas"
		btn_quest2.disabled = (qtd_chips < 5)
		btn_cancel2.show()

func _cancelar_quest(quest_id: String) -> void:
	if PlayerStats.quests_ativas.has(quest_id):
		PlayerStats.quests_ativas[quest_id] = false
		PlayerStats.salvar()
		PlayerStats.quests_atualizadas.emit()
		_atualizar_quests()

func _contar_item(nome_item: String) -> int:
	var contagem = 0
	for item in PlayerStats.itens:
		if item["nome"] == nome_item:
			contagem += 1
	return contagem

func _remover_itens(nome_item: String, qtd: int) -> void:
	var removidos = 0
	# Remove de trás pra frente para não quebrar os índices
	for i in range(PlayerStats.itens.size() - 1, -1, -1):
		if PlayerStats.itens[i]["nome"] == nome_item:
			PlayerStats.itens.remove_at(i)
			removidos += 1
			if removidos >= qtd:
				break

func _tentar_entregar_quest1() -> void:
	if not PlayerStats.quests_ativas.get("fisica_quest1", false):
		PlayerStats.quests_ativas["fisica_quest1"] = true
		PlayerStats.salvar()
		PlayerStats.quests_atualizadas.emit()
		_atualizar_quests()
		return
		
	if not PlayerStats.quests_concluidas.get("fisica_quest1", false) and _contar_item("Bateria Elétrica") >= 5:
		_remover_itens("Bateria Elétrica", 5)
		PlayerStats.moedas += 50
		PlayerStats.quests_concluidas["fisica_quest1"] = true
		PlayerStats.quests_ativas["fisica_quest1"] = false
		PlayerStats.salvar()
		PlayerStats.quests_atualizadas.emit()
		_atualizar_quests()
		if not (PlayerStats.quests_concluidas.get("fisica_quest1", false) and PlayerStats.quests_concluidas.get("fisica_quest2", false)):
			_definir_texto_dialogo("Essas baterias estão carregadíssimas! Muito obrigado, vai ser perfeito para a máquina!")

func _tentar_entregar_quest2() -> void:
	if not PlayerStats.quests_ativas.get("fisica_quest2", false):
		PlayerStats.quests_ativas["fisica_quest2"] = true
		PlayerStats.salvar()
		PlayerStats.quests_atualizadas.emit()
		_atualizar_quests()
		return

	if not PlayerStats.quests_concluidas.get("fisica_quest2", false) and _contar_item("Fragmento de Chip") >= 5:
		_remover_itens("Fragmento de Chip", 5)
		PlayerStats.moedas += 50
		PlayerStats.quests_concluidas["fisica_quest2"] = true
		PlayerStats.quests_ativas["fisica_quest2"] = false
		PlayerStats.salvar()
		PlayerStats.quests_atualizadas.emit()
		_atualizar_quests()
		if not (PlayerStats.quests_concluidas.get("fisica_quest1", false) and PlayerStats.quests_concluidas.get("fisica_quest2", false)):
			_definir_texto_dialogo("Excelente! Com esses chips poderei reprogramar o sistema de segurança!")

var _tween_typewriter: Tween = null

func _definir_texto_dialogo(novo_texto: String) -> void:
	if lbl_desc == null: return
	if lbl_desc.text == novo_texto and lbl_desc.visible_ratio >= 0.99:
		return
		
	if _tween_typewriter and _tween_typewriter.is_running():
		_tween_typewriter.kill()
		
	lbl_desc.text = novo_texto
	lbl_desc.visible_ratio = 0.0
	
	var duracao = clamp(novo_texto.length() * 0.02, 0.45, 1.4)
	_tween_typewriter = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween_typewriter.tween_method(_atualizar_progresso_typewriter, 0.0, 1.0, duracao)

func _atualizar_progresso_typewriter(progresso: float) -> void:
	if lbl_desc:
		var total_chars = lbl_desc.text.length()
		var antigo_char = int(lbl_desc.visible_ratio * total_chars)
		var novo_char = int(progresso * total_chars)
		lbl_desc.visible_ratio = progresso
		
		if novo_char > antigo_char and novo_char % 3 == 0 and progresso < 0.96:
			if get_node_or_null("/root/AudioManager"):
				AudioManager.play_sfx("ui-1")

func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed) or event.is_action_pressed("interagir") or (event is InputEventKey and event.keycode == KEY_F and event.pressed):
		if _tween_typewriter and _tween_typewriter.is_running():
			_tween_typewriter.kill()
			if lbl_desc: lbl_desc.visible_ratio = 1.0
			get_viewport().set_input_as_handled()
			return
			
	if event.is_action_pressed("interagir") or (event is InputEventKey and event.keycode == KEY_F and event.pressed):
		get_viewport().set_input_as_handled()
		_fechar()

func _fechar() -> void:
	get_tree().paused = false
	var pai = get_parent()
	if pai and pai.has_method("_fechar_interface"):
		pai._fechar_interface()
	else:
		queue_free()

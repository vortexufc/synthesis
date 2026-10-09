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
	add_to_group("dialogo_ativo")
	add_to_group("interacao_ativa")
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
	style_panel.bg_color = Color(0.08, 0.13, 0.09, 0.95)
	style_panel.border_width_left = 3
	style_panel.border_width_right = 3
	style_panel.border_width_top = 3
	style_panel.border_width_bottom = 3
	style_panel.border_color = Color(0.25, 0.85, 0.45, 1.0) # Verde Esmeralda Botânico
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
	lbl_titulo.text = "Dra. Flora - Botânica Arcana"
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
	btn_cancel1.pressed.connect(func(): _cancelar_quest("biologia_quest1"))
	hbox1.add_child(btn_cancel1)
	
	var hbox2 = HBoxContainer.new()
	vbox.add_child(hbox2)
	
	btn_quest2 = Button.new()
	btn_quest2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_quest2.pressed.connect(_tentar_entregar_quest2)
	hbox2.add_child(btn_quest2)
	
	btn_cancel2 = Button.new()
	btn_cancel2.text = " X "
	btn_cancel2.pressed.connect(func(): _cancelar_quest("biologia_quest2"))
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
	lbl_desc.add_theme_color_override("font_color", Color(0.92, 0.95, 0.94))
	lbl_titulo.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5))
	
	_estilizar_botao(btn_quest1)
	_estilizar_botao(btn_quest2)
	_estilizar_botao(btn_cancel1, true)
	_estilizar_botao(btn_cancel2, true)
	_estilizar_botao(btn_fechar)
	
	_atualizar_quests()

func _estilizar_botao(btn: Button, e_cancelar: bool = false) -> void:
	var sf = SystemFont.new()
	sf.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	sf.font_weight = 600
	btn.add_theme_font_override("font", sf)
	btn.add_theme_font_size_override("font_size", 13)
	
	var sb_normal = StyleBoxFlat.new()
	if e_cancelar:
		sb_normal.bg_color = Color(0.4, 0.1, 0.1, 1) # Vermelho escuro pro 'X'
	else:
		sb_normal.bg_color = Color(0.12, 0.22, 0.15, 1)
		
	sb_normal.border_width_bottom = 2
	sb_normal.border_color = Color(0.3, 0.85, 0.45)
	sb_normal.corner_radius_top_left = 6
	sb_normal.corner_radius_top_right = 6
	sb_normal.corner_radius_bottom_left = 6
	sb_normal.corner_radius_bottom_right = 6
	sb_normal.content_margin_left = 10
	sb_normal.content_margin_right = 10
	sb_normal.content_margin_top = 10
	sb_normal.content_margin_bottom = 10
	
	var sb_hover = sb_normal.duplicate()
	sb_hover.bg_color = Color(0.18, 0.32, 0.22, 1)
	
	var sb_disabled = sb_normal.duplicate()
	sb_disabled.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	sb_disabled.border_color = Color(0.3, 0.3, 0.3)
	
	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("disabled", sb_disabled)
	btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))

func _obter_player_stats() -> Node:
	return get_node_or_null("/root/PlayerStats")

func _atualizar_quests() -> void:
	var ps = _obter_player_stats()
	if not ps: return
	
	var q1 = ps.quests_concluidas.get("biologia_quest1", false)
	var q2 = ps.quests_concluidas.get("biologia_quest2", false)
	var ativa1 = ps.quests_ativas.get("biologia_quest1", false)
	var ativa2 = ps.quests_ativas.get("biologia_quest2", false)
	
	if q1 and q2:
		var acabou_de_ganhar = false
		if ps.has_method("adicionar_codice_mural"):
			acabou_de_ganhar = ps.adicionar_codice_mural(
				"codice_biologia",
				"Tratado Botânico: Código Genético & DNA",
				3,
				"Tratado botânico arcano concedido pela Dra. Flora. Detalha a estrutura celular vegetal, dupla hélice de DNA e fotossíntese mágica para estudo e consulta a qualquer momento."
			)
		if acabou_de_ganhar:
			_definir_texto_dialogo("Maravilhoso! Graças a você com as flores raras e os chips de DNA, sintetizamos o antídoto e desvendamos os mistérios genéticos da estufa!\n\nComo recompensa suprema, entrego-lhe o TRATADO BOTÂNICO! Ele foi guardado no seu Grimório (Inventário) para você consultar a estrutura celular e DNA sempre que desejar!")
		else:
			_definir_texto_dialogo("Obrigada por coletar os materiais! Nossa pesquisa com a flora arcana está concluída. Consulte o Tratado Botânico no seu Grimório (Inventário) sempre que desejar revisar os conceitos de biologia!")
	elif not ativa1 and not ativa2:
		_definir_texto_dialogo("Os esporos da estufa corromperam os espécimes e as plantas! Preciso de amostras botânicas e sequências de DNA para formular o antídoto. Você pode me ajudar? Aceite uma missão abaixo:")
	else:
		_definir_texto_dialogo("Estou preparando os extratos e centrífugas... Me avise assim que conseguir os 5 materiais de cada missão!")
		
	if q1:
		btn_quest1.text = "Quest Concluída"
		btn_quest1.disabled = true
		btn_cancel1.hide()
	elif not ativa1:
		btn_quest1.text = "Aceitar Missão: Coletar Flores Raras"
		btn_quest1.disabled = false
		btn_cancel1.hide()
	else:
		var qtd_flores = _contar_item("Flor Rara")
		btn_quest1.text = "Entregar Flores Raras (" + str(qtd_flores) + "/5)\nRecompensa: 50 Moedas"
		btn_quest1.disabled = (qtd_flores < 5)
		btn_cancel1.show()

	if q2:
		btn_quest2.text = "Quest Concluída"
		btn_quest2.disabled = true
		btn_cancel2.hide()
	elif not ativa2:
		btn_quest2.text = "Aceitar Missão: Obter Chips de DNA"
		btn_quest2.disabled = false
		btn_cancel2.hide()
	else:
		var qtd_chips = _contar_item("Chip de DNA")
		btn_quest2.text = "Entregar Chips de DNA (" + str(qtd_chips) + "/5)\nRecompensa: 50 Moedas"
		btn_quest2.disabled = (qtd_chips < 5)
		btn_cancel2.show()

func _cancelar_quest(quest_id: String) -> void:
	var ps = _obter_player_stats()
	if ps and ps.quests_ativas.has(quest_id):
		ps.quests_ativas[quest_id] = false
		ps.salvar()
		ps.quests_atualizadas.emit()
		_atualizar_quests()

func _contar_item(nome_item: String) -> int:
	var contagem = 0
	var ps = _obter_player_stats()
	if not ps: return 0
	for item in ps.itens:
		if item["nome"] == nome_item:
			contagem += 1
	return contagem

func _tentar_entregar_quest1() -> void:
	var ps = _obter_player_stats()
	if not ps: return
	var ativa = ps.quests_ativas.get("biologia_quest1", false)
	if not ativa:
		ps.quests_ativas["biologia_quest1"] = true
		ps.salvar()
		ps.quests_atualizadas.emit()
		_atualizar_quests()
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("ui_1")
		return
		
	var qtd = _contar_item("Flor Rara")
	if qtd >= 5:
		_remover_itens("Flor Rara", 5)
		ps.quests_ativas["biologia_quest1"] = false
		ps.quests_concluidas["biologia_quest1"] = true
		ps.adicionar_moedas(50)
		ps.salvar()
		ps.quests_atualizadas.emit()
		_atualizar_quests()
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("correct")

func _tentar_entregar_quest2() -> void:
	var ps = _obter_player_stats()
	if not ps: return
	var ativa = ps.quests_ativas.get("biologia_quest2", false)
	if not ativa:
		ps.quests_ativas["biologia_quest2"] = true
		ps.salvar()
		ps.quests_atualizadas.emit()
		_atualizar_quests()
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("ui_1")
		return
		
	var qtd = _contar_item("Chip de DNA")
	if qtd >= 5:
		_remover_itens("Chip de DNA", 5)
		ps.quests_ativas["biologia_quest2"] = false
		ps.quests_concluidas["biologia_quest2"] = true
		ps.adicionar_moedas(50)
		ps.salvar()
		ps.quests_atualizadas.emit()
		_atualizar_quests()
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("correct")

func _remover_itens(nome_item: String, quantidade: int) -> void:
	var ps = _obter_player_stats()
	if not ps: return
	var removidos = 0
	var i = ps.itens.size() - 1
	while i >= 0 and removidos < quantidade:
		if ps.itens[i]["nome"] == nome_item:
			ps.itens.remove_at(i)
			removidos += 1
		i -= 1

func _definir_texto_dialogo(texto: String) -> void:
	lbl_desc.text = texto

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.keycode == KEY_F)):
		get_viewport().set_input_as_handled()
		_fechar()

func _fechar() -> void:
	get_tree().paused = false
	var tw = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(painel, "scale", Vector2(0.85, 0.85), 0.16)
	tw.tween_property(painel, "modulate:a", 0.0, 0.14)
	tw.tween_property(bg_rect, "modulate:a", 0.0, 0.14)
	tw.chain().tween_callback(func():
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("finalizar_interacao"):
			player.finalizar_interacao(0.4)
		queue_free()
	)

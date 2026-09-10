extends CanvasLayer

var panel: PanelContainer
var lbl_moedas: Label
var lbl_fala_mercador: Label = null
var _tween_fala: Tween = null

var _botoes_compra: Array = []
var _lbl_qtd_gel: Label = null
var _btn_vender_gel: Button = null
var _lbl_qtd_chip: Label = null
var _btn_vender_chip: Button = null

var tex_pocao = preload("res://assets/sprites/vida.png")
var tex_pergaminho = preload("res://assets/sprites/pergaminho.png")
var tex_moeda = preload("res://assets/sprites/ui/coin.png")
var tex_gelatina = preload("res://assets/sprites/ui/item_fragmento_gelatina.png")
var tex_chip = preload("res://assets/sprites/ui/item_chip.png")

var itens_loja = [
	{
		"nome": "Poção Grande",
		"desc": "Restaura 50 Pontos de Vida (PV).",
		"preco": 10,
		"tipo": "pocao"
	},
	{
		"nome": "Poção Menor",
		"desc": "Restaura 20 Pontos de Vida (PV).",
		"preco": 5,
		"tipo": "pocao_menor"
	},
	{
		"nome": "Pergaminho Misterioso",
		"desc": "Um trecho perdido da história antiga de Synthesis.",
		"preco": 50,
		"tipo": "lore"
	}
]

func _ready() -> void:
	name = "LojaUI"
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Fundo escurecido translúcido
	var bg_rect = ColorRect.new()
	bg_rect.color = Color(0, 0, 0, 0.72)
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_rect)
	
	# Painel principal da Loja com margens confortáveis e moldura dourada
	panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.12, 0.96)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.85, 0.65, 0.22, 1.0)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.shadow_color = Color(0, 0, 0, 0.85)
	style.shadow_size = 20
	
	# Margens internas generosas para que nenhum texto encoste na borda
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", style)
	
	panel.custom_minimum_size = Vector2(560, 530)
	var vp_size = get_viewport().get_visible_rect().size
	panel.position = (vp_size - panel.custom_minimum_size) * 0.5
	panel.pivot_offset = panel.custom_minimum_size * 0.5
	add_child(panel)
	
	# Animação suave de abertura
	panel.scale = Vector2(0.90, 0.90)
	panel.modulate.a = 0.0
	var tw_open = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_open.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.24)
	tw_open.tween_property(panel, "modulate:a", 1.0, 0.20)
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui_5")
	
	var font_pixel = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	var font_num = SystemFont.new()
	font_num.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_num.font_weight = 700
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	
	# ===== 1. HEADER (TÍTULO E BADGE DE MOEDAS) =====
	var header_box = HBoxContainer.new()
	header_box.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var lbl_titulo = Label.new()
	lbl_titulo.text = "Mercador"
	if font_pixel: lbl_titulo.add_theme_font_override("font", font_pixel)
	lbl_titulo.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	lbl_titulo.add_theme_font_size_override("font_size", 22)
	header_box.add_child(lbl_titulo)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_box.add_child(spacer)
	
	# Badge de moedas com ícone real
	var coin_badge = PanelContainer.new()
	var sb_coin = StyleBoxFlat.new()
	sb_coin.bg_color = Color(0.16, 0.13, 0.08, 0.95)
	sb_coin.border_color = Color(0.9, 0.75, 0.25, 0.9)
	sb_coin.set_border_width_all(1)
	sb_coin.set_corner_radius_all(6)
	sb_coin.content_margin_left = 10
	sb_coin.content_margin_right = 12
	sb_coin.content_margin_top = 4
	sb_coin.content_margin_bottom = 4
	coin_badge.add_theme_stylebox_override("panel", sb_coin)
	
	var coin_hbox = HBoxContainer.new()
	coin_hbox.add_theme_constant_override("separation", 6)
	
	var coin_icon = TextureRect.new()
	coin_icon.texture = tex_moeda
	coin_icon.custom_minimum_size = Vector2(16, 16)
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_hbox.add_child(coin_icon)
	
	lbl_moedas = Label.new()
	lbl_moedas.add_theme_font_override("font", font_num)
	lbl_moedas.add_theme_font_size_override("font_size", 14)
	lbl_moedas.add_theme_color_override("font_color", Color(1.0, 0.92, 0.5))
	coin_hbox.add_child(lbl_moedas)
	
	coin_badge.add_child(coin_hbox)
	header_box.add_child(coin_badge)
	vbox.add_child(header_box)
	
	# ===== 2. FALA DO MERCADOR (BALÃO ESTILIZADO) =====
	var balao_panel = PanelContainer.new()
	var sb_balao = StyleBoxFlat.new()
	sb_balao.bg_color = Color(0.04, 0.04, 0.07, 0.75)
	sb_balao.border_color = Color(0.35, 0.32, 0.45, 0.45)
	sb_balao.set_border_width_all(1)
	sb_balao.set_corner_radius_all(6)
	sb_balao.content_margin_left = 12
	sb_balao.content_margin_right = 12
	sb_balao.content_margin_top = 8
	sb_balao.content_margin_bottom = 8
	balao_panel.add_theme_stylebox_override("panel", sb_balao)
	
	lbl_fala_mercador = Label.new()
	lbl_fala_mercador.autowrap_mode = TextServer.AUTOWRAP_WORD
	if font_pixel: lbl_fala_mercador.add_theme_font_override("font", font_pixel)
	lbl_fala_mercador.add_theme_font_size_override("font_size", 13)
	lbl_fala_mercador.add_theme_color_override("font_color", Color(0.92, 0.94, 0.96))
	balao_panel.add_child(lbl_fala_mercador)
	vbox.add_child(balao_panel)
	
	_iniciar_fala_mercador("Bem-vindo à minha humilde banca! Tenho poções frescas e pago moedas de ouro por sucatas e fragmentos.")
	
	# ===== 3. SEÇÃO: PRODUTOS À VENDA =====
	var lbl_sec_comprar = Label.new()
	lbl_sec_comprar.text = "PRODUTOS DA BANCA"
	lbl_sec_comprar.add_theme_font_override("font", font_num)
	lbl_sec_comprar.add_theme_font_size_override("font_size", 11)
	lbl_sec_comprar.add_theme_color_override("font_color", Color(0.85, 0.72, 0.35, 0.95))
	vbox.add_child(lbl_sec_comprar)
	
	for item in itens_loja:
		var card_item = PanelContainer.new()
		var sb_item = StyleBoxFlat.new()
		sb_item.bg_color = Color(0.12, 0.10, 0.17, 0.55)
		sb_item.border_color = Color(0.28, 0.24, 0.36, 0.45)
		sb_item.set_border_width_all(1)
		sb_item.set_corner_radius_all(6)
		sb_item.content_margin_left = 12
		sb_item.content_margin_right = 10
		sb_item.content_margin_top = 6
		sb_item.content_margin_bottom = 6
		card_item.add_theme_stylebox_override("panel", sb_item)
		
		var hbox = HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", 12)
		
		# Ícone
		var icone = TextureRect.new()
		if item["tipo"] == "pocao" or item["tipo"] == "pocao_menor":
			icone.texture = tex_pocao
		else:
			icone.texture = tex_pergaminho
		icone.custom_minimum_size = Vector2(28, 28)
		icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(icone)
		
		# Informações
		var info_box = VBoxContainer.new()
		info_box.add_theme_constant_override("separation", 1)
		var l_nome = Label.new()
		l_nome.text = item["nome"]
		l_nome.add_theme_font_override("font", font_num)
		l_nome.add_theme_font_size_override("font_size", 14)
		l_nome.add_theme_color_override("font_color", Color(0.96, 0.96, 0.98))
		
		var l_desc = Label.new()
		l_desc.text = item["desc"]
		l_desc.add_theme_font_override("font", font_num)
		l_desc.add_theme_font_size_override("font_size", 11)
		l_desc.add_theme_color_override("font_color", Color(0.68, 0.72, 0.78))
		info_box.add_child(l_nome)
		info_box.add_child(l_desc)
		hbox.add_child(info_box)
		
		var item_spacer = Control.new()
		item_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(item_spacer)
		
		# Botão de compra estilizado
		var btn_comprar = Button.new()
		btn_comprar.text = "Comprar (" + str(item["preco"]) + " 🪙)"
		btn_comprar.add_theme_font_override("font", font_num)
		btn_comprar.add_theme_font_size_override("font_size", 12)
		_estilizar_botao_compra(btn_comprar)
		btn_comprar.pressed.connect(func(): _comprar(item))
		hbox.add_child(btn_comprar)
		
		_botoes_compra.append({"btn": btn_comprar, "preco": item["preco"]})
		
		card_item.add_child(hbox)
		vbox.add_child(card_item)
		
	# ===== 4. SEÇÃO: VENDER SUCATAS =====
	var lbl_sec_vender = Label.new()
	lbl_sec_vender.text = "RECICLAR SUCATA (10 UNIDADES = 10 MOEDAS)"
	lbl_sec_vender.add_theme_font_override("font", font_num)
	lbl_sec_vender.add_theme_font_size_override("font_size", 11)
	lbl_sec_vender.add_theme_color_override("font_color", Color(0.35, 0.85, 0.55, 0.95))
	vbox.add_child(lbl_sec_vender)
	
	# Card Gelatina
	var card_gel = _criar_card_venda(
		tex_gelatina, 
		"Fragmento de Gelatina", 
		func(): _vender_sucata("Fragmento de Gelatina", 10, 10),
		font_num
	)
	_lbl_qtd_gel = card_gel["lbl_qtd"]
	_btn_vender_gel = card_gel["btn"]
	vbox.add_child(card_gel["card"])
	
	# Card Chip
	var card_chip = _criar_card_venda(
		tex_chip, 
		"Fragmento de Chip", 
		func(): _vender_sucata("Fragmento de Chip", 10, 10),
		font_num
	)
	_lbl_qtd_chip = card_chip["lbl_qtd"]
	_btn_vender_chip = card_chip["btn"]
	vbox.add_child(card_chip["card"])
	
	# ===== 5. FOOTER (FECHAR LOJA) =====
	var btn_fechar = Button.new()
	btn_fechar.text = "[ F ]  Fechar Loja"
	btn_fechar.add_theme_font_override("font", font_num)
	btn_fechar.add_theme_font_size_override("font_size", 13)
	_estilizar_botao_fechar(btn_fechar)
	btn_fechar.pressed.connect(func(): queue_free())
	vbox.add_child(btn_fechar)
	
	# Atualiza o estado dos botões e o texto das moedas
	_atualizar_todos_botoes()
	
	# Centraliza na tela
	panel.reset_size()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

func _criar_card_venda(icone_tex: Texture2D, nome_item: String, callback: Callable, font: Font) -> Dictionary:
	var card = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.12, 0.15, 0.55)
	sb.border_color = Color(0.24, 0.32, 0.28, 0.45)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	card.add_theme_stylebox_override("panel", sb)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 12)
	
	var ico = TextureRect.new()
	ico.texture = icone_tex
	ico.custom_minimum_size = Vector2(26, 26)
	ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(ico)
	
	var info_box = VBoxContainer.new()
	info_box.add_theme_constant_override("separation", 1)
	var l_nome = Label.new()
	l_nome.text = nome_item
	l_nome.add_theme_font_override("font", font)
	l_nome.add_theme_font_size_override("font_size", 13)
	l_nome.add_theme_color_override("font_color", Color(0.92, 0.95, 0.96))
	
	var lbl_qtd = Label.new()
	lbl_qtd.add_theme_font_override("font", font)
	lbl_qtd.add_theme_font_size_override("font_size", 11)
	lbl_qtd.add_theme_color_override("font_color", Color(0.60, 0.78, 0.70))
	info_box.add_child(l_nome)
	info_box.add_child(lbl_qtd)
	hbox.add_child(info_box)
	
	var sp = Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(sp)
	
	var btn = Button.new()
	btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", 12)
	_estilizar_botao_venda(btn)
	btn.pressed.connect(callback)
	hbox.add_child(btn)
	
	card.add_child(hbox)
	return {"card": card, "lbl_qtd": lbl_qtd, "btn": btn}

func _estilizar_botao_compra(btn: Button) -> void:
	var sb_normal = StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.18, 0.15, 0.10, 0.9)
	sb_normal.border_color = Color(0.85, 0.65, 0.25, 0.9)
	sb_normal.set_border_width_all(1)
	sb_normal.set_corner_radius_all(4)
	sb_normal.content_margin_left = 12
	sb_normal.content_margin_right = 12
	sb_normal.content_margin_top = 5
	sb_normal.content_margin_bottom = 5
	
	var sb_hover = sb_normal.duplicate() as StyleBoxFlat
	sb_hover.bg_color = Color(0.28, 0.22, 0.12, 1.0)
	sb_hover.border_color = Color(1.0, 0.85, 0.35, 1.0)
	
	var sb_disabled = sb_normal.duplicate() as StyleBoxFlat
	sb_disabled.bg_color = Color(0.10, 0.10, 0.12, 0.5)
	sb_disabled.border_color = Color(0.30, 0.28, 0.32, 0.4)
	
	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_hover)
	btn.add_theme_stylebox_override("disabled", sb_disabled)
	btn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.6))
	btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))

func _estilizar_botao_venda(btn: Button) -> void:
	var sb_normal = StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.10, 0.18, 0.14, 0.9)
	sb_normal.border_color = Color(0.25, 0.85, 0.50, 0.9)
	sb_normal.set_border_width_all(1)
	sb_normal.set_corner_radius_all(4)
	sb_normal.content_margin_left = 12
	sb_normal.content_margin_right = 12
	sb_normal.content_margin_top = 5
	sb_normal.content_margin_bottom = 5
	
	var sb_hover = sb_normal.duplicate() as StyleBoxFlat
	sb_hover.bg_color = Color(0.14, 0.26, 0.18, 1.0)
	sb_hover.border_color = Color(0.40, 1.0, 0.65, 1.0)
	
	var sb_disabled = sb_normal.duplicate() as StyleBoxFlat
	sb_disabled.bg_color = Color(0.10, 0.10, 0.12, 0.5)
	sb_disabled.border_color = Color(0.30, 0.28, 0.32, 0.4)
	
	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_hover)
	btn.add_theme_stylebox_override("disabled", sb_disabled)
	btn.add_theme_color_override("font_color", Color(0.4, 1.0, 0.65))
	btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))

func _estilizar_botao_fechar(btn: Button) -> void:
	var sb_normal = StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.12, 0.10, 0.16, 0.85)
	sb_normal.border_color = Color(0.38, 0.35, 0.48, 0.6)
	sb_normal.set_border_width_all(1)
	sb_normal.set_corner_radius_all(6)
	sb_normal.content_margin_top = 8
	sb_normal.content_margin_bottom = 8
	
	var sb_hover = sb_normal.duplicate() as StyleBoxFlat
	sb_hover.bg_color = Color(0.20, 0.16, 0.26, 1.0)
	sb_hover.border_color = Color(0.85, 0.65, 0.25, 0.8)
	
	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_hover)
	btn.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.6))

func _atualizar_moedas() -> void:
	if get_node_or_null("/root/PlayerStats") and lbl_moedas:
		lbl_moedas.text = str(PlayerStats.moedas) + " Moedas"

func _atualizar_todos_botoes() -> void:
	_atualizar_moedas()
	
	var moedas_atuais = PlayerStats.moedas if get_node_or_null("/root/PlayerStats") else 0
	for item_info in _botoes_compra:
		var btn = item_info["btn"] as Button
		var preco = item_info["preco"] as int
		btn.disabled = (moedas_atuais < preco)
		
	var qtd_gel = _contar_item("Fragmento de Gelatina")
	if _lbl_qtd_gel:
		_lbl_qtd_gel.text = "Possui: " + str(qtd_gel) + " un. (Requer 10)"
	if _btn_vender_gel:
		if qtd_gel >= 10:
			_btn_vender_gel.disabled = false
			_btn_vender_gel.text = "Vender (+10 🪙)"
		else:
			_btn_vender_gel.disabled = true
			_btn_vender_gel.text = "Precisa de 10"
			
	var qtd_chip = _contar_item("Fragmento de Chip")
	if _lbl_qtd_chip:
		_lbl_qtd_chip.text = "Possui: " + str(qtd_chip) + " un. (Requer 10)"
	if _btn_vender_chip:
		if qtd_chip >= 10:
			_btn_vender_chip.disabled = false
			_btn_vender_chip.text = "Vender (+10 🪙)"
		else:
			_btn_vender_chip.disabled = true
			_btn_vender_chip.text = "Precisa de 10"

func _comprar(item: Dictionary) -> void:
	if not get_node_or_null("/root/PlayerStats"): return
	
	if PlayerStats.moedas >= item["preco"]:
		PlayerStats.moedas -= item["preco"]
		_entregar_item(item)
		PlayerStats.salvar()
		_atualizar_todos_botoes()
		
		_iniciar_fala_mercador("Excelente escolha! Guarde bem esse " + item["nome"] + ".")
		
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("mostrar_mensagem"):
			hud.mostrar_mensagem("Comprado: " + item["nome"] + " (-" + str(item["preco"]) + " Moedas)")
		
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("ui_5")
	else:
		_iniciar_fala_mercador("Moedas insuficientes, amigo! Derrote monstros ou me traga sucatas para conseguir mais.")
		if lbl_moedas:
			lbl_moedas.modulate = Color(1, 0.3, 0.3)
			var t = create_tween()
			t.tween_property(lbl_moedas, "modulate", Color(1, 1, 1), 0.5)

func _contar_item(nome_item: String) -> int:
	if not get_node_or_null("/root/PlayerStats"): return 0
	var contagem = 0
	for item in PlayerStats.itens:
		if item["nome"] == nome_item:
			contagem += 1
	return contagem

func _vender_sucata(nome_item: String, qtd_necessaria: int, recompensa: int) -> void:
	if not get_node_or_null("/root/PlayerStats"): return
	
	var qtd_atual = _contar_item(nome_item)
	if qtd_atual >= qtd_necessaria:
		var removidos = 0
		var i = PlayerStats.itens.size() - 1
		while i >= 0 and removidos < qtd_necessaria:
			if PlayerStats.itens[i]["nome"] == nome_item:
				PlayerStats.itens.remove_at(i)
				removidos += 1
			i -= 1
			
		PlayerStats.moedas += recompensa
		PlayerStats.salvar()
		_atualizar_todos_botoes()
		
		_iniciar_fala_mercador("Negócio fechado! +" + str(recompensa) + " Moedas de ouro na sua algibeira.")
		
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("mostrar_mensagem"):
			hud.mostrar_mensagem("Vendido: " + nome_item + " (+" + str(recompensa) + " Moedas)")
			
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("ui_5")
	else:
		_iniciar_fala_mercador("Você não tem " + str(qtd_necessaria) + " " + nome_item + " para me vender!")
		if lbl_moedas:
			lbl_moedas.modulate = Color(1, 0.3, 0.3)
			var t = create_tween()
			t.tween_property(lbl_moedas, "modulate", Color(1, 1, 1), 0.5)

func _iniciar_fala_mercador(texto: String) -> void:
	if lbl_fala_mercador == null: return
	if _tween_fala and _tween_fala.is_running():
		_tween_fala.kill()
		
	lbl_fala_mercador.text = texto
	lbl_fala_mercador.visible_ratio = 0.0
	
	var duracao = clamp(texto.length() * 0.02, 0.45, 1.3)
	_tween_fala = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween_fala.tween_method(func(prog: float):
		if lbl_fala_mercador:
			var total_chars = lbl_fala_mercador.text.length()
			var antigo = int(lbl_fala_mercador.visible_ratio * total_chars)
			var novo = int(prog * total_chars)
			lbl_fala_mercador.visible_ratio = prog
			if novo > antigo and novo % 3 == 0 and prog < 0.96:
				if get_node_or_null("/root/AudioManager"):
					AudioManager.play_sfx("ui-1")
	, 0.0, 1.0, duracao)

func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed) or event.is_action_pressed("interagir") or (event is InputEventKey and event.keycode == KEY_F and event.pressed):
		if _tween_fala and _tween_fala.is_running():
			_tween_fala.kill()
			if lbl_fala_mercador: lbl_fala_mercador.visible_ratio = 1.0
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("interagir") or (event is InputEventKey and event.keycode == KEY_F and event.pressed) or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed):
		get_viewport().set_input_as_handled()
		queue_free()

func _entregar_item(item: Dictionary) -> void:
	if item["tipo"] == "pocao":
		var tem = false
		for p in PlayerStats.pocoes:
			if p["nome"] == "Poção Grande":
				p["qtd"] += 1
				tem = true
				break
		if not tem:
			PlayerStats.pocoes.append({"nome": "Poção Grande", "qtd": 1, "cura": 50, "desc": "Cura 50 HP"})
	
	elif item["tipo"] == "pocao_menor":
		var tem = false
		for p in PlayerStats.pocoes:
			if p["nome"] == "Poção Menor":
				p["qtd"] += 1
				tem = true
				break
		if not tem:
			PlayerStats.pocoes.append({"nome": "Poção Menor", "qtd": 1, "cura": 20, "desc": "Cura 20 HP"})
			
	elif item["tipo"] == "lore":
		var id = randi() % 100
		PlayerStats.adicionar_pergaminho("Conto Perdido #" + str(id), ["Este pergaminho relata histórias antigas sobre os fundadores de Synthesis..."])

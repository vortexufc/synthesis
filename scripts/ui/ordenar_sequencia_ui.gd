extends CanvasLayer

# minigame de ordenar sequencia

signal sequencia_concluida(sucesso: bool)

# sequencias por materia
const SEQUENCIAS = {
	"quimica": [
		{
			"titulo": "Destilação Alquímica Fracionada",
			"descricao": "Ordene os passos para separar os componentes de uma mistura líquida:",
			"passos": [
				{"id": 1, "texto": "Aquecer a mistura até o ponto de ebulição do componente mais volátil.", "icone": "🔥"},
				{"id": 2, "texto": "Conduzir os vapores através do condensador resfriado por água.", "icone": "⚗️"},
				{"id": 3, "texto": "Recolher o líquido destilado e purificado no frasco coletor final.", "icone": "🧪"}
			]
		},
		{
			"titulo": "Reação de Neutralização",
			"descricao": "Ordene as etapas da reação entre um ácido e uma base:",
			"passos": [
				{"id": 1, "texto": "Misturar a solução aquosa de ácido (HCl) com uma base forte (NaOH).", "icone": "🧪"},
				{"id": 2, "texto": "Ocorrer a reação exotérmica entre H⁺ e OH⁻ gerando água e calor.", "icone": "⚡"},
				{"id": 3, "texto": "Evaporar a água restante para cristalizar o sal puro (NaCl).", "icone": "✨"}
			]
		},
		{
			"titulo": "Síntese de Cristais Alquímicos",
			"descricao": "Ordene o processo de precipitação e cristalização de substâncias:",
			"passos": [
				{"id": 1, "texto": "Dissolver o soluto até a saturação completa em solvente fervente.", "icone": "🌡️"},
				{"id": 2, "texto": "Resfriar lentamente a solução em repouso absoluto.", "icone": "❄️"},
				{"id": 3, "texto": "Separar a rede cristalina sólida pura através de filtração.", "icone": "💎"}
			]
		},
		{
			"titulo": "Ciclo das Mudanças de Estado",
			"descricao": "Ordene a transformação física da água do estado sólido ao gasoso:",
			"passos": [
				{"id": 1, "texto": "Gelo sólido com moléculas organizadas em retículo cristalino rígido.", "icone": "🧊"},
				{"id": 2, "texto": "Fusão em água líquida fluida com o aumento da energia térmica.", "icone": "💧"},
				{"id": 3, "texto": "Ebulição a 100°C rompendo forças intermoleculares e gerando vapor.", "icone": "💨"}
			]
		},
		{
			"titulo": "Separação por Decantação",
			"descricao": "Ordene o método para separar líquidos de densidades diferentes:",
			"passos": [
				{"id": 1, "texto": "Despejar a mistura imiscível (água e óleo) no funil de decantação.", "icone": "🧪"},
				{"id": 2, "texto": "Aguardar o repouso para que a fase mais densa sedimente no fundo.", "icone": "⏳"},
				{"id": 3, "texto": "Abrir a torneira inferior e recolher a fase mais densa isolada.", "icone": "💧"}
			]
		}
	],
	"fisica": [
		{
			"titulo": "2ª Lei de Newton (Causa e Efeito)",
			"descricao": "Ordene a cadeia de fenômenos do movimento acelerado (F = m · a):",
			"passos": [
				{"id": 1, "texto": "Aplicar uma força resultante não-nula sobre a massa de um corpo.", "icone": "💪"},
				{"id": 2, "texto": "O corpo adquire aceleração constante na mesma direção da força.", "icone": "🚀"},
				{"id": 3, "texto": "A velocidade aumenta continuamente elevando sua energia cinética.", "icone": "⚡"}
			]
		},
		{
			"titulo": "Circuito Elétrico Fechado",
			"descricao": "Ordene o funcionamento de uma lâmpada ao ligar o interruptor:",
			"passos": [
				{"id": 1, "texto": "Fechar a chave do circuito conectando condutores aos pólos da pilha.", "icone": "🔌"},
				{"id": 2, "texto": "Diferença de potencial estabelece campo e corrente de elétrons.", "icone": "⚡"},
				{"id": 3, "texto": "Elétrons colidem no filamento emitindo luz e calor (Efeito Joule).", "icone": "💡"}
			]
		},
		{
			"titulo": "Propagação da Onda Sonora",
			"descricao": "Ordene as etapas da física acústica do som no ar até a audição:",
			"passos": [
				{"id": 1, "texto": "Uma fonte vibratória perturba as moléculas de ar ao seu redor.", "icone": "🔔"},
				{"id": 2, "texto": "Onda mecânica longitudinal propaga zonas de compressão no ar.", "icone": "〰️"},
				{"id": 3, "texto": "Vibração mecânica atinge o tímpano do ouvinte gerando sinal sonoro.", "icone": "👂"}
			]
		},
		{
			"titulo": "Conservação da Energia Mecânica",
			"descricao": "Ordene a transformação da energia durante a queda livre de um objeto:",
			"passos": [
				{"id": 1, "texto": "Corpo posicionado em grande altura acumulando energia potencial máxima.", "icone": "⛰️"},
				{"id": 2, "texto": "Queda acelerada pela gravidade convertendo altura em velocidade.", "icone": "📉"},
				{"id": 3, "texto": "Toda a energia potencial é transformada em energia cinética no solo.", "icone": "💥"}
			]
		},
		{
			"titulo": "Decomposição Óptica da Luz",
			"descricao": "Ordene o fenômeno da refração da luz através de um prisma de vidro:",
			"passos": [
				{"id": 1, "texto": "Feixe de luz branca policromática incide na face do prisma.", "icone": "☀️"},
				{"id": 2, "texto": "Ao entrar no vidro, a velocidade de cada cor diminui de modo desigual.", "icone": "📐"},
				{"id": 3, "texto": "Cores desviam em ângulos distintos emergindo o arco-íris visível.", "icone": "🌈"}
			]
		}
	],
	"geral": [
		{
			"titulo": "Ciclo da Fotossíntese",
			"descricao": "Ordene as etapas da produção vegetal de energia orgânica:",
			"passos": [
				{"id": 1, "texto": "Cloroplastos absorvem fótons de luz solar, dióxido de carbono e água.", "icone": "☀️"},
				{"id": 2, "texto": "A clorofila canaliza as reações químicas que quebram as moléculas de água.", "icone": "🌿"},
				{"id": 3, "texto": "Síntese de moléculas de glicose nutritiva e liberação de gás O₂.", "icone": "🍃"}
			]
		},
		{
			"titulo": "Método Científico Alquímico",
			"descricao": "Ordene as etapas da investigação e comprovação experimental:",
			"passos": [
				{"id": 1, "texto": "Observar atentamente um fenômeno natural intrigante e fazer perguntas.", "icone": "🔍"},
				{"id": 2, "texto": "Formular hipóteses testáveis e realizar experimentos em laboratório.", "icone": "📝"},
				{"id": 3, "texto": "Analisar dados empíricos, validar a tese e enunciar a lei científica.", "icone": "📚"}
			]
		}
	]
}

var _tema_atual: String = "quimica"
var _sequencia_atual: Dictionary = {}
var _cards_ordenados: Array = []
var _card_selecionado_idx: int = -1
var _resolvido: bool = false

# referencias da tela
var _painel_central: PanelContainer
var _lbl_titulo: Label
var _lbl_descricao: Label
var _lbl_status: Label
var _hbox_cards: HBoxContainer
var _btn_verificar: Button
var _card_nodes: Array = []

func _ready() -> void:
	add_to_group("minigame_ativo")
	layer = 105
	process_mode = Node.PROCESS_MODE_ALWAYS
	_construir_ui()

func iniciar_minigame(tema: String = "auto") -> void:
	var p = get_tree().get_first_node_in_group("player")
	if p:
		p.travado = true
		p.em_interacao = true

	if tema == "auto" or tema == "":
		tema = "quimica"
	if not SEQUENCIAS.has(tema):
		tema = "geral"
	_tema_atual = tema
	
	var lista = SEQUENCIAS[_tema_atual]
	_sequencia_atual = lista[randi() % lista.size()]
	
	# embaralha os passos
	var passos = _sequencia_atual["passos"].duplicate(true)
	var tentativas = 0
	while tentativas < 20:
		passos.shuffle()
		if not _esta_na_ordem(passos):
			break
		tentativas += 1
		
	_cards_ordenados = passos
	_card_selecionado_idx = -1
	_resolvido = false
	
	_atualizar_textos_e_cards()

func _esta_na_ordem(lista: Array) -> bool:
	if lista.size() != 3:
		return false
	return lista[0]["id"] == 1 and lista[1]["id"] == 2 and lista[2]["id"] == 3

func _construir_ui() -> void:
	# fundo escuro
	var backdrop = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.04, 0.04, 0.07, 0.88)
	add_child(backdrop)
	
	# container central
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	# painel principal
	_painel_central = PanelContainer.new()
	_painel_central.custom_minimum_size = Vector2(900, 520)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.12, 0.98) # Grafite arcano escuro
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.border_color = Color(0.95, 0.78, 0.25, 1.0) # Dourado alquímico
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 22
	sb.content_margin_bottom = 22
	sb.shadow_color = Color(0.95, 0.78, 0.25, 0.25)
	sb.shadow_size = 24
	_painel_central.add_theme_stylebox_override("panel", sb)
	center.add_child(_painel_central)
	
	var vbox_principal = VBoxContainer.new()
	vbox_principal.add_theme_constant_override("separation", 16)
	vbox_principal.alignment = BoxContainer.ALIGNMENT_CENTER
	_painel_central.add_child(vbox_principal)
	
	# titulo e botao fechar
	var hbox_top = HBoxContainer.new()
	vbox_principal.add_child(hbox_top)
	
	var vbox_header = VBoxContainer.new()
	vbox_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_header.add_theme_constant_override("separation", 4)
	hbox_top.add_child(vbox_header)
	
	var lbl_tag = Label.new()
	lbl_tag.text = "✦ SELO RÚNICO DO PORTÃO ANCESTRAL ✦"
	lbl_tag.add_theme_font_size_override("font_size", 13)
	lbl_tag.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	_aplicar_fonte_pixel(lbl_tag)
	vbox_header.add_child(lbl_tag)
	
	_lbl_titulo = Label.new()
	_lbl_titulo.text = "ORDENE A SEQUÊNCIA"
	_lbl_titulo.add_theme_font_size_override("font_size", 22)
	_lbl_titulo.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_aplicar_fonte_pixel(_lbl_titulo)
	vbox_header.add_child(_lbl_titulo)
	
	_lbl_descricao = Label.new()
	_lbl_descricao.text = "Coloque os 3 passos na ordem cronológica correta (1 → 2 → 3) para liberar a passagem."
	_lbl_descricao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_descricao.add_theme_font_size_override("font_size", 14)
	_lbl_descricao.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	vbox_header.add_child(_lbl_descricao)
	
	# botao fechar
	var btn_fechar = Button.new()
	btn_fechar.text = " ✕ "
	btn_fechar.custom_minimum_size = Vector2(36, 36)
	btn_fechar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_fechar.pressed.connect(_on_fechar_clicado)
	_aplicar_estilo_botao_secundario(btn_fechar)
	hbox_top.add_child(btn_fechar)
	
	# separador
	var sep = HSeparator.new()
	var sep_style = StyleBoxLine.new()
	sep_style.color = Color(0.95, 0.78, 0.25, 0.4)
	sep_style.thickness = 1
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox_principal.add_child(sep)
	
	# linha dos 3 cards
	_hbox_cards = HBoxContainer.new()
	_hbox_cards.add_theme_constant_override("separation", 20)
	_hbox_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	_hbox_cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hbox_cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox_principal.add_child(_hbox_cards)
	
	# texto de instrucao
	_lbl_status = Label.new()
	_lbl_status.text = "💡 Clique em um card e depois em outro para trocar, ou use as setas [ ◀ ] [ ▶ ]."
	_lbl_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_status.add_theme_font_size_override("font_size", 13)
	_lbl_status.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	vbox_principal.add_child(_lbl_status)
	
	# rodape com botao
	var hbox_acoes = HBoxContainer.new()
	hbox_acoes.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_acoes.add_theme_constant_override("separation", 24)
	vbox_principal.add_child(hbox_acoes)
	
	_btn_verificar = Button.new()
	_btn_verificar.text = "✦ VERIFICAR E QUEBRAR SELO ✦"
	_btn_verificar.custom_minimum_size = Vector2(300, 48)
	_btn_verificar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_btn_verificar.pressed.connect(_on_verificar_clicado)
	_aplicar_estilo_botao_dourado(_btn_verificar)
	_aplicar_fonte_pixel(_btn_verificar)
	hbox_acoes.add_child(_btn_verificar)
	
	var btn_desistir = Button.new()
	btn_desistir.text = "Voltar à Sala"
	btn_desistir.custom_minimum_size = Vector2(160, 48)
	btn_desistir.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_desistir.pressed.connect(_on_fechar_clicado)
	_aplicar_estilo_botao_secundario(btn_desistir)
	hbox_acoes.add_child(btn_desistir)

func _atualizar_textos_e_cards() -> void:
	if _sequencia_atual.has("titulo"):
		_lbl_titulo.text = str(_sequencia_atual["titulo"]).to_upper()
	if _sequencia_atual.has("descricao"):
		_lbl_descricao.text = str(_sequencia_atual["descricao"])
		
	# limpa cards antigos
	for child in _hbox_cards.get_children():
		child.queue_free()
	_card_nodes.clear()
	
	# cria os 3 cards
	for i in range(_cards_ordenados.size()):
		var dado_card = _cards_ordenados[i]
		var card_widget = _criar_widget_card(i, dado_card)
		_hbox_cards.add_child(card_widget)
		_card_nodes.append(card_widget)

func _criar_widget_card(pos_idx: int, dado: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(260, 240)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var eh_selecionado = (pos_idx == _card_selecionado_idx)
	_aplicar_estilo_card(card, eh_selecionado, false)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)
	
	# numero da posicao
	var pnl_badge = PanelContainer.new()
	var sb_badge = StyleBoxFlat.new()
	sb_badge.bg_color = Color(0.18, 0.22, 0.35, 0.95) if not eh_selecionado else Color(0.2, 0.6, 0.8, 0.95)
	sb_badge.set_corner_radius_all(6)
	sb_badge.content_margin_left = 8
	sb_badge.content_margin_right = 8
	sb_badge.content_margin_top = 4
	sb_badge.content_margin_bottom = 4
	pnl_badge.add_theme_stylebox_override("panel", sb_badge)
	
	var lbl_pos = Label.new()
	lbl_pos.text = "PASSO %d" % (pos_idx + 1)
	lbl_pos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_pos.add_theme_font_size_override("font_size", 12)
	lbl_pos.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5) if not eh_selecionado else Color(1.0, 1.0, 1.0))
	_aplicar_fonte_pixel(lbl_pos)
	pnl_badge.add_child(lbl_pos)
	vbox.add_child(pnl_badge)
	
	# icone
	var lbl_icone = Label.new()
	lbl_icone.text = dado.get("icone", "✦")
	lbl_icone.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_icone.add_theme_font_size_override("font_size", 34)
	vbox.add_child(lbl_icone)
	
	# botao pra selecionar card
	var btn_corpo = Button.new()
	btn_corpo.text = dado.get("texto", "")
	btn_corpo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn_corpo.custom_minimum_size = Vector2(230, 85)
	btn_corpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn_corpo.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_corpo.pressed.connect(func(): _on_card_clicado(pos_idx))
	
	var sb_btn = StyleBoxFlat.new()
	sb_btn.bg_color = Color(0.1, 0.12, 0.18, 0.6)
	sb_btn.set_corner_radius_all(6)
	sb_btn.set_content_margin_all(8)
	btn_corpo.add_theme_stylebox_override("normal", sb_btn)
	btn_corpo.add_theme_font_size_override("font_size", 12)
	btn_corpo.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	vbox.add_child(btn_corpo)
	
	# setas de mover card
	var hbox_setas = HBoxContainer.new()
	hbox_setas.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_setas.add_theme_constant_override("separation", 10)
	vbox.add_child(hbox_setas)
	
	if pos_idx > 0:
		var btn_esq = Button.new()
		btn_esq.text = "◀ Mover"
		btn_esq.custom_minimum_size = Vector2(85, 30)
		btn_esq.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn_esq.pressed.connect(func(): _trocar_posicoes(pos_idx, pos_idx - 1))
		_aplicar_estilo_seta(btn_esq)
		hbox_setas.add_child(btn_esq)
		
	if pos_idx < _cards_ordenados.size() - 1:
		var btn_dir = Button.new()
		btn_dir.text = "Mover ▶"
		btn_dir.custom_minimum_size = Vector2(85, 30)
		btn_dir.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn_dir.pressed.connect(func(): _trocar_posicoes(pos_idx, pos_idx + 1))
		_aplicar_estilo_seta(btn_dir)
		hbox_setas.add_child(btn_dir)
		
	return card

func _on_card_clicado(idx: int) -> void:
	if _resolvido:
		return
		
	if _card_selecionado_idx == -1:
		# seleciona card
		_card_selecionado_idx = idx
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("ui_1")
		_lbl_status.text = "Card do Passo %d selecionado! Clique em outro card para trocar de lugar." % (idx + 1)
		_lbl_status.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
		_atualizar_textos_e_cards()
	elif _card_selecionado_idx == idx:
		# tira selecao
		_card_selecionado_idx = -1
		_lbl_status.text = "Seleção desfeita. Clique em um card ou use as setas para ordenar."
		_lbl_status.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
		_atualizar_textos_e_cards()
	else:
		# troca os dois cards de lugar
		var origem = _card_selecionado_idx
		var destino = idx
		_card_selecionado_idx = -1
		_trocar_posicoes(origem, destino)

func _trocar_posicoes(idx_a: int, idx_b: int) -> void:
	if _resolvido:
		return
	if idx_a < 0 or idx_a >= _cards_ordenados.size() or idx_b < 0 or idx_b >= _cards_ordenados.size():
		return
		
	var temp = _cards_ordenados[idx_a]
	_cards_ordenados[idx_a] = _cards_ordenados[idx_b]
	_cards_ordenados[idx_b] = temp
	
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui_2")
		
	_lbl_status.text = "Cards trocados! Verifique se a ordem (1 → 2 → 3) está correta."
	_lbl_status.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	_atualizar_textos_e_cards()

func _on_verificar_clicado() -> void:
	if _resolvido:
		return
		
	if _esta_na_ordem(_cards_ordenados):
		_resolvido = true
		_executar_vitoria()
	else:
		_executar_erro()

func _executar_vitoria() -> void:
	_btn_verificar.disabled = true
	_lbl_status.text = "✦ PARABÉNS! A SEQUÊNCIA ESTÁ CORRETA! O SELO SE ROMPEU! ✦"
	_lbl_status.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("acerto_1")
		
	# brilho de acerto
	for card in _card_nodes:
		_aplicar_estilo_card(card, false, true)
		var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(card, "scale", Vector2(1.05, 1.05), 0.2)
		tw.tween_property(card, "scale", Vector2(1.0, 1.0), 0.2)
		
	# espera antes de fechar
	await get_tree().create_timer(1.2).timeout
	var p = get_tree().get_first_node_in_group("player")
	if p:
		if p.has_method("finalizar_interacao"):
			p.finalizar_interacao(0.8)
		else:
			p.travado = false
			p.em_interacao = false
	sequencia_concluida.emit(true)
	queue_free()

func _executar_erro() -> void:
	_lbl_status.text = "❌ A ordem ainda está incorreta! Pense na causa, processo e resultado."
	_lbl_status.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("erro_1")
		
	# treme o painel ao errar
	var pos_original = _painel_central.position
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_painel_central, "position", pos_original + Vector2(12, 0), 0.05)
	tw.tween_property(_painel_central, "position", pos_original - Vector2(12, 0), 0.05)
	tw.tween_property(_painel_central, "position", pos_original + Vector2(6, 0), 0.05)
	tw.tween_property(_painel_central, "position", pos_original, 0.05)

func _on_fechar_clicado() -> void:
	if _resolvido:
		return
	var p = get_tree().get_first_node_in_group("player")
	if p:
		if p.has_method("finalizar_interacao"):
			p.finalizar_interacao(0.8)
		else:
			p.travado = false
			p.em_interacao = false
	sequencia_concluida.emit(false)
	queue_free()

# estilos visuais dos cards
func _aplicar_estilo_card(card: PanelContainer, selecionado: bool, sucesso: bool) -> void:
	var sb = StyleBoxFlat.new()
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(12)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	
	if sucesso:
		sb.bg_color = Color(0.1, 0.2, 0.15, 0.95)
		sb.border_color = Color(0.4, 1.0, 0.6, 1.0)
		sb.shadow_color = Color(0.2, 0.9, 0.4, 0.4)
		sb.shadow_size = 14
	elif selecionado:
		sb.bg_color = Color(0.12, 0.18, 0.26, 0.95)
		sb.border_color = Color(0.3, 0.85, 1.0, 1.0)
		sb.shadow_color = Color(0.2, 0.8, 1.0, 0.5)
		sb.shadow_size = 16
	else:
		sb.bg_color = Color(0.09, 0.1, 0.15, 0.92)
		sb.border_color = Color(0.4, 0.45, 0.6, 0.8)
		sb.shadow_size = 4
		sb.shadow_color = Color(0, 0, 0, 0.5)
		
	card.add_theme_stylebox_override("panel", sb)

func _aplicar_estilo_botao_dourado(btn: Button) -> void:
	var sb_norm = StyleBoxFlat.new()
	sb_norm.bg_color = Color(0.22, 0.18, 0.08, 0.95)
	sb_norm.border_color = Color(0.95, 0.78, 0.25, 1.0)
	sb_norm.set_border_width_all(2)
	sb_norm.set_corner_radius_all(8)
	sb_norm.set_content_margin_all(10)
	
	var sb_hover = StyleBoxFlat.new()
	sb_hover.bg_color = Color(0.35, 0.28, 0.12, 1.0)
	sb_hover.border_color = Color(1.0, 0.9, 0.4, 1.0)
	sb_hover.set_border_width_all(2)
	sb_hover.set_corner_radius_all(8)
	sb_hover.set_content_margin_all(10)
	sb_hover.shadow_color = Color(1.0, 0.85, 0.3, 0.4)
	sb_hover.shadow_size = 10
	
	btn.add_theme_stylebox_override("normal", sb_norm)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("focus", sb_hover)
	btn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.5))
	btn.add_theme_font_size_override("font_size", 14)

func _aplicar_estilo_botao_secundario(btn: Button) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.14, 0.15, 0.22, 0.9)
	sb.border_color = Color(0.35, 0.4, 0.55, 0.8)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	btn.add_theme_font_size_override("font_size", 13)

func _aplicar_estilo_seta(btn: Button) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.2, 0.3, 0.9)
	sb.border_color = Color(0.4, 0.65, 0.9, 0.7)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(4)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	btn.add_theme_font_size_override("font_size", 11)

func _aplicar_fonte_pixel(control: Control) -> void:
	var font = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	if font:
		control.add_theme_font_override("font", font)

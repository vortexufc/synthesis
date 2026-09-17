extends CanvasLayer

signal vinheta_concluida

# vinheta com historinhas entre os andares

var _andar_atual: int = 1
var _quadro_revelado: int = 0
var _concluida: bool = false

# referencias dos nos
var _lbl_capitulo: Label
var _lbl_titulo: Label
var _lbl_subtitulo: Label
var _quadros_nodes: Array[PanelContainer] = []
var _btn_avancar: Button
var _lbl_contador: Label

# textos dos 3 capitulos da historia
var capitulos = {
	1: { # Transição Química -> Física (Ao derrotar o Chefe de Alquimia)
		"capitulo": "CAPÍTULO I: DA ALQUIMIA À QUÍMICA MODERNA",
		"subtitulo": "Como a humanidade substituiu mitos e segredos arcanos por medições exatas.",
		"quadros": [
			{
				"badge": "QUADRO I",
				"titulo": "A Era dos Mistérios e Caldeirões",
				"icone_tipo": "alquimia",
				"cor": Color(0.85, 0.45, 1.0),
				"texto": "Durante séculos, os antigos alquimistas buscavam a Pedra Filosofal e elixires de imortalidade em caldeirões escuros. Guiados por rituais secretos e lendas astrológicas, suas receitas eram mistérios transmitidos em códigos cifrados.",
				"marco": "💡 Buscavam ouro mítico, mas nos deixaram as primeiras tintas, remédios e ligas metálicas."
			},
			{
				"badge": "QUADRO II",
				"titulo": "A Balança da Razão — Lavoisier",
				"icone_tipo": "balanca",
				"cor": Color(1.0, 0.85, 0.3),
				"texto": "No final do século XVIII, Antoine Lavoisier revolucionou o pensamento humano ao colocar uma balança de precisão absoluta no laboratório. Fechando vidrarias herméticas e pesando tudo antes e depois de queimar substâncias, sepultou as superstições.",
				"marco": "⚖️ \"Na natureza nada se cria, nada se perde, tudo se transforma.\" — Lei de Lavoisier"
			},
			{
				"badge": "QUADRO III",
				"titulo": "O Legado Elemental",
				"icone_tipo": "atomo",
				"cor": Color(0.3, 0.95, 0.65),
				"texto": "Ao catalogar os elementos na Tabela Periódica e compreender como os átomos trocam elétrons, a humanidade dominou a matéria! A alquimia tornou-se a Química Moderna — abrindo caminho para que a Física desvendasse as forças do universo.",
				"marco": "🧪 A matéria deixou de ser magia: tornou-se uma sinfonia de átomos mensuráveis!"
			}
		]
	},
	2: { # Transição Física -> Biologia (Ao derrotar o Chefe de Física)
		"capitulo": "CAPÍTULO II: DAS FORÇAS AO DOMÍNIO DO RELÂMPAGO",
		"subtitulo": "O domínio das leis do movimento, do magnetismo e da luz que iluminou o mundo.",
		"quadros": [
			{
				"badge": "QUADRO I",
				"titulo": "A Harmonia dos Corpos — Newton",
				"icone_tipo": "newton",
				"cor": Color(0.3, 0.8, 1.0),
				"texto": "Observando a queda dos corpos na Terra e a órbita suave da Lua, Isaac Newton compreendeu que a mesma gravidade governa o céu e o chão. Três leis fundamentais descreveram matematicamente a inércia, a força e a ação e reação.",
				"marco": "🍎 O universo deixou de ser caótico e revelou suas engrenagens mecânicas perfeitas."
			},
			{
				"badge": "QUADRO II",
				"titulo": "A Fagulha do Progresso — Faraday & Maxwell",
				"icone_tipo": "raio",
				"cor": Color(1.0, 0.9, 0.35),
				"texto": "Físicos descobriram que magnetismo e eletricidade são a mesma força. Girando ímãs dentro de fios de cobre, Michael Faraday domou o relâmpago, criando motores e geradores que transformaram vilarejos escuros em metrópoles iluminadas.",
				"marco": "⚡ A eletricidade e o magnetismo unidos deram vida às máquinas da revolução humana!"
			},
			{
				"badge": "QUADRO III",
				"titulo": "A Luz que Revela o Invisível",
				"icone_tipo": "otica",
				"cor": Color(0.4, 0.65, 1.0),
				"texto": "Compreendendo a ótica e a refração da luz, cientistas lapidaram lentes. Telescópios desvendaram as galáxias distantes, enquanto tubos de microscópio revelaram algo ainda mais surpreendente: o universo oculto das células vivas!",
				"marco": "🔬 A Física construiu os olhos que permitiram à humanidade enxergar a Biologia!"
			}
		]
	},
	3: { # Conclusão Biologia / Grande Síntese (Ao derrotar o Chefe de Biologia)
		"capitulo": "CAPÍTULO III: A ESPIRAL DA CRIAÇÃO E A GRANDE SÍNTESE",
		"subtitulo": "A revelação do código genético e a união definitiva de todas as ciências.",
		"quadros": [
			{
				"badge": "QUADRO I",
				"titulo": "A Descoberta da Célula Viva",
				"icone_tipo": "celula",
				"cor": Color(0.4, 1.0, 0.5),
				"texto": "Apontando suas primeiras lentes para tecidos vegetais e gotas de água, Robert Hooke descobriu pequenas câmaras que batizou de 'células'. Cada ser vivo na Terra — do menor slime ao sábio mago — é uma metrópole de células ativas.",
				"marco": "🌿 A célula é o tijolo elementar e a usina com que a vida constrói a si mesma."
			},
			{
				"badge": "QUADRO II",
				"titulo": "O Livro da Vida — A Dupla Hélice",
				"icone_tipo": "dna",
				"cor": Color(1.0, 0.45, 0.85),
				"texto": "Em 1953, Rosalind Franklin, Watson e Crick desvendaram o enigma da hereditariedade: a molécula de DNA. Uma deslumbrante escada em espiral contendo quatro bases químicas (A, T, C, G) que guardam as instruções de toda a biodiversidade.",
				"marco": "🧬 Todo o mistério da evolução humana escrito na mais elegante molécula do cosmos."
			},
			{
				"badge": "QUADRO III",
				"titulo": "A Grande Síntese Arcana",
				"icone_tipo": "sintese",
				"cor": Color(1.0, 0.85, 0.25),
				"texto": "A matéria da Química, as energias da Física e os códigos da Biologia não são reinos separados: são a mesma tapeçaria integrada da realidade! Você superou as provações dos três andares e alcançou o título de Mestre Supremo da Síntese!",
				"marco": "✨ O conhecimento científico comprovado é a maior e mais bela magia do universo!"
			}
		]
	}
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 120 # Acima de todas as telas
	_construir_layout()

func iniciar_vinheta(andar_id: int) -> void:
	_andar_atual = clampi(andar_id, 1, 3)
	_quadro_revelado = 0
	_concluida = false
	
	# salva que o player ja viu
	if get_node_or_null("/root/PlayerStats") and PlayerStats.has_method("desbloquear_vinheta"):
		PlayerStats.desbloquear_vinheta(_andar_atual)
		
	var dados = capitulos.get(_andar_atual, capitulos[1])
	_lbl_capitulo.text = dados["capitulo"]
	_lbl_subtitulo.text = dados["subtitulo"]
	
	var quadros_dados = dados["quadros"]
	for i in range(_quadros_nodes.size()):
		if i < quadros_dados.size():
			_configurar_quadro_conteudo(_quadros_nodes[i], quadros_dados[i])
			_quadros_nodes[i].modulate.a = 0.0
			_quadros_nodes[i].scale = Vector2(0.9, 0.9)
			_quadros_nodes[i].visible = false
			
	# mostra o primeiro quadrinho
	_revelar_proximo_quadro()

func _construir_layout() -> void:
	var font_titulo = SystemFont.new()
	font_titulo.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_titulo.font_weight = 700

	var font_sans = SystemFont.new()
	font_sans.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_sans.font_weight = 500
	
	# fundo escuro
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.05, 0.09, 0.96)
	add_child(bg)
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)
	
	var vbox_root = VBoxContainer.new()
	vbox_root.add_theme_constant_override("separation", 16)
	vbox_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox_root)
	
	# cabecalho e botao pular
	var hbox_topo = HBoxContainer.new()
	hbox_topo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_root.add_child(hbox_topo)
	
	var vbox_titulos = VBoxContainer.new()
	vbox_titulos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_titulos.add_theme_constant_override("separation", 4)
	hbox_topo.add_child(vbox_titulos)
	
	_lbl_capitulo = Label.new()
	_lbl_capitulo.text = "CRÔNICAS DO CONHECIMENTO — CAPÍTULO I"
	_lbl_capitulo.add_theme_font_override("font", font_titulo)
	_lbl_capitulo.add_theme_font_size_override("font_size", 18)
	_lbl_capitulo.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	vbox_titulos.add_child(_lbl_capitulo)
	
	_lbl_subtitulo = Label.new()
	_lbl_subtitulo.text = "A saga da humanidade na descoberta das leis do universo."
	_lbl_subtitulo.add_theme_font_override("font", font_sans)
	_lbl_subtitulo.add_theme_font_size_override("font_size", 13)
	_lbl_subtitulo.add_theme_color_override("font_color", Color(0.7, 0.8, 0.95))
	vbox_titulos.add_child(_lbl_subtitulo)
	
	# separador
	var sep = HSeparator.new()
	vbox_root.add_child(sep)
	
	# area dos 3 quadrinhos
	var hbox_quadros = HBoxContainer.new()
	hbox_quadros.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_quadros.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox_quadros.add_theme_constant_override("separation", 18)
	vbox_root.add_child(hbox_quadros)
	
	_quadros_nodes.clear()
	for i in range(3):
		var card = _criar_estrutura_quadro(i)
		hbox_quadros.add_child(card)
		_quadros_nodes.append(card)
		
	# barra de navegacao embaixo
	var hbox_rodape = HBoxContainer.new()
	hbox_rodape.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_rodape.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_root.add_child(hbox_rodape)
	
	_lbl_contador = Label.new()
	_lbl_contador.text = "Quadro 1 de 3"
	_lbl_contador.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_contador.add_theme_font_override("font", font_sans)
	_lbl_contador.add_theme_font_size_override("font_size", 13)
	_lbl_contador.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	hbox_rodape.add_child(_lbl_contador)
	
	_btn_avancar = Button.new()
	_btn_avancar.text = "Revelar Próximo Quadro ▶ (Espaço)"
	_btn_avancar.custom_minimum_size = Vector2(300, 42)
	_btn_avancar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_btn_avancar.focus_mode = Control.FOCUS_ALL
	
	var sb_btn_norm = StyleBoxFlat.new()
	sb_btn_norm.bg_color = Color(0.18, 0.28, 0.48, 0.95)
	sb_btn_norm.border_color = Color(0.45, 0.8, 1.0)
	sb_btn_norm.set_border_width_all(2)
	sb_btn_norm.set_corner_radius_all(6)
	sb_btn_norm.content_margin_left = 16
	sb_btn_norm.content_margin_right = 16
	
	var sb_btn_hover = StyleBoxFlat.new()
	sb_btn_hover.bg_color = Color(0.24, 0.42, 0.72, 1.0)
	sb_btn_hover.border_color = Color(0.7, 0.95, 1.0)
	sb_btn_hover.set_border_width_all(2)
	sb_btn_hover.set_corner_radius_all(6)
	sb_btn_hover.shadow_color = Color(0.3, 0.7, 1.0, 0.4)
	sb_btn_hover.shadow_size = 12
	
	_btn_avancar.add_theme_stylebox_override("normal", sb_btn_norm)
	_btn_avancar.add_theme_stylebox_override("hover", sb_btn_hover)
	_btn_avancar.add_theme_stylebox_override("focus", sb_btn_hover)
	_btn_avancar.add_theme_font_override("font", font_titulo)
	_btn_avancar.add_theme_font_size_override("font_size", 14)
	_btn_avancar.add_theme_color_override("font_color", Color.WHITE)
	_btn_avancar.pressed.connect(_on_btn_avancar_pressed)
	hbox_rodape.add_child(_btn_avancar)

func _criar_estrutura_quadro(indice: int) -> PanelContainer:
	var font_titulo = SystemFont.new()
	font_titulo.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_titulo.font_weight = 700

	var font_sans = SystemFont.new()
	font_sans.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_sans.font_weight = 400

	var card = PanelContainer.new()
	card.name = "Quadro_%d" % (indice + 1)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.09, 0.15, 0.98)
	sb.border_color = Color(0.9, 0.75, 0.3)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	sb.shadow_color = Color(0, 0, 0, 0.75)
	sb.shadow_size = 12
	card.add_theme_stylebox_override("panel", sb)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(vbox)
	
	# numero do quadro
	var lbl_badge = Label.new()
	lbl_badge.name = "LblBadge"
	lbl_badge.text = "QUADRO %d" % (indice + 1)
	lbl_badge.add_theme_font_override("font", font_titulo)
	lbl_badge.add_theme_font_size_override("font_size", 11)
	lbl_badge.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	vbox.add_child(lbl_badge)
	
	# titulo do quadro
	var lbl_titulo_q = Label.new()
	lbl_titulo_q.name = "LblTitulo"
	lbl_titulo_q.text = "Título do Quadro"
	lbl_titulo_q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_titulo_q.add_theme_font_override("font", font_titulo)
	lbl_titulo_q.add_theme_font_size_override("font_size", 14)
	lbl_titulo_q.add_theme_color_override("font_color", Color(1.0, 0.95, 0.9))
	vbox.add_child(lbl_titulo_q)
	
	# desenho em pixel art
	var moldura_ilustracao = PanelContainer.new()
	moldura_ilustracao.custom_minimum_size = Vector2(0, 130)
	moldura_ilustracao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb_mold = StyleBoxFlat.new()
	sb_mold.bg_color = Color(0.04, 0.05, 0.08, 0.95)
	sb_mold.border_color = Color(0.3, 0.4, 0.6)
	sb_mold.set_border_width_all(1)
	sb_mold.set_corner_radius_all(6)
	moldura_ilustracao.add_theme_stylebox_override("panel", sb_mold)
	
	# no pra desenhar a arte
	var canvas_arte = Control.new()
	canvas_arte.name = "CanvasArte"
	canvas_arte.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas_arte.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas_arte.draw.connect(_desenhar_arte_quadro.bind(canvas_arte))
	moldura_ilustracao.add_child(canvas_arte)
	vbox.add_child(moldura_ilustracao)
	
	# texto da historia
	var lbl_texto = RichTextLabel.new()
	lbl_texto.name = "LblTexto"
	lbl_texto.bbcode_enabled = true
	lbl_texto.fit_content = true
	lbl_texto.scroll_active = false
	lbl_texto.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lbl_texto.add_theme_font_override("normal_font", font_sans)
	lbl_texto.add_theme_font_size_override("normal_font_size", 13)
	vbox.add_child(lbl_texto)
	
	# citacao cientifica
	var painel_marco = PanelContainer.new()
	painel_marco.name = "PainelMarco"
	var sb_marco = StyleBoxFlat.new()
	sb_marco.bg_color = Color(0.12, 0.14, 0.2, 0.9)
	sb_marco.border_color = Color(0.9, 0.75, 0.3, 0.7)
	sb_marco.set_border_width_all(1)
	sb_marco.set_corner_radius_all(6)
	sb_marco.content_margin_left = 10
	sb_marco.content_margin_right = 10
	sb_marco.content_margin_top = 6
	sb_marco.content_margin_bottom = 6
	painel_marco.add_theme_stylebox_override("panel", sb_marco)
	
	var lbl_marco = Label.new()
	lbl_marco.name = "LblMarco"
	lbl_marco.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_marco.add_theme_font_override("font", font_sans)
	lbl_marco.add_theme_font_size_override("font_size", 12)
	lbl_marco.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	painel_marco.add_child(lbl_marco)
	vbox.add_child(painel_marco)
	
	return card

func _configurar_quadro_conteudo(card: PanelContainer, dados: Dictionary) -> void:
	var lbl_badge = card.find_child("LblBadge", true, false) as Label
	var lbl_titulo = card.find_child("LblTitulo", true, false) as Label
	var lbl_texto = card.find_child("LblTexto", true, false) as RichTextLabel
	var lbl_marco = card.find_child("LblMarco", true, false) as Label
	var canvas_arte = card.find_child("CanvasArte", true, false) as Control
	
	if lbl_badge: lbl_badge.text = dados.get("badge", "QUADRO")
	if lbl_titulo: lbl_titulo.text = dados.get("titulo", "")
	if lbl_texto: lbl_texto.text = "[color=#d8e2f0]" + dados.get("texto", "") + "[/color]"
	if lbl_marco: lbl_marco.text = dados.get("marco", "")
	
	# guarda os dados do desenho
	if canvas_arte:
		canvas_arte.set_meta("tipo", dados.get("icone_tipo", "alquimia"))
		canvas_arte.set_meta("cor", dados.get("cor", Color.GOLD))
		canvas_arte.queue_redraw()

# desenha a arte do quadrinho
func _desenhar_arte_quadro(canvas: Control) -> void:
	var rect = canvas.get_rect()
	var center = rect.size * 0.5
	var tipo = canvas.get_meta("tipo", "alquimia")
	var cor: Color = canvas.get_meta("cor", Color.GOLD)
	
	match tipo:
		"alquimia":
			# caldeirao borbulhando
			canvas.draw_circle(center + Vector2(0, 10), 32.0, Color(0.2, 0.22, 0.28))
			canvas.draw_circle(center + Vector2(0, 10), 28.0, Color(0.12, 0.08, 0.18))
			# liquido no caldeirao
			canvas.draw_circle(center + Vector2(0, 4), 22.0, cor)
			canvas.draw_circle(center + Vector2(-6, -2), 6.0, Color(1.0, 0.8, 1.0, 0.9))
			# bolhas
			canvas.draw_circle(center + Vector2(-12, -22), 4.0, cor)
			canvas.draw_circle(center + Vector2(8, -28), 5.0, Color(0.9, 0.5, 1.0))
			canvas.draw_circle(center + Vector2(18, -16), 3.0, cor)
			# frasco de pocao
			canvas.draw_rect(Rect2(center.x + 40, center.y - 15, 18, 28), Color(0.4, 0.85, 1.0, 0.6), false, 2.0)
			canvas.draw_rect(Rect2(center.x + 42, center.y - 5, 14, 16), Color(0.3, 0.7, 1.0, 0.9))
			
		"balanca":
			# balanca de lavoisier
			canvas.draw_line(center + Vector2(0, -35), center + Vector2(0, 40), Color(0.95, 0.8, 0.3), 4.0)
			# base da balanca
			canvas.draw_line(center + Vector2(-30, 40), center + Vector2(30, 40), Color(0.95, 0.8, 0.3), 6.0)
			# barra da balanca
			canvas.draw_line(center + Vector2(-55, -20), center + Vector2(55, -20), Color(1.0, 0.9, 0.4), 3.0)
			canvas.draw_circle(center + Vector2(0, -20), 6.0, Color(1.0, 0.7, 0.2))
			# pratos da balanca
			canvas.draw_line(center + Vector2(-55, -20), center + Vector2(-68, 10), Color(0.8, 0.8, 0.9), 1.5)
			canvas.draw_line(center + Vector2(-55, -20), center + Vector2(-42, 10), Color(0.8, 0.8, 0.9), 1.5)
			canvas.draw_line(center + Vector2(-75, 12), center + Vector2(-35, 12), Color(1.0, 0.85, 0.3), 3.5)
			# pesos no prato
			canvas.draw_circle(center + Vector2(-55, 6), 6.0, Color(0.3, 0.9, 1.0))
			
			canvas.draw_line(center + Vector2(55, -20), center + Vector2(42, 10), Color(0.8, 0.8, 0.9), 1.5)
			canvas.draw_line(center + Vector2(55, -20), center + Vector2(68, 10), Color(0.8, 0.8, 0.9), 1.5)
			canvas.draw_line(center + Vector2(35, 12), center + Vector2(75, 12), Color(1.0, 0.85, 0.3), 3.5)
			canvas.draw_circle(center + Vector2(55, 6), 6.0, Color(1.0, 0.3, 0.3))
			
		"atomo":
			# modelo atomico
			canvas.draw_circle(center, 12.0, cor)
			canvas.draw_circle(center, 7.0, Color(1.0, 1.0, 0.6))
			# orbitas dos eletrons
			var r_orbit = 48.0
			for angle in [0.0, 60.0, 120.0]:
				var rad = deg_to_rad(angle)
				var p1 = center + Vector2(cos(rad) * r_orbit, sin(rad) * 20)
				var p2 = center - Vector2(cos(rad) * r_orbit, sin(rad) * 20)
				canvas.draw_line(p1, p2, Color(0.3, 0.8, 1.0, 0.45), 2.0)
				canvas.draw_circle(p1, 4.0, Color(0.4, 1.0, 0.8))
				
		"newton":
			# gravidade de newton
			canvas.draw_circle(center + Vector2(-30, 15), 26.0, Color(0.2, 0.45, 0.85))
			canvas.draw_arc(center + Vector2(-30, 15), 36.0, -PI*0.4, PI*0.6, 24, Color(1.0, 1.0, 1.0, 0.4), 2.0)
			# maca caindo
			var pos_maca = center + Vector2(35, -15)
			canvas.draw_circle(pos_maca, 12.0, Color(0.95, 0.2, 0.2))
			canvas.draw_line(pos_maca, pos_maca + Vector2(0, 32), Color(1.0, 0.85, 0.2), 3.0)
			# ponta da seta
			canvas.draw_line(pos_maca + Vector2(0, 32), pos_maca + Vector2(-5, 24), Color(1.0, 0.85, 0.2), 3.0)
			canvas.draw_line(pos_maca + Vector2(0, 32), pos_maca + Vector2(5, 24), Color(1.0, 0.85, 0.2), 3.0)
			
		"raio":
			# bobina eletromagnetica
			canvas.draw_circle(center + Vector2(-45, 0), 16.0, Color(0.8, 0.5, 0.2))
			canvas.draw_circle(center + Vector2(45, 0), 16.0, Color(0.8, 0.5, 0.2))
			# faíscas eletricas
			var pontos = PackedVector2Array([
				center + Vector2(-30, 0),
				center + Vector2(-15, -18),
				center + Vector2(0, 12),
				center + Vector2(15, -14),
				center + Vector2(30, 0)
			])
			canvas.draw_polyline(pontos, Color(1.0, 0.95, 0.3), 4.0)
			canvas.draw_polyline(pontos, Color(1.0, 1.0, 1.0), 2.0)
			
		"otica":
			# lente convergente
			canvas.draw_circle(center, 34.0, Color(0.3, 0.6, 1.0, 0.25))
			canvas.draw_arc(center, 34.0, -PI*0.5, PI*0.5, 24, Color(0.5, 0.85, 1.0), 3.0)
			canvas.draw_arc(center, 34.0, PI*0.5, PI*1.5, 24, Color(0.5, 0.85, 1.0), 3.0)
			# raios de luz
			canvas.draw_line(center + Vector2(-60, -18), center + Vector2(0, -18), Color(1.0, 0.9, 0.4), 2.0)
			canvas.draw_line(center + Vector2(-60, 18), center + Vector2(0, 18), Color(1.0, 0.9, 0.4), 2.0)
			canvas.draw_line(center + Vector2(0, -18), center + Vector2(50, 0), Color(1.0, 0.9, 0.4), 2.0)
			canvas.draw_line(center + Vector2(0, 18), center + Vector2(50, 0), Color(1.0, 0.9, 0.4), 2.0)
			canvas.draw_circle(center + Vector2(50, 0), 5.0, Color(1.0, 1.0, 1.0))
			
		"celula":
			# celula vegetal
			canvas.draw_rect(Rect2(center.x - 45, center.y - 30, 90, 60), Color(0.15, 0.5, 0.25), false, 4.0)
			canvas.draw_circle(center, 14.0, Color(0.85, 0.35, 0.6)) # Núcleo
			canvas.draw_circle(center, 6.0, Color(1.0, 0.7, 0.9))
			# cloroplastos
			canvas.draw_circle(center + Vector2(-28, -14), 7.0, Color(0.3, 0.9, 0.3))
			canvas.draw_circle(center + Vector2(28, -12), 8.0, Color(0.3, 0.9, 0.3))
			canvas.draw_circle(center + Vector2(-22, 16), 6.0, Color(0.3, 0.9, 0.3))
			canvas.draw_circle(center + Vector2(24, 15), 7.0, Color(0.3, 0.9, 0.3))
			
		"dna":
			# dupla helice de dna
			for step in range(-4, 5):
				var y_pos = center.y + (step * 8)
				var offset_x = sin(step * 0.8) * 32.0
				# fios do dna
				canvas.draw_circle(Vector2(center.x - offset_x, y_pos), 4.5, Color(0.3, 0.85, 1.0))
				canvas.draw_circle(Vector2(center.x + offset_x, y_pos), 4.5, Color(1.0, 0.4, 0.8))
				# bases pareadas
				if abs(offset_x) > 4:
					canvas.draw_line(Vector2(center.x - offset_x, y_pos), Vector2(center.x, y_pos), Color(0.3, 1.0, 0.4), 2.5)
					canvas.draw_line(Vector2(center.x, y_pos), Vector2(center.x + offset_x, y_pos), Color(1.0, 0.8, 0.2), 2.5)
					
		"sintese":
			# triangulo dos tres elementos
			var p_top = center + Vector2(0, -32)
			var p_left = center + Vector2(-36, 24)
			var p_right = center + Vector2(36, 24)
			canvas.draw_line(p_top, p_left, Color(1.0, 0.8, 0.3), 3.0)
			canvas.draw_line(p_left, p_right, Color(0.3, 0.85, 1.0), 3.0)
			canvas.draw_line(p_right, p_top, Color(0.4, 1.0, 0.5), 3.0)
			canvas.draw_circle(p_top, 10.0, Color(1.0, 0.8, 0.3)) # Química
			canvas.draw_circle(p_left, 10.0, Color(0.3, 0.85, 1.0)) # Física
			canvas.draw_circle(p_right, 10.0, Color(0.4, 1.0, 0.5)) # Biologia
			canvas.draw_circle(center, 12.0, Color(1.0, 1.0, 1.0, 0.85)) # Síntese Central

func _on_btn_avancar_pressed() -> void:
	if _concluida: return
	
	if _quadro_revelado < 3:
		_revelar_proximo_quadro()
	else:
		_encerrar_vinheta()

func _input(event: InputEvent) -> void:
	if _concluida: return
	
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)):
		get_viewport().set_input_as_handled()
		_on_btn_avancar_pressed()

func _revelar_proximo_quadro() -> void:
	if _quadro_revelado >= 3:
		return
		
	var idx = _quadro_revelado
	_quadro_revelado += 1
	_lbl_contador.text = "Quadro %d de 3" % _quadro_revelado
	
	var card = _quadros_nodes[idx]
	card.visible = true
	
	# som de passar pagina
	if get_node_or_null("/root/AudioManager"):
		if _quadro_revelado == 3:
			AudioManager.play_sfx("win")
		else:
			AudioManager.play_sfx("transicao-1")
			
	# Animação cinematográfica de slide e fade in (processa mesmo no pause)
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "modulate:a", 1.0, 0.35)
	tw.tween_property(card, "scale", Vector2.ONE, 0.35)
	
	# atualiza o botao
	if _quadro_revelado == 3:
		_btn_avancar.text = "Descer ao Próximo Andar (Ir ao Hub) ▶ (Espaço)"
			
		var sb_b = _btn_avancar.get_theme_stylebox("normal") as StyleBoxFlat
		if sb_b:
			sb_b.bg_color = Color(0.15, 0.45, 0.25, 1.0)
			sb_b.border_color = Color(0.4, 1.0, 0.6)
	else:
		_btn_avancar.text = "Revelar Próximo Quadro ▶ (Espaço)"
		
	_btn_avancar.grab_focus()

func _encerrar_vinheta() -> void:
	if _concluida: return
	_concluida = true
	
	get_tree().paused = false
	vinheta_concluida.emit()
	
	if get_node_or_null("/root/DungeonGenerator"):
		DungeonGenerator.resetar_masmorra()
	if get_node_or_null("/root/QuizManager"):
		QuizManager.resetar_historico_perguntas()
		
	# volta pro hub
	if get_node_or_null("/root/TransitionScreen"):
		TransitionScreen.change_scene("res://scenes/Salas/Comum/Hub_Geral.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/Salas/Comum/Hub_Geral.tscn")
		
	queue_free()

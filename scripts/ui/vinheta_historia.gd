extends CanvasLayer

signal vinheta_concluida

# vinheta com historinhas entre os andares e tela de conclusao

var _andar_atual: int = 1
var _quadro_revelado: int = 0
var _concluida: bool = false

# referencias dos nos da vinheta dos 3 capitulos
var _lbl_tag_topo: Label
var _lbl_capitulo: Label
var _lbl_subtitulo: Label
var _quadros_nodes: Array[PanelContainer] = []
var _btn_avancar: Button
var _lbl_contador: Label

# tela de vitoria do andar
var _margin_conteudo: MarginContainer = null
var _em_tela_vitoria: bool = false
var _container_vitoria: Control = null
var _btn_fechar_topo: Button = null
var _btn_ir_hub: Button = null

# textos das crônicas dos 3 andares da história
var capitulos = {
	1: { # Andar de Alquimia / Química
		"capitulo": "CRÔNICAS DA QUÍMICA: DA ALQUIMIA AO ÁTOMO",
		"subtitulo": "Como a humanidade substituiu mitos e segredos arcanos por medições exatas.",
		"cor_tema": Color(1.0, 0.85, 0.35),
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
				"texto": "Ao catalogar os elementos na Tabela Periódica e compreender como os átomos trocam elétrons, a humanidade dominou a matéria! A alquimia transformou-se na Química Moderna — a chave fundamental que compõe e decifra a estrutura de todo o universo observável.",
				"marco": "🧪 A matéria deixou de ser magia: tornou-se uma sinfonia de átomos mensuráveis!"
			}
		]
	},
	2: { # Andar de Física
		"capitulo": "CRÔNICAS DA FÍSICA: DAS FORÇAS AO DOMÍNIO DO RELÂMPAGO",
		"subtitulo": "O domínio das leis do movimento, do magnetismo e da energia que transformou o mundo.",
		"cor_tema": Color(0.35, 0.85, 1.0),
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
				"titulo": "A Luz e a Energia Cósmica",
				"icone_tipo": "otica",
				"cor": Color(0.4, 0.65, 1.0),
				"texto": "Compreendendo a ótica, a mecânica e o eletromagnetismo, cientistas lapidaram instrumentos de altíssima precisão. Telescópios desvendaram galáxias distantes, enquanto equações fundamentais revelaram as energias e forças que governam todo o cosmos!",
				"marco": "⚡ A Física uniu o movimento dos corpos às forças invisíveis que movem o universo!"
			}
		]
	},
	3: { # Andar de Biologia
		"capitulo": "CRÔNICAS DA BIOLOGIA: A ESPIRAL DA CRIAÇÃO E DA VIDA",
		"subtitulo": "A revelação da célula viva, da evolução e do código genético que rege a biodiversidade.",
		"cor_tema": Color(0.45, 1.0, 0.65),
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
				"titulo": "A Teia da Vida",
				"icone_tipo": "sintese",
				"cor": Color(0.3, 0.95, 0.65),
				"texto": "Dos ecossistemas globais à complexidade dos tecidos celulares, a Biologia revelou que todos os seres vivos na Terra compartilham a mesma ancestralidade e a mesma química fascinante. A vida é a mais sublime expressão da natureza!",
				"marco": "🌿 A vida é uma tapeçaria contínua de adaptação, energia e evolução!"
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
	
	# salva que o player ja visualizou
	if get_node_or_null("/root/PlayerStats") and PlayerStats.has_method("desbloquear_vinheta"):
		PlayerStats.desbloquear_vinheta(_andar_atual)
		
	var dados = capitulos.get(_andar_atual, capitulos[1])
	var cor_tema: Color = dados.get("cor_tema", Color(1.0, 0.85, 0.35))
	
	_lbl_capitulo.text = dados["capitulo"]
	_lbl_capitulo.add_theme_color_override("font_color", cor_tema)
	_lbl_subtitulo.text = dados["subtitulo"]
	
	var quadros_dados = dados["quadros"]
	for i in range(_quadros_nodes.size()):
		if i < quadros_dados.size():
			_configurar_quadro_conteudo(_quadros_nodes[i], quadros_dados[i])
			_quadros_nodes[i].modulate.a = 0.0
			_quadros_nodes[i].scale = Vector2(0.92, 0.92)
			_quadros_nodes[i].visible = false
			
	# mostra o primeiro quadrinho com animacao
	_revelar_proximo_quadro()

func _construir_layout() -> void:
	var font_titulo = SystemFont.new()
	font_titulo.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_titulo.font_weight = 700

	var font_sans = SystemFont.new()
	font_sans.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_sans.font_weight = 400
	
	# fundo atmosférico azul-meia-noite profundo
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.04, 0.07, 0.98)
	add_child(bg)
	
	# partículas arcanas sutis de fundo
	var particulas_bg = CPUParticles2D.new()
	particulas_bg.amount = 25
	particulas_bg.lifetime = 4.0
	particulas_bg.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particulas_bg.emission_rect_extents = Vector2(640, 360)
	particulas_bg.position = Vector2(640, 360)
	particulas_bg.gravity = Vector2(0, -15)
	particulas_bg.scale_amount_min = 1.5
	particulas_bg.scale_amount_max = 3.5
	particulas_bg.color = Color(0.4, 0.6, 1.0, 0.25)
	add_child(particulas_bg)
	
	_margin_conteudo = MarginContainer.new()
	_margin_conteudo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_margin_conteudo.add_theme_constant_override("margin_left", 40)
	_margin_conteudo.add_theme_constant_override("margin_right", 40)
	_margin_conteudo.add_theme_constant_override("margin_top", 20)
	_margin_conteudo.add_theme_constant_override("margin_bottom", 20)
	add_child(_margin_conteudo)
	
	var vbox_root = VBoxContainer.new()
	vbox_root.add_theme_constant_override("separation", 14)
	vbox_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_margin_conteudo.add_child(vbox_root)
	
	# cabecalho estilizado com pill badge e tipografia premium
	var vbox_titulos = VBoxContainer.new()
	vbox_titulos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_titulos.add_theme_constant_override("separation", 4)
	vbox_root.add_child(vbox_titulos)
	
	var hbox_pill = HBoxContainer.new()
	vbox_titulos.add_child(hbox_pill)
	
	var pill_top = PanelContainer.new()
	var sb_pill_top = StyleBoxFlat.new()
	sb_pill_top.bg_color = Color(0.12, 0.18, 0.32, 0.6)
	sb_pill_top.border_color = Color(0.35, 0.6, 0.95, 0.8)
	sb_pill_top.set_border_width_all(1)
	sb_pill_top.set_corner_radius_all(10)
	sb_pill_top.content_margin_left = 12
	sb_pill_top.content_margin_right = 12
	sb_pill_top.content_margin_top = 3
	sb_pill_top.content_margin_bottom = 3
	pill_top.add_theme_stylebox_override("panel", sb_pill_top)
	
	_lbl_tag_topo = Label.new()
	_lbl_tag_topo.text = "✦ CODEX CIENTÍFICO • REGISTRO HISTÓRICO ✦"
	_lbl_tag_topo.add_theme_font_override("font", font_titulo)
	_lbl_tag_topo.add_theme_font_size_override("font_size", 10)
	_lbl_tag_topo.add_theme_color_override("font_color", Color(0.65, 0.85, 1.0))
	pill_top.add_child(_lbl_tag_topo)
	hbox_pill.add_child(pill_top)
	
	_lbl_capitulo = Label.new()
	_lbl_capitulo.text = "CRÔNICAS DO CONHECIMENTO — CAPÍTULO I"
	_lbl_capitulo.add_theme_font_override("font", font_titulo)
	_lbl_capitulo.add_theme_font_size_override("font_size", 21)
	_lbl_capitulo.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4))
	vbox_titulos.add_child(_lbl_capitulo)
	
	_lbl_subtitulo = Label.new()
	_lbl_subtitulo.text = "A saga da humanidade na descoberta das leis fundamentais do universo."
	_lbl_subtitulo.add_theme_font_override("font", font_sans)
	_lbl_subtitulo.add_theme_font_size_override("font_size", 13)
	_lbl_subtitulo.add_theme_color_override("font_color", Color(0.80, 0.88, 0.98))
	vbox_titulos.add_child(_lbl_subtitulo)
	
	# linha divisoria estilizada com gradiente sutil
	var sep = HSeparator.new()
	var sb_sep = StyleBoxLine.new()
	sb_sep.color = Color(0.3, 0.5, 0.8, 0.4)
	sb_sep.thickness = 1
	sep.add_theme_stylebox_override("separator", sb_sep)
	vbox_root.add_child(sep)
	
	# container horizontal dos 3 cartões
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
		
	# barra de navegacao inferior
	var hbox_rodape = HBoxContainer.new()
	hbox_rodape.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_rodape.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_root.add_child(hbox_rodape)
	
	_lbl_contador = Label.new()
	_lbl_contador.text = "Quadro 1 de 3  •  [ Espaço ] para Avançar"
	_lbl_contador.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_contador.add_theme_font_override("font", font_sans)
	_lbl_contador.add_theme_font_size_override("font_size", 13)
	_lbl_contador.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	hbox_rodape.add_child(_lbl_contador)
	
	_btn_avancar = Button.new()
	_btn_avancar.text = "Revelar Próximo Quadro ▶ (Espaço)"
	_btn_avancar.custom_minimum_size = Vector2(380, 46)
	_btn_avancar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_btn_avancar.focus_mode = Control.FOCUS_ALL
	
	var sb_btn_norm = StyleBoxFlat.new()
	sb_btn_norm.bg_color = Color(0.14, 0.24, 0.44, 0.95)
	sb_btn_norm.border_color = Color(0.45, 0.8, 1.0)
	sb_btn_norm.set_border_width_all(2)
	sb_btn_norm.set_corner_radius_all(8)
	sb_btn_norm.content_margin_left = 18
	sb_btn_norm.content_margin_right = 18
	sb_btn_norm.shadow_color = Color(0.1, 0.3, 0.6, 0.4)
	sb_btn_norm.shadow_size = 8
	
	var sb_btn_hover = StyleBoxFlat.new()
	sb_btn_hover.bg_color = Color(0.20, 0.38, 0.68, 1.0)
	sb_btn_hover.border_color = Color(0.7, 0.95, 1.0)
	sb_btn_hover.set_border_width_all(2)
	sb_btn_hover.set_corner_radius_all(8)
	sb_btn_hover.shadow_color = Color(0.3, 0.7, 1.0, 0.5)
	sb_btn_hover.shadow_size = 14
	
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
	
	# design de placa de vidro obsidiana com cantos arredondados e sombra difusa
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.12, 0.98)
	sb.border_color = Color(0.85, 0.72, 0.32, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	sb.shadow_color = Color(0, 0, 0, 0.8)
	sb.shadow_size = 16
	card.add_theme_stylebox_override("panel", sb)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(vbox)
	
	# tag badge no topo do cartao (ex: [ QUADRO I ])
	var hbox_badge = HBoxContainer.new()
	vbox.add_child(hbox_badge)
	
	var badge_pill = PanelContainer.new()
	badge_pill.name = "BadgePill"
	var sb_pill = StyleBoxFlat.new()
	sb_pill.bg_color = Color(0.18, 0.22, 0.34, 0.5)
	sb_pill.border_color = Color(1.0, 0.8, 0.3, 0.7)
	sb_pill.set_border_width_all(1)
	sb_pill.set_corner_radius_all(8)
	sb_pill.content_margin_left = 10
	sb_pill.content_margin_right = 10
	sb_pill.content_margin_top = 3
	sb_pill.content_margin_bottom = 3
	badge_pill.add_theme_stylebox_override("panel", sb_pill)
	
	var lbl_badge = Label.new()
	lbl_badge.name = "LblBadge"
	lbl_badge.text = "QUADRO %d" % (indice + 1)
	lbl_badge.add_theme_font_override("font", font_titulo)
	lbl_badge.add_theme_font_size_override("font_size", 11)
	lbl_badge.add_theme_color_override("font_color", Color(1.0, 0.82, 0.3))
	badge_pill.add_child(lbl_badge)
	hbox_badge.add_child(badge_pill)
	
	# titulo do quadro
	var lbl_titulo_q = Label.new()
	lbl_titulo_q.name = "LblTitulo"
	lbl_titulo_q.text = "Título do Quadro"
	lbl_titulo_q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_titulo_q.add_theme_font_override("font", font_titulo)
	lbl_titulo_q.add_theme_font_size_override("font_size", 15)
	lbl_titulo_q.add_theme_color_override("font_color", Color(0.98, 0.96, 0.92))
	vbox.add_child(lbl_titulo_q)
	
	# moldura da ilustracao vetorial com fundo de observatorio
	var moldura_ilustracao = PanelContainer.new()
	moldura_ilustracao.custom_minimum_size = Vector2(0, 138)
	moldura_ilustracao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb_mold = StyleBoxFlat.new()
	sb_mold.bg_color = Color(0.02, 0.03, 0.05, 0.98)
	sb_mold.border_color = Color(0.35, 0.45, 0.65, 0.5)
	sb_mold.set_border_width_all(1)
	sb_mold.set_corner_radius_all(8)
	moldura_ilustracao.add_theme_stylebox_override("panel", sb_mold)
	
	# canvas de desenho procedimental rico
	var canvas_arte = Control.new()
	canvas_arte.name = "CanvasArte"
	canvas_arte.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas_arte.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas_arte.draw.connect(_desenhar_arte_quadro.bind(canvas_arte))
	moldura_ilustracao.add_child(canvas_arte)
	vbox.add_child(moldura_ilustracao)
	
	# texto da narrativa histórica
	var lbl_texto = RichTextLabel.new()
	lbl_texto.name = "LblTexto"
	lbl_texto.bbcode_enabled = true
	lbl_texto.fit_content = true
	lbl_texto.scroll_active = false
	lbl_texto.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lbl_texto.add_theme_font_override("normal_font", font_sans)
	lbl_texto.add_theme_font_size_override("normal_font_size", 13)
	vbox.add_child(lbl_texto)
	
	# caixa de destaque para citação ou marco científico com barra lateral
	var painel_marco = PanelContainer.new()
	painel_marco.name = "PainelMarco"
	var sb_marco = StyleBoxFlat.new()
	sb_marco.bg_color = Color(0.07, 0.09, 0.14, 0.92)
	sb_marco.border_color = Color(0.9, 0.75, 0.3, 0.9)
	sb_marco.border_width_left = 3
	sb_marco.border_width_top = 0
	sb_marco.border_width_right = 0
	sb_marco.border_width_bottom = 0
	sb_marco.set_corner_radius_all(6)
	sb_marco.content_margin_left = 12
	sb_marco.content_margin_right = 12
	sb_marco.content_margin_top = 8
	sb_marco.content_margin_bottom = 8
	painel_marco.add_theme_stylebox_override("panel", sb_marco)
	
	var lbl_marco = Label.new()
	lbl_marco.name = "LblMarco"
	lbl_marco.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_marco.add_theme_font_override("font", font_sans)
	lbl_marco.add_theme_font_size_override("font_size", 12)
	lbl_marco.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4))
	painel_marco.add_child(lbl_marco)
	vbox.add_child(painel_marco)
	
	return card

func _configurar_quadro_conteudo(card: PanelContainer, dados: Dictionary) -> void:
	var lbl_badge = card.find_child("LblBadge", true, false) as Label
	var badge_pill = card.find_child("BadgePill", true, false) as PanelContainer
	var lbl_titulo = card.find_child("LblTitulo", true, false) as Label
	var lbl_texto = card.find_child("LblTexto", true, false) as RichTextLabel
	var lbl_marco = card.find_child("LblMarco", true, false) as Label
	var painel_marco = card.find_child("PainelMarco", true, false) as PanelContainer
	var canvas_arte = card.find_child("CanvasArte", true, false) as Control
	
	var cor_tema: Color = dados.get("cor", Color.GOLD)
	
	if lbl_badge:
		lbl_badge.text = dados.get("badge", "QUADRO")
		lbl_badge.add_theme_color_override("font_color", cor_tema)
		
	if badge_pill:
		var sb_pill = badge_pill.get_theme_stylebox("panel") as StyleBoxFlat
		if sb_pill:
			sb_pill.border_color = Color(cor_tema.r, cor_tema.g, cor_tema.b, 0.75)
			sb_pill.bg_color = Color(cor_tema.r, cor_tema.g, cor_tema.b, 0.12)
			
	# Atualiza a borda do cartão com a cor do tema
	var sb_card = card.get_theme_stylebox("panel") as StyleBoxFlat
	if sb_card:
		sb_card.border_color = Color(cor_tema.r, cor_tema.g, cor_tema.b, 0.85)
		sb_card.shadow_color = Color(cor_tema.r, cor_tema.g, cor_tema.b, 0.22)
		
	if lbl_titulo:
		lbl_titulo.text = dados.get("titulo", "")
		
	if lbl_texto:
		lbl_texto.text = "[color=#dce5f2]" + dados.get("texto", "") + "[/color]"
		
	if lbl_marco:
		lbl_marco.text = dados.get("marco", "")
		lbl_marco.add_theme_color_override("font_color", cor_tema)
		
	if painel_marco:
		var sb_marco = painel_marco.get_theme_stylebox("panel") as StyleBoxFlat
		if sb_marco:
			sb_marco.border_color = cor_tema
	
	if canvas_arte:
		canvas_arte.set_meta("tipo", dados.get("icone_tipo", "alquimia"))
		canvas_arte.set_meta("cor", cor_tema)
		canvas_arte.queue_redraw()

# Desenho procedural de alta fidelidade para as 9 ilustrações históricas
func _desenhar_arte_quadro(canvas: Control) -> void:
	var rect = canvas.get_rect()
	var center = rect.size * 0.5
	var tipo = canvas.get_meta("tipo", "alquimia")
	var cor: Color = canvas.get_meta("cor", Color.GOLD)
	
	# 1. Aura radial suave de iluminação
	canvas.draw_circle(center, 54.0, Color(cor.r, cor.g, cor.b, 0.08))
	canvas.draw_circle(center, 34.0, Color(cor.r, cor.g, cor.b, 0.14))
	canvas.draw_circle(center, 18.0, Color(cor.r, cor.g, cor.b, 0.20))
	
	# 2. Retículo astronômico / anel de blueprint alquímico
	canvas.draw_arc(center, 50.0, 0.0, TAU, 32, Color(cor.r, cor.g, cor.b, 0.16), 1.0, true)
	canvas.draw_line(center + Vector2(-55, 0), center + Vector2(-45, 0), Color(cor.r, cor.g, cor.b, 0.3), 1.0)
	canvas.draw_line(center + Vector2(45, 0), center + Vector2(55, 0), Color(cor.r, cor.g, cor.b, 0.3), 1.0)
	canvas.draw_line(center + Vector2(0, -55), center + Vector2(0, -45), Color(cor.r, cor.g, cor.b, 0.3), 1.0)
	canvas.draw_line(center + Vector2(0, 45), center + Vector2(0, 55), Color(cor.r, cor.g, cor.b, 0.3), 1.0)

	match tipo:
		"alquimia":
			# Fogo ardente sob o caldeirão
			canvas.draw_circle(center + Vector2(-8, 30), 8.0, Color(1.0, 0.25, 0.1, 0.7))
			canvas.draw_circle(center + Vector2(8, 30), 8.0, Color(1.0, 0.25, 0.1, 0.7))
			canvas.draw_circle(center + Vector2(0, 26), 10.0, Color(1.0, 0.65, 0.1, 0.9))
			canvas.draw_circle(center + Vector2(0, 24), 5.0, Color(1.0, 0.95, 0.4, 1.0))
			
			# Tripé de ferro fundido
			canvas.draw_line(center + Vector2(-26, 38), center + Vector2(-16, 18), Color(0.3, 0.32, 0.4), 3.0)
			canvas.draw_line(center + Vector2(26, 38), center + Vector2(16, 18), Color(0.3, 0.32, 0.4), 3.0)
			
			# Corpo do caldeirão
			canvas.draw_circle(center + Vector2(0, 10), 28.0, Color(0.16, 0.18, 0.24))
			canvas.draw_circle(center + Vector2(0, 10), 25.0, Color(0.10, 0.08, 0.15))
			# Bordas e alças do caldeirão
			canvas.draw_arc(center + Vector2(-26, 8), 6.0, -PI*0.5, PI*0.5, 12, Color(0.4, 0.45, 0.55), 2.5)
			canvas.draw_arc(center + Vector2(26, 8), 6.0, PI*0.5, PI*1.5, 12, Color(0.4, 0.45, 0.55), 2.5)
			canvas.draw_line(center + Vector2(-26, 4), center + Vector2(26, 4), Color(0.5, 0.55, 0.65), 4.0)
			
			# Poção mágica fervilhante
			canvas.draw_circle(center + Vector2(0, 6), 20.0, cor)
			canvas.draw_circle(center + Vector2(-6, 2), 6.0, Color(1.0, 0.85, 1.0, 0.9))
			
			# Bolhas luminosas em suspensão
			canvas.draw_circle(center + Vector2(-10, -18), 5.0, cor)
			canvas.draw_circle(center + Vector2(-11, -19), 1.5, Color.WHITE)
			canvas.draw_circle(center + Vector2(6, -26), 6.0, Color(1.0, 0.6, 1.0))
			canvas.draw_circle(center + Vector2(5, -27), 2.0, Color.WHITE)
			canvas.draw_circle(center + Vector2(18, -14), 4.0, cor)
			
			# Frasco de vidro graduado ao lado
			var fx = center.x + 38
			var fy = center.y + 4
			canvas.draw_rect(Rect2(fx - 8, fy - 18, 16, 26), Color(0.4, 0.8, 1.0, 0.5), false, 2.0)
			canvas.draw_rect(Rect2(fx - 6, fy - 6, 12, 12), Color(0.2, 0.7, 1.0, 0.85))
			canvas.draw_line(Vector2(fx - 6, fy - 18), Vector2(fx + 6, fy - 18), Color(0.7, 0.5, 0.3), 3.0) # Rolha

		"balanca":
			# Cúpula de vidro protetora (Lavoisier)
			canvas.draw_arc(center + Vector2(0, -6), 46.0, -PI, 0.0, 24, Color(0.4, 0.8, 1.0, 0.25), 1.5, true)
			
			# Pilar central e pedestal ornamental
			canvas.draw_rect(Rect2(center.x - 30, center.y + 36, 60, 6), Color(0.85, 0.70, 0.25))
			canvas.draw_rect(Rect2(center.x - 20, center.y + 32, 40, 4), Color(1.0, 0.85, 0.35))
			canvas.draw_line(center + Vector2(0, -32), center + Vector2(0, 32), Color(1.0, 0.85, 0.3), 4.0)
			
			# Eixo fulcro central com mancal circular
			canvas.draw_circle(center + Vector2(0, -20), 7.0, Color(1.0, 0.9, 0.4))
			canvas.draw_circle(center + Vector2(0, -20), 3.0, Color(0.4, 0.25, 0.1))
			
			# Ponteiro indicador de equilíbrio
			canvas.draw_line(center + Vector2(0, -20), center + Vector2(0, -34), Color(1.0, 0.3, 0.3), 2.0)
			
			# Braço horizontal perfeitamente nivelado
			canvas.draw_line(center + Vector2(-54, -20), center + Vector2(54, -20), Color(1.0, 0.85, 0.35), 3.5)
			
			# Prato esquerdo com correntes
			canvas.draw_line(center + Vector2(-54, -20), center + Vector2(-66, 12), Color(0.7, 0.8, 0.95), 1.5)
			canvas.draw_line(center + Vector2(-54, -20), center + Vector2(-42, 12), Color(0.7, 0.8, 0.95), 1.5)
			canvas.draw_arc(center + Vector2(-54, 12), 16.0, 0.0, PI, 16, Color(1.0, 0.85, 0.3), 3.0)
			# Matéria reagente no prato esquerdo (minerais)
			canvas.draw_circle(center + Vector2(-58, 10), 5.0, Color(0.4, 0.9, 1.0))
			canvas.draw_circle(center + Vector2(-50, 8), 6.0, Color(0.3, 0.7, 0.95))
			
			# Prato direito com correntes
			canvas.draw_line(center + Vector2(54, -20), center + Vector2(42, 12), Color(0.7, 0.8, 0.95), 1.5)
			canvas.draw_line(center + Vector2(54, -20), center + Vector2(66, 12), Color(0.7, 0.8, 0.95), 1.5)
			canvas.draw_arc(center + Vector2(54, 12), 16.0, 0.0, PI, 16, Color(1.0, 0.85, 0.3), 3.0)
			# Pesos de latão calibrados no prato direito
			canvas.draw_rect(Rect2(center.x + 48, center.y + 4, 12, 10), Color(1.0, 0.8, 0.2))
			canvas.draw_rect(Rect2(center.x + 50, center.y - 2, 8, 6), Color(1.0, 0.9, 0.3))

		"atomo":
			# Núcleo atômico com múltiplos núcleons
			var posicoes_nucleo = [
				Vector2(0, 0), Vector2(-5, -4), Vector2(5, -3),
				Vector2(-4, 5), Vector2(4, 4), Vector2(0, -6)
			]
			for idx in range(posicoes_nucleo.size()):
				var p = center + posicoes_nucleo[idx]
				var cor_nucleon = Color(1.0, 0.85, 0.3) if (idx % 2 == 0) else Color(0.3, 0.9, 0.8)
				canvas.draw_circle(p, 5.5, cor_nucleon)
				canvas.draw_circle(p + Vector2(-1.5, -1.5), 1.5, Color.WHITE)
			
			# Três órbitas elípticas de elétrons (modelo quântico)
			var r_orb = 50.0
			var angulos = [0.0, PI / 3.0, (2.0 * PI) / 3.0]
			for ang in angulos:
				var pts: PackedVector2Array = []
				for step in range(33):
					var t = step * (TAU / 32.0)
					var x_local = cos(t) * r_orb
					var y_local = sin(t) * 16.0
					var rot_x = x_local * cos(ang) - y_local * sin(ang)
					var rot_y = x_local * sin(ang) + y_local * cos(ang)
					pts.append(center + Vector2(rot_x, rot_y))
				canvas.draw_polyline(pts, Color(0.4, 0.85, 1.0, 0.45), 1.5, true)
				
				# Elétron na órbita com cauda brilhante
				var e_pos = pts[8]
				canvas.draw_circle(e_pos, 4.5, Color(0.4, 1.0, 0.8))
				canvas.draw_circle(e_pos, 2.0, Color.WHITE)

		"newton":
			# Prisma óptico refrator de Newton
			var p_prism_top = center + Vector2(-22, -26)
			var p_prism_left = center + Vector2(-46, 22)
			var p_prism_right = center + Vector2(2, 22)
			var pts_prism = PackedVector2Array([p_prism_top, p_prism_left, p_prism_right, p_prism_top])
			canvas.draw_colored_polygon(pts_prism, Color(0.3, 0.6, 1.0, 0.25))
			canvas.draw_polyline(pts_prism, Color(0.6, 0.85, 1.0, 0.8), 2.0, true)
			
			# Raio de luz branca incidente
			canvas.draw_line(center + Vector2(-64, -2), center + Vector2(-24, -2), Color.WHITE, 2.5)
			
			# Espectro visível decomposto (arco-íris de Newton)
			var cores_espectro = [
				Color(1.0, 0.2, 0.2), # Vermelho
				Color(1.0, 0.6, 0.1), # Laranja
				Color(1.0, 0.95, 0.2), # Amarelo
				Color(0.2, 0.9, 0.3), # Verde
				Color(0.2, 0.7, 1.0), # Ciano
				Color(0.7, 0.3, 1.0)  # Violeta
			]
			for idx in range(cores_espectro.size()):
				var y_dest = -16.0 + (idx * 6.5)
				canvas.draw_line(center + Vector2(-8, -2), center + Vector2(48, y_dest), cores_espectro[idx], 2.0)
				
			# Maçã gravitacional de Newton
			var p_maca = center + Vector2(46, 20)
			canvas.draw_circle(p_maca, 9.0, Color(0.95, 0.2, 0.2))
			canvas.draw_circle(p_maca + Vector2(-2, -2), 2.5, Color(1.0, 0.6, 0.6))
			canvas.draw_line(p_maca, p_maca + Vector2(2, -8), Color(0.45, 0.25, 0.1), 2.0) # Cabinho
			canvas.draw_circle(p_maca + Vector2(4, -7), 2.5, Color(0.3, 0.8, 0.3)) # Folhinha

		"raio":
			# Solenóides / Bobinas eletromagnéticas de Faraday
			var b1 = center + Vector2(-42, 0)
			var b2 = center + Vector2(42, 0)
			
			# Enrolamentos de cobre
			for x_off in [-4, 0, 4]:
				canvas.draw_rect(Rect2(b1.x + x_off - 4, b1.y - 18, 6, 36), Color(0.85, 0.5, 0.2))
				canvas.draw_rect(Rect2(b2.x + x_off - 4, b2.y - 18, 6, 36), Color(0.85, 0.5, 0.2))
			canvas.draw_circle(b1 + Vector2(12, 0), 6.0, Color(1.0, 0.85, 0.3))
			canvas.draw_circle(b2 + Vector2(-12, 0), 6.0, Color(1.0, 0.85, 0.3))
			
			# Linhas de campo magnético curvas
			canvas.draw_arc(center, 40.0, -PI*0.7, -PI*0.3, 16, Color(0.3, 0.8, 1.0, 0.4), 1.5, true)
			canvas.draw_arc(center, 40.0, PI*0.3, PI*0.7, 16, Color(0.3, 0.8, 1.0, 0.4), 1.5, true)
			
			# Raio / Fagulha elétrica intensa entre eletrodos
			var pts_raio = PackedVector2Array([
				b1 + Vector2(12, 0),
				center + Vector2(-16, -14),
				center + Vector2(-4, 12),
				center + Vector2(10, -10),
				center + Vector2(18, 8),
				b2 + Vector2(-12, 0)
			])
			canvas.draw_polyline(pts_raio, Color(1.0, 0.9, 0.2, 0.6), 5.0, true)
			canvas.draw_polyline(pts_raio, Color.WHITE, 2.0, true)
			# Faíscas radiais
			canvas.draw_circle(center + Vector2(-4, 12), 3.0, Color(0.5, 1.0, 1.0))
			canvas.draw_circle(center + Vector2(10, -10), 3.0, Color(1.0, 1.0, 0.6))

		"otica":
			# Lente biconvexa de vidro óptico
			var pts_lente_esq: PackedVector2Array = []
			var pts_lente_dir: PackedVector2Array = []
			for step in range(-16, 17):
				var y = step * 2.2
				var curve = cos((step / 16.0) * (PI * 0.5)) * 14.0
				pts_lente_esq.append(center + Vector2(-curve, y))
				pts_lente_dir.append(center + Vector2(curve, y))
			pts_lente_dir.reverse()
			var poligono_lente = pts_lente_esq + pts_lente_dir
			canvas.draw_colored_polygon(poligono_lente, Color(0.35, 0.7, 1.0, 0.3))
			canvas.draw_polyline(poligono_lente, Color(0.6, 0.9, 1.0, 0.85), 2.0, true)
			
			# Raios de luz paralelos incidentes
			var ys = [-22.0, 0.0, 22.0]
			var foco = center + Vector2(48, 0)
			for y_val in ys:
				canvas.draw_line(center + Vector2(-58, y_val), center + Vector2(-8, y_val), Color(1.0, 0.92, 0.4), 2.0)
				canvas.draw_line(center + Vector2(8, y_val), foco, Color(1.0, 0.92, 0.4), 2.0)
				
			# Ponto focal estelar resplandecente
			canvas.draw_circle(foco, 8.0, Color(1.0, 0.95, 0.5, 0.6))
			canvas.draw_circle(foco, 3.5, Color.WHITE)
			canvas.draw_line(foco + Vector2(-8, 0), foco + Vector2(8, 0), Color.WHITE, 1.5)
			canvas.draw_line(foco + Vector2(0, -8), foco + Vector2(0, 8), Color.WHITE, 1.5)
			# Ondas esféricas emergindo do foco
			canvas.draw_arc(foco, 12.0, -PI*0.4, PI*0.4, 12, Color(1.0, 0.9, 0.5, 0.5), 1.5)
			canvas.draw_arc(foco, 20.0, -PI*0.4, PI*0.4, 12, Color(1.0, 0.9, 0.5, 0.3), 1.5)

		"celula":
			# Campo de visão do microscópio
			canvas.draw_arc(center, 44.0, 0.0, TAU, 32, Color(0.3, 0.8, 0.5, 0.4), 1.5, true)
			
			# Membrana plasmática dupla da célula
			canvas.draw_rect(Rect2(center.x - 38, center.y - 26, 76, 52), Color(0.12, 0.45, 0.22, 0.6), false, 4.0)
			canvas.draw_rect(Rect2(center.x - 36, center.y - 24, 72, 48), Color(0.25, 0.75, 0.35), false, 1.5)
			
			# Núcleo celular com nucléolo
			canvas.draw_circle(center + Vector2(-8, 0), 13.0, Color(0.85, 0.3, 0.65))
			canvas.draw_circle(center + Vector2(-8, 0), 5.0, Color(1.0, 0.8, 0.95))
			
			# Mitocôndrias com dobras internas
			canvas.draw_rect(Rect2(center.x + 14, center.y - 16, 16, 9), Color(0.9, 0.45, 0.2), true)
			canvas.draw_line(center + Vector2(16, -11), center + Vector2(28, -11), Color(1.0, 0.8, 0.4), 1.5)
			
			# Cloroplastos bioluminescentes
			var pos_cloro = [Vector2(18, 12), Vector2(-22, -14), Vector2(-24, 12)]
			for p_c in pos_cloro:
				canvas.draw_circle(center + p_c, 5.5, Color(0.3, 0.95, 0.4))
				canvas.draw_circle(center + p_c + Vector2(-1, -1), 1.5, Color.WHITE)

		"dna":
			# Dupla hélice em perspectiva tridimensional
			var passos = 8
			for step in range(-passos, passos + 1):
				var y_pos = center.y + (step * 5.8)
				var t = step * 0.45
				var x_off = sin(t) * 28.0
				var z_depth = cos(t) # profundidade
				
				var p1 = Vector2(center.x - x_off, y_pos)
				var p2 = Vector2(center.x + x_off, y_pos)
				
				# Par de bases nitrogenadas (A-T / C-G)
				if abs(x_off) > 4:
					var cor_base_a = Color(0.3, 0.95, 0.6) if step % 2 == 0 else Color(1.0, 0.8, 0.2)
					var cor_base_b = Color(0.2, 0.7, 1.0) if step % 2 == 0 else Color(1.0, 0.35, 0.7)
					canvas.draw_line(p1, Vector2(center.x, y_pos), cor_base_a, 2.2)
					canvas.draw_line(Vector2(center.x, y_pos), p2, cor_base_b, 2.2)
					canvas.draw_circle(Vector2(center.x, y_pos), 1.5, Color.WHITE)
				
				# Fitas de açúcar-fosfato (Cyan e Magenta)
				var raio_esfera = 3.8 if z_depth >= 0 else 2.6
				var alpha_esfera = 1.0 if z_depth >= 0 else 0.55
				canvas.draw_circle(p1, raio_esfera, Color(0.3, 0.85, 1.0, alpha_esfera))
				canvas.draw_circle(p2, raio_esfera, Color(1.0, 0.4, 0.85, alpha_esfera))

		"sintese":
			# Triângulo das três ciências fundamentais
			var p_quimica = center + Vector2(0, -32)
			var p_fisica = center + Vector2(-36, 24)
			var p_bio = center + Vector2(36, 24)
			
			# Dutos de energia pulsante entre os vértices
			canvas.draw_line(p_quimica, p_fisica, Color(1.0, 0.8, 0.3, 0.85), 2.5)
			canvas.draw_line(p_fisica, p_bio, Color(0.3, 0.85, 1.0, 0.85), 2.5)
			canvas.draw_line(p_bio, p_quimica, Color(0.4, 1.0, 0.5, 0.85), 2.5)
			
			# Esferas de poder científico
			canvas.draw_circle(p_quimica, 9.0, Color(1.0, 0.85, 0.3)) # Química
			canvas.draw_circle(p_quimica, 3.0, Color.WHITE)
			canvas.draw_circle(p_fisica, 9.0, Color(0.3, 0.85, 1.0))  # Física
			canvas.draw_circle(p_fisica, 3.0, Color.WHITE)
			canvas.draw_circle(p_bio, 9.0, Color(0.4, 1.0, 0.5))     # Biologia
			canvas.draw_circle(p_bio, 3.0, Color.WHITE)
			
			# Núcleo da Grande Síntese
			canvas.draw_circle(center, 14.0, Color(1.0, 1.0, 1.0, 0.9))
			canvas.draw_circle(center, 8.0, Color(1.0, 0.9, 0.4))
			# Raios de luz estelar de 8 pontas
			for ang_s in [0.0, PI*0.25, PI*0.5, PI*0.75]:
				var v = Vector2(cos(ang_s), sin(ang_s)) * 22.0
				canvas.draw_line(center - v, center + v, Color(1.0, 1.0, 0.8, 0.8), 2.0)

func _on_btn_avancar_pressed() -> void:
	if _concluida: return
	
	if _quadro_revelado < 3:
		_revelar_proximo_quadro()
	else:
		_mostrar_tela_vitoria()

func _input(event: InputEvent) -> void:
	if _concluida: return
	
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)):
		get_viewport().set_input_as_handled()
		if _em_tela_vitoria:
			_encerrar_vinheta()
		else:
			_on_btn_avancar_pressed()
	elif _em_tela_vitoria and (event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE)):
		get_viewport().set_input_as_handled()
		_encerrar_vinheta()

func _revelar_proximo_quadro() -> void:
	if _quadro_revelado >= 3:
		return
		
	var idx = _quadro_revelado
	_quadro_revelado += 1
	_lbl_contador.text = "Quadro %d de 3  •  [ Espaço ] para Avançar" % _quadro_revelado
	
	var card = _quadros_nodes[idx]
	card.visible = true
	
	# som de virar página ou vitória no terceiro
	if get_node_or_null("/root/AudioManager"):
		if _quadro_revelado == 3:
			AudioManager.play_sfx("win")
		else:
			AudioManager.play_sfx("transicao-1")
			
	# animação cinematográfica de slide e fade in
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "modulate:a", 1.0, 0.35)
	tw.tween_property(card, "scale", Vector2.ONE, 0.35)
	
	# atualiza o botao
	if _quadro_revelado == 3:
		_btn_avancar.text = "Concluir Crônicas & Ver Vitória ▶ (Espaço)"
		var sb_b = _btn_avancar.get_theme_stylebox("normal") as StyleBoxFlat
		if sb_b:
			sb_b.bg_color = Color(0.15, 0.45, 0.25, 1.0)
			sb_b.border_color = Color(0.4, 1.0, 0.6)
	else:
		_btn_avancar.text = "Revelar Próximo Quadro ▶ (Espaço)"
		
	_btn_avancar.grab_focus()

# Tela de vitória do andar: 100% centralizada, sem tempo limite, com botão vermelho superior para fechar
func _mostrar_tela_vitoria() -> void:
	if _em_tela_vitoria or _concluida: return
	_em_tela_vitoria = true
	
	# toca som de vitoria triunfal
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("win")
		
	# oculta suavemente o conteudo dos 3 quadros
	if _margin_conteudo and is_instance_valid(_margin_conteudo):
		var tw_fade = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw_fade.tween_property(_margin_conteudo, "modulate:a", 0.0, 0.25)
		tw_fade.tween_callback(func(): _margin_conteudo.visible = false)
		
	# Verifica quais andares foram concluídos e quais ainda estão pendentes
	var concluidos: Array = []
	if get_node_or_null("/root/PlayerStats") and PlayerStats.get("vinhetas_desbloqueadas") != null:
		concluidos = PlayerStats.vinhetas_desbloqueadas.duplicate()
	if not concluidos.has(_andar_atual):
		concluidos.append(_andar_atual)
		
	var pendentes: Array = []
	for id_andar in [1, 2, 3]:
		if not concluidos.has(id_andar):
			pendentes.append(id_andar)

	# Estilo e textos base pelo andar recém-concluído
	var cor_tema = Color(1.0, 0.85, 0.3)
	var cor_borda = Color(1.0, 0.8, 0.25, 0.95)
	var badge_texto = "✦ ANDAR DE QUÍMICA CONCLUÍDO ✦"
	var titulo_texto = "PARABÉNS! VITÓRIA ALQUÍMICA!"
	var subtitulo_texto = "A Matéria foi Desvendada e a Alquimia Transformou-se em Ciência!"
	var conquista_texto = "Você dominou as reações, purificou os caldeirões corrompidos e derrotou o Guardião da Alquimia com inteligência e estratégia."
	
	if _andar_atual == 2:
		cor_tema = Color(0.35, 0.85, 1.0)
		cor_borda = Color(0.4, 0.9, 1.0, 0.95)
		badge_texto = "✦ ANDAR DE FÍSICA CONCLUÍDO ✦"
		titulo_texto = "PARABÉNS! TRIUNFO DAS FORÇAS CÓSMICAS!"
		subtitulo_texto = "O Relâmpago foi Domado e as Leis do Movimento Foram Conquistadas!"
		conquista_texto = "Você resistiu às anomalias magnéticas, subjugou a inércia e derrotou o Guardião da Física com raciocínio e precisão."
	elif _andar_atual == 3:
		cor_tema = Color(0.45, 1.0, 0.65)
		cor_borda = Color(0.5, 1.0, 0.7, 0.95)
		badge_texto = "✦ ANDAR DE BIOLOGIA CONCLUÍDO ✦"
		titulo_texto = "PARABÉNS! SOBERANIA DA VIDA!"
		subtitulo_texto = "A Teia da Criação foi Desvendada e a Vida Revelou seus Segredos!"
		conquista_texto = "Você desvendou as máquinas celulares, compreendeu o código do DNA e superou as provações do Guardião da Vida."

	# Textos dinâmicos baseados no progresso global (ordem livre de andares)
	var proximo_texto = ""
	var conselho_texto = ""
	
	if pendentes.is_empty():
		badge_texto = "👑 A GRANDE SÍNTESE ALCANÇADA 👑"
		titulo_texto = "MESTRE SUPREMO DA SÍNTESE!"
		subtitulo_texto = "Química, Física e Biologia Unidas na Mais Perfeita Sinfonia do Saber!"
		conquista_texto = "Extraordinário! Você superou as provações de todos os três domínios sagrados da Masmorra Arcana!"
		proximo_texto = "O labirinto do saber foi totalmente purificado. As barreiras entre matéria, energias e vida se uniram na Grande Síntese Arcana!"
		conselho_texto = "Você provou que o conhecimento científico comprovado é a maior e mais bela magia do universo. Parabéns pelo triunfo supremo!"
	elif pendentes.size() == 1:
		var prox_id = pendentes[0]
		if prox_id == 2:
			proximo_texto = "Apenas o Andar de Física resta para a Grande Síntese! No saguão central (Hub), o portal de energia aguarda sua coragem: abaixo, as leis da gravidade de Newton, campos magnéticos e relâmpagos arcanos de Faraday desafiarão seus conhecimentos!"
			conselho_texto = "Retorne vitorioso ao Hub! Renove seus elixires e prepare-se para encarar o domínio das forças e da eletricidade."
		elif prox_id == 3:
			proximo_texto = "Apenas o Andar de Biologia resta para a Grande Síntese! No saguão central (Hub), o portal da natureza aguarda sua coragem: prepare-se para decifrar a teia viva das células, os mistérios da evolução e a sagrada espiral do DNA!"
			conselho_texto = "Retorne vitorioso ao Hub! Renove seus elixires e prepare-se para adentrar o coração pulsante da vida."
		else:
			proximo_texto = "Apenas o Andar de Química resta para a Grande Síntese! No saguão central (Hub), o portal alquímico aguarda sua coragem: prepare-se para decifrar as transmutações de Lavoisier, as reações puras e a orquestra dos átomos!"
			conselho_texto = "Retorne vitorioso ao Hub! Renove seus elixires e prepare-se para desvendar os segredos da matéria."
	else:
		if _andar_atual == 1:
			proximo_texto = "Você concluiu o Andar de Química! No saguão central (Hub), você agora pode escolher livremente seu próximo desafio: encarar as leis da gravidade de Newton, campos magnéticos e relâmpagos arcanos de Faraday no Andar de Física, ou desvendar os códigos celulares no Andar de Biologia!"
			conselho_texto = "Retorne ao Hub e escolha seu próximo caminho. Lembre-se: uma vez iniciada uma expedição, você deve concluí-la para poder trocar de andar!"
		elif _andar_atual == 2:
			proximo_texto = "Você concluiu o Andar de Física! No saguão central (Hub), você agora pode escolher livremente seu próximo desafio: dominar as transmutações e reações no Andar de Química, ou explorar os códigos celulares e a evolução no Andar de Biologia!"
			conselho_texto = "Retorne ao Hub e escolha seu próximo caminho. Lembre-se: uma vez iniciada uma expedição, você deve concluí-la para poder trocar de andar!"
		else:
			proximo_texto = "Você concluiu o Andar de Biologia! No saguão central (Hub), você agora pode escolher livremente seu próximo desafio: encarar as leis da gravidade de Newton, campos magnéticos e relâmpagos arcanos de Faraday no Andar de Física, ou dominar as reações e a matéria no Andar de Química!"
			conselho_texto = "Retorne ao Hub e escolha seu próximo caminho. Lembre-se: uma vez iniciada uma expedição, você deve concluí-la para poder trocar de andar!"

	# Container de sobreposição da tela de vitória
	_container_vitoria = Control.new()
	_container_vitoria.name = "TelaVitoria"
	_container_vitoria.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_container_vitoria)
	
	# Fundo escurecido semi-transparente
	var bg_dim = ColorRect.new()
	bg_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_dim.color = Color(0.02, 0.03, 0.06, 0.88)
	_container_vitoria.add_child(bg_dim)
	
	# Partículas douradas / temáticas de comemoração
	var particulas = CPUParticles2D.new()
	particulas.amount = 50
	particulas.lifetime = 3.0
	particulas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particulas.emission_rect_extents = Vector2(640, 360)
	particulas.position = Vector2(640, 360)
	particulas.gravity = Vector2(0, -30)
	particulas.scale_amount_min = 2.5
	particulas.scale_amount_max = 5.0
	particulas.color = Color(cor_tema.r, cor_tema.g, cor_tema.b, 0.8)
	_container_vitoria.add_child(particulas)
	
	# CenterContainer que GARANTE centralização 100% perfeita na tela
	var center_wrap = CenterContainer.new()
	center_wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	_container_vitoria.add_child(center_wrap)
	
	# Card principal de vitória
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(780, 480)
	card.pivot_offset = Vector2(390, 240)
	
	var sb_card = StyleBoxFlat.new()
	sb_card.bg_color = Color(0.06, 0.08, 0.13, 0.98)
	sb_card.border_color = cor_borda
	sb_card.set_border_width_all(2)
	sb_card.set_corner_radius_all(14)
	sb_card.shadow_color = Color(cor_tema.r, cor_tema.g, cor_tema.b, 0.35)
	sb_card.shadow_size = 28
	sb_card.content_margin_left = 32
	sb_card.content_margin_right = 32
	sb_card.content_margin_top = 22
	sb_card.content_margin_bottom = 22
	card.add_theme_stylebox_override("panel", sb_card)
	center_wrap.add_child(card)
	
	var vbox_card = VBoxContainer.new()
	vbox_card.add_theme_constant_override("separation", 12)
	vbox_card.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox_card)
	
	var font_bold = SystemFont.new()
	font_bold.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_bold.font_weight = 700
	
	var font_normal = SystemFont.new()
	font_normal.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_normal.font_weight = 400
	
	# Barra superior com Badge no centro e Botão Vermelho de Fechar no canto superior direito
	var hbox_topo = HBoxContainer.new()
	hbox_topo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_card.add_child(hbox_topo)
	
	# Espaçador invisível à esquerda para manter o badge perfeitamente centralizado
	var spacer_esq = Control.new()
	spacer_esq.custom_minimum_size = Vector2(90, 0)
	spacer_esq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_topo.add_child(spacer_esq)
	
	# Badge central do andar
	var badge_panel = PanelContainer.new()
	var sb_badge = StyleBoxFlat.new()
	sb_badge.bg_color = Color(cor_tema.r, cor_tema.g, cor_tema.b, 0.16)
	sb_badge.border_color = cor_tema
	sb_badge.set_border_width_all(1)
	sb_badge.set_corner_radius_all(14)
	sb_badge.content_margin_left = 18
	sb_badge.content_margin_right = 18
	sb_badge.content_margin_top = 5
	sb_badge.content_margin_bottom = 5
	badge_panel.add_theme_stylebox_override("panel", sb_badge)
	
	var lbl_badge = Label.new()
	lbl_badge.text = badge_texto
	lbl_badge.add_theme_font_override("font", font_bold)
	lbl_badge.add_theme_font_size_override("font_size", 12)
	lbl_badge.add_theme_color_override("font_color", cor_tema)
	badge_panel.add_child(lbl_badge)
	hbox_topo.add_child(badge_panel)
	
	# Espaçador à direita
	var spacer_dir = Control.new()
	spacer_dir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_topo.add_child(spacer_dir)
	
	# BOTÃO VERMELHO SUPERIOR PARA FECHAR
	_btn_fechar_topo = Button.new()
	_btn_fechar_topo.text = "✕ FECHAR"
	_btn_fechar_topo.custom_minimum_size = Vector2(90, 32)
	_btn_fechar_topo.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_btn_fechar_topo.focus_mode = Control.FOCUS_ALL
	
	var sb_close_norm = StyleBoxFlat.new()
	sb_close_norm.bg_color = Color(0.72, 0.16, 0.20, 0.95)
	sb_close_norm.border_color = Color(1.0, 0.4, 0.45)
	sb_close_norm.set_border_width_all(1)
	sb_close_norm.set_corner_radius_all(8)
	sb_close_norm.content_margin_left = 10
	sb_close_norm.content_margin_right = 10
	sb_close_norm.content_margin_top = 4
	sb_close_norm.content_margin_bottom = 4
	
	var sb_close_hover = StyleBoxFlat.new()
	sb_close_hover.bg_color = Color(0.90, 0.22, 0.26, 1.0)
	sb_close_hover.border_color = Color(1.0, 0.7, 0.75)
	sb_close_hover.set_border_width_all(2)
	sb_close_hover.set_corner_radius_all(8)
	sb_close_hover.shadow_color = Color(0.9, 0.2, 0.3, 0.5)
	sb_close_hover.shadow_size = 8
	sb_close_hover.content_margin_left = 10
	sb_close_hover.content_margin_right = 10
	sb_close_hover.content_margin_top = 4
	sb_close_hover.content_margin_bottom = 4
	
	var sb_close_press = StyleBoxFlat.new()
	sb_close_press.bg_color = Color(0.55, 0.12, 0.15, 1.0)
	sb_close_press.border_color = Color(1.0, 0.3, 0.35)
	sb_close_press.set_border_width_all(1)
	sb_close_press.set_corner_radius_all(8)
	sb_close_press.content_margin_left = 10
	sb_close_press.content_margin_right = 10
	sb_close_press.content_margin_top = 4
	sb_close_press.content_margin_bottom = 4
	
	_btn_fechar_topo.add_theme_stylebox_override("normal", sb_close_norm)
	_btn_fechar_topo.add_theme_stylebox_override("hover", sb_close_hover)
	_btn_fechar_topo.add_theme_stylebox_override("focus", sb_close_hover)
	_btn_fechar_topo.add_theme_stylebox_override("pressed", sb_close_press)
	_btn_fechar_topo.add_theme_font_override("font", font_bold)
	_btn_fechar_topo.add_theme_font_size_override("font_size", 12)
	_btn_fechar_topo.add_theme_color_override("font_color", Color.WHITE)
	_btn_fechar_topo.pressed.connect(_encerrar_vinheta)
	hbox_topo.add_child(_btn_fechar_topo)
	
	# Titulo da vitoria
	var lbl_titulo = Label.new()
	lbl_titulo.text = titulo_texto
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_titulo.add_theme_font_override("font", font_bold)
	lbl_titulo.add_theme_font_size_override("font_size", 22)
	lbl_titulo.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75))
	vbox_card.add_child(lbl_titulo)
	
	# Subtitulo explicativo
	var lbl_sub = Label.new()
	lbl_sub.text = subtitulo_texto
	lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_sub.add_theme_font_override("font", font_normal)
	lbl_sub.add_theme_font_size_override("font_size", 13)
	lbl_sub.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0))
	vbox_card.add_child(lbl_sub)
	
	# Divisor decorativo
	var sep_card = HSeparator.new()
	var sb_sep = StyleBoxLine.new()
	sb_sep.color = Color(cor_tema.r, cor_tema.g, cor_tema.b, 0.35)
	sb_sep.thickness = 1
	sep_card.add_theme_stylebox_override("separator", sb_sep)
	vbox_card.add_child(sep_card)
	
	# Bloco com a lore e orientações do próximo andar
	var box_lore = PanelContainer.new()
	var sb_lore = StyleBoxFlat.new()
	sb_lore.bg_color = Color(0.03, 0.04, 0.08, 0.85)
	sb_lore.set_corner_radius_all(8)
	sb_lore.set_border_width_all(1)
	sb_lore.border_color = Color(cor_tema.r, cor_tema.g, cor_tema.b, 0.25)
	sb_lore.content_margin_left = 22
	sb_lore.content_margin_right = 22
	sb_lore.content_margin_top = 16
	sb_lore.content_margin_bottom = 16
	box_lore.add_theme_stylebox_override("panel", sb_lore)
	
	var vbox_lore = VBoxContainer.new()
	vbox_lore.add_theme_constant_override("separation", 10)
	
	# 1. Conquista
	var lbl_c1 = Label.new()
	lbl_c1.text = "🏆 Conquista: " + conquista_texto
	lbl_c1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_c1.add_theme_font_override("font", font_normal)
	lbl_c1.add_theme_font_size_override("font_size", 12)
	lbl_c1.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	vbox_lore.add_child(lbl_c1)
	
	# 2. Próximo andar
	var lbl_c2 = Label.new()
	lbl_c2.text = "🔮 Próximos Desafios: " + proximo_texto
	lbl_c2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_c2.add_theme_font_override("font", font_normal)
	lbl_c2.add_theme_font_size_override("font_size", 12)
	lbl_c2.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	vbox_lore.add_child(lbl_c2)
	
	# 3. Conselho
	var lbl_c3 = Label.new()
	lbl_c3.text = "💡 Conselho: " + conselho_texto
	lbl_c3.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_c3.add_theme_font_override("font", font_normal)
	lbl_c3.add_theme_font_size_override("font_size", 12)
	lbl_c3.add_theme_color_override("font_color", cor_tema)
	vbox_lore.add_child(lbl_c3)
	
	box_lore.add_child(vbox_lore)
	vbox_card.add_child(box_lore)
	
	# Rodapé centralizado com o botão principal de retorno ao Hub
	var hbox_foot = HBoxContainer.new()
	hbox_foot.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_foot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_card.add_child(hbox_foot)
	
	_btn_ir_hub = Button.new()
	_btn_ir_hub.text = "✦ RETORNAR AO SAGUÃO (HUB) ✦ ▶ (Espaço / Enter)"
	_btn_ir_hub.custom_minimum_size = Vector2(400, 44)
	_btn_ir_hub.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_btn_ir_hub.focus_mode = Control.FOCUS_ALL
	
	var sb_b_norm = StyleBoxFlat.new()
	sb_b_norm.bg_color = Color(0.14, 0.38, 0.25, 0.95)
	sb_b_norm.border_color = Color(0.4, 0.9, 0.6)
	sb_b_norm.set_border_width_all(2)
	sb_b_norm.set_corner_radius_all(8)
	sb_b_norm.content_margin_left = 18
	sb_b_norm.content_margin_right = 18
	sb_b_norm.shadow_color = Color(0.2, 0.6, 0.35, 0.35)
	sb_b_norm.shadow_size = 10
	
	var sb_b_hov = StyleBoxFlat.new()
	sb_b_hov.bg_color = Color(0.20, 0.52, 0.35, 1.0)
	sb_b_hov.border_color = Color(0.6, 1.0, 0.8)
	sb_b_hov.set_border_width_all(2)
	sb_b_hov.set_corner_radius_all(8)
	sb_b_hov.shadow_color = Color(0.4, 1.0, 0.6, 0.5)
	sb_b_hov.shadow_size = 14
	
	_btn_ir_hub.add_theme_stylebox_override("normal", sb_b_norm)
	_btn_ir_hub.add_theme_stylebox_override("hover", sb_b_hov)
	_btn_ir_hub.add_theme_stylebox_override("focus", sb_b_hov)
	_btn_ir_hub.add_theme_font_override("font", font_bold)
	_btn_ir_hub.add_theme_font_size_override("font_size", 14)
	_btn_ir_hub.add_theme_color_override("font_color", Color.WHITE)
	_btn_ir_hub.pressed.connect(_encerrar_vinheta)
	hbox_foot.add_child(_btn_ir_hub)
	
	# Animação suave de entrada do card (escala e opacidade)
	card.scale = Vector2(0.9, 0.9)
	card.modulate.a = 0.0
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "scale", Vector2.ONE, 0.35)
	tw.tween_property(card, "modulate:a", 1.0, 0.28)
	
	_btn_ir_hub.grab_focus()

func _encerrar_vinheta() -> void:
	if _concluida: return
	_concluida = true
	_em_tela_vitoria = false
	
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

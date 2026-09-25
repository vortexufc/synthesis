extends CanvasLayer

signal vinheta_concluida

# Vinheta histórica em pergaminho animado de mago com crônicas científicas

var _andar_atual: int = 1
var _quadro_atual_indice: int = 0
var _concluida: bool = false
var _em_tela_vitoria: bool = false
var _animando_transicao: bool = false

# Nós do pergaminho vertical e seu conteúdo
var _scroll_rect: NinePatchRect = null
var _center_pergaminho: CenterContainer = null
var _container_conteudo: MarginContainer = null

var _lbl_capitulo: Label = null
var _lbl_subtitulo: Label = null
var _lbl_quadro_badge: Label = null
var _lbl_quadro_titulo: Label = null
var _canvas_arte: Control = null
var _lbl_quadro_texto: RichTextLabel = null
var _lbl_marco: Label = null
var _painel_marco: Control = null
var _lbl_contador: Label = null
var _btn_avancar: Button = null

# Tela de vitória do andar
var _container_vitoria: Control = null
var _btn_fechar_topo: Button = null
var _btn_ir_hub: Button = null

# Textos das crônicas dos 3 andares da história
var capitulos = {
	1: { # Andar de Alquimia / Química
		"capitulo": "CRÔNICAS DA QUÍMICA: DA ALQUIMIA AO ÁTOMO",
		"subtitulo": "Como a humanidade substituiu mitos e segredos arcanos por medições exatas.",
		"cor_tema": Color(0.85, 0.50, 0.15),
		"quadros": [
			{
				"badge": "QUADRO I",
				"titulo": "A Era dos Mistérios e Caldeirões",
				"icone_tipo": "alquimia",
				"cor": Color(0.68, 0.22, 0.78),
				"texto": "Durante séculos, os antigos alquimistas buscavam a lendária Pedra Filosofal e elixires de imortalidade em caldeirões escuros. Guiados por rituais secretos e lendas astrológicas, suas receitas eram mistérios transmitidos em códigos cifrados.",
				"marco": "« Buscavam ouro mítico, mas legaram as primeiras tintas, remédios e ligas metálicas à humanidade. »"
			},
			{
				"badge": "QUADRO II",
				"titulo": "A Balança da Razão — Lavoisier",
				"icone_tipo": "balanca",
				"cor": Color(0.82, 0.62, 0.18),
				"texto": "No final do século XVIII, Antoine Lavoisier revolucionou o pensamento humano ao colocar uma balança de precisão absoluta no laboratório. Fechando vidrarias herméticas e pesando tudo antes e depois de queimar substâncias, sepultou as superstições.",
				"marco": "« Na natureza nada se cria, nada se perde, tudo se transforma. » — Antoine Lavoisier"
			},
			{
				"badge": "QUADRO III",
				"titulo": "O Legado Elemental",
				"icone_tipo": "atomo",
				"cor": Color(0.20, 0.65, 0.45),
				"texto": "Ao catalogar os elementos e compreender as trocas atômicas, a matéria foi desvendada! A alquimia tornou-se Química Moderna — e hoje, o alquimista [b][color=#6b1814]{JOGADOR}[/color][/b] gravou seu feito nesta grande síntese da matéria!",
				"marco": "« O alquimista {JOGADOR} provou: a matéria deixou de ser magia arcanista para se tornar uma sinfonia de átomos mensuráveis. »"
			}
		]
	},
	2: { # Andar de Física
		"capitulo": "CRÔNICAS DA FÍSICA: DAS FORÇAS AO RELÂMPAGO",
		"subtitulo": "O domínio das leis do movimento, do magnetismo e das forças cósmicas.",
		"cor_tema": Color(0.20, 0.55, 0.85),
		"quadros": [
			{
				"badge": "QUADRO I",
				"titulo": "A Harmonia dos Corpos — Newton",
				"icone_tipo": "newton",
				"cor": Color(0.25, 0.55, 0.85),
				"texto": "Observando a queda dos corpos na Terra e a órbita suave da Lua, Isaac Newton compreendeu que a mesma gravidade governa o céu e o chão. Três leis fundamentais descreveram matematicamente a inércia, a força e a ação e reação.",
				"marco": "« O universo revelou suas engrenagens mecânicas e leis matemáticas universais. » — Isaac Newton"
			},
			{
				"badge": "QUADRO II",
				"titulo": "A Fagulha do Progresso — Faraday & Maxwell",
				"icone_tipo": "raio",
				"cor": Color(0.85, 0.68, 0.15),
				"texto": "Físicos descobriram que magnetismo e eletricidade são a mesma força. Girando ímãs dentro de fios de cobre, Michael Faraday domou o relâmpago, criando motores e geradores que transformaram vilarejos escuros em metrópoles iluminadas.",
				"marco": "« A eletricidade e o magnetismo unidos ergueram os motores da civilização moderna. » — Michael Faraday"
			},
			{
				"badge": "QUADRO III",
				"titulo": "A Luz e a Energia Cósmica",
				"icone_tipo": "otica",
				"cor": Color(0.35, 0.48, 0.82),
				"texto": "Compreendendo a ótica, a mecânica e o eletromagnetismo, instrumentos desvendaram os segredos do cosmos. Com determinação, o sábio [b][color=#123b63]{JOGADOR}[/color][/b] dominou as forças e energias fundamentais do universo!",
				"marco": "« Que os céus testemunhem: {JOGADOR} dominou as leis que regem a queda de um fruto e movem as estrelas do cosmos. »"
			}
		]
	},
	3: { # Andar de Biologia
		"capitulo": "CRÔNICAS DA BIOLOGIA: A ESPIRAL DA VIDA",
		"subtitulo": "A revelação da célula viva, da evolução e do código sagrado da vida.",
		"cor_tema": Color(0.20, 0.65, 0.35),
		"quadros": [
			{
				"badge": "QUADRO I",
				"titulo": "A Descoberta da Célula Viva",
				"icone_tipo": "celula",
				"cor": Color(0.25, 0.65, 0.32),
				"texto": "Apontando suas primeiras lentes para tecidos vegetais e gotas de água, Robert Hooke descobriu pequenas câmaras que batizou de 'células'. Cada ser vivo na Terra — do menor slime ao sábio mago — é uma metrópole de células ativas.",
				"marco": "« A célula é o tijolo elementar e a oficina viva com que a natureza constrói a si mesma. » — Robert Hooke"
			},
			{
				"badge": "QUADRO II",
				"titulo": "O Livro da Vida — A Dupla Hélice",
				"icone_tipo": "dna",
				"cor": Color(0.78, 0.28, 0.65),
				"texto": "Em 1953, Rosalind Franklin, Watson e Crick desvendaram o enigma da hereditariedade: a molécula de DNA. Uma deslumbrante escada em espiral contendo quatro bases químicas (A, T, C, G) que guardam as instruções de toda a biodiversidade.",
				"marco": "« Quatro bases químicas escrevem no DNA a grandiosa biografia de toda a vida na Terra. »"
			},
			{
				"badge": "QUADRO III",
				"titulo": "A Teia da Vida",
				"icone_tipo": "sintese",
				"cor": Color(0.20, 0.65, 0.45),
				"texto": "Dos ecossistemas globais à complexidade celular, a Biologia revelou que toda vida compartilha a mesma ancestralidade. Diante dessa teia sagrada, o guardião [b][color=#144820]{JOGADOR}[/color][/b] consagrou seu triunfo e desvendou a criação!",
				"marco": "« Da menor célula ao nobre {JOGADOR}, toda vida pulsa entrelaçada na mesma sinfonia natural da Grande Síntese. »"
			}
		]
	}
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 120 # Acima de todas as telas
	if _container_conteudo == null:
		_construir_layout()

func iniciar_vinheta(andar_id: int) -> void:
	if _container_conteudo == null:
		_construir_layout()
	_andar_atual = clampi(andar_id, 1, 3)
	_quadro_atual_indice = 0
	_concluida = false
	_em_tela_vitoria = false
	
	# Salva que o jogador desbloqueou esta vinheta
	if is_inside_tree() and get_tree() and get_tree().root:
		var ps = get_tree().root.get_node_or_null("PlayerStats")
		if ps and ps.has_method("desbloquear_vinheta"):
			ps.desbloquear_vinheta(_andar_atual)
			
	var dados = capitulos.get(_andar_atual, capitulos[1])
	_lbl_capitulo.text = "✦  " + dados.get("capitulo", "CRÔNICAS") + "  ✦"
	_lbl_subtitulo.text = dados.get("subtitulo", "")
	
	_exibir_quadro(0)
	_animar_abertura_pergaminho()

func _obter_nick_jogador() -> String:
	var nick = ""
	if is_inside_tree() and get_tree() and get_tree().root:
		var db = get_tree().root.get_node_or_null("DatabaseManager")
		if db and "user_nick" in db and not str(db.user_nick).strip_edges().is_empty():
			nick = str(db.user_nick).strip_edges()
	if nick.is_empty():
		nick = "Você"
	return nick

func _obter_cla_jogador() -> String:
	var cla = ""
	if is_inside_tree() and get_tree() and get_tree().root:
		var db = get_tree().root.get_node_or_null("DatabaseManager")
		if db and "user_cla" in db and not str(db.user_cla).strip_edges().is_empty():
			cla = str(db.user_cla).strip_edges()
	return cla

func _obter_textura(caminho: String) -> Texture2D:
	if ResourceLoader.exists(caminho):
		var res = load(caminho)
		if res is Texture2D:
			return res
	var p_abs = ProjectSettings.globalize_path(caminho)
	if FileAccess.file_exists(p_abs):
		var img = Image.load_from_file(p_abs)
		if img:
			return ImageTexture.create_from_image(img)
	return null

func _construir_layout() -> void:
	var font_titulo = SystemFont.new()
	font_titulo.font_names = PackedStringArray(["Segoe UI", "Georgia", "Palatino Linotype", "Times New Roman", "serif"])
	font_titulo.font_weight = 700

	var font_corpo = SystemFont.new()
	font_corpo.font_names = PackedStringArray(["Segoe UI", "Georgia", "Palatino Linotype", "Times New Roman", "serif"])
	font_corpo.font_weight = 600
	
	# 1. Fundo elegante do laboratório do mago (mesa de pedra, lanterna a óleo, livros, crânio, fórmulas em giz)
	var tex_fundo = _obter_textura("res://assets/sprites/fundo_laboratorio_mago.png")
	if tex_fundo:
		var bg_tex = TextureRect.new()
		bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg_tex.texture = tex_fundo
		bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		add_child(bg_tex)
	else:
		var bg_escuro = ColorRect.new()
		bg_escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg_escuro.color = Color(0.05, 0.04, 0.07, 0.98)
		add_child(bg_escuro)
		
	# Partículas de fagulhas douradas arcanas no ambiente
	var particulas_bg = CPUParticles2D.new()
	particulas_bg.amount = 32
	particulas_bg.lifetime = 4.5
	particulas_bg.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particulas_bg.emission_rect_extents = Vector2(640, 360)
	particulas_bg.position = Vector2(640, 360)
	particulas_bg.gravity = Vector2(0, -14)
	particulas_bg.scale_amount_min = 1.5
	particulas_bg.scale_amount_max = 3.5
	particulas_bg.color = Color(1.0, 0.85, 0.45, 0.35)
	add_child(particulas_bg)
	
	# 2. Container central que abriga o Pergaminho de Mago
	_center_pergaminho = CenterContainer.new()
	_center_pergaminho.name = "CenterPergaminho"
	_center_pergaminho.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_center_pergaminho)
	
	# O Grande Pergaminho vertical desenrolado com papiro largo e hastes de madeira
	var tex_scroll = _obter_textura("res://assets/sprites/pergaminho_vertical_4x.png")
	if not tex_scroll:
		tex_scroll = _obter_textura("res://assets/sprites/pergaminho_vertical.png")
		
	_scroll_rect = NinePatchRect.new()
	_scroll_rect.name = "PergaminhoScroll"
	_scroll_rect.custom_minimum_size = Vector2(580, 650)
	_scroll_rect.texture = tex_scroll
	_scroll_rect.patch_margin_left = 44
	_scroll_rect.patch_margin_top = 48
	_scroll_rect.patch_margin_right = 44
	_scroll_rect.patch_margin_bottom = 48
	_scroll_rect.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
	_scroll_rect.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
	_scroll_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_scroll_rect.pivot_offset = Vector2(290, 325)
	_center_pergaminho.add_child(_scroll_rect)
	
	# Margens seguras: todo o texto fica 100% contido sobre o papiro claro, sem nunca vazar para fora
	_container_conteudo = MarginContainer.new()
	_container_conteudo.name = "ContainerConteudo"
	_container_conteudo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_container_conteudo.add_theme_constant_override("margin_left", 118)
	_container_conteudo.add_theme_constant_override("margin_right", 118)
	_container_conteudo.add_theme_constant_override("margin_top", 54)
	_container_conteudo.add_theme_constant_override("margin_bottom", 54)
	_scroll_rect.add_child(_container_conteudo)
	
	var vbox_corpo = VBoxContainer.new()
	vbox_corpo.add_theme_constant_override("separation", 5)
	vbox_corpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_corpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_container_conteudo.add_child(vbox_corpo)
	
	# Cabeçalho do capítulo em tinta nobre com relevo e profundidade
	_lbl_capitulo = Label.new()
	_lbl_capitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_capitulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_capitulo.add_theme_font_override("font", font_titulo)
	_lbl_capitulo.add_theme_font_size_override("font_size", 12)
	_lbl_capitulo.add_theme_color_override("font_color", Color(0.10, 0.04, 0.01))
	_lbl_capitulo.add_theme_color_override("font_outline_color", Color(0.14, 0.06, 0.02, 0.7))
	_lbl_capitulo.add_theme_constant_override("outline_size", 1)
	_lbl_capitulo.add_theme_color_override("font_shadow_color", Color(1.0, 0.94, 0.82, 0.90))
	_lbl_capitulo.add_theme_constant_override("shadow_offset_x", 0)
	_lbl_capitulo.add_theme_constant_override("shadow_offset_y", 1)
	vbox_corpo.add_child(_lbl_capitulo)
	
	# Subtítulo explicativo: tinta ferro-gálica escura, nítida, com relevo de escrita no papel
	_lbl_subtitulo = Label.new()
	_lbl_subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_subtitulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_subtitulo.add_theme_font_override("font", font_corpo)
	_lbl_subtitulo.add_theme_font_size_override("font_size", 11)
	_lbl_subtitulo.add_theme_color_override("font_color", Color(0.08, 0.03, 0.01))
	_lbl_subtitulo.add_theme_color_override("font_outline_color", Color(0.12, 0.05, 0.02, 0.80))
	_lbl_subtitulo.add_theme_constant_override("outline_size", 1)
	_lbl_subtitulo.add_theme_color_override("font_shadow_color", Color(1.0, 0.94, 0.82, 0.90))
	_lbl_subtitulo.add_theme_constant_override("shadow_offset_x", 0)
	_lbl_subtitulo.add_theme_constant_override("shadow_offset_y", 1)
	vbox_corpo.add_child(_lbl_subtitulo)
	
	# Filete decorativo com gema central em sépia suave
	var sep = HSeparator.new()
	var sb_sep = StyleBoxLine.new()
	sb_sep.color = Color(0.68, 0.48, 0.22, 0.50)
	sb_sep.thickness = 1
	sep.add_theme_stylebox_override("separator", sb_sep)
	vbox_corpo.add_child(sep)
	
	# Título do Registro Atual em tinta rubrica clássica entalhada
	_lbl_quadro_badge = Label.new()
	_lbl_quadro_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_quadro_badge.add_theme_font_override("font", font_titulo)
	_lbl_quadro_badge.add_theme_font_size_override("font_size", 11)
	_lbl_quadro_badge.add_theme_color_override("font_color", Color(0.58, 0.12, 0.10))
	_lbl_quadro_badge.add_theme_color_override("font_shadow_color", Color(1.0, 0.94, 0.82, 0.85))
	_lbl_quadro_badge.add_theme_constant_override("shadow_offset_x", 0)
	_lbl_quadro_badge.add_theme_constant_override("shadow_offset_y", 1)
	vbox_corpo.add_child(_lbl_quadro_badge)
	
	_lbl_quadro_titulo = Label.new()
	_lbl_quadro_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_quadro_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_quadro_titulo.add_theme_font_override("font", font_titulo)
	_lbl_quadro_titulo.add_theme_font_size_override("font_size", 14)
	_lbl_quadro_titulo.add_theme_color_override("font_color", Color(0.08, 0.03, 0.01))
	_lbl_quadro_titulo.add_theme_color_override("font_outline_color", Color(0.14, 0.06, 0.02, 0.70))
	_lbl_quadro_titulo.add_theme_constant_override("outline_size", 1)
	_lbl_quadro_titulo.add_theme_color_override("font_shadow_color", Color(1.0, 0.94, 0.82, 0.90))
	_lbl_quadro_titulo.add_theme_constant_override("shadow_offset_x", 0)
	_lbl_quadro_titulo.add_theme_constant_override("shadow_offset_y", 1)
	vbox_corpo.add_child(_lbl_quadro_titulo)
	
	# Área de desenho manuscrita do mago sobre o papiro (100% transparente)
	_canvas_arte = Control.new()
	_canvas_arte.name = "CanvasArteMago"
	_canvas_arte.custom_minimum_size = Vector2(0, 136)
	_canvas_arte.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_canvas_arte.draw.connect(_desenhar_arte_quadro.bind(_canvas_arte))
	vbox_corpo.add_child(_canvas_arte)
	
	# Texto da crônica histórica: tinta escura encorpada, efeito de texto escrito a pena no papel
	_lbl_quadro_texto = RichTextLabel.new()
	_lbl_quadro_texto.bbcode_enabled = true
	_lbl_quadro_texto.fit_content = true
	_lbl_quadro_texto.scroll_active = false
	_lbl_quadro_texto.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lbl_quadro_texto.add_theme_font_override("normal_font", font_corpo)
	_lbl_quadro_texto.add_theme_font_size_override("normal_font_size", 12)
	_lbl_quadro_texto.add_theme_color_override("default_color", Color(0.08, 0.03, 0.01))
	_lbl_quadro_texto.add_theme_color_override("font_outline_color", Color(0.12, 0.05, 0.02, 0.80))
	_lbl_quadro_texto.add_theme_constant_override("outline_size", 1)
	_lbl_quadro_texto.add_theme_color_override("font_shadow_color", Color(1.0, 0.94, 0.82, 0.90))
	_lbl_quadro_texto.add_theme_constant_override("shadow_offset_x", 0)
	_lbl_quadro_texto.add_theme_constant_override("shadow_offset_y", 1)
	_lbl_quadro_texto.add_theme_constant_override("line_separation", 3)
	vbox_corpo.add_child(_lbl_quadro_texto)
	
	# Citação manuscrita escrita diretamente sobre o papiro (SEM caixa branca, 100% imersiva)
	_painel_marco = MarginContainer.new()
	_painel_marco.name = "ContainerCitacao"
	_painel_marco.add_theme_constant_override("margin_left", 8)
	_painel_marco.add_theme_constant_override("margin_right", 8)
	_painel_marco.add_theme_constant_override("margin_top", 2)
	_painel_marco.add_theme_constant_override("margin_bottom", 2)
	
	var vbox_citacao = VBoxContainer.new()
	vbox_citacao.add_theme_constant_override("separation", 3)
	_painel_marco.add_child(vbox_citacao)
	
	var sep_cit_top = HSeparator.new()
	var sb_sep_c1 = StyleBoxLine.new()
	sb_sep_c1.color = Color(0.68, 0.48, 0.22, 0.40)
	sb_sep_c1.thickness = 1
	sep_cit_top.add_theme_stylebox_override("separator", sb_sep_c1)
	vbox_citacao.add_child(sep_cit_top)
	
	_lbl_marco = Label.new()
	_lbl_marco.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_marco.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_marco.add_theme_font_override("font", font_corpo)
	_lbl_marco.add_theme_font_size_override("font_size", 11)
	_lbl_marco.add_theme_color_override("font_color", Color(0.12, 0.05, 0.02))
	_lbl_marco.add_theme_color_override("font_outline_color", Color(0.16, 0.07, 0.03, 0.65))
	_lbl_marco.add_theme_constant_override("outline_size", 1)
	_lbl_marco.add_theme_color_override("font_shadow_color", Color(1.0, 0.94, 0.82, 0.90))
	_lbl_marco.add_theme_constant_override("shadow_offset_x", 0)
	_lbl_marco.add_theme_constant_override("shadow_offset_y", 1)
	vbox_citacao.add_child(_lbl_marco)
	
	var sep_cit_bot = HSeparator.new()
	var sb_sep_c2 = StyleBoxLine.new()
	sb_sep_c2.color = Color(0.68, 0.48, 0.22, 0.40)
	sb_sep_c2.thickness = 1
	sep_cit_bot.add_theme_stylebox_override("separator", sb_sep_c2)
	vbox_citacao.add_child(sep_cit_bot)
	
	vbox_corpo.add_child(_painel_marco)
	
	# Rodapé do pergaminho: contador acima, botão nobre abaixo, com folga garantida do rolo inferior
	var vbox_rodape = VBoxContainer.new()
	vbox_rodape.add_theme_constant_override("separation", 6)
	vbox_rodape.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_corpo.add_child(vbox_rodape)
	
	_lbl_contador = Label.new()
	_lbl_contador.text = "✦  Folha I de III  ✦  •  [ Espaço ] para Folhear"
	_lbl_contador.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_contador.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_contador.add_theme_font_override("font", font_titulo)
	_lbl_contador.add_theme_font_size_override("font_size", 11)
	_lbl_contador.add_theme_color_override("font_color", Color(0.24, 0.10, 0.04))
	_lbl_contador.add_theme_color_override("font_shadow_color", Color(1.0, 0.94, 0.82, 0.90))
	_lbl_contador.add_theme_constant_override("shadow_offset_x", 0)
	_lbl_contador.add_theme_constant_override("shadow_offset_y", 1)
	vbox_rodape.add_child(_lbl_contador)
	
	_btn_avancar = Button.new()
	_btn_avancar.text = "✦ Virar Página ✦ ▶ (Espaço)"
	_btn_avancar.custom_minimum_size = Vector2(280, 34)
	_btn_avancar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_btn_avancar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_btn_avancar.focus_mode = Control.FOCUS_ALL
	
	var sb_btn_norm = StyleBoxFlat.new()
	sb_btn_norm.bg_color = Color(0.48, 0.12, 0.10, 0.95) # Selo carmesim imperial
	sb_btn_norm.border_color = Color(0.78, 0.60, 0.22)   # Filete dourado medieval
	sb_btn_norm.set_border_width_all(2)
	sb_btn_norm.set_corner_radius_all(6)
	sb_btn_norm.content_margin_left = 18
	sb_btn_norm.content_margin_right = 18
	sb_btn_norm.content_margin_top = 6
	sb_btn_norm.content_margin_bottom = 6
	sb_btn_norm.shadow_color = Color(0.25, 0.08, 0.05, 0.35)
	sb_btn_norm.shadow_size = 4
	
	var sb_btn_hover = StyleBoxFlat.new()
	sb_btn_hover.bg_color = Color(0.62, 0.16, 0.14, 1.0)
	sb_btn_hover.border_color = Color(0.95, 0.82, 0.38)
	sb_btn_hover.set_border_width_all(2)
	sb_btn_hover.set_corner_radius_all(6)
	sb_btn_hover.content_margin_left = 18
	sb_btn_hover.content_margin_right = 18
	sb_btn_hover.content_margin_top = 6
	sb_btn_hover.content_margin_bottom = 6
	sb_btn_hover.shadow_color = Color(0.45, 0.12, 0.08, 0.5)
	sb_btn_hover.shadow_size = 6
	
	_btn_avancar.add_theme_stylebox_override("normal", sb_btn_norm)
	_btn_avancar.add_theme_stylebox_override("hover", sb_btn_hover)
	_btn_avancar.add_theme_stylebox_override("focus", sb_btn_hover)
	_btn_avancar.add_theme_font_override("font", font_titulo)
	_btn_avancar.add_theme_font_size_override("font_size", 11)
	_btn_avancar.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88))
	_btn_avancar.pressed.connect(_avancar_quadro)
	vbox_rodape.add_child(_btn_avancar)

func _animar_abertura_pergaminho() -> void:
	if not _scroll_rect or not _container_conteudo: return
	
	_animando_transicao = true
	# Começa enrolado no meio (apenas as hastes de madeira encostadas)
	_scroll_rect.pivot_offset = Vector2(290, 325)
	_scroll_rect.scale = Vector2(1.025, 0.16)
	_scroll_rect.self_modulate = Color(0.90, 0.86, 0.80)
	_container_conteudo.modulate.a = 0.0
	
	# Som de abrir o pergaminho
	var am = get_tree().root.get_node_or_null("AudioManager") if is_inside_tree() and get_tree() and get_tree().root else null
	if am and am.has_method("play_sfx"):
		am.play_sfx("transicao-1")
		
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	# O pergaminho se desenrola verticalmente de forma cinematográfica, majestosa e contemplativa
	tw.tween_property(_scroll_rect, "scale:y", 1.0, 1.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_scroll_rect, "scale:x", 1.0, 1.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_scroll_rect, "self_modulate", Color(1.0, 1.0, 1.0), 1.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# A tinta antiga e ilustrações do mago surgem suavemente sobre o papel
	tw.parallel().tween_property(_container_conteudo, "modulate:a", 1.0, 0.85).set_delay(0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		_animando_transicao = false
		if _btn_avancar and _btn_avancar.is_inside_tree():
			_btn_avancar.grab_focus()
	)

func _exibir_quadro(indice: int) -> void:
	var dados_andar = capitulos.get(_andar_atual, capitulos[1])
	var quadros = dados_andar.get("quadros", [])
	if indice < 0 or indice >= quadros.size():
		return
		
	var q = quadros[indice]
	var cor_tema: Color = q.get("cor", Color.GOLD)
	
	var num_romano = ["I", "II", "III"][clampi(indice, 0, 2)]
	_lbl_quadro_badge.text = "— REGISTRO %s —" % num_romano
	_lbl_quadro_titulo.text = q.get("titulo", "")
	var nick = _obter_nick_jogador()
	var texto_fmt = q.get("texto", "").replace("{JOGADOR}", nick)
	var marco_fmt = q.get("marco", "").replace("{JOGADOR}", nick)
	_lbl_quadro_texto.text = "[center][color=#0a0401]" + texto_fmt + "[/color][/center]"
	_lbl_marco.text = marco_fmt
	
	if indice == 2:
		_lbl_contador.text = "✦  Folha %s de III  ✦  •  [ Espaço ] para Concluir" % num_romano
		_btn_avancar.text = "✦ Concluir Crônicas & Triunfo ✦ ▶ (Espaço)"
		var sb_b = _btn_avancar.get_theme_stylebox("normal") as StyleBoxFlat
		if sb_b:
			sb_b.bg_color = Color(0.14, 0.40, 0.22, 0.95) # Selo esmeralda imperial
			sb_b.border_color = Color(0.50, 0.90, 0.60)
	else:
		_lbl_contador.text = "✦  Folha %s de III  ✦  •  [ Espaço ] para Folhear" % num_romano
		_btn_avancar.text = "✦ Virar Página ✦ ▶ (Espaço)"
		var sb_b = _btn_avancar.get_theme_stylebox("normal") as StyleBoxFlat
		if sb_b:
			sb_b.bg_color = Color(0.48, 0.12, 0.10, 0.95) # Selo carmesim nobre
			sb_b.border_color = Color(0.78, 0.60, 0.22)
			
	if _canvas_arte:
		_canvas_arte.set_meta("tipo", q.get("icone_tipo", "alquimia"))
		_canvas_arte.set_meta("cor", cor_tema)
		_canvas_arte.queue_redraw()

func _avancar_quadro() -> void:
	if _concluida or _em_tela_vitoria or _animando_transicao: return
	
	if _quadro_atual_indice < 2:
		_animando_transicao = true
		_quadro_atual_indice += 1
		var prox = _quadro_atual_indice
		var am = get_tree().root.get_node_or_null("AudioManager") if is_inside_tree() and get_tree() and get_tree().root else null
		if am and am.has_method("play_sfx"):
			am.play_sfx("transicao-1")
				
		# Animação cinematográfica do pergaminho se enrolando bem devagar com efeito físico e realismo
		var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		
		# 1. Enrola o pergaminho devagar em direção ao centro com sensação física de peso, espessura e sombra
		# O texto vai sumindo suavemente enquanto o pergaminho se contrai
		tw.tween_property(_container_conteudo, "modulate:a", 0.0, 0.88).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(_scroll_rect, "scale:y", 0.16, 1.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tw.parallel().tween_property(_scroll_rect, "scale:x", 1.038, 1.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.parallel().tween_property(_scroll_rect, "self_modulate", Color(0.90, 0.86, 0.80), 1.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		# 2. Efeito tátil de encontro dos rolos de madeira: pequeno rebote físico e som suave de toque
		tw.tween_callback(func():
			var am_click = get_tree().root.get_node_or_null("AudioManager") if is_inside_tree() and get_tree() and get_tree().root else null
			if am_click and am_click.has_method("play_sfx"):
				am_click.play_sfx("ui-1")
		)
		tw.tween_property(_scroll_rect, "scale:y", 0.185, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(_scroll_rect, "scale:y", 0.16, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.parallel().tween_property(_scroll_rect, "scale:x", 1.025, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		# 3. Intervalo contemplativo com o pergaminho fechado repousando na mesa do mago
		tw.tween_interval(0.28)
		
		# 4. No ponto em que o pergaminho está fechado, inscreve a nova página
		tw.tween_callback(func():
			_exibir_quadro(prox)
			var am2 = get_tree().root.get_node_or_null("AudioManager") if is_inside_tree() and get_tree() and get_tree().root else null
			if am2 and am2.has_method("play_sfx"):
				am2.play_sfx("transicao-1")
		)
		
		# 5. O pergaminho se desenrola majestosamente de forma suave, lenta e com física elástica realista
		tw.tween_property(_scroll_rect, "scale:y", 1.0, 1.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(_scroll_rect, "scale:x", 1.0, 1.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(_scroll_rect, "self_modulate", Color(1.0, 1.0, 1.0), 1.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		# A nova folha se revela com a tinta e gravuras surgindo serenamente sobre o papiro
		tw.parallel().tween_property(_container_conteudo, "modulate:a", 1.0, 0.80).set_delay(0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		tw.tween_callback(func():
			_animando_transicao = false
			if _btn_avancar and _btn_avancar.is_inside_tree():
				_btn_avancar.grab_focus()
		)
	else:
		_mostrar_tela_vitoria()

func _input(event: InputEvent) -> void:
	if _concluida: return
	
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)):
		get_viewport().set_input_as_handled()
		if _em_tela_vitoria:
			_encerrar_vinheta()
		else:
			_avancar_quadro()
	elif _em_tela_vitoria and (event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE)):
		get_viewport().set_input_as_handled()
		_encerrar_vinheta()

# Ilustrações antigas feitas à mão no pergaminho (Estilo Códice Renascentista / Alquimista de Mago)
func _desenhar_arte_quadro(canvas: Control) -> void:
	var rect = canvas.get_rect()
	var center = rect.size * 0.5
	var tipo = canvas.get_meta("tipo", "alquimia")
	
	# Paleta de tintas antigas autênticas
	var ink_dark = Color(0.24, 0.14, 0.06, 0.95)   # Tinta ferro-gálica de noz
	var ink_med = Color(0.48, 0.28, 0.14, 0.85)    # Tinta sépia bistre
	var ink_light = Color(0.62, 0.44, 0.24, 0.45)  # Traçado fino de construção
	var ink_rubric = Color(0.68, 0.20, 0.16, 0.90) # Rubrica de cinábrio
	var ink_gold = Color(0.74, 0.54, 0.18, 0.85)   # Iluminação dourada
	
	# Círculos concêntricos de coordenadas astronômicas / astrolábio
	canvas.draw_arc(center, 58.0, 0.0, TAU, 36, ink_light, 1.0, true)
	canvas.draw_arc(center, 50.0, 0.0, TAU, 36, ink_light, 1.0, true)
	
	# Marcações graduadas de bússola nos anéis
	for i in range(12):
		var ang_t = i * (TAU / 12.0)
		var p_in = center + Vector2(cos(ang_t), sin(ang_t)) * 54.0
		var p_out = center + Vector2(cos(ang_t), sin(ang_t)) * 58.0
		canvas.draw_line(p_in, p_out, ink_light, 1.0)

	match tipo:
		"alquimia":
			# Pés do tripé de ferro forjado
			canvas.draw_line(center + Vector2(-32, 44), center + Vector2(-20, 16), ink_dark, 2.0)
			canvas.draw_line(center + Vector2(32, 44), center + Vector2(20, 16), ink_dark, 2.0)
			canvas.draw_line(center + Vector2(0, 44), center + Vector2(0, 18), ink_dark, 2.0)
			
			# Bojo do caldeirão com hachuras de sombreamento
			canvas.draw_arc(center + Vector2(0, 10), 28.0, 0.0, PI, 24, ink_dark, 2.0)
			var rim_pts: PackedVector2Array = []
			for step in range(25):
				var t = step * (TAU / 24.0)
				rim_pts.append(center + Vector2(0, 10) + Vector2(cos(t) * 28.0, sin(t) * 7.0))
			canvas.draw_polyline(rim_pts, ink_dark, 1.5)
			# Alças
			canvas.draw_arc(center + Vector2(-28, 12), 6.0, PI * 0.5, PI * 1.5, 12, ink_dark, 2.0)
			canvas.draw_arc(center + Vector2(28, 12), 6.0, -PI * 0.5, PI * 0.5, 12, ink_dark, 2.0)
			
			# Tubo do alambique de destilação saindo do topo
			canvas.draw_arc(center + Vector2(10, -22), 22.0, -PI * 0.5, 0.0, 16, ink_dark, 2.0)
			canvas.draw_line(center + Vector2(32, -22), center + Vector2(48, 5), ink_dark, 2.0)
			# Frasco receptor de condensação
			canvas.draw_circle(center + Vector2(48, 15), 10.0, ink_light)
			canvas.draw_arc(center + Vector2(48, 15), 10.0, 0.0, TAU, 16, ink_dark, 1.5)
			
			# Fogo da fornalha sob o caldeirão
			for fx in [-14, -4, 6, 16]:
				canvas.draw_line(center + Vector2(fx, 40), center + Vector2(fx + 2, 24), ink_rubric, 2.0)
			
			# Símbolos Alquímicos manuscritos (Mercúrio ☿ à esq, Enxofre 🜍 à dir)
			# Mercúrio
			canvas.draw_circle(center + Vector2(-52, -22), 6.0, ink_med)
			canvas.draw_arc(center + Vector2(-52, -30), 6.0, 0.0, PI, 10, ink_med, 1.5)
			canvas.draw_line(center + Vector2(-52, -16), center + Vector2(-52, -4), ink_med, 1.5)
			canvas.draw_line(center + Vector2(-58, -10), center + Vector2(-46, -10), ink_med, 1.5)
			# Enxofre (triângulo sobre cruz)
			var p_t1 = center + Vector2(-52, 14)
			var p_t2 = center + Vector2(-59, 28)
			var p_t3 = center + Vector2(-45, 28)
			canvas.draw_polyline(PackedVector2Array([p_t1, p_t2, p_t3, p_t1]), ink_med, 1.5)
			canvas.draw_line(center + Vector2(-52, 28), center + Vector2(-52, 42), ink_med, 1.5)
			canvas.draw_line(center + Vector2(-58, 35), center + Vector2(-46, 35), ink_med, 1.5)

		"balanca":
			# Balança analítica de precisão de Lavoisier
			# Pilar central e fulcro
			canvas.draw_line(center + Vector2(0, -36), center + Vector2(0, 36), ink_dark, 3.0)
			canvas.draw_circle(center + Vector2(0, -22), 5.0, ink_gold)
			canvas.draw_line(center + Vector2(-52, -22), center + Vector2(52, -22), ink_dark, 2.5)
			
			# Correntes e pratos
			canvas.draw_line(center + Vector2(-52, -22), center + Vector2(-52, 12), ink_med, 1.0)
			canvas.draw_line(center + Vector2(52, -22), center + Vector2(52, 12), ink_med, 1.0)
			canvas.draw_arc(center + Vector2(-52, 12), 16.0, 0.0, PI, 16, ink_dark, 2.0)
			canvas.draw_arc(center + Vector2(52, 12), 16.0, 0.0, PI, 16, ink_dark, 2.0)
			
			# Matéria reagente pesada no prato esquerdo
			canvas.draw_circle(center + Vector2(-52, 10), 5.0, ink_rubric)
			# Pesos calibrados de latão no prato direito
			canvas.draw_rect(Rect2(center.x + 46, center.y + 4, 12, 8), ink_gold)
			
			# Cúpula de vidro hermética de Lavoisier
			canvas.draw_arc(center + Vector2(0, -5), 58.0, -PI, 0.0, 24, ink_light, 1.5, true)
			# Anotação manuscrita de massa: "m1 = m2"
			canvas.draw_line(center + Vector2(-15, -42), center + Vector2(15, -42), ink_light, 1.0)

		"atomo":
			# Modelo Atômico Quântico e Esfera Elemental
			# Núcleo atômico com prótons e nêutrons hachurados
			canvas.draw_circle(center, 9.0, ink_rubric)
			canvas.draw_circle(center + Vector2(-4, -4), 5.0, ink_gold)
			canvas.draw_circle(center + Vector2(4, 3), 4.5, ink_dark)
			
			# Três órbitas elípticas de elétrons
			var r_orb = 54.0
			for ang in [0.0, PI / 3.0, (2.0 * PI) / 3.0]:
				var pts: PackedVector2Array = []
				for step in range(33):
					var t = step * (TAU / 32.0)
					var x_loc = cos(t) * r_orb
					var y_loc = sin(t) * 16.0
					var rx = x_loc * cos(ang) - y_loc * sin(ang)
					var ry = x_loc * sin(ang) + y_loc * cos(ang)
					pts.append(center + Vector2(rx, ry))
				canvas.draw_polyline(pts, ink_med, 1.2, true)
				
				# Elétron na órbita
				var e_p = pts[8]
				canvas.draw_circle(e_p, 3.5, ink_dark)
				canvas.draw_circle(e_p, 1.5, ink_gold)

		"newton":
			# Prisma óptico e maçã gravitacional de Newton
			var p_topo = center + Vector2(-22, -28)
			var p_esq = center + Vector2(-50, 24)
			var p_dir = center + Vector2(6, 24)
			canvas.draw_polyline(PackedVector2Array([p_topo, p_esq, p_dir, p_topo]), ink_dark, 2.0)
			
			# Raio de luz branca incidente
			canvas.draw_line(center + Vector2(-68, -4), center + Vector2(-25, -4), ink_dark, 2.5)
			
			# Espectro decomposto em leque
			var dys = [-18.0, -10.0, -2.0, 6.0, 14.0, 22.0]
			for i in range(dys.size()):
				var cor_raio = ink_rubric if i < 2 else (ink_gold if i < 4 else ink_dark)
				canvas.draw_line(center + Vector2(-12, -4), center + Vector2(48, dys[i]), cor_raio, 1.5)
				
			# Maçã gravitacional de Newton com vetor de força
			var p_maca = center + Vector2(42, 22)
			canvas.draw_circle(p_maca, 9.0, ink_rubric)
			canvas.draw_line(p_maca, p_maca + Vector2(2, -8), ink_dark, 2.0)
			canvas.draw_line(p_maca, p_maca + Vector2(0, 16), ink_med, 1.5) # Vetor gravidade

		"raio":
			# Solenóide e indução eletromagnética de Faraday
			# Ímã em ferradura
			canvas.draw_arc(center + Vector2(0, -10), 42.0, -PI, 0.0, 20, ink_dark, 6.0)
			canvas.draw_line(center + Vector2(-42, -10), center + Vector2(-42, 25), ink_dark, 6.0)
			canvas.draw_line(center + Vector2(42, -10), center + Vector2(42, 25), ink_dark, 6.0)
			
			# Linhas de campo magnético curvas
			for sy in range(-12, 26, 8):
				canvas.draw_arc(center + Vector2(0, sy), 20.0, 0.0, PI, 12, ink_gold, 1.5)
				
			# Fagulha de arco elétrico
			var pts_f = PackedVector2Array([
				center + Vector2(-36, 25),
				center + Vector2(-18, 12),
				center + Vector2(-2, 22),
				center + Vector2(14, 10),
				center + Vector2(36, 25)
			])
			canvas.draw_polyline(pts_f, ink_rubric, 2.5)

		"otica":
			# Telescópio astronômico e mecânica celeste
			canvas.draw_line(center + Vector2(-54, -18), center + Vector2(42, 16), ink_dark, 5.0)
			canvas.draw_circle(center + Vector2(-58, -20), 8.0, ink_gold)
			
			# Tripé do telescópio
			canvas.draw_line(center + Vector2(-6, -2), center + Vector2(-24, 38), ink_med, 2.0)
			canvas.draw_line(center + Vector2(-6, -2), center + Vector2(12, 38), ink_med, 2.0)
			
			# Lua e astro celeste com raios de luz
			canvas.draw_arc(center + Vector2(48, -24), 16.0, 0.0, TAU, 16, ink_gold, 1.5)
			canvas.draw_arc(center + Vector2(48, -24), 12.0, -PI * 0.5, PI * 0.5, 12, ink_rubric, 2.0)

		"celula":
			# O microscópio de Hooke e a estrutura celular
			canvas.draw_circle(center, 44.0, ink_light)
			canvas.draw_arc(center, 44.0, 0.0, TAU, 28, ink_dark, 2.0)
			
			# Favo de células vegetais
			for hx in range(-28, 29, 14):
				canvas.draw_line(center + Vector2(hx, -36), center + Vector2(hx, 36), ink_med, 1.0)
			for hy in range(-28, 29, 14):
				canvas.draw_line(center + Vector2(-36, hy), center + Vector2(36, hy), ink_med, 1.0)
				
			# Núcleo celular e cloroplasto
			canvas.draw_circle(center + Vector2(-7, -7), 7.0, ink_rubric)
			canvas.draw_circle(center + Vector2(-7, -7), 3.0, ink_dark)
			canvas.draw_circle(center + Vector2(12, 10), 5.0, ink_gold)

		"dna":
			# A Dupla Hélice de DNA manuscrita
			var passos = 7
			for st in range(-passos, passos + 1):
				var y_pos = center.y + (st * 7.5)
				var t = st * 0.55
				var x_off = sin(t) * 28.0
				
				var p1 = Vector2(center.x - x_off, y_pos)
				var p2 = Vector2(center.x + x_off, y_pos)
				
				# Pontes de hidrogênio (A-T / C-G)
				canvas.draw_line(p1, p2, ink_gold, 1.5)
				canvas.draw_circle(Vector2(center.x, y_pos), 1.5, ink_dark)
				
				# Fitas de açúcar-fosfato
				canvas.draw_circle(p1, 3.5, ink_dark)
				canvas.draw_circle(p2, 3.5, ink_rubric)

		"sintese":
			# Triângulo das três ciências na Grande Síntese
			var p_q = center + Vector2(0, -35)
			var p_f = center + Vector2(-35, 26)
			var p_b = center + Vector2(35, 26)
			
			canvas.draw_polyline(PackedVector2Array([p_q, p_f, p_b, p_q]), ink_dark, 2.0)
			canvas.draw_circle(p_q, 7.0, ink_rubric) # Química
			canvas.draw_circle(p_f, 7.0, ink_gold)   # Física
			canvas.draw_circle(p_b, 7.0, ink_med)    # Biologia
			
			# Núcleo radiante da Síntese
			canvas.draw_circle(center, 9.0, ink_dark)
			canvas.draw_circle(center, 4.0, ink_gold)
			canvas.draw_arc(center, 48.0, 0.0, TAU, 28, ink_light, 1.0)

# Desenho do Medalhão Dourado Triunfal (Brasão Arcano do Guardião Derrotado)
func _desenhar_emblema_vitoria(canvas: Control) -> void:
	var rect = canvas.get_rect()
	var center = rect.size * 0.5
	var r = 36.0
	
	var cor_dourada = Color(0.96, 0.84, 0.36)
	var cor_dourada_escura = Color(0.58, 0.42, 0.14)
	var cor_brilho = Color(1.0, 0.96, 0.72)
	
	var cor_acento = Color(0.95, 0.70, 0.20)
	if _andar_atual == 2:
		cor_acento = Color(0.35, 0.85, 1.0)
	elif _andar_atual == 3:
		cor_acento = Color(0.40, 0.95, 0.60)
		
	var todos_feitos = canvas.get_meta("todos_feitos", false)
	if todos_feitos:
		cor_acento = Color(1.0, 0.88, 0.35)
		
	# 1. Aura de brilho radial externa
	for step in range(4):
		var rad_glow = r + 3.0 + (step * 3.0)
		var alpha = 0.24 - (step * 0.05)
		canvas.draw_arc(center, rad_glow, 0.0, TAU, 32, Color(cor_acento.r, cor_acento.g, cor_acento.b, alpha), 2.0)
		
	# 2. Raios solares ornamentais do medalhão (12 raios pontiagudos)
	for i in range(12):
		var ang = i * (TAU / 12.0)
		var dir = Vector2(cos(ang), sin(ang))
		var p_start = center + dir * (r + 1.0)
		var p_end = center + dir * (r + 7.0)
		canvas.draw_line(p_start, p_end, cor_dourada, 2.0)
		
	# 3. Fundo circular do medalhão (obsidiana com núcleo colorido radiante)
	canvas.draw_circle(center, r, Color(0.06, 0.07, 0.12, 0.98))
	canvas.draw_circle(center, r * 0.72, Color(cor_acento.r, cor_acento.g, cor_acento.b, 0.22))
	
	# 4. Bordas duplas de ouro nobre
	canvas.draw_arc(center, r, 0.0, TAU, 36, cor_dourada, 2.5)
	canvas.draw_arc(center, r - 3.5, 0.0, TAU, 36, cor_dourada_escura, 1.2)
	
	# 5. Ícone heráldico do Domínio Vencedor no centro do medalhão
	if todos_feitos:
		# Coroa da Grande Síntese
		var pts_crown = PackedVector2Array([
			center + Vector2(-15, 8),
			center + Vector2(-13, -9),
			center + Vector2(-5, -2),
			center + Vector2(0, -14),
			center + Vector2(5, -2),
			center + Vector2(13, -9),
			center + Vector2(15, 8),
			center + Vector2(-15, 8)
		])
		canvas.draw_colored_polygon(pts_crown, Color(cor_dourada.r, cor_dourada.g, cor_dourada.b, 0.35))
		canvas.draw_polyline(pts_crown, cor_brilho, 2.0)
		canvas.draw_circle(center + Vector2(0, -14), 2.5, cor_brilho)
		canvas.draw_circle(center + Vector2(-13, -9), 2.0, cor_brilho)
		canvas.draw_circle(center + Vector2(13, -9), 2.0, cor_brilho)
	elif _andar_atual == 1:
		# Alquimia: Caldeirão com pernas e anéis atômicos
		canvas.draw_arc(center + Vector2(0, 4), 13.0, 0.0, PI, 18, cor_dourada, 2.0)
		canvas.draw_line(center + Vector2(-14, 4), center + Vector2(14, 4), cor_dourada, 2.0)
		canvas.draw_line(center + Vector2(-9, 16), center + Vector2(-13, 21), cor_dourada, 2.0)
		canvas.draw_line(center + Vector2(9, 16), center + Vector2(13, 21), cor_dourada, 2.0)
		var elip: PackedVector2Array = []
		for st in range(21):
			var t = st * (TAU / 20.0)
			elip.append(center + Vector2(0, -7) + Vector2(cos(t) * 15.0, sin(t) * 6.0))
		canvas.draw_polyline(elip, cor_acento, 1.5)
		canvas.draw_circle(center + Vector2(0, -7), 3.0, cor_brilho)
	elif _andar_atual == 2:
		# Física: Prisma óptico e Raio de Faraday
		var pts_p = PackedVector2Array([
			center + Vector2(0, -17),
			center + Vector2(-14, 9),
			center + Vector2(14, 9),
			center + Vector2(0, -17)
		])
		canvas.draw_polyline(pts_p, cor_dourada, 2.0)
		var pts_bolt = PackedVector2Array([
			center + Vector2(2, -13),
			center + Vector2(-4, -1),
			center + Vector2(4, 2),
			center + Vector2(-2, 16)
		])
		canvas.draw_polyline(pts_bolt, cor_acento, 2.5)
		canvas.draw_circle(center + Vector2(0, 0), 2.0, cor_brilho)
	else:
		# Biologia: Espiral de DNA e Esferas Vivas
		for st in range(-4, 5):
			var y_pos = center.y + (st * 4.0)
			var x_off = sin(st * 0.7) * 11.0
			var p1 = Vector2(center.x - x_off, y_pos)
			var p2 = Vector2(center.x + x_off, y_pos)
			canvas.draw_line(p1, p2, cor_dourada_escura, 1.2)
			canvas.draw_circle(p1, 2.5, cor_acento)
			canvas.draw_circle(p2, 2.5, cor_dourada)
		canvas.draw_circle(center + Vector2(0, -17), 3.0, cor_brilho)

# Tela de triunfo do andar: placa heráldica nobre, sem poluição de texto, com santuário das 3 runas
func _mostrar_tela_vitoria() -> void:
	if _em_tela_vitoria or _concluida: return
	_em_tela_vitoria = true
	
	# Som de vitória triunfal (toca aqui com exclusividade ao concluir)
	var am_vit = get_tree().root.get_node_or_null("AudioManager") if is_inside_tree() and get_tree() and get_tree().root else null
	if am_vit and am_vit.has_method("play_sfx"):
		am_vit.play_sfx("win")
		
	# Oculta o Pergaminho de Mago enrolando-o devagar no centro com som e efeito físico
	if _scroll_rect and is_instance_valid(_scroll_rect):
		var am_roll = get_tree().root.get_node_or_null("AudioManager") if is_inside_tree() and get_tree() and get_tree().root else null
		if am_roll and am_roll.has_method("play_sfx"):
			am_roll.play_sfx("transicao-1")
			
		var tw_fade = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw_fade.tween_property(_container_conteudo, "modulate:a", 0.0, 0.88).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_fade.parallel().tween_property(_scroll_rect, "scale:y", 0.16, 1.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tw_fade.parallel().tween_property(_scroll_rect, "scale:x", 1.038, 1.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw_fade.parallel().tween_property(_scroll_rect, "self_modulate", Color(0.90, 0.86, 0.80), 1.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		# Toque sutil dos rolos e acomodação física
		tw_fade.tween_callback(func():
			var am_click = get_tree().root.get_node_or_null("AudioManager") if is_inside_tree() and get_tree() and get_tree().root else null
			if am_click and am_click.has_method("play_sfx"):
				am_click.play_sfx("ui-1")
		)
		tw_fade.tween_property(_scroll_rect, "scale:y", 0.185, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw_fade.tween_property(_scroll_rect, "scale:y", 0.16, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw_fade.parallel().tween_property(_scroll_rect, "scale:x", 1.025, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw_fade.tween_interval(0.20)
		tw_fade.tween_property(_scroll_rect, "modulate:a", 0.0, 0.35)
		tw_fade.tween_callback(func(): _scroll_rect.visible = false)
		
	# Verifica quais andares foram concluídos e quais ainda estão pendentes
	var concluidos: Array = []
	var ps_vit = get_tree().root.get_node_or_null("PlayerStats") if is_inside_tree() and get_tree() and get_tree().root else null
	if ps_vit and ps_vit.get("vinhetas_desbloqueadas") != null:
		for v in ps_vit.vinhetas_desbloqueadas:
			var id_int = int(v)
			if not concluidos.has(id_int):
				concluidos.append(id_int)
	if not concluidos.has(int(_andar_atual)):
		concluidos.append(int(_andar_atual))
		
	var pendentes: Array = []
	for id_andar in [1, 2, 3]:
		if not concluidos.has(id_andar):
			pendentes.append(id_andar)

	var nick = _obter_nick_jogador()
	var cla = _obter_cla_jogador()

	# Estilo e textos nobres diretos pelo andar recém-concluído (sem textão)
	var cor_tema = Color(1.0, 0.85, 0.3)
	var cor_borda = Color(1.0, 0.80, 0.28, 0.95)
	var badge_texto = "✦ PROVAÇÃO ALQUÍMICA CONCLUÍDA ✦"
	var titulo_texto = "VITÓRIA ALQUÍMICA!"
	var subtitulo_texto = "A Matéria foi Desvendada — A Alquimia tornou-se Ciência."
	var insignia_nome = "Insígnia do Mestre da Matéria"
	var conquista_curta = "Guardião da Alquimia superado e caldeirões purificados."
	
	if _andar_atual == 2:
		cor_tema = Color(0.35, 0.85, 1.0)
		cor_borda = Color(0.40, 0.90, 1.0, 0.95)
		badge_texto = "✦ PROVAÇÃO DAS FORÇAS CONCLUÍDA ✦"
		titulo_texto = "TRIUNFO DAS FORÇAS!"
		subtitulo_texto = "O Relâmpago foi Domado — O Movimento obedece à Razão."
		insignia_nome = "Insígnia do Senhor dos Relâmpagos"
		conquista_curta = "Guardião da Física derrotado e leis do cosmos dominadas."
	elif _andar_atual == 3:
		cor_tema = Color(0.45, 1.0, 0.65)
		cor_borda = Color(0.50, 1.0, 0.70, 0.95)
		badge_texto = "✦ PROVAÇÃO DA VIDA CONCLUÍDA ✦"
		titulo_texto = "SOBERANIA DA VIDA!"
		subtitulo_texto = "A Espiral Viva foi Decifrada — A Criação revelou seus Segredos."
		insignia_nome = "Insígnia do Guardião da Vida"
		conquista_curta = "Guardião da Vida vencido e códigos do DNA desvendados."

	var hub_titulo = "Portal do Saguão Central Aberto"
	var hub_curto = "Retorne ao Hub para escolher sua próxima expedição."
	
	if pendentes.is_empty():
		badge_texto = "👑 A GRANDE SÍNTESE ALCANÇADA POR %s 👑" % nick.to_upper()
		titulo_texto = "MESTRE SUPREMO DA SÍNTESE!"
		subtitulo_texto = "%s uniu Química, Física e Biologia na mais sublime sinfonia do saber!" % nick
		insignia_nome = "Insígnia do Arquimago Supremo"
		conquista_curta = "Os 3 domínios arcanos foram purificados com glória."
		hub_titulo = "A Masmorra Arcana foi Consagrada!"
		hub_curto = "%s dominou todas as ciências e alcançou a Grande Síntese!" % nick
	elif pendentes.size() == 1:
		hub_titulo = "Última Provação Aguarda no Hub"
		var p_nome = "Física" if pendentes[0] == 2 else ("Biologia" if pendentes[0] == 3 else "Química")
		hub_curto = "Apenas o Andar de %s resta para %s alcançar a Grande Síntese!" % [p_nome, nick]

	# Container de sobreposição da tela de vitória
	_container_vitoria = Control.new()
	_container_vitoria.name = "TelaVitoria"
	_container_vitoria.set_anchors_preset(Control.PRESET_FULL_RECT)
	_container_vitoria.modulate.a = 0.0
	add_child(_container_vitoria)
	
	# Fundo escurecido semi-transparente
	var bg_dim = ColorRect.new()
	bg_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_dim.color = Color(0.02, 0.03, 0.06, 0.88)
	_container_vitoria.add_child(bg_dim)
	
	# Partículas douradas / temáticas flutuantes
	var particulas = CPUParticles2D.new()
	particulas.amount = 45
	particulas.lifetime = 3.5
	particulas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particulas.emission_rect_extents = Vector2(640, 360)
	particulas.position = Vector2(640, 360)
	particulas.gravity = Vector2(0, -28)
	particulas.scale_amount_min = 2.0
	particulas.scale_amount_max = 4.5
	particulas.color = Color(cor_tema.r, cor_tema.g, cor_tema.b, 0.75)
	_container_vitoria.add_child(particulas)
	
	# CenterContainer que garante centralização perfeita
	var center_wrap = CenterContainer.new()
	center_wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	_container_vitoria.add_child(center_wrap)
	
	# Placa Real de Vitória (Estilo Placa Arcana de Jogo de Fantasia)
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(760, 520)
	card.pivot_offset = Vector2(380, 260)
	
	var sb_card = StyleBoxFlat.new()
	sb_card.bg_color = Color(0.05, 0.06, 0.10, 0.98)
	sb_card.border_color = cor_borda
	sb_card.set_border_width_all(2)
	sb_card.set_corner_radius_all(14)
	sb_card.shadow_color = Color(cor_tema.r, cor_tema.g, cor_tema.b, 0.30)
	sb_card.shadow_size = 32
	sb_card.content_margin_left = 28
	sb_card.content_margin_right = 28
	sb_card.content_margin_top = 16
	sb_card.content_margin_bottom = 18
	card.add_theme_stylebox_override("panel", sb_card)
	center_wrap.add_child(card)
	
	var vbox_card = VBoxContainer.new()
	vbox_card.add_theme_constant_override("separation", 10)
	vbox_card.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox_card)
	
	var font_serif_bold = SystemFont.new()
	font_serif_bold.font_names = PackedStringArray(["Cinzel", "Georgia", "Palatino Linotype", "Times New Roman", "serif"])
	font_serif_bold.font_weight = 700
	
	var font_sans_bold = SystemFont.new()
	font_sans_bold.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_sans_bold.font_weight = 700
	
	var font_sans_norm = SystemFont.new()
	font_sans_norm.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_sans_norm.font_weight = 400
	
	# Barra superior com Badge ornamental e Botão de Fechar
	var hbox_topo = HBoxContainer.new()
	hbox_topo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_card.add_child(hbox_topo)
	
	var lbl_decor_esq = Label.new()
	lbl_decor_esq.text = "✦  ✦  ✦"
	lbl_decor_esq.add_theme_font_override("font", font_sans_bold)
	lbl_decor_esq.add_theme_font_size_override("font_size", 11)
	lbl_decor_esq.add_theme_color_override("font_color", Color(cor_tema.r, cor_tema.g, cor_tema.b, 0.5))
	hbox_topo.add_child(lbl_decor_esq)
	
	var spacer_esq = Control.new()
	spacer_esq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_topo.add_child(spacer_esq)
	
	var badge_panel = PanelContainer.new()
	var sb_badge = StyleBoxFlat.new()
	sb_badge.bg_color = Color(cor_tema.r, cor_tema.g, cor_tema.b, 0.14)
	sb_badge.border_color = cor_tema
	sb_badge.set_border_width_all(1)
	sb_badge.set_corner_radius_all(12)
	sb_badge.content_margin_left = 18
	sb_badge.content_margin_right = 18
	sb_badge.content_margin_top = 4
	sb_badge.content_margin_bottom = 4
	badge_panel.add_theme_stylebox_override("panel", sb_badge)
	
	var lbl_badge = Label.new()
	lbl_badge.text = badge_texto
	lbl_badge.add_theme_font_override("font", font_serif_bold)
	lbl_badge.add_theme_font_size_override("font_size", 12)
	lbl_badge.add_theme_color_override("font_color", cor_tema)
	badge_panel.add_child(lbl_badge)
	hbox_topo.add_child(badge_panel)
	
	var spacer_dir = Control.new()
	spacer_dir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_topo.add_child(spacer_dir)
	
	# Botão discreto e elegante de fechar no canto superior direito
	_btn_fechar_topo = Button.new()
	_btn_fechar_topo.text = "✕ Fechar"
	_btn_fechar_topo.custom_minimum_size = Vector2(82, 28)
	_btn_fechar_topo.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_btn_fechar_topo.focus_mode = Control.FOCUS_ALL
	
	var sb_close_norm = StyleBoxFlat.new()
	sb_close_norm.bg_color = Color(0.48, 0.12, 0.14, 0.90)
	sb_close_norm.border_color = Color(0.78, 0.28, 0.32)
	sb_close_norm.set_border_width_all(1)
	sb_close_norm.set_corner_radius_all(6)
	sb_close_norm.content_margin_left = 8
	sb_close_norm.content_margin_right = 8
	sb_close_norm.content_margin_top = 3
	sb_close_norm.content_margin_bottom = 3
	
	var sb_close_hover = StyleBoxFlat.new()
	sb_close_hover.bg_color = Color(0.70, 0.16, 0.20, 1.0)
	sb_close_hover.border_color = Color(1.0, 0.5, 0.55)
	sb_close_hover.set_border_width_all(1)
	sb_close_hover.set_corner_radius_all(6)
	sb_close_hover.content_margin_left = 8
	sb_close_hover.content_margin_right = 8
	sb_close_hover.content_margin_top = 3
	sb_close_hover.content_margin_bottom = 3
	
	_btn_fechar_topo.add_theme_stylebox_override("normal", sb_close_norm)
	_btn_fechar_topo.add_theme_stylebox_override("hover", sb_close_hover)
	_btn_fechar_topo.add_theme_stylebox_override("focus", sb_close_hover)
	_btn_fechar_topo.add_theme_font_override("font", font_sans_bold)
	_btn_fechar_topo.add_theme_font_size_override("font_size", 11)
	_btn_fechar_topo.add_theme_color_override("font_color", Color(1.0, 0.92, 0.92))
	_btn_fechar_topo.pressed.connect(_encerrar_vinheta)
	hbox_topo.add_child(_btn_fechar_topo)
	
	# Medalhão Dourado de Conquista Central
	var center_med = CenterContainer.new()
	center_med.custom_minimum_size = Vector2(0, 80)
	var canvas_med = Control.new()
	canvas_med.custom_minimum_size = Vector2(84, 80)
	canvas_med.set_meta("todos_feitos", pendentes.is_empty())
	canvas_med.draw.connect(_desenhar_emblema_vitoria.bind(canvas_med))
	center_med.add_child(canvas_med)
	vbox_card.add_child(center_med)
	
	# Título e Subtítulo Triunfais em Tipografia Épica
	var vbox_titulos = VBoxContainer.new()
	vbox_titulos.add_theme_constant_override("separation", 2)
	vbox_card.add_child(vbox_titulos)
	
	var lbl_titulo = Label.new()
	lbl_titulo.text = titulo_texto
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_titulo.add_theme_font_override("font", font_serif_bold)
	lbl_titulo.add_theme_font_size_override("font_size", 22)
	lbl_titulo.add_theme_color_override("font_color", Color(1.0, 0.94, 0.72))
	lbl_titulo.add_theme_color_override("font_shadow_color", Color(cor_tema.r, cor_tema.g, cor_tema.b, 0.50))
	lbl_titulo.add_theme_constant_override("shadow_offset_x", 0)
	lbl_titulo.add_theme_constant_override("shadow_offset_y", 2)
	vbox_titulos.add_child(lbl_titulo)
	
	var lbl_sub = Label.new()
	lbl_sub.text = subtitulo_texto
	lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_sub.add_theme_font_override("font", font_sans_norm)
	lbl_sub.add_theme_font_size_override("font_size", 12)
	lbl_sub.add_theme_color_override("font_color", Color(0.85, 0.88, 0.94))
	vbox_titulos.add_child(lbl_sub)
	
	# Linha divisória ornamental
	var sep_card = HSeparator.new()
	var sb_sep = StyleBoxLine.new()
	sb_sep.color = Color(cor_tema.r, cor_tema.g, cor_tema.b, 0.35)
	sb_sep.thickness = 1
	sep_card.add_theme_stylebox_override("separator", sb_sep)
	vbox_card.add_child(sep_card)
	
	# O Santuário da Grande Síntese: 3 Selos Rúnicos com status visual instantâneo
	var vbox_santuario = VBoxContainer.new()
	vbox_santuario.add_theme_constant_override("separation", 6)
	vbox_card.add_child(vbox_santuario)
	
	var lbl_sant_tit = Label.new()
	lbl_sant_tit.text = "✦ OS TRÊS PILARES DA GRANDE SÍNTESE ✦"
	lbl_sant_tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_sant_tit.add_theme_font_override("font", font_serif_bold)
	lbl_sant_tit.add_theme_font_size_override("font_size", 10)
	lbl_sant_tit.add_theme_color_override("font_color", Color(0.86, 0.76, 0.42))
	vbox_santuario.add_child(lbl_sant_tit)
	
	var hbox_runas = HBoxContainer.new()
	hbox_runas.add_theme_constant_override("separation", 10)
	hbox_runas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_santuario.add_child(hbox_runas)
	
	# Definição dos 3 domínios para os slots
	var dados_runas = [
		{"id": 1, "nome": "QUÍMICA", "icone": "🧪", "sub": "Matéria", "cor": Color(0.95, 0.72, 0.22)},
		{"id": 2, "nome": "FÍSICA", "icone": "⚡", "sub": "Energia", "cor": Color(0.35, 0.85, 1.0)},
		{"id": 3, "nome": "BIOLOGIA", "icone": "🧬", "sub": "Vida", "cor": Color(0.40, 0.95, 0.60)}
	]
	
	for dr in dados_runas:
		var feito = concluidos.has(dr.id)
		var p_runa = PanelContainer.new()
		p_runa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p_runa.custom_minimum_size = Vector2(0, 56)
		
		var sb_r = StyleBoxFlat.new()
		sb_r.set_corner_radius_all(8)
		if feito:
			sb_r.bg_color = Color(0.08, 0.12, 0.16, 0.95)
			sb_r.border_color = dr.cor
			sb_r.set_border_width_all(2)
			sb_r.shadow_color = Color(dr.cor.r, dr.cor.g, dr.cor.b, 0.35)
			sb_r.shadow_size = 10
		else:
			sb_r.bg_color = Color(0.04, 0.05, 0.07, 0.80)
			sb_r.border_color = Color(0.25, 0.28, 0.36, 0.45)
			sb_r.set_border_width_all(1)
		sb_r.content_margin_left = 12
		sb_r.content_margin_right = 12
		sb_r.content_margin_top = 8
		sb_r.content_margin_bottom = 8
		p_runa.add_theme_stylebox_override("panel", sb_r)
		
		var vbox_r = VBoxContainer.new()
		vbox_r.add_theme_constant_override("separation", 2)
		vbox_r.alignment = BoxContainer.ALIGNMENT_CENTER
		p_runa.add_child(vbox_r)
		
		var lbl_r_top = Label.new()
		lbl_r_top.text = "%s %s • %s" % [dr.icone, dr.nome, dr.sub]
		lbl_r_top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_r_top.add_theme_font_override("font", font_serif_bold)
		lbl_r_top.add_theme_font_size_override("font_size", 11)
		lbl_r_top.add_theme_color_override("font_color", dr.cor if feito else Color(0.52, 0.55, 0.62))
		vbox_r.add_child(lbl_r_top)
		
		var lbl_r_bot = Label.new()
		lbl_r_bot.text = "✦ SELO DESPERTADO ✦" if feito else "🔒 Selo Adormecido"
		lbl_r_bot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_r_bot.add_theme_font_override("font", font_sans_bold if feito else font_sans_norm)
		lbl_r_bot.add_theme_font_size_override("font_size", 10)
		lbl_r_bot.add_theme_color_override("font_color", Color(0.50, 0.95, 0.60) if feito else Color(0.40, 0.42, 0.48))
		vbox_r.add_child(lbl_r_bot)
		
		hbox_runas.add_child(p_runa)
		
	# Dois cartões de recompensa compactos e diretos (sem parágrafos longos)
	var hbox_cards = HBoxContainer.new()
	hbox_cards.add_theme_constant_override("separation", 12)
	hbox_cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_card.add_child(hbox_cards)
	
	# Card Esquerdo: Insígnia do Guardião Superado
	var card_esq = PanelContainer.new()
	card_esq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_esq.custom_minimum_size = Vector2(0, 68)
	var sb_ce = StyleBoxFlat.new()
	sb_ce.bg_color = Color(0.04, 0.06, 0.10, 0.90)
	sb_ce.border_color = Color(cor_tema.r, cor_tema.g, cor_tema.b, 0.35)
	sb_ce.set_border_width_all(1)
	sb_ce.set_corner_radius_all(8)
	sb_ce.content_margin_left = 14
	sb_ce.content_margin_right = 14
	sb_ce.content_margin_top = 8
	sb_ce.content_margin_bottom = 8
	card_esq.add_theme_stylebox_override("panel", sb_ce)
	
	var vbox_ce = VBoxContainer.new()
	vbox_ce.add_theme_constant_override("separation", 2)
	card_esq.add_child(vbox_ce)
	
	var lbl_ce_tag = Label.new()
	if nick.to_lower() == "você" or nick.to_lower() == "voce":
		lbl_ce_tag.text = "🏆  INSÍGNIA CONQUISTADA POR VOCÊ"
	else:
		lbl_ce_tag.text = "🏆  INSÍGNIA CONQUISTADA PELO MAGO %s" % nick.to_upper()
	lbl_ce_tag.add_theme_font_override("font", font_sans_bold)
	lbl_ce_tag.add_theme_font_size_override("font_size", 10)
	lbl_ce_tag.add_theme_color_override("font_color", cor_tema)
	vbox_ce.add_child(lbl_ce_tag)
	
	var lbl_ce_tit = Label.new()
	lbl_ce_tit.text = insignia_nome
	lbl_ce_tit.add_theme_font_override("font", font_serif_bold)
	lbl_ce_tit.add_theme_font_size_override("font_size", 12)
	lbl_ce_tit.add_theme_color_override("font_color", Color.WHITE)
	vbox_ce.add_child(lbl_ce_tit)
	
	var lbl_ce_sub = Label.new()
	if not cla.is_empty() and cla != "Sem Clã":
		lbl_ce_sub.text = "%s • Honra do Clã %s." % [conquista_curta, cla]
	else:
		lbl_ce_sub.text = "%s" % conquista_curta
	lbl_ce_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_ce_sub.add_theme_font_override("font", font_sans_norm)
	lbl_ce_sub.add_theme_font_size_override("font_size", 11)
	lbl_ce_sub.add_theme_color_override("font_color", Color(0.78, 0.82, 0.90))
	vbox_ce.add_child(lbl_ce_sub)
	hbox_cards.add_child(card_esq)
	
	# Card Direito: Próxima Expedição / Status do Hub
	var card_dir = PanelContainer.new()
	card_dir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_dir.custom_minimum_size = Vector2(0, 68)
	var sb_cd = StyleBoxFlat.new()
	sb_cd.bg_color = Color(0.04, 0.06, 0.10, 0.90)
	sb_cd.border_color = Color(0.35, 0.55, 0.85, 0.35)
	sb_cd.set_border_width_all(1)
	sb_cd.set_corner_radius_all(8)
	sb_cd.content_margin_left = 14
	sb_cd.content_margin_right = 14
	sb_cd.content_margin_top = 8
	sb_cd.content_margin_bottom = 8
	card_dir.add_theme_stylebox_override("panel", sb_cd)
	
	var vbox_cd = VBoxContainer.new()
	vbox_cd.add_theme_constant_override("separation", 2)
	card_dir.add_child(vbox_cd)
	
	var lbl_cd_tag = Label.new()
	lbl_cd_tag.text = "🧭  DESTINO ARCANO"
	lbl_cd_tag.add_theme_font_override("font", font_sans_bold)
	lbl_cd_tag.add_theme_font_size_override("font_size", 10)
	lbl_cd_tag.add_theme_color_override("font_color", Color(0.45, 0.85, 1.0))
	vbox_cd.add_child(lbl_cd_tag)
	
	var lbl_cd_tit = Label.new()
	lbl_cd_tit.text = hub_titulo
	lbl_cd_tit.add_theme_font_override("font", font_serif_bold)
	lbl_cd_tit.add_theme_font_size_override("font_size", 12)
	lbl_cd_tit.add_theme_color_override("font_color", Color.WHITE)
	vbox_cd.add_child(lbl_cd_tit)
	
	var lbl_cd_sub = Label.new()
	lbl_cd_sub.text = hub_curto
	lbl_cd_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_cd_sub.add_theme_font_override("font", font_sans_norm)
	lbl_cd_sub.add_theme_font_size_override("font_size", 11)
	lbl_cd_sub.add_theme_color_override("font_color", Color(0.78, 0.82, 0.90))
	vbox_cd.add_child(lbl_cd_sub)
	hbox_cards.add_child(card_dir)
	
	# Rodapé centralizado com o botão principal de retorno ao Hub
	var hbox_foot = HBoxContainer.new()
	hbox_foot.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_foot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_card.add_child(hbox_foot)
	
	_btn_ir_hub = Button.new()
	_btn_ir_hub.text = "✦ RETORNAR AO SAGUÃO CENTRAL ✦ ▶ (Espaço / Enter)"
	_btn_ir_hub.custom_minimum_size = Vector2(430, 42)
	_btn_ir_hub.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_btn_ir_hub.focus_mode = Control.FOCUS_ALL
	
	var sb_b_norm = StyleBoxFlat.new()
	sb_b_norm.bg_color = Color(0.12, 0.36, 0.22, 0.95)
	sb_b_norm.border_color = Color(0.45, 0.90, 0.65)
	sb_b_norm.set_border_width_all(2)
	sb_b_norm.set_corner_radius_all(8)
	sb_b_norm.content_margin_left = 18
	sb_b_norm.content_margin_right = 18
	sb_b_norm.shadow_color = Color(0.20, 0.70, 0.40, 0.35)
	sb_b_norm.shadow_size = 12
	
	var sb_b_hov = StyleBoxFlat.new()
	sb_b_hov.bg_color = Color(0.18, 0.48, 0.30, 1.0)
	sb_b_hov.border_color = Color(0.70, 1.0, 0.85)
	sb_b_hov.set_border_width_all(2)
	sb_b_hov.set_corner_radius_all(8)
	sb_b_hov.shadow_color = Color(0.35, 1.0, 0.60, 0.50)
	sb_b_hov.shadow_size = 18
	
	_btn_ir_hub.add_theme_stylebox_override("normal", sb_b_norm)
	_btn_ir_hub.add_theme_stylebox_override("hover", sb_b_hov)
	_btn_ir_hub.add_theme_stylebox_override("focus", sb_b_hov)
	_btn_ir_hub.add_theme_font_override("font", font_serif_bold)
	_btn_ir_hub.add_theme_font_size_override("font_size", 13)
	_btn_ir_hub.add_theme_color_override("font_color", Color.WHITE)
	_btn_ir_hub.pressed.connect(_encerrar_vinheta)
	hbox_foot.add_child(_btn_ir_hub)
	
	card.scale = Vector2(0.88, 0.88)
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	# Aguarda o pergaminho enrolar completamente de forma solene e contemplativa
	tw.tween_interval(1.65)
	tw.tween_property(_container_vitoria, "modulate:a", 1.0, 0.35)
	tw.parallel().tween_property(card, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		if _btn_ir_hub and _btn_ir_hub.is_inside_tree():
			_btn_ir_hub.grab_focus()
	)

func _encerrar_vinheta() -> void:
	if _concluida: return
	_concluida = true
	_em_tela_vitoria = false
	
	if get_tree():
		get_tree().paused = false
	vinheta_concluida.emit()
	
	var dg = get_tree().root.get_node_or_null("DungeonGenerator") if is_inside_tree() and get_tree() and get_tree().root else null
	if dg and dg.has_method("resetar_masmorra"):
		dg.resetar_masmorra()
	var qm = get_tree().root.get_node_or_null("QuizManager") if is_inside_tree() and get_tree() and get_tree().root else null
	if qm and qm.has_method("resetar_historico_perguntas"):
		qm.resetar_historico_perguntas()
		
	# Volta para o Hub
	var ts = get_tree().root.get_node_or_null("TransitionScreen") if is_inside_tree() and get_tree() and get_tree().root else null
	if ts and ts.has_method("change_scene"):
		ts.change_scene("res://scenes/Salas/Comum/Hub_Geral.tscn")
	elif get_tree():
		get_tree().change_scene_to_file("res://scenes/Salas/Comum/Hub_Geral.tscn")
		
	queue_free()

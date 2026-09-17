extends CanvasLayer

signal furia_concluida(sucesso: bool)

# minigame de furia do boss

const TEMPO_POR_AFIRMACAO: float = 6.0
const META_COMBO: int = 3

enum Fase { LORE, CONTAGEM, QUIZ, RESULTADO }
var _fase_atual: Fase = Fase.LORE

var _andar_atual: int = 1
var _nome_chefe: String = "Chefe Supremo"
var _combo_atual: int = 0
var _perguntas_ativas: Array = []
var _indice_pergunta: int = 0
var _tempo_restante: float = 6.0
var _em_andamento: bool = false
var _respondendo: bool = false
var _resultado_sucesso: bool = false
var _ja_emitiu: bool = false

# referencias dos nos
var _banner_alerta: PanelContainer
var _lbl_titulo_alerta: Label
var _lbl_subtitulo_alerta: Label

# painel de instrucoes antes do golpe
var _painel_lore: PanelContainer
var _lbl_lore_titulo: Label
var _lbl_lore_texto: Label
var _btn_iniciar_defesa: Button

# painel de perguntas rapidas V ou F
var _painel_quiz: VBoxContainer
var _hbox_orbes: HBoxContainer
var _orbes: Array[PanelContainer] = []
var _painel_card_pergunta: PanelContainer
var _lbl_afirmacao: Label
var _barra_tempo: ProgressBar
var _lbl_tempo: Label
var _btn_verdadeiro: Button
var _btn_falso: Button
var _lbl_dica_continuar: Label

# textos de lore por andar
var lores_chefe = {
	1: {
		"golpe": "🔥 REAÇÃO EM CADEIA EXOTÉRMICA!",
		"lore": "O monstro superaqueceu o ambiente e está prestes a detonar uma onda ácida!"
	},
	2: {
		"golpe": "⚡ SOBRECARGA ELETROMAGNÉTICA!",
		"lore": "O autômato canalizou milhões de Volts e vai disparar uma descarga mortal!"
	},
	3: {
		"golpe": "☣️ ONDA DE ESPOROS CÁUSTICOS!",
		"lore": "A entidade liberou toxinas cáusticas que corroem a barreira arcana do mago!"
	}
}

# perguntas rapidas por andar
var banco_afirmacoes = {
	1: [ # Química (Andar 1)
		{"texto": "A água (H₂O) é formada por 2 átomos de hidrogênio e 1 de oxigênio.", "correta": true},
		{"texto": "A combustão de carvão é uma reação endotérmica que absorve calor do ambiente.", "correta": false},
		{"texto": "Na Tabela Periódica, os elementos do Grupo 18 são chamados de Gases Nobres.", "correta": true},
		{"texto": "O cloreto de sódio (NaCl) é formado por uma ligação puramente metálica.", "correta": false},
		{"texto": "Transformações físicas não alteram a estrutura molecular das substâncias.", "correta": true},
		{"texto": "Grafite e diamante são formados por elementos químicos completamente distintos.", "correta": false},
		{"texto": "Segundo Lavoisier, em um sistema fechado a massa total dos reagentes se conserva.", "correta": true},
		{"texto": "O símbolo químico do elemento Ferro na tabela periódica é apenas a letra 'F'.", "correta": false},
		{"texto": "Soluções com pH menor que 7 em água pura a 25°C são classificadas como ácidas.", "correta": true},
		{"texto": "A evaporação da água fervente destrói permanentemente suas moléculas de hidrogênio.", "correta": false},
		{"texto": "Metais alcalinos do Grupo 1 reagem vigorosamente ao entrar em contato com água.", "correta": true},
		{"texto": "Uma mistura de água purificada e óleo de cozinha forma uma solução monofásica homogênea.", "correta": false},
		{"texto": "A sublimação é a transição direta do estado sólido para o gasoso sem passar pelo líquido.", "correta": true},
		{"texto": "Um catalisador acelera a reação química sendo totalmente consumido no processo.", "correta": false},
		{"texto": "A neutralização entre ácido clorídrico (HCl) e hidróxido de sódio (NaOH) produz sal e água.", "correta": true},
		{"texto": "O gás oxigênio essencial que respiramos na atmosfera possui fórmula molecular O₃.", "correta": false},
		{"texto": "Na ligação covalente, átomos ametais compartilham pares de elétrons para atingir estabilidade.", "correta": true},
		{"texto": "A densidade de um corpo é calculada dividindo-se o seu volume pela sua massa (d = V / m).", "correta": false},
		{"texto": "O símbolo químico do elemento Ouro na tabela periódica é 'Au', derivado de 'Aurum'.", "correta": true},
		{"texto": "O ponto de fusão do gelo puro sob pressão normal de 1 atm ocorre a 100°C.", "correta": false}
	],
	2: [ # Física (Andar 2)
		{"texto": "Pela 1ª Lei de Newton, um corpo em repouso tende naturalmente a permanecer em repouso.", "correta": true},
		{"texto": "No Movimento Retilíneo Uniforme (MRU), a aceleração do corpo é sempre diferente de zero.", "correta": false},
		{"texto": "A aceleração da gravidade média na Terra é de aproximadamente 9,8 m/s².", "correta": true},
		{"texto": "A massa de um guerreiro em kg muda drasticamente se ele for transportado para a Lua.", "correta": false},
		{"texto": "Para toda ação existe uma reação de mesmo módulo, mesma direção e sentido oposto.", "correta": true},
		{"texto": "A energia mecânica total de um objeto é calculada somando sua temperatura à pressão.", "correta": false},
		{"texto": "A velocidade média é dada pela divisão da distância percorrida pelo tempo gasto.", "correta": true},
		{"texto": "No vácuo absoluto, uma bigorna pesada cai mais rápido do que uma pluma leve.", "correta": false},
		{"texto": "A unidade oficial de Força no Sistema Internacional (SI) é o Newton (N).", "correta": true},
		{"texto": "A luz visível viaja com velocidade maior através do vidro do que no vácuo espacial.", "correta": false},
		{"texto": "Cargas elétricas de mesmo sinal (positiva e positiva) repelem-se mutuamente.", "correta": true},
		{"texto": "A energia cinética de um projétil independe totalmente da sua velocidade de deslocamento.", "correta": false}
	],
	3: [ # Biologia (Andar 3)
		{"texto": "A mitose gera duas células-filhas geneticamente idênticas à célula-mãe original.", "correta": true},
		{"texto": "Os vírus possuem membrana plasmática, mitocôndrias e ribossomos próprios.", "correta": false},
		{"texto": "As mitocôndrias realizam a respiração celular para gerar energia na forma de ATP.", "correta": true},
		{"texto": "Fungos realizam fotossíntese para produzir glicose exatamente como as plantas verdes.", "correta": false},
		{"texto": "O DNA possui conformação em dupla-hélice e é o guardião das instruções genéticas.", "correta": true},
		{"texto": "Os ribossomos têm como principal função biológica bombear sangue e linfa.", "correta": false},
		{"texto": "Os cloroplastos contêm clorofila, pigmento vital para a absorção da luz solar.", "correta": true},
		{"texto": "Bactérias são seres pluricelulares complexos que possuem núcleo delimitado por carioteca.", "correta": false},
		{"texto": "A cissiparidade (divisão binária) é uma forma comum de reprodução assexuada.", "correta": true},
		{"texto": "A respiração aeróbica consome gás carbônico para produzir oxigênio livre.", "correta": false},
		{"texto": "Enzimas atuam como catalisadores orgânicos que aceleram as reações químicas.", "correta": true},
		{"texto": "A meiose resulta na formação de quatro células com o dobro do número de cromossomos.", "correta": false}
	]
}

var _root_container: Control = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 110 # Camada superior
	_construir_interface()

func _construir_interface() -> void:
	_root_container = Control.new()
	_root_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root_container)
	
	# fundo escuro avermelhado
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.01, 0.02, 0.90)
	_root_container.add_child(bg)
	
	var font_sans = SystemFont.new()
	font_sans.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_sans.font_weight = 600

	var font_titulo = SystemFont.new()
	font_titulo.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_titulo.font_weight = 700
	
	# container central
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root_container.add_child(center)
	
	var vbox_root = VBoxContainer.new()
	vbox_root.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_root.add_theme_constant_override("separation", 14)
	center.add_child(vbox_root)
	
	# banner de alerta no topo
	_banner_alerta = PanelContainer.new()
	var sb_banner = StyleBoxFlat.new()
	sb_banner.bg_color = Color(0.38, 0.06, 0.08, 0.96)
	sb_banner.border_color = Color(1.0, 0.25, 0.25, 1.0)
	sb_banner.set_border_width_all(2)
	sb_banner.set_corner_radius_all(8)
	sb_banner.content_margin_left = 28
	sb_banner.content_margin_right = 28
	sb_banner.content_margin_top = 10
	sb_banner.content_margin_bottom = 10
	sb_banner.shadow_color = Color(1.0, 0.1, 0.1, 0.5)
	sb_banner.shadow_size = 20
	_banner_alerta.add_theme_stylebox_override("panel", sb_banner)
	vbox_root.add_child(_banner_alerta)
	
	var vbox_topo = VBoxContainer.new()
	vbox_topo.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_topo.add_theme_constant_override("separation", 4)
	_banner_alerta.add_child(vbox_topo)
	
	_lbl_titulo_alerta = Label.new()
	_lbl_titulo_alerta.text = "⚠️ GOLPE SUPREMO DO CHEFE PREPARANDO! ⚠️"
	_lbl_titulo_alerta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_titulo_alerta.add_theme_font_size_override("font_size", 20)
	_lbl_titulo_alerta.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	_lbl_titulo_alerta.add_theme_font_override("font", font_titulo)
	vbox_topo.add_child(_lbl_titulo_alerta)
	
	_lbl_subtitulo_alerta = Label.new()
	_lbl_subtitulo_alerta.text = "A vida do monstro caiu pela metade! Prepare sua defesa arcana."
	_lbl_subtitulo_alerta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_subtitulo_alerta.add_theme_font_size_override("font_size", 13)
	_lbl_subtitulo_alerta.add_theme_color_override("font_color", Color(1.0, 0.75, 0.75))
	_lbl_subtitulo_alerta.add_theme_font_override("font", font_sans)
	vbox_topo.add_child(_lbl_subtitulo_alerta)
	
	# painel de instrucao antes da acao
	_painel_lore = PanelContainer.new()
	_painel_lore.custom_minimum_size = Vector2(680, 210)
	var sb_lore = StyleBoxFlat.new()
	sb_lore.bg_color = Color(0.08, 0.08, 0.14, 0.98)
	sb_lore.border_color = Color(1.0, 0.75, 0.25)
	sb_lore.set_border_width_all(2)
	sb_lore.set_corner_radius_all(10)
	sb_lore.content_margin_left = 26
	sb_lore.content_margin_right = 26
	sb_lore.content_margin_top = 18
	sb_lore.content_margin_bottom = 18
	sb_lore.shadow_color = Color(0, 0, 0, 0.85)
	sb_lore.shadow_size = 18
	_painel_lore.add_theme_stylebox_override("panel", sb_lore)
	vbox_root.add_child(_painel_lore)
	
	var vbox_lore_conteudo = VBoxContainer.new()
	vbox_lore_conteudo.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_lore_conteudo.add_theme_constant_override("separation", 12)
	_painel_lore.add_child(vbox_lore_conteudo)
	
	_lbl_lore_titulo = Label.new()
	_lbl_lore_titulo.text = "🔥 GOLPE SUPREMO DO CHEFE EM CARGA!"
	_lbl_lore_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_lore_titulo.add_theme_font_size_override("font_size", 18)
	_lbl_lore_titulo.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3))
	_lbl_lore_titulo.add_theme_font_override("font", font_titulo)
	vbox_lore_conteudo.add_child(_lbl_lore_titulo)
	
	_lbl_lore_texto = Label.new()
	_lbl_lore_texto.text = "Carregando a narrativa da fúria..."
	_lbl_lore_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_lore_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_lore_texto.add_theme_font_size_override("font_size", 14)
	_lbl_lore_texto.add_theme_color_override("font_color", Color(0.9, 0.92, 0.98))
	_lbl_lore_texto.add_theme_font_override("font", font_sans)
	vbox_lore_conteudo.add_child(_lbl_lore_texto)
	
	# regras da disputa
	var hbox_regras = HBoxContainer.new()
	hbox_regras.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_regras.add_theme_constant_override("separation", 14)
	vbox_lore_conteudo.add_child(hbox_regras)
	
	var criar_pill = func(icone: String, texto: String, cor_borda: Color) -> PanelContainer:
		var pill = PanelContainer.new()
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.10, 0.12, 0.18, 0.92)
		sb.border_color = cor_borda
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(6)
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		sb.content_margin_top = 7
		sb.content_margin_bottom = 7
		pill.add_theme_stylebox_override("panel", sb)
		
		var lbl = Label.new()
		lbl.text = icone + " " + texto
		lbl.add_theme_font_override("font", font_sans)
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
		pill.add_child(lbl)
		return pill
		
	hbox_regras.add_child(criar_pill.call("⏱️", "6s por rodada", Color(0.3, 0.7, 1.0, 0.8)))
	hbox_regras.add_child(criar_pill.call("🛡️", "Combo 3/3 ➔ Contra-Ataque (-40 Boss)", Color(0.3, 0.9, 0.5, 0.9)))
	hbox_regras.add_child(criar_pill.call("💥", "Erro ➔ Dano (-30)", Color(0.95, 0.4, 0.4, 0.8)))
	
	_btn_iniciar_defesa = Button.new()
	_btn_iniciar_defesa.text = "⚔️ PREPARAR DEFESA E INICIAR! (Espaço / Enter)"
	_btn_iniciar_defesa.custom_minimum_size = Vector2(400, 48)
	_btn_iniciar_defesa.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_btn_iniciar_defesa.focus_mode = Control.FOCUS_ALL
	
	var sb_btn_lore = StyleBoxFlat.new()
	sb_btn_lore.bg_color = Color(0.18, 0.42, 0.24, 0.98)
	sb_btn_lore.border_color = Color(0.4, 0.95, 0.6)
	sb_btn_lore.set_border_width_all(2)
	sb_btn_lore.set_corner_radius_all(8)
	_btn_iniciar_defesa.add_theme_stylebox_override("normal", sb_btn_lore)
	
	var sb_btn_lore_h = StyleBoxFlat.new()
	sb_btn_lore_h.bg_color = Color(0.24, 0.58, 0.32, 1.0)
	sb_btn_lore_h.border_color = Color(0.6, 1.0, 0.8)
	sb_btn_lore_h.set_border_width_all(2)
	sb_btn_lore_h.set_corner_radius_all(8)
	_btn_iniciar_defesa.add_theme_stylebox_override("hover", sb_btn_lore_h)
	_btn_iniciar_defesa.add_theme_stylebox_override("focus", sb_btn_lore_h)
	_btn_iniciar_defesa.add_theme_font_size_override("font_size", 15)
	_btn_iniciar_defesa.add_theme_color_override("font_color", Color.WHITE)
	_btn_iniciar_defesa.add_theme_font_override("font", font_titulo)
	_btn_iniciar_defesa.pressed.connect(_iniciar_desafio_quiz)
	vbox_lore_conteudo.add_child(_btn_iniciar_defesa)
	
	# quiz rapido V ou F
	_painel_quiz = VBoxContainer.new()
	_painel_quiz.alignment = BoxContainer.ALIGNMENT_CENTER
	_painel_quiz.add_theme_constant_override("separation", 14)
	_painel_quiz.visible = false
	vbox_root.add_child(_painel_quiz)
	
	# orbes de acerto
	_hbox_orbes = HBoxContainer.new()
	_hbox_orbes.alignment = BoxContainer.ALIGNMENT_CENTER
	_hbox_orbes.add_theme_constant_override("separation", 16)
	_painel_quiz.add_child(_hbox_orbes)
	
	_orbes.clear()
	for i in range(META_COMBO):
		var orbe = PanelContainer.new()
		orbe.custom_minimum_size = Vector2(130, 32)
		var sb_orbe = StyleBoxFlat.new()
		sb_orbe.bg_color = Color(0.12, 0.14, 0.22, 0.9)
		sb_orbe.border_color = Color(0.3, 0.4, 0.6)
		sb_orbe.set_border_width_all(1)
		sb_orbe.set_corner_radius_all(6)
		orbe.add_theme_stylebox_override("panel", sb_orbe)
		
		var lbl_o = Label.new()
		lbl_o.text = "✦ COMBO %d/3" % (i + 1)
		lbl_o.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_o.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_o.add_theme_font_size_override("font_size", 11)
		lbl_o.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
		lbl_o.add_theme_font_override("font", font_sans)
		orbe.add_child(lbl_o)
		
		_hbox_orbes.add_child(orbe)
		_orbes.append(orbe)
		
	# card da frase
	_painel_card_pergunta = PanelContainer.new()
	_painel_card_pergunta.custom_minimum_size = Vector2(640, 160)
	var sb_card = StyleBoxFlat.new()
	sb_card.bg_color = Color(0.08, 0.09, 0.16, 0.98)
	sb_card.border_color = Color(1.0, 0.75, 0.2)
	sb_card.set_border_width_all(2)
	sb_card.set_corner_radius_all(10)
	sb_card.content_margin_left = 24
	sb_card.content_margin_right = 24
	sb_card.content_margin_top = 18
	sb_card.content_margin_bottom = 18
	sb_card.shadow_color = Color(0, 0, 0, 0.8)
	sb_card.shadow_size = 15
	_painel_card_pergunta.add_theme_stylebox_override("panel", sb_card)
	_painel_quiz.add_child(_painel_card_pergunta)
	
	var vbox_card = VBoxContainer.new()
	vbox_card.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_card.add_theme_constant_override("separation", 14)
	_painel_card_pergunta.add_child(vbox_card)
	
	_lbl_afirmacao = Label.new()
	_lbl_afirmacao.text = "Preparando afirmação rúnica..."
	_lbl_afirmacao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_afirmacao.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lbl_afirmacao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_afirmacao.custom_minimum_size = Vector2(580, 65)
	_lbl_afirmacao.add_theme_font_size_override("font_size", 16)
	_lbl_afirmacao.add_theme_color_override("font_color", Color.WHITE)
	_lbl_afirmacao.add_theme_font_override("font", font_sans)
	vbox_card.add_child(_lbl_afirmacao)
	
	# barra de tempo
	var hbox_tempo = HBoxContainer.new()
	hbox_tempo.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_tempo.add_theme_constant_override("separation", 10)
	vbox_card.add_child(hbox_tempo)
	
	_barra_tempo = ProgressBar.new()
	_barra_tempo.custom_minimum_size = Vector2(460, 10)
	_barra_tempo.show_percentage = false
	_barra_tempo.max_value = TEMPO_POR_AFIRMACAO
	_barra_tempo.value = TEMPO_POR_AFIRMACAO
	var sb_tempo_fill = StyleBoxFlat.new()
	sb_tempo_fill.bg_color = Color(0.2, 0.85, 1.0)
	sb_tempo_fill.set_corner_radius_all(4)
	_barra_tempo.add_theme_stylebox_override("fill", sb_tempo_fill)
	hbox_tempo.add_child(_barra_tempo)
	
	_lbl_tempo = Label.new()
	_lbl_tempo.text = "6.0s"
	_lbl_tempo.add_theme_font_size_override("font_size", 13)
	_lbl_tempo.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	_lbl_tempo.add_theme_font_override("font", font_titulo)
	hbox_tempo.add_child(_lbl_tempo)
	
	# botoes verdadeiro e falso
	var hbox_botoes = HBoxContainer.new()
	hbox_botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_botoes.add_theme_constant_override("separation", 24)
	_painel_quiz.add_child(hbox_botoes)
	
	_btn_verdadeiro = Button.new()
	_btn_verdadeiro.text = "✓ VERDADEIRO"
	_btn_verdadeiro.custom_minimum_size = Vector2(280, 52)
	_btn_verdadeiro.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_btn_verdadeiro.focus_mode = Control.FOCUS_ALL
	
	var sb_v_norm = StyleBoxFlat.new()
	sb_v_norm.bg_color = Color(0.08, 0.35, 0.18, 0.95)
	sb_v_norm.border_color = Color(0.35, 0.95, 0.55)
	sb_v_norm.set_border_width_all(2)
	sb_v_norm.set_corner_radius_all(8)
	
	var sb_v_hover = StyleBoxFlat.new()
	sb_v_hover.bg_color = Color(0.12, 0.52, 0.26, 1.0)
	sb_v_hover.border_color = Color(0.6, 1.0, 0.75)
	sb_v_hover.set_border_width_all(2)
	sb_v_hover.set_corner_radius_all(8)
	
	var sb_v_press = StyleBoxFlat.new()
	sb_v_press.bg_color = Color(0.2, 0.7, 0.35, 1.0)
	sb_v_press.border_color = Color(1.0, 1.0, 1.0)
	sb_v_press.set_border_width_all(2)
	sb_v_press.set_corner_radius_all(8)
	
	_btn_verdadeiro.add_theme_stylebox_override("normal", sb_v_norm)
	_btn_verdadeiro.add_theme_stylebox_override("hover", sb_v_hover)
	_btn_verdadeiro.add_theme_stylebox_override("focus", sb_v_hover)
	_btn_verdadeiro.add_theme_stylebox_override("pressed", sb_v_press)
	_btn_verdadeiro.add_theme_font_size_override("font_size", 16)
	_btn_verdadeiro.add_theme_color_override("font_color", Color(0.9, 1.0, 0.9))
	_btn_verdadeiro.add_theme_font_override("font", font_titulo)
	_btn_verdadeiro.pressed.connect(func(): _responder(true))
	hbox_botoes.add_child(_btn_verdadeiro)
	
	_btn_falso = Button.new()
	_btn_falso.text = "✗ FALSO"
	_btn_falso.custom_minimum_size = Vector2(280, 52)
	_btn_falso.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_btn_falso.focus_mode = Control.FOCUS_ALL
	
	var sb_f_norm = StyleBoxFlat.new()
	sb_f_norm.bg_color = Color(0.38, 0.10, 0.12, 0.95)
	sb_f_norm.border_color = Color(0.95, 0.35, 0.40)
	sb_f_norm.set_border_width_all(2)
	sb_f_norm.set_corner_radius_all(8)
	
	var sb_f_hover = StyleBoxFlat.new()
	sb_f_hover.bg_color = Color(0.55, 0.14, 0.18, 1.0)
	sb_f_hover.border_color = Color(1.0, 0.6, 0.65)
	sb_f_hover.set_border_width_all(2)
	sb_f_hover.set_corner_radius_all(8)
	
	var sb_f_press = StyleBoxFlat.new()
	sb_f_press.bg_color = Color(0.75, 0.2, 0.25, 1.0)
	sb_f_press.border_color = Color(1.0, 1.0, 1.0)
	sb_f_press.set_border_width_all(2)
	sb_f_press.set_corner_radius_all(8)
	
	_btn_falso.add_theme_stylebox_override("normal", sb_f_norm)
	_btn_falso.add_theme_stylebox_override("hover", sb_f_hover)
	_btn_falso.add_theme_stylebox_override("focus", sb_f_hover)
	_btn_falso.add_theme_stylebox_override("pressed", sb_f_press)
	_btn_falso.add_theme_font_size_override("font_size", 16)
	_btn_falso.add_theme_color_override("font_color", Color(1.0, 0.9, 0.9))
	_btn_falso.add_theme_font_override("font", font_titulo)
	_btn_falso.pressed.connect(func(): _responder(false))
	hbox_botoes.add_child(_btn_falso)
	
	# dica pra pular resultado
	_lbl_dica_continuar = Label.new()
	_lbl_dica_continuar.text = "( Pressione ESPAÇO ou ENTER para continuar )"
	_lbl_dica_continuar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_dica_continuar.add_theme_font_size_override("font_size", 13)
	_lbl_dica_continuar.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 0.9))
	_lbl_dica_continuar.add_theme_font_override("font", font_sans)
	_lbl_dica_continuar.visible = false
	vbox_root.add_child(_lbl_dica_continuar)

func iniciar_furia(andar_id: int, nome_chefe: String = "Chefe Supremo") -> void:
	_andar_atual = clampi(andar_id, 1, 3)
	_nome_chefe = nome_chefe
	_combo_atual = 0
	_ja_emitiu = false
	_em_andamento = false
	_respondendo = false
	_fase_atual = Fase.LORE
	
	# sorteia 3 frases
	var pool = banco_afirmacoes.get(_andar_atual, banco_afirmacoes[1]).duplicate()
	pool.shuffle()
	_perguntas_ativas = pool.slice(0, mini(META_COMBO, pool.size()))
	_indice_pergunta = 0
	
	# texto do boss do andar
	var info_lore = lores_chefe.get(_andar_atual, lores_chefe[1])
	_lbl_titulo_alerta.text = "⚠️ GOLPE SUPREMO DO CHEFE PREPARANDO! ⚠️"
	_lbl_subtitulo_alerta.text = "A vida do monstro caiu pela metade! Prepare sua defesa arcana."
	_lbl_lore_titulo.text = info_lore["golpe"]
	_lbl_lore_texto.text = info_lore.get("lore", "O monstro está prestes a desferir um ataque devastador!")
	
	# visual inicial
	_painel_lore.visible = true
	_painel_quiz.visible = false
	_lbl_dica_continuar.visible = false
	
	_btn_verdadeiro.disabled = false
	_btn_falso.disabled = false
	
	_atualizar_orbes_ui()
	
	# som de alerta
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("transicao-1")
		
	# animacao do painel
	_painel_lore.modulate.a = 0.0
	_banner_alerta.scale = Vector2(0.85, 0.85)
	
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_banner_alerta, "scale", Vector2.ONE, 0.25)
	tw.tween_property(_painel_lore, "modulate:a", 1.0, 0.25)
	
	_btn_iniciar_defesa.grab_focus()

func _iniciar_desafio_quiz() -> void:
	if _fase_atual != Fase.LORE:
		return
		
	_fase_atual = Fase.CONTAGEM
	
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui-1")
		
	# comeca o quiz
	_painel_lore.visible = false
	_painel_quiz.visible = true
	_painel_quiz.modulate.a = 0.0
	
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	tw.tween_property(_painel_quiz, "modulate:a", 1.0, 0.2)
	
	await get_tree().create_timer(0.25, true).timeout
	
	_fase_atual = Fase.QUIZ
	_carregar_proxima_afirmacao()

func _carregar_proxima_afirmacao() -> void:
	if _fase_atual != Fase.QUIZ: return
	if _indice_pergunta >= _perguntas_ativas.size():
		_concluir_vitoria_parry()
		return
		
	_respondendo = false
	_em_andamento = true
	_tempo_restante = TEMPO_POR_AFIRMACAO
	
	var item = _perguntas_ativas[_indice_pergunta]
	_lbl_afirmacao.text = item["texto"]
	_barra_tempo.value = TEMPO_POR_AFIRMACAO
	_lbl_tempo.text = "%.1fs" % TEMPO_POR_AFIRMACAO
	
	_lbl_afirmacao.modulate.a = 0.0
	var tw_txt = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw_txt.tween_property(_lbl_afirmacao, "modulate:a", 1.0, 0.12)
	
	_btn_verdadeiro.grab_focus()

func _process(delta: float) -> void:
	if _fase_atual != Fase.QUIZ or not _em_andamento or _respondendo:
		return
		
	_tempo_restante -= delta
	if _tempo_restante <= 0.0:
		_tempo_restante = 0.0
		_barra_tempo.value = 0.0
		_lbl_tempo.text = "0.0s"
		_em_andamento = false
		_concluir_falha_tempo()
		return
		
	_barra_tempo.value = _tempo_restante
	_lbl_tempo.text = "%.1fs" % _tempo_restante
	
	var sb = _barra_tempo.get_theme_stylebox("fill") as StyleBoxFlat
	if sb:
		if _tempo_restante <= 2.0:
			sb.bg_color = Color(1.0, 0.2, 0.2)
			_lbl_tempo.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
		elif _tempo_restante <= 3.8:
			sb.bg_color = Color(1.0, 0.8, 0.2)
			_lbl_tempo.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		else:
			sb.bg_color = Color(0.2, 0.85, 1.0)
			_lbl_tempo.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))

func _input(event: InputEvent) -> void:
	if _fase_atual == Fase.LORE:
		if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)):
			get_viewport().set_input_as_handled()
			_iniciar_desafio_quiz()
		return

	if _fase_atual == Fase.RESULTADO:
		if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)):
			get_viewport().set_input_as_handled()
			_fechar_e_emitir(_resultado_sucesso)
		return

func _responder(escolha_verdadeiro: bool) -> void:
	if _fase_atual != Fase.QUIZ or not _em_andamento or _respondendo:
		return
		
	_respondendo = true
	_em_andamento = false
	
	var item = _perguntas_ativas[_indice_pergunta]
	var acertou = (escolha_verdadeiro == item["correta"])
	
	if acertou:
		_combo_atual += 1
		_atualizar_orbes_ui()
		
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("acerto_1")
			
		_animar_feedback_card(Color(0.2, 0.9, 0.4), "✓ ACERTOU O COMBO!")
		await get_tree().create_timer(0.35, true).timeout
		
		_indice_pergunta += 1
		if _combo_atual >= META_COMBO:
			_concluir_vitoria_parry()
		else:
			_carregar_proxima_afirmacao()
	else:
		_animar_feedback_card(Color(1.0, 0.25, 0.25), "✗ ERROU! O COMBO QUEBROU!")
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("ui-2")
		await get_tree().create_timer(0.5, true).timeout
		_concluir_falha_erro()

func _atualizar_orbes_ui() -> void:
	for i in range(_orbes.size()):
		var orbe = _orbes[i]
		var sb = orbe.get_theme_stylebox("panel") as StyleBoxFlat
		var lbl = orbe.get_child(0) as Label
		
		if i < _combo_atual:
			sb.bg_color = Color(0.15, 0.45, 0.25, 1.0)
			sb.border_color = Color(0.4, 1.0, 0.6)
			sb.set_border_width_all(2)
			lbl.text = "✓ COMBO %d ATIVO!" % (i + 1)
			lbl.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
			
			var tw_o = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tw_o.tween_property(orbe, "scale", Vector2(1.1, 1.1), 0.1)
			tw_o.tween_property(orbe, "scale", Vector2.ONE, 0.1)
		else:
			sb.bg_color = Color(0.12, 0.14, 0.22, 0.9)
			sb.border_color = Color(0.3, 0.4, 0.6)
			sb.set_border_width_all(1)
			lbl.text = "✦ COMBO %d/3" % (i + 1)
			lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))

func _animar_feedback_card(cor: Color, texto_status: String) -> void:
	var sb = _painel_card_pergunta.get_theme_stylebox("panel") as StyleBoxFlat
	if sb:
		var cor_original = Color(1.0, 0.75, 0.2)
		var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(sb, "border_color", cor, 0.1)
		tw.tween_property(sb, "border_color", cor_original, 0.25)
	
	var lbl_temp = Label.new()
	lbl_temp.text = texto_status
	lbl_temp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_temp.add_theme_font_size_override("font_size", 14)
	lbl_temp.add_theme_color_override("font_color", cor)
	var font_sans = SystemFont.new()
	font_sans.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_sans.font_weight = 700
	lbl_temp.add_theme_font_override("font", font_sans)
	_painel_card_pergunta.get_child(0).add_child(lbl_temp)
	
	var tw_l = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	tw_l.tween_property(lbl_temp, "modulate:a", 0.0, 0.35)
	tw_l.chain().tween_callback(lbl_temp.queue_free)

func _concluir_vitoria_parry() -> void:
	_fase_atual = Fase.RESULTADO
	_resultado_sucesso = true
	_em_andamento = false
	
	_lbl_titulo_alerta.text = "✦ CONTRA-ATAQUE ARCANO! GOLPE REBATIDO! ✦"
	_lbl_titulo_alerta.add_theme_color_override("font_color", Color(0.3, 1.0, 0.6))
	_lbl_subtitulo_alerta.text = "Você desarmou o ataque e quebrou a postura do Chefe com -40 HP de Dano Crítico!"
	_lbl_afirmacao.text = "O golpe do Chefe foi REBATIDO com maestria!"
	
	_btn_verdadeiro.disabled = true
	_btn_falso.disabled = true
	_lbl_dica_continuar.visible = true
	
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("win")
		AudioManager.tocar_som_ataque()
		
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_painel_card_pergunta, "scale", Vector2(1.04, 1.04), 0.12)
	tw.tween_property(_painel_card_pergunta, "scale", Vector2.ONE, 0.12)
	
	# espera ou aperta enter
	await get_tree().create_timer(2.2, true).timeout
	if _fase_atual == Fase.RESULTADO and not _ja_emitiu:
		_fechar_e_emitir(true)

func _concluir_falha_tempo() -> void:
	_lbl_afirmacao.text = "TEMPO ESGOTADO! O Golpe Supremo foi desferido sem defesa!"
	_concluir_falha_generica()

func _concluir_falha_erro() -> void:
	_lbl_afirmacao.text = "O selo quebrou! Você sofreu o impacto total da Fúria do Chefe (-30 HP)!"
	_concluir_falha_generica()

func _concluir_falha_generica() -> void:
	_fase_atual = Fase.RESULTADO
	_resultado_sucesso = false
	_em_andamento = false
	
	_lbl_titulo_alerta.text = "💥 GOLPE SUPREMO DO CHEFE TE ATINGIU! 💥"
	_lbl_titulo_alerta.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
	_lbl_subtitulo_alerta.text = "Você não conseguiu quebrar a Fúria e sofreu -30 HP de Dano Severo!"
	
	_btn_verdadeiro.disabled = true
	_btn_falso.disabled = true
	_lbl_dica_continuar.visible = true
	
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("fail")
		AudioManager.tocar_som_dano()
		
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_painel_card_pergunta, "position:x", _painel_card_pergunta.position.x + 8.0, 0.04)
	tw.tween_property(_painel_card_pergunta, "position:x", _painel_card_pergunta.position.x - 8.0, 0.04)
	tw.tween_property(_painel_card_pergunta, "position:x", _painel_card_pergunta.position.x, 0.04)
	
	# espera ou aperta enter
	await get_tree().create_timer(2.2, true).timeout
	if _fase_atual == Fase.RESULTADO and not _ja_emitiu:
		_fechar_e_emitir(false)

func _fechar_e_emitir(sucesso: bool) -> void:
	if _ja_emitiu:
		return
	_ja_emitiu = true
	_em_andamento = false
	
	# timer pra liberar
	get_tree().create_timer(0.25, true).timeout.connect(func():
		if is_instance_valid(self) and not is_queued_for_deletion():
			furia_concluida.emit(sucesso)
			queue_free()
	)
	
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	if is_instance_valid(_root_container):
		tw.tween_property(_root_container, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(func():
		furia_concluida.emit(sucesso)
		queue_free()
	)

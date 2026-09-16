extends CanvasLayer

@onready var fill: NinePatchRect = $Control/HealthBarContainer/HealthBarFill
@onready var text_label: Label = $Control/HealthText

var max_width: float = 200.0

# Sistema de Notificações de Quests / Toast
var _toast_panel: PanelContainer = null
var _toast_label_titulo: Label = null
var _toast_label_sub: Label = null
var _toast_tween: Tween = null

var _ultimas_ativas: Dictionary = {}
var _ultimas_concluidas: Dictionary = {}

var defs_titulos_quests = {
	"cientista_quest1": "Procurar Livros de Fórmulas",
	"cientista_quest2": "Caçar Slimes da Alquimia",
	"fisica_quest1": "Coleta de Baterias Elétricas",
	"fisica_quest2": "Coleta de Fragmentos de Chip"
}

func _ready() -> void:
	add_to_group("hud")
	visible = true
	
	# Seta a vida inicial
	atualizar_vida(PlayerStats.vida_atual_jogador, PlayerStats.vida_maxima_jogador)
	PlayerStats.vida_alterada.connect(atualizar_vida)
	
	# Esconde a barra na batalha
	GlobalSignals.iniciar_batalha.connect(func(_enemy_data): self.hide())
	GlobalSignals.batalha_encerrada.connect(func(_vitoria: bool): self.show())
	
	# Inicializa o hud de quests dinamicamente
	var cena_quest_hud = load("res://scripts/ui/QuestHUD.gd")
	if cena_quest_hud:
		var q_hud = Control.new()
		q_hud.set_script(cena_quest_hud)
		if has_node("Control"):
			$Control.add_child(q_hud)
		else:
			add_child(q_hud)
			
	_criar_painel_toast()
	
	# Monitoramento de quests
	_ultimas_ativas = PlayerStats.quests_ativas.duplicate()
	_ultimas_concluidas = PlayerStats.quests_concluidas.duplicate()
	PlayerStats.quests_atualizadas.connect(_verificar_mudancas_quest)

func _criar_painel_toast() -> void:
	_toast_panel = PanelContainer.new()
	_toast_panel.name = "ToastNotificacaoQuest"
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_panel.custom_minimum_size = Vector2(360, 56)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.14, 0.95)
	sb.border_color = Color(1.0, 0.85, 0.3)
	sb.border_width_left = 3
	sb.border_width_right = 3
	sb.border_width_top = 3
	sb.border_width_bottom = 3
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	sb.shadow_color = Color(0, 0, 0, 0.7)
	sb.shadow_size = 10
	_toast_panel.add_theme_stylebox_override("panel", sb)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	
	var font_pixel = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	
	_toast_label_titulo = Label.new()
	if font_pixel: _toast_label_titulo.add_theme_font_override("font", font_pixel)
	_toast_label_titulo.add_theme_font_size_override("font_size", 18)
	_toast_label_titulo.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	_toast_label_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_toast_label_titulo)
	
	var font_num = font_pixel

	_toast_label_sub = Label.new()
	_toast_label_sub.add_theme_font_override("font", font_num)
	_toast_label_sub.add_theme_font_size_override("font_size", 14)
	_toast_label_sub.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	_toast_label_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_toast_label_sub)
	
	_toast_panel.add_child(vbox)
	
	var parent_node = $Control if has_node("Control") else self
	parent_node.add_child(_toast_panel)
	
	_toast_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast_panel.grow_vertical = Control.GROW_DIRECTION_END
	_toast_panel.position.y = -90.0
	_toast_panel.modulate.a = 0.0
	_toast_panel.pivot_offset = Vector2(180, 28)

func _verificar_mudancas_quest() -> void:
	for q_id in PlayerStats.quests_concluidas.keys():
		if PlayerStats.quests_concluidas[q_id] and not _ultimas_concluidas.get(q_id, false):
			var nome = defs_titulos_quests.get(q_id, "Missão")
			mostrar_notificacao_quest("✨ MISSÃO CONCLUÍDA!", nome + " (+50 Moedas)", Color(1.0, 0.85, 0.2), "acerto_1")
			_ultimas_concluidas = PlayerStats.quests_concluidas.duplicate()
			_ultimas_ativas = PlayerStats.quests_ativas.duplicate()
			return
			
	for q_id in PlayerStats.quests_ativas.keys():
		if PlayerStats.quests_ativas[q_id] and not _ultimas_ativas.get(q_id, false):
			var nome = defs_titulos_quests.get(q_id, "Missão")
			mostrar_notificacao_quest("📜 NOVA MISSÃO ACEITA", nome, Color(0.25, 0.85, 1.0), "ui_5")
			_ultimas_ativas = PlayerStats.quests_ativas.duplicate()
			_ultimas_concluidas = PlayerStats.quests_concluidas.duplicate()
			return
			
	_ultimas_ativas = PlayerStats.quests_ativas.duplicate()
	_ultimas_concluidas = PlayerStats.quests_concluidas.duplicate()

func mostrar_mensagem(texto: String) -> void:
	mostrar_notificacao_quest("📦 ITEM COLETADO", texto, Color(0.3, 0.9, 0.5), "ui_1")

func mostrar_notificacao_quest(titulo: String, subtitulo: String, cor_borda: Color = Color(1.0, 0.85, 0.3), som: String = "ui_5") -> void:
	if _toast_panel == null:
		return
		
	if get_node_or_null("/root/AudioManager") and som != "":
		AudioManager.play_sfx(som)
		
	var sb = _toast_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if sb:
		sb.border_color = cor_borda
		
	_toast_label_titulo.text = titulo
	_toast_label_titulo.add_theme_color_override("font_color", cor_borda)
	_toast_label_sub.text = subtitulo
	_toast_label_sub.visible = (subtitulo != "")
	
	var vp_width = get_viewport().get_visible_rect().size.x
	_toast_panel.position.x = (vp_width - _toast_panel.size.x) * 0.5
	_toast_panel.pivot_offset = _toast_panel.size * 0.5
	
	if _toast_tween and _toast_tween.is_running():
		_toast_tween.kill()
		
	_toast_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	# Se o aviso já estiver na tela (ex: pegou outro item rapidamente), atualiza na hora com pulso
	if _toast_panel.position.y > -20.0 and _toast_panel.modulate.a > 0.2:
		_toast_panel.position.y = 35.0
		_toast_panel.modulate.a = 1.0
		# Pulso elástico para feedback imediato do novo item coletado
		_toast_tween.tween_property(_toast_panel, "scale", Vector2(1.08, 1.08), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_toast_tween.tween_property(_toast_panel, "scale", Vector2(1.0, 1.0), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		# Se estiver fora da tela, desce suavemente
		_toast_panel.position.y = -90.0
		_toast_panel.modulate.a = 0.0
		_toast_panel.scale = Vector2(1.0, 1.0)
		_toast_tween.tween_property(_toast_panel, "position:y", 35.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_toast_tween.parallel().tween_property(_toast_panel, "modulate:a", 1.0, 0.25)
	
	# Permanece visível por 2.0 segundos após o último item/ação
	_toast_tween.tween_interval(2.0)
	
	# Sobe de volta suavemente
	_toast_tween.tween_property(_toast_panel, "position:y", -90.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_toast_tween.parallel().tween_property(_toast_panel, "modulate:a", 0.0, 0.30)

func atualizar_vida(atual: float, maxima: float) -> void:
	var pct = clamp(atual / maxima, 0.0, 1.0)
	var target_w = max(0.0, max_width * pct)
	
	if target_w > 0:
		fill.visible = true
		
	var tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fill, "size:x", target_w, 0.3)
	
	if target_w <= 0:
		tween.finished.connect(func(): fill.visible = false, CONNECT_ONE_SHOT)
	
	text_label.text = str(max(0, int(atual))) + " / " + str(int(maxima))

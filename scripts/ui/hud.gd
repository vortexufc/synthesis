extends CanvasLayer

@onready var fill: NinePatchRect = $Control/HealthBarContainer/HealthBarFill
@onready var ghost: NinePatchRect = $Control/HealthBarContainer/HealthBarGhost
@onready var text_label: Label = $Control/HealthText
@onready var heart_icon: TextureRect = $Control/HeartIcon
@onready var health_container: Control = $Control/HealthBarContainer

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

# Controle de animação da barra de vida
var _vida_anterior: float = -1.0
var _displayed_vida: float = 100.0
var _tween_fill: Tween = null
var _tween_ghost: Tween = null
var _tween_heart: Tween = null
var _tween_roll: Tween = null
var _heart_base_pos: Vector2 = Vector2.ZERO
var _heal_particles: CPUParticles2D = null
var _font_pixel: Font = null

# Efeito de Vida Crítica (Vinheta vermelha & Coração acelerado)
var _vinheta_critica: TextureRect = null
var _tween_vinheta: Tween = null
var _tween_heart_critico: Tween = null
var _em_alerta_critico: bool = false

# Indicador do Dash Arcana
var _dash_bar: ProgressBar = null
var _dash_label: Label = null
var _dash_tween: Tween = null

func _ready() -> void:
	add_to_group("hud")
	visible = true
	_font_pixel = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	
	if heart_icon:
		_heart_base_pos = heart_icon.position
		heart_icon.pivot_offset = heart_icon.size * 0.5
		
	if _font_pixel and text_label:
		text_label.add_theme_font_override("font", _font_pixel)
		text_label.add_theme_font_size_override("font_size", 16)
		text_label.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.08, 0.95))
		text_label.add_theme_constant_override("outline_size", 2)
		
	_criar_vinheta_critica()
	_criar_particulas_cura()
	
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
	_criar_indicador_dash()
	
	# Monitoramento de quests
	_ultimas_ativas = PlayerStats.quests_ativas.duplicate()
	_ultimas_concluidas = PlayerStats.quests_concluidas.duplicate()
	PlayerStats.quests_atualizadas.connect(_verificar_mudancas_quest)

func _exit_tree() -> void:
	if _tween_roll and _tween_roll.is_running():
		_tween_roll.kill()
	if _tween_fill and _tween_fill.is_running():
		_tween_fill.kill()
	if _tween_ghost and _tween_ghost.is_running():
		_tween_ghost.kill()
	if _tween_heart and _tween_heart.is_running():
		_tween_heart.kill()
	if _tween_vinheta and _tween_vinheta.is_running():
		_tween_vinheta.kill()
	if _tween_heart_critico and _tween_heart_critico.is_running():
		_tween_heart_critico.kill()
	if _dash_tween and _dash_tween.is_running():
		_dash_tween.kill()

var _vida_maxima_cache: float = 100.0
var _target_w_cache: float = 0.0

func _atualizar_texto_vida_roll(val: float) -> void:
	_displayed_vida = val
	if text_label and is_instance_valid(text_label):
		text_label.text = str(max(0, int(round(val)))) + " / " + str(int(round(_vida_maxima_cache)))

func _on_roll_cura_finished() -> void:
	if text_label and is_instance_valid(text_label):
		text_label.remove_theme_color_override("font_color")

func _on_roll_dano_finished() -> void:
	if text_label and is_instance_valid(text_label):
		text_label.remove_theme_color_override("font_color")
	if fill and is_instance_valid(fill) and _target_w_cache <= 0.0:
		fill.visible = false
		if ghost and is_instance_valid(ghost):
			ghost.visible = false


func _criar_vinheta_critica() -> void:
	var parent_ctrl: Node = get_node_or_null("Control")
	if parent_ctrl == null:
		parent_ctrl = self
	if _vinheta_critica != null:
		return
		
	_vinheta_critica = TextureRect.new()
	_vinheta_critica.name = "VinhetaVidaCritica"
	_vinheta_critica.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vinheta_critica.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vinheta_critica.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_vinheta_critica.grow_vertical = Control.GROW_DIRECTION_END
	_vinheta_critica.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vinheta_critica.modulate.a = 0.0
	
	# Gradiente radial com túnel escurecido e vermelho escarlate nas bordas (Item 5 melhorado)
	var grad = Gradient.new()
	grad.colors = PackedColorArray([
		Color(0.85, 0.05, 0.05, 0.0),    # Centro limpo
		Color(0.85, 0.05, 0.05, 0.16),   # Transição suave
		Color(0.92, 0.02, 0.02, 0.68),   # Borda vermelha pulsante
		Color(0.12, 0.0, 0.03, 0.90)     # Cantos com vinheta escura (visão de túnel)
	])
	grad.offsets = PackedFloat32Array([0.0, 0.40, 0.80, 1.0])
	
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 320
	tex.height = 180
	
	_vinheta_critica.texture = tex
	parent_ctrl.add_child(_vinheta_critica)
	parent_ctrl.move_child(_vinheta_critica, 0)

func _verificar_estado_critico(atual: float, maxima: float) -> void:
	var eh_critico = (atual > 0.0 and (atual / maxima) <= 0.28)
	if eh_critico != _em_alerta_critico:
		_em_alerta_critico = eh_critico
		_atualizar_alerta_critico(eh_critico)

func _atualizar_alerta_critico(ativo: bool) -> void:
	if _vinheta_critica:
		if _tween_vinheta and _tween_vinheta.is_running():
			_tween_vinheta.kill()
		_tween_vinheta = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		if ativo:
			# Ritmo cardiovascular duplo (Lub-Dub orgânico)
			_tween_vinheta.set_loops()
			# Pulso 1: Lub
			_tween_vinheta.tween_property(_vinheta_critica, "modulate:a", 0.55, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_tween_vinheta.tween_property(_vinheta_critica, "modulate:a", 0.30, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			# Pulso 2: DUB (impacto principal)
			_tween_vinheta.tween_property(_vinheta_critica, "modulate:a", 0.88, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_tween_vinheta.tween_property(_vinheta_critica, "modulate:a", 0.18, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			# Intervalo de descanso entre batimentos
			_tween_vinheta.tween_interval(0.42)
		else:
			_tween_vinheta.tween_property(_vinheta_critica, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			
	if heart_icon:
		if _tween_heart_critico and _tween_heart_critico.is_running():
			_tween_heart_critico.kill()
		if ativo:
			_tween_heart_critico = create_tween().set_loops().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			# Pulso 1: Lub
			_tween_heart_critico.tween_property(heart_icon, "scale", Vector2(1.18, 1.18), 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_tween_heart_critico.parallel().tween_property(heart_icon, "modulate", Color(1.2, 0.45, 0.45), 0.09)
			_tween_heart_critico.tween_property(heart_icon, "scale", Vector2(1.05, 1.05), 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			# Pulso 2: DUB (sístole profunda)
			_tween_heart_critico.tween_property(heart_icon, "scale", Vector2(1.35, 1.35), 0.11).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_tween_heart_critico.parallel().tween_property(heart_icon, "modulate", Color(1.4, 0.25, 0.25), 0.11)
			_tween_heart_critico.tween_property(heart_icon, "scale", Vector2(1.0, 1.0), 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			_tween_heart_critico.parallel().tween_property(heart_icon, "modulate", Color(1.0, 0.85, 0.85), 0.22)
			# Intervalo
			_tween_heart_critico.tween_interval(0.42)
		else:
			var tw_h = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw_h.tween_property(heart_icon, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw_h.parallel().tween_property(heart_icon, "modulate", Color.WHITE, 0.25)


func _criar_particulas_cura() -> void:
	if health_container == null:
		return
		
	_heal_particles = CPUParticles2D.new()
	_heal_particles.name = "HealParticles"
	_heal_particles.emitting = false
	_heal_particles.one_shot = true
	_heal_particles.explosiveness = 0.45
	_heal_particles.amount = 14
	_heal_particles.lifetime = 0.65
	_heal_particles.direction = Vector2(0.0, -1.0)
	_heal_particles.spread = 50.0
	_heal_particles.gravity = Vector2(0.0, -22.0)
	_heal_particles.initial_velocity_min = 25.0
	_heal_particles.initial_velocity_max = 50.0
	_heal_particles.scale_amount_min = 2.0
	_heal_particles.scale_amount_max = 3.5
	_heal_particles.color = Color(0.35, 1.0, 0.45, 0.95)
	health_container.add_child(_heal_particles)


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
	
	var font_pixel = _font_pixel if _font_pixel else (load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font)
	
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
	
	var parent_node: Node = get_node_or_null("Control")
	if parent_node == null:
		parent_node = self
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
	
	if _toast_panel.position.y > -20.0 and _toast_panel.modulate.a > 0.2:
		_toast_panel.position.y = 35.0
		_toast_panel.modulate.a = 1.0
		_toast_tween.tween_property(_toast_panel, "scale", Vector2(1.08, 1.08), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_toast_tween.tween_property(_toast_panel, "scale", Vector2(1.0, 1.0), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		_toast_panel.position.y = -90.0
		_toast_panel.modulate.a = 0.0
		_toast_panel.scale = Vector2(1.0, 1.0)
		_toast_tween.tween_property(_toast_panel, "position:y", 35.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_toast_tween.parallel().tween_property(_toast_panel, "modulate:a", 1.0, 0.25)
	
	_toast_tween.tween_interval(2.0)
	
	_toast_tween.tween_property(_toast_panel, "position:y", -90.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_toast_tween.parallel().tween_property(_toast_panel, "modulate:a", 0.0, 0.30)


func atualizar_vida(atual: float, maxima: float) -> void:
	var pct = clamp(atual / maxima, 0.0, 1.0)
	var target_w = max(0.0, max_width * pct)
	
	_verificar_estado_critico(atual, maxima)
	
	# Primeira inicialização: define instantaneamente sem animações
	if _vida_anterior < 0.0:
		_vida_anterior = atual
		_displayed_vida = atual
		fill.set_deferred("size:x", target_w)
		if ghost: ghost.set_deferred("size:x", target_w)
		fill.visible = (target_w > 0.0)
		if text_label:
			text_label.text = str(max(0, int(round(atual)))) + " / " + str(int(round(maxima)))
		return
	
	var diff = atual - _vida_anterior
	_vida_anterior = atual
	
	if diff > 0.0:
		_animar_cura(atual, maxima, target_w, diff)
	elif diff < 0.0:
		_animar_dano(atual, maxima, target_w, abs(diff))
	else:
		fill.size.x = target_w
		if ghost: ghost.size.x = target_w


func _animar_cura(atual: float, maxima: float, target_w: float, qtd_curada: float) -> void:
	fill.visible = true
	if ghost: ghost.visible = true
	
	# 1. Preenchimento suave com curva fluida (TRANS_CUBIC, EASE_OUT)
	if _tween_fill and _tween_fill.is_running():
		_tween_fill.kill()
	_tween_fill = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween_fill.tween_property(fill, "size:x", target_w, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if ghost:
		_tween_fill.parallel().tween_property(ghost, "size:x", target_w, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 2. Flash / Brilho esmeralda na barra
	var tween_glow = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fill.modulate = Color(1.6, 2.4, 1.6)
	tween_glow.tween_property(fill, "modulate", Color.WHITE, 0.60).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 3. Pulso cardíaco do ícone de coração (batimento elástico e vivo)
	if heart_icon:
		if _tween_heart and _tween_heart.is_running():
			_tween_heart.kill()
		_tween_heart = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		heart_icon.scale = Vector2(1.0, 1.0)
		_tween_heart.tween_property(heart_icon, "scale", Vector2(1.35, 1.35), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tween_heart.tween_property(heart_icon, "scale", Vector2(1.10, 1.10), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_tween_heart.tween_property(heart_icon, "scale", Vector2(1.22, 1.22), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tween_heart.tween_property(heart_icon, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 4. Partículas mágicas de cura
	if _heal_particles:
		_heal_particles.position = Vector2(clamp(target_w, 10.0, max_width - 8.0), 12.0)
		_heal_particles.restart()
		_heal_particles.emitting = true
	
	# 5. Rolagem numérica suave dos pontos de vida + tom verde esmeralda
	_vida_maxima_cache = maxima
	_target_w_cache = target_w
	if _tween_roll and _tween_roll.is_running():
		_tween_roll.kill()
	_tween_roll = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween_roll.tween_method(_atualizar_texto_vida_roll, _displayed_vida, atual, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	if text_label:
		text_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.5))
		_tween_roll.finished.connect(_on_roll_cura_finished, CONNECT_ONE_SHOT)
	
	# 6. Texto flutuante de cura (+X HP)
	_mostrar_texto_flutuante_cura(qtd_curada)


func _animar_dano(atual: float, maxima: float, target_w: float, qtd_dano: float) -> void:
	_vida_maxima_cache = maxima
	_target_w_cache = target_w
	# 1. Fill verde cai com impacto rápido
	if _tween_fill and _tween_fill.is_running():
		_tween_fill.kill()
	_tween_fill = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween_fill.tween_property(fill, "size:x", target_w, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 2. Ghost vermelho segura por 0.25s e depois encolhe suavemente
	if ghost:
		if _tween_ghost and _tween_ghost.is_running():
			_tween_ghost.kill()
		_tween_ghost = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_tween_ghost.tween_interval(0.25)
		_tween_ghost.tween_property(ghost, "size:x", target_w, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 3. Tremor de impacto no coração
	if heart_icon:
		if _tween_heart and _tween_heart.is_running():
			_tween_heart.kill()
		_tween_heart = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_tween_heart.tween_property(heart_icon, "position:x", _heart_base_pos.x - 3.0, 0.04)
		_tween_heart.tween_property(heart_icon, "position:x", _heart_base_pos.x + 3.0, 0.04)
		_tween_heart.tween_property(heart_icon, "position:x", _heart_base_pos.x - 2.0, 0.04)
		_tween_heart.tween_property(heart_icon, "position:x", _heart_base_pos.x + 2.0, 0.04)
		_tween_heart.tween_property(heart_icon, "position:x", _heart_base_pos.x, 0.04)
	
	# 4. Rolagem dos números descendo com cor avermelhada
	if _tween_roll and _tween_roll.is_running():
		_tween_roll.kill()
	_tween_roll = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween_roll.tween_method(_atualizar_texto_vida_roll, _displayed_vida, atual, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	if text_label:
		text_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		_tween_roll.finished.connect(_on_roll_dano_finished, CONNECT_ONE_SHOT)
	
	# 5. Texto flutuante de dano (-X HP)
	_mostrar_texto_flutuante_dano(qtd_dano)


func _mostrar_texto_flutuante_cura(qtd: float) -> void:
	if not has_node("Control"): return
	var lbl = Label.new()
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.text = "+%d HP" % int(round(qtd))
	if _font_pixel:
		lbl.add_theme_font_override("font", _font_pixel)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	lbl.add_theme_color_override("font_outline_color", Color(0.04, 0.14, 0.04, 0.95))
	lbl.add_theme_constant_override("outline_size", 3)
	
	$Control.add_child(lbl)
	var start_pos = Vector2(130.0, 10.0)
	lbl.position = start_pos
	lbl.scale = Vector2(0.8, 0.8)
	lbl.modulate.a = 0.0
	lbl.pivot_offset = Vector2(30.0, 10.0)
	
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.parallel().tween_property(lbl, "position:y", start_pos.y - 18.0, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "scale", Vector2(1.15, 1.15), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 1.0, 0.12)
	tw.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.15)
	tw.tween_interval(0.35)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.25)
	tw.finished.connect(lbl.queue_free)


func _mostrar_texto_flutuante_dano(qtd: float) -> void:
	if not has_node("Control"): return
	var lbl = Label.new()
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.text = "-%d HP" % int(round(qtd))
	if _font_pixel:
		lbl.add_theme_font_override("font", _font_pixel)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	lbl.add_theme_color_override("font_outline_color", Color(0.18, 0.02, 0.02, 0.95))
	lbl.add_theme_constant_override("outline_size", 3)
	
	$Control.add_child(lbl)
	var start_pos = Vector2(130.0, 10.0)
	lbl.position = start_pos
	lbl.scale = Vector2(0.8, 0.8)
	lbl.modulate.a = 0.0
	lbl.pivot_offset = Vector2(30.0, 10.0)
	
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.parallel().tween_property(lbl, "position:y", start_pos.y - 16.0, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "scale", Vector2(1.2, 1.2), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 1.0, 0.10)
	tw.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.12)
	tw.tween_interval(0.30)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.25)
	tw.finished.connect(lbl.queue_free)


func _criar_indicador_dash() -> void:
	var parent_ctrl: Node = get_node_or_null("Control")
	if parent_ctrl == null:
		parent_ctrl = self
	if _dash_bar != null:
		return
		
	var container = PanelContainer.new()
	container.name = "DashContainer"
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.position = Vector2(58, 49)
	container.custom_minimum_size = Vector2(130, 15)
	
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.06, 0.08, 0.14, 0.85)
	sb_bg.border_color = Color(0.20, 0.40, 0.65, 0.70)
	sb_bg.set_border_width_all(1)
	sb_bg.set_corner_radius_all(3)
	container.add_theme_stylebox_override("panel", sb_bg)
	
	_dash_bar = ProgressBar.new()
	_dash_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dash_bar.show_percentage = false
	_dash_bar.min_value = 0.0
	_dash_bar.max_value = 1.0
	_dash_bar.value = 1.0
	_dash_bar.custom_minimum_size = Vector2(130, 15)
	
	var sb_fill = StyleBoxFlat.new()
	sb_fill.bg_color = Color(0.18, 0.82, 0.98, 0.90)
	sb_fill.set_corner_radius_all(2)
	_dash_bar.add_theme_stylebox_override("fill", sb_fill)
	
	var sb_empty = StyleBoxEmpty.new()
	_dash_bar.add_theme_stylebox_override("background", sb_empty)
	
	container.add_child(_dash_bar)
	
	_dash_label = Label.new()
	_dash_label.text = "⚡ DASH [ESPAÇO]"
	_dash_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dash_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_dash_label.custom_minimum_size = Vector2(130, 15)
	_dash_label.add_theme_font_size_override("font_size", 10)
	_dash_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.95))
	_dash_label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.08, 0.95))
	_dash_label.add_theme_constant_override("outline_size", 2)
	if _font_pixel:
		_dash_label.add_theme_font_override("font", _font_pixel)
		
	container.add_child(_dash_label)
	parent_ctrl.add_child(container)
	
	if get_node_or_null("/root/GlobalSignals"):
		GlobalSignals.dash_executado.connect(_on_dash_executado)

func _on_dash_executado(cooldown: float) -> void:
	if not _dash_bar or not is_instance_valid(_dash_bar):
		return
	if _dash_tween and _dash_tween.is_running():
		_dash_tween.kill()
		
	_dash_bar.value = 0.0
	if _dash_label:
		_dash_label.text = "RECARREGANDO..."
		_dash_label.add_theme_color_override("font_color", Color(0.7, 0.85, 0.95, 0.75))
		
	var sb_fill = _dash_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if sb_fill:
		sb_fill.bg_color = Color(0.15, 0.50, 0.75, 0.80)
		
	_dash_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_dash_tween.tween_property(_dash_bar, "value", 1.0, cooldown).set_trans(Tween.TRANS_LINEAR)
	_dash_tween.tween_callback(func():
		if _dash_label and is_instance_valid(_dash_label):
			_dash_label.text = "⚡ DASH [ESPAÇO]"
			_dash_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.95))
		var sb = _dash_bar.get_theme_stylebox("fill") as StyleBoxFlat
		if sb:
			sb.bg_color = Color(0.20, 0.95, 1.0, 0.95)
			
		var tw_brilho = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw_brilho.tween_property(_dash_bar, "modulate", Color(1.4, 1.5, 1.8), 0.12)
		tw_brilho.tween_property(_dash_bar, "modulate", Color.WHITE, 0.20)
	)


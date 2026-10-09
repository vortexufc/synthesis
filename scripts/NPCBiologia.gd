extends Area2D

# NPC de Biologia (Dra. Flora - Botânica Arcana)

@export_group("Visual")
# pose isometrica 3/4
@export var usar_angulo_isometrico: bool = false

var player_perto: bool = false
var ui_instancia = null

var _balao_interacao: Node2D = null
var _indicador_quest: Control = null
var _sprite: Sprite2D = null
var _tempo_anim: float = 0.0
var _base_balao_y: float = -142.0
var _base_quest_y: float = -145.0
var _curr_quest_y: float = -145.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	collision_layer = 0
	collision_mask = 15 # Pega o Player
	_sprite = get_node_or_null("Sprite2D")
	
	body_entered.connect(_quando_corpo_entra)
	body_exited.connect(_quando_corpo_sai)
	
	_criar_balao_e_indicadores()
	var ps = get_node_or_null("/root/PlayerStats")
	if ps:
		ps.quests_atualizadas.connect(_atualizar_indicador_quest)
	_atualizar_indicador_quest()

func _quando_corpo_entra(corpo: Node2D) -> void:
	if corpo.is_in_group("player") or corpo.name.begins_with("Player"):
		player_perto = true
		_mostrar_prompt()

func _quando_corpo_sai(corpo: Node2D) -> void:
	if corpo.is_in_group("player") or corpo.name.begins_with("Player"):
		player_perto = false
		_esconder_prompt()
		_fechar_interface()

func _unhandled_input(event: InputEvent) -> void:
	if player_perto and (event.is_action_pressed("interagir") or (event is InputEventKey and event.keycode == KEY_F and event.pressed)):
		get_viewport().set_input_as_handled()
		if ui_instancia == null or not is_instance_valid(ui_instancia):
			_abrir_interface()
		else:
			_fechar_interface()

func _abrir_interface() -> void:
	var script_ui = load("res://scripts/ui/quests_biologia.gd")
	if not script_ui: return
	
	ui_instancia = CanvasLayer.new()
	ui_instancia.set_script(script_ui)
	add_child(ui_instancia)
	_esconder_prompt()

func _fechar_interface() -> void:
	if ui_instancia and is_instance_valid(ui_instancia):
		ui_instancia.queue_free()
		ui_instancia = null
		if player_perto:
			_mostrar_prompt()

func _process(delta: float) -> void:
	_tempo_anim += delta
	var flutuacao = sin(_tempo_anim * 3.8) * 4.0
	
	if _sprite:
		_sprite.flip_h = false
		var frame_base = 2 if usar_angulo_isometrico else 0
		var total_frames = _sprite.hframes * _sprite.vframes
		_sprite.frame = (frame_base + (int(_tempo_anim * 2.0) % 2)) % max(1, total_frames)
	
	if _balao_interacao:
		_balao_interacao.position.y = _base_balao_y + flutuacao
		
	if _indicador_quest:
		var alvo_y = (_base_balao_y - 52.0) if player_perto else _base_quest_y
		_curr_quest_y = lerp(_curr_quest_y, alvo_y, delta * 12.0)
		_indicador_quest.position.y = _curr_quest_y + flutuacao
		var pulso = 1.0 + sin(_tempo_anim * 5.0) * 0.12
		_indicador_quest.scale = Vector2(pulso, pulso)

func _criar_balao_e_indicadores() -> void:
	# 1. Balão de interação flutuante [ F ] Falar
	_balao_interacao = Node2D.new()
	_balao_interacao.name = "BalaoInteracaoBio"
	_balao_interacao.position = Vector2(0, _base_balao_y)
	_balao_interacao.scale = Vector2.ZERO
	_balao_interacao.visible = false
	_balao_interacao.z_index = 25
	
	var panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.14, 0.09, 0.95)
	sb.border_color = Color(0.3, 0.85, 0.45, 1.0) # Verde Esmeralda Botânico
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", sb)
	
	var font = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	var lbl = Label.new()
	lbl.text = "💬 [ F ] Falar"
	if font: lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(lbl)
	
	panel.position = Vector2(-55, -15)
	_balao_interacao.add_child(panel)
	add_child(_balao_interacao)
	
	# 2. Indicador de Quest flutuante em balão de RPG (! ou ?)
	_indicador_quest = Control.new()
	_indicador_quest.name = "IndicadorQuestBio"
	_indicador_quest.z_index = 26
	_indicador_quest.custom_minimum_size = Vector2(34, 34)
	_indicador_quest.size = Vector2(34, 34)
	_indicador_quest.position = Vector2(-17, _base_quest_y)
	_indicador_quest.pivot_offset = Vector2(17, 17)
	
	var painel_badge = PanelContainer.new()
	painel_badge.name = "PainelBadge"
	painel_badge.custom_minimum_size = Vector2(34, 34)
	painel_badge.size = Vector2(34, 34)
	_indicador_quest.add_child(painel_badge)
	
	var lbl_badge = Label.new()
	lbl_badge.name = "LblBadge"
	if font: lbl_badge.add_theme_font_override("font", font)
	lbl_badge.add_theme_font_size_override("font_size", 22)
	lbl_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	painel_badge.add_child(lbl_badge)
	
	var rabicho = ColorRect.new()
	rabicho.name = "Rabicho"
	rabicho.size = Vector2(8, 8)
	rabicho.position = Vector2(13, 27)
	rabicho.rotation = deg_to_rad(45.0)
	_indicador_quest.add_child(rabicho)
	
	add_child(_indicador_quest)

func _atualizar_indicador_quest() -> void:
	if _indicador_quest == null: return
	var ps = get_node_or_null("/root/PlayerStats")
	if not ps: return
	
	var q1_conc = ps.quests_concluidas.get("biologia_quest1", false)
	var q2_conc = ps.quests_concluidas.get("biologia_quest2", false)
	var q1_ativa = ps.quests_ativas.get("biologia_quest1", false)
	var q2_ativa = ps.quests_ativas.get("biologia_quest2", false)
	
	var tem_flores = _contar_item("Flor Rara") >= 5
	var tem_dna = _contar_item("Chip de DNA") >= 5
	
	var painel = _indicador_quest.get_node_or_null("PainelBadge") as PanelContainer
	var lbl = _indicador_quest.get_node_or_null("PainelBadge/LblBadge") as Label
	var rabicho = _indicador_quest.get_node_or_null("Rabicho") as ColorRect
	
	var sb = StyleBoxFlat.new()
	sb.set_corner_radius_all(17)
	sb.set_border_width_all(2)
	sb.shadow_size = 6
	
	# Se tiver itens suficientes para entregar uma quest ativa: "?"
	if (q1_ativa and not q1_conc and tem_flores) or (q2_ativa and not q2_conc and tem_dna):
		sb.bg_color = Color(0.04, 0.16, 0.08, 0.95)
		sb.border_color = Color(0.3, 1.0, 0.55, 1.0)
		sb.shadow_color = Color(0.1, 0.6, 0.3, 0.5)
		if lbl:
			lbl.text = "?"
			lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.65))
			lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.25, 0.1, 0.9))
			lbl.add_theme_constant_override("outline_size", 3)
		if rabicho:
			rabicho.color = Color(0.3, 1.0, 0.55)
		if painel: painel.add_theme_stylebox_override("panel", sb)
		_indicador_quest.show()
	# Se tiver missões disponíveis para aceitar: "!"
	elif (not q1_conc and not q1_ativa) or (not q2_conc and not q2_ativa):
		sb.bg_color = Color(0.16, 0.12, 0.03, 0.95)
		sb.border_color = Color(1.0, 0.85, 0.2, 1.0)
		sb.shadow_color = Color(0.8, 0.6, 0.1, 0.5)
		if lbl:
			lbl.text = "!"
			lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
			lbl.add_theme_color_override("font_outline_color", Color(0.3, 0.18, 0.02, 0.9))
			lbl.add_theme_constant_override("outline_size", 3)
		if rabicho:
			rabicho.color = Color(1.0, 0.85, 0.2)
		if painel: painel.add_theme_stylebox_override("panel", sb)
		_indicador_quest.show()
	else:
		_indicador_quest.hide()

func _contar_item(nome_item: String) -> int:
	var total = 0
	if not get_node_or_null("/root/PlayerStats"): return 0
	for item in PlayerStats.itens:
		var nome_it = item.get("nome", "")
		if nome_it == nome_item:
			total += 1
	return total

func _mostrar_prompt() -> void:
	if _balao_interacao:
		_balao_interacao.visible = true
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(_balao_interacao, "scale", Vector2(1.0, 1.0), 0.22)
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui-1")

func _esconder_prompt() -> void:
	if _balao_interacao:
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(_balao_interacao, "scale", Vector2.ZERO, 0.16)
		tw.tween_callback(func(): _balao_interacao.visible = false)

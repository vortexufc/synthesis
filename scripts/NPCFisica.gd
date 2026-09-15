extends Area2D

var player_perto: bool = false
var ui_instancia = null

func _quando_corpo_entra(corpo: Node2D) -> void:
	if corpo.is_in_group("player") or corpo.name.begins_with("Player"):
		player_perto = true
		_mostrar_prompt()

func _quando_corpo_sai(corpo: Node2D) -> void:
	if corpo.is_in_group("player") or corpo.name.begins_with("Player"):
		player_perto = false
		_esconder_prompt()
		_fechar_interface()

var _balao_interacao: Node2D = null
var _indicador_quest: Label = null
var _sprite: Sprite2D = null
var _tempo_anim: float = 0.0
var _base_balao_y: float = -110.0
var _base_quest_y: float = -130.0
var _curr_quest_y: float = -130.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	collision_layer = 0
	collision_mask = 15 # Pega o player
	_sprite = get_node_or_null("Sprite2D")
	
	body_entered.connect(_quando_corpo_entra)
	body_exited.connect(_quando_corpo_sai)
	
	_criar_balao_e_indicadores()
	PlayerStats.quests_atualizadas.connect(_atualizar_indicador_quest)
	_atualizar_indicador_quest()

func _process(delta: float) -> void:
	_tempo_anim += delta
	var flutuacao = sin(_tempo_anim * 3.8) * 4.0
	
	if _sprite and _sprite.hframes > 1:
		_sprite.frame = int(_tempo_anim * 2.0) % _sprite.hframes
	
	if _balao_interacao:
		_balao_interacao.position.y = _base_balao_y + flutuacao
		
	if _indicador_quest:
		var alvo_y = (_base_balao_y - 52.0) if player_perto else _base_quest_y
		_curr_quest_y = lerp(_curr_quest_y, alvo_y, delta * 12.0)
		_indicador_quest.position.y = _curr_quest_y + flutuacao
		var pulso = 1.0 + sin(_tempo_anim * 5.0) * 0.12
		_indicador_quest.scale = Vector2(pulso, pulso)

func _criar_balao_e_indicadores() -> void:
	# 1. Balão de Interação Flutuante [ F ] Falar
	_balao_interacao = Node2D.new()
	_balao_interacao.name = "BalaoInteracaoFisica"
	_balao_interacao.position = Vector2(0, _base_balao_y)
	_balao_interacao.scale = Vector2.ZERO
	_balao_interacao.visible = false
	_balao_interacao.z_index = 25
	
	var panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.14, 0.95)
	sb.border_color = Color(1.0, 0.65, 0.2, 1.0) # Laranja Elétrico Engenheiro
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
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 5
	panel.add_theme_stylebox_override("panel", sb)
	
	var lbl = Label.new()
	lbl.text = "💬 [ F ] Falar"
	var font = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	if font: lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(lbl)
	
	panel.position = Vector2(-55, -15)
	_balao_interacao.add_child(panel)
	add_child(_balao_interacao)
	
	# 2. Indicador de Quest flutuante acima da cabeça (! ou ?)
	_indicador_quest = Label.new()
	_indicador_quest.name = "IndicadorQuestFisica"
	_indicador_quest.z_index = 26
	_indicador_quest.custom_minimum_size = Vector2(40, 32)
	if font: _indicador_quest.add_theme_font_override("font", font)
	_indicador_quest.add_theme_font_size_override("font_size", 24)
	_indicador_quest.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_indicador_quest.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_indicador_quest.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_indicador_quest.position = Vector2(-20, _base_quest_y)
	_indicador_quest.pivot_offset = Vector2(20, 16)
	add_child(_indicador_quest)

func _atualizar_indicador_quest() -> void:
	if _indicador_quest == null: return
	
	var q1_conc = PlayerStats.quests_concluidas.get("fisica_quest1", false)
	var q2_conc = PlayerStats.quests_concluidas.get("fisica_quest2", false)
	var q1_ativa = PlayerStats.quests_ativas.get("fisica_quest1", false)
	var q2_ativa = PlayerStats.quests_ativas.get("fisica_quest2", false)
	
	var tem_baterias = _contar_item("Bateria Elétrica") >= 5
	var tem_chips = _contar_item("Fragmento de Chip") >= 5
	
	# Se tiver itens suficientes para entregar uma quest ativa: "?"
	if (q1_ativa and not q1_conc and tem_baterias) or (q2_ativa and not q2_conc and tem_chips):
		_indicador_quest.text = "?"
		_indicador_quest.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		_indicador_quest.show()
	# Se tiver missões disponíveis para aceitar: "!"
	elif (not q1_conc and not q1_ativa) or (not q2_conc and not q2_ativa):
		_indicador_quest.text = "!"
		_indicador_quest.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		_indicador_quest.show()
	else:
		_indicador_quest.hide()

func _contar_item(nome_item: String) -> int:
	var total = 0
	for item in PlayerStats.itens:
		if item.get("nome") == nome_item: total += 1
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

func _unhandled_input(event: InputEvent) -> void:
	if player_perto and (event.is_action_pressed("interagir") or (event is InputEventKey and event.keycode == KEY_F and event.pressed)):
		get_viewport().set_input_as_handled()
		if ui_instancia == null or not is_instance_valid(ui_instancia):
			_abrir_interface()
		else:
			_fechar_interface()

func _abrir_interface() -> void:
	_esconder_prompt()
	var cena_ui = load("res://scripts/ui/quests_fisica.gd")
	if cena_ui:
		ui_instancia = CanvasLayer.new()
		ui_instancia.set_script(cena_ui)
		add_child(ui_instancia)

func _fechar_interface() -> void:
	if ui_instancia:
		ui_instancia.queue_free()
		ui_instancia = null
		if player_perto:
			_mostrar_prompt()

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
		_fechar_loja()


var _balao_interacao: Node2D = null
var _indicador_loja: Control = null
var _tempo_anim: float = 0.0
var _base_balao_y: float = -95.0
var _base_icone_y: float = -115.0
var _curr_icone_y: float = -115.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	collision_layer = 0
	collision_mask = 15 # Pega o player
	
	body_entered.connect(_quando_corpo_entra)
	body_exited.connect(_quando_corpo_sai)
	
	_criar_balao_e_indicadores()

func _process(delta: float) -> void:
	_tempo_anim += delta
	var flutuacao = sin(_tempo_anim * 3.6) * 3.8
	
	if _balao_interacao:
		_balao_interacao.position.y = _base_balao_y + flutuacao
		
	if _indicador_loja:
		var alvo_y = (_base_balao_y - 50.0) if player_perto else _base_icone_y
		_curr_icone_y = lerp(_curr_icone_y, alvo_y, delta * 12.0)
		_indicador_loja.position.y = _curr_icone_y + flutuacao
		var pulso = 1.0 + sin(_tempo_anim * 4.5) * 0.1
		_indicador_loja.scale = Vector2(pulso, pulso)

func _criar_balao_e_indicadores() -> void:
	# 1. Balão de Interação Flutuante [ F ] Loja
	_balao_interacao = Node2D.new()
	_balao_interacao.name = "BalaoInteracaoMercador"
	_balao_interacao.position = Vector2(0, _base_balao_y)
	_balao_interacao.scale = Vector2.ZERO
	_balao_interacao.visible = false
	_balao_interacao.z_index = 25
	
	var panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.14, 0.95)
	sb.border_color = Color(1.0, 0.85, 0.3, 1.0) # Dourado Mercador
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
	lbl.text = "💰 [ F ] Loja"
	var font = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	if font: lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.5))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(lbl)
	
	panel.position = Vector2(-55, -15)
	_balao_interacao.add_child(panel)
	add_child(_balao_interacao)
	
	# 2. Ícone flutuante de Moeda acima do Mercador (Emoji 🪙)
	_indicador_loja = Label.new()
	_indicador_loja.name = "IndicadorLoja"
	_indicador_loja.z_index = 26
	_indicador_loja.custom_minimum_size = Vector2(40, 32)
	if font: _indicador_loja.add_theme_font_override("font", font)
	_indicador_loja.add_theme_font_size_override("font_size", 22)
	_indicador_loja.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_indicador_loja.text = "🪙"
	_indicador_loja.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_indicador_loja.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_indicador_loja.position = Vector2(-20, _base_icone_y)
	_indicador_loja.pivot_offset = Vector2(20, 16)
	add_child(_indicador_loja)

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
			_abrir_loja()
		else:
			_fechar_loja()

func _abrir_loja() -> void:
	var script_loja = load("res://scripts/ui/loja_mercador.gd")
	if not script_loja: return
	
	ui_instancia = CanvasLayer.new()
	ui_instancia.set_script(script_loja)
	add_child(ui_instancia)
	_esconder_prompt()

func _fechar_loja() -> void:
	if ui_instancia and is_instance_valid(ui_instancia):
		ui_instancia.queue_free()
		ui_instancia = null
		if player_perto:
			_mostrar_prompt()

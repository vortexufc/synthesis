extends Area2D

## NPC da Biologia (Botânica e Bióloga Arcana)
## Fica localizada na sala de teste enquanto o andar de Biologia está em desenvolvimento.

@export_group("Visual")
## Quando ativado, o NPC fica na pose lateralizada (isométrica 3/4)
@export var usar_angulo_isometrico: bool = false

var player_perto: bool = false
var ui_instancia: CanvasLayer = null

var _balao_interacao: Node2D = null
var _indicador_quest: Label = null
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
	
	_criar_balao()

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
	if ui_instancia and is_instance_valid(ui_instancia):
		if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.keycode == KEY_F)):
			get_viewport().set_input_as_handled()
			_fechar_interface()
			return

	if player_perto and (event.is_action_pressed("interagir") or (event is InputEventKey and event.keycode == KEY_F and event.pressed)):
		get_viewport().set_input_as_handled()
		if ui_instancia == null or not is_instance_valid(ui_instancia):
			_abrir_interface()
		else:
			_fechar_interface()

func _exit_tree() -> void:
	_fechar_interface()

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

func _criar_balao() -> void:
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
	
	# 2. Indicador de Interação/Quest flutuante acima da cabeça (!)
	_indicador_quest = Label.new()
	_indicador_quest.name = "IndicadorQuestBio"
	_indicador_quest.z_index = 26
	_indicador_quest.custom_minimum_size = Vector2(40, 32)
	if font: _indicador_quest.add_theme_font_override("font", font)
	_indicador_quest.add_theme_font_size_override("font_size", 24)
	_indicador_quest.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_indicador_quest.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_indicador_quest.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_indicador_quest.position = Vector2(-20, _base_quest_y)
	_indicador_quest.pivot_offset = Vector2(20, 16)
	_indicador_quest.text = "!"
	add_child(_indicador_quest)

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

func _abrir_interface() -> void:
	_esconder_prompt()
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.travado = true
		player.em_interacao = true

	ui_instancia = CanvasLayer.new()
	ui_instancia.name = "DialogoBiologia"
	ui_instancia.add_to_group("dialogo_ativo")
	add_child(ui_instancia)
	
	# Fundo escurecido
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.65)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_instancia.add_child(bg)
	
	# Painel do Diálogo
	var panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.11, 0.08, 0.96)
	sb.border_color = Color(0.35, 0.9, 0.45, 1.0)
	sb.border_width_left = 3
	sb.border_width_right = 3
	sb.border_width_top = 3
	sb.border_width_bottom = 3
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	sb.shadow_color = Color(0, 0, 0, 0.7)
	sb.shadow_size = 12
	panel.add_theme_stylebox_override("panel", sb)
	
	panel.custom_minimum_size = Vector2(520, 260)
	var vp = get_viewport().get_visible_rect().size
	panel.position = (vp - panel.custom_minimum_size) * 0.5
	panel.pivot_offset = panel.custom_minimum_size * 0.5
	ui_instancia.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)
	
	# Fontes normais e legíveis
	var font_normal = SystemFont.new()
	font_normal.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	
	var font_bold = SystemFont.new()
	font_bold.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_bold.font_weight = 700
	
	# Cabeçalho (sem emoji de planta)
	var lbl_titulo = Label.new()
	lbl_titulo.text = "Dra. Flora - Botânica & Bióloga Arcana"
	lbl_titulo.add_theme_font_override("font", font_bold)
	lbl_titulo.add_theme_font_size_override("font_size", 19)
	lbl_titulo.add_theme_color_override("font_color", Color(0.45, 1.0, 0.6))
	vbox.add_child(lbl_titulo)
	
	# Divisória visual
	var hline = ColorRect.new()
	hline.custom_minimum_size = Vector2(0, 2)
	hline.color = Color(0.3, 0.7, 0.4, 0.5)
	vbox.add_child(hline)
	
	# Texto de lore / introdução
	var lbl_msg = RichTextLabel.new()
	lbl_msg.bbcode_enabled = true
	lbl_msg.text = "[color=#d8f5dc]\"Saudações, nobre Mago! Estou analisando os espécimes celulares e esporos vegetais da masmorra.\n\nO [color=#55ff88][b]Andar de Biologia[/b][/color] ainda está sendo feito, em breve trarei missões.\"[/color]"
	lbl_msg.custom_minimum_size = Vector2(460, 110)
	lbl_msg.add_theme_font_override("normal_font", font_normal)
	lbl_msg.add_theme_font_override("bold_font", font_bold)
	lbl_msg.add_theme_font_size_override("normal_font_size", 16)
	lbl_msg.add_theme_font_size_override("bold_font_size", 16)
	vbox.add_child(lbl_msg)
	
	# Botão fechar
	var hbox_btn = HBoxContainer.new()
	hbox_btn.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(hbox_btn)
	
	var btn_fechar = Button.new()
	btn_fechar.text = "Fechar (Esc / F)"
	btn_fechar.custom_minimum_size = Vector2(160, 36)
	btn_fechar.add_theme_font_override("font", font_bold)
	btn_fechar.add_theme_font_size_override("font_size", 14)
	
	var sb_btn = StyleBoxFlat.new()
	sb_btn.bg_color = Color(0.15, 0.28, 0.18, 1.0)
	sb_btn.border_color = Color(0.4, 0.9, 0.5, 1.0)
	sb_btn.set_border_width_all(1)
	sb_btn.set_corner_radius_all(6)
	sb_btn.content_margin_left = 12
	sb_btn.content_margin_right = 12
	btn_fechar.add_theme_stylebox_override("normal", sb_btn)
	
	var sb_btn_h = sb_btn.duplicate()
	sb_btn_h.bg_color = Color(0.22, 0.42, 0.26, 1.0)
	btn_fechar.add_theme_stylebox_override("hover", sb_btn_h)
	
	btn_fechar.pressed.connect(_fechar_interface)
	hbox_btn.add_child(btn_fechar)
	
	# Animação de abertura suave
	panel.scale = Vector2(0.85, 0.85)
	panel.modulate.a = 0.0
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.22)
	tw.tween_property(panel, "modulate:a", 1.0, 0.18)
	
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui-1")

func _fechar_interface() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_method("finalizar_interacao"):
			player.finalizar_interacao(0.6)
		else:
			player.travado = false
			player.em_interacao = false
			
	if ui_instancia and is_instance_valid(ui_instancia):
		ui_instancia.queue_free()
		ui_instancia = null
		if player_perto:
			_mostrar_prompt()

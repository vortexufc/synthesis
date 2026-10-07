extends Area2D

# Frasco Instável (Armadilha de poção falsa no chão que causa dano ao pisar ou inspecionar)

@export var dano: float = 25.0
@export var raio_detonacao_passo: float = 24.0

var id_unico: String = ""
var _player_perto: Node2D = null
var _canvas_prompt: CanvasLayer = null
var _detonado: bool = false
var _shadow: Sprite2D = null

@onready var sprite_frasco: Sprite2D = $SpriteFrasco
@onready var aura_brilho: Sprite2D = $AuraBrilho
@onready var particulas_explosao: CPUParticles2D = $ParticulasExplosao

func _obter_id_unico() -> String:
	if id_unico != "":
		return id_unico
	var cena_path = ""
	if get_tree() and get_tree().current_scene:
		cena_path = get_tree().current_scene.scene_file_path
	var pos_str = "%d_%d" % [int(global_position.x), int(global_position.y)]
	var pai_nome = get_parent().name if get_parent() else ""
	return "%s::%s/%s@%s" % [cena_path, pai_nome, name, pos_str]

func _ready() -> void:
	if id_unico == "":
		id_unico = _obter_id_unico()
	if get_node_or_null("/root/PlayerStats") and PlayerStats.is_item_coletado(id_unico):
		queue_free()
		return

	z_index = 2
	collision_layer = 0
	collision_mask = 15 # player
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	_criar_sombra()
	_gerar_aura_instavel()

func _exit_tree() -> void:
	_remover_prompt()

func _criar_sombra() -> void:
	if _shadow != null: return
	_shadow = Sprite2D.new()
	_shadow.name = "Shadow"
	var tex_shadow = load("res://assets/sprites/Characters/Maguinho/shadow.png") as Texture2D
	if tex_shadow:
		_shadow.texture = tex_shadow
		_shadow.position = Vector2(0, 18)
		_shadow.scale = Vector2(0.9, 0.5)
		_shadow.modulate = Color(0.0, 0.0, 0.0, 0.65)
		_shadow.z_as_relative = false
		_shadow.z_index = 1
		add_child(_shadow)
		move_child(_shadow, 0)

func _gerar_aura_instavel() -> void:
	if aura_brilho and not aura_brilho.texture:
		var grad = Gradient.new()
		grad.colors = PackedColorArray([
			Color(1.0, 0.40, 0.15, 0.75),
			Color(0.9, 0.15, 0.25, 0.45),
			Color(0.0, 0.0, 0.0, 0.0)
		])
		grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
		
		var tex = GradientTexture2D.new()
		tex.gradient = grad
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(0.5, 0.0)
		tex.width = 54
		tex.height = 54
		aura_brilho.texture = tex
		
	if aura_brilho:
		# Aura pulsando de calor químico instável
		var tw = create_tween().set_loops()
		tw.tween_property(aura_brilho, "scale", Vector2(1.35, 1.35), 0.45).set_trans(Tween.TRANS_SINE)
		tw.tween_property(aura_brilho, "scale", Vector2(0.85, 0.85), 0.45).set_trans(Tween.TRANS_SINE)
		
	if sprite_frasco:
		# Frasco tremendo sutilmente (indício visual da armadilha para o jogador atento)
		var tw_f = create_tween().set_loops()
		tw_f.tween_property(sprite_frasco, "rotation", 0.09, 0.18)
		tw_f.tween_property(sprite_frasco, "rotation", -0.09, 0.18)
		tw_f.tween_property(sprite_frasco, "rotation", 0.0, 0.08)

func _physics_process(_delta: float) -> void:
	if _detonado or not _player_perto or not is_instance_valid(_player_perto):
		return
	
	# Se o jogador pisar diretamente em cima da poção no chão, detona na hora!
	var dist = global_position.distance_to(_player_perto.global_position)
	if dist <= raio_detonacao_passo:
		detonar_reagente()

func _on_body_entered(body: Node2D) -> void:
	if _detonado: return
	if body.is_in_group("player") or body.name == "Player":
		_player_perto = body
		# Verifica se já entrou muito perto (pisando)
		var dist = global_position.distance_to(body.global_position)
		if dist <= raio_detonacao_passo:
			detonar_reagente()
		else:
			_exibir_prompt()

func _on_body_exited(body: Node2D) -> void:
	if body == _player_perto:
		_player_perto = null
		_remover_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if _detonado or not _player_perto: return
	
	var apertou_f = (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F)
	if apertou_f or event.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled()
		detonar_reagente()

func detonar_reagente() -> void:
	if _detonado: return
	_detonado = true
	_remover_prompt()
	
	if get_node_or_null("/root/PlayerStats") and id_unico != "":
		PlayerStats.registrar_item_coletado(id_unico)
		PlayerStats.salvar()
	
	# Esconde o frasco e a aura
	if sprite_frasco: sprite_frasco.visible = false
	if aura_brilho: aura_brilho.visible = false
	if _shadow: _shadow.visible = false
	
	# Efeito de explosão química
	if particulas_explosao:
		particulas_explosao.restart()
		particulas_explosao.emitting = true
		
	# Tira vida do jogador e treme a tela
	var player = _player_perto
	if player and is_instance_valid(player):
		if player.has_method("receber_dano"):
			player.receber_dano(dano, 14.0, "Reação Exotérmica")
		elif get_node_or_null("/root/PlayerStats"):
			PlayerStats.sofrer_dano(dano)
			
		if player.has_method("aplicar_shake"):
			player.aplicar_shake(14.0, 0.35)
			
		_flash_vermelho(player)
		_exibir_texto_dano(dano)
			
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui-2")
		AudioManager.tocar_som_dano()
		
	# Popup informativo avisando da armadilha
	_exibir_modal_aviso_explosao()

func _flash_vermelho(player: Node2D) -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 105
	var rect := ColorRect.new()
	rect.color = Color(1.0, 0.15, 0.1, 0.0)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(rect)
	player.add_child(canvas)

	var tween = create_tween()
	tween.tween_property(rect, "color", Color(1.0, 0.15, 0.1, 0.40), 0.08)
	tween.tween_property(rect, "color", Color(1.0, 0.15, 0.1, 0.0), 0.32)
	await tween.finished
	if is_instance_valid(canvas):
		canvas.queue_free()

func _exibir_texto_dano(valor: float) -> void:
	var lbl = Label.new()
	lbl.text = "-%.0f HP 💥 (Frasco Instável)" % valor
	lbl.z_index = 25
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	lbl.add_theme_color_override("font_outline_color", Color(0.25, 0.05, 0.05, 0.95))
	lbl.add_theme_constant_override("outline_size", 3)
	
	var font_pixel = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	if font_pixel:
		lbl.add_theme_font_override("font", font_pixel)
		
	var arvore = get_tree()
	var cena_alvo = arvore.current_scene if (arvore and arvore.current_scene) else get_parent()
	if cena_alvo:
		cena_alvo.add_child(lbl)
	else:
		get_tree().root.add_child(lbl)
		
	lbl.global_position = global_position + Vector2(-60, -32)
	
	var tw = lbl.create_tween().set_parallel(true)
	tw.tween_property(lbl, "global_position:y", lbl.global_position.y - 32.0, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.25).set_delay(0.50)
	tw.chain().tween_callback(lbl.queue_free)

func _exibir_prompt() -> void:
	if _canvas_prompt and is_instance_valid(_canvas_prompt): return
	_canvas_prompt = CanvasLayer.new()
	add_child(_canvas_prompt)
	
	var panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.08, 0.08, 0.92)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(10)
	sb.border_color = Color(1.0, 0.45, 0.2, 0.95)
	sb.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", sb)
	
	var lbl = Label.new()
	lbl.text = "⚠️ [F] Inspecionar Frasco de Poção"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var font_prompt = SystemFont.new()
	font_prompt.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_prompt.font_weight = 600
	lbl.add_theme_font_override("font", font_prompt)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	
	panel.add_child(lbl)
	panel.custom_minimum_size = Vector2(400, 46)
	_canvas_prompt.add_child(panel)
	
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -125
	panel.offset_bottom = -79
	panel.offset_left = 340
	panel.offset_right = -340

func _remover_prompt() -> void:
	if _canvas_prompt and is_instance_valid(_canvas_prompt):
		_canvas_prompt.queue_free()
		_canvas_prompt = null

func _exibir_modal_aviso_explosao() -> void:
	var canvas_aviso = CanvasLayer.new()
	canvas_aviso.layer = 106
	canvas_aviso.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(canvas_aviso)
	
	var font_titulo = SystemFont.new()
	font_titulo.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_titulo.font_weight = 700

	var font_sans = SystemFont.new()
	font_sans.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_sans.font_weight = 500

	var font_bold = SystemFont.new()
	font_bold.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_bold.font_weight = 600

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(580, 150)
	var vp = get_viewport_rect().size
	panel.position = (vp - Vector2(580, 150)) * 0.5
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.14, 0.05, 0.05, 0.97)
	sb.border_color = Color(1.0, 0.3, 0.3, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(16)
	sb.shadow_color = Color(0, 0, 0, 0.75)
	sb.shadow_size = 12
	panel.add_theme_stylebox_override("panel", sb)
	canvas_aviso.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	
	# Top bar com título e botão X
	var hbox_top = HBoxContainer.new()
	vbox.add_child(hbox_top)
	
	var lbl_titulo = Label.new()
	lbl_titulo.text = "⚠️ REAÇÃO EXOTÉRMICA VIOLENTA! ⚠️"
	lbl_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_titulo.add_theme_font_override("font", font_titulo)
	lbl_titulo.add_theme_font_size_override("font_size", 16)
	lbl_titulo.add_theme_color_override("font_color", Color(1.0, 0.38, 0.38))
	hbox_top.add_child(lbl_titulo)
	
	var btn_x = Button.new()
	btn_x.text = "✕"
	btn_x.custom_minimum_size = Vector2(28, 28)
	btn_x.add_theme_font_override("font", font_bold)
	btn_x.add_theme_font_size_override("font_size", 14)
	btn_x.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	
	var sb_btn = StyleBoxFlat.new()
	sb_btn.bg_color = Color(0.35, 0.1, 0.1)
	sb_btn.set_corner_radius_all(4)
	btn_x.add_theme_stylebox_override("normal", sb_btn)
	var sb_btn_h = sb_btn.duplicate()
	sb_btn_h.bg_color = Color(0.75, 0.15, 0.15)
	btn_x.add_theme_stylebox_override("hover", sb_btn_h)
	btn_x.add_theme_stylebox_override("pressed", sb_btn_h)
	
	var fechou: Array = [false]
	var fechar_modal = func():
		if fechou[0]: return
		fechou[0] = true
		if is_instance_valid(panel):
			var tw_out = panel.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			tw_out.tween_property(panel, "modulate:a", 0.0, 0.18)
			tw_out.tween_property(panel, "scale", Vector2(0.85, 0.85), 0.18)
			await tw_out.finished
		if is_instance_valid(canvas_aviso):
			canvas_aviso.queue_free()
		queue_free()
		
	btn_x.pressed.connect(fechar_modal)
	hbox_top.add_child(btn_x)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	var lbl_desc = Label.new()
	lbl_desc.text = "O frasco não continha um elixir estável!\nReagentes voláteis detonaram ao menor contato térmico, causando -%.0f HP!" % dano
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_desc.add_theme_font_override("font", font_sans)
	lbl_desc.add_theme_font_size_override("font_size", 14)
	lbl_desc.add_theme_color_override("font_color", Color(0.96, 0.92, 0.92))
	vbox.add_child(lbl_desc)
	
	var lbl_dica = Label.new()
	lbl_dica.text = "💡 DICA: Abra o Inventário [I] e tome uma Poção de Cura para se recuperar."
	lbl_dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_dica.add_theme_font_override("font", font_bold)
	lbl_dica.add_theme_font_size_override("font_size", 13)
	lbl_dica.add_theme_color_override("font_color", Color(0.35, 0.90, 1.0))
	vbox.add_child(lbl_dica)
	
	# Animação suave de entrada
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.85, 0.85)
	var tw = panel.create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.22)
	tw.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.22)
	
	# Fecha automaticamente após 2.2 segundos para não travar a exploração
	if get_tree():
		get_tree().create_timer(2.2).timeout.connect(fechar_modal)

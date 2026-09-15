extends Area2D

## [Armadilha Alquímica] Frasco de Reagente Instável
## Parece um frasco de poção inofensivo no chão, mas ao ser inspecionado com [F],
## detona uma reação exotérmica violenta causando -35 HP no jogador!

@export var dano: float = 35.0

var _player_perto: Node2D = null
var _canvas_prompt: CanvasLayer = null
var _detonado: bool = false

@onready var sprite_frasco: Sprite2D = $SpriteFrasco
@onready var aura_brilho: Sprite2D = $AuraBrilho
@onready var particulas_explosao: CPUParticles2D = $ParticulasExplosao

func _ready() -> void:
	collision_layer = 0
	collision_mask = 15
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	_gerar_aura_instavel()

func _exit_tree() -> void:
	_remover_prompt()

func _gerar_aura_instavel() -> void:
	if aura_brilho and not aura_brilho.texture:
		var grad = Gradient.new()
		grad.colors = PackedColorArray([
			Color(1.0, 0.45, 0.1, 0.75), # Laranja fogo reagente
			Color(0.9, 0.1, 0.3, 0.45), # Carmim instável
			Color(0.0, 0.0, 0.0, 0.0)
		])
		grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
		
		var tex = GradientTexture2D.new()
		tex.gradient = grad
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(0.5, 0.0)
		tex.width = 48
		tex.height = 48
		aura_brilho.texture = tex
		
	if aura_brilho:
		# Efeito de tremor/instabilidade térmica
		var tw = create_tween().set_loops()
		tw.tween_property(aura_brilho, "scale", Vector2(1.3, 1.3), 0.5).set_trans(Tween.TRANS_SINE)
		tw.tween_property(aura_brilho, "scale", Vector2(0.9, 0.9), 0.5).set_trans(Tween.TRANS_SINE)
		
	if sprite_frasco:
		# Leve jittering / tremidinha de substância volátil fervendo
		var tw_f = create_tween().set_loops()
		tw_f.tween_property(sprite_frasco, "rotation", 0.08, 0.25)
		tw_f.tween_property(sprite_frasco, "rotation", -0.08, 0.25)

func _on_body_entered(body: Node2D) -> void:
	if _detonado: return
	if body.is_in_group("player") or body.name == "Player":
		_player_perto = body
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
	
	# Esconde o frasco e a aura
	if sprite_frasco: sprite_frasco.visible = false
	if aura_brilho: aura_brilho.visible = false
	
	# 1. Partículas de explosão
	if particulas_explosao:
		particulas_explosao.restart()
		particulas_explosao.emitting = true
		
	# 2. Aplica dano ao jogador com shake violento
	if _player_perto and is_instance_valid(_player_perto):
		if _player_perto.has_method("receber_dano"):
			_player_perto.receber_dano(dano, 16.0, "Reação Exotérmica")
		elif get_node_or_null("/root/PlayerStats"):
			PlayerStats.sofrer_dano(dano)
			
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui-2")
		AudioManager.tocar_som_dano()
		
	# 3. Exibe o aviso explicativo na tela (estilo o Mímico)
	_exibir_modal_aviso_explosao()

func _exibir_prompt() -> void:
	if _canvas_prompt and is_instance_valid(_canvas_prompt): return
	_canvas_prompt = CanvasLayer.new()
	add_child(_canvas_prompt)
	
	var panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.08, 0.08, 0.92)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(10)
	sb.border_color = Color(1.0, 0.55, 0.2, 0.95)
	sb.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", sb)
	
	var lbl = Label.new()
	lbl.text = "Pressione [F] - Inspecionar Frasco Suspeito"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var font_prompt = SystemFont.new()
	font_prompt.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_prompt.font_weight = 600
	lbl.add_theme_font_override("font", font_prompt)
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	
	panel.add_child(lbl)
	panel.custom_minimum_size = Vector2(440, 50)
	_canvas_prompt.add_child(panel)
	
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -130
	panel.offset_bottom = -80
	panel.offset_left = 330
	panel.offset_right = -330

func _remover_prompt() -> void:
	if _canvas_prompt and is_instance_valid(_canvas_prompt):
		_canvas_prompt.queue_free()
		_canvas_prompt = null

func _exibir_modal_aviso_explosao() -> void:
	var canvas_aviso = CanvasLayer.new()
	canvas_aviso.layer = 106
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
	panel.custom_minimum_size = Vector2(580, 160)
	var vp = get_viewport_rect().size
	panel.position = (vp - Vector2(580, 160)) * 0.5
	
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
	vbox.add_theme_constant_override("separation", 10)
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
	btn_x.pressed.connect(func():
		canvas_aviso.queue_free()
		queue_free()
	)
	hbox_top.add_child(btn_x)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	var lbl_desc = Label.new()
	lbl_desc.text = "O frasco não continha um elixir seguro!\nReagentes alquímicos voláteis detonaram ao entrar em contato com o oxigênio causando -%.0f HP!" % dano
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_desc.add_theme_font_override("font", font_sans)
	lbl_desc.add_theme_font_size_override("font_size", 14)
	lbl_desc.add_theme_color_override("font_color", Color(0.96, 0.92, 0.92))
	vbox.add_child(lbl_desc)
	
	var lbl_dica = Label.new()
	lbl_dica.text = "💡 DICA: Abra o Inventário (I) e tome uma Poção de Cura para se recuperar."
	lbl_dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_dica.add_theme_font_override("font", font_bold)
	lbl_dica.add_theme_font_size_override("font_size", 13)
	lbl_dica.add_theme_color_override("font_color", Color(0.35, 0.90, 1.0))
	vbox.add_child(lbl_dica)

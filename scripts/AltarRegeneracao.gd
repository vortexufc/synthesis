extends Area2D

# Altar / Cristal de Regeneração do Hub
# A base de pedra rúnica fica fixa no solo, enquanto o cristal mágico levita continuamente.
# Ao interagir com [F], canaliza e restaura totalmente o HP do jogador.

@export var cor_luz: Color = Color(0.20, 0.95, 0.85, 1.0)
@export var energia_luz: float = 0.95

var player_perto: bool = false
var player_ref: Node2D = null
var canvas_prompt: CanvasLayer = null
var panel_prompt: PanelContainer = null
var label_prompt: Label = null

@onready var sprite_base: Sprite2D = get_node_or_null("SpriteBase")
@onready var sprite_cristal: Sprite2D = get_node_or_null("SpriteCristal")
@onready var luz_altar: PointLight2D = get_node_or_null("LuzAltar")
@onready var particulas_ambiente: CPUParticles2D = get_node_or_null("ParticulasAmbiente")

var _pos_cristal_base_y: float = -56.0
var _escala_cristal_base: Vector2 = Vector2(0.72, 0.72)
var _tempo_flutuacao: float = 0.0
var _tween_pulso_luz: Tween = null
var _em_canalizacao: bool = false

func _ready() -> void:
	y_sort_enabled = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if sprite_base:
		sprite_base.z_index = 0
	if sprite_cristal:
		sprite_cristal.z_index = 1
		sprite_cristal.z_as_relative = true
		_pos_cristal_base_y = sprite_cristal.position.y
		_escala_cristal_base = sprite_cristal.scale
		
	_configurar_luz_procedural()
	_animar_luz_idle()

func _process(delta: float) -> void:
	# A base de pedra permanece fixa no chão.
	# Somente o cristal flutua misticamente acima do receptáculo central.
	if sprite_cristal and not _em_canalizacao:
		_tempo_flutuacao += delta * 2.4
		var bob = sin(_tempo_flutuacao) * 5.0
		var wobble = sin(_tempo_flutuacao * 0.7) * 0.035
		var breath = 1.0 + sin(_tempo_flutuacao * 1.8) * 0.025
		
		sprite_cristal.position.y = _pos_cristal_base_y + bob
		sprite_cristal.rotation = wobble
		sprite_cristal.scale = _escala_cristal_base * breath

func _exit_tree() -> void:
	_remover_prompt_tela()
	if _tween_pulso_luz and _tween_pulso_luz.is_running():
		_tween_pulso_luz.kill()

func _configurar_luz_procedural() -> void:
	if luz_altar and not luz_altar.texture:
		var grad = Gradient.new()
		grad.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CUBIC
		grad.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
		grad.colors = PackedColorArray([
			Color(1, 1, 1, 1.0),
			Color(0.4, 0.95, 0.9, 0.45),
			Color(0, 0, 0, 0.0)
		])
		var tex = GradientTexture2D.new()
		tex.gradient = grad
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(0.5, 0.0)
		tex.width = 256
		tex.height = 256
		luz_altar.texture = tex
		luz_altar.color = cor_luz
		luz_altar.energy = energia_luz

func _animar_luz_idle() -> void:
	# Pulso suave de iluminação mística
	if luz_altar:
		_tween_pulso_luz = create_tween().set_loops()
		_tween_pulso_luz.tween_property(luz_altar, "energy", energia_luz * 1.25, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween_pulso_luz.tween_property(luz_altar, "energy", energia_luz * 0.75, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_body_entered(body: Node2D) -> void:
	if not (body.is_in_group("player") or body.name == "Player"):
		return
	player_perto = true
	player_ref = body
	_exibir_prompt_tela()

func _on_body_exited(body: Node2D) -> void:
	if body == player_ref or body.is_in_group("player") or body.name == "Player":
		player_perto = false
		player_ref = null
		_remover_prompt_tela()

func _exibir_prompt_tela() -> void:
	if canvas_prompt and is_instance_valid(canvas_prompt):
		return
		
	canvas_prompt = CanvasLayer.new()
	canvas_prompt.layer = 100
	canvas_prompt.name = "PromptAltarRegeneracao"
	add_child(canvas_prompt)
	
	panel_prompt = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.09, 0.14, 0.92)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	style.set_border_width_all(2)
	style.border_color = Color(0.25, 0.92, 0.85, 0.95) # Borda ciano esmeralda
	panel_prompt.add_theme_stylebox_override("panel", style)
	
	label_prompt = Label.new()
	var hp_atual = PlayerStats.vida_atual_jogador if get_node_or_null("/root/PlayerStats") else 100.0
	var hp_max = PlayerStats.vida_maxima_jogador if get_node_or_null("/root/PlayerStats") else 100.0
	
	if hp_atual < hp_max:
		label_prompt.text = "Pressione [F] para Orar e Restaurar sua Vida"
	else:
		label_prompt.text = "Cristal da Vida: Sua vida ja esta cheia!"
		
	label_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var font_pixel = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	if font_pixel:
		label_prompt.add_theme_font_override("font", font_pixel)
	label_prompt.add_theme_font_size_override("font_size", 15)
	label_prompt.add_theme_color_override("font_color", Color(0.95, 1.0, 1.0))
	label_prompt.add_theme_color_override("font_outline_color", Color(0.02, 0.05, 0.08, 0.95))
	label_prompt.add_theme_constant_override("outline_size", 2)
	
	panel_prompt.add_child(label_prompt)
	canvas_prompt.add_child(panel_prompt)
	
	panel_prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel_prompt.offset_top = -130
	panel_prompt.offset_bottom = -80
	panel_prompt.offset_left = 300
	panel_prompt.offset_right = -300

func _remover_prompt_tela() -> void:
	if canvas_prompt and is_instance_valid(canvas_prompt):
		canvas_prompt.queue_free()
		canvas_prompt = null
		panel_prompt = null
		label_prompt = null

func _unhandled_input(event: InputEvent) -> void:
	if not player_perto or _em_canalizacao:
		return
	if player_ref and is_instance_valid(player_ref) and player_ref.has_method("esta_em_interacao") and player_ref.esta_em_interacao():
		return
		
	var apertou_f = event.is_action_pressed("interagir") or (event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode == KEY_F or event.keycode == KEY_F))
	if apertou_f:
		_ativar_regeneracao()

func _ativar_regeneracao() -> void:
	if not get_node_or_null("/root/PlayerStats"):
		return
		
	var hp_atual = PlayerStats.vida_atual_jogador
	var hp_max = PlayerStats.vida_maxima_jogador
	
	if hp_atual >= hp_max:
		# Já está com a vida cheia! Feedback sonoro e visual sutil
		if label_prompt:
			label_prompt.text = "Sua vida ja esta cheia!"
			label_prompt.add_theme_color_override("font_color", Color(0.35, 1.0, 0.85))
			var tw_txt = create_tween()
			tw_txt.tween_interval(1.5)
			tw_txt.tween_callback(func():
				if label_prompt and is_instance_valid(label_prompt):
					label_prompt.text = "Cristal da Vida: Sua vida ja esta cheia!"
			)
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("ui_1")
		return
		
	_em_canalizacao = true
	
	# Restaura totalmente a vida do jogador
	var hp_restaurado = hp_max - hp_atual
	PlayerStats.resetar_vida()
	
	# Sons de cura sagrada
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("win")
		AudioManager.play_sfx("pocao_cura")
		
	# Efeito visual espetacular de levitação, pulso e cura
	_executar_efeito_cura(hp_restaurado)
	
	# Notificação no HUD
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("mostrar_notificacao_quest"):
		hud.mostrar_notificacao_quest(
			"VITALIDADE RESTAURADA!",
			"O Altar purificou suas feridas (+%.0f HP restaurados)!" % hp_restaurado,
			Color(0.20, 0.95, 0.80),
			"win"
		)
		
	if label_prompt:
		label_prompt.text = "Vida Plenamente Restaurada!"
		label_prompt.add_theme_color_override("font_color", Color(0.35, 1.0, 0.85))
		
	await get_tree().create_timer(1.2).timeout
	_em_canalizacao = false
	if player_perto:
		_exibir_prompt_tela()

func _executar_efeito_cura(qtd_cura: float) -> void:
	# Flash e expansão de luz no altar
	if luz_altar:
		var tw_luz = create_tween()
		tw_luz.tween_property(luz_altar, "energy", energia_luz * 2.6, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_luz.tween_property(luz_altar, "energy", energia_luz, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Animação especial do Cristal elevando-se mais alto e brilhando intensamente
	if sprite_cristal:
		var tw_cristal = create_tween().set_parallel(true)
		# Eleva 18px a mais temporariamente
		tw_cristal.tween_property(sprite_cristal, "position:y", _pos_cristal_base_y - 18.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_cristal.tween_property(sprite_cristal, "rotation", TAU, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_cristal.tween_property(sprite_cristal, "modulate", Color(2.0, 2.5, 2.5, 1.0), 0.25)
		
		# Retorna à altura e brilho normais
		tw_cristal.chain().tween_property(sprite_cristal, "position:y", _pos_cristal_base_y, 0.50).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw_cristal.parallel().tween_property(sprite_cristal, "rotation", 0.0, 0.40)
		tw_cristal.parallel().tween_property(sprite_cristal, "modulate", Color.WHITE, 0.50)

	# Explosão de partículas de cura ao redor do altar e do jogador
	var part = CPUParticles2D.new()
	part.global_position = global_position + Vector2(0, -35)
	part.emitting = true
	part.one_shot = true
	part.explosiveness = 0.85
	part.amount = 36
	part.lifetime = 1.1
	part.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	part.emission_sphere_radius = 40.0
	part.direction = Vector2(0, -1)
	part.spread = 180.0
	part.gravity = Vector2(0, -50)
	part.initial_velocity_min = 35.0
	part.initial_velocity_max = 95.0
	part.scale_amount_min = 1.6
	part.scale_amount_max = 3.4
	
	var grad = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.25, 0.75, 1.0])
	grad.colors = PackedColorArray([
		Color(0.2, 0.95, 0.85, 0.0),
		Color(0.3, 1.0, 0.85, 0.95),
		Color(0.9, 0.95, 0.4, 0.85),
		Color(1.0, 1.0, 1.0, 0.0)
	])
	part.color_ramp = grad
	
	get_parent().add_child(part)
	get_tree().create_timer(1.5, true, false, true).timeout.connect(func():
		if is_instance_valid(part):
			part.queue_free()
	)
	
	# Se o jogador estiver na área, solta partículas nele também
	if player_ref and is_instance_valid(player_ref):
		var part_player = CPUParticles2D.new()
		part_player.global_position = player_ref.global_position + Vector2(0, 10)
		part_player.emitting = true
		part_player.one_shot = true
		part_player.amount = 20
		part_player.lifetime = 0.85
		part_player.direction = Vector2(0, -1)
		part_player.spread = 45.0
		part_player.gravity = Vector2(0, -70)
		part_player.initial_velocity_min = 30.0
		part_player.initial_velocity_max = 75.0
		part_player.scale_amount_min = 1.4
		part_player.scale_amount_max = 2.6
		part_player.color_ramp = grad
		
		get_parent().add_child(part_player)
		get_tree().create_timer(1.2, true, false, true).timeout.connect(func():
			if is_instance_valid(part_player):
				part_player.queue_free()
		)
		
		# Texto flutuante verde de cura "+X HP"
		_exibir_texto_cura_jogador(player_ref, qtd_cura)

func _exibir_texto_cura_jogador(alvo: Node2D, qtd: float) -> void:
	var lbl = Label.new()
	lbl.text = "+%.0f HP (Altar)" % qtd
	lbl.z_index = 25
	lbl.global_position = alvo.global_position + Vector2(-60, -85)
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color(0.25, 1.0, 0.65))
	lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.12, 0.06, 0.95))
	lbl.add_theme_constant_override("outline_size", 3)
	
	var font_pixel = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	if font_pixel:
		lbl.add_theme_font_override("font", font_pixel)
		
	get_parent().add_child(lbl)
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 36.0, 0.95).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.95).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(lbl.queue_free)

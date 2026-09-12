extends Area2D

var coletavel = false
var _coletado = false

var _tween_brilho: Tween
var _tween_glow: Tween
var _tween_bob: Tween

func _ready() -> void:
	z_index = 2
	collision_layer = 0
	collision_mask = 15 # Pega o player
	body_entered.connect(_coletar)
	
	_iniciar_efeito_brilho()
	
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): coletavel = true)
	tween.tween_callback(_verificar_coleta_imediata)

func _iniciar_efeito_brilho() -> void:
	var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		for child in get_children():
			if child is Sprite2D and child.name != "GlowSprite":
				sprite = child as Sprite2D
				break
				
	# 1. Glow translúcido dourado atrás da moeda (idêntico ao pergaminho e chave)
	var glow: Sprite2D = get_node_or_null("GlowSprite") as Sprite2D
	if glow == null:
		glow = Sprite2D.new()
		glow.name = "GlowSprite"
		var tex_glow = load("res://assets/sprites/ui/glow_yellow.png") as Texture2D
		if tex_glow:
			glow.texture = tex_glow
			glow.scale = Vector2(0.32, 0.32) # Proporcional ao tamanho da moeda
			glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			add_child(glow)
			move_child(glow, 0)
			
	if glow:
		glow.modulate = Color(1.0, 0.88, 0.25, 0.5)
		_tween_glow = create_tween().set_loops()
		_tween_glow.tween_property(glow, "modulate:a", 0.85, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween_glow.tween_property(glow, "modulate:a", 0.35, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
	# 2. Pulsação de brilho e piscar dourado vivo na própria moeda
	if sprite:
		_tween_brilho = create_tween().set_loops()
		_tween_brilho.tween_property(sprite, "modulate", Color(1.7, 1.45, 0.35, 1.0), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween_brilho.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		# 3. Flutuação suave
		var pos_y = sprite.position.y
		_tween_bob = create_tween().set_loops()
		_tween_bob.tween_property(sprite, "position:y", pos_y - 5.0, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween_bob.tween_property(sprite, "position:y", pos_y + 5.0, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		# Sombra realista no chão acompanhando a flutuação
		_criar_sombra()
		if _shadow:
			var tw_s = create_tween().set_loops()
			tw_s.tween_property(_shadow, "scale", Vector2(1.30, 0.70), 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw_s.parallel().tween_property(_shadow, "modulate:a", 0.65, 0.85)
			tw_s.tween_property(_shadow, "scale", Vector2(1.65, 0.95), 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw_s.parallel().tween_property(_shadow, "modulate:a", 0.90, 0.85)

var _shadow: Sprite2D = null

func _criar_sombra() -> void:
	if _shadow == null:
		_shadow = get_node_or_null("Shadow") as Sprite2D
	if _shadow != null:
		_shadow.z_as_relative = false
		_shadow.z_index = 1
		return
	_shadow = Sprite2D.new()
	_shadow.name = "Shadow"
	var tex_shadow = load("res://assets/sprites/Characters/Maguinho/shadow.png") as Texture2D
	if tex_shadow:
		_shadow.texture = tex_shadow
		_shadow.position = Vector2(0, 44)
		_shadow.scale = Vector2(1.5, 0.85)
		_shadow.modulate = Color(1.0, 1.0, 1.0, 0.85)
		_shadow.z_as_relative = false
		_shadow.z_index = 1
		add_child(_shadow)
		move_child(_shadow, 0)

	# 4. Luz 2D ambiente para iluminar o chão da masmorra ao redor da moeda
	var luz: PointLight2D = get_node_or_null("LuzMoeda") as PointLight2D
	if luz == null:
		luz = PointLight2D.new()
		luz.name = "LuzMoeda"
		var tex_glow = load("res://assets/sprites/ui/glow_yellow.png") as Texture2D
		if tex_glow:
			luz.texture = tex_glow
			luz.texture_scale = 0.35
			luz.color = Color(1.0, 0.85, 0.35)
			luz.energy = 0.65
			add_child(luz)

func _verificar_coleta_imediata() -> void:
	for corpo in get_overlapping_bodies():
		if corpo.is_in_group("player") or corpo.name.begins_with("Player"):
			_coletar(corpo)
			break

func _coletar(corpo: Node2D) -> void:
	if not coletavel or _coletado:
		return
	if corpo.is_in_group("player") or corpo.name.begins_with("Player"):
		_coletado = true
		coletavel = false
		
		if get_node_or_null("/root/PlayerStats"):
			PlayerStats.moedas += randi_range(3, 5)
			PlayerStats.salvar()
			print("Pegou moedas! Total: ", PlayerStats.moedas)
			
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("moedas")
			
		if _tween_brilho and _tween_brilho.is_valid(): _tween_brilho.kill()
		if _tween_glow and _tween_glow.is_valid(): _tween_glow.kill()
		if _tween_bob and _tween_bob.is_valid(): _tween_bob.kill()
		
		# Efeito "Pop" com burst de partículas douradas brilhantes
		var part = CPUParticles2D.new()
		part.global_position = global_position
		part.z_index = 10 # Fica por cima de tudo
		
		var mat_p = CanvasItemMaterial.new()
		mat_p.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		part.material = mat_p
		
		var grad_tex = Gradient.new()
		grad_tex.offsets = PackedFloat32Array([0, 0.6, 1])
		grad_tex.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 0.9, 0.4, 0.9), Color(1, 0.6, 0.1, 0)])
		var tex_spark = GradientTexture2D.new()
		tex_spark.gradient = grad_tex
		tex_spark.width = 10
		tex_spark.height = 10
		tex_spark.fill = GradientTexture2D.FILL_RADIAL
		tex_spark.fill_from = Vector2(0.5, 0.5)
		tex_spark.fill_to = Vector2(0.5, 0)
		part.texture = tex_spark
		
		part.amount = 14
		part.lifetime = 0.55
		part.one_shot = true
		part.explosiveness = 0.9
		part.direction = Vector2(0, -1)
		part.spread = 180.0
		part.gravity = Vector2(0, 45)
		part.initial_velocity_min = 40.0
		part.initial_velocity_max = 85.0
		part.scale_amount_min = 0.6
		part.scale_amount_max = 1.3
		var grad = Gradient.new()
		grad.colors = PackedColorArray([Color(1.0, 0.98, 0.5, 1.0), Color(1.0, 0.5, 0.05, 0.0)])
		part.color_ramp = grad
		get_parent().add_child(part)
		part.emitting = true
		get_tree().create_timer(0.65).timeout.connect(part.queue_free)
		
		# Animação clara e visível de salto (Hop & Pop)
		var tween_coleta = create_tween()
		# 1. Pula para cima e cresce brilhando
		tween_coleta.set_parallel(true)
		tween_coleta.tween_property(self, "position:y", position.y - 32.0, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween_coleta.tween_property(self, "scale", scale * 1.35, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween_coleta.tween_property(self, "modulate", Color(1.6, 1.6, 1.0, 1.0), 0.20)
		# 2. Desvanece e encolhe
		tween_coleta.chain().set_parallel(true)
		tween_coleta.tween_property(self, "scale", Vector2.ZERO, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween_coleta.tween_property(self, "modulate:a", 0.0, 0.22)
		await tween_coleta.finished
		queue_free()

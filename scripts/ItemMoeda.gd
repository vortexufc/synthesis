extends Area2D

var coletavel = false
var _coletado = false
var valor_custom: int = 0
var id_unico: String = ""
var is_drop_dinamico: bool = false

var _tween_brilho: Tween
var _tween_glow: Tween
var _tween_bob: Tween

# Controle de combo de som de moedas
static var _ultimo_tempo_moeda: float = 0.0
static var _combo_moedas: int = 0

func _obter_id_unico() -> String:
	if id_unico != "":
		return id_unico
	var cena_path = ""
	if get_tree() and get_tree().current_scene:
		cena_path = get_tree().current_scene.scene_file_path
	var pos_str = "%d_%d" % [int(global_position.x), int(global_position.y)]
	var pai_nome = get_parent().name if get_parent() else ""
	return "%s::%s/%s@%s" % [cena_path, pai_nome, name, pos_str]

func _physics_process(delta: float) -> void:
	if not coletavel or _coletado:
		return
		
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < 80.0: # Raio de atração magnética
			var dir = (player.global_position - global_position).normalized()
			var speed = lerp(220.0, 520.0, 1.0 - (dist / 80.0))
			global_position += dir * speed * delta
			if dist < 16.0:
				_coletar(player)

func _ready() -> void:
	if not is_drop_dinamico:
		if id_unico == "":
			id_unico = _obter_id_unico()
		if get_node_or_null("/root/PlayerStats") and PlayerStats.is_item_coletado(id_unico):
			queue_free()
			return

	z_index = 2
	collision_layer = 0
	collision_mask = 15 # Pega o player
	body_entered.connect(_coletar)
	
	_iniciar_efeito_brilho()
	
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.35)
	tween.tween_callback(func(): coletavel = true)
	tween.tween_callback(_verificar_coleta_imediata)

func lancar_arco(pos_origem: Vector2, pos_destino: Vector2, altura_arco: float = 65.0) -> void:
	is_drop_dinamico = true
	coletavel = false
	global_position = pos_origem
	scale = Vector2(0.3, 0.3)
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position:x", pos_destino.x, 0.52).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	var tw_y = create_tween()
	var pico_y = min(pos_origem.y, pos_destino.y) - altura_arco
	tw_y.tween_property(self, "global_position:y", pico_y, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_y.tween_property(self, "global_position:y", pos_destino.y, 0.28).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	tw_y.tween_interval(0.18)
	tw_y.tween_callback(func():
		coletavel = true
		_verificar_coleta_imediata()
	)

func _iniciar_efeito_brilho() -> void:
	var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		for child in get_children():
			if child is Sprite2D and child.name != "GlowSprite":
				sprite = child as Sprite2D
				break
				
	# glow da moeda
	var glow: Sprite2D = get_node_or_null("GlowSprite") as Sprite2D
	if glow == null:
		glow = Sprite2D.new()
		glow.name = "GlowSprite"
		var tex_glow = load("res://assets/sprites/ui/glow_yellow.png") as Texture2D
		if tex_glow:
			glow.texture = tex_glow
			glow.scale = Vector2(0.32, 0.32)
			glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			add_child(glow)
			move_child(glow, 0)
			
	if glow:
		glow.modulate = Color(1.0, 0.88, 0.25, 0.5)
		_tween_glow = create_tween().set_loops()
		_tween_glow.tween_property(glow, "modulate:a", 0.85, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween_glow.tween_property(glow, "modulate:a", 0.35, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
	# moeda flutuando
	if sprite:
		_tween_brilho = create_tween().set_loops()
		_tween_brilho.tween_property(sprite, "modulate", Color(1.7, 1.45, 0.35, 1.0), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween_brilho.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		var pos_y = sprite.position.y
		_tween_bob = create_tween().set_loops()
		_tween_bob.tween_property(sprite, "position:y", pos_y - 5.0, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween_bob.tween_property(sprite, "position:y", pos_y + 5.0, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		# sombra
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

	# luz no chao
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
		
		var ganho = valor_custom if valor_custom > 0 else randi_range(3, 5)
		if get_node_or_null("/root/PlayerStats"):
			PlayerStats.moedas += ganho
			if not is_drop_dinamico and id_unico != "":
				PlayerStats.registrar_item_coletado(id_unico)
			PlayerStats.salvar()
			
		# Combo escalonado de som
		var agora = Time.get_ticks_msec() / 1000.0
		if agora - _ultimo_tempo_moeda < 1.3:
			_combo_moedas = min(_combo_moedas + 1, 8)
		else:
			_combo_moedas = 0
		_ultimo_tempo_moeda = agora
		
		var pitch = 1.0 + (_combo_moedas * 0.08)
		if get_node_or_null("/root/AudioManager"):
			if AudioManager.has_method("play_sfx_pitch"):
				AudioManager.play_sfx_pitch("moedas", pitch)
			else:
				AudioManager.play_sfx("moedas")
				
		_exibir_texto_flutuante_moeda(ganho)
			
		if _tween_brilho and _tween_brilho.is_valid(): _tween_brilho.kill()
		if _tween_glow and _tween_glow.is_valid(): _tween_glow.kill()
		if _tween_bob and _tween_bob.is_valid(): _tween_bob.kill()
		
		# particulas de coleta
		var pos_coleta = global_position
		var sprite = get_node_or_null("Sprite2D")
		if sprite:
			pos_coleta = sprite.global_position

		var part = CPUParticles2D.new()
		part.top_level = true
		part.z_index = 15
		part.local_coords = false
		
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
		
		var arvore = get_tree()
		var cena_alvo = arvore.current_scene if (arvore and arvore.current_scene) else get_parent()
		if cena_alvo:
			cena_alvo.add_child(part)
		else:
			get_tree().root.add_child(part)
			
		part.global_position = pos_coleta
		part.emitting = true
		part.restart()
		if arvore:
			arvore.create_timer(0.65).timeout.connect(part.queue_free)
		
		# animacao pulando e sumindo
		var tween_coleta = create_tween()
		tween_coleta.set_parallel(true)
		tween_coleta.tween_property(self, "position:y", position.y - 32.0, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween_coleta.tween_property(self, "scale", scale * 1.35, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween_coleta.tween_property(self, "modulate", Color(1.6, 1.6, 1.0, 1.0), 0.20)
		tween_coleta.chain().set_parallel(true)
		tween_coleta.tween_property(self, "scale", Vector2.ZERO, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween_coleta.tween_property(self, "modulate:a", 0.0, 0.22)
		await tween_coleta.finished
		queue_free()

func _exibir_texto_flutuante_moeda(qtd: int) -> void:
	var lbl = Label.new()
	lbl.text = "+%d 🪙" % qtd
	lbl.z_index = 25
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.35))
	lbl.add_theme_color_override("font_outline_color", Color(0.25, 0.14, 0.02, 0.95))
	lbl.add_theme_constant_override("outline_size", 2)
	
	var font_num = SystemFont.new()
	font_num.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_num.font_weight = 700
	lbl.add_theme_font_override("font", font_num)
		
	var arvore = get_tree()
	var cena_alvo = arvore.current_scene if (arvore and arvore.current_scene) else get_parent()
	if cena_alvo:
		cena_alvo.add_child(lbl)
	else:
		get_tree().root.add_child(lbl)
		
	lbl.global_position = global_position + Vector2(-15, -20)
	lbl.scale = Vector2(0.8, 0.8)
	
	var tw = lbl.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "global_position:y", lbl.global_position.y - 28.0, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "scale", Vector2(1.15, 1.15), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.15)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.22).set_delay(0.40)
	tw.chain().tween_callback(lbl.queue_free)
	
	if arvore:
		arvore.create_timer(0.75).timeout.connect(func():
			if is_instance_valid(lbl):
				lbl.queue_free()
		)


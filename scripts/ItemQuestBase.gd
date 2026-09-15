extends Area2D

@export var nome_item: String = "Item Desconhecido"
@export var descricao_item: String = "Um item genérico de missão."

var coletavel = false
var _coletado = false

func _ready() -> void:
	z_index = 2
	collision_layer = 0
	collision_mask = 15 # Pega o player
	body_entered.connect(_coletar)
	
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.35)
	tween.tween_callback(func(): coletavel = true)
	tween.tween_callback(_verificar_coleta_imediata)
	
	var tween_float = create_tween().set_loops()
	var sprite = $Sprite2D
	if sprite:
		tween_float.tween_property(sprite, "position:y", -8.0, 1.0).as_relative().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween_float.tween_property(sprite, "position:y", 8.0, 1.0).as_relative().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		# Sombra realista no chão acompanhando a flutuação
		_criar_sombra()
		if _shadow:
			var tw_s = create_tween().set_loops()
			tw_s.tween_property(_shadow, "scale", Vector2(1.20, 0.65), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw_s.parallel().tween_property(_shadow, "modulate:a", 0.65, 1.0)
			tw_s.tween_property(_shadow, "scale", Vector2(1.50, 0.90), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw_s.parallel().tween_property(_shadow, "modulate:a", 0.90, 1.0)

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
		_shadow.position = Vector2(0, 34)
		_shadow.scale = Vector2(1.4, 0.8)
		_shadow.modulate = Color(1.0, 1.0, 1.0, 0.85)
		_shadow.z_as_relative = false
		_shadow.z_index = 1
		add_child(_shadow)
		move_child(_shadow, 0)

func _verificar_coleta_imediata() -> void:
	for corpo in get_overlapping_bodies():
		_coletar(corpo)

func _coletar(corpo: Node2D) -> void:
	if not coletavel or _coletado: return
	if corpo.is_in_group("player") or corpo.name.begins_with("Player"):
		_coletado = true
		coletavel = false
		if get_node_or_null("/root/PlayerStats"):
			PlayerStats.itens.append({
				"nome": nome_item,
				"descricao": descricao_item
			})
			PlayerStats.salvar()
			PlayerStats.quests_atualizadas.emit()
			
			var hud = get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("mostrar_mensagem"):
				var total = 0
				for it in PlayerStats.itens:
					if it.get("nome") == nome_item: total += 1
				hud.mostrar_mensagem(nome_item + " (" + str(total) + "/5)")
				
		# Burst de partículas mágicas brilhantes do item coletado
		var part = CPUParticles2D.new()
		part.global_position = global_position
		part.z_index = 10
		
		var mat_p = CanvasItemMaterial.new()
		mat_p.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		part.material = mat_p
		
		var grad_tex = Gradient.new()
		grad_tex.offsets = PackedFloat32Array([0, 0.6, 1])
		grad_tex.colors = PackedColorArray([Color(1, 1, 1, 1), Color(0.4, 0.9, 1.0, 0.9), Color(0.1, 0.4, 1.0, 0)])
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
		grad.colors = PackedColorArray([Color(0.5, 1.0, 1.0, 1.0), Color(0.2, 0.5, 1.0, 0.0)])
		part.color_ramp = grad
		get_parent().add_child(part)
		part.emitting = true
		get_tree().create_timer(0.65).timeout.connect(part.queue_free)
		
		# Animação clara de salto (Hop & Pop)
		var tween_coleta = create_tween()
		tween_coleta.set_parallel(true)
		tween_coleta.tween_property(self, "position:y", position.y - 32.0, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween_coleta.tween_property(self, "scale", scale * 1.35, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween_coleta.tween_property(self, "modulate", Color(1.6, 1.6, 1.6, 1.0), 0.20)
		tween_coleta.chain().set_parallel(true)
		tween_coleta.tween_property(self, "scale", Vector2.ZERO, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween_coleta.tween_property(self, "modulate:a", 0.0, 0.22)
		await tween_coleta.finished
		queue_free()

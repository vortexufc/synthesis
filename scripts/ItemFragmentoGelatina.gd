extends "res://scripts/ItemQuestBase.gd"

@export_enum("azul", "verde", "vermelho") var cor_fragmento: String = "azul"

func _ready() -> void:
	nome_item = "Fragmento de Gelatina"
	_aplicar_cor()
	super._ready()

func configurar_cor(cor_nome: String) -> void:
	cor_fragmento = cor_nome.to_lower()
	_aplicar_cor()

func _aplicar_cor() -> void:
	var sprite = get_node_or_null("Sprite2D") as Sprite2D
	if not sprite:
		return
	
	sprite.hframes = 3
	sprite.vframes = 3
	
	var row = 2 # Padrão: Linha 2 = Azul
	if "verm" in cor_fragmento or "laranja" in cor_fragmento:
		row = 0 # Linha 0 = Vermelho
		cor_fragmento = "vermelho"
		descricao_item = "Um fragmento pegajoso e incandescente deixado por um slime vermelho."
	elif "verd" in cor_fragmento:
		row = 1 # Linha 1 = Verde
		cor_fragmento = "verde"
		descricao_item = "Um fragmento pegajoso e ácido deixado por um slime verde."
	else:
		row = 2 # Linha 2 = Azul
		cor_fragmento = "azul"
		descricao_item = "Um fragmento pegajoso e translúcido deixado por um slime azul."
		
	var col = randi_range(0, 2)
	sprite.frame_coords = Vector2i(col, row)
	sprite.scale = Vector2(1.25, 1.25)

func _coletar(corpo: Node2D) -> void:
	if not coletavel or _coletado: return
	if corpo.is_in_group("player") or corpo.name.begins_with("Player"):
		_coletado = true
		coletavel = false
		if get_node_or_null("/root/PlayerStats"):
			PlayerStats.itens.append({
				"nome": nome_item,
				"descricao": descricao_item,
				"cor": cor_fragmento
			})
			PlayerStats.salvar()
			PlayerStats.quests_atualizadas.emit()
			
			var hud = get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("mostrar_mensagem"):
				var total = 0
				for it in PlayerStats.itens:
					if it.get("nome") == nome_item: total += 1
				hud.mostrar_mensagem(nome_item + " (" + str(total) + "/5)")
				
		# particulas de coleta
		_emitir_particulas_coleta()
		
		# animacao de pulo
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

func _emitir_particulas_coleta() -> void:
	var part = CPUParticles2D.new()
	part.global_position = global_position
	part.z_index = 10
	
	var mat_p = CanvasItemMaterial.new()
	mat_p.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	part.material = mat_p
	
	var grad_tex = Gradient.new()
	grad_tex.offsets = PackedFloat32Array([0, 0.6, 1])
	grad_tex.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0)])
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
	if cor_fragmento == "vermelho":
		grad.colors = PackedColorArray([Color(1.0, 0.35, 0.25, 1.0), Color(0.85, 0.10, 0.10, 0.0)])
	elif cor_fragmento == "verde":
		grad.colors = PackedColorArray([Color(0.40, 1.0, 0.40, 1.0), Color(0.10, 0.70, 0.20, 0.0)])
	else:
		grad.colors = PackedColorArray([Color(0.35, 0.85, 1.0, 1.0), Color(0.10, 0.40, 1.0, 0.0)])
		
	part.color_ramp = grad
	var pai = get_parent()
	if pai:
		pai.add_child(part)
	else:
		get_tree().root.add_child(part)
	part.emitting = true
	get_tree().create_timer(0.65).timeout.connect(part.queue_free)

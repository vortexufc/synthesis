extends "res://scripts/ItemQuestBase.gd"

@export_enum("aleatoria", "amarela", "azul", "roxa", "laranja", "vermelha") var tipo_cor: String = "aleatoria"

var _row_idx: int = 0
var _tempo_flor: float = 0.0

func _ready() -> void:
	nome_item = "Flor Rara"
	descricao_item = "Uma flor arcana rara e luminosa, com pétalas cheias de essência mágica."
	
	if tipo_cor == "amarela":
		_row_idx = 0
	elif tipo_cor == "azul":
		_row_idx = 1
	elif tipo_cor == "roxa":
		_row_idx = 2
	elif tipo_cor == "laranja":
		_row_idx = 3
	elif tipo_cor == "vermelha":
		_row_idx = 4
	else:
		_row_idx = randi() % 5
		
	super._ready()
	
	var sprite = get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.hframes = 7
		sprite.vframes = 5
		sprite.frame_coords = Vector2i(0, _row_idx)

func _process(delta: float) -> void:
	_tempo_flor += delta
	var sprite = get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		var col = int(_tempo_flor * 4.5) % 7
		sprite.frame_coords = Vector2i(col, _row_idx)

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
			if not is_drop_dinamico and id_unico != "":
				PlayerStats.registrar_item_coletado(id_unico)
			PlayerStats.salvar()
			PlayerStats.quests_atualizadas.emit()
			
			var hud = get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("mostrar_mensagem"):
				var total = 0
				for it in PlayerStats.itens:
					if it.get("nome") == nome_item: total += 1
				hud.mostrar_mensagem(nome_item + " (" + str(total) + "/5)")
				
		_emitir_particulas_flor()
		
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

func _emitir_particulas_flor() -> void:
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
	
	part.amount = 16
	part.lifetime = 0.60
	part.one_shot = true
	part.explosiveness = 0.9
	part.direction = Vector2(0, -1)
	part.spread = 180.0
	part.gravity = Vector2(0, 40)
	part.initial_velocity_min = 40.0
	part.initial_velocity_max = 90.0
	part.scale_amount_min = 0.8
	part.scale_amount_max = 1.4
	
	var grad = Gradient.new()
	if _row_idx == 0:
		grad.colors = PackedColorArray([Color(1.0, 0.9, 0.3, 1.0), Color(0.9, 0.7, 0.1, 0.0)])
	elif _row_idx == 1:
		grad.colors = PackedColorArray([Color(0.4, 0.7, 1.0, 1.0), Color(0.2, 0.4, 0.9, 0.0)])
	elif _row_idx == 2:
		grad.colors = PackedColorArray([Color(0.8, 0.4, 1.0, 1.0), Color(0.5, 0.1, 0.8, 0.0)])
	elif _row_idx == 3:
		grad.colors = PackedColorArray([Color(1.0, 0.6, 0.2, 1.0), Color(0.9, 0.3, 0.1, 0.0)])
	else:
		grad.colors = PackedColorArray([Color(1.0, 0.3, 0.4, 1.0), Color(0.8, 0.1, 0.2, 0.0)])
	part.color_ramp = grad
	
	var arvore = get_tree()
	var pai = arvore.current_scene if (arvore and arvore.current_scene) else get_parent()
	if pai:
		pai.add_child(part)
	else:
		get_tree().root.add_child(part)
	part.global_position = pos_coleta
	part.emitting = true
	part.restart()
	if arvore:
		arvore.create_timer(0.7).timeout.connect(part.queue_free)

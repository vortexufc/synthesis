extends "res://scripts/ItemQuestBase.gd"

func _ready() -> void:
	nome_item = "Chip de DNA"
	descricao_item = "Um microdispositivo genético contendo sequências celulares da flora arcana."
	super._ready()

func _emitir_particulas_coleta() -> void:
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
	part.lifetime = 0.55
	part.one_shot = true
	part.explosiveness = 0.88
	part.direction = Vector2(0, -1)
	part.spread = 180.0
	part.gravity = Vector2(0, 30)
	part.initial_velocity_min = 40.0
	part.initial_velocity_max = 85.0
	part.scale_amount_min = 0.8
	part.scale_amount_max = 1.3
	
	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color(0.2, 0.8, 1.0, 1.0), Color(1.0, 0.5, 0.2, 0.0)])
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
		arvore.create_timer(0.65).timeout.connect(part.queue_free)

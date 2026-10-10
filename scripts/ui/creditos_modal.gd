extends Control

# Modal de Créditos da Equipe Synthesis & Vortex UFC

@onready var panel_container = $CenterContainer/PanelCard
@onready var btn_fechar = $CenterContainer/PanelCard/MarginContainer/VBoxMain/Header/BtnFechar
@onready var btn_fechar_rodape = $CenterContainer/PanelCard/MarginContainer/VBoxMain/BtnFecharRodape
@onready var backdrop = $Backdrop

var _fechando: bool = false
var _particulas: CPUParticles2D = null

func _ready() -> void:
	# Inicia invisível para animação de entrada suave
	modulate.a = 0.0
	
	btn_fechar.pressed.connect(fechar)
	btn_fechar_rodape.pressed.connect(fechar)
	backdrop.gui_input.connect(_on_backdrop_gui_input)
	
	_criar_particulas_douradas()
	
	# Garante que o pivô de escala esteja sempre perfeitamente centralizado
	panel_container.resized.connect(_atualizar_pivo)
	
	# Aguarda 1 frame do layout do Godot para obter as dimensões reais do cartão
	await get_tree().process_frame
	if not is_instance_valid(self) or not is_instance_valid(panel_container):
		return
	
	_atualizar_pivo()
	panel_container.scale = Vector2(0.95, 0.95)
	
	_animar_entrada()

func _atualizar_pivo() -> void:
	if is_instance_valid(panel_container):
		panel_container.pivot_offset = panel_container.size * 0.5
		if is_instance_valid(_particulas):
			_particulas.position = Vector2(panel_container.size.x * 0.5, panel_container.size.y - 12.0)
			_particulas.emission_rect_extents = Vector2(max(120.0, (panel_container.size.x * 0.5) - 24.0), 8.0)

func _criar_particulas_douradas() -> void:
	# Partículas sutis de fagulhas arcanas flutuando ao fundo (estilo Bolsa Arcana)
	_particulas = CPUParticles2D.new()
	_particulas.name = "FagulhasDouradas"
	_particulas.amount = 20
	_particulas.lifetime = 4.2
	_particulas.preprocess = 2.5
	_particulas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_particulas.emission_rect_extents = Vector2(280, 8)
	_particulas.direction = Vector2(0, -1)
	_particulas.spread = 16.0
	_particulas.gravity = Vector2(0, -12)
	_particulas.initial_velocity_min = 12.0
	_particulas.initial_velocity_max = 28.0
	_particulas.scale_amount_min = 1.8
	_particulas.scale_amount_max = 3.6
	_particulas.color = Color(1.0, 0.88, 0.45, 0.75)
	
	# Gradiente de nascimento suave e desvanecimento antes do topo
	var grad = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.20, 0.75, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 0.88, 0.45, 0.0),   # Nasce invisível
		Color(1.0, 0.88, 0.45, 0.35),  # Dourado arcano radiante
		Color(1.0, 0.82, 0.35, 0.25),  # Âmbar místico suave
		Color(1.0, 0.75, 0.20, 0.0)    # Desvanece completamente
	])
	_particulas.color_ramp = grad
	_particulas.process_mode = Node.PROCESS_MODE_ALWAYS
	
	panel_container.add_child(_particulas)
	panel_container.move_child(_particulas, 0)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # Tecla ESC ou B
		fechar()
		get_viewport().set_input_as_handled()

func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		fechar()

func _animar_entrada() -> void:
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui_5")
	
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.30)
	tw.tween_property(panel_container, "scale", Vector2.ONE, 0.30)

func fechar() -> void:
	if _fechando:
		return
	_fechando = true
	
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui_1")
	
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, 0.22)
	tw.tween_property(panel_container, "scale", Vector2(0.95, 0.95), 0.22)
	await tw.finished
	queue_free()


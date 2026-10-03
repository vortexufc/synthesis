extends Control

# Modal de Créditos da Equipe Synthesis & Vortex UFC

@onready var panel_container = $CenterContainer/PanelCard
@onready var btn_fechar = $CenterContainer/PanelCard/MarginContainer/VBoxMain/Header/BtnFechar
@onready var btn_fechar_rodape = $CenterContainer/PanelCard/MarginContainer/VBoxMain/BtnFecharRodape
@onready var backdrop = $Backdrop

func _ready() -> void:
	# Inicia invisível para animação de entrada suave
	modulate.a = 0.0
	panel_container.scale = Vector2(0.92, 0.92)
	panel_container.pivot_offset = panel_container.size * 0.5
	
	btn_fechar.pressed.connect(fechar)
	btn_fechar_rodape.pressed.connect(fechar)
	backdrop.gui_input.connect(_on_backdrop_gui_input)
	
	_animar_entrada()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # Tecla ESC ou B
		fechar()
		get_viewport().set_input_as_handled()

func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		fechar()

func _animar_entrada() -> void:
	AudioManager.play_sfx("ui_5")
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.28)
	tw.tween_property(panel_container, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK)

func fechar() -> void:
	AudioManager.play_sfx("ui_1")
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, 0.20)
	tw.tween_property(panel_container, "scale", Vector2(0.92, 0.92), 0.20)
	await tw.finished
	queue_free()

extends Control

# Modal amigável de alerta para jogadores visitantes salvando no navegador

signal continuar_como_visitante()
signal criar_conta_solicitada()

@onready var panel_card = $CenterContainer/PanelCard
@onready var btn_criar_conta = $CenterContainer/PanelCard/Margin/VBox/BtnCriarConta
@onready var btn_continuar_visitante = $CenterContainer/PanelCard/Margin/VBox/BtnContinuarVisitante
@onready var btn_fechar = $CenterContainer/PanelCard/Margin/VBox/Header/BtnFechar
@onready var lbl_mensagem = $CenterContainer/PanelCard/Margin/VBox/InfoBox/LabelMensagem
@onready var backdrop = $Backdrop

func _ready() -> void:
	modulate.a = 0.0
	panel_card.scale = Vector2(0.92, 0.92)
	panel_card.pivot_offset = panel_card.size * 0.5
	
	_aplicar_visual()
	btn_criar_conta.pressed.connect(_on_btn_criar_conta_pressed)
	btn_continuar_visitante.pressed.connect(_on_btn_continuar_visitante_pressed)
	btn_fechar.pressed.connect(_on_btn_continuar_visitante_pressed)
	backdrop.gui_input.connect(_on_backdrop_gui_input)
	
	_animar_entrada()

func _aplicar_visual() -> void:
	var font_normal = SystemFont.new()
	font_normal.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_normal.font_weight = 600
	
	lbl_mensagem.add_theme_font_override("font", font_normal)
	lbl_mensagem.add_theme_font_size_override("font_size", 14)
	btn_criar_conta.add_theme_font_override("font", font_normal)
	btn_criar_conta.add_theme_font_size_override("font_size", 15)
	btn_continuar_visitante.add_theme_font_override("font", font_normal)
	btn_continuar_visitante.add_theme_font_size_override("font_size", 13)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_btn_continuar_visitante_pressed()
		get_viewport().set_input_as_handled()

func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_btn_continuar_visitante_pressed()

func _on_btn_criar_conta_pressed() -> void:
	(get_node_or_null("/root/AudioManager").play_sfx("ui_5") if get_node_or_null("/root/AudioManager") else null)
	emit_signal("criar_conta_solicitada")
	_fechar_e_liberar(func():
		(get_node_or_null("/root/TransitionScreen").change_scene("res://scenes/ui/login.tscn") if get_node_or_null("/root/TransitionScreen") else get_tree().change_scene_to_file("res://scenes/ui/login.tscn"))
	)

func _on_btn_continuar_visitante_pressed() -> void:
	(get_node_or_null("/root/AudioManager").play_sfx("ui-1") if get_node_or_null("/root/AudioManager") else null)
	emit_signal("continuar_como_visitante")
	_fechar_e_liberar(Callable())

func _animar_entrada() -> void:
	(get_node_or_null("/root/AudioManager").play_sfx("ui_5") if get_node_or_null("/root/AudioManager") else null)
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.22)
	tw.tween_property(panel_card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK)

func _fechar_e_liberar(callback: Callable = Callable()) -> void:
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, 0.16)
	tw.tween_property(panel_card, "scale", Vector2(0.92, 0.92), 0.16)
	await tw.finished
	if callback.is_valid():
		callback.call()
	queue_free()

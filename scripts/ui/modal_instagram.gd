extends Control

# Modal de exibição do QR Code e link do Instagram da Vortex UFC

@onready var panel_card = $CenterContainer/PanelCard
@onready var btn_fechar = $CenterContainer/PanelCard/Margin/VBox/Header/BtnFechar
@onready var btn_abrir = $CenterContainer/PanelCard/Margin/VBox/BtnAbrir
@onready var btn_fechar_rodape = $CenterContainer/PanelCard/Margin/VBox/BtnFecharRodape
@onready var backdrop = $Backdrop
@onready var lbl_sub = $CenterContainer/PanelCard/Margin/VBox/LabelSub

const INSTAGRAM_URL = "https://www.instagram.com/vortexufc"

func _ready() -> void:
	modulate.a = 0.0
	panel_card.scale = Vector2(0.92, 0.92)
	panel_card.pivot_offset = panel_card.size * 0.5
	
	_aplicar_visual()
	btn_fechar.pressed.connect(fechar)
	btn_fechar_rodape.pressed.connect(fechar)
	btn_abrir.pressed.connect(_on_btn_abrir_pressed)
	backdrop.gui_input.connect(_on_backdrop_gui_input)
	
	_animar_entrada()

func _aplicar_visual() -> void:
	var font_normal = SystemFont.new()
	font_normal.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_normal.font_weight = 600
	lbl_sub.add_theme_font_override("font", font_normal)
	lbl_sub.add_theme_font_size_override("font_size", 14)
	btn_abrir.add_theme_font_override("font", font_normal)
	btn_abrir.add_theme_font_size_override("font_size", 15)
	btn_fechar_rodape.add_theme_font_override("font", font_normal)
	btn_fechar_rodape.add_theme_font_size_override("font_size", 14)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		fechar()
		get_viewport().set_input_as_handled()

func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		fechar()

func _on_btn_abrir_pressed() -> void:
	(get_node_or_null("/root/AudioManager").play_sfx("ui_5") if get_node_or_null("/root/AudioManager") else null)
	OS.shell_open(INSTAGRAM_URL)

func _animar_entrada() -> void:
	(get_node_or_null("/root/AudioManager").play_sfx("ui_5") if get_node_or_null("/root/AudioManager") else null)
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.22)
	tw.tween_property(panel_card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK)

func fechar() -> void:
	(get_node_or_null("/root/AudioManager").play_sfx("ui_1") if get_node_or_null("/root/AudioManager") else null)
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, 0.16)
	tw.tween_property(panel_card, "scale", Vector2(0.92, 0.92), 0.16)
	await tw.finished
	queue_free()

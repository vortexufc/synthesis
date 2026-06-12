extends Control

@onready var panel_centro: PanelContainer = $PanelCentro
@onready var lbl_titulo: Label = $PanelCentro/MarginContainer/VBox/LblTitulo
@onready var input_nome: LineEdit = $PanelCentro/MarginContainer/VBox/InputNome
@onready var input_tag: LineEdit = $PanelCentro/MarginContainer/VBox/InputTag
@onready var input_descricao: TextEdit = $PanelCentro/MarginContainer/VBox/InputDescricao
@onready var btn_cancelar: Button = $PanelCentro/MarginContainer/VBox/HBoxBotoes/BtnCancelar
@onready var btn_confirmar: Button = $PanelCentro/MarginContainer/VBox/HBoxBotoes/BtnConfirmar

func _ready() -> void:
	_aplicar_visual()
	btn_cancelar.pressed.connect(queue_free)
	btn_confirmar.pressed.connect(_on_btn_confirmar_pressed)

func _aplicar_visual() -> void:
	var font: Font = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	
	# Estilo do Painel (Azul escuro com borda azul vibrante)
	var style_painel: StyleBoxFlat = StyleBoxFlat.new()
	style_painel.bg_color = Color("142240")
	style_painel.border_color = Color("0088ff")
	style_painel.set_border_width_all(3)
	style_painel.corner_radius_top_left = 8
	style_painel.corner_radius_top_right = 8
	style_painel.corner_radius_bottom_right = 8
	style_painel.corner_radius_bottom_left = 8
	panel_centro.add_theme_stylebox_override("panel", style_painel)
	
	if font:
		lbl_titulo.add_theme_font_override("font", font)
		lbl_titulo.add_theme_font_size_override("font_size", 24)
		lbl_titulo.add_theme_color_override("font_color", Color.WHITE)
		
		input_nome.add_theme_font_override("font", font)
		input_tag.add_theme_font_override("font", font)
		input_descricao.add_theme_font_override("font", font)
		
		btn_cancelar.add_theme_font_override("font", font)
		btn_confirmar.add_theme_font_override("font", font)
		
	# Botão Confirmar (Verde premium)
	var style_confirmar: StyleBoxFlat = StyleBoxFlat.new()
	style_confirmar.bg_color = Color("28a745")
	style_confirmar.border_color = Color("4cd137")
	style_confirmar.set_border_width_all(2)
	style_confirmar.corner_radius_top_left = 4
	style_confirmar.corner_radius_top_right = 4
	style_confirmar.corner_radius_bottom_right = 4
	style_confirmar.corner_radius_bottom_left = 4
	
	btn_confirmar.add_theme_stylebox_override("normal", style_confirmar)
	btn_confirmar.add_theme_stylebox_override("hover", style_confirmar)
	
	# Botão Cancelar (Cinza escuro)
	var style_cancelar: StyleBoxFlat = StyleBoxFlat.new()
	style_cancelar.bg_color = Color("4a526d")
	style_cancelar.border_color = Color("7b84a1")
	style_cancelar.set_border_width_all(2)
	style_cancelar.corner_radius_top_left = 4
	style_cancelar.corner_radius_top_right = 4
	style_cancelar.corner_radius_bottom_right = 4
	style_cancelar.corner_radius_bottom_left = 4
	
	btn_cancelar.add_theme_stylebox_override("normal", style_cancelar)
	btn_cancelar.add_theme_stylebox_override("hover", style_cancelar)

func _on_btn_confirmar_pressed() -> void:
	var nome: String = input_nome.text.strip_edges()
	var tag: String = input_tag.text.strip_edges().to_upper()
	var descricao: String = input_descricao.text.strip_edges()
	
	# Validações
	if nome.length() < 3:
		_mostrar_erro("O nome do clã deve ter pelo menos 3 caracteres!")
		return
		
	if tag.length() < 2 or tag.length() > 5:
		_mostrar_erro("A TAG deve ter entre 2 e 5 letras!")
		return
		
	if descricao.is_empty():
		_mostrar_erro("Por favor, preencha uma breve descrição para o clã!")
		return
		
	btn_confirmar.disabled = true
	btn_cancelar.disabled = true
	
	# Tenta criar o clã
	var resultado: Dictionary = await ClanManager.create_clan(nome, tag, descricao)
	
	btn_confirmar.disabled = false
	btn_cancelar.disabled = false
	
	if resultado.get("success", false):
		print("Clã criado com sucesso!")
		queue_free()
	else:
		_mostrar_erro(resultado.get("message", "Nome ou TAG de clã já estão em uso!"))

func _mostrar_erro(msg: String) -> void:
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = "Erro de Validação"
	dialog.dialog_text = msg
	add_child(dialog)
	dialog.popup_centered()

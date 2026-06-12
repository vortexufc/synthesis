extends Control

@onready var dynamic_container: Control = $PainelCentro/DynamicContainer
@onready var btn_voltar: Button = $PainelCentro/BtnVoltar

var sem_cla_scene: PackedScene = preload("res://scenes/ui/SemCla.tscn")
var meu_cla_scene: PackedScene = preload("res://scenes/ui/MeuCla.tscn")

func _ready() -> void:
	_aplicar_visual()
	btn_voltar.pressed.connect(_on_btn_voltar_pressed)
	ClanManager.clan_updated.connect(_on_clan_updated)
	_atualizar_tela()

func _on_btn_voltar_pressed() -> void:
	TransitionScreen.change_scene("res://scenes/ui/main_menu.tscn")

func _on_clan_updated() -> void:
	_atualizar_tela()

func _atualizar_tela() -> void:
	# Limpa instâncias anteriores
	for child in dynamic_container.get_children():
		child.queue_free()
		
	var user_cla: String = DatabaseManager.user_cla
	if user_cla == "Nenhum" or user_cla.is_empty():
		var sem_cla: VBoxContainer = sem_cla_scene.instantiate() as VBoxContainer
		dynamic_container.add_child(sem_cla)
	else:
		var meu_cla: VBoxContainer = meu_cla_scene.instantiate() as VBoxContainer
		dynamic_container.add_child(meu_cla)

func _aplicar_visual() -> void:
	var tex_fundo_tela: Texture2D = load("res://assets/sprites/ui/ranking/painel_fundo.png") as Texture2D
	var tex_painel_central: Texture2D = load("res://assets/sprites/ui/ranking/item_fundo.png") as Texture2D
	var font: Font = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	
	if get_node_or_null("ColorRect"):
		var color_rect: ColorRect = $ColorRect as ColorRect
		color_rect.hide()
		
	var rect_fundo: TextureRect = TextureRect.new()
	rect_fundo.texture = tex_fundo_tela
	rect_fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect_fundo.ignore_texture_size = true
	add_child(rect_fundo)
	move_child(rect_fundo, 0)
	
	var style_centro: StyleBoxTexture = StyleBoxTexture.new()
	if tex_painel_central:
		style_centro.texture = tex_painel_central
	$PainelCentro.add_theme_stylebox_override("panel", style_centro)
	
	if font:
		$PainelCentro/LblTitulo.add_theme_font_override("font", font)
		$PainelCentro/LblTitulo.add_theme_font_size_override("font_size", 32)
		$PainelCentro/LblTitulo.add_theme_color_override("font_color", Color.WHITE)
		btn_voltar.add_theme_font_override("font", font)
		
	# Botão Voltar styling
	var style_voltar: StyleBoxFlat = StyleBoxFlat.new()
	style_voltar.bg_color = Color("142240")
	style_voltar.border_color = Color("0088ff")
	style_voltar.set_border_width_all(2)
	style_voltar.corner_radius_top_left = 4
	style_voltar.corner_radius_top_right = 4
	style_voltar.corner_radius_bottom_right = 4
	style_voltar.corner_radius_bottom_left = 4
	
	btn_voltar.add_theme_stylebox_override("normal", style_voltar)
	btn_voltar.add_theme_stylebox_override("hover", style_voltar)
	btn_voltar.add_theme_color_override("font_color", Color.WHITE)
	btn_voltar.position.y = 440 # Alinhado com o rodapé do painel 500px de altura

extends PanelContainer

@onready var img_avatar: TextureRect = $HBox/Avatar
@onready var lbl_nome: Label = $HBox/LblNome
@onready var lbl_cargo: Label = $HBox/LblCargo
@onready var lbl_score: Label = $HBox/LblScore
@onready var btn_expulsar: Button = $HBox/BtnExpulsar

var member_name: String = ""

func _ready() -> void:
	_aplicar_visual()
	btn_expulsar.pressed.connect(_on_btn_expulsar_pressed)

func _aplicar_visual() -> void:
	var font: Font = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	
	# Transparent panel background
	var style_vazio: StyleBoxEmpty = StyleBoxEmpty.new()
	add_theme_stylebox_override("panel", style_vazio)
	
	if font:
		lbl_nome.add_theme_font_override("font", font)
		lbl_cargo.add_theme_font_override("font", font)
		lbl_score.add_theme_font_override("font", font)
		btn_expulsar.add_theme_font_override("font", font)
		
	# Avatar loading
	var tex: Texture2D = load("res://avatar.png.png") as Texture2D
	if tex == null:
		tex = load("res://avatar.png") as Texture2D
	if tex:
		img_avatar.texture = tex
		
	# Pintar avatar do player logado de azul mágico para destacar!
	# (Veremos no set_info se o card é o jogador ativo)
	
	# Estilo do botão expulsar (Vermelho perigo)
	var style_btn: StyleBoxFlat = StyleBoxFlat.new()
	style_btn.bg_color = Color("ed2828")
	style_btn.border_color = Color("ff6868")
	style_btn.set_border_width_all(2)
	style_btn.corner_radius_top_left = 4
	style_btn.corner_radius_top_right = 4
	style_btn.corner_radius_bottom_right = 4
	style_btn.corner_radius_bottom_left = 4
	
	btn_expulsar.add_theme_stylebox_override("normal", style_btn)
	btn_expulsar.add_theme_stylebox_override("hover", style_btn)
	btn_expulsar.add_theme_color_override("font_color", Color.WHITE)

func set_info(p_member_name: String, role: String, score: int, is_active_player_leader: bool) -> void:
	member_name = p_member_name
	
	lbl_nome.text = member_name
	lbl_cargo.text = role.to_upper()
	lbl_score.text = str(score) + " PTS"
	
	# Cor para o cargo
	if role == "Líder":
		lbl_cargo.add_theme_color_override("font_color", Color("ffd700")) # Dourado
	else:
		lbl_cargo.add_theme_color_override("font_color", Color("ffffff")) # Branco
		
	# Pinta avatar do jogador ativo para identificação visual
	var meu_nick: String = ClanManager.get_player_nick()
	if member_name == meu_nick:
		img_avatar.modulate = Color(0.2, 0.5, 1.0) # Azul mágico!
		lbl_nome.text = member_name + " (VOCÊ)"
	else:
		img_avatar.modulate = Color.WHITE
		
	# Botão expulsar só aparece se o jogador atual for o líder E o alvo NÃO for ele mesmo
	if is_active_player_leader and member_name != meu_nick:
		btn_expulsar.show()
	else:
		btn_expulsar.hide()

func _on_btn_expulsar_pressed() -> void:
	if member_name.is_empty():
		return
		
	# Confirmação antes de expulsar
	var confirm: ConfirmationDialog = ConfirmationDialog.new()
	confirm.title = "Expulsar Membro"
	confirm.dialog_text = "Tem certeza que deseja expulsar " + member_name + " do clã?"
	add_child(confirm)
	confirm.confirmed.connect(func():
		btn_expulsar.disabled = true
		var resultado: Dictionary = await ClanManager.expel_member(member_name)
		btn_expulsar.disabled = false
		if resultado.get("success", false):
			print("Membro expulso: ", member_name)
		else:
			var dialog: AcceptDialog = AcceptDialog.new()
			dialog.title = "Erro ao Expulsar"
			dialog.dialog_text = resultado.get("message", "Falha ao expulsar membro")
			add_child(dialog)
			dialog.popup_centered()
	)
	confirm.popup_centered()

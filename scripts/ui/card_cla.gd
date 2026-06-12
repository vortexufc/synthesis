extends PanelContainer

@onready var lbl_nome_tag: Label = $HBox/LblNomeTag
@onready var lbl_membros: Label = $HBox/LblMembros
@onready var lbl_score: Label = $HBox/LblScore
@onready var btn_entrar: Button = $HBox/BtnEntrar

var clan_name: String = ""

func _ready() -> void:
	_aplicar_visual()
	btn_entrar.pressed.connect(_on_btn_entrar_pressed)

func _aplicar_visual() -> void:
	var font: Font = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	
	# Fundo transparente para o card se misturar com o painel pai
	var style_vazio: StyleBoxEmpty = StyleBoxEmpty.new()
	add_theme_stylebox_override("panel", style_vazio)
	
	if font:
		lbl_nome_tag.add_theme_font_override("font", font)
		lbl_membros.add_theme_font_override("font", font)
		lbl_score.add_theme_font_override("font", font)
		btn_entrar.add_theme_font_override("font", font)
		
	lbl_membros.add_theme_color_override("font_color", Color("d9d9d9"))
	lbl_score.add_theme_color_override("font_color", Color("ffd700")) # Dourado para score

	# Botão Entrar (Azul vibrante)
	var style_btn: StyleBoxFlat = StyleBoxFlat.new()
	style_btn.bg_color = Color("284eed")
	style_btn.border_color = Color("686ff8")
	style_btn.set_border_width_all(2)
	style_btn.corner_radius_top_left = 4
	style_btn.corner_radius_top_right = 4
	style_btn.corner_radius_bottom_right = 4
	style_btn.corner_radius_bottom_left = 4
	
	var style_btn_disabled: StyleBoxFlat = StyleBoxFlat.new()
	style_btn_disabled.bg_color = Color("4a526d")
	style_btn_disabled.border_color = Color("7b84a1")
	style_btn_disabled.set_border_width_all(2)
	style_btn_disabled.corner_radius_top_left = 4
	style_btn_disabled.corner_radius_top_right = 4
	style_btn_disabled.corner_radius_bottom_right = 4
	style_btn_disabled.corner_radius_bottom_left = 4

	btn_entrar.add_theme_stylebox_override("normal", style_btn)
	btn_entrar.add_theme_stylebox_override("hover", style_btn)
	btn_entrar.add_theme_stylebox_override("disabled", style_btn_disabled)
	btn_entrar.add_theme_color_override("font_color", Color.WHITE)

# Assinatura sem posição/rank — o ranking fica na aba de Ranking
func set_info(p_clan_name: String, tag: String, score: int, member_count: int) -> void:
	clan_name = p_clan_name
	
	lbl_nome_tag.text = clan_name + "  [" + tag + "]"
	lbl_membros.text = str(member_count) + " membros"
	lbl_score.text = str(score) + " PTS"
	
	# Verifica permissão para entrar
	var meu_cla: String = DatabaseManager.user_cla
	if meu_cla == clan_name:
		btn_entrar.text = "MEMBRO"
		btn_entrar.disabled = true
	elif meu_cla != "Nenhum" and not meu_cla.is_empty():
		btn_entrar.text = "BLOQUEADO"
		btn_entrar.disabled = true
	else:
		btn_entrar.text = "ENTRAR"
		btn_entrar.disabled = false

func _on_btn_entrar_pressed() -> void:
	if clan_name.is_empty():
		return
		
	btn_entrar.disabled = true
	var resultado: Dictionary = await ClanManager.join_clan(clan_name)
	btn_entrar.disabled = false
	
	if resultado.get("success", false):
		print("Entrou no clã: ", clan_name)
	else:
		var dialog: AcceptDialog = AcceptDialog.new()
		dialog.title = "Erro ao Entrar no Clã"
		dialog.dialog_text = resultado.get("message", "Não foi possível entrar no clã!")
		add_child(dialog)
		dialog.popup_centered()

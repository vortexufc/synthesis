extends PanelContainer

@onready var lbl_nome_tag: Label = $HBox/LblNomeTag
@onready var lbl_membros: Label = $HBox/LblMembros
@onready var lbl_score: Label = $HBox/LblScore
@onready var btn_ver_membros: Button = $HBox/BtnVerMembros
@onready var btn_entrar: Button = $HBox/BtnEntrar

var clan_name: String = ""

func _ready() -> void:
	_aplicar_visual()
	btn_entrar.pressed.connect(_on_btn_entrar_pressed)
	btn_ver_membros.pressed.connect(_on_btn_ver_membros_pressed)

func _aplicar_visual() -> void:
	var font_normal = SystemFont.new()
	font_normal.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_normal.font_weight = 600
	
	# Fundo transparente para o card se misturar com o painel pai
	var style_vazio: StyleBoxEmpty = StyleBoxEmpty.new()
	add_theme_stylebox_override("panel", style_vazio)
	
	lbl_nome_tag.add_theme_font_override("font", font_normal)
	lbl_nome_tag.add_theme_font_size_override("font_size", 18)
	lbl_membros.add_theme_font_override("font", font_normal)
	lbl_membros.add_theme_font_size_override("font_size", 15)
	lbl_score.add_theme_font_override("font", font_normal)
	lbl_score.add_theme_font_size_override("font_size", 18)
	btn_ver_membros.add_theme_font_override("font", font_normal)
	btn_ver_membros.add_theme_font_size_override("font_size", 14)
	btn_entrar.add_theme_font_override("font", font_normal)
	btn_entrar.add_theme_font_size_override("font_size", 16)
		
	lbl_membros.add_theme_color_override("font_color", Color("d9d9d9"))
	lbl_score.add_theme_color_override("font_color", Color("ffd700")) # Dourado para score

	# Botão Ver Membros (Borda ciano/azul escuro, discreto e elegante)
	var style_btn_ver: StyleBoxFlat = StyleBoxFlat.new()
	style_btn_ver.bg_color = Color(0.08, 0.14, 0.25, 0.9)
	style_btn_ver.border_color = Color(0.22, 0.65, 0.95, 0.9)
	style_btn_ver.set_border_width_all(2)
	style_btn_ver.corner_radius_top_left = 4
	style_btn_ver.corner_radius_top_right = 4
	style_btn_ver.corner_radius_bottom_right = 4
	style_btn_ver.corner_radius_bottom_left = 4

	var style_btn_ver_hover: StyleBoxFlat = style_btn_ver.duplicate()
	style_btn_ver_hover.bg_color = Color(0.14, 0.24, 0.42, 1.0)
	style_btn_ver_hover.border_color = Color(0.45, 0.82, 1.0, 1.0)

	btn_ver_membros.add_theme_stylebox_override("normal", style_btn_ver)
	btn_ver_membros.add_theme_stylebox_override("hover", style_btn_ver_hover)
	btn_ver_membros.add_theme_stylebox_override("pressed", style_btn_ver_hover)
	btn_ver_membros.add_theme_stylebox_override("focus", style_btn_ver_hover)
	btn_ver_membros.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	btn_ver_membros.add_theme_color_override("font_hover_color", Color.WHITE)

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
	if not is_node_ready():
		await ready
		
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

func _on_btn_ver_membros_pressed() -> void:
	if clan_name.is_empty():
		return
	var modal_scene = preload("res://scenes/ui/ModalMembrosCla.tscn")
	var modal = modal_scene.instantiate()
	var target_parent = get_tree().current_scene
	if target_parent:
		target_parent.add_child(modal)
	else:
		get_tree().root.add_child(modal)
	modal.carregar_dados_cla(clan_name)

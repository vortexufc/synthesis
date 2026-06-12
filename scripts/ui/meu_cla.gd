extends VBoxContainer

@onready var lbl_nome_tag: Label = $HBoxInfo/VBoxDetalhes/LblNomeTag
@onready var lbl_pontuacao: Label = $HBoxInfo/VBoxDetalhes/LblPontuacao
@onready var lbl_descricao: Label = $HBoxInfo/VBoxDetalhes/LblDescricao
@onready var btn_sair: Button = $HBoxInfo/BtnSair
@onready var lbl_membros_titulo: Label = $HBoxSub/LblMembrosTitulo
@onready var container_lista: VBoxContainer = $ScrollContainer/ListaDeMembros

var card_membro_scene: PackedScene = preload("res://scenes/ui/CardMembro.tscn")

func _ready() -> void:
	_aplicar_visual()
	btn_sair.pressed.connect(_on_btn_sair_pressed)
	
	ClanManager.clan_updated.connect(_on_clan_updated)
	
	_carregar_dados_cla()

func _aplicar_visual() -> void:
	var font: Font = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	if font:
		lbl_nome_tag.add_theme_font_override("font", font)
		lbl_nome_tag.add_theme_font_size_override("font_size", 24)
		lbl_nome_tag.add_theme_color_override("font_color", Color("0088ff")) # Azul vibrante
		
		lbl_pontuacao.add_theme_font_override("font", font)
		lbl_pontuacao.add_theme_font_size_override("font_size", 18)
		
		lbl_descricao.add_theme_font_override("font", font)
		lbl_descricao.add_theme_font_size_override("font_size", 14)
		lbl_descricao.add_theme_color_override("font_color", Color("d9d9d9"))
		
		btn_sair.add_theme_font_override("font", font)
		lbl_membros_titulo.add_theme_font_override("font", font)
		lbl_membros_titulo.add_theme_font_size_override("font_size", 20)
		
	# Botão Sair (Vermelho perigo)
	var style_btn_sair: StyleBoxFlat = StyleBoxFlat.new()
	style_btn_sair.bg_color = Color("ed2828")
	style_btn_sair.border_color = Color("ff6868")
	style_btn_sair.set_border_width_all(2)
	style_btn_sair.corner_radius_top_left = 4
	style_btn_sair.corner_radius_top_right = 4
	style_btn_sair.corner_radius_bottom_right = 4
	style_btn_sair.corner_radius_bottom_left = 4
	
	btn_sair.add_theme_stylebox_override("normal", style_btn_sair)
	btn_sair.add_theme_stylebox_override("hover", style_btn_sair)
	btn_sair.add_theme_color_override("font_color", Color.WHITE)

func _carregar_dados_cla() -> void:
	var clan_name: String = DatabaseManager.user_cla
	var clan: Dictionary = ClanManager.get_clan_info(clan_name)
	
	if clan.is_empty():
		push_error("Informações do clã não encontradas!")
		return
		
	lbl_nome_tag.text = clan["name"] + " [" + clan["tag"] + "]"
	lbl_pontuacao.text = "PONTUAÇÃO TOTAL: " + str(clan["score"]) + " PTS"
	lbl_descricao.text = clan["description"]
	lbl_membros_titulo.text = "MEMBROS (" + str(clan["members"].size()) + "/50)"
	
	# Determina se o jogador logado é o líder
	var meu_nick: String = ClanManager.get_player_nick()
	var sou_lider: bool = (clan["leader"] == meu_nick)
	
	# Desenha os membros
	for child in container_lista.get_children():
		child.queue_free()
		
	for member in clan["members"]:
		var card = card_membro_scene.instantiate()
		container_lista.add_child(card)
		card.set_info(member["name"], member["role"], member["score"], sou_lider)

func _on_btn_sair_pressed() -> void:
	var confirm: ConfirmationDialog = ConfirmationDialog.new()
	confirm.title = "Sair do Clã"
	
	var clan_name: String = DatabaseManager.user_cla
	var clan: Dictionary = ClanManager.get_clan_info(clan_name)
	
	if clan.get("leader", "") == ClanManager.get_player_nick() and clan.get("members", []).size() == 1:
		confirm.dialog_text = "Você é o único membro e líder. Se sair, o clã será desfeito para sempre. Continuar?"
	else:
		confirm.dialog_text = "Tem certeza que deseja sair do clã?"
		
	add_child(confirm)
	confirm.confirmed.connect(func():
		btn_sair.disabled = true
		var resultado: Dictionary = await ClanManager.leave_clan()
		btn_sair.disabled = false
		if resultado.get("success", false):
			print("Saiu do clã com sucesso")
		else:
			var dialog: AcceptDialog = AcceptDialog.new()
			dialog.title = "Erro ao Sair do Clã"
			dialog.dialog_text = resultado.get("message", "Erro ao tentar sair do clã")
			add_child(dialog)
			dialog.popup_centered()
	)
	confirm.popup_centered()

func _on_clan_updated() -> void:
	# Se saímos do clã ou fomos expulsos, a TelaClas cuidará de descarregar essa cena, 
	# mas caso estejamos ainda aqui (ex: membro expulso da lista), recarrega.
	var clan_name: String = DatabaseManager.user_cla
	if clan_name != "Nenhum" and not clan_name.is_empty():
		_carregar_dados_cla()

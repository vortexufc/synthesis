extends Control

# Modal para visualização de membros de um Clã

@onready var panel_card = $CenterContainer/PanelCard
@onready var lbl_clan_nome = $CenterContainer/PanelCard/MarginContainer/VBoxMain/Header/VBoxTitles/LabelClanNome
@onready var lbl_sub = $CenterContainer/PanelCard/MarginContainer/VBoxMain/Header/VBoxTitles/LabelSub
@onready var lbl_membros_titulo = $CenterContainer/PanelCard/MarginContainer/VBoxMain/LabelMembrosTitulo
@onready var container_membros = $CenterContainer/PanelCard/MarginContainer/VBoxMain/ScrollContainer/VBoxMembros
@onready var btn_fechar = $CenterContainer/PanelCard/MarginContainer/VBoxMain/Header/BtnFechar
@onready var btn_fechar_rodape = $CenterContainer/PanelCard/MarginContainer/VBoxMain/BtnFecharRodape
@onready var backdrop = $Backdrop

var card_membro_scene = preload("res://scenes/ui/CardMembro.tscn")

func _ready() -> void:
	modulate.a = 0.0
	panel_card.scale = Vector2(0.92, 0.92)
	panel_card.pivot_offset = panel_card.size * 0.5
	
	_aplicar_visual()
	btn_fechar.pressed.connect(fechar)
	btn_fechar_rodape.pressed.connect(fechar)
	backdrop.gui_input.connect(_on_backdrop_gui_input)
	
	_animar_entrada()

func _aplicar_visual() -> void:
	var font_normal = SystemFont.new()
	font_normal.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_normal.font_weight = 600
	
	lbl_sub.add_theme_font_override("font", font_normal)
	lbl_sub.add_theme_font_size_override("font_size", 15)
	lbl_membros_titulo.add_theme_font_override("font", font_normal)
	lbl_membros_titulo.add_theme_font_size_override("font_size", 14)
	btn_fechar_rodape.add_theme_font_override("font", font_normal)
	btn_fechar_rodape.add_theme_font_size_override("font_size", 15)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		fechar()
		get_viewport().set_input_as_handled()

func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		fechar()

func carregar_dados_cla(clan_name: String) -> void:
	var clan: Dictionary = ClanManager.get_clan_info(clan_name)
	
	if clan.is_empty():
		await ClanManager.load_clans()
		clan = ClanManager.get_clan_info(clan_name)
		
	if clan.is_empty():
		lbl_clan_nome.text = clan_name
		lbl_sub.text = "Informações do clã indisponíveis."
		return
		
	lbl_clan_nome.text = clan.get("name", "") + " [" + clan.get("tag", "") + "]"
	
	var leader = clan.get("leader", "Nenhum")
	var score = int(clan.get("score", 0))
	lbl_sub.text = "Líder: %s  •  Pontuação Total: %d PTS" % [leader, score]
	
	var members: Array = clan.get("members", [])
	lbl_membros_titulo.text = "MEMBROS INTEGRANTES (%d/50)" % members.size()
	
	for child in container_membros.get_children():
		child.queue_free()
		
	if members.is_empty():
		var lbl_vazio = Label.new()
		lbl_vazio.text = "Nenhum membro listado neste clã."
		lbl_vazio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_vazio.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_vazio.custom_minimum_size = Vector2(0, 60)
		container_membros.add_child(lbl_vazio)
	else:
		for m in members:
			var card = card_membro_scene.instantiate()
			container_membros.add_child(card)
			card.set_info(m.get("name", ""), m.get("role", "Membro"), int(m.get("score", 0)), false)

func _animar_entrada() -> void:
	AudioManager.play_sfx("ui_5")
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.25)
	tw.tween_property(panel_card, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)

func fechar() -> void:
	AudioManager.play_sfx("ui_1")
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, 0.18)
	tw.tween_property(panel_card, "scale", Vector2(0.92, 0.92), 0.18)
	await tw.finished
	queue_free()

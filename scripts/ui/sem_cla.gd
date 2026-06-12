extends VBoxContainer

@onready var input_busca: LineEdit = $HBoxAcoes/InputBusca
@onready var btn_buscar: Button = $HBoxAcoes/BtnBuscar
@onready var btn_criar_popup: Button = $HBoxAcoes/BtnCriarPopup
@onready var lbl_top: Label = $LblTop
@onready var container_lista: VBoxContainer = $ScrollContainer/ListaDeClas

var card_cla_scene: PackedScene = preload("res://scenes/ui/CardCla.tscn")
var popup_criar_scene: PackedScene = preload("res://scenes/ui/PopupCriarCla.tscn")

func _ready() -> void:
	_aplicar_visual()
	
	btn_buscar.pressed.connect(_on_btn_buscar_pressed)
	btn_criar_popup.pressed.connect(_on_btn_criar_popup_pressed)
	ClanManager.clan_list_updated.connect(_on_clan_list_updated)
	
	# Carrega sugestões iniciais (embaralhadas, sem ordenação de ranking)
	_carregar_lista(ClanManager.get_sugestoes_clas())

func _aplicar_visual() -> void:
	var font: Font = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	if font:
		input_busca.add_theme_font_override("font", font)
		btn_buscar.add_theme_font_override("font", font)
		btn_criar_popup.add_theme_font_override("font", font)
		lbl_top.add_theme_font_override("font", font)
		lbl_top.add_theme_font_size_override("font_size", 20)
		lbl_top.add_theme_color_override("font_color", Color("d9d9d9"))
		
	# Estilo do botão Criar (Verde premium)
	var style_btn_criar: StyleBoxFlat = StyleBoxFlat.new()
	style_btn_criar.bg_color = Color("28a745")
	style_btn_criar.border_color = Color("4cd137")
	style_btn_criar.set_border_width_all(2)
	style_btn_criar.corner_radius_top_left = 4
	style_btn_criar.corner_radius_top_right = 4
	style_btn_criar.corner_radius_bottom_right = 4
	style_btn_criar.corner_radius_bottom_left = 4
	
	btn_criar_popup.add_theme_stylebox_override("normal", style_btn_criar)
	btn_criar_popup.add_theme_stylebox_override("hover", style_btn_criar)
	btn_criar_popup.add_theme_color_override("font_color", Color.WHITE)
	
	# Estilo do botão buscar
	var style_btn_buscar: StyleBoxFlat = StyleBoxFlat.new()
	style_btn_buscar.bg_color = Color("142240")
	style_btn_buscar.border_color = Color("0088ff")
	style_btn_buscar.set_border_width_all(2)
	style_btn_buscar.corner_radius_top_left = 4
	style_btn_buscar.corner_radius_top_right = 4
	style_btn_buscar.corner_radius_bottom_right = 4
	style_btn_buscar.corner_radius_bottom_left = 4
	
	btn_buscar.add_theme_stylebox_override("normal", style_btn_buscar)
	btn_buscar.add_theme_stylebox_override("hover", style_btn_buscar)
	btn_buscar.add_theme_color_override("font_color", Color.WHITE)

func _carregar_lista(lista: Array) -> void:
	for child in container_lista.get_children():
		child.queue_free()
	
	if lista.is_empty():
		# Nenhum clã encontrado — mostra mensagem amigável
		var lbl: Label = Label.new()
		var font: Font = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
		if font:
			lbl.add_theme_font_override("font", font)
		lbl.text = "Nenhum clã encontrado. Que tal criar o seu?"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", Color("d9d9d9"))
		container_lista.add_child(lbl)
		return
		
	for clan in lista:
		var card: PanelContainer = card_cla_scene.instantiate() as PanelContainer
		container_lista.add_child(card)
		if card.has_method("set_info"):
			# Sem posição/rank — apenas nome, tag e membros
			card.call("set_info", clan["name"], clan["tag"], clan["score"], clan["members"].size())

func _on_btn_buscar_pressed() -> void:
	var query: String = input_busca.text
	btn_buscar.disabled = true
	# Puxa atualizações do banco antes da pesquisa
	await ClanManager.load_clans()
	btn_buscar.disabled = false
	
	var filtrados: Array = ClanManager.search_clans(query)
	_carregar_lista(filtrados)
	
	# Atualiza o label conforme o contexto
	if query.strip_edges().is_empty():
		lbl_top.text = "SUGESTÕES DE CLÃS"
	else:
		lbl_top.text = "RESULTADOS DA BUSCA"

func _on_btn_criar_popup_pressed() -> void:
	var popup: Control = popup_criar_scene.instantiate() as Control
	get_tree().current_scene.add_child(popup)

func _on_clan_list_updated() -> void:
	# Recarrega as sugestões após mudança no banco de clãs
	_carregar_lista(ClanManager.get_sugestoes_clas())
	lbl_top.text = "SUGESTÕES DE CLÃS"

extends Control

var vbox_quests: VBoxContainer
var quest_cards: Dictionary = {}

var _font_pixel: Font = null
var _font_normal: Font = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_font_pixel = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	_font_normal = _font_pixel
	
	vbox_quests = VBoxContainer.new()
	vbox_quests.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox_quests.add_theme_constant_override("separation", 8)
	
	# Posicionando abaixo da barra de vida (exemplo: y=80)
	vbox_quests.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	vbox_quests.position = Vector2(20, 80)
	
	add_child(vbox_quests)
	
	PlayerStats.quests_atualizadas.connect(_atualizar_hud)
	_atualizar_hud()

var _timer_hud: float = 0.0

func _process(delta: float) -> void:
	# Atualiza o progresso a cada 0.3s em vez de todo frame (economiza CPU no navegador)
	_timer_hud += delta
	if _timer_hud >= 0.3:
		_timer_hud = 0.0
		_atualizar_hud()

func _atualizar_hud() -> void:
	# Lista de todas as quests possiveis e suas descrições
	var defs_quests = {
		"cientista_quest1": {"titulo": "Livros do Cientista", "item": "Livro de Fórmulas", "qtd": 5},
		"cientista_quest2": {"titulo": "Gelatina do Cientista", "item": "Fragmento de Gelatina", "qtd": 5},
		"fisica_quest1": {"titulo": "Baterias do Engenheiro", "item": "Bateria Elétrica", "qtd": 5},
		"fisica_quest2": {"titulo": "Chips do Engenheiro", "item": "Fragmento de Chip", "qtd": 5}
	}
	
	# Remover cards de quests que não estão mais ativas
	for quest_id in quest_cards.keys():
		if not PlayerStats.quests_ativas.has(quest_id) or not PlayerStats.quests_ativas[quest_id]:
			quest_cards[quest_id].queue_free()
			quest_cards.erase(quest_id)
			
	# Atualizar ou criar cards para quests ativas
	for quest_id in PlayerStats.quests_ativas.keys():
		if PlayerStats.quests_ativas[quest_id] and defs_quests.has(quest_id):
			var def = defs_quests[quest_id]
			var progresso = _contar_item(def["item"])
			var pronto = (progresso >= def["qtd"])
			
			if not quest_cards.has(quest_id):
				var novo_card = _criar_card()
				quest_cards[quest_id] = novo_card
				vbox_quests.add_child(novo_card)
				novo_card.modulate.a = 0.0
				novo_card.scale = Vector2(0.8, 0.8)
				var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw.tween_property(novo_card, "modulate:a", 1.0, 0.3)
				tw.tween_property(novo_card, "scale", Vector2(1.0, 1.0), 0.3)
				
			var card = quest_cards[quest_id]
			var lbl_titulo = card.get_node("VBox/LblTitulo") as Label
			var lbl_progresso = card.get_node("VBox/LblProgresso") as Label
			
			lbl_titulo.text = "📜 " + def["titulo"]
			
			var sb = card.get_theme_stylebox("panel") as StyleBoxFlat
			if pronto:
				lbl_progresso.text = "✔ Pronto para Entregar! (" + str(progresso) + "/" + str(def["qtd"]) + ")"
				lbl_progresso.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55))
				lbl_titulo.add_theme_color_override("font_color", Color(0.5, 1.0, 0.7))
				if sb:
					sb.border_color = Color(0.25, 0.95, 0.5, 1.0)
					sb.border_width_left = 3
					sb.border_width_top = 0
					sb.border_width_right = 0
					sb.border_width_bottom = 0
					sb.bg_color = Color(0.06, 0.06, 0.1, 0.88)
			else:
				lbl_progresso.text = "Progresso: " + str(progresso) + "/" + str(def["qtd"])
				lbl_progresso.add_theme_color_override("font_color", Color(1.0, 0.92, 0.7))
				lbl_titulo.add_theme_color_override("font_color", Color(1.0, 0.88, 0.5))
				if sb:
					sb.border_color = Color(0.8, 0.7, 0.3, 0.8)
					sb.border_width_left = 2
					sb.border_width_top = 0
					sb.border_width_right = 0
					sb.border_width_bottom = 0
					sb.bg_color = Color(0.06, 0.06, 0.1, 0.88)

func _criar_card() -> PanelContainer:
	var card = PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.06, 0.1, 0.88)
	sb.border_color = Color(0.8, 0.7, 0.3, 0.8)
	sb.border_width_left = 2
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 4
	card.add_theme_stylebox_override("panel", sb)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 2)
	card.add_child(vbox)
	
	var lbl_titulo = Label.new()
	lbl_titulo.name = "LblTitulo"
	lbl_titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _font_pixel:
		lbl_titulo.add_theme_font_override("font", _font_pixel)
	lbl_titulo.add_theme_font_size_override("font_size", 14)
	vbox.add_child(lbl_titulo)
	
	var lbl_progresso = Label.new()
	lbl_progresso.name = "LblProgresso"
	lbl_progresso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _font_normal:
		lbl_progresso.add_theme_font_override("font", _font_normal)
	lbl_progresso.add_theme_font_size_override("font_size", 13)
	vbox.add_child(lbl_progresso)
	
	return card

func _contar_item(nome_item: String) -> int:
	var contagem = 0
	for item in PlayerStats.itens:
		var nome_it = item.get("nome", "")
		if nome_it == nome_item:
			contagem += 1
		elif nome_item == "Fragmento de Gelatina" and ("Gelatina" in nome_it or item.has("cor")):
			contagem += 1
	return contagem

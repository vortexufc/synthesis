extends Control

var input_pergunta: TextEdit
var input_a: LineEdit
var input_b: LineEdit
var input_c: LineEdit
var input_d: LineEdit
var input_e: LineEdit
var opt_correta: OptionButton
var opt_disciplina: OptionButton
var lbl_status: Label

func _ready() -> void:
	# Fundo
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.15, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Layout Principal
	var margem = MarginContainer.new()
	margem.add_theme_constant_override("margin_left", 40)
	margem.add_theme_constant_override("margin_right", 40)
	margem.add_theme_constant_override("margin_top", 40)
	margem.add_theme_constant_override("margin_bottom", 40)
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(margem)
	
	var scroll = ScrollContainer.new()
	margem.add_child(scroll)
	
	var vbox_principal = VBoxContainer.new()
	vbox_principal.add_theme_constant_override("separation", 20)
	vbox_principal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox_principal)
	
	# Cabeçalho
	var cabecalho_hbox = HBoxContainer.new()
	vbox_principal.add_child(cabecalho_hbox)
	
	var lbl_titulo = Label.new()
	lbl_titulo.text = "Gerenciador de Perguntas - Nova Questão"
	lbl_titulo.add_theme_font_size_override("font_size", 28)
	lbl_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabecalho_hbox.add_child(lbl_titulo)
	
	var btn_voltar = Button.new()
	btn_voltar.text = "Voltar ao Painel"
	btn_voltar.pressed.connect(func(): TransitionScreen.change_scene("res://scenes/ui/painel_admin.tscn"))
	cabecalho_hbox.add_child(btn_voltar)
	
	# Formulário
	var form_panel = PanelContainer.new()
	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = Color(0.15, 0.16, 0.22, 1.0)
	style_panel.corner_radius_top_left = 15
	style_panel.corner_radius_top_right = 15
	style_panel.corner_radius_bottom_left = 15
	style_panel.corner_radius_bottom_right = 15
	style_panel.shadow_color = Color(0, 0, 0, 0.4)
	style_panel.shadow_size = 5
	style_panel.shadow_offset = Vector2(0, 4)
	style_panel.content_margin_left = 30
	style_panel.content_margin_right = 30
	style_panel.content_margin_top = 30
	style_panel.content_margin_bottom = 30
	form_panel.add_theme_stylebox_override("panel", style_panel)
	vbox_principal.add_child(form_panel)
	
	var form_vbox = VBoxContainer.new()
	form_vbox.add_theme_constant_override("separation", 20)
	form_panel.add_child(form_vbox)
	
	# Disciplina
	var hbox_disc = HBoxContainer.new()
	form_vbox.add_child(hbox_disc)
	var lbl_disc = Label.new()
	lbl_disc.text = "Disciplina (Andar):"
	lbl_disc.custom_minimum_size = Vector2(200, 0)
	hbox_disc.add_child(lbl_disc)
	
	opt_disciplina = OptionButton.new()
	opt_disciplina.add_item("Química (Andar 1)", 1)
	opt_disciplina.add_item("Física (Andar 2)", 2)
	opt_disciplina.add_item("Biologia (Andar 3)", 3)
	hbox_disc.add_child(opt_disciplina)
	
	# Pergunta
	var hbox_perg = HBoxContainer.new()
	form_vbox.add_child(hbox_perg)
	var lbl_perg = Label.new()
	lbl_perg.text = "Enunciado:"
	lbl_perg.custom_minimum_size = Vector2(200, 0)
	hbox_perg.add_child(lbl_perg)
	
	input_pergunta = TextEdit.new()
	input_pergunta.custom_minimum_size = Vector2(600, 100)
	input_pergunta.placeholder_text = "Digite a pergunta aqui..."
	input_pergunta.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	hbox_perg.add_child(input_pergunta)
	
	# Alternativas
	input_a = _criar_campo_alternativa(form_vbox, "A) ")
	input_b = _criar_campo_alternativa(form_vbox, "B) ")
	input_c = _criar_campo_alternativa(form_vbox, "C) ")
	input_d = _criar_campo_alternativa(form_vbox, "D) ")
	input_e = _criar_campo_alternativa(form_vbox, "E) ")
	
	# Resposta Correta
	var hbox_correta = HBoxContainer.new()
	form_vbox.add_child(hbox_correta)
	var lbl_correta = Label.new()
	lbl_correta.text = "Alternativa Correta:"
	lbl_correta.custom_minimum_size = Vector2(200, 0)
	hbox_correta.add_child(lbl_correta)
	
	opt_correta = OptionButton.new()
	opt_correta.add_item("Alternativa A", 0)
	opt_correta.add_item("Alternativa B", 1)
	opt_correta.add_item("Alternativa C", 2)
	opt_correta.add_item("Alternativa D", 3)
	opt_correta.add_item("Alternativa E", 4)
	hbox_correta.add_child(opt_correta)
	
	# Botão Salvar e Status
	var btn_salvar = Button.new()
	btn_salvar.text = " SALVAR NOVA PERGUNTA "
	btn_salvar.custom_minimum_size = Vector2(250, 50)
	btn_salvar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_salvar.pressed.connect(_on_salvar_pressed)
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.1, 0.6, 0.2, 1.0)
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	btn_salvar.add_theme_stylebox_override("normal", btn_style)
	
	var btn_style_hover = btn_style.duplicate()
	btn_style_hover.bg_color = Color(0.15, 0.7, 0.25, 1.0)
	btn_salvar.add_theme_stylebox_override("hover", btn_style_hover)
	
	vbox_principal.add_child(btn_salvar)
	
	lbl_status = Label.new()
	lbl_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_principal.add_child(lbl_status)

func _criar_campo_alternativa(parent: Control, prefixo: String) -> LineEdit:
	var hbox = HBoxContainer.new()
	parent.add_child(hbox)
	
	var lbl = Label.new()
	lbl.text = "Alternativa " + prefixo
	lbl.custom_minimum_size = Vector2(200, 0)
	hbox.add_child(lbl)
	
	var line_edit = LineEdit.new()
	line_edit.custom_minimum_size = Vector2(600, 0)
	line_edit.placeholder_text = "Digite a alternativa..."
	hbox.add_child(line_edit)
	
	return line_edit

func _on_salvar_pressed() -> void:
	if input_pergunta.text.strip_edges().is_empty():
		_mostrar_erro("O enunciado não pode ser vazio!")
		return
	if input_a.text.is_empty() or input_b.text.is_empty() or input_c.text.is_empty() or input_d.text.is_empty() or input_e.text.is_empty():
		_mostrar_erro("Preencha todas as 5 alternativas!")
		return
		
	lbl_status.text = "Salvando no banco de dados..."
	lbl_status.add_theme_color_override("font_color", Color.YELLOW)
	
	var opcoes_array = [
		input_a.text.strip_edges(),
		input_b.text.strip_edges(),
		input_c.text.strip_edges(),
		input_d.text.strip_edges(),
		input_e.text.strip_edges()
	]
	
	var dados_pergunta = {
		"andar_id": opt_disciplina.get_selected_id() + 1,
		"question": input_pergunta.text.strip_edges(),
		"options": opcoes_array,
		"answer": opt_correta.get_selected_id(),
		"nivel_progresso": 1 # Nível padrão
	}
	
	var res = await DatabaseManager.request_async("/rest/v1/perguntas", HTTPClient.METHOD_POST, dados_pergunta)
	
	if res["success"]:
		lbl_status.text = "SUCESSO! Pergunta adicionada ao banco."
		lbl_status.add_theme_color_override("font_color", Color.GREEN)
		# Limpar campos
		input_pergunta.text = ""
		input_a.text = ""
		input_b.text = ""
		input_c.text = ""
		input_d.text = ""
		input_e.text = ""
	else:
		_mostrar_erro("Erro ao salvar: " + res.get("message", "Erro desconhecido"))

func _mostrar_erro(msg: String) -> void:
	lbl_status.text = msg
	lbl_status.add_theme_color_override("font_color", Color.RED)

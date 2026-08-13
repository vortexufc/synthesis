extends Area2D

# Textos do pergaminho
@export var titulo_pergaminho: String = "Pergaminho Encontrado"
@export_multiline var paginas: Array[String] = [
	"Página 1 do pergaminho...",
	"Página 2 do pergaminho..."
]

@export var eh_pergaminho_de_dicas: bool = true

var player_perto: bool = false
var player_ref: Node2D = null
var canvas_prompt: CanvasLayer = null
var panel_prompt: PanelContainer = null

signal dicas_geradas
var _gerando_dicas: bool = false

var _tween_brilho: Tween
var _tween_glow: Tween
var _tween_bob: Tween

func _ready() -> void:
	body_entered.connect(_quando_corpo_entra)
	body_exited.connect(_quando_corpo_sai)
	_iniciar_efeito_brilho()

func _iniciar_efeito_brilho() -> void:
	var sprite: Sprite2D = get_node_or_null("PergaminhoSprite") as Sprite2D
	if sprite == null:
		sprite = get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		for child in get_children():
			if child is Sprite2D and child.name != "GlowSprite":
				sprite = child as Sprite2D
				break
				
	var glow: Sprite2D = get_node_or_null("GlowSprite") as Sprite2D
	if glow == null:
		glow = Sprite2D.new()
		glow.name = "GlowSprite"
		var tex_glow = load("res://assets/sprites/ui/glow_yellow.png") as Texture2D
		if tex_glow:
			glow.texture = tex_glow
			glow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			add_child(glow)
			move_child(glow, 0)
			
	if glow:
		glow.modulate = Color(1.0, 0.9, 0.3, 0.5)
		_tween_glow = create_tween().set_loops()
		_tween_glow.tween_property(glow, "modulate:a", 0.85, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween_glow.tween_property(glow, "modulate:a", 0.35, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
	if sprite:
		_tween_brilho = create_tween().set_loops()
		_tween_brilho.tween_property(sprite, "modulate", Color(1.7, 1.45, 0.35, 1.0), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween_brilho.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		var pos_y = sprite.position.y
		_tween_bob = create_tween().set_loops()
		_tween_bob.tween_property(sprite, "position:y", pos_y - 3.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween_bob.tween_property(sprite, "position:y", pos_y + 3.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _gerar_dicas_dinamicas() -> void:
	if not eh_pergaminho_de_dicas: return
	if not get_node_or_null("/root/QuizManager"): return
	
	_gerando_dicas = true
	var q_manager = get_node("/root/QuizManager")
	
	# Verifica em qual andar estamos baseado no nome da cena
	if get_tree() and get_tree().current_scene:
		var current_scene_path = get_tree().current_scene.scene_file_path.to_lower()
		var andar_correto = q_manager.get("_andar_atual")
		
		if "quimica" in current_scene_path:
			andar_correto = 1
		elif "fisica" in current_scene_path:
			andar_correto = 2
		elif "biologia" in current_scene_path:
			andar_correto = 3
			
		# Se estivermos testando uma sala (F6) e o QuizManager estiver com o andar errado, forçamos a troca
		if q_manager.get("_andar_atual") != andar_correto:
			q_manager.set("_andar_atual", andar_correto)
			q_manager.set("questions", [])
			q_manager.set("shuffled_questions", [])
			if get_node_or_null("/root/DatabaseManager"):
				DatabaseManager.puxar_perguntas(andar_correto)
	
	# Se o QuizManager ainda estiver baixando do banco, esperamos ele terminar (máximo de 5 segundos pra não travar)
	var tempo_espera = 0.0
	while typeof(q_manager.get("questions")) == TYPE_ARRAY and q_manager.get("questions").size() == 0 and tempo_espera < 5.0:
		await get_tree().create_timer(0.5).timeout
		tempo_espera += 0.5
	
	# Se as perguntas ainda não foram preparadas para esta sala, força a preparação
	if q_manager.has_method("reset_questions"):
		var precisa_sortear = false
		var current_shuffled = q_manager.get("shuffled_questions")
		if typeof(current_shuffled) != TYPE_ARRAY or current_shuffled.size() == 0:
			precisa_sortear = true
			
		var sala_atual = ""
		if get_tree() and get_tree().current_scene:
			sala_atual = get_tree().current_scene.scene_file_path
		
		# Se o pergaminho estiver numa sala nova que ainda não sorteou as questões, a gente força o sorteio!
		if q_manager.get("ultima_sala_sorteada") != sala_atual:
			precisa_sortear = true
			
		if precisa_sortear:
			q_manager.reset_questions()
			
	var sorteados = q_manager.get("shuffled_questions")
	
	if typeof(sorteados) == TYPE_ARRAY and sorteados.size() > 0:
		var novas_paginas: Array[String] = []
		var max_dicas = 4
		
		# Pega as primeiras perguntas sorteadas que o jogador vai enfrentar
		for i in range(min(max_dicas, sorteados.size())):
			var q = sorteados[i]
			var pergunta_texto = q.get("question", "")
			
			# Tenta buscar a coluna "dica" ou "explicacao" do banco de dados primeiro (Supabase)
			var dica = q.get("dica", "")
			if dica == "" or dica == null:
				dica = q.get("explicacao", "")
			
			# Se não vier nada do Supabase, tenta resgatar a dica que a IA salvou no arquivo JSON local!
			if dica == "" or dica == null:
				var file = FileAccess.open("res://data/questions.json", FileAccess.READ)
				if file:
					var local_data = JSON.parse_string(file.get_as_text())
					if typeof(local_data) == TYPE_ARRAY:
						for local_q in local_data:
							if str(local_q.get("id")) == str(q.get("id")):
								var local_dica = local_q.get("dica", "")
								if local_dica != "":
									dica = local_dica
									break
			
			# Se não tiver dica no banco nem no JSON local, usamos um fallback visual provisório
			if dica == "" or dica == null:
				var preview = pergunta_texto.substr(0, 45) + "..." if pergunta_texto.length() > 45 else pergunta_texto
				dica = "Estude com atenção o seguinte tema:\n'%s'\n\n(Dica ainda não gerada pela IA no banco de dados!)" % preview
				
			var texto_dica = "FRAGMENTO DE SABEDORIA %d:\n\n" % (i + 1)
			texto_dica += dica
			
			novas_paginas.append(texto_dica)
			
		if novas_paginas.size() > 0:
			paginas = novas_paginas
			
	_gerando_dicas = false
	dicas_geradas.emit()

func _exit_tree() -> void:
	_remover_prompt_tela()

func _exibir_prompt_tela() -> void:
	if canvas_prompt and is_instance_valid(canvas_prompt):
		return
		
	canvas_prompt = CanvasLayer.new()
	canvas_prompt.name = "PromptColetaPergaminho"
	add_child(canvas_prompt)
	
	panel_prompt = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.90) # Escuro translúcido arcano
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.set_content_margin_all(10)
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_color = Color(0.95, 0.80, 0.25, 0.95) # Borda dourada brilhante
	
	panel_prompt.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = "Pressione [F] para Coletar o Pergaminho"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var font_pixel = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	if font_pixel:
		label.add_theme_font_override("font", font_pixel)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7)) # Amarelo ouro
	
	panel_prompt.add_child(label)
	panel_prompt.custom_minimum_size = Vector2(460, 50)
	canvas_prompt.add_child(panel_prompt)
	
	# Posiciona centralizado no rodapé da tela (mesmo padrão das portas)
	panel_prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel_prompt.offset_top = -130
	panel_prompt.offset_bottom = -80
	panel_prompt.offset_left = 320
	panel_prompt.offset_right = -320

func _remover_prompt_tela() -> void:
	if canvas_prompt and is_instance_valid(canvas_prompt):
		canvas_prompt.queue_free()
		canvas_prompt = null
		panel_prompt = null

func _quando_corpo_entra(corpo: Node2D) -> void:
	if not corpo.is_in_group("player") and corpo.name != "Player":
		return
	player_perto = true
	player_ref = corpo
	_exibir_prompt_tela()
	
	# Ao invés de tentar gerar no início da sala (o que pode bugar o F6 rápido), gera quando o player chegar perto!
	_gerar_dicas_dinamicas()

func _quando_corpo_sai(corpo: Node2D) -> void:
	if corpo == player_ref or corpo.is_in_group("player") or corpo.name == "Player":
		player_perto = false
		player_ref = null
		_remover_prompt_tela()

func _unhandled_input(event: InputEvent) -> void:
	if not player_perto:
		return
		
	var pressionou_f = (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F)
	if pressionou_f or event.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled()
		coletar()

func coletar() -> void:
	# Se o jogador for ninja e apertar F antes de terminar de carregar as questões, a gente aguarda
	if _gerando_dicas:
		await dicas_geradas
		
	_remover_prompt_tela()
		
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui-1")

	# Salva no Inventário
	if get_node_or_null("/root/PlayerStats"):
		PlayerStats.adicionar_pergaminho(titulo_pergaminho, paginas)

	# Abre o pergaminho na tela dinamicamente ao coletar com a tecla F
	var ui = get_tree().get_first_node_in_group("parchment_ui")
	if ui == null and get_tree().current_scene:
		ui = get_tree().current_scene.find_child("ParchmentUI", true, false)

	if ui and ui.has_method("abrir_pergaminho"):
		ui.abrir_pergaminho(paginas, player_ref)

	# Remove o pergaminho do mapa
	queue_free()







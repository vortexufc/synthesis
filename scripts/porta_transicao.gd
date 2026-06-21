extends Area2D

@export var proxima_cena: String = ""
@export var porta_de_retorno: bool = false

# Cooldown para evitar teletransporte imediato ao carregar a cena (loop infinito)
var _cooldown_ativo: bool = true

func _ready() -> void:
	add_to_group("porta_transicao")
	body_entered.connect(_on_body_entered)
	
	# Aguarda antes de ativar a porta
	await get_tree().create_timer(0.6).timeout
	_cooldown_ativo = false
	
	# Após o cooldown, verifica se o player já está dentro da área
	# (necessário se o player spawnou dentro da zona de colisão)
	for body in get_overlapping_bodies():
		if body.name == "Player":
			_on_body_entered(body)
			break

func _tem_inimigos_vivos() -> bool:
	var inimigos = get_tree().get_nodes_in_group("inimigos")
	for inimigo in inimigos:
		if is_instance_valid(inimigo) and not inimigo.is_queued_for_deletion():
			return true
	return false

func _mostrar_feedback_bloqueio() -> void:
	# Evita acumular múltiplas mensagens se o jogador ficar colidindo repetidamente
	if get_node_or_null("FeedbackMensagem"):
		return
		
	var canvas = CanvasLayer.new()
	canvas.name = "FeedbackMensagem"
	add_child(canvas)
	
	var label = Label.new()
	label.text = "Portão selado! Derrote todos os monstros da sala."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Usar fonte customizada PixelifySans do projeto
	var font = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	if font:
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", 16)
	
	# Usar painel com estilo premium integrado à lore
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 0.85) # Escuro translúcido com toque azulado/arcano
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.set_content_margin_all(10)
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_color = Color(0.85, 0.25, 0.25, 0.9) # Vermelho mágico vibrante
	
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(label)
	
	# Dimensões customizadas
	panel.custom_minimum_size = Vector2(400, 45)
	canvas.add_child(panel)
	
	# Posiciona centralizado no meio-inferior (viewport: 1280x720)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -130
	panel.offset_bottom = -80
	panel.offset_left = 340
	panel.offset_right = -340
	
	# Efeito de Fade In / Intervalo / Fade Out usando Tween do Godot 4
	panel.modulate.a = 0.0
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	tween.tween_interval(1.8)
	tween.tween_property(panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(canvas.queue_free)

func _on_body_entered(body: Node2D) -> void:
	if _cooldown_ativo:
		return
		
	if body.name == "Player":
		if _tem_inimigos_vivos():
			_mostrar_feedback_bloqueio()
			return
			
		var cena_alvo = proxima_cena
		
		# SEMPRE marca se o jogador acabou de usar uma porta de retorno
		if get_node_or_null("/root/DungeonGenerator"):
			DungeonGenerator.vindo_de_porta_de_retorno = porta_de_retorno
		
		# Se nenhuma cena foi definida no Editor, puxa do Gerador de Masmorra
		if cena_alvo == "" and get_node_or_null("/root/DungeonGenerator"):
			var arquivo_sala = get_tree().current_scene.scene_file_path
			
			if porta_de_retorno:
				cena_alvo = DungeonGenerator.get_sala_anterior(arquivo_sala)
			else:
				cena_alvo = DungeonGenerator.get_proxima_sala(arquivo_sala)
		
		print("[PortaTransicao] porta_de_retorno=", porta_de_retorno, " | Indo para: ", cena_alvo)
			
		if cena_alvo != "":
			_cooldown_ativo = true  # Evita duplo disparo
			TransitionScreen.change_scene(cena_alvo)

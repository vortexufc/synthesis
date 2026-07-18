extends Area2D

@export_category("Configurações de Rota")
@export var proxima_cena: String = ""
@export var porta_de_retorno: bool = false

@export_category("Configurações do Hub")
@export var is_hub_door: bool = false
@export var hub_dungeon_name: String = "" # Ex: "Química"
@export var textura_porta: Texture2D

@export var esta_trancada: bool = false
@export var mensagem_customizada: String = ""

@export_category("Animação de Região (Spritesheet de Cenário)")
@export var frames_animacao: int = 1
@export var stride_animacao: int = 0

var _sprite_porta: Sprite2D = null
var _aguardando_confirmacao: bool = false
var _base_region_rect: Rect2

# Cooldown para evitar teletransporte imediato ao carregar a cena (loop infinito)
var _cooldown_ativo: bool = true

func _ready() -> void:
	add_to_group("porta_transicao")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	_sprite_porta = get_node_or_null("SpritePorta")
	if _sprite_porta and _sprite_porta.region_enabled:
		_base_region_rect = _sprite_porta.region_rect
		
	if not _sprite_porta and textura_porta:
		_sprite_porta = Sprite2D.new()
		_sprite_porta.texture = textura_porta
		if textura_porta.get_width() > 100:
			_sprite_porta.hframes = int(textura_porta.get_width() / 32)
			_sprite_porta.frame = 0 # Porta fechada
		# Posiciona o sprite ajustando para o centro da colisão
		_sprite_porta.position = Vector2(0, -16) 
		_sprite_porta.scale = Vector2(3, 3) # As texturas do hub costumam ser ampliadas
		add_child(_sprite_porta)
	
	# Aguarda antes de ativar a porta
	await get_tree().create_timer(0.6).timeout
	_cooldown_ativo = false
	
	# Após o cooldown, verifica se o player já está dentro da área
	for body in get_overlapping_bodies():
		if body.is_in_group("player") or body.name == "Player" or body.name.begins_with("Player"):
			_on_body_entered(body)
			break

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		_fechar_prompt_hub()

func _tem_inimigos_vivos() -> bool:
	var inimigos = get_tree().get_nodes_in_group("inimigos")
	for inimigo in inimigos:
		if is_instance_valid(inimigo) and not inimigo.is_queued_for_deletion():
			return true
	return false

# Agora a função aceita Texto e Cor de Borda dinamicamente!
func _mostrar_feedback_hub(mensagem: String, cor_borda: Color) -> void:
	# Evita acumular múltiplas mensagens se o jogador ficar colidindo repetidamente
	if get_node_or_null("FeedbackMensagem"):
		return
		
	var canvas = CanvasLayer.new()
	canvas.name = "FeedbackMensagem"
	add_child(canvas)
	
	var label = Label.new()
	label.text = mensagem
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
	style.bg_color = Color(0.08, 0.08, 0.1, 0.85) # Escuro translúcido arcano
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.set_content_margin_all(10)
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_color = cor_borda # Cor injetada dinamicamente
	
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
	
	# Efeito de Fade In / Intervalo / Fade Out usando Tween
	panel.modulate.a = 0.0
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	tween.tween_interval(1.8)
	tween.tween_property(panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(canvas.queue_free)

func _abrir_porta_animacao() -> void:
	if _sprite_porta:
		if _sprite_porta.hframes > 1:
			for i in range(_sprite_porta.hframes):
				_sprite_porta.frame = i
				await get_tree().create_timer(0.15).timeout
		elif _sprite_porta.region_enabled and frames_animacao > 1 and stride_animacao > 0:
			for i in range(frames_animacao):
				var new_rect = _base_region_rect
				new_rect.position.x = _base_region_rect.position.x + (i * stride_animacao)
				_sprite_porta.region_rect = new_rect
				await get_tree().create_timer(0.15).timeout

func _fechar_porta_animacao() -> void:
	if _sprite_porta:
		if _sprite_porta.hframes > 1:
			for i in range(_sprite_porta.hframes - 1, -1, -1):
				_sprite_porta.frame = i
				await get_tree().create_timer(0.15).timeout
		elif _sprite_porta.region_enabled and frames_animacao > 1 and stride_animacao > 0:
			for i in range(frames_animacao - 1, -1, -1):
				var new_rect = _base_region_rect
				new_rect.position.x = _base_region_rect.position.x + (i * stride_animacao)
				_sprite_porta.region_rect = new_rect
				await get_tree().create_timer(0.15).timeout

func _fechar_prompt_hub() -> void:
	_aguardando_confirmacao = false
	var prompt = get_node_or_null("PromptHub")
	if prompt:
		prompt.queue_free()

func _mostrar_prompt_hub() -> void:
	if get_node_or_null("PromptHub") or _aguardando_confirmacao:
		return
		
	_aguardando_confirmacao = true
	var canvas = CanvasLayer.new()
	canvas.name = "PromptHub"
	add_child(canvas)
	
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 0.95)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.8, 0.8, 0.2, 0.9)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var label = Label.new()
	if DatabaseManager.active_dungeon == hub_dungeon_name:
		label.text = "Deseja continuar o andar de " + hub_dungeon_name + "?"
	else:
		label.text = "Deseja começar o andar de " + hub_dungeon_name + "?"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var font = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	if font: label.add_theme_font_override("font", font)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	
	var btn_sim = Button.new()
	btn_sim.text = "SIM"
	if font: btn_sim.add_theme_font_override("font", font)
	btn_sim.pressed.connect(func():
		_aguardando_confirmacao = false
		canvas.queue_free()
		
		if hub_dungeon_name == "Biologia":
			_aguardando_confirmacao = true # Mantém travado enquanto anima
			await _abrir_porta_animacao()
			_mostrar_feedback_hub("Em desenvolvimento!", Color(0.8, 0.2, 0.2, 0.9))
			await get_tree().create_timer(1.2).timeout
			await _fechar_porta_animacao()
			_aguardando_confirmacao = false
			_cooldown_ativo = false
			return
			
		# Salvar a escolha do jogador localmente na conta
		DatabaseManager.active_dungeon = hub_dungeon_name
		if DatabaseManager.has_method("salvar_progresso"):
			DatabaseManager.salvar_progresso()
		_transacionar_porta()
	)
	
	var btn_nao = Button.new()
	btn_nao.text = "NÃO"
	if font: btn_nao.add_theme_font_override("font", font)
	btn_nao.pressed.connect(func():
		_fechar_prompt_hub()
	)
	
	hbox.add_child(btn_sim)
	hbox.add_child(btn_nao)
	
	vbox.add_child(label)
	vbox.add_child(Control.new()) # spacer
	vbox.add_child(hbox)
	panel.add_child(vbox)
	
	panel.custom_minimum_size = Vector2(350, 100)
	canvas.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

func _transacionar_porta() -> void:
	if _cooldown_ativo: return
	_cooldown_ativo = true
	
	await _abrir_porta_animacao()
	
	var cena_alvo = proxima_cena
	if get_node_or_null("/root/DungeonGenerator"):
		DungeonGenerator.vindo_de_porta_de_retorno = porta_de_retorno
	
	if cena_alvo == "" and get_node_or_null("/root/DungeonGenerator"):
		var arquivo_sala = get_tree().current_scene.scene_file_path
		if porta_de_retorno:
			cena_alvo = DungeonGenerator.get_sala_anterior(arquivo_sala)
		else:
			if is_hub_door:
				var d_name = DatabaseManager.active_dungeon
				if d_name == "Química":
					cena_alvo = "res://scenes/Salas/Salas_BuildTGXP/Corredor.tscn"
				elif d_name == "Física":
					cena_alvo = "res://scenes/Salas/Sala_Fisica/Sala_Física01.tscn"
			else:
				cena_alvo = DungeonGenerator.get_proxima_sala(arquivo_sala)
			
		print("[PortaTransicao] Indo para: ", cena_alvo)
			
	if cena_alvo != "":
		# Se tiver mensagem de entrada (Ex: Porta Aberta do Hub)
		if mensagem_customizada != "":
			_mostrar_feedback_hub(mensagem_customizada, Color(0.25, 0.65, 0.85, 0.9)) # Borda Azul
			await get_tree().create_timer(0.4).timeout
			
		TransitionScreen.change_scene(cena_alvo)

func _on_body_entered(body: Node2D) -> void:
	if _cooldown_ativo:
		return
		
	if body.is_in_group("player") or body.name == "Player" or body.name.begins_with("Player"):
		# [DEV TOOL] Verifica se o cheat de ignorar portas trancadas está ativo
		var dev_mgr = get_node_or_null("/root/DevManager")
		var ignorar_bloqueio = dev_mgr and dev_mgr.DEV_MODE_ENABLED and dev_mgr.passar_portas_trancadas

		if not ignorar_bloqueio:
			# REGRA 1: Se a porta for do Hub e estiver marcada como trancada
			if esta_trancada:
				var texto = mensagem_customizada if mensagem_customizada != "" else "TRANCADO"
				_mostrar_feedback_hub(texto, Color(0.85, 0.25, 0.25, 0.9)) # Borda Vermelha
				return
				
			# REGRA 2: Bloqueio antigo por conter inimigos na sala
			if not porta_de_retorno and _tem_inimigos_vivos():
				_mostrar_feedback_hub("Portão selado! Derrote todos os monstros da sala.", Color(0.85, 0.25, 0.25, 0.9))
				return
			
		# Lógica de porta de Hub
		if is_hub_door:
			# TODO: Descomentar isso no futuro para travar o jogador na run atual!
			# var active = DatabaseManager.active_dungeon
			# if active != "" and active != hub_dungeon_name:
			# 	_mostrar_feedback_hub("Você já está explorando " + active + "!", Color(0.85, 0.25, 0.25, 0.9))
			# 	return
			
			_mostrar_prompt_hub()
		else:
			_transacionar_porta()

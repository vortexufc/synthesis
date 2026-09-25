extends Area2D

@export_category("Configurações de Rota")
@export var proxima_cena: String = ""
@export var porta_de_retorno: bool = false

@export_category("Configurações do Hub")
@export var is_hub_door: bool = false
@export var hub_dungeon_name: String = "" # Ex: "Química"
@export var textura_porta: Texture2D

@export_category("Tranca e Chave")
@export var precisa_de_chave: bool = false
@export var esta_trancada: bool = false
@export var mensagem_customizada: String = ""

@export_category("Animação de Região (Spritesheet de Cenário)")
@export var frames_animacao: int = 1
@export var stride_animacao: int = 0

@export_category("Selo Rúnico")
@export var tem_selo_runico: bool = false # minigame de ordenar sequencia
@export_enum("auto", "quimica", "fisica", "geral") var selo_tema: String = "auto"

var _sprite_porta: Sprite2D = null
var _aguardando_confirmacao: bool = false
var _base_region_rect: Rect2
var _porta_aberta: bool = false
var _checagem_timer: float = 0.0

var _chave_usada: bool = false
var _player_no_alcance: bool = false
var _canvas_prompt_chave: CanvasLayer = null
var _panel_prompt_chave: PanelContainer = null
var _label_prompt_chave: Label = null

var _selo_ativo: bool = false
var _selo_resolvido: bool = false
var _minigame_selo_aberto: bool = false
var _indicador_selo_node: Node2D = null
var _tw_indicador_selo: Tween = null

# Cooldown para evitar teletransporte imediato ao carregar a cena (loop infinito)
var _cooldown_ativo: bool = true

func _exit_tree() -> void:
	_remover_prompt_tranca()
	_remover_indicador_selo()

func _ready() -> void:
	add_to_group("porta_transicao")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	var porta_key = _obter_porta_id()
	if get_node_or_null("/root/DungeonGenerator") and DungeonGenerator.is_porta_destrancada(porta_key):
		_chave_usada = true
		_porta_aberta = true
	
	_sprite_porta = get_node_or_null("SpritePorta")
	if _sprite_porta and _sprite_porta.region_enabled:
		_base_region_rect = _sprite_porta.region_rect

	if not _sprite_porta and textura_porta:
		_sprite_porta = Sprite2D.new()
		_sprite_porta.texture = textura_porta
		if textura_porta.get_width() > 100:
			_sprite_porta.hframes = int(float(textura_porta.get_width()) / 32.0)
			_sprite_porta.frame = 0 # Porta fechada
		# Posiciona o sprite ajustando para o centro da colisão
		_sprite_porta.position = Vector2(0, -16) 
		_sprite_porta.scale = Vector2(3, 3) # As texturas do hub costumam ser ampliadas
		add_child(_sprite_porta)
	
	# Aguarda antes de ativar a porta
	await get_tree().create_timer(0.6).timeout
	_cooldown_ativo = false
	
	# Após o cooldown, verifica se o player já está dentro da área
	if is_inside_tree() and monitoring:
		for body in get_overlapping_bodies():
			if body.is_in_group("player") or body.name == "Player" or body.name.begins_with("Player"):
				_on_body_entered(body)
				break

func _player_esta_na_porta() -> bool:
	if _player_no_alcance:
		return true
	if not is_inside_tree() or not monitoring:
		return false
	for body in get_overlapping_bodies():
		if body.is_in_group("player") or body.name == "Player" or body.name.begins_with("Player"):
			_player_no_alcance = true
			return true
	return false

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player" or body.name.begins_with("Player"):
		_player_no_alcance = false
		_remover_prompt_tranca()
		if is_hub_door:
			_fechar_prompt_hub()

func _unhandled_input(event: InputEvent) -> void:
	if not _player_esta_na_porta():
		return
		
	var pressionou_f = false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F or event.physical_keycode == KEY_F or event.key_label == KEY_F:
			pressionou_f = true
	if pressionou_f or event.is_action_pressed("interagir"):
		if _sala_requer_chave() and not _chave_usada:
			get_viewport().set_input_as_handled()
			_tentar_abrir_com_chave_f()
		elif tem_selo_runico and not _selo_resolvido and not porta_de_retorno:
			get_viewport().set_input_as_handled()
			_abrir_minigame_selo_runico()

func _process(delta: float) -> void:
	# Apenas portas de avanço em salas de combate precisam abrir automaticamente
	if is_hub_door or porta_de_retorno or _porta_aberta:
		return
		
	# Fazemos a checagem a cada 0.5 segundos para não pesar o processamento
	_checagem_timer += delta
	if _checagem_timer >= 0.5:
		_checagem_timer = 0.0
		
		# Se não houver mais inimigos:
		if not _tem_inimigos_vivos():
			if tem_selo_runico and not _selo_resolvido:
				if not _selo_ativo:
					_ativar_selo_runico()
			elif _sala_requer_chave() and not _chave_usada:
				# apenas mantem o texto atualizado se o jogador estiver encostado
				if _player_no_alcance:
					_atualizar_texto_prompt_tranca()
			else:
				# sem selo e sem chave: abre sozinha
				if not _porta_aberta:
					_porta_aberta = true
					_abrir_porta_animacao()

# checa se essa porta ou a sala atual exige chave para abrir
func _sala_requer_chave() -> bool:
	if porta_de_retorno or is_hub_door:
		return false
	if _is_sala_boss():
		return false
	if _chave_usada:
		return false
	if get_node_or_null("/root/DungeonGenerator") and DungeonGenerator.is_porta_destrancada(_obter_porta_id()):
		return false
	if precisa_de_chave:
		return true
		
	var cena = get_tree().current_scene
	if cena and cena.get("dropar_chave_no_ultimo_monstro") == true:
		return true
		
	var pai = get_parent()
	if pai and pai.get("dropar_chave_no_ultimo_monstro") == true:
		return true
		
	var dono = owner
	if dono and dono.get("dropar_chave_no_ultimo_monstro") == true:
		return true
		
	return false

func _obter_porta_id() -> String:
	var cena_path = get_tree().current_scene.scene_file_path if (get_tree() and get_tree().current_scene) else ""
	return cena_path + "::" + name

# mostra o prompt na tela igual a porta trancada
func _exibir_prompt_tranca() -> void:
	if _canvas_prompt_chave and is_instance_valid(_canvas_prompt_chave):
		_atualizar_texto_prompt_tranca()
		return
		
	_canvas_prompt_chave = CanvasLayer.new()
	_canvas_prompt_chave.name = "PromptPortaTrancada"
	add_child(_canvas_prompt_chave)
	
	_panel_prompt_chave = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.12, 0.90)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.set_content_margin_all(10)
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_color = Color(0.8, 0.8, 0.8, 0.95)
	_panel_prompt_chave.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_prompt_chave.add_theme_stylebox_override("panel", style)
	
	_label_prompt_chave = Label.new()
	_label_prompt_chave.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label_prompt_chave.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_prompt_chave.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var font_pixel = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	if font_pixel:
		_label_prompt_chave.add_theme_font_override("font", font_pixel)
	_label_prompt_chave.add_theme_font_size_override("font_size", 18)
	
	_panel_prompt_chave.add_child(_label_prompt_chave)
	_panel_prompt_chave.custom_minimum_size = Vector2(460, 50)
	_canvas_prompt_chave.add_child(_panel_prompt_chave)
	
	_panel_prompt_chave.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_panel_prompt_chave.offset_top = -130
	_panel_prompt_chave.offset_bottom = -80
	_panel_prompt_chave.offset_left = 320
	_panel_prompt_chave.offset_right = -320
	
	_atualizar_texto_prompt_tranca()

func _atualizar_texto_prompt_tranca() -> void:
	if not _label_prompt_chave or not is_instance_valid(_label_prompt_chave):
		return
		
	var dev_mgr = get_node_or_null("/root/DevManager")
	var ignorar = dev_mgr and dev_mgr.DEV_MODE_ENABLED and dev_mgr.passar_portas_trancadas
	
	var tem_chave = get_node_or_null("/root/PlayerStats") and PlayerStats.chaves > 0
	
	if tem_chave or ignorar:
		_label_prompt_chave.text = "Pressione [F] para Destrancar a Porta"
		_label_prompt_chave.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	else:
		_label_prompt_chave.text = "A porta está trancada. Derrote os monstros para obter a chave."
		_label_prompt_chave.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))

func _remover_prompt_tranca() -> void:
	if _canvas_prompt_chave and is_instance_valid(_canvas_prompt_chave):
		_canvas_prompt_chave.queue_free()
		_canvas_prompt_chave = null
		_panel_prompt_chave = null
		_label_prompt_chave = null

# gasta a chave e abre a porta apenas quando o jogador aperta F
func _tentar_abrir_com_chave_f() -> void:
	var dev_mgr = get_node_or_null("/root/DevManager")
	var ignorar_bloqueio = dev_mgr and dev_mgr.DEV_MODE_ENABLED and dev_mgr.passar_portas_trancadas
	
	var tem_chave = get_node_or_null("/root/PlayerStats") and PlayerStats.chaves > 0
	
	if not tem_chave and not ignorar_bloqueio:
		_atualizar_texto_prompt_tranca()
		return
		
	if tem_chave and not ignorar_bloqueio:
		PlayerStats.chaves = max(0, PlayerStats.chaves - 1)
		if PlayerStats.has_method("salvar"):
			PlayerStats.salvar()
			
	_chave_usada = true
	if get_node_or_null("/root/DungeonGenerator"):
		DungeonGenerator.registrar_porta_destrancada(_obter_porta_id())
		
	_remover_prompt_tranca()
	
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui-1")
		
	_porta_aberta = true
	await _abrir_porta_animacao()
	
	if _player_esta_na_porta():
		_transacionar_porta()

func _ativar_selo_runico() -> void:
	_selo_ativo = true
	_criar_indicador_selo()

func _criar_indicador_selo() -> void:
	if _indicador_selo_node and is_instance_valid(_indicador_selo_node):
		return
		
	_indicador_selo_node = Node2D.new()
	_indicador_selo_node.name = "IndicadorSeloRunico"
	_indicador_selo_node.position = Vector2(0, -48)
	_indicador_selo_node.z_index = 25
	_indicador_selo_node.scale = Vector2.ZERO
	add_child(_indicador_selo_node)
	
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.14, 0.94)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	style.set_border_width_all(1)
	style.border_color = Color(1.0, 0.82, 0.28, 0.95)
	style.shadow_color = Color(0.95, 0.70, 0.15, 0.40)
	style.shadow_size = 10
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)
	
	var lbl_top = Label.new()
	lbl_top.text = "✦ SELO RÚNICO ✦"
	lbl_top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_top.add_theme_font_size_override("font_size", 11)
	lbl_top.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	var font = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	if font: lbl_top.add_theme_font_override("font", font)
	vbox.add_child(lbl_top)
	
	var lbl_bot = Label.new()
	lbl_bot.text = "Decifrar Enigma"
	lbl_bot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_bot.add_theme_font_size_override("font_size", 10)
	lbl_bot.add_theme_color_override("font_color", Color(0.85, 0.90, 0.98))
	if font: lbl_bot.add_theme_font_override("font", font)
	vbox.add_child(lbl_bot)
	
	panel.position = Vector2(-65, -20)
	_indicador_selo_node.add_child(panel)
	
	if _tw_indicador_selo and _tw_indicador_selo.is_valid():
		_tw_indicador_selo.kill()
		
	var tw_pop = _indicador_selo_node.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_pop.tween_property(_indicador_selo_node, "scale", Vector2.ONE, 0.22)
	
	# Efeito de flutuação suave contínuo vinculado diretamente ao node do indicador
	_tw_indicador_selo = _indicador_selo_node.create_tween().set_loops().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tw_indicador_selo.tween_property(_indicador_selo_node, "position:y", -54.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tw_indicador_selo.tween_property(_indicador_selo_node, "position:y", -46.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _remover_indicador_selo() -> void:
	if _tw_indicador_selo and _tw_indicador_selo.is_valid():
		_tw_indicador_selo.kill()
		_tw_indicador_selo = null
	if _indicador_selo_node and is_instance_valid(_indicador_selo_node):
		_indicador_selo_node.queue_free()
		_indicador_selo_node = null

func _abrir_minigame_selo_runico() -> void:
	if _minigame_selo_aberto:
		return
	_minigame_selo_aberto = true
	
	var cena_minigame = load("res://scenes/ui/ordenar_sequencia_ui.tscn")
	if not cena_minigame:
		_minigame_selo_aberto = false
		return
		
	var minigame = cena_minigame.instantiate()
	get_tree().root.add_child(minigame)
	minigame.sequencia_concluida.connect(_on_selo_sequencia_concluido)
	
	var tema = selo_tema
	if tema == "auto" or tema == "":
		var andar = _obter_andar_atual()
		tema = "quimica" if andar == 1 else ("fisica" if andar == 2 else "geral")
		
	minigame.iniciar_minigame(tema)

func _on_selo_sequencia_concluido(sucesso: bool) -> void:
	_minigame_selo_aberto = false
	if sucesso:
		_selo_ativo = false
		_selo_resolvido = true
		_remover_indicador_selo()
		_mostrar_feedback_hub("✦ Selo Rúnico Rompido! O portão se abriu! ✦", Color(1.0, 0.85, 0.25, 0.95))
		
		# se apos romper o selo ainda requerer chave
		if _sala_requer_chave() and not _chave_usada:
			if _player_no_alcance:
				_exibir_prompt_tranca()
			return
			
		_porta_aberta = true
		await _abrir_porta_animacao()
		if _player_no_alcance:
			_transacionar_porta()

func _tem_inimigos_vivos() -> bool:
	var inimigos = get_tree().get_nodes_in_group("inimigos")
	for inimigo in inimigos:
		if is_instance_valid(inimigo) and not inimigo.is_queued_for_deletion():
			return true
	return false

# mostra mensagem de aviso na tela
func _mostrar_feedback_hub(mensagem: String, cor_borda: Color) -> void:
	# evita spam de mensagem se o player ficar encostando
	if get_node_or_null("FeedbackMensagem"):
		return
		
	var canvas = CanvasLayer.new()
	canvas.name = "FeedbackMensagem"
	add_child(canvas)
	
	var label = Label.new()
	label.text = mensagem
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var font = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	if font:
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", 16)
	
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 0.85)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.set_content_margin_all(10)
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_color = cor_borda
	
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
	var e_concluido = false
	if get_node_or_null("/root/PlayerStats") and PlayerStats.get("vinhetas_desbloqueadas") != null:
		var andar_porta = 1
		if hub_dungeon_name == "Física": andar_porta = 2
		elif hub_dungeon_name == "Biologia": andar_porta = 3
		e_concluido = PlayerStats.vinhetas_desbloqueadas.has(andar_porta)
		
	if DatabaseManager.active_dungeon == hub_dungeon_name:
		label.text = "Deseja continuar o andar de " + hub_dungeon_name + "?"
	elif e_concluido:
		label.text = "Andar Concluído!\nDeseja explorar novamente o andar de " + hub_dungeon_name + "?"
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
		
		# Salvar a escolha do jogador localmente na conta
		DatabaseManager.active_dungeon = hub_dungeon_name
		if DatabaseManager.has_method("salvar_progresso"):
			DatabaseManager.salvar_progresso()
		if get_node_or_null("/root/DungeonGenerator"):
			DungeonGenerator.masmorra_retorno_hub = hub_dungeon_name
			DungeonGenerator.resetar_masmorra(hub_dungeon_name)
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
	
	if not _porta_aberta:
		await _abrir_porta_animacao()
	
	var cena_alvo = proxima_cena
	if get_node_or_null("/root/DungeonGenerator"):
		DungeonGenerator.vindo_de_porta_de_retorno = porta_de_retorno
		var s_path = ""
		if get_tree() and get_tree().current_scene:
			s_path = get_tree().current_scene.scene_file_path.to_lower()
		if "biologia" in s_path or "estufa" in s_path:
			DungeonGenerator.masmorra_retorno_hub = "Biologia"
			if get_node_or_null("/root/DatabaseManager"):
				DatabaseManager.active_dungeon = "Biologia"
		elif "fisica" in s_path or "física" in s_path or "oficina" in s_path:
			DungeonGenerator.masmorra_retorno_hub = "Física"
			if get_node_or_null("/root/DatabaseManager"):
				DatabaseManager.active_dungeon = "Física"
		elif "alquimia" in s_path or "quimica" in s_path or "química" in s_path or "laborat" in s_path or "corredor" in s_path:
			DungeonGenerator.masmorra_retorno_hub = "Química"
			if get_node_or_null("/root/DatabaseManager"):
				DatabaseManager.active_dungeon = "Química"
	
	if cena_alvo == "" and get_node_or_null("/root/DungeonGenerator"):
		var arquivo_sala = get_tree().current_scene.scene_file_path
		if porta_de_retorno:
			cena_alvo = DungeonGenerator.get_sala_anterior(arquivo_sala)
		else:
			if is_hub_door:
				var d_name = DatabaseManager.active_dungeon
				if d_name == "Química":
					cena_alvo = "res://scenes/Salas/Laboratório_Alquimia/Corredor_Alquimia.tscn"
				elif d_name == "Física":
					cena_alvo = "res://scenes/Salas/Oficina_Física/Corredor_Física.tscn"
				elif d_name == "Biologia":
					cena_alvo = "res://scenes/Salas/Estufa_Biologia/Corredor_Estufa.tscn"
			else:
				cena_alvo = DungeonGenerator.get_proxima_sala(arquivo_sala)
			
		print("[PortaTransicao] Indo para: ", cena_alvo)
			
	if cena_alvo != "":
		# Sincronizar o índice do percurso no DungeonGenerator para a cena de destino
		if get_node_or_null("/root/DungeonGenerator"):
			DungeonGenerator.sincronizar_cena(cena_alvo)

		# Se tiver mensagem de entrada (Ex: Porta Aberta do Hub)
		if mensagem_customizada != "":
			_mostrar_feedback_hub(mensagem_customizada, Color(0.25, 0.65, 0.85, 0.9)) # Borda Azul
			await get_tree().create_timer(0.4).timeout
			
		TransitionScreen.change_scene(cena_alvo, porta_de_retorno)

func _on_body_entered(body: Node2D) -> void:
	if _cooldown_ativo:
		return
	if get_node_or_null("/root/TransitionScreen") and TransitionScreen.is_transitioning:
		return
	if get_node_or_null("/root/QuizManager") and QuizManager.em_batalha:
		return
		
	if body.is_in_group("player") or body.name == "Player" or body.name.begins_with("Player"):
		_player_no_alcance = true
		
		# cheat de passar portas do dev
		var dev_mgr = get_node_or_null("/root/DevManager")
		var ignorar_bloqueio = dev_mgr and dev_mgr.DEV_MODE_ENABLED and dev_mgr.passar_portas_trancadas

		# sala do boss
		if _is_sala_boss():
			if porta_de_retorno:
				# nao pode voltar na sala do boss
				if not ignorar_bloqueio:
					if _tem_inimigos_vivos():
						_mostrar_feedback_hub("A entrada da arena foi selada! Derrote o Chefe para sobreviver.", Color(0.85, 0.25, 0.25, 0.9))
					else:
						_mostrar_feedback_hub("O caminho de volta desmoronou! Avance pelo portal dimensional do Chefe.", Color(0.85, 0.25, 0.25, 0.9))
					return
			else:
				# saida do boss
				if _tem_inimigos_vivos() and not ignorar_bloqueio:
					_mostrar_feedback_hub("Portão ancestral selado pela aura do Chefe! Derrote o monstro para abrir.", Color(0.85, 0.25, 0.25, 0.9))
					return
				
				# se venceu o boss, vai pra vinheta e volta pro hub
				_cooldown_ativo = true
				set_deferred("monitoring", false)
				var andar_id = _obter_andar_atual()
				_exibir_vinheta_boss(andar_id)
				return

		if not ignorar_bloqueio:
			# se tiver trancada fixa com mensagem customizada
			if esta_trancada and mensagem_customizada != "":
				_mostrar_feedback_hub(mensagem_customizada, Color(0.85, 0.25, 0.25, 0.9))
				return
				
			# bloqueia se ainda tiver monstros vivos
			if not porta_de_retorno and _tem_inimigos_vivos():
				_mostrar_feedback_hub("Portão selado! Derrote todos os monstros da sala.", Color(0.85, 0.25, 0.25, 0.9))
				return
				
			# se tem o minigame do selo runico
			if tem_selo_runico and not _selo_resolvido and not porta_de_retorno:
				_abrir_minigame_selo_runico()
				return
				
			# se precisa de chave para abrir
			if _sala_requer_chave() and not _chave_usada:
				_exibir_prompt_tranca()
				return
				
			# tranca genérica caso esteja marcada como trancada sem chave
			if esta_trancada:
				_mostrar_feedback_hub("TRANCADO", Color(0.85, 0.25, 0.25, 0.9))
				return
			
		# Lógica de porta de Hub (só pode trocar de andar ao finalizar a run atual)
		if is_hub_door:
			var dev_liberado = dev_mgr and dev_mgr.DEV_MODE_ENABLED and dev_mgr.get("liberar_portas_hub") == true
			if not dev_liberado:
				var active = ""
				if get_node_or_null("/root/DatabaseManager"):
					active = DatabaseManager.active_dungeon
				if active != "" and active != hub_dungeon_name:
					_mostrar_feedback_hub("Você já iniciou a expedição em " + active + "!\nConclua o andar para poder trocar de expedição.", Color(0.95, 0.45, 0.25, 0.95))
					return
			
			_mostrar_prompt_hub()
		else:
			_transacionar_porta()

func _is_sala_boss() -> bool:
	var cena_atual = ""
	if get_tree() and get_tree().current_scene:
		cena_atual = get_tree().current_scene.scene_file_path.to_lower()
	if get_node_or_null("/root/DungeonGenerator"):
		if DungeonGenerator.has_method("is_sala_boss") and DungeonGenerator.is_sala_boss(cena_atual):
			return true
	return ("boss" in cena_atual) or ("fisica12" in cena_atual) or ("física12" in cena_atual) or ("biologia04" in cena_atual)

func _obter_andar_atual() -> int:
	var cena_atual = ""
	if get_tree() and get_tree().current_scene:
		cena_atual = get_tree().current_scene.scene_file_path.to_lower()
		
	if "fisica" in cena_atual or "física" in cena_atual:
		return 2
	elif "biologia" in cena_atual:
		return 3
		
	var d_name = ""
	if get_node_or_null("/root/DatabaseManager"):
		d_name = DatabaseManager.active_dungeon.to_lower()
	if "física" in d_name or "fisica" in d_name:
		return 2
	elif "biologia" in d_name:
		return 3
	return 1

func _exibir_vinheta_boss(andar_id: int) -> void:
	if not _porta_aberta:
		await _abrir_porta_animacao()
		
	# Conclui a masmorra ativa, liberando o jogador para escolher o próximo andar no Hub
	if get_node_or_null("/root/DatabaseManager"):
		DatabaseManager.active_dungeon = ""
		if DatabaseManager.has_method("salvar_progresso"):
			DatabaseManager.salvar_progresso()
	if get_node_or_null("/root/DungeonGenerator"):
		DungeonGenerator.masmorra_retorno_hub = ""
		
	var vinheta_cena = load("res://scenes/ui/vinheta_historia.tscn")
	if vinheta_cena:
		var vinheta = vinheta_cena.instantiate()
		get_tree().root.add_child(vinheta)
		vinheta.iniciar_vinheta(andar_id)
	else:
		if get_node_or_null("/root/TransitionScreen"):
			TransitionScreen.change_scene("res://scenes/Salas/Comum/Hub_Geral.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/Salas/Comum/Hub_Geral.tscn")

extends Control

# HUD de Controles Touch / Mobile (Joystick Virtual + Botões de Ação + Pausa)

@onready var joystick_zone = $JoystickZone
@onready var base_circle = $JoystickZone/BaseCircle
@onready var knob = $JoystickZone/BaseCircle/Knob
@onready var btn_interagir = $ActionsContainer/BtnInteragir
@onready var btn_inventario = $ActionsContainer/BtnInventario
@onready var btn_grimorio = $ActionsContainer/BtnGrimorio
@onready var btn_pausa = $PauseContainer/BtnPausa

const RAIO_MAXIMO: float = 55.0
const ZONA_MORTA: float = 8.0

var _touch_id_joystick: int = -1
var _touch_id_interagir: int = -1
var _mouse_arrastando_joystick: bool = false
var _mouse_pressionou_interagir: bool = false
var _joystick_centro: Vector2 = Vector2.ZERO
var _vetor_movimento: Vector2 = Vector2.ZERO

var _interagir_ativo: bool = false
var _ultimo_click_inventario: int = 0
var _ultimo_click_grimorio: int = 0
var _ultimo_click_pausa: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Garante que os containers intermediários não bloqueiem cliques
	if joystick_zone: joystick_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if base_circle: base_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if knob: knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if has_node("ActionsContainer"): $ActionsContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if has_node("PauseContainer"): $PauseContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Centraliza o knob no centro da base
	call_deferred("_atualizar_geometria_joystick")
	
	# Atualiza a posição ao redimensionar a tela (rotação de celular, resize no navegador)
	if get_viewport():
		get_viewport().size_changed.connect(_on_viewport_resized)
	
	# Conexões diretas dos botões de ação (GUI)
	if btn_interagir:
		btn_interagir.button_down.connect(_on_interagir_down)
		btn_interagir.button_up.connect(_on_interagir_up)
		
	if btn_inventario:
		btn_inventario.pressed.connect(_on_inventario_pressed)
		
	if btn_grimorio:
		btn_grimorio.pressed.connect(_on_grimorio_pressed)
		
	if btn_pausa:
		btn_pausa.pressed.connect(_on_pausa_pressed)
		
	# Escuta mudanças no MobileControlsManager
	var mcm = get_node_or_null("/root/MobileControlsManager")
	if mcm:
		mcm.joystick_toggled.connect(_on_joystick_toggled)
		_atualizar_visibilidade(mcm.joystick_habilitado)
	else:
		_atualizar_visibilidade(false)
		
	# Esconde durante batalhas de turno para não atrapalhar o quiz
	GlobalSignals.iniciar_batalha.connect(func(_enemy_data): _esconder_temporario(true))
	GlobalSignals.batalha_encerrada.connect(func(_vitoria: bool): _esconder_temporario(false))

func _on_viewport_resized() -> void:
	call_deferred("_atualizar_geometria_joystick")

func _atualizar_geometria_joystick() -> void:
	if base_circle and knob:
		_joystick_centro = base_circle.global_position + (base_circle.size * 0.5)
		knob.position = (base_circle.size - knob.size) * 0.5

func _atualizar_visibilidade(ativo: bool) -> void:
	visible = ativo
	if not ativo:
		_liberar_joystick()
	else:
		call_deferred("_atualizar_geometria_joystick")

func _esconder_temporario(esconder: bool) -> void:
	if esconder:
		_liberar_joystick()
		visible = false
	else:
		var mcm = get_node_or_null("/root/MobileControlsManager")
		if mcm:
			visible = mcm.joystick_habilitado
			if visible:
				call_deferred("_atualizar_geometria_joystick")

func _on_joystick_toggled(ativo: bool) -> void:
	_atualizar_visibilidade(ativo)

func _process(_delta: float) -> void:
	var bloqueado = GlobalSignals.tem_interacao_ou_minigame_ativo() or _inventario_aberto() or _pausa_aberta()
	if bloqueado:
		if visible:
			_liberar_joystick()
			visible = false
	else:
		var mcm = get_node_or_null("/root/MobileControlsManager")
		var deve_exibir = mcm.joystick_habilitado if mcm else false
		if visible != deve_exibir:
			visible = deve_exibir
			if visible:
				call_deferred("_atualizar_geometria_joystick")

func _inventario_aberto() -> bool:
	var ui_inv = get_tree().get_first_node_in_group("inventario_ui")
	if ui_inv == null:
		var cena = get_tree().current_scene
		if cena:
			ui_inv = cena.find_child("InventarioUI", true, false)
	return ui_inv != null and is_instance_valid(ui_inv) and ui_inv.visible

func _pausa_aberta() -> bool:
	var mpm = get_node_or_null("/root/MenuPausaManager")
	return mpm != null and mpm.get("menu_aberto") == true

func _input(event: InputEvent) -> void:
	if not visible or GlobalSignals.tem_interacao_ou_minigame_ativo() or _inventario_aberto() or _pausa_aberta():
		return
		
	# 1. Mouse no PC
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = event.position
			if event.pressed:
				# Verifica cliques nos botões de ação e pausa
				if btn_interagir and btn_interagir.is_visible_in_tree() and btn_interagir.get_global_rect().has_point(mouse_pos):
					_mouse_pressionou_interagir = true
					_on_interagir_down()
					get_viewport().set_input_as_handled()
					return
				elif btn_inventario and btn_inventario.is_visible_in_tree() and btn_inventario.get_global_rect().has_point(mouse_pos):
					_on_inventario_pressed()
					get_viewport().set_input_as_handled()
					return
				elif btn_grimorio and btn_grimorio.is_visible_in_tree() and btn_grimorio.get_global_rect().has_point(mouse_pos):
					_on_grimorio_pressed()
					get_viewport().set_input_as_handled()
					return
				elif btn_pausa and btn_pausa.is_visible_in_tree() and btn_pausa.get_global_rect().has_point(mouse_pos):
					_on_pausa_pressed()
					get_viewport().set_input_as_handled()
					return
				# Se clicou no quadrante do analógico (lado esquerdo inferior)
				elif mouse_pos.x < get_viewport_rect().size.x * 0.45 and mouse_pos.y > get_viewport_rect().size.y * 0.35:
					_mouse_arrastando_joystick = true
					_processar_arrasto(mouse_pos)
			else:
				if _mouse_pressionou_interagir:
					_mouse_pressionou_interagir = false
					_on_interagir_up()
				if _mouse_arrastando_joystick:
					_mouse_arrastando_joystick = false
					_liberar_joystick()
					
	elif event is InputEventMouseMotion:
		if _mouse_arrastando_joystick:
			_processar_arrasto(event.position)
			
	# 2. Toque em tela (Mobile Touch)
	elif event is InputEventScreenTouch:
		var touch_pos = event.position
		if event.pressed:
			if btn_interagir and btn_interagir.is_visible_in_tree() and btn_interagir.get_global_rect().has_point(touch_pos):
				_touch_id_interagir = event.index
				_on_interagir_down()
				get_viewport().set_input_as_handled()
				return
			elif btn_inventario and btn_inventario.is_visible_in_tree() and btn_inventario.get_global_rect().has_point(touch_pos):
				_on_inventario_pressed()
				get_viewport().set_input_as_handled()
				return
			elif btn_grimorio and btn_grimorio.is_visible_in_tree() and btn_grimorio.get_global_rect().has_point(touch_pos):
				_on_grimorio_pressed()
				get_viewport().set_input_as_handled()
				return
			elif btn_pausa and btn_pausa.is_visible_in_tree() and btn_pausa.get_global_rect().has_point(touch_pos):
				_on_pausa_pressed()
				get_viewport().set_input_as_handled()
				return
			elif _touch_id_joystick == -1 and touch_pos.x < get_viewport_rect().size.x * 0.45 and touch_pos.y > get_viewport_rect().size.y * 0.35:
				_touch_id_joystick = event.index
				_processar_arrasto(touch_pos)
		else:
			if event.index == _touch_id_interagir:
				_touch_id_interagir = -1
				_on_interagir_up()
			elif event.index == _touch_id_joystick:
				_liberar_joystick()
				
	elif event is InputEventScreenDrag:
		if event.index == _touch_id_joystick:
			_processar_arrasto(event.position)

func _processar_arrasto(posicao_toque: Vector2) -> void:
	if base_circle == null or knob == null:
		return
		
	_joystick_centro = base_circle.global_position + (base_circle.size * 0.5)
	var delta_pos = posicao_toque - _joystick_centro
	var dist = delta_pos.length()
	
	if dist > RAIO_MAXIMO:
		delta_pos = delta_pos.normalized() * RAIO_MAXIMO
		
	var knob_centro = (base_circle.size - knob.size) * 0.5
	knob.position = knob_centro + delta_pos
	
	if dist > ZONA_MORTA:
		_vetor_movimento = delta_pos / RAIO_MAXIMO
	else:
		_vetor_movimento = Vector2.ZERO
		
	_aplicar_acoes_movimento(_vetor_movimento)

func _aplicar_acoes_movimento(vec: Vector2) -> void:
	# Horizontal
	if vec.x > 0.2:
		Input.action_press("direita", vec.x)
		Input.action_release("esquerda")
	elif vec.x < -0.2:
		Input.action_press("esquerda", abs(vec.x))
		Input.action_release("direita")
	else:
		Input.action_release("direita")
		Input.action_release("esquerda")
		
	# Vertical
	if vec.y > 0.2:
		Input.action_press("baixo", vec.y)
		Input.action_release("cima")
	elif vec.y < -0.2:
		Input.action_press("cima", abs(vec.y))
		Input.action_release("baixo")
	else:
		Input.action_release("baixo")
		Input.action_release("cima")

func _liberar_joystick() -> void:
	_touch_id_joystick = -1
	_mouse_arrastando_joystick = false
	_vetor_movimento = Vector2.ZERO
	
	Input.action_release("esquerda")
	Input.action_release("direita")
	Input.action_release("cima")
	Input.action_release("baixo")
	
	if base_circle and knob:
		var knob_centro = (base_circle.size - knob.size) * 0.5
		var tw = create_tween().set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
		tw.tween_property(knob, "position", knob_centro, 0.15)

func _on_interagir_down() -> void:
	if _interagir_ativo or GlobalSignals.tem_interacao_ou_minigame_ativo() or _inventario_aberto() or _pausa_aberta():
		return
	_interagir_ativo = true
	
	AudioManager.play_sfx("ui-1")
	if btn_interagir:
		btn_interagir.scale = Vector2(0.92, 0.92)
		
	# 1. Tenta acionar diretamente o objeto interativo próximo (sem disparar múltiplos eventos)
	if _acionar_interacao_direta():
		return
		
	# 2. Se nenhum objeto direto tratou, envia um único evento de tecla F
	var ev_key = InputEventKey.new()
	ev_key.keycode = KEY_F
	ev_key.physical_keycode = KEY_F
	ev_key.pressed = true
	Input.parse_input_event(ev_key)

func _on_interagir_up() -> void:
	if not _interagir_ativo:
		return
	_interagir_ativo = false
	
	if btn_interagir:
		btn_interagir.scale = Vector2.ONE
		
	var ev_key = InputEventKey.new()
	ev_key.keycode = KEY_F
	ev_key.physical_keycode = KEY_F
	ev_key.pressed = false
	Input.parse_input_event(ev_key)

func _acionar_interacao_direta() -> bool:
	if GlobalSignals.tem_interacao_ou_minigame_ativo():
		return false

	# Procura baús abertos ou fechados próximos ao jogador
	var baus = get_tree().get_nodes_in_group("baus")
	for bau in baus:
		if is_instance_valid(bau) and bau.get("player_perto") == true and not bool(bau.get("ja_aberto")):
			if bau.has_method("abrir_bau"):
				bau.abrir_bau()
				return true
				
	var cena = get_tree().current_scene
	if cena == null:
		return false
		
	# Procura por áreas de interação na cena (NPCs, Inscrições/Murais, Portas, Itens)
	var areas = cena.find_children("*", "Area2D", true, false)
	for a in areas:
		if not is_instance_valid(a):
			continue
		if a.get("player_perto") == true:
			# Inscrição Ancestral / Mural da sala
			if a.has_method("examinar_mural"):
				a.examinar_mural()
				return true
			# NPCs com interface de diálogo/quest (Flora, Cientista, Física)
			elif a.has_method("_abrir_interface"):
				a._abrir_interface()
				return true
			# NPC Mercador
			elif a.has_method("_abrir_loja"):
				a._abrir_loja()
				return true
			# Baú sem grupo
			elif a.has_method("abrir_bau") and not bool(a.get("ja_aberto")):
				a.abrir_bau()
				return true
			# Coletáveis
			elif a.has_method("coletar_chave"):
				a.coletar_chave()
				return true
			elif a.has_method("coletar_pergaminho"):
				a.coletar_pergaminho()
				return true
			elif a.has_method("_coletar_pergaminho"):
				a._coletar_pergaminho()
				return true
			elif a.has_method("coletar"):
				a.coletar()
				return true
			# Portas trancadas
			elif a.has_method("tentar_abrir_porta"):
				a.tentar_abrir_porta()
				return true
			elif a.has_method("_iniciar_dialogo"):
				a._iniciar_dialogo()
				return true
			elif a.has_method("_interagir"):
				a._interagir()
				return true
		elif a.get("_player_no_alcance") == true or a.get("player_no_alcance") == true:
			if a.has_method("_sala_requer_chave") and a._sala_requer_chave() and not bool(a.get("_chave_usada")):
				if a.has_method("_tentar_abrir_com_chave_f"):
					a._tentar_abrir_com_chave_f()
					return true
			elif bool(a.get("tem_selo_runico")) and not bool(a.get("_selo_resolvido")):
				if a.has_method("_abrir_minigame_selo_runico"):
					a._abrir_minigame_selo_runico()
					return true
			elif bool(a.get("is_hub_door")) and a.has_method("_mostrar_prompt_hub"):
				a._mostrar_prompt_hub()
				return true
			elif a.has_method("_executar_transicao"):
				a._executar_transicao()
				return true
				
	return false

func _on_inventario_pressed() -> void:
	if GlobalSignals.tem_interacao_ou_minigame_ativo() or _pausa_aberta():
		return
	var agora = Time.get_ticks_msec()
	if agora - _ultimo_click_inventario < 280:
		return
	_ultimo_click_inventario = agora
	
	AudioManager.play_sfx("ui-1")
	if btn_inventario:
		var tw = create_tween()
		tw.tween_property(btn_inventario, "scale", Vector2(0.92, 0.92), 0.08)
		tw.tween_property(btn_inventario, "scale", Vector2.ONE, 0.08)
		
	var ui_inv = get_tree().get_first_node_in_group("inventario_ui")
	if ui_inv == null:
		var cena = get_tree().current_scene
		if cena: ui_inv = cena.find_child("InventarioUI", true, false)
		
	if ui_inv and ui_inv.has_method("_toggle_inventario"):
		# Se já estava aberto na aba Grimório (2), apenas troca para Poções/Mochila (0)
		if ui_inv.visible and ui_inv.get("tab_container") and is_instance_valid(ui_inv.tab_container) and ui_inv.tab_container.current_tab == 2:
			ui_inv.tab_container.current_tab = 0
		else:
			ui_inv._toggle_inventario()
			if ui_inv.visible and ui_inv.get("tab_container") and is_instance_valid(ui_inv.tab_container):
				ui_inv.tab_container.current_tab = 0
	else:
		var ev = InputEventAction.new()
		ev.action = "inventory"
		ev.pressed = true
		Input.parse_input_event(ev)

func _on_grimorio_pressed() -> void:
	if GlobalSignals.tem_interacao_ou_minigame_ativo() or _pausa_aberta():
		return
	var agora = Time.get_ticks_msec()
	if agora - _ultimo_click_grimorio < 280:
		return
	_ultimo_click_grimorio = agora
	
	AudioManager.play_sfx("ui-1")
	if btn_grimorio:
		var tw = create_tween()
		tw.tween_property(btn_grimorio, "scale", Vector2(0.92, 0.92), 0.08)
		tw.tween_property(btn_grimorio, "scale", Vector2.ONE, 0.08)
		
	var ui_inv = get_tree().get_first_node_in_group("inventario_ui")
	if ui_inv == null:
		var cena = get_tree().current_scene
		if cena: ui_inv = cena.find_child("InventarioUI", true, false)
		
	if ui_inv:
		if not ui_inv.visible and ui_inv.has_method("_toggle_inventario"):
			ui_inv._toggle_inventario()
			if ui_inv.get("tab_container") and is_instance_valid(ui_inv.tab_container):
				ui_inv.tab_container.current_tab = 2 # Grimório
		elif ui_inv.visible:
			# Se já estava na mochila, apenas muda de aba para o Grimório
			if ui_inv.get("tab_container") and is_instance_valid(ui_inv.tab_container) and ui_inv.tab_container.current_tab != 2:
				ui_inv.tab_container.current_tab = 2
			else:
				# Se já estava no grimório, fecha
				if ui_inv.has_method("_toggle_inventario"):
					ui_inv._toggle_inventario()

func _on_pausa_pressed() -> void:
	if GlobalSignals.tem_interacao_ou_minigame_ativo() or _inventario_aberto():
		return
	var agora = Time.get_ticks_msec()
	if agora - _ultimo_click_pausa < 280:
		return
	_ultimo_click_pausa = agora
	
	AudioManager.play_sfx("ui_5")
	if btn_pausa:
		var tw = create_tween()
		tw.tween_property(btn_pausa, "scale", Vector2(0.92, 0.92), 0.08)
		tw.tween_property(btn_pausa, "scale", Vector2.ONE, 0.08)
		
	if get_node_or_null("/root/MenuPausaManager"):
		MenuPausaManager._processar_tecla_esc()
		
	var mcm = get_node_or_null("/root/MobileControlsManager")
	if mcm and mcm.has_method("solicitar_tela_cheia_web"):
		mcm.solicitar_tela_cheia_web()

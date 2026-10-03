extends Node

# Gerenciador global dos controles virtuais / touch para dispositivos móveis

signal joystick_toggled(ativo: bool)

var joystick_habilitado: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_detectar_dispositivo_touch()
	_carregar_preferencia()
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node.name == "InterfaceLeitura":
		call_deferred("_limpar_interface_leitura", node)

func _limpar_interface_leitura(node: Node) -> void:
	if is_instance_valid(node):
		for child in node.get_children():
			if child.name != "Fundo":
				child.reparent(node.get_parent())
			else:
				for sub in child.get_children():
					if sub.name != "PapelTextura":
						sub.reparent(node.get_parent())
		node.queue_free()

func _detectar_dispositivo_touch() -> void:
	var eh_mobile_os = OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("android") or OS.has_feature("ios")
	var eh_pc = OS.has_feature("pc") or OS.has_feature("windows") or OS.has_feature("macos") or OS.has_feature("linux")
	var eh_web = OS.has_feature("web")
	
	var eh_touch_web = false
	if eh_web and JavaScriptBridge:
		var res = JavaScriptBridge.eval("('ontouchstart' in window) || (navigator.maxTouchPoints > 0)")
		if res == true:
			eh_touch_web = true
			
	# Em desktop PC nativo (Windows, macOS, Linux), NUNCA ativar controles virtuais por padrão.
	# Jogadores no PC utilizam teclado e mouse.
	if eh_pc and not eh_web:
		joystick_habilitado = false
	elif eh_mobile_os or (eh_web and (eh_mobile_os or eh_touch_web)):
		joystick_habilitado = true
	else:
		joystick_habilitado = false
		
	print("[MobileControlsManager] Plataforma detectada (PC: %s, Mobile: %s, Web: %s) -> Joystick default: %s" % [eh_pc, eh_mobile_os, eh_web, joystick_habilitado])

func _carregar_preferencia() -> void:
	if FileAccess.file_exists("user://controls_pref.json"):
		var f = FileAccess.open("user://controls_pref.json", FileAccess.READ)
		if f:
			var json = JSON.parse_string(f.get_as_text())
			f.close()
			if json is Dictionary and json.has("joystick"):
				joystick_habilitado = bool(json["joystick"])

func _salvar_preferencia() -> void:
	var f = FileAccess.open("user://controls_pref.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"joystick": joystick_habilitado}))
		f.close()

func set_joystick_habilitado(ativo: bool) -> void:
	if joystick_habilitado == ativo:
		return
	joystick_habilitado = ativo
	_salvar_preferencia()
	print("[MobileControlsManager] Joystick virtual alterado para: ", "ATIVADO" if ativo else "DESATIVADO")
	joystick_toggled.emit(ativo)

func solicitar_tela_cheia_web() -> void:
	if OS.has_feature("web") and JavaScriptBridge:
		JavaScriptBridge.eval("window.synthesisRequestFullscreen && window.synthesisRequestFullscreen()")

extends Node

# Gerenciador global dos controles virtuais / touch para dispositivos móveis

signal joystick_toggled(ativo: bool)
signal plataforma_detectada(eh_mobile: bool)

var eh_mobile: bool = false
var eh_pc: bool = false
var eh_web: bool = false
var joystick_habilitado: bool = false
var _preferencia_manual: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_detectar_dispositivo()
	_carregar_preferencia()
	get_tree().node_added.connect(_on_node_added)

func is_mobile() -> bool:
	return eh_mobile

func is_pc() -> bool:
	return eh_pc

func is_web() -> bool:
	return eh_web

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

func _input(event: InputEvent) -> void:
	# Detecção em tempo de execução caso o primeiro toque aconteça após o carregamento inicial
	if not eh_mobile and event is InputEventScreenTouch and event.pressed:
		_marcar_como_mobile()

func _marcar_como_mobile() -> void:
	if not eh_mobile:
		eh_mobile = true
		eh_pc = false
		if not _preferencia_manual and not joystick_habilitado:
			set_joystick_habilitado(true, false)
		plataforma_detectada.emit(true)
		print("[MobileControlsManager] Toque de tela detectado em tempo de execução! Modo Mobile ativado.")

func _detectar_dispositivo() -> void:
	var os_name = OS.get_name().to_lower()
	eh_web = OS.has_feature("web") or os_name == "web"
	
	# 1. Sistemas nativos comprovadamente móveis
	var eh_mobile_nativo = (
		os_name in ["android", "ios"]
		or OS.has_feature("android")
		or OS.has_feature("ios")
		or OS.has_feature("mobile")
	)
	
	# 2. Touchscreen disponível no dispositivo
	var tem_touchscreen = DisplayServer.is_touchscreen_available()
	
	# 3. Navegador Web rodando em aparelho mobile (Android, iPhone, iPad, etc)
	var eh_mobile_web = false
	if eh_web and JavaScriptBridge:
		var js_code = """
		(function() {
			try {
				var ua = (navigator.userAgent || navigator.vendor || window.opera || '').toLowerCase();
				var isMobileUA = /android|iphone|ipad|ipod|blackberry|iemobile|opera mini|mobile|webos|silk|kindle/.test(ua);
				var hasTouch = ('ontouchstart' in window) || (navigator.maxTouchPoints > 0) || (navigator.msMaxTouchPoints > 0);
				var isCoarse = window.matchMedia && (window.matchMedia('(pointer: coarse)').matches || window.matchMedia('(any-pointer: coarse)').matches);
				var isSmallScreen = Math.min(window.screen.width, window.screen.height) <= 950;
				return Boolean(isMobileUA || (hasTouch && (isCoarse || isSmallScreen)));
			} catch(e) {
				return false;
			}
		})()
		"""
		var res = JavaScriptBridge.eval(js_code)
		if res != null:
			eh_mobile_web = bool(res)
			
	# Decisão final de plataforma
	if eh_mobile_nativo or eh_mobile_web:
		eh_mobile = true
		eh_pc = false
	elif (OS.has_feature("pc") or OS.has_feature("windows") or OS.has_feature("macos") or OS.has_feature("linux")) and not eh_web:
		eh_pc = true
		eh_mobile = false
	elif tem_touchscreen and not eh_pc:
		eh_mobile = true
		eh_pc = false
	else:
		# Padrão desktop / PC
		eh_pc = true
		eh_mobile = false
		
	# Configuração padrão do Joystick
	# Em mobile, SEMPRE inicia ativado por padrão.
	# Em PC nativo, inicia desativado para teclado/mouse.
	if eh_mobile:
		joystick_habilitado = true
	else:
		joystick_habilitado = false
		
	print("[MobileControlsManager] Plataforma detectada (Mobile: %s, PC: %s, Web: %s) -> Joystick padrão: %s" % [
		eh_mobile, eh_pc, eh_web, joystick_habilitado
	])
	plataforma_detectada.emit(eh_mobile)

func _carregar_preferencia() -> void:
	if FileAccess.file_exists("user://controls_pref.json"):
		var f = FileAccess.open("user://controls_pref.json", FileAccess.READ)
		if f:
			var json = JSON.parse_string(f.get_as_text())
			f.close()
			if json is Dictionary:
				_preferencia_manual = bool(json.get("manual", false))
				if _preferencia_manual and json.has("joystick"):
					joystick_habilitado = bool(json["joystick"])
				elif eh_mobile:
					# Se está no mobile e nunca desativou manualmente, garante ativado
					joystick_habilitado = true
				elif eh_pc:
					joystick_habilitado = false
					
	# Garante que o estado seja propagado no início
	call_deferred("_notificar_estado_inicial")

func _notificar_estado_inicial() -> void:
	joystick_toggled.emit(joystick_habilitado)

func _salvar_preferencia() -> void:
	var f = FileAccess.open("user://controls_pref.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({
			"joystick": joystick_habilitado,
			"manual": _preferencia_manual
		}))
		f.close()

func set_joystick_habilitado(ativo: bool, manual: bool = true) -> void:
	if manual:
		_preferencia_manual = true
	if joystick_habilitado == ativo:
		_salvar_preferencia()
		return
	joystick_habilitado = ativo
	_salvar_preferencia()
	print("[MobileControlsManager] Joystick virtual alterado para: ", "ATIVADO" if ativo else "DESATIVADO", " (Manual: %s)" % manual)
	joystick_toggled.emit(ativo)

func solicitar_tela_cheia_web() -> void:
	if OS.has_feature("web") and JavaScriptBridge:
		JavaScriptBridge.eval("window.synthesisRequestFullscreen && window.synthesisRequestFullscreen()")

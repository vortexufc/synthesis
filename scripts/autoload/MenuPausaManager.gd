extends Node

## Gerenciador Global de Pausa e Configurações in-game (ESC)
## Permite abrir a tela de configurações em qualquer sala do jogo pressionando ESC,
## pausando a ação e permitindo ajustar áudio, joystick, deslogar ou voltar ao menu principal.

var cena_configuracoes = preload("res://scenes/ui/configuracoes.tscn")
var _canvas_layer: CanvasLayer = null
var _config_instancia: Control = null

var menu_aberto: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_criar_canvas_pausa()

func _criar_canvas_pausa() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.name = "CanvasMenuPausa"
	_canvas_layer.layer = 110 # Camada superior, acima de HUD, Inventário e diálogos
	add_child(_canvas_layer)
	
	_config_instancia = cena_configuracoes.instantiate()
	_config_instancia.visible = false
	_canvas_layer.add_child(_config_instancia)
	
	if _config_instancia.has_method("configurar_modo_in_game"):
		_config_instancia.configurar_modo_in_game(true)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_processar_tecla_esc()

func _processar_tecla_esc() -> void:
	var cena_atual = get_tree().current_scene
	if cena_atual == null:
		return
		
	var caminho_cena = cena_atual.scene_file_path.to_lower()
	
	# Se a tela de pausa já estiver aberta pelo ESC, verifica se há popup de confirmação aberto
	if menu_aberto:
		get_viewport().set_input_as_handled()
		if _config_instancia and is_instance_valid(_config_instancia):
			if _config_instancia.get("popup_confirmacao") and _config_instancia.popup_confirmacao.visible:
				_config_instancia._fechar_confirmacao()
				if get_node_or_null("/root/AudioManager"):
					AudioManager.play_sfx("ui_5")
				return
		fechar_menu()
		return
		
	# Não abre o menu in-game se estivermos nas telas iniciais / autenticação
	if not _eh_cena_de_jogo(caminho_cena):
		return
		
	# 1. Se o Inventário estiver aberto, ESC fecha o inventário primeiro
	var ui_inv = get_tree().get_first_node_in_group("inventario_ui")
	if ui_inv == null:
		ui_inv = cena_atual.find_child("InventarioUI", true, false)
	if ui_inv and ui_inv.visible:
		get_viewport().set_input_as_handled()
		if ui_inv.has_method("_toggle_inventario"):
			ui_inv._toggle_inventario()
		else:
			ui_inv.visible = false
			get_tree().paused = false
		return
		
	# 2. Se um Pergaminho estiver aberto na tela, ESC fecha o pergaminho primeiro
	var ui_pergaminho = get_tree().get_first_node_in_group("parchment_ui")
	if ui_pergaminho == null:
		ui_pergaminho = cena_atual.find_child("ParchmentUI", true, false)
	if ui_pergaminho and ui_pergaminho.visible:
		get_viewport().set_input_as_handled()
		if ui_pergaminho.has_method("_fechar_pergaminho"):
			ui_pergaminho._fechar_pergaminho()
		else:
			ui_pergaminho.visible = false
		return
		
	# 3. Se nenhum modal prioritário estiver aberto, abre a tela de configurações in-game!
	get_viewport().set_input_as_handled()
	abrir_menu()

func _eh_cena_de_jogo(caminho_cena: String) -> bool:
	var p = caminho_cena.to_lower()
	if "main_menu" in p or "login" in p or "cadastro" in p or "auth" in p:
		return false
	if "telaclas" in p or "meucla" in p or "semcla" in p or "popupcriarcla" in p:
		return false
	if "painel_admin" in p or "adicionar_perguntas" in p:
		return false
	if p.ends_with("configuracoes.tscn"):
		return false
	return true

func abrir_menu() -> void:
	if menu_aberto:
		return
		
	menu_aberto = true
	get_tree().paused = true
	
	if _config_instancia == null or not is_instance_valid(_config_instancia):
		_config_instancia = cena_configuracoes.instantiate()
		_canvas_layer.add_child(_config_instancia)
		
	if _config_instancia.has_method("configurar_modo_in_game"):
		_config_instancia.configurar_modo_in_game(true)
		
	_config_instancia.visible = true
	
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui_5")

func fechar_menu() -> void:
	if not menu_aberto:
		return
		
	menu_aberto = false
	if _config_instancia and is_instance_valid(_config_instancia):
		_config_instancia.visible = false
		
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui_5")
		
	get_tree().paused = false

func fechar_menu_sem_som() -> void:
	menu_aberto = false
	if _config_instancia and is_instance_valid(_config_instancia):
		_config_instancia.visible = false
	get_tree().paused = false

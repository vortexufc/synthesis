extends Node

@warning_ignore("unused_signal")
# dados do inimigo: questoes e tempo
signal iniciar_batalha(enemy_data: Dictionary)
@warning_ignore("unused_signal")
signal batalha_encerrada(vitoria: bool)
@warning_ignore("unused_signal")
signal mimico_ativado(player: Node) # quando abre bau falso
@warning_ignore("unused_signal")
signal fim_de_jogo(vitoria: bool, stats: Dictionary)
@warning_ignore("unused_signal")
signal dash_executado(cooldown: float)

func _enter_tree() -> void:
	_configurar_fontes_emoji()

func _ready() -> void:
	_configurar_fontes_emoji()
	Engine.max_fps = 60

func _configurar_fontes_emoji() -> void:
	var emoji_font = load("res://assets/fonts/seguiemj.ttf") as FontFile
	var symbol_font = load("res://assets/fonts/seguisym.ttf") as FontFile
	var fallbacks_list: Array[Font] = []
	if emoji_font: fallbacks_list.append(emoji_font)
	if symbol_font: fallbacks_list.append(symbol_font)
	
	if fallbacks_list.is_empty(): return
	
	var font_pixelify = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as FontFile
	if font_pixelify:
		font_pixelify.fallbacks = fallbacks_list
		
	var font_pressstart = load("res://assets/fonts/PressStart2P-Regular.ttf") as FontFile
	if font_pressstart:
		font_pressstart.fallbacks = fallbacks_list
		
	if ThemeDB.fallback_font:
		ThemeDB.fallback_font.fallbacks = fallbacks_list

func tem_interacao_ou_minigame_ativo() -> bool:
	if not is_inside_tree() or get_tree() == null:
		return false
	if get_node_or_null("/root/QuizManager") and QuizManager.em_batalha:
		return true
	if _tem_no_visivel_no_grupo("minigame_ativo"):
		return true
	if _tem_no_visivel_no_grupo("dialogo_ativo"):
		return true
	if _tem_no_visivel_no_grupo("interacao_ativa"):
		return true
	if _tem_no_visivel_no_grupo("loja_mercador"):
		return true
	if _tem_no_visivel_no_grupo("desafio_memoria"):
		return true
	if _tem_no_visivel_no_grupo("mural_ui"):
		return true
	if _tem_no_visivel_no_grupo("parchment_ui"):
		return true
		
	var root = get_tree().root
	if root:
		var mural = root.find_child("MuralUI", true, false)
		if mural and is_instance_valid(mural) and not mural.is_queued_for_deletion() and mural.visible:
			return true
		var loja = root.find_child("LojaUI", true, false)
		if loja and is_instance_valid(loja) and not loja.is_queued_for_deletion() and loja.visible:
			return true
	var cena = get_tree().current_scene
	if cena:
		var loja_c = cena.find_child("LojaUI", true, false)
		if loja_c and is_instance_valid(loja_c) and not loja_c.is_queued_for_deletion() and loja_c.visible:
			return true
		var prompt_hub = cena.find_child("PromptHub", true, false)
		if prompt_hub and is_instance_valid(prompt_hub) and not prompt_hub.is_queued_for_deletion() and prompt_hub.visible:
			return true
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player and is_instance_valid(player) and player.has_method("esta_em_interacao") and player.esta_em_interacao():
		return true
	return false

func _tem_no_visivel_no_grupo(grupo: String) -> bool:
	if not is_inside_tree() or get_tree() == null:
		return false
	for node in get_tree().get_nodes_in_group(grupo):
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			if node is CanvasLayer:
				if node.visible:
					return true
			elif node is CanvasItem:
				if node.is_visible_in_tree():
					return true
			else:
				return true
	return false


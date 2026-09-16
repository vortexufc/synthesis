extends Node

@warning_ignore("unused_signal")
# [Combat-4] EnemyData: { "num_questoes": int, "duracao_batalha": float }
signal iniciar_batalha(enemy_data: Dictionary)
@warning_ignore("unused_signal")
signal batalha_encerrada(vitoria: bool)
@warning_ignore("unused_signal")
signal mimico_ativado(player: Node) # [Trap-1] Emitido ao interagir com o Bau Falso
@warning_ignore("unused_signal")
signal fim_de_jogo(vitoria: bool, stats: Dictionary)

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

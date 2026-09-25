extends Control

@onready var label_posicao = $HBox/LblPosicao
@onready var icone_medalha = $HBox/IconeMedalha
@onready var icone_mago = $HBox/IconeMago
@onready var label_nome = $HBox/LblNome
@onready var label_score = $HBox/LblScore
@onready var container_insignias = $HBox/ContainerInsignias

var tex_ouro = load("res://assets/sprites/ui/ranking/medalha_ouro.png")
var tex_prata = load("res://assets/sprites/ui/ranking/medalha_prata.png")
var tex_bronze = load("res://assets/sprites/ui/ranking/medalha_bronze.png")
var tex_mago = load("res://assets/sprites/ui/ranking/icone_mago.png")

# Definições visuais e de lore das 3 insígnias elementares dos andares
var defs_insignias = {
	1: {
		"nome": "Química",
		"tag": "ALQ",
		"icone": "🧪",
		"cor": Color(1.0, 0.82, 0.35),
		"cor_bg": Color(0.14, 0.10, 0.22, 0.95),
		"lore_ok": "✦ Insígnia da Alquimia (Química) ✦\nConquistada por dominar as reações e purificar os caldeirões!",
		"lore_lock": "✦ Insígnia da Alquimia ✦\nNão conquistada por este jogador."
	},
	2: {
		"nome": "Física",
		"tag": "FÍS",
		"icone": "⚡",
		"cor": Color(0.35, 0.85, 1.0),
		"cor_bg": Color(0.08, 0.15, 0.26, 0.95),
		"lore_ok": "✦ Insígnia do Relâmpago (Física) ✦\nConquistada por domar as leis da inércia e os relâmpagos de Faraday!",
		"lore_lock": "✦ Insígnia do Relâmpago ✦\nNão conquistada por este jogador."
	},
	3: {
		"nome": "Biologia",
		"tag": "BIO",
		"icone": "🧬",
		"cor": Color(0.45, 1.0, 0.65),
		"cor_bg": Color(0.08, 0.18, 0.12, 0.95),
		"lore_ok": "✦ Insígnia da Vida (Biologia) ✦\nConquistada por desvendar os mistérios celulares e a espiral do DNA!",
		"lore_lock": "✦ Insígnia da Vida ✦\nNão conquistada por este jogador."
	}
}

func _ready():
	_aplicar_visual()

func _aplicar_visual():
	var font = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf")
	
	# tira o fundo pra nao cobrir o painel
	var style_vazio = StyleBoxEmpty.new()
	add_theme_stylebox_override("panel", style_vazio)
	
	# icone do mago
	if tex_mago:
		icone_mago.texture = tex_mago
	
	var font_num = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	
	label_posicao.add_theme_font_override("font", font_num)
	label_score.add_theme_font_override("font", font_num)
	if font:
		label_nome.add_theme_font_override("font", font)

func set_info(posicao: int, nome: String, score: int, eh_cla: bool = false, dados_extras: Dictionary = {}) -> void:
	if not is_node_ready():
		await ready
		
	var nome_exibido = nome
	if not eh_cla:
		var nick_local = ""
		if get_node_or_null("/root/DatabaseManager") and not DatabaseManager.user_nick.is_empty():
			nick_local = DatabaseManager.user_nick
		elif get_node_or_null("/root/RankingManager"):
			nick_local = RankingManager.get_local_nick()
			
		var tem_conta = get_node_or_null("/root/DatabaseManager") and not DatabaseManager.user_token.is_empty()
		if not tem_conta:
			var guest_nick = ""
			if get_node_or_null("/root/RankingManager"):
				guest_nick = RankingManager.get_local_nick()
			if nome == guest_nick or (nome.begins_with("Mago_") and nome == guest_nick):
				nome_exibido = "Você"
				label_nome.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3))
		elif nome == nick_local:
			label_nome.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3))
		
	# preenche os textos
	label_nome.text = nome_exibido
	label_score.text = str(score) + " PTS"
	
	# esconde o capuz e insígnias na aba de clas
	if eh_cla:
		icone_mago.hide()
		if container_insignias:
			container_insignias.hide()
	else:
		icone_mago.show()
		if container_insignias:
			container_insignias.show()
			_atualizar_insignias(nome_exibido, dados_extras)
	
	# alinha o espaco da medalha
	label_posicao.custom_minimum_size.x = 60
	icone_medalha.custom_minimum_size.x = 60
	
	# medalhas do top 3
	if posicao == 1:
		label_posicao.hide()
		icone_medalha.show()
		icone_medalha.texture = tex_ouro
	elif posicao == 2:
		label_posicao.hide()
		icone_medalha.show()
		icone_medalha.texture = tex_prata
	elif posicao == 3:
		label_posicao.hide()
		icone_medalha.show()
		icone_medalha.texture = tex_bronze
	else:
		icone_medalha.hide() # Esconde a área da medalha
		label_posicao.show() # Mostra apenas o texto 4º, 5º...
		label_posicao.text = str(posicao) + "º"

func _atualizar_insignias(nome: String, dados_extras: Dictionary) -> void:
	if not container_insignias:
		return
		
	# limpa insígnias anteriores
	for child in container_insignias.get_children():
		child.queue_free()
		
	var insignias_player = _obter_insignias_player(nome, dados_extras)
	var font = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	
	for andar_id in [1, 2, 3]:
		var info = defs_insignias[andar_id]
		var conquistada = insignias_player.has(andar_id)
		
		var badge = PanelContainer.new()
		badge.custom_minimum_size = Vector2(58, 26)
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		badge.mouse_filter = Control.MOUSE_FILTER_PASS
		
		var sb = StyleBoxFlat.new()
		sb.set_corner_radius_all(6)
		sb.content_margin_left = 6
		sb.content_margin_right = 6
		sb.content_margin_top = 2
		sb.content_margin_bottom = 2
		
		var hbox = HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", 3)
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_child(hbox)
		
		var lbl_ico = Label.new()
		lbl_ico.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_ico.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_ico.add_theme_font_size_override("font_size", 11)
		lbl_ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(lbl_ico)
		
		var lbl_tag = Label.new()
		lbl_tag.text = info["tag"]
		lbl_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if font:
			lbl_tag.add_theme_font_override("font", font)
		lbl_tag.add_theme_font_size_override("font_size", 10)
		lbl_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(lbl_tag)
		
		if conquistada:
			sb.bg_color = info["cor_bg"]
			sb.border_color = info["cor"]
			sb.set_border_width_all(1)
			sb.shadow_color = Color(info["cor"].r, info["cor"].g, info["cor"].b, 0.35)
			sb.shadow_size = 4
			lbl_ico.text = info["icone"]
			lbl_tag.add_theme_color_override("font_color", info["cor"])
			badge.tooltip_text = info["lore_ok"]
		else:
			sb.bg_color = Color(0.05, 0.07, 0.10, 0.45)
			sb.border_color = Color(0.25, 0.28, 0.35, 0.35)
			sb.set_border_width_all(1)
			lbl_ico.text = "🔒"
			lbl_ico.modulate = Color(0.45, 0.5, 0.6, 0.45)
			lbl_tag.add_theme_color_override("font_color", Color(0.38, 0.42, 0.52, 0.45))
			badge.tooltip_text = info["lore_lock"]
			
		badge.add_theme_stylebox_override("panel", sb)
		container_insignias.add_child(badge)

func _obter_insignias_player(nome_player: String, dados: Dictionary) -> Array:
	# 1. Se for o jogador local atual, usa a lista real de vinhetas/insígnias desbloqueadas
	var nick_local = ""
	if get_node_or_null("/root/DatabaseManager") and not DatabaseManager.user_nick.is_empty():
		nick_local = DatabaseManager.user_nick
	elif get_node_or_null("/root/RankingManager"):
		nick_local = RankingManager.get_local_nick()
		
	if (nome_player == nick_local or nome_player == "Você") and get_node_or_null("/root/PlayerStats"):
		return PlayerStats.vinhetas_desbloqueadas.duplicate()
		
	# 2. Se veio lista explícita no dicionário de dados da API
	if dados.has("insignias") and dados["insignias"] is Array and not dados["insignias"].is_empty():
		return dados["insignias"]
		
	# 3. Caso contrário, infere a partir dos scores dos andares ou pontuação total
	var ins: Array = []
	var s_d = int(dados.get("score_diario", 0))   # Química
	var s_s = int(dados.get("score_semanal", 0))  # Física
	var s_m = int(dados.get("score_mensal", 0))   # Biologia
	var total = int(dados.get("score", 0))
	
	if s_d > 0 or total >= 1000:
		ins.append(1) # Química
	if s_s > 0 or total >= 5000:
		ins.append(2) # Física
	if s_m > 0 or total >= 15000:
		ins.append(3) # Biologia
		
	return ins

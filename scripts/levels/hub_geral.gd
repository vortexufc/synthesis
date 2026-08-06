extends Node2D

## Controlador da Cena do Hub Geral
## Executa a cutscene in-game ao clicar em Jogar com iluminação misteriosa, sem duplicatas de nos e transicao ao fechar pergaminho.

@export var titulo_intro: String = "Boas-Vindas à Masmorra Arcana"

@export_multiline var paginas_intro: Array[String] = [
	"Seja bem-vindo, jovem Mago Aprendiz...\n\nVocê acaba de adentrar a lendária Masmorra Arcana. Poucos que ousaram cruzar estes portões conseguiram decifrar as verdades ocultas que selam os andares desta torre.\n\nAqui, a magia não é fruto da mera força bruta — ela é moldada pela razão, pela ciência e pela sabedoria dos antigos.",
	"Três domínios sagrados guardam os segredos deste reino:\n\n🧪 O ANDAR DE ALQUIMIA — Onde a matéria se transmuta em reações puras, pH corrosivo e elixires elementais.\n\n⚡ O ANDAR DE FÍSICA — Onde a gravidade, as forças da dinâmica e a energia regem a ordem do cosmos e operam mecanismos ancestrais.\n\n🌱 O ANDAR DE BIOLOGIA — Onde os mistérios da vida, células e ecossistemas revelam a essência da criação.",
	"Fórmulas esquecidas e anotações valiosas estão espalhadas em pergaminhos pelas salas.\n\nEstude cada enigma, enfrente os Guardiões do Conhecimento e prove que sua mente é a sua arma mais poderosa.\n\nA jornada começou. Que a luz da razão guie seus passos..."
]

var _canvas_iluminacao: CanvasLayer = null
var _overlay_escuro: ColorRect = null
var _node_tochas: TileMapLayer = null

func _ready() -> void:
	if get_node_or_null("/root/DungeonGenerator") and DungeonGenerator.tocar_cutscene_inicial:
		DungeonGenerator.tocar_cutscene_inicial = false
		_aplicar_iluminacao_escura(true)
		call_deferred("_executar_cutscene_inicial")

func _executar_cutscene_inicial() -> void:
	var player = get_node_or_null("Player")
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		
	if player == null:
		return

	# Trava a movimentação do jogador
	player.travado = true
	player.global_position = Vector2(580, 946)
	
	var sprite = player.get_node_or_null("sprite") as AnimatedSprite2D
	if sprite:
		sprite.play("correr_cima")
		
	# 1. Deslocamento vertical para CIMA até Y=710 com passos
	var tween = create_tween().set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(player, "global_position:y", 710.0, 3.0)
	_tocar_passos_cutscene(3.0)
	await tween.finished
	
	# 2. Mudança de direção para a ESQUERDA até a mesa (X=263, Y=710) com passos
	if sprite:
		sprite.play("correr_esquerda")
		
	var tween2 = create_tween().set_trans(Tween.TRANS_LINEAR)
	tween2.tween_property(player, "global_position:x", 263.0, 4.0)
	_tocar_passos_cutscene(4.0)
	await tween2.finished
	
	# 3. Mago para em frente à mesa olhado para CIMA
	if sprite:
		sprite.play("idle_cima")
		
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui-1")
		
	# 4. Remove o pergaminho visual da mesa (pois foi coletado!)
	var pergaminho_mesa = get_node_or_null("PergaminhoMesa")
	if pergaminho_mesa and is_instance_valid(pergaminho_mesa):
		if pergaminho_mesa.has_method("_remover_prompt_tela"):
			pergaminho_mesa._remover_prompt_tela()
		pergaminho_mesa.queue_free()
		
	# 5. Salva no Inventário (Grimório)
	if get_node_or_null("/root/PlayerStats"):
		PlayerStats.adicionar_pergaminho(titulo_intro, paginas_intro, "O pergaminho de introdução entregue ao jovem mago na mesa de alquimia.")

	# 6. Abre a interface do Pergaminho na tela com os textos de lore
	var ui = get_tree().get_first_node_in_group("parchment_ui")
	if ui == null and get_tree().current_scene:
		ui = get_tree().current_scene.find_child("ParchmentUI", true, false)

	if ui and ui.has_method("abrir_pergaminho"):
		if ui.has_signal("pergaminho_fechado"):
			ui.pergaminho_fechado.connect(_restaurar_iluminacao_normal, CONNECT_ONE_SHOT)
		ui.abrir_pergaminho(paginas_intro, player)
	else:
		player.travado = false
		_restaurar_iluminacao_normal()

func _tocar_passos_cutscene(duracao: float) -> void:
	var tempo_decorrido: float = 0.0
	while tempo_decorrido < duracao:
		if get_node_or_null("/root/AudioManager"):
			AudioManager.tocar_som_caminhada()
		await get_tree().create_timer(0.35).timeout
		tempo_decorrido += 0.35

func _aplicar_iluminacao_escura(instantanea: bool = false) -> void:
	if _canvas_iluminacao and is_instance_valid(_canvas_iluminacao):
		return
		
	_canvas_iluminacao = CanvasLayer.new()
	_canvas_iluminacao.name = "IluminacaoCutscene"
	_canvas_iluminacao.layer = 5 # Fica abaixo da HUD/ParchmentUI
	add_child(_canvas_iluminacao)
	
	_overlay_escuro = ColorRect.new()
	_overlay_escuro.name = "OverlayEscuro"
	_overlay_escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay_escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if instantanea:
		_overlay_escuro.color = Color(0.03, 0.03, 0.07, 0.60) # Iluminação misteriosa limpa
	else:
		_overlay_escuro.color = Color(0.03, 0.03, 0.07, 0.0)
		var tween = create_tween().set_trans(Tween.TRANS_SINE)
		tween.tween_property(_overlay_escuro, "color:a", 0.60, 0.9)
		
	_canvas_iluminacao.add_child(_overlay_escuro)
	
	# Altera diretamente a modulacao das tochas originais no propio cenario (sem criar clones/duplicatas)
	_node_tochas = find_child("Tochas", true, false) as TileMapLayer
	if _node_tochas:
		_node_tochas.modulate = Color(2.2, 1.8, 1.2, 1.0)

func _restaurar_iluminacao_normal() -> void:
	if _node_tochas and is_instance_valid(_node_tochas):
		var tween_t = create_tween().set_trans(Tween.TRANS_SINE)
		tween_t.tween_property(_node_tochas, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.8)
		
	if _overlay_escuro and is_instance_valid(_overlay_escuro):
		var tween = create_tween().set_trans(Tween.TRANS_SINE)
		tween.tween_property(_overlay_escuro, "color:a", 0.0, 0.8)
		await tween.finished
		
	if _canvas_iluminacao and is_instance_valid(_canvas_iluminacao):
		_canvas_iluminacao.queue_free()
		_canvas_iluminacao = null
		_overlay_escuro = null
		_node_tochas = null

extends Node2D

## Controlador da Cena do Hub Geral
## Executa a cutscene in-game de introdução quando o jogador clica em Jogar no Menu Principal.

@export var titulo_intro: String = "Boas-Vindas à Masmorra Arcana"

@export_multiline var paginas_intro: Array[String] = [
	"Seja bem-vindo, jovem Mago Aprendiz...\n\nVocê acaba de adentrar a lendária Masmorra Arcana. Poucos que ousaram cruzar estes portões conseguiram decifrar as verdades ocultas que selam os andares desta torre.\n\nAqui, a magia não é fruto da mera força bruta — ela é moldada pela razão, pela ciência e pela sabedoria dos antigos.",
	"Três domínios sagrados guardam os segredos deste reino:\n\n🧪 O ANDAR DE ALQUIMIA — Onde a matéria se transmuta em reações puras, pH corrosivo e elixires elementais.\n\n⚡ O ANDAR DE FÍSICA — Onde a gravidade, as forças da dinâmica e a energia regem a ordem do cosmos e operam mecanismos ancestrais.\n\n🌱 O ANDAR DE BIOLOGIA — Onde os mistérios da vida, células e ecossistemas revelam a essência da criação.",
	"Fórmulas esquecidas e anotações valiosas estão espalhadas em pergaminhos pelas salas.\n\nEstude cada enigma, enfrente os Guardiões do Conhecimento e prove que sua mente é a sua arma mais poderosa.\n\nA jornada começou. Que a luz da razão guie seus passos..."
]

func _ready() -> void:
	if get_node_or_null("/root/DungeonGenerator") and DungeonGenerator.tocar_cutscene_inicial:
		DungeonGenerator.tocar_cutscene_inicial = false
		call_deferred("_executar_cutscene_inicial")

func _executar_cutscene_inicial() -> void:
	var player = get_node_or_null("Player")
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		
	if player == null:
		return

	# Trava a movimentação e os inputs do jogador durante a cena
	player.travado = true
	
	# Ponto inicial do jogador (entrada inferior da sala)
	player.global_position = Vector2(580, 750)
	
	var sprite = player.get_node_or_null("sprite") as AnimatedSprite2D
	if sprite:
		sprite.play("correr_cima")
		
	# 1. Deslocamento vertical para CIMA até a altura da mesa superior (Y: 750 -> 450)
	var tween = create_tween().set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(player, "global_position:y", 450.0, 2.0)
	await tween.finished
	
	# 2. Mudança de direção para a ESQUERDA até a mesa (X: 580 -> 280)
	if sprite:
		sprite.play("correr_esquerda")
		
	var tween2 = create_tween().set_trans(Tween.TRANS_LINEAR)
	tween2.tween_property(player, "global_position:x", 280.0, 1.8)
	await tween2.finished
	
	# 3. Animação Idle em frente à mesa do pergaminho
	if sprite:
		sprite.play("idle_cima")
		
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui-1")
		
	# 4. Salva o pergaminho de introdução no Grimório do jogador
	if get_node_or_null("/root/PlayerStats"):
		PlayerStats.adicionar_pergaminho(titulo_intro, paginas_intro, "Pergaminho com as instruções iniciais da Masmorra Arcana.")

	# 5. Abre a interface do Pergaminho na tela com os textos de lore
	var ui = get_tree().get_first_node_in_group("parchment_ui")
	if ui == null and get_tree().current_scene:
		ui = get_tree().current_scene.find_child("ParchmentUI", true, false)

	if ui and ui.has_method("abrir_pergaminho"):
		ui.abrir_pergaminho(paginas_intro, player)
	else:
		player.travado = false

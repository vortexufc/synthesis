extends Node2D

## Controlador da Cena do Hub Geral
## Executa a cutscene in-game ao clicar em Jogar com iluminação misteriosa, sem duplicatas de nos e transicao ao fechar pergaminho.

@export var titulo_intro: String = "Boas-Vindas à Masmorra Arcana"

@export_multiline var paginas_intro: Array[String] = [
	"Seja bem-vindo, jovem Mago Aprendiz...\n\nVocê acaba de adentrar a lendária Masmorra Arcana. Poucos que ousaram cruzar estes portões conseguiram decifrar as verdades ocultas que selam os andares desta torre.\n\nAqui, a magia não é fruto da mera força bruta — ela é moldada pela razão, pela ciência e pela sabedoria dos antigos.",
	"Três domínios sagrados guardam os segredos deste reino:\n\n🧪 O ANDAR DE ALQUIMIA — Onde a matéria se transmuta em reações puras, pH corrosivo e elixires elementais.\n\n⚡ O ANDAR DE FÍSICA — Onde a gravidade, as forças da dinâmica e a energia regem a ordem do cosmos e operam mecanismos ancestrais.\n\n🌱 O ANDAR DE BIOLOGIA — Onde os mistérios da vida, células e ecossistemas revelam a essência da criação.",
	"Fórmulas esquecidas e anotações valiosas estão espalhadas em pergaminhos pelas salas.\n\nEstude cada enigma, enfrente os Guardiões do Conhecimento e prove que sua mente é a sua arma mais poderosa.\n\nA jornada começou. Que a luz da razão guie seus passos..."
]

var _canvas_modulate: CanvasModulate = null
var _luzes_tochas: Array = []
var _luz_cajado: PointLight2D = null
var _luz_player: PointLight2D = null
var _luz_caldeirao: PointLight2D = null
var _luzes_portais: Array = []
var _luzes_props: Array = []
var _tempo_iluminacao: float = 0.0

func _ready() -> void:
	_configurar_sistema_iluminacao()
	
	if get_node_or_null("/root/DungeonGenerator") and DungeonGenerator.tocar_cutscene_inicial:
		DungeonGenerator.tocar_cutscene_inicial = false
		call_deferred("_executar_cutscene_inicial")

func _obter_textura_luz() -> Texture2D:
	# Gera uma textura radial nativa com decaimento cúbico suave e transparência perfeita
	var grad_tex = GradientTexture2D.new()
	var grad = Gradient.new()
	grad.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CUBIC
	grad.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	grad.colors = PackedColorArray([
		Color(1, 1, 1, 1.0),
		Color(1, 1, 1, 0.4),
		Color(1, 1, 1, 0.0)
	])
	grad_tex.gradient = grad
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(1.0, 0.5)
	grad_tex.width = 256
	grad_tex.height = 256
	return grad_tex

func _configurar_sistema_iluminacao() -> void:
	var tex_luz = _obter_textura_luz()
	
	# 1. CanvasModulate: Cria a escuridão ambiente misteriosa e profunda da masmorra
	_canvas_modulate = CanvasModulate.new()
	_canvas_modulate.name = "AmbienteMasmorra"
	_canvas_modulate.color = Color(0.24, 0.24, 0.35, 1.0) # Tom azul-ardósia escuro da masmorra
	add_child(_canvas_modulate)
	
	# 2. Tochas: Iluminação acolhedora e equilibrada em cada tocha do mapa
	var tochas_layer = find_child("Tochas", true, false) as TileMapLayer
	if tochas_layer:
		var cells = tochas_layer.get_used_cells()
		for cell in cells:
			var local_pos = tochas_layer.map_to_local(cell)
			var pos_global = tochas_layer.to_global(local_pos)
			
			var luz = PointLight2D.new()
			luz.name = "LuzTocha_%d_%d" % [cell.x, cell.y]
			luz.texture = tex_luz
			luz.color = Color(1.0, 0.70, 0.35, 1.0) # Chama quente e alaranjada
			luz.energy = 0.58
			luz.texture_scale = 1.6
			# Alinha a luz com o topo da tocha (onde fica a chama acesa)
			luz.global_position = pos_global + Vector2(0, -18)
			add_child(luz)
			
			_luzes_tochas.append({
				"node": luz,
				"base_energy": 0.58,
				"base_scale": 1.6,
				"offset": randf() * 100.0,
				"speed": randf_range(7.0, 12.0)
			})
	
	# 3. Orbe Mágico do Mago Mercador: Brilho sutil no topo do cajado
	var mercador = find_child("NPCMercador", true, false)
	if mercador:
		_luz_cajado = PointLight2D.new()
		_luz_cajado.name = "LuzCajadoArcano"
		_luz_cajado.texture = tex_luz
		_luz_cajado.color = Color(0.15, 0.70, 1.0, 1.0) # Azul celeste místico
		_luz_cajado.energy = 0.18
		_luz_cajado.texture_scale = 0.35 # Raio compacto apenas no orbe, sem lavar o chão
		_luz_cajado.position = Vector2(46, -58) # Posição exata do orbe no cajado
		mercador.add_child(_luz_cajado)
	
	# 4. Aura do Jogador: Clareia o chão e o ambiente por onde o mago caminha
	var player = find_child("Player", true, false)
	if player:
		_luz_player = PointLight2D.new()
		_luz_player.name = "AuraPlayer"
		_luz_player.texture = tex_luz
		_luz_player.color = Color(1.0, 0.94, 0.82, 1.0) # Luz mágica acolhedora
		_luz_player.energy = 0.34
		_luz_player.texture_scale = 1.65 # Raio amplo para clarear os passos do mago
		_luz_player.position = Vector2(0, -10)
		player.add_child(_luz_player)
	
	# 5. Caldeirão Alquímico e Frascos de Cristais (Bioluminescência Realista)
	var frascos_pos: Array[Vector2] = []
	var pos_caldeirao: Vector2 = Vector2(921, 910)
	
	var decor = find_child("Decoration", true, false) as TileMapLayer
	if decor:
		for cell in decor.get_used_cells():
			var atlas = decor.get_cell_atlas_coords(cell)
			if atlas == Vector2i(40, 20): # Frasco de cristais azuis
				var cell_world = decor.to_global(decor.map_to_local(cell))
				frascos_pos.append(cell_world + Vector2(4, -16))
			elif atlas == Vector2i(91, 20): # Caldeirão borbulhante do Hub
				var cell_world = decor.to_global(decor.map_to_local(cell))
				pos_caldeirao = cell_world + Vector2(-20, -32)
				
	# 5.1. Caldeirão Alquímico: Brilho violeta concentrado na boca borbulhante do caldeirão
	_luz_caldeirao = PointLight2D.new()
	_luz_caldeirao.name = "LuzCaldeirao"
	_luz_caldeirao.texture = tex_luz
	_luz_caldeirao.color = Color(0.84, 0.22, 0.98, 1.0) # Violeta alquímico vivo
	_luz_caldeirao.energy = 0.52
	_luz_caldeirao.texture_scale = 0.50 # Raio compacto focado diretamente na boca do caldeirão
	_luz_caldeirao.global_position = pos_caldeirao
	add_child(_luz_caldeirao)
	
	# 5.2. Frascos de Cristais Arcanos na Mesa de Alquimia (Bioluminescência Ciano/Azul)
	frascos_pos.sort_custom(func(a, b): return a.x < b.x)
	if frascos_pos.size() < 2:
		frascos_pos = [Vector2(195, 665), Vector2(285, 665)]
		
	for i in range(frascos_pos.size()):
		var pos_frasco = frascos_pos[i]
		var luz_frasco = PointLight2D.new()
		luz_frasco.name = "LuzFrascoCristal_%d" % (i + 1)
		luz_frasco.texture = tex_luz
		luz_frasco.color = Color(0.18, 0.88, 1.0, 1.0) # Ciano celestial bioluminescente (idêntico à Sala de Química)
		luz_frasco.energy = 0.40
		luz_frasco.texture_scale = 0.35 # Focado diretamente sobre o vidro do frasco
		luz_frasco.global_position = pos_frasco
		add_child(luz_frasco)
		
		_luzes_props.append({
			"node": luz_frasco,
			"base_energy": 0.40,
			"speed": 1.8 + i * 0.3,
			"offset": i * 1.5
		})
	
	# 6. Luzes temáticas realistas nos Portais das Masmorras
	_criar_luz_portal("PortaTransicao", Color(0.85, 0.38, 1.0, 1.0), Color(0.14, 0.06, 0.20))   # Alquimia - Roxo arcano
	_criar_luz_portal("PortaTransicao3", Color(0.25, 0.78, 1.0, 1.0), Color(0.05, 0.12, 0.22))  # Física - Azul elétrico
	_criar_luz_portal("PortaTransicao2", Color(0.32, 0.95, 0.50, 1.0), Color(0.05, 0.18, 0.09))  # Biologia - Verde vivo

func _criar_luz_portal(nome_porta: String, cor_luz: Color, cor_fundo: Color) -> void:
	var porta = find_child(nome_porta, true, false)
	if not porta:
		return
		
	# 1. Ajusta o fundo interior do portal para refletir sutilmente a dimensão
	var fundo = porta.get_node_or_null("FundoPreto") as ColorRect
	if fundo:
		fundo.color = cor_fundo
		
	# 2. Luz de portal: posicionada na soleira (Y=-25) para banhar o arco e o piso à frente
	var luz = PointLight2D.new()
	luz.name = "LuzPortal_" + nome_porta
	luz.texture = _obter_textura_luz()
	luz.color = cor_luz
	luz.energy = 0.48
	luz.texture_scale = 1.55
	luz.position = Vector2(0, -25)
	porta.add_child(luz)
	
	_luzes_portais.append({
		"node": luz,
		"base_energy": 0.48,
		"offset": randf() * 10.0
	})

func _process(delta: float) -> void:
	_tempo_iluminacao += delta
	
	# 1. Efeito dinâmico de chamas tremeluzindo (flicker suave)
	for tocha in _luzes_tochas:
		var node = tocha["node"] as PointLight2D
		if not node or not is_instance_valid(node):
			continue
		var off = tocha["offset"]
		var spd = tocha["speed"]
		var f1 = sin((_tempo_iluminacao + off) * spd) * 0.03
		var f2 = sin((_tempo_iluminacao + off * 1.7) * (spd * 1.5)) * 0.02
		var flicker = f1 + f2
		node.energy = tocha["base_energy"] + flicker
		node.texture_scale = tocha["base_scale"] + flicker * 0.05
	
	# 2. Pulso mágico sutil do orbe do cajado
	if _luz_cajado and is_instance_valid(_luz_cajado):
		var pulso = sin(_tempo_iluminacao * 2.5) * 0.02
		_luz_cajado.energy = 0.18 + pulso
	
	# 3. Pulso suave da aura de caminhada do mago jogador
	if _luz_player and is_instance_valid(_luz_player):
		var pulso_p = sin(_tempo_iluminacao * 2.0) * 0.02
		_luz_player.energy = 0.34 + pulso_p
	
	# 4. Pulso místico suave dos portais das masmorras
	for portal_info in _luzes_portais:
		var luz_p = portal_info["node"] as PointLight2D
		if luz_p and is_instance_valid(luz_p):
			var off_p = portal_info["offset"]
			var pulso_portal = sin((_tempo_iluminacao + off_p) * 2.2) * 0.04
			luz_p.energy = portal_info["base_energy"] + pulso_portal
			
	# 5. Borbulhar dinâmico no Caldeirão Alquímico do Hub
	if _luz_caldeirao and is_instance_valid(_luz_caldeirao):
		var borbulha = sin(_tempo_iluminacao * 5.5) * 0.06 + sin(_tempo_iluminacao * 9.2) * 0.03
		_luz_caldeirao.energy = 0.52 + borbulha
		_luz_caldeirao.texture_scale = 0.50 + sin(_tempo_iluminacao * 6.0) * 0.02
		
	# 6. Cintilação mágica suave dos frascos de cristais da mesa de alquimia
	for prop in _luzes_props:
		var node = prop["node"] as PointLight2D
		if node and is_instance_valid(node):
			var pulso = sin((_tempo_iluminacao + prop["offset"]) * prop["speed"]) * 0.04
			node.energy = prop["base_energy"] + pulso

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
			ui.pergaminho_fechado.connect(_ao_fechar_pergaminho_cutscene.bind(player), CONNECT_ONE_SHOT)
		ui.abrir_pergaminho(paginas_intro, player)
	else:
		player.travado = false

func _ao_fechar_pergaminho_cutscene(player: Node2D) -> void:
	if player and is_instance_valid(player):
		player.travado = false

func _tocar_passos_cutscene(duracao: float) -> void:
	var tempo_decorrido: float = 0.0
	while tempo_decorrido < duracao:
		if get_node_or_null("/root/AudioManager"):
			AudioManager.tocar_som_caminhada()
		await get_tree().create_timer(0.35).timeout
		tempo_decorrido += 0.35

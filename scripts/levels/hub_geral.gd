extends Node2D

# script da sala principal (hub)

@export var forcar_cutscene_teste: bool = false
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

var _cutscene_em_andamento: bool = false
var _cutscene_tipo: String = "" # "inicial" ou "retorno_vitoria"
var _cutscene_tween: Tween = null
var _cutscene_pular_ui: CanvasLayer = null
var _cutscene_mesa_instancia: CanvasLayer = null
var _ultimo_toque_cutscene_ms: int = 0
const INTERVALO_DUPLO_TOQUE_MS: int = 400

func _ready() -> void:
	if get_node_or_null("/root/AudioManager"):
		AudioManager.start_playlist()

	_configurar_sistema_iluminacao()
	
	var cutscene_ja_vista = false
	if get_node_or_null("/root/PlayerStats") and PlayerStats.cutscene_inicial_vista:
		cutscene_ja_vista = true
		
	var deve_tocar_cutscene = false
	if forcar_cutscene_teste:
		deve_tocar_cutscene = true
	elif get_node_or_null("/root/DungeonGenerator") and DungeonGenerator.tocar_cutscene_inicial:
		if not cutscene_ja_vista:
			deve_tocar_cutscene = true
		DungeonGenerator.tocar_cutscene_inicial = false

	var deve_tocar_vitoria = false
	var andar_vitoria = 1
	if get_node_or_null("/root/DungeonGenerator") and DungeonGenerator.tocar_cutscene_vitoria:
		deve_tocar_vitoria = true
		andar_vitoria = DungeonGenerator.andar_vitoria_concluido
		DungeonGenerator.tocar_cutscene_vitoria = false
		
	if deve_tocar_cutscene:
		call_deferred("_executar_cutscene_inicial")
	elif deve_tocar_vitoria:
		# Se a historinha inicial já foi vista, garante que o pergaminho suma da mesa
		var pergaminho_mesa = get_node_or_null("PergaminhoMesa")
		if pergaminho_mesa and is_instance_valid(pergaminho_mesa):
			pergaminho_mesa.visible = false
			if pergaminho_mesa.has_method("_remover_prompt_tela"):
				pergaminho_mesa._remover_prompt_tela()
			pergaminho_mesa.queue_free()
		call_deferred("_executar_cutscene_retorno_vitoria", andar_vitoria)
	else:
		# Se a cutscene não for tocar, o pergaminho da historinha inicial NUNCA deve ficar na mesa!
		var pergaminho_mesa = get_node_or_null("PergaminhoMesa")
		if pergaminho_mesa and is_instance_valid(pergaminho_mesa):
			pergaminho_mesa.visible = false
			if pergaminho_mesa.has_method("_remover_prompt_tela"):
				pergaminho_mesa._remover_prompt_tela()
			pergaminho_mesa.queue_free()
			
		if get_node_or_null("/root/PlayerStats"):
			PlayerStats.adicionar_pergaminho(titulo_intro, paginas_intro, "O pergaminho de introdução entregue ao jovem mago na mesa de alquimia.")
			if not PlayerStats.cutscene_inicial_vista:
				PlayerStats.marcar_cutscene_inicial_vista()
		
		# Garante que o jogador está destravado para jogar livremente
		var player = get_node_or_null("Player")
		if player == null:
			player = get_tree().get_first_node_in_group("player")
		if player and is_instance_valid(player):
			player.travado = false
			player.em_interacao = false

func _obter_textura_luz() -> Texture2D:
	# cria a textura da luz
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

func _obter_textura_brasa() -> Texture2D:
	var grad_tex = GradientTexture2D.new()
	var grad = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	grad.colors = PackedColorArray([
		Color(1, 1, 1, 1.0),
		Color(1, 1, 1, 0.8),
		Color(1, 1, 1, 0.0)
	])
	grad_tex.gradient = grad
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(0.5, 0.0)
	grad_tex.width = 12
	grad_tex.height = 12
	return grad_tex

func _configurar_sistema_iluminacao() -> void:
	var tex_luz = _obter_textura_luz()
	
	# escurece o hub
	_canvas_modulate = CanvasModulate.new()
	_canvas_modulate.name = "AmbienteMasmorra"
	_canvas_modulate.color = Color(0.24, 0.24, 0.35, 1.0) # Tom azul-ardósia escuro da masmorra
	add_child(_canvas_modulate)
	
	# tochas do mapa
	
	# luz no cajado do mercador
	var mercador = find_child("NPCMercador", true, false)
	if mercador:
		_luz_cajado = PointLight2D.new()
		_luz_cajado.name = "LuzCajadoArcano"
		_luz_cajado.texture = tex_luz
		_luz_cajado.color = Color(0.20, 0.75, 1.0, 1.0) # Azul celeste místico
		_luz_cajado.energy = 0.28
		_luz_cajado.texture_scale = 0.40 # Raio compacto no orbe
		_luz_cajado.position = Vector2(-28, -90) # Posição exata do orbe no novo sprite
		mercador.add_child(_luz_cajado)
		
		var tw_luz = create_tween().set_loops()
		tw_luz.tween_property(_luz_cajado, "energy", 0.40, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw_luz.tween_property(_luz_cajado, "energy", 0.22, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# luz no pe do player
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
	
	# luz no caldeirao e frascos
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
				
	# luz roxa no caldeirao
	_luz_caldeirao = PointLight2D.new()
	_luz_caldeirao.name = "LuzCaldeirao"
	_luz_caldeirao.texture = tex_luz
	_luz_caldeirao.color = Color(0.84, 0.22, 0.98, 1.0) # Violeta alquímico vivo
	_luz_caldeirao.energy = 0.52
	_luz_caldeirao.texture_scale = 0.50 # Raio compacto focado diretamente na boca do caldeirão
	_luz_caldeirao.global_position = pos_caldeirao
	add_child(_luz_caldeirao)
	
	# fumaca e bolhas saindo do caldeirao
	var part_caldeirao = CPUParticles2D.new()
	part_caldeirao.name = "ParticulasCaldeirao"
	part_caldeirao.global_position = pos_caldeirao + Vector2(0, -10)
	part_caldeirao.z_index = 5 # Garante que apareça na frente do caldeirão e do cenário
	
	var mat_caldeirao = CanvasItemMaterial.new()
	mat_caldeirao.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	part_caldeirao.material = mat_caldeirao
	
	var grad_b_tex = Gradient.new()
	grad_b_tex.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	grad_b_tex.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.85), Color(1, 1, 1, 0)])
	var tex_bolha = GradientTexture2D.new()
	tex_bolha.gradient = grad_b_tex
	tex_bolha.width = 16
	tex_bolha.height = 16
	tex_bolha.fill = GradientTexture2D.FILL_RADIAL
	tex_bolha.fill_from = Vector2(0.5, 0.5)
	tex_bolha.fill_to = Vector2(0.5, 0.0)
	part_caldeirao.texture = tex_bolha
	
	part_caldeirao.amount = 18
	part_caldeirao.lifetime = 1.8
	part_caldeirao.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	part_caldeirao.emission_rect_extents = Vector2(18, 6)
	part_caldeirao.direction = Vector2(0, -1)
	part_caldeirao.spread = 28.0
	part_caldeirao.gravity = Vector2(0, -22)
	part_caldeirao.initial_velocity_min = 18.0
	part_caldeirao.initial_velocity_max = 38.0
	part_caldeirao.scale_amount_min = 0.5
	part_caldeirao.scale_amount_max = 1.3
	
	var grad_c = Gradient.new()
	grad_c.colors = PackedColorArray([
		Color(0.85, 0.35, 1.0, 0.95),
		Color(0.40, 0.85, 1.0, 0.85),
		Color(0.60, 0.20, 0.95, 0.0)
	])
	part_caldeirao.color_ramp = grad_c
	add_child(part_caldeirao)
	
	# luz nos frascos da mesa
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
	
	# luzes nos portais dos andares
	_criar_luz_portal("PortaTransicao", Color(0.85, 0.38, 1.0, 1.0), Color(0.14, 0.06, 0.20))   # Alquimia - Roxo arcano
	_criar_luz_portal("PortaTransicao3", Color(0.25, 0.78, 1.0, 1.0), Color(0.05, 0.12, 0.22))  # Física - Azul elétrico
	_criar_luz_portal("PortaTransicao2", Color(0.32, 0.95, 0.50, 1.0), Color(0.05, 0.18, 0.09))  # Biologia - Verde vivo

func _criar_luz_portal(nome_porta: String, cor_luz: Color, cor_fundo: Color) -> void:
	var porta = find_child(nome_porta, true, false)
	if not porta:
		return
		
	# cor do fundo do portal
	var fundo = porta.get_node_or_null("FundoPreto") as ColorRect
	if fundo:
		fundo.color = cor_fundo
		
	# luz do chao do portal
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

var _tempo_luz_tick: float = 0.0

func _process(delta: float) -> void:
	_tempo_luz_tick += delta
	if _tempo_luz_tick < 0.033:
		return
	var dt = _tempo_luz_tick
	_tempo_luz_tick = 0.0
	_tempo_iluminacao += dt
	
	# efeito orgânico de chama nas tochas (três frequências harmônicas)
	for tocha in _luzes_tochas:
		var node = tocha["node"] as PointLight2D
		if not node or not is_instance_valid(node):
			continue
		var off = tocha["offset"]
		var spd = tocha["speed"]
		var f1 = sin((_tempo_iluminacao + off) * spd) * 0.045
		var f2 = sin((_tempo_iluminacao + off * 1.63) * (spd * 1.85)) * 0.024
		var f3 = sin((_tempo_iluminacao + off * 2.41) * (spd * 3.1)) * 0.015
		var flicker = f1 + f2 + f3
		node.energy = maxf(0.25, tocha["base_energy"] + flicker)
		node.texture_scale = 1.35 * (1.0 + flicker * 0.30)
	
	# pulso da luz do cajado
	if _luz_cajado and is_instance_valid(_luz_cajado):
		var pulso = sin(_tempo_iluminacao * 2.5) * 0.025
		_luz_cajado.energy = 0.18 + pulso
		_luz_cajado.texture_scale = 0.40 + (pulso * 0.4)
	
	# pulso de luz do player
	if _luz_player and is_instance_valid(_luz_player):
		var pulso_p = sin(_tempo_iluminacao * 2.0) * 0.025
		_luz_player.energy = 0.34 + pulso_p
	
	# respiração cósmica e expansão de raio dos portais
	for portal_info in _luzes_portais:
		var luz_p = portal_info["node"] as PointLight2D
		if luz_p and is_instance_valid(luz_p):
			var off_p = portal_info["offset"]
			var pulso_portal = sin((_tempo_iluminacao + off_p) * 2.4) * 0.065 + sin((_tempo_iluminacao + off_p * 1.5) * 4.2) * 0.025
			luz_p.energy = maxf(0.3, portal_info["base_energy"] + pulso_portal)
			luz_p.texture_scale = 1.55 + (pulso_portal * 0.6)
			
	# bolhas no caldeirao
	if _luz_caldeirao and is_instance_valid(_luz_caldeirao):
		var borbulha = sin(_tempo_iluminacao * 5.5) * 0.06 + sin(_tempo_iluminacao * 9.2) * 0.03
		_luz_caldeirao.energy = 0.52 + borbulha
		
	# pisca a luz dos frascos
	for prop in _luzes_props:
		var node = prop["node"] as PointLight2D
		if node and is_instance_valid(node):
			var pulso = sin((_tempo_iluminacao + prop["offset"]) * prop["speed"]) * 0.04
			node.energy = prop["base_energy"] + pulso

func _input(event: InputEvent) -> void:
	if not _cutscene_em_andamento:
		return
		
	# Teclado / PC: ESPAÇO ou ui_select pula direto
	if event.is_action_pressed("ui_select") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
		get_viewport().set_input_as_handled()
		_pular_cutscene_atual()
		return
		
	# Mobile / Touch / Clique: duplo toque
	var eh_toque = false
	if event is InputEventScreenTouch and event.pressed:
		eh_toque = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		eh_toque = true
		
	if eh_toque:
		var agora = Time.get_ticks_msec()
		if agora - _ultimo_toque_cutscene_ms <= INTERVALO_DUPLO_TOQUE_MS:
			get_viewport().set_input_as_handled()
			_pular_cutscene_atual()
		else:
			_ultimo_toque_cutscene_ms = agora

func _criar_ui_pular_cutscene() -> void:
	if _cutscene_pular_ui and is_instance_valid(_cutscene_pular_ui):
		_cutscene_pular_ui.queue_free()
		
	_cutscene_pular_ui = CanvasLayer.new()
	_cutscene_pular_ui.layer = 99
	add_child(_cutscene_pular_ui)
	
	# Detecta se é mobile
	var eh_mobile = false
	var mc = get_node_or_null("/root/MobileControlsManager")
	if mc and "is_mobile" in mc:
		eh_mobile = mc.is_mobile
	elif OS.has_feature("mobile") or (OS.has_feature("web") and DisplayServer.is_touchscreen_available()):
		eh_mobile = true
		
	# Botão Pular elegante e translúcido no canto superior direito
	var btn_pular = Button.new()
	btn_pular.text = "PULAR ❯❯"
	btn_pular.custom_minimum_size = Vector2(100, 36)
	btn_pular.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn_pular.offset_left = -120
	btn_pular.offset_top = 16
	btn_pular.offset_right = -16
	btn_pular.offset_bottom = 52
	
	var font_btn = SystemFont.new()
	font_btn.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_btn.font_weight = 700
	btn_pular.add_theme_font_override("font", font_btn)
	btn_pular.add_theme_font_size_override("font_size", 13)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.12, 0.20, 0.85)
	sb.border_color = Color(0.95, 0.70, 0.20, 0.90)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	btn_pular.add_theme_stylebox_override("normal", sb)
	
	var sb_hov = sb.duplicate() as StyleBoxFlat
	sb_hov.bg_color = Color(0.18, 0.24, 0.36, 0.95)
	sb_hov.border_color = Color(1.0, 0.85, 0.35, 1.0)
	btn_pular.add_theme_stylebox_override("hover", sb_hov)
	btn_pular.add_theme_stylebox_override("pressed", sb_hov)
	btn_pular.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	
	btn_pular.pressed.connect(_pular_cutscene_atual)
	_cutscene_pular_ui.add_child(btn_pular)
	
	# Legenda discreta na parte inferior
	var lbl_dica = Label.new()
	if eh_mobile:
		lbl_dica.text = "( Toque 2x na tela para pular )"
	else:
		lbl_dica.text = "( Pressione ESPAÇO ou clique 2x para pular )"
	lbl_dica.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	lbl_dica.offset_top = -45
	lbl_dica.offset_bottom = -15
	lbl_dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_dica.add_theme_font_size_override("font_size", 13)
	lbl_dica.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 0.75))
	var font_dica = SystemFont.new()
	font_dica.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_dica.font_weight = 500
	lbl_dica.add_theme_font_override("font", font_dica)
	_cutscene_pular_ui.add_child(lbl_dica)

func _pular_cutscene_atual() -> void:
	if not _cutscene_em_andamento:
		return
	if _cutscene_tipo == "retorno_vitoria":
		_pular_cutscene_retorno_vitoria()
	else:
		_pular_cutscene_inicial()

func _pular_cutscene_inicial() -> void:
	if not _cutscene_em_andamento:
		return
	_cutscene_em_andamento = false
	
	# Mata o tween de movimento se ainda estiver rodando
	if _cutscene_tween and is_instance_valid(_cutscene_tween):
		_cutscene_tween.kill()
		_cutscene_tween = null
		
	# Encerra imediatamente a tela preta com a animação se estiver tocando
	if _cutscene_mesa_instancia and is_instance_valid(_cutscene_mesa_instancia):
		_cutscene_mesa_instancia.pular()
		_cutscene_mesa_instancia = null
		
	_finalizar_cutscene_com_pergaminho()

func _finalizar_cutscene_com_pergaminho() -> void:
	_cutscene_em_andamento = false
	
	# Remove a interface de pular
	if _cutscene_pular_ui and is_instance_valid(_cutscene_pular_ui):
		_cutscene_pular_ui.queue_free()
		_cutscene_pular_ui = null
		
	var player = get_node_or_null("Player")
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		
	if player and is_instance_valid(player):
		player.global_position = Vector2(263, 710)
		player.ultima_direcao = "cima"
		var sprite = player.get_node_or_null("sprite") as AnimatedSprite2D
		if sprite:
			sprite.play("idle_cima")
		var poeira = player.get_node_or_null("PoeiraPassos") as CPUParticles2D
		if poeira:
			poeira.emitting = false
			
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui-1")
		
	# Some o pergaminho da mesa
	var pergaminho_mesa = get_node_or_null("PergaminhoMesa")
	if pergaminho_mesa and is_instance_valid(pergaminho_mesa):
		if pergaminho_mesa.has_method("_remover_prompt_tela"):
			pergaminho_mesa._remover_prompt_tela()
		pergaminho_mesa.queue_free()
		
	# Salva o pergaminho no grimório
	if get_node_or_null("/root/PlayerStats"):
		PlayerStats.adicionar_pergaminho(titulo_intro, paginas_intro, "O pergaminho de introdução entregue ao jovem mago na mesa de alquimia.")
		PlayerStats.marcar_cutscene_inicial_vista()

	# Abre o pergaminho na tela com o jogador já destravando ao fechar
	var ui = get_tree().get_first_node_in_group("parchment_ui")
	if ui == null and get_tree().current_scene:
		ui = get_tree().current_scene.find_child("ParchmentUI", true, false)

	if ui and ui.has_method("abrir_pergaminho"):
		if ui.has_signal("pergaminho_fechado"):
			ui.pergaminho_fechado.connect(_ao_fechar_pergaminho_cutscene.bind(player), CONNECT_ONE_SHOT)
		ui.abrir_pergaminho(paginas_intro, player)
	else:
		_ao_fechar_pergaminho_cutscene(player)

func _executar_cutscene_inicial() -> void:
	var player = get_node_or_null("Player")
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		
	if player == null:
		return

	_cutscene_em_andamento = true
	_cutscene_tipo = "inicial"
	_ultimo_toque_cutscene_ms = 0
	_criar_ui_pular_cutscene()

	# Marca que a historinha inicial já foi iniciada/vista para nunca mais repetir em Novos Jogos
	if get_node_or_null("/root/PlayerStats"):
		PlayerStats.marcar_cutscene_inicial_vista()

	# Trava o jogador na cutscene e define direção inicial olhando para o corredor (cima)
	player.travado = true
	player.em_interacao = true
	player.global_position = Vector2(580, 946)
	player.ultima_direcao = "cima"
	
	var sprite = player.get_node_or_null("sprite") as AnimatedSprite2D
	var poeira = player.get_node_or_null("PoeiraPassos") as CPUParticles2D
	
	# PASSO 1: Anda para cima pelo corredor
	if sprite:
		sprite.play("correr_cima")
	if poeira:
		poeira.emitting = true
		poeira.direction = Vector2(0, 1)
		
	_cutscene_tween = create_tween().set_trans(Tween.TRANS_LINEAR)
	_cutscene_tween.tween_property(player, "global_position:y", 710.0, 3.0)
	_tocar_passos_cutscene(3.0)
	await _cutscene_tween.finished
	if not _cutscene_em_andamento:
		return
	
	# PASSO 2: Vira para a esquerda e anda até a mesa
	player.ultima_direcao = "esquerda"
	if sprite:
		sprite.play("correr_esquerda")
	if poeira:
		poeira.emitting = true
		poeira.direction = Vector2(1, 0)
		
	_cutscene_tween = create_tween().set_trans(Tween.TRANS_LINEAR)
	_cutscene_tween.tween_property(player, "global_position:x", 263.0, 4.0)
	_tocar_passos_cutscene(4.0)
	await _cutscene_tween.finished
	if not _cutscene_em_andamento:
		return
	
	# PASSO 3: Chegou normalmente à mesa - para e olha para a mesa
	player.ultima_direcao = "cima"
	if sprite:
		sprite.play("idle_cima")
	if poeira:
		poeira.emitting = false

	# Troca para a tela preta com a animação cinematográfica do mago (cerca de 5 segundos)
	var cena_anim = load("res://scenes/ui/cutscene_mesa_animacao.tscn")
	if cena_anim:
		_cutscene_mesa_instancia = cena_anim.instantiate()
		add_child(_cutscene_mesa_instancia)
		await _cutscene_mesa_instancia.animacao_concluida
		_cutscene_mesa_instancia = null
		
	if not _cutscene_em_andamento:
		return
		
	# Volta para o jogo normal já com o pergaminho aberto
	_finalizar_cutscene_com_pergaminho()

func _ao_fechar_pergaminho_cutscene(player: Node2D) -> void:
	if _cutscene_pular_ui and is_instance_valid(_cutscene_pular_ui):
		_cutscene_pular_ui.queue_free()
		_cutscene_pular_ui = null
	if player and is_instance_valid(player):
		player.travado = false
		player.em_interacao = false
		player.ultima_direcao = "baixo"
		var sprite = player.get_node_or_null("sprite") as AnimatedSprite2D
		if sprite:
			sprite.play("idle_baixo")
		var poeira = player.get_node_or_null("PoeiraPassos") as CPUParticles2D
		if poeira:
			poeira.emitting = false
	if get_node_or_null("/root/PlayerStats"):
		PlayerStats.marcar_cutscene_inicial_vista()

func _tocar_passos_cutscene(duracao: float) -> void:
	var tempo_decorrido: float = 0.0
	while tempo_decorrido < duracao:
		if not is_inside_tree() or not _cutscene_em_andamento:
			return
		if get_node_or_null("/root/AudioManager"):
			AudioManager.tocar_som_caminhada()
		await get_tree().create_timer(0.35).timeout
		tempo_decorrido += 0.35

func _executar_cutscene_retorno_vitoria(andar_id: int) -> void:
	var player = get_node_or_null("Player")
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
		
	var hud = get_node_or_null("HUD")
	if hud == null:
		hud = get_tree().get_first_node_in_group("hud")
	var hud_ctrl = hud.get_node_or_null("Control") if hud else null
	if hud_ctrl:
		hud_ctrl.modulate.a = 0.0

	_cutscene_em_andamento = true
	_cutscene_tipo = "retorno_vitoria"
	_ultimo_toque_cutscene_ms = 0
	_criar_ui_pular_cutscene()

	# Trava o jogador na cutscene e posiciona no interior da porta de entrada inicial (sul do Hub)
	player.travado = true
	player.em_interacao = true
	player.global_position = Vector2(580, 955)
	player.ultima_direcao = "cima"

	var sprite = player.get_node_or_null("sprite") as AnimatedSprite2D
	var poeira = player.get_node_or_null("PoeiraPassos") as CPUParticles2D
	
	if sprite:
		sprite.play("correr_cima")
	if poeira:
		poeira.emitting = true
		poeira.direction = Vector2(0, 1)

	# Criação de aura mística e partículas de fagulhas celebrando a saída do andar
	var particulas_aura = CPUParticles2D.new()
	particulas_aura.name = "AuraRetornoVitoria"
	particulas_aura.amount = 20
	particulas_aura.lifetime = 1.3
	particulas_aura.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particulas_aura.emission_sphere_radius = 16.0
	particulas_aura.gravity = Vector2(0, -32)
	particulas_aura.initial_velocity_min = 10.0
	particulas_aura.initial_velocity_max = 24.0
	particulas_aura.scale_amount_min = 1.6
	particulas_aura.scale_amount_max = 3.4
	
	var cor_aura = Color(1.0, 0.85, 0.35, 0.80) # Química / Dourado
	if andar_id == 2:
		cor_aura = Color(0.35, 0.85, 1.0, 0.80) # Física / Ciano
	elif andar_id == 3:
		cor_aura = Color(0.35, 0.95, 0.55, 0.80) # Biologia / Esmeralda
	particulas_aura.color = cor_aura
	player.add_child(particulas_aura)

	# Movimento majestoso do boneco saindo da escuridão do portal e caminhando para o centro do saguão
	_cutscene_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_cutscene_tween.tween_property(player, "global_position:y", 710.0, 2.5)
	_tocar_passos_cutscene(2.5)
	await _cutscene_tween.finished
	
	if not _cutscene_em_andamento:
		return

	# Chegou à soleira da entrada: para de caminhar e se vira para baixo com dignidade
	player.ultima_direcao = "baixo"
	if sprite:
		sprite.play("idle_baixo")
	if poeira:
		poeira.emitting = false

	# Dissipa suavemente a aura cintilante de retorno
	var tw_aura = create_tween()
	tw_aura.tween_property(particulas_aura, "modulate:a", 0.0, 0.70)
	tw_aura.tween_callback(particulas_aura.queue_free)

	# Som solene de conquista e triunfo
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("acerto_1")

	# Fade suave revelando o HUD profissionalmente
	if hud_ctrl:
		var tw_hud = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw_hud.tween_property(hud_ctrl, "modulate:a", 1.0, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Notificação Toast triunfante no topo da tela
	if hud and hud.has_method("mostrar_notificacao_quest"):
		var nome_andar = "Alquimia"
		if andar_id == 2: nome_andar = "Física"
		elif andar_id == 3: nome_andar = "Biologia"
		hud.mostrar_notificacao_quest("🏆 ANDAR DE " + nome_andar.to_upper() + " CONCLUÍDO!", "Você superou o Guardião e retornou são e salvo ao Saguão Central.", cor_aura, "acerto_1")

	# Intervalo de contemplação e destravamento
	await get_tree().create_timer(0.4).timeout
	if not _cutscene_em_andamento:
		return
	_finalizar_cutscene_retorno_vitoria(player, hud_ctrl)

func _pular_cutscene_retorno_vitoria() -> void:
	if not _cutscene_em_andamento:
		return
	_cutscene_em_andamento = false
	_cutscene_tipo = ""
	
	if _cutscene_tween and is_instance_valid(_cutscene_tween):
		_cutscene_tween.kill()
		_cutscene_tween = null
		
	var player = get_node_or_null("Player")
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	var hud = get_node_or_null("HUD")
	if hud == null:
		hud = get_tree().get_first_node_in_group("hud")
	var hud_ctrl = hud.get_node_or_null("Control") if hud else null
	
	_finalizar_cutscene_retorno_vitoria(player, hud_ctrl)

func _finalizar_cutscene_retorno_vitoria(player: Node2D, hud_ctrl: Control) -> void:
	_cutscene_em_andamento = false
	_cutscene_tipo = ""
	
	if _cutscene_pular_ui and is_instance_valid(_cutscene_pular_ui):
		_cutscene_pular_ui.queue_free()
		_cutscene_pular_ui = null
		
	if player and is_instance_valid(player):
		player.global_position = Vector2(580, 710)
		player.ultima_direcao = "baixo"
		var sprite = player.get_node_or_null("sprite") as AnimatedSprite2D
		if sprite:
			sprite.play("idle_baixo")
		var poeira = player.get_node_or_null("PoeiraPassos") as CPUParticles2D
		if poeira:
			poeira.emitting = false
		var aura = player.get_node_or_null("AuraRetornoVitoria")
		if aura and is_instance_valid(aura):
			aura.queue_free()
		player.travado = false
		player.em_interacao = false
		
	if hud_ctrl and is_instance_valid(hud_ctrl):
		hud_ctrl.modulate.a = 1.0

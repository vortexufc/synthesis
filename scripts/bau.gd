extends Area2D

# script do bau (abre pergaminho de dica ou minigame da memoria)

@export var titulo_pergaminho: String = "Pergaminho Arcano"
@export var usar_paginas_custom: bool = false
@export_multiline var paginas_custom: Array[String] = []
@export_range(1, 4) var num_paginas: int = 4
@export_enum("Madeira", "Arcano", "Ferro") var tipo_bau: int = 0
@export_enum("Desafio da Memória Arcana", "Pergaminho de Dicas") var modo_conteudo: int = 0
@export_enum("Automático (Detectar pela Sala)", "Andar 1 (Química)", "Andar 2 (Física)", "Andar 3 (Biologia)") var forcar_andar: int = 0
@export var eh_desafio_memoria: bool = true
@export var recompensa_moedas: int = 30
@export var recompensa_pocao: String = "Poção de Cura"
@export var duracao_buff_salas: int = 2

var ja_aberto: bool = false
var id_unico: String = ""

@onready var sprite: Sprite2D = get_node_or_null("BauSprite")

const CENA_MOEDA = preload("res://scenes/Entidades/Items/ItemMoeda.tscn")

# sprites do tileset de objetos
var tex_fechado: AtlasTexture
var tex_aberto: AtlasTexture

var player_perto: bool = false
var player_ref: Node2D = null
var canvas_prompt: CanvasLayer = null
var panel_prompt: PanelContainer = null
var _minigame_ativo: bool = false
var _minigame_instancia: Node = null

func _obter_id_unico() -> String:
	if id_unico != "":
		return id_unico
	var cena_path = ""
	if get_tree() and get_tree().current_scene:
		cena_path = get_tree().current_scene.scene_file_path
	var pos_str = "%d_%d" % [int(global_position.x), int(global_position.y)]
	var pai_nome = get_parent().name if get_parent() else ""
	return "%s::%s/%s@%s" % [cena_path, pai_nome, name, pos_str]

func _ready() -> void:
	add_to_group("baus")
	if id_unico == "":
		id_unico = _obter_id_unico()

	if get_node_or_null("/root/PlayerStats") and PlayerStats.is_bau_aberto(id_unico):
		ja_aberto = true

	if modo_conteudo == 0:
		eh_desafio_memoria = true
	elif modo_conteudo == 1:
		eh_desafio_memoria = false

	# recorta o sprite aberto e fechado
	var base_tex = load("res://assets/sprites/tilesets/Alquimia/OBJETOS.png")
	if base_tex:
		tex_fechado = AtlasTexture.new()
		tex_fechado.atlas = base_tex
		
		tex_aberto = AtlasTexture.new()
		tex_aberto.atlas = base_tex
		
		match tipo_bau:
			0: # madeira
				tex_fechado.region = Rect2(1024, 336, 48, 48)
				tex_aberto.region = Rect2(1024, 528, 48, 48)
			1: # arcano
				tex_fechado.region = Rect2(896, 336, 48, 48)
				tex_aberto.region = Rect2(896, 528, 48, 48)
			2: # ferro
				tex_fechado.region = Rect2(768, 336, 48, 48)
				tex_aberto.region = Rect2(768, 528, 48, 48)
		
		if sprite:
			if ja_aberto:
				sprite.texture = tex_aberto
			else:
				sprite.texture = tex_fechado

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _exit_tree() -> void:
	_remover_prompt_tela()

var _indicador_flutuante: Node2D = null
var _tempo_indicador: float = 0.0

func _process(delta: float) -> void:
	if _indicador_flutuante and is_instance_valid(_indicador_flutuante):
		_tempo_indicador += delta
		_indicador_flutuante.position.y = -36.0 + sin(_tempo_indicador * 3.8) * 4.5

func _exibir_prompt_tela() -> void:
	if ja_aberto or _minigame_ativo:
		return
	if _minigame_instancia and is_instance_valid(_minigame_instancia):
		return
	if get_tree().get_nodes_in_group("minigame_ativo").size() > 0 or get_tree().get_nodes_in_group("desafio_memoria").size() > 0:
		return
	if _indicador_flutuante and is_instance_valid(_indicador_flutuante):
		return
		
	_indicador_flutuante = Node2D.new()
	_indicador_flutuante.name = "IndicadorFlutuante"
	_indicador_flutuante.z_index = 25
	_indicador_flutuante.position = Vector2(0, -36)
	_indicador_flutuante.scale = Vector2.ZERO
	add_child(_indicador_flutuante)
	
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.12, 0.94)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	style.set_border_width_all(1)
	style.border_color = Color(1.0, 0.82, 0.28, 0.95)
	style.shadow_color = Color(0.95, 0.70, 0.15, 0.35)
	style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	panel.add_child(hbox)
	
	var lbl_key = Label.new()
	lbl_key.text = "[F]"
	lbl_key.add_theme_color_override("font_color", Color(1.0, 0.95, 0.50))
	var font_pixel = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	if font_pixel:
		lbl_key.add_theme_font_override("font", font_pixel)
	lbl_key.add_theme_font_size_override("font_size", 13)
	hbox.add_child(lbl_key)
	
	var lbl_txt = Label.new()
	lbl_txt.text = "Desafio Arcano" if eh_desafio_memoria else "Abrir Baú"
	lbl_txt.add_theme_color_override("font_color", Color(0.90, 0.92, 0.98))
	if font_pixel:
		lbl_txt.add_theme_font_override("font", font_pixel)
	lbl_txt.add_theme_font_size_override("font_size", 12)
	hbox.add_child(lbl_txt)
	
	panel.position = Vector2(-70, -14)
	_indicador_flutuante.add_child(panel)
	
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_indicador_flutuante, "scale", Vector2.ONE, 0.22)

func _remover_prompt_tela() -> void:
	if _indicador_flutuante and is_instance_valid(_indicador_flutuante):
		var node = _indicador_flutuante
		_indicador_flutuante = null
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(node, "scale", Vector2.ZERO, 0.16)
		tw.tween_callback(node.queue_free)

func _on_body_entered(body: Node2D) -> void:
	if ja_aberto:
		return
	if not body.is_in_group("player") and body.name != "Player":
		return
	player_perto = true
	player_ref = body
	_exibir_prompt_tela()

func _on_body_exited(body: Node2D) -> void:
	if body == player_ref or body.is_in_group("player") or body.name == "Player":
		player_perto = false
		player_ref = null
		_remover_prompt_tela()

func _unhandled_input(event: InputEvent) -> void:
	if not player_perto or ja_aberto or _minigame_ativo:
		return
	if _minigame_instancia and is_instance_valid(_minigame_instancia):
		return
	if player_ref and is_instance_valid(player_ref) and player_ref.has_method("esta_em_interacao") and player_ref.esta_em_interacao():
		return
	if get_tree().get_nodes_in_group("minigame_ativo").size() > 0 or get_tree().get_nodes_in_group("desafio_memoria").size() > 0:
		return
		
	var pressionou_f = (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F)
	if pressionou_f or event.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled()
		abrir_bau()

func abrir_bau() -> void:
	if ja_aberto or _minigame_ativo:
		return
	if _minigame_instancia and is_instance_valid(_minigame_instancia):
		return
	if get_tree().get_nodes_in_group("minigame_ativo").size() > 0 or get_tree().get_nodes_in_group("desafio_memoria").size() > 0:
		return
		
	if eh_desafio_memoria:
		_iniciar_desafio_memoria()
		return

	ja_aberto = true
	_remover_prompt_tela()
	
	if get_node_or_null("/root/PlayerStats") and id_unico != "":
		PlayerStats.registrar_bau_aberto(id_unico)
	
	# muda pro sprite aberto
	if sprite and tex_aberto:
		sprite.texture = tex_aberto

	_executar_animacao_abrir_bau(false)

	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui-1")

	# pega o conteudo das paginas de dica
	var paginas: Array[String] = []
	if usar_paginas_custom and paginas_custom.size() > 0:
		paginas = paginas_custom
	else:
		var andar_id = 1
		if get_node_or_null("/root/QuizManager"):
			andar_id = QuizManager._andar_atual
		paginas = PergaminhoManager.obter_paginas_dicas(andar_id, [], num_paginas)

	# guarda no grimorio
	if get_node_or_null("/root/PlayerStats"):
		var nome_sala = ""
		if get_tree() and get_tree().current_scene:
			nome_sala = get_tree().current_scene.name
		var titulo_final = titulo_pergaminho
		if nome_sala != "":
			titulo_final += " (" + nome_sala + ")"
		PlayerStats.adicionar_pergaminho(titulo_final, paginas)

	# abre a tela do pergaminho
	var ui = get_tree().get_first_node_in_group("parchment_ui")
	if ui == null and get_tree().current_scene:
		ui = get_tree().current_scene.find_child("ParchmentUI", true, false)

	if ui and ui.has_method("abrir_pergaminho"):
		ui.abrir_pergaminho(paginas, player_ref)
	else:
		push_warning("[Bau] ParchmentUI não foi encontrado na cena!")

# minigame de cartas da memoria
func _iniciar_desafio_memoria() -> void:
	if _minigame_ativo or (_minigame_instancia and is_instance_valid(_minigame_instancia)):
		return
	if get_tree().get_nodes_in_group("desafio_memoria").size() > 0 or get_tree().get_nodes_in_group("minigame_ativo").size() > 0:
		return
		
	_minigame_ativo = true
	_remover_prompt_tela()
	
	var ui_inv = get_tree().get_first_node_in_group("inventario_ui")
	if ui_inv and ui_inv.visible and ui_inv.has_method("fechar_inventario"):
		ui_inv.fechar_inventario()
	
	# pega o andar certo
	var andar_id = 1
	if forcar_andar > 0:
		andar_id = forcar_andar
	else:
		var nome_dungeon = ""
		if get_node_or_null("/root/DatabaseManager") and DatabaseManager.active_dungeon != "":
			nome_dungeon = DatabaseManager.active_dungeon.to_lower()
		elif get_tree() and get_tree().current_scene:
			nome_dungeon = get_tree().current_scene.scene_file_path.to_lower()
			
		if "fisica" in nome_dungeon:
			andar_id = 2
		elif "biologia" in nome_dungeon:
			andar_id = 3
		elif get_node_or_null("/root/QuizManager"):
			andar_id = QuizManager._andar_atual
		else:
			andar_id = 1
		
	var minigame_scene = preload("res://scenes/ui/desafio_memoria_ui.tscn")
	if minigame_scene:
		var minigame = minigame_scene.instantiate()
		_minigame_instancia = minigame
		get_tree().root.add_child(minigame)
		minigame.desafio_concluido.connect(_on_desafio_memoria_concluido)
		minigame.tree_exited.connect(func():
			_minigame_ativo = false
			_minigame_instancia = null
		)
		minigame.iniciar_desafio(andar_id, player_ref)

func _on_desafio_memoria_concluido(vitoria: bool, tempo_esgotado: bool = false) -> void:
	_minigame_ativo = false
	_minigame_instancia = null
	if vitoria:
		ja_aberto = true
		if sprite and tex_aberto:
			sprite.texture = tex_aberto
			
		if get_node_or_null("/root/PlayerStats") and id_unico != "":
			PlayerStats.registrar_bau_aberto(id_unico)
			
		if get_node_or_null("/root/PlayerStats"):
			# recompensas: pocao e escudo temporario
			PlayerStats.adicionar_pocao(recompensa_pocao, 40, "Cura 40 HP (Baú Arcano)", 1)
			PlayerStats.aplicar_buff_escudo(duracao_buff_salas, 10.0)
			
		_executar_loot_pop(recompensa_moedas)
			
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("mostrar_notificacao_quest"):
			hud.mostrar_notificacao_quest(
				"DESAFIO CONCLUÍDO!",
				"+1 Poção, +%d Moedas e Escudo Arcano (+10 HP Máx)!" % recompensa_moedas,
				Color(0.7, 0.45, 1.0),
				"ui_1"
			)
	elif tempo_esgotado:
		# Somente se o tempo esgotou de verdade
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("mostrar_notificacao_quest"):
			hud.mostrar_notificacao_quest(
				"ARMADILHA DO BAÚ!",
				"O tempo esgotou! Você sofreu -15 HP de dano da runa.",
				Color(1.0, 0.35, 0.35),
				""
			)
		if player_perto:
			_exibir_prompt_tela()
	else:
		# Fechamento manual ou cancelamento antes de acabar o tempo (sem dano)
		if player_perto:
			_exibir_prompt_tela()

func _executar_animacao_abrir_bau(eh_grande: bool = false) -> void:
	if sprite:
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(sprite, "scale", Vector2(1.28, 0.72), 0.08)
		tw.tween_property(sprite, "scale", Vector2(0.84, 1.28), 0.14)
		tw.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.22)
		
	# Partículas de brilho mágico / poeira dourada
	var part = CPUParticles2D.new()
	part.top_level = true
	part.z_index = 20
	part.global_position = global_position + Vector2(0, -10)
	part.emitting = true
	part.one_shot = true
	part.amount = 26 if eh_grande else 14
	part.lifetime = 0.65
	part.explosiveness = 0.85
	part.direction = Vector2(0, -1)
	part.spread = 55.0
	part.gravity = Vector2(0, 180)
	part.initial_velocity_min = 70.0
	part.initial_velocity_max = 150.0
	part.scale_amount_min = 1.2
	part.scale_amount_max = 2.4
	
	var grad = Gradient.new()
	if eh_grande:
		grad.colors = PackedColorArray([Color(1.0, 0.95, 0.4, 1.0), Color(0.8, 0.4, 1.0, 0.8), Color(0.4, 0.8, 1.0, 0.0)])
	else:
		grad.colors = PackedColorArray([Color(1.0, 0.9, 0.5, 1.0), Color(1.0, 0.7, 0.2, 0.0)])
	part.color_ramp = grad
	
	get_tree().root.add_child(part)
	get_tree().create_timer(0.75).timeout.connect(part.queue_free)

func _executar_loot_pop(total_moedas: int) -> void:
	_executar_animacao_abrir_bau(true)
	
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("win")
	
	var pai = get_parent()
	if not pai: return
	
	var num_moedas = clamp(int(float(total_moedas) / 6.0), 4, 7)
	var valor_por_moeda = max(1, int(float(total_moedas) / float(num_moedas)))
	var resto = total_moedas - (valor_por_moeda * num_moedas)
	
	for i in range(num_moedas):
		var moeda = CENA_MOEDA.instantiate()
		var v = valor_por_moeda + (resto if i == 0 else 0)
		if "valor_custom" in moeda:
			moeda.valor_custom = v
			
		var angulo_deg = lerp(-140.0, -40.0, float(i) / max(1.0, float(num_moedas - 1))) + randf_range(-12.0, 12.0)
		var rad = deg_to_rad(angulo_deg)
		var distancia = randf_range(38.0, 68.0)
		var offset_pouso = Vector2(cos(rad) * distancia, abs(sin(rad)) * distancia * 0.55 + randf_range(12.0, 28.0))
		var pos_pouso = global_position + offset_pouso
		
		# Evita entrar na parede
		if is_inside_tree() and get_world_2d():
			var space = get_world_2d().direct_space_state
			if space:
				var q = PhysicsRayQueryParameters2D.create(global_position, pos_pouso, 1)
				var hit = space.intersect_ray(q)
				if hit and hit.has("position"):
					pos_pouso = hit["position"] - offset_pouso.normalized() * 12.0
					
		pai.call_deferred("add_child", moeda)
		
		var delay = i * 0.06
		get_tree().create_timer(delay, false).timeout.connect(func():
			if is_instance_valid(moeda) and moeda.has_method("lancar_arco"):
				moeda.lancar_arco(global_position + Vector2(0, -8), pos_pouso, randf_range(65.0, 95.0))
		)



extends CharacterBody2D

# script do inimigo e movimentacao

signal inimigo_derrotado(pos: Vector2)

@export var vida_maxima:       float = 100.0
@export var velocidade:        float =  55.0
@export var dano:              float =  25.0
@export var tempo_min_direcao: float =  0.8
@export var tempo_max_direcao: float =  2.2
@export var chance_pausa:      float =  0.2
@export var distancia_perseguicao: float = 200.0
@export var velocidade_perseguicao: float = 75.0

@export var eh_runico: bool = false
@export var chance_ser_runico: float = 0.35

var vida_atual:      float
var _em_batalha:     bool    = false
var _sou_o_combatente: bool  = false
var _em_pausa:       bool    = false
var _direcao:        Vector2 = Vector2.RIGHT
var _timer_direcao:  float   = 0.0
var _timer_pausa:    float   = 0.0
var _player:         Node2D  = null
var _perseguindo:    bool    = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# 8 direcoes possiveis
var DIRECOES: Array = [
	Vector2(1, 0),                 # Direita
	Vector2(-1, 0),                # Esquerda
	Vector2(0, 1),                 # Baixo
	Vector2(0, -1),                # Cima
	Vector2(1, 1).normalized(),    # Diagonal 
	Vector2(-1, 1).normalized(),   # Diagonal 
	Vector2(1, -1).normalized(),   # Diagonal 
	Vector2(-1, -1).normalized(),  # Diagonal 
]

func _ready() -> void:
	# Se este inimigo já foi derrotado nesta masmorra, remove ele imediatamente
	if get_node_or_null("/root/DungeonGenerator"):
		var room_path = get_tree().current_scene.scene_file_path
		var key = room_path + "::" + self.name
		if DungeonGenerator.is_inimigo_derrotado(key):
			print("[Inimigo] Já derrotado anteriormente nesta masmorra, removendo: ", key)
			queue_free()
			return

	add_to_group("inimigos")
	_calibrar_balanceamento_inimigo()
	vida_atual = vida_maxima
	randomize()

	# Começa já com uma direção aleatória
	_sortear_nova_direcao()

	# Escuta sinais globais de batalha
	GlobalSignals.iniciar_batalha.connect(_on_batalha_iniciada)
	GlobalSignals.batalha_encerrada.connect(_on_batalha_encerrada)

	if sprite:
		sprite.play("default")
	
	_criar_sombra()

	# Campeão Rúnico: chance aleatória se não for boss
	var nome_baixo = name.to_lower()
	if not eh_runico and chance_ser_runico > 0.0 and not ("boss" in nome_baixo):
		if randf() < chance_ser_runico:
			eh_runico = true

	if eh_runico:
		vida_maxima *= 1.25
		vida_atual = vida_maxima
		_criar_aura_runica()

func _calibrar_balanceamento_inimigo() -> void:
	var nome_baixo = name.to_lower()
	var enemy_id = ""
	for child in get_children():
		if child is Area2D and "id_inimigo" in child:
			enemy_id = str(child.id_inimigo).to_lower()
			break

	# 1. Chefes
	if ("boss" in nome_baixo) or ("boss" in enemy_id) or ("roxo" in nome_baixo) or ("roxo" in enemy_id):
		vida_maxima = 130.0
		dano = 30.0
		velocidade = 30.0
		velocidade_perseguicao = 48.0
		distancia_perseguicao = 220.0
	elif ("robo_g" in nome_baixo) or ("robo_g" in enemy_id):
		vida_maxima = 140.0
		dano = 30.0
		velocidade = 30.0
		velocidade_perseguicao = 50.0
		distancia_perseguicao = 220.0
	elif ("wizard" in nome_baixo) or ("wizzard" in nome_baixo) or ("wizard" in enemy_id):
		vida_maxima = 120.0
		dano = 28.0
		velocidade = 40.0
		velocidade_perseguicao = 60.0
		distancia_perseguicao = 200.0
	# 2. Tier 3 (Inimigos Grandes / Avançados)
	elif ("laranja" in nome_baixo) or ("laranja" in enemy_id) or ("slime_g" in nome_baixo) or ("slime_g" in enemy_id) or ("vermelho" in nome_baixo):
		vida_maxima = 100.0
		dano = 24.0
		velocidade = 46.0
		velocidade_perseguicao = 70.0
		distancia_perseguicao = 190.0
	# 3. Tier 2 (Inimigos Médios / Ácidos / Ciano)
	elif ("verde" in nome_baixo) or ("verde" in enemy_id) or ("ciano" in nome_baixo) or ("ciano" in enemy_id):
		vida_maxima = 75.0
		dano = 18.0
		velocidade = 40.0
		velocidade_perseguicao = 62.0
		distancia_perseguicao = 180.0
	# 4. Tier 1 (Inimigos Menores / Salas Iniciais)
	elif ("azul" in nome_baixo) or ("azul" in enemy_id) or ("slime_p" in nome_baixo) or ("slime_p" in enemy_id) or ("amarelo" in nome_baixo) or ("amarelo" in enemy_id):
		vida_maxima = 50.0
		dano = 12.0
		velocidade = 36.0
		velocidade_perseguicao = 55.0
		distancia_perseguicao = 160.0

var shadow: Sprite2D = null
var shadow_base_scale: Vector2 = Vector2(1.8, 1.2)
var tempo_anim_sombra: float = 0.0

func _criar_sombra() -> void:
	var shadow_tex = load("res://assets/sprites/Characters/Maguinho/shadow.png")
	if not shadow_tex:
		return
	
	shadow = Sprite2D.new()
	shadow.name = "Shadow"
	shadow.texture = shadow_tex
	shadow.z_index = 0
	
	if sprite and sprite.z_index == 0:
		sprite.z_index = 1
	
	var nome_baixo = name.to_lower()
	
	# Slimes não precisam de sombra pois são colados no chão
	if "slime" in nome_baixo:
		return
	
	var pos_y: float = 20.0
	
	if "robo_g" in nome_baixo:
		pos_y = 82.0
		shadow_base_scale = Vector2(1.8, 1.2)
	elif "robo_p" in nome_baixo:
		pos_y = 46.0
		shadow_base_scale = Vector2(1.9, 1.2)
	elif "evil_wizzard" in nome_baixo or "wizzard" in nome_baixo or "wizard" in nome_baixo:
		pos_y = 40.0
		shadow_base_scale = Vector2(1.85, 1.25)
	else:
		var col = get_node_or_null("CollisionShape2D")
		if col:
			pos_y = col.position.y + 12.0
		else:
			pos_y = 20.0
		shadow_base_scale = Vector2(1.8, 1.2)
	
	shadow.position = Vector2(0, pos_y)
	shadow.scale = shadow_base_scale
	
	add_child(shadow)
	move_child(shadow, 0)

var aura_runica_sprite: Sprite2D = null
var tag_runico_label: Label = null
var particulas_runicas: CPUParticles2D = null

func _criar_aura_runica() -> void:
	var nome_baixo = name.to_lower()
	var pos_y: float = 20.0
	
	if "robo_g" in nome_baixo:
		pos_y = 82.0
	elif "robo_p" in nome_baixo:
		pos_y = 46.0
	elif "evil_wizzard" in nome_baixo or "wizzard" in nome_baixo or "wizard" in nome_baixo:
		pos_y = 40.0
	else:
		var col = get_node_or_null("CollisionShape2D")
		if col:
			pos_y = col.position.y + 12.0
		else:
			pos_y = 20.0

	# circulo de luz no chao pro runico
	var grad = Gradient.new()
	grad.colors = PackedColorArray([
		Color(0.2, 0.9, 1.0, 0.75),
		Color(0.65, 0.25, 0.95, 0.45),
		Color(0.1, 0.05, 0.4, 0.0)
	])
	grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])

	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 64
	tex.height = 64

	aura_runica_sprite = Sprite2D.new()
	aura_runica_sprite.name = "AuraRunica"
	aura_runica_sprite.texture = tex
	aura_runica_sprite.position = Vector2(0, pos_y)
	aura_runica_sprite.scale = Vector2(2.0, 1.1)
	aura_runica_sprite.z_index = 0
	add_child(aura_runica_sprite)
	move_child(aura_runica_sprite, 0)

	var tw = create_tween().set_loops().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(aura_runica_sprite, "scale", Vector2(2.4, 1.35), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(aura_runica_sprite, "scale", Vector2(1.8, 0.95), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# particulas saindo do chao
	particulas_runicas = CPUParticles2D.new()
	particulas_runicas.name = "ParticulasAura"
	particulas_runicas.amount = 10
	particulas_runicas.lifetime = 1.1
	particulas_runicas.speed_scale = 1.0
	particulas_runicas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particulas_runicas.emission_rect_extents = Vector2(16, 6)
	particulas_runicas.direction = Vector2(0, -1)
	particulas_runicas.gravity = Vector2(0, -22)
	particulas_runicas.initial_velocity_min = 8.0
	particulas_runicas.initial_velocity_max = 20.0
	particulas_runicas.scale_amount_min = 2.0
	particulas_runicas.scale_amount_max = 3.5
	particulas_runicas.color = Color(0.4, 0.95, 1.0, 0.85)
	particulas_runicas.position = Vector2(0, pos_y)
	particulas_runicas.z_index = 2
	add_child(particulas_runicas)

	# texto de runico em cima da cabeca
	tag_runico_label = Label.new()
	tag_runico_label.name = "TagRunico"
	tag_runico_label.text = "✦ RÚNICO ✦"
	tag_runico_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_runico_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tag_runico_label.add_theme_font_size_override("font_size", 10)
	tag_runico_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	tag_runico_label.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.15, 0.95))
	tag_runico_label.add_theme_constant_override("outline_size", 4)
	tag_runico_label.z_index = 10 # Garante que fique acima de sprites com z_index alto (ex: robôs z=4)

	var font_pixel = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf") as Font
	if font_pixel:
		tag_runico_label.add_theme_font_override("font", font_pixel)

	# Detecta o tipo de monstro para calibrar a altura exata da tag acima da cabeça
	var enemy_id: String = ""
	for child in get_children():
		if child.name == "EnemyTrigger":
			enemy_id = str(child.get("id_inimigo")).to_lower()
			break

	var eh_robo_g: bool = ("robo_g" in nome_baixo) or ("robo_g" in enemy_id)
	var eh_robo_p: bool = ("robo_p" in nome_baixo) or ("robo_p" in enemy_id) or ("robo" in nome_baixo) or ("robo" in enemy_id)
	var eh_wizard: bool = ("wizard" in nome_baixo) or ("wizzard" in nome_baixo) or ("wizard" in enemy_id)

	var tag_y: float = -38.0
	if eh_robo_g:
		tag_y = -105.0
	elif eh_robo_p:
		tag_y = -68.0
	elif eh_wizard:
		tag_y = -55.0
	else:
		tag_y = -38.0

	tag_runico_label.position = Vector2(-40, tag_y)
	tag_runico_label.size = Vector2(80, 16)
	add_child(tag_runico_label)

	var tw_tag = create_tween().set_loops().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw_tag.tween_property(tag_runico_label, "position:y", tag_y - 4.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw_tag.tween_property(tag_runico_label, "position:y", tag_y, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# 4. Brilho sutil no Sprite do próprio monstro
	if sprite:
		sprite.self_modulate = Color(1.15, 1.1, 1.3, 1.0)

func _process(delta: float) -> void:
	_animar_sombra(delta)

func _animar_sombra(delta: float) -> void:
	if not shadow or not is_instance_valid(shadow):
		return
	
	tempo_anim_sombra += delta
	if velocity.length() > 5.0:
		# Movimento / patrulha: squash & stretch suave acompanhando os passos/quiques
		var onda = sin(tempo_anim_sombra * 14.0)
		shadow.scale.x = shadow_base_scale.x + onda * (shadow_base_scale.x * 0.08)
		shadow.scale.y = shadow_base_scale.y - onda * (shadow_base_scale.y * 0.08)
	else:
		# Parado / pausa: respiração sutil
		var onda = sin(tempo_anim_sombra * 3.0)
		shadow.scale.x = shadow_base_scale.x + onda * (shadow_base_scale.x * 0.04)
		shadow.scale.y = shadow_base_scale.y + onda * (shadow_base_scale.y * 0.04)

# checa se o player ta ocupado com bau, dialogo ou tela
func _player_em_interacao(p_node: Node2D = null) -> bool:
	var pl = p_node if p_node else _player
	if pl and is_instance_valid(pl):
		if pl.has_method("esta_imune_a_combate"):
			if pl.esta_imune_a_combate():
				return true
		elif pl.has_method("esta_em_interacao"):
			if pl.esta_em_interacao():
				return true
		elif pl.get("travado") == true or pl.get("em_interacao") == true:
			return true
	if get_node_or_null("/root/QuizManager") and QuizManager.em_batalha:
		return true
	if get_node_or_null("/root/TransitionScreen") and TransitionScreen.is_transitioning:
		return true
	if get_tree():
		if get_tree().get_nodes_in_group("minigame_ativo").size() > 0:
			return true
		if get_tree().get_nodes_in_group("dialogo_ativo").size() > 0:
			return true
	return false

func _physics_process(delta: float) -> void:
	# Localiza o player dinamicamente se ainda não referenciado
	if not _player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_player = players[0]

	# Se o jogador estiver em uma interação (baú, minigame, diálogo), monstros ignoram e pausam o combate!
	if _player_em_interacao(_player):
		if _perseguindo:
			_perseguindo = false
			_sortear_nova_direcao()
		velocity = Vector2.ZERO
		move_and_slide()
		if sprite:
			sprite.play("default")
		return

	var no_alcance: bool = false
	if _player and is_instance_valid(_player):
		var distancia = global_position.distance_to(_player.global_position)
		if distancia <= distancia_perseguicao:
			no_alcance = true

	if no_alcance:
		if not _perseguindo:
			print("[Inimigo] Jogador avistado! Iniciando perseguição.")
			_perseguindo = true
			_em_pausa = false
		
		# Define a direção apontando para o player
		_direcao = (_player.global_position - global_position).normalized()
		velocity = _direcao * velocidade_perseguicao
	else:
		if _perseguindo:
			print("[Inimigo] Jogador perdeu-se de vista. Retornando à patrulha.")
			_perseguindo = false
			_sortear_nova_direcao()
		
		# Contagem regressiva de pausa (inimigo fica parado por um instante)
		if _em_pausa:
			_timer_pausa -= delta
			if _timer_pausa <= 0.0:
				_em_pausa = false
				_sortear_nova_direcao()
			velocity = Vector2.ZERO
			move_and_slide()
			if sprite:
				sprite.play("default")
			return

		# Contagem regressiva para trocar de direção
		_timer_direcao -= delta
		if _timer_direcao <= 0.0:
			# Chance de entrar em pausa antes de sortear nova direção
			if randf() < chance_pausa:
				_em_pausa     = true
				_timer_pausa  = randf_range(0.3, 0.8)
				velocity      = Vector2.ZERO
				move_and_slide()
				return
			_sortear_nova_direcao()

		# Move na direção atual da patrulha
		velocity = _direcao * velocidade

	# Atualiza a animação dependendo da direção
	if sprite:
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("walk_side"):
			if abs(_direcao.x) > abs(_direcao.y):
				sprite.play("walk_side")
				# A arte original (Y=0) do robô está olhando para a ESQUERDA.
				# Então para andar para a direita (> 0.0), precisamos virar (flip_h = true).
				sprite.flip_h = (_direcao.x > 0.0)
			elif _direcao.y > 0:
				sprite.play("walk_down")
			elif _direcao.y < 0:
				sprite.play("walk_up")
		else:
			# Lógica antiga para inimigos simples (Slime, etc)
			if _direcao.x != 0.0:
				sprite.flip_h = (_direcao.x < 0.0)

	move_and_slide()

	# Se tocou no jogador fisicamente durante o movimento, aciona a batalha imediatamente!
	var em_transicao = get_node_or_null("/root/TransitionScreen") and TransitionScreen.is_transitioning
	if not _em_batalha and not em_transicao and not _player_em_interacao(_player):
		for i in range(get_slide_collision_count()):
			var col = get_slide_collision(i)
			var collider = col.get_collider()
			if collider and (collider.is_in_group("player") or collider.name == "Player"):
				if _player_em_interacao(collider):
					continue
				var trigger = get_node_or_null("EnemyTrigger")
				if trigger and trigger.has_method("_on_body_entered"):
					trigger._on_body_entered(collider)
					return

	# se bateu na parede, sorteia outro rumo
	if not no_alcance and velocity.length() < 1.0 and not _em_pausa:
		_sortear_nova_direcao()

# escolhe outra direcao e reseta o tempo
func _sortear_nova_direcao() -> void:
	_direcao       = DIRECOES[randi() % DIRECOES.size()]
	_timer_direcao = randf_range(tempo_min_direcao, tempo_max_direcao)

# pausa ou volta a andar na batalha
func _on_batalha_iniciada(enemy_data: Dictionary) -> void:
	# para o monstro quando a batalha comeca
	_sou_o_combatente = (enemy_data.get("inimigo_node") == self)

	_em_batalha = true
	_em_pausa   = false
	velocity    = Vector2.ZERO
	set_physics_process(false)  # trava o bicho
	hide()                      # some da tela
	print("inimigo pausado por causa da batalha")

func _on_batalha_encerrada(vitoria: bool) -> void:
	if vitoria:
		if not _sou_o_combatente:
			# se ganhou de outro bicho, volto a andar
			_em_batalha = false
			show()
			set_physics_process(true)
			_sortear_nova_direcao()
			print("outro inimigo morreu, voltando a patrulhar")
	else:
		# se perdeu, todo mundo volta a patrulhar
		_em_batalha = false
		show()                      # volta o bicho
		set_physics_process(true)   # liga o movimento de novo
		_sortear_nova_direcao()
		print("player perdeu, voltando a patrulhar")

# controle de dano e morte
func sofrer_dano(quantidade: float) -> void:
	vida_atual = max(0.0, vida_atual - quantidade)
	print("dano no monstro: ", quantidade, " vida: ", vida_atual)

func derrotar() -> void:
	_dropar_itens()
	inimigo_derrotado.emit(global_position)
	queue_free()

func _dropar_itens() -> void:
	var enemy_id = ""
	for child in get_children():
		if child.name == "EnemyTrigger" or child is Area2D:
			if "id_inimigo" in child:
				enemy_id = str(child.id_inimigo)
				break

	var nome_baixo = name.to_lower()
	var enemy_id_lower = enemy_id.to_lower()
	if enemy_id_lower.is_empty():
		enemy_id_lower = nome_baixo

	var anim_sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var sf_path = ""
	if anim_sprite and anim_sprite.sprite_frames:
		sf_path = anim_sprite.sprite_frames.resource_path.to_lower()

	var is_quimica = enemy_id_lower.begins_with("slime") or ("slime" in nome_baixo) or ("slime" in sf_path)
	var is_fisica = enemy_id_lower.begins_with("robo") or ("robo" in nome_baixo) or ("robo" in sf_path)
	var is_boss_slime = is_quimica and (("boss" in enemy_id_lower) or ("roxo" in enemy_id_lower) or ("boss" in nome_baixo) or ("roxo" in nome_baixo) or ("boss_roxo" in sf_path))
	var is_boss = is_boss_slime or ("boss" in enemy_id_lower) or (enemy_id_lower == "robo_g") or ("boss" in nome_baixo)

	# boss roxo só dá moeda
	if is_boss_slime:
		_instanciar_drop("res://scenes/Entidades/ItemMoeda.tscn")
		_instanciar_drop("res://scenes/Entidades/ItemMoeda.tscn")
		_instanciar_drop("res://scenes/Entidades/ItemMoeda.tscn")
		if eh_runico:
			_instanciar_drop("res://scenes/Entidades/ItemMoeda.tscn")
		return

	# boss robo
	if is_boss:
		if is_fisica:
			_instanciar_drop("res://scenes/Entidades/ItemChip.tscn")
		_instanciar_drop("res://scenes/Entidades/ItemMoeda.tscn")
		_instanciar_drop("res://scenes/Entidades/ItemMoeda.tscn")
		if eh_runico:
			_instanciar_drop("res://scenes/Entidades/ItemMoeda.tscn")
		return

	# acha a cor certa do slime
	var cor_slime = "azul" 
	if ("verde" in enemy_id_lower) or ("verde" in nome_baixo) or ("slime_verde" in sf_path):
		cor_slime = "verde"
	elif ("laranja" in enemy_id_lower) or ("vermelho" in enemy_id_lower) or ("slime_g" in enemy_id_lower) or ("laranja" in nome_baixo) or ("vermelho" in nome_baixo) or ("slime_g" in nome_baixo) or ("slime_g" in sf_path):
		cor_slime = "vermelho"
	else:
		cor_slime = "azul"

	# dropa item e moeda
	if is_quimica:
		_instanciar_drop("res://scenes/Entidades/ItemFragmentoGelatina.tscn", {"cor": cor_slime})
		_instanciar_drop("res://scenes/Entidades/ItemMoeda.tscn")
	elif is_fisica:
		_instanciar_drop("res://scenes/Entidades/ItemChip.tscn")
		_instanciar_drop("res://scenes/Entidades/ItemMoeda.tscn")
	else:
		_instanciar_drop("res://scenes/Entidades/ItemMoeda.tscn")

	# bicho runico da mais moeda
	if eh_runico:
		_instanciar_drop("res://scenes/Entidades/ItemMoeda.tscn")
		_instanciar_drop("res://scenes/Entidades/ItemMoeda.tscn")

func _instanciar_drop(caminho: String, dados_custom: Dictionary = {}) -> void:
	var cena = load(caminho)
	if not cena: return
	var item = cena.instantiate()
	
	if dados_custom.has("cor") and item.has_method("configurar_cor"):
		item.configurar_cor(dados_custom["cor"])
	
	# joga o item um pouco longe do player
	var pos_alvo = global_position
	var dir = Vector2.RIGHT
	if _player and is_instance_valid(_player):
		var dir_player = (global_position - _player.global_position).normalized()
		var angulo_aleatorio = randf_range(-deg_to_rad(50.0), deg_to_rad(50.0))
		var dir_drop = dir_player.rotated(angulo_aleatorio)
		var distancia = randf_range(35.0, 65.0)
		pos_alvo = global_position + dir_drop * distancia
		dir = dir_drop
	else:
		var angle = randf() * TAU
		var dist = randf_range(65.0, 95.0)
		dir = Vector2.from_angle(angle)
		pos_alvo = global_position + dir * dist

	if caminho.ends_with("ItemChave.tscn"):
		# chave pula mais longe
		var dist = randf_range(55.0, 80.0)
		pos_alvo = global_position + dir * dist

	# nao deixa o item parar dentro da parede
	if is_inside_tree() and get_world_2d():
		var space_state = get_world_2d().direct_space_state
		if space_state:
			var query = PhysicsRayQueryParameters2D.create(global_position, pos_alvo, 1)
			var hit = space_state.intersect_ray(query)
			if hit and hit.has("position"):
				pos_alvo = hit["position"] - dir * 25.0

	var pai = get_parent()
	if pai:
		item.position = pai.to_local(pos_alvo)
		pai.call_deferred("add_child", item)
	else:
		item.global_position = pos_alvo
		call_deferred("add_child", item)

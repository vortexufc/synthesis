extends Area2D

# poca de acido (andar de quimica)
# da dano se o player pisar em cima

@export var dano: float = 15.0
@export var intervalo_dano: float = 1.2

var _player_dentro: Node2D = null
var _tempo_proximo_dano: float = 0.0

@onready var sprite_poca: Sprite2D = $SpritePoca
@onready var bolhas: CPUParticles2D = $Bolhas

func _ready() -> void:
	collision_layer = 0
	collision_mask = 15 # player
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	_gerar_visual_procedural()

func _gerar_visual_procedural() -> void:
	if sprite_poca and sprite_poca.texture:
		var tw = create_tween().set_loops()
		tw.tween_property(sprite_poca, "scale", Vector2(1.06, 0.96), 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(sprite_poca, "scale", Vector2(0.96, 1.05), 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		return

	# textura verde caso nao tenha sprite pronto
	var grad = Gradient.new()
	grad.colors = PackedColorArray([
		Color(0.25, 0.95, 0.20, 0.85),
		Color(0.12, 0.70, 0.35, 0.70),
		Color(0.35, 0.08, 0.55, 0.40),
		Color(0.0, 0.0, 0.0, 0.0)
	])
	grad.offsets = PackedFloat32Array([0.0, 0.45, 0.75, 1.0])
	
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 72
	tex.height = 48
	
	if sprite_poca:
		sprite_poca.texture = tex
		# deixa a poca pulsando de leve
		var tw = create_tween().set_loops()
		tw.tween_property(sprite_poca, "scale", Vector2(1.06, 0.96), 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(sprite_poca, "scale", Vector2(0.96, 1.05), 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _process(delta: float) -> void:
	if _player_dentro and is_instance_valid(_player_dentro):
		_tempo_proximo_dano -= delta
		if _tempo_proximo_dano <= 0.0:
			_tempo_proximo_dano = intervalo_dano
			_aplicar_dano_acido()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		_player_dentro = body
		_tempo_proximo_dano = intervalo_dano
		_aplicar_dano_acido()

func _on_body_exited(body: Node2D) -> void:
	if body == _player_dentro:
		_player_dentro = null

func _aplicar_dano_acido() -> void:
	if _player_dentro and is_instance_valid(_player_dentro):
		if _player_dentro.has_method("receber_dano"):
			_player_dentro.receber_dano(dano, 6.0, "Ácido Corrosivo")
		elif get_node_or_null("/root/PlayerStats"):
			PlayerStats.sofrer_dano(dano)
			
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("ui-2")
			
		# borbulha mais quando pisa
		if bolhas:
			bolhas.amount = 16
			bolhas.speed_scale = 1.6
			get_tree().create_timer(0.4).timeout.connect(func():
				if is_instance_valid(bolhas):
					bolhas.amount = 8
					bolhas.speed_scale = 1.0
			)

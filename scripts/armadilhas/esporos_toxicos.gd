extends Node2D

# cogumelo com esporos (andar de biologia)
# incha e solta veneno se o player chegar perto

@export var dano: float = 20.0
@export var tempo_recarga: float = 4.0

var _em_recarga: bool = false
var _player_perto: Node2D = null

@onready var corpo_fungo: Node2D = $CorpoFungo
@onready var sprite_chapeu: Sprite2D = $CorpoFungo/SpriteChapeu
@onready var nuvem_esporos: CPUParticles2D = $NuvemEsporos
@onready var area_gatilho: Area2D = $AreaGatilho

func _ready() -> void:
	if area_gatilho:
		area_gatilho.body_entered.connect(_on_body_entered)
		area_gatilho.body_exited.connect(_on_body_exited)
		
	_desenhar_fungo_procedural()
	_animar_respiracao()

func _desenhar_fungo_procedural() -> void:
	if sprite_chapeu and sprite_chapeu.texture:
		return
	# gradiente do cogumelo caso nao tenha sprite
	var grad = Gradient.new()
	grad.colors = PackedColorArray([
		Color(0.95, 0.85, 0.15, 0.95),
		Color(0.65, 0.15, 0.85, 0.90),
		Color(0.25, 0.05, 0.35, 0.80),
		Color(0.0, 0.0, 0.0, 0.0)
	])
	grad.offsets = PackedFloat32Array([0.0, 0.45, 0.85, 1.0])
	
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 36
	tex.height = 36
	
	if sprite_chapeu:
		sprite_chapeu.texture = tex

var _tween_respiracao: Tween

func _animar_respiracao() -> void:
	if _tween_respiracao and _tween_respiracao.is_running():
		_tween_respiracao.kill()
		
	if corpo_fungo:
		_tween_respiracao = create_tween().set_loops()
		_tween_respiracao.tween_property(corpo_fungo, "scale", Vector2(1.10, 0.92), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween_respiracao.tween_property(corpo_fungo, "scale", Vector2(0.95, 1.08), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		_player_perto = body
		if not _em_recarga:
			_disparar_esporos()

func _on_body_exited(body: Node2D) -> void:
	if body == _player_perto:
		_player_perto = null

func _disparar_esporos() -> void:
	if _em_recarga: return
	_em_recarga = true
	
	if _tween_respiracao and _tween_respiracao.is_running():
		_tween_respiracao.kill()
		
	# incha avisando que vai estourar
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui-1")
		
	var tw_infla = create_tween()
	tw_infla.tween_property(corpo_fungo, "scale", Vector2(1.45, 1.45), 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_infla.parallel().tween_property(sprite_chapeu, "modulate", Color(2.0, 1.8, 0.5), 0.30)
	
	await tw_infla.finished
	
	# solta as partículas de veneno
	if nuvem_esporos:
		nuvem_esporos.restart()
		nuvem_esporos.emitting = true
		
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui-2")
		
	# murcha depois de soltar
	var tw_murcha = create_tween()
	tw_murcha.tween_property(corpo_fungo, "scale", Vector2(0.5, 0.5), 0.20)
	tw_murcha.parallel().tween_property(sprite_chapeu, "modulate", Color(0.5, 0.5, 0.5, 0.5), 0.20)
	
	# da dano se o player tiver perto
	if _player_perto and is_instance_valid(_player_perto):
		if _player_perto.has_method("receber_dano"):
			_player_perto.receber_dano(dano, 8.0, "Esporos Tóxicos")
		elif get_node_or_null("/root/PlayerStats"):
			PlayerStats.sofrer_dano(dano)
			
	# espera um tempo pra brotar de novo
	await get_tree().create_timer(tempo_recarga).timeout
	
	# volta ao normal
	var tw_renasce = create_tween()
	tw_renasce.tween_property(corpo_fungo, "scale", Vector2.ONE, 0.50).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw_renasce.parallel().tween_property(sprite_chapeu, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.50)
	await tw_renasce.finished
	
	_em_recarga = false
	_animar_respiracao()
	
	# Se o jogador ainda estiver perto ao renascer, dispara de novo!
	if _player_perto:
		_disparar_esporos()

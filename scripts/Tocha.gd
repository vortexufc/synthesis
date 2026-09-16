extends Node2D

## Script da Tocha da Masmorra
## Executa a animação de chama viva e a cintilação dinâmica da luz.

@export var linha_frames: int = 0 # 0 para tocha de parede (Row 0), 2 para tocha de chão/poste (Row 2)
@export var cor_luz: Color = Color(1.0, 0.70, 0.35, 1.0)
@export var energia_base: float = 0.55
@export var escala_base: float = 1.55

var _sprite: Sprite2D = null
var _luz: PointLight2D = null
var _brasas: CPUParticles2D = null
var _tempo: float = 0.0
var _anim_timer: float = 0.0
var _offset: float = 0.0
var _velocidade: float = 8.0
var _frame_offset: int = 0

func _ready() -> void:
	add_to_group("tochas")
	_offset = randf() * 100.0
	_velocidade = randf_range(7.0, 12.0)
	_frame_offset = randi() % 7
	
	_sprite = get_node_or_null("Sprite2D")
	_luz = get_node_or_null("PointLight2D")
	_brasas = get_node_or_null("Brasas")
	
	if linha_frames == 2:
		# Tocha de poste/chão: a chama fica centralizada no topo
		if _luz:
			_luz.position = Vector2(0, -16)
		if _brasas:
			_brasas.position = Vector2(0, -18)
	elif linha_frames == 0:
		# Tocha de parede: a chama fica alinhada à bacia
		if _luz:
			_luz.position = Vector2(-12, -16)
		if _brasas:
			_brasas.position = Vector2(-12, -18)
			
	if _sprite:
		_sprite.frame = (linha_frames * 7) + _frame_offset
		
	if _luz:
		_luz.color = cor_luz
		_luz.energy = energia_base
		_luz.texture_scale = escala_base

func _process(delta: float) -> void:
	_tempo += delta
	_anim_timer += delta
	
	# 1. Animação suave dos frames da chama (ciclo de 7 frames)
	if _sprite and _anim_timer >= 0.11:
		_anim_timer = 0.0
		_frame_offset = (_frame_offset + 1) % 7
		_sprite.frame = (linha_frames * 7) + _frame_offset
		
	# 2. Flicker orgânico de chama tremeluzindo
	if _luz:
		var f1 = sin((_tempo + _offset) * _velocidade) * 0.03
		var f2 = sin((_tempo + _offset * 1.7) * (_velocidade * 1.5)) * 0.02
		var flicker = f1 + f2
		_luz.energy = energia_base + flicker

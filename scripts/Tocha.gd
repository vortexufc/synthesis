extends Node2D

## Script da Tocha da Masmorra
## Executa a animação de chama viva e a cintilação dinâmica da luz.

@export var cor_luz: Color = Color(1.0, 0.70, 0.35, 1.0)
@export var energia_base: float = 0.55
@export var escala_base: float = 1.55

var _sprite: Sprite2D = null
var _luz: PointLight2D = null
var _tempo: float = 0.0
var _anim_timer: float = 0.0
var _offset: float = 0.0
var _velocidade: float = 8.0

func _ready() -> void:
	add_to_group("tochas")
	_offset = randf() * 100.0
	_velocidade = randf_range(7.0, 12.0)
	
	_sprite = get_node_or_null("Sprite2D")
	_luz = get_node_or_null("PointLight2D")
	
	if _sprite:
		_sprite.frame = randi() % 7
		
	if _luz:
		_luz.color = cor_luz
		_luz.energy = energia_base
		_luz.texture_scale = escala_base

func _process(delta: float) -> void:
	_tempo += delta
	_anim_timer += delta
	
	# 1. Animação suave dos frames da chama (ciclo de 7 frames)
	if _sprite and _anim_timer >= 0.12:
		_anim_timer = 0.0
		_sprite.frame = (_sprite.frame + 1) % 7
		
	# 2. Flicker orgânico de chama tremeluzindo
	if _luz:
		var f1 = sin((_tempo + _offset) * _velocidade) * 0.03
		var f2 = sin((_tempo + _offset * 1.7) * (_velocidade * 1.5)) * 0.02
		var flicker = f1 + f2
		_luz.energy = energia_base + flicker
		_luz.texture_scale = escala_base + flicker * 0.05

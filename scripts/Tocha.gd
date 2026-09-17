extends Node2D

# tocha da masmorra com animacao e luz oscilando

@export var linha_frames: int = 0 # 0 = parede, 2 = chao
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
		# tocha de chao: centraliza a luz
		if _luz:
			_luz.position = Vector2(0, -16)
		if _brasas:
			_brasas.position = Vector2(0, -18)
	elif linha_frames == 0:
		# tocha de parede: alinha com o sprite
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
	
	# passa os frames da animacao
	if _sprite and _anim_timer >= 0.11:
		_anim_timer = 0.0
		_frame_offset = (_frame_offset + 1) % 7
		_sprite.frame = (linha_frames * 7) + _frame_offset
		
	# efeito da chama tremendo
	if _luz:
		var f1 = sin((_tempo + _offset) * _velocidade) * 0.03
		var f2 = sin((_tempo + _offset * 1.7) * (_velocidade * 1.5)) * 0.02
		var flicker = f1 + f2
		_luz.energy = energia_base + flicker

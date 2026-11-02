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

	var ps = get_node_or_null("/root/PlayerStats")
	if ps:
		if ps.has_method("is_modo_desempenho") and ps.is_modo_desempenho():
			if _brasas:
				_brasas.emitting = false
				_brasas.visible = false
		if ps.has_signal("modo_desempenho_alterado"):
			ps.modo_desempenho_alterado.connect(_on_modo_desempenho_alterado)

func _on_modo_desempenho_alterado(ativo: bool) -> void:
	if _brasas:
		_brasas.emitting = not ativo
		_brasas.visible = not ativo
	if _luz:
		_luz.energy = energia_base

var _luz_tick: float = 0.0

func _process(delta: float) -> void:
	_tempo += delta
	_anim_timer += delta
	
	# passa os frames da animacao
	if _sprite and _anim_timer >= 0.11:
		_anim_timer = 0.0
		_frame_offset = (_frame_offset + 1) % 7
		_sprite.frame = (linha_frames * 7) + _frame_offset
		
	if not _luz:
		return
		
	# Em modo desempenho, mantém a iluminação pontual estática (o sprite animado já dá o efeito visual de fogo)
	var ps = get_node_or_null("/root/PlayerStats")
	if ps and ps.has_method("is_modo_desempenho") and ps.is_modo_desempenho():
		if _luz.energy != energia_base:
			_luz.energy = energia_base
		return

	_luz_tick += delta
	if _luz_tick < 0.066: # Atualiza a ~15 Hz em vez de todo frame para economizar CPU/GPU
		return
	_luz_tick = 0.0
	
	# Simulação suave de chama (energia apenas, texture_scale mantido estático para não invalidar AABB no WebGL)
	var f1 = sin((_tempo + _offset) * _velocidade) * 0.048
	var f2 = sin((_tempo + _offset * 1.63) * (_velocidade * 1.85)) * 0.026
	var flicker = f1 + f2
	_luz.energy = maxf(0.25, energia_base + flicker)

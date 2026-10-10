@tool
extends Node2D

# luminaria da parede do andar de fisica
# suporta animacao dos 4 frames da nova textura lampada.png com oscilacao de energia e faiscas

enum Orientacao { NORTE = 0, OESTE = 1, LESTE = 2 }

@export var orientacao: Orientacao = Orientacao.NORTE:
	set(value):
		orientacao = value
		if is_node_ready():
			_aplicar_orientacao()

@export var cor_luz: Color = Color(0.72, 0.88, 1.0, 1.0):
	set(value):
		cor_luz = value
		if is_node_ready() and _luz:
			_luz.color = cor_luz

@export var energia_base: float = 1.05:
	set(value):
		energia_base = value
		if is_node_ready() and _luz:
			_luz.energy = energia_base

@export var escala_base: float = 2.2:
	set(value):
		escala_base = value
		if is_node_ready() and _luz:
			_luz.texture_scale = escala_base

@export var habilitar_flicker: bool = true

var _sprite: Sprite2D = null
var _luz: PointLight2D = null
var _faiscas: CPUParticles2D = null
var _tempo: float = 0.0
var _offset: float = 0.0
var _anim_timer: float = 0.0
var _frame_atual: int = 0
var _tempo_proximo_flicker: float = 0.0
var _duracao_flicker: float = 0.0

func _ready() -> void:
	add_to_group("luminarias_fisica")
	_sprite = get_node_or_null("Sprite2D")
	_luz = get_node_or_null("PointLight2D")
	_faiscas = get_node_or_null("Faiscas")
	
	_frame_atual = randi() % 4
	_aplicar_orientacao()
	
	if _luz:
		_luz.color = cor_luz
		_luz.energy = energia_base
		_luz.texture_scale = escala_base
		
	if Engine.is_editor_hint():
		return
		
	_offset = randf() * 50.0
	_tempo_proximo_flicker = randf_range(3.0, 8.0)

func atualizar_orientacao(nova_orientacao) -> void:
	var parsed: Orientacao = Orientacao.NORTE
	if nova_orientacao is int:
		parsed = nova_orientacao as Orientacao
	elif nova_orientacao is String:
		match nova_orientacao.to_lower():
			"oeste", "west", "esquerda":
				parsed = Orientacao.OESTE
			"leste", "east", "direita":
				parsed = Orientacao.LESTE
			_:
				parsed = Orientacao.NORTE
	orientacao = parsed

func _aplicar_orientacao() -> void:
	if not _sprite:
		_sprite = get_node_or_null("Sprite2D")
	if not _luz:
		_luz = get_node_or_null("PointLight2D")
	if not _faiscas:
		_faiscas = get_node_or_null("Faiscas")
		
	if _sprite:
		_sprite.region_enabled = false
		_sprite.hframes = 4
		_sprite.vframes = 1
		_sprite.frame = _frame_atual
		
		match orientacao:
			Orientacao.NORTE:
				_sprite.flip_h = false
				if _luz:
					_luz.position = Vector2(0, 8)
				if _faiscas:
					_faiscas.position = Vector2(0, 14)
					_faiscas.direction = Vector2(0, 1)
			Orientacao.OESTE:
				_sprite.flip_h = false
				if _luz:
					_luz.position = Vector2(4, 8)
				if _faiscas:
					_faiscas.position = Vector2(4, 14)
					_faiscas.direction = Vector2(0.3, 1)
			Orientacao.LESTE:
				_sprite.flip_h = true
				if _luz:
					_luz.position = Vector2(-4, 8)
				if _faiscas:
					_faiscas.position = Vector2(-4, 14)
					_faiscas.direction = Vector2(-0.3, 1)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_tempo += delta
	_anim_timer += delta
	
	# avança frames da lâmpada de forma suave
	if _anim_timer >= 0.13:
		_anim_timer = 0.0
		_frame_atual = (_frame_atual + 1) % 4
		if _sprite:
			_sprite.frame = _frame_atual

	if not _luz:
		return
		
	# leve oscilação na luz
	var zumbido = sin((_tempo + _offset) * 16.0) * 0.015 + sin((_tempo + _offset) * 32.0) * 0.008
	var energia_alvo = energia_base + zumbido
	
	# pisca de vez em quando dando impressão de falha elétrica
	if habilitar_flicker:
		if _duracao_flicker > 0.0:
			_duracao_flicker -= delta
			energia_alvo *= randf_range(0.35, 0.95)
			if _sprite and randf() < 0.35:
				_sprite.frame = randi() % 4
			if _faiscas and randf() < 0.15:
				_faiscas.emitting = true
		else:
			_tempo_proximo_flicker -= delta
			if _tempo_proximo_flicker <= 0.0:
				_tempo_proximo_flicker = randf_range(4.0, 10.0)
				_duracao_flicker = randf_range(0.08, 0.22)
				
	_luz.energy = energia_alvo

extends Area2D

# grade de choque (andar de fisica)
# fica alternando: desligado -> aviso -> choque

@export var dano: float = 25.0
@export var tempo_desligado: float = 2.2
@export var tempo_aviso: float = 0.7
@export var tempo_ativo: float = 1.3

enum Estado { DESLIGADO, AVISO, ATIVO }
var estado_atual: Estado = Estado.DESLIGADO
var _tempo_estado: float = 0.0
var _player_dentro: Node2D = null

@onready var painel_grade: Panel = $PainelGrade
@onready var faíscas: CPUParticles2D = $Faiscas
@onready var luz_aura: Sprite2D = $LuzAura

func _ready() -> void:
	collision_layer = 0
	collision_mask = 15
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	_estilizar_grade_procedural()
	_trocar_estado(Estado.DESLIGADO)

func _estilizar_grade_procedural() -> void:
	if painel_grade:
		var sb_existente = painel_grade.get_theme_stylebox("panel")
		if sb_existente is StyleBoxFlat:
			painel_grade.add_theme_stylebox_override("panel", sb_existente.duplicate())
		else:
			var sb = StyleBoxFlat.new()
			sb.bg_color = Color(0.12, 0.12, 0.18, 0.95)
			sb.border_width_left = 3
			sb.border_width_top = 3
			sb.border_width_right = 3
			sb.border_width_bottom = 3
			sb.border_color = Color(0.35, 0.4, 0.5, 0.9)
			sb.corner_radius_top_left = 4
			sb.corner_radius_top_right = 4
			sb.corner_radius_bottom_right = 4
			sb.corner_radius_bottom_left = 4
			painel_grade.add_theme_stylebox_override("panel", sb)

	if luz_aura and not luz_aura.texture:
		var grad = Gradient.new()
		grad.colors = PackedColorArray([
			Color(0.2, 0.9, 1.0, 0.65),
			Color(0.1, 0.4, 0.9, 0.35),
			Color(0.0, 0.0, 0.0, 0.0)
		])
		grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
		
		var tex = GradientTexture2D.new()
		tex.gradient = grad
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(0.5, 0.0)
		tex.width = 64
		tex.height = 64
		luz_aura.texture = tex

	if luz_aura:
		luz_aura.modulate.a = 0.0

func _process(delta: float) -> void:
	_tempo_estado -= delta
	if _tempo_estado <= 0.0:
		match estado_atual:
			Estado.DESLIGADO:
				_trocar_estado(Estado.AVISO)
			Estado.AVISO:
				_trocar_estado(Estado.ATIVO)
			Estado.ATIVO:
				_trocar_estado(Estado.DESLIGADO)

func _trocar_estado(novo: Estado) -> void:
	estado_atual = novo
	match novo:
		Estado.DESLIGADO:
			_tempo_estado = tempo_desligado
			faíscas.emitting = false
			if luz_aura: luz_aura.modulate.a = 0.0
			_atualizar_borda(Color(0.3, 0.35, 0.45), Color(0.10, 0.10, 0.15))
		Estado.AVISO:
			_tempo_estado = tempo_aviso
			faíscas.emitting = true
			faíscas.amount = 4
			faíscas.color = Color(1.0, 0.85, 0.2, 0.9) # faíscas amarelas avisando
			if luz_aura: luz_aura.modulate = Color(1.0, 0.8, 0.2, 0.25)
			_atualizar_borda(Color(1.0, 0.8, 0.2), Color(0.20, 0.18, 0.10))
			if get_node_or_null("/root/AudioManager"):
				AudioManager.play_sfx("ui-1")
		Estado.ATIVO:
			_tempo_estado = tempo_ativo
			faíscas.emitting = true
			faíscas.amount = 24
			faíscas.color = Color(0.3, 0.95, 1.0, 1.0) # choque azul
			if luz_aura: luz_aura.modulate = Color(0.2, 0.9, 1.0, 0.85)
			_atualizar_borda(Color(0.4, 0.95, 1.0), Color(0.12, 0.28, 0.40))
			if get_node_or_null("/root/AudioManager"):
				AudioManager.play_sfx("ui-3")
			# acertou quem tava em cima
			if _player_dentro:
				_aplicar_choque()

func _atualizar_borda(cor_borda: Color, cor_fundo: Color) -> void:
	if painel_grade:
		var sb = painel_grade.get_theme_stylebox("panel") as StyleBoxFlat
		if sb:
			sb.border_color = cor_borda
			sb.bg_color = cor_fundo

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		_player_dentro = body
		if estado_atual == Estado.ATIVO:
			_aplicar_choque()

func _on_body_exited(body: Node2D) -> void:
	if body == _player_dentro:
		_player_dentro = null

func _aplicar_choque() -> void:
	if _player_dentro and is_instance_valid(_player_dentro):
		if _player_dentro.has_method("receber_dano"):
			_player_dentro.receber_dano(dano, 10.0, "Sobrecarga Elétrica")
		elif get_node_or_null("/root/PlayerStats"):
			PlayerStats.sofrer_dano(dano)
			
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("ui-2")

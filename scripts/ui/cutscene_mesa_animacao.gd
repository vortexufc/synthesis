extends CanvasLayer

signal animacao_concluida

# Duração total da animação (aproximadamente 5 segundos)
@export var duracao_total: float = 5.0
@export var total_frames: int = 74
@export var tempo_fade: float = 0.35

@onready var container_geral: Control = $ContainerGeral
@onready var fundo_preto: ColorRect = $ContainerGeral/FundoPreto
@onready var sprite: Sprite2D = $ContainerGeral/SpriteAnimacao

var _tempo: float = 0.0
var _frame_atual: int = 0
var _finalizado: bool = false
var _som_magia_tocado: bool = false

func _ready() -> void:
	layer = 98 # Fica sob a UI de pular (layer 99) e sob o ParchmentUI (layer 100)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_ajustar_posicao()
	get_viewport().size_changed.connect(_ajustar_posicao)
	
	if sprite:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.frame = 0
		
	# Inicia escurecendo suavemente e exibindo a cena através do ContainerGeral (Control)
	if container_geral:
		container_geral.modulate.a = 0.0
		var tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(container_geral, "modulate:a", 1.0, tempo_fade)

func _ajustar_posicao() -> void:
	if not is_inside_tree():
		return
	var vp_size = get_viewport().get_visible_rect().size
	if container_geral:
		container_geral.size = vp_size
		container_geral.position = Vector2.ZERO
	if fundo_preto:
		fundo_preto.size = vp_size
		fundo_preto.position = Vector2.ZERO
	if sprite:
		sprite.position = vp_size / 2.0

func _process(delta: float) -> void:
	if _finalizado:
		return
		
	_tempo += delta
	var frame_idx = int((_tempo / duracao_total) * total_frames)
	
	# Quando o livro se abre e brilha magicamente (frame ~27), toca um sfx suave se disponível
	if not _som_magia_tocado and frame_idx >= 27:
		_som_magia_tocado = true
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("transicao-1")
	
	if frame_idx >= total_frames:
		frame_idx = total_frames - 1
		if sprite and sprite.frame != frame_idx:
			sprite.frame = frame_idx
		_concluir_animacao()
	elif frame_idx != _frame_atual:
		_frame_atual = frame_idx
		if sprite:
			sprite.frame = _frame_atual

func _concluir_animacao() -> void:
	if _finalizado:
		return
	_finalizado = true
	set_process(false)
	
	# Suave fade-out para revelar o jogo com o pergaminho aberto
	if container_geral:
		var tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_property(container_geral, "modulate:a", 0.0, tempo_fade)
		await tw.finished
		
	animacao_concluida.emit()
	queue_free()

func pular() -> void:
	if _finalizado:
		return
	_finalizado = true
	set_process(false)
	animacao_concluida.emit()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	# Permite pular se for executado isoladamente no F6
	if get_parent() == get_tree().root:
		if event.is_action_pressed("ui_select") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
			get_viewport().set_input_as_handled()
			pular()

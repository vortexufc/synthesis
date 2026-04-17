## [Trap-1] Armadilha: O Mímico (Baú Falso)
## Lore: Criado para punir aprendizes que buscam atalhos fáceis.
## Fluxo: player entra na área → travado → tremor + flash vermelho → -15% HP → libera.
extends Area2D

# Controla se a armadilha já foi ativada (dispara uma única vez)
var ja_ativado: bool = false

# Duração do tremor em segundos
@export var duracao_tremor: float = 0.5
# Intensidade do tremor (deslocamento em pixels)
@export var intensidade_tremor: float = 6.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Só ativa uma vez e só para o Player
	if ja_ativado:
		return
	if not body.name == "Player":
		return

	ja_ativado = true
	set_deferred("monitoring", false) # desativa colisão futura

	# Emite sinal global (pode ser ouvido pela HUD)
	GlobalSignals.mimico_ativado.emit(body)

	# Inicia a sequência assíncrona da armadilha
	_sequencia_mimico(body)

func _sequencia_mimico(player: Node2D) -> void:
	# 1) Trava o movimento do player
	player.travado = true

	# 2) Tremor + flash vermelho simultâneos (placeholder visual)
	_executar_tremor(player)
	_flash_vermelho(player)

	# 3) Aguarda a duração total do efeito
	await get_tree().create_timer(duracao_tremor + 0.15).timeout

	# 4) Aplica o dano de 15% HP e flash no sprite (definido no player)
	player.receber_dano_mimico()

	# 5) Libera o movimento após o flash de dano terminar
	await get_tree().create_timer(0.45).timeout
	player.travado = false

## Tremor: oscila a posição do player rapidamente
func _executar_tremor(player: Node2D) -> void:
	var pos_original: Vector2 = player.position
	var tween = create_tween()

	# Monta sequência de chacoalhadas
	var passos: int = int(duracao_tremor / 0.05)
	for i in passos:
		var offset := Vector2(
			randf_range(-intensidade_tremor, intensidade_tremor),
			randf_range(-intensidade_tremor * 0.5, intensidade_tremor * 0.5)
		)
		tween.tween_property(player, "position", pos_original + offset, 0.04)
	# Volta à posição original no fim
	tween.tween_property(player, "position", pos_original, 0.06)

## Flash vermelho: ColorRect vermelho semi-transparente sobre a tela
func _flash_vermelho(player: Node2D) -> void:
	# Cria o overlay vermelho como filho do CanvasLayer do player (ou da cena)
	var canvas := CanvasLayer.new()
	canvas.layer = 10 # acima de tudo
	var rect := ColorRect.new()
	rect.color = Color(1, 0, 0, 0.0)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(rect)
	player.add_child(canvas)

	# Fade in → fade out vermelho
	var tween = create_tween()
	tween.tween_property(rect, "color", Color(1, 0, 0, 0.45), 0.08)
	tween.tween_property(rect, "color", Color(1, 0, 0, 0.0), 0.35)
	await tween.finished

	# Remove o overlay da memória
	canvas.queue_free()

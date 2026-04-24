extends CanvasLayer

@onready var fill: ColorRect = $Control/HealthBarFill
@onready var text_label: Label = $Control/HealthText

func _ready() -> void:
	# liga a barra quando der play
	visible = true
	
	# seta a vida inicial
	atualizar_vida(PlayerStats.vida_atual_jogador, PlayerStats.vida_maxima_jogador)
	# atualiza a barra quando tomar dano ou curar
	PlayerStats.vida_alterada.connect(atualizar_vida)
	
	# esconde a barra na batalha
	GlobalSignals.iniciar_batalha.connect(func(): visible = false)
	GlobalSignals.batalha_encerrada.connect(func(): visible = true)

func atualizar_vida(atual: float, maxima: float) -> void:
	var pct = clamp(atual / maxima, 0.0, 1.0)
	
	var tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fill, "size:x", 200.0 * pct, 0.3)
	
	text_label.text = str(int(atual)) + " / " + str(int(maxima))

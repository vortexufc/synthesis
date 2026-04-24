extends CanvasLayer

signal resposta_escolhida(indice: int, tempo_usado: float)

@onready var label_pergunta: Label = $Control/FooterColor/MarginContainer/VBoxContainer/QuestionPanel/LabelQuestion
@onready var btn_a: Button = $Control/FooterColor/MarginContainer/VBoxContainer/HBoxButtons/BtnA
@onready var btn_b: Button = $Control/FooterColor/MarginContainer/VBoxContainer/HBoxButtons/BtnB
@onready var btn_c: Button = $Control/FooterColor/MarginContainer/VBoxContainer/HBoxButtons/BtnC
@onready var btn_d: Button = $Control/FooterColor/MarginContainer/VBoxContainer/HBoxButtons/BtnD
@onready var btn_e: Button = $Control/FooterColor/MarginContainer/VBoxContainer/HBoxButtons/BtnE
@onready var label_tempo: Label = $Control/TimerPainel/TextoTempo

@onready var health_player: ColorRect = $Control/HealthPlayer
@onready var health_enemy: ColorRect = $Control/HealthEnemy

var _botoes: Array = []
var tempo_restante: float = 300.0
var tempo_rodando: bool = false

func _ready() -> void:
	_botoes = [btn_a, btn_b, btn_c, btn_d, btn_e]
	for i in range(_botoes.size()):
		_botoes[i].pressed.connect(_on_botao_pressionado.bind(i))
		
	# se curar no inventario, arruma a barra verde
	PlayerStats.vida_alterada.connect(_on_vida_jogador_alterada)

func _on_vida_jogador_alterada(atual: float, maxima: float) -> void:
	var pct = atual / maxima
	var t = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(health_player, "size:x", max(0.0, 200.0 * pct), 0.5)

func _process(delta: float) -> void:
	if self.visible and tempo_rodando:
		tempo_restante -= delta
		if tempo_restante <= 0:
			tempo_restante = 0
			_on_botao_pressionado(-1) # errou por tempo
		
		var minutos = int(tempo_restante) / 60
		var segundos = int(tempo_restante) % 60
		label_tempo.text = "TEMPO:\n%02d:%02d" % [minutos, segundos]

func atualizar_pergunta(texto: String, alternativas: Array) -> void:
	self.show()
	tempo_rodando = true
	label_pergunta.text = texto
	
	for i in range(_botoes.size()):
		if i < alternativas.size():
			var prefix = ["A) ", "B) ", "C) ", "D) ", "E) "][i]
			_botoes[i].text = prefix + str(alternativas[i])
			_botoes[i].show()
			_botoes[i].disabled = false
		else:
			_botoes[i].hide()

func atualizar_vida(pct_player: float, pct_enemy: float) -> void:
	# tween de pausa senao a animacao nao toca
	var t = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	
	# tamanho do retangulo (200px / 230px)
	t.tween_property(health_player, "size:x", max(0.0, 200.0 * pct_player), 0.5)
	t.tween_property(health_enemy, "size:x", max(0.0, 230.0 * pct_enemy), 0.5)

func _on_botao_pressionado(indice: int) -> void:
	tempo_rodando = false # para o timer
	for btn in _botoes:
		btn.disabled = true
		
	resposta_escolhida.emit(indice, tempo_restante)

func ocultar_interface() -> void:
	self.hide()

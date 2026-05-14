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

# [Combat-4] O timer corre de forma contínua durante toda a batalha.
# tempo_restante só é (re)definido por iniciar_timer() — nunca em atualizar_pergunta().
var tempo_restante: float = 300.0
var tempo_rodando: bool = false
var _duracao_batalha: float = 300.0  ## Espelho da duração do inimigo (para exibição futura)
var _ultimo_botao_clicado: int = -1
var _tween_botoes: Tween

func _ready() -> void:
	# garante que os botoes funcionem mesmo com o jogo pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
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

# [Combat-4] Inicia o timer com a duração correta do inimigo.
# Deve ser chamado UMA ÚNICA VEZ por batalha, antes da primeira rodada.
func iniciar_timer(duracao: float) -> void:
	_duracao_batalha = duracao
	tempo_restante   = duracao
	tempo_rodando    = true

func atualizar_pergunta(texto: String, alternativas: Array) -> void:
	self.show()
	# [Combat-4] Retoma a contagem — NÃO reinicia tempo_restante (timer é contínuo por batalha)
	tempo_rodando = true
	label_pergunta.text = texto
	# Cancela o tween antigo das cores pra ele não sobreescrever o branco da nova pergunta
	if _tween_botoes:
		_tween_botoes.kill()
		
	for i in range(_botoes.size()):
		_botoes[i].modulate = Color.WHITE
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
	_ultimo_botao_clicado = indice
	tempo_rodando = false # para o timer
	for btn in _botoes:
		btn.disabled = true
		
	resposta_escolhida.emit(indice, tempo_restante)

func ocultar_interface() -> void:
	self.hide()

func mostrar_resultado(acertou: bool, idx_correto: int, valor: int) -> void:
	if _tween_botoes:
		_tween_botoes.kill()
		
	_tween_botoes = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	
	if idx_correto >= 0 and idx_correto < _botoes.size():
		# Pinta instantaneamente e segura a cor (ou anima bem rápido)
		_botoes[idx_correto].modulate = Color(0.2, 0.8, 0.2)
		_tween_botoes.tween_property(_botoes[idx_correto], "modulate", Color(0.2, 0.8, 0.2), 1.2)
		
	if not acertou and _ultimo_botao_clicado >= 0 and _ultimo_botao_clicado < _botoes.size():
		_botoes[_ultimo_botao_clicado].modulate = Color(0.9, 0.2, 0.2)
		_tween_botoes.tween_property(_botoes[_ultimo_botao_clicado], "modulate", Color(0.9, 0.2, 0.2), 1.2)
		
	var lbl = Label.new()
	if acertou:
		lbl.text = str(valor) + " DMG!"
		lbl.modulate = Color(0.2, 0.8, 0.2)
	else:
		if _ultimo_botao_clicado == -1:
			lbl.text = "Tempo!"
		else:
			lbl.text = "-" + str(valor) + " HP"
		lbl.modulate = Color(0.9, 0.2, 0.2)
		
	lbl.add_theme_font_size_override("font_size", 40)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 6)
	
	# Adiciona primeiro pra ter o tamanho e poder centralizar
	$Control.add_child(lbl)
	
	if acertou:
		# Texto saindo de cima do inimigo
		lbl.position = health_enemy.position + Vector2(50, -20)
	else:
		# Texto saindo de cima do player
		lbl.position = health_player.position + Vector2(0, -20)
		
	var t_lbl = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	t_lbl.tween_property(lbl, "position:y", lbl.position.y - 100, 1.2)
	t_lbl.tween_property(lbl, "modulate:a", 0.0, 1.2)
	t_lbl.chain().tween_callback(lbl.queue_free)

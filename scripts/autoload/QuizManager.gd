extends Node

var questions = []
var shuffled_questions = []
var current_index = 0

# Referências da Interface
var batalha_ui_cena = preload("res://scenes/ui/batalha_ui.tscn")
var game_over_cena = preload("res://scenes/ui/game_over.tscn")
var ui_instancia = null
var pergunta_atual = null

# Sinal que as outras tasks (ex: Combat-3) vão escutar!
signal resultado_batalha(acertou: bool)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS # Super importante para rodar no pause!
	randomize()
	
	# Instancia o Game Over na raiz do jogo para ele sempre existir
	var go_inst = game_over_cena.instantiate()
	add_child(go_inst)
	
	# Assina no sinal do banco de dados e Manda baixar as do Chão 1
	DatabaseManager.perguntas_recebidas.connect(_on_perguntas_chegaram)
	DatabaseManager.puxar_perguntas(1)
	
	# Escuta o sinal do NPC no mundo! (Task Combat-1 -> Combat-2 -> Combat-4)
	GlobalSignals.iniciar_batalha.connect(iniciar_batalha)

func _on_perguntas_chegaram(dados: Array) -> void:
	# Quando terminar o download na nuvem, salva na memória e prepara as variáveis
	questions = dados
	reset_questions()

func reset_questions():
	if questions.size() > 0:
		shuffled_questions = questions.duplicate()
		shuffled_questions.shuffle()
		current_index = 0

func shuffle_questions(q):
	var new_q = q.duplicate(true)
	var correct_answer = new_q["options"][new_q["answer"]]
	new_q["options"].shuffle()
	new_q["answer"] = new_q["options"].find(correct_answer)
	return new_q

func get_random_question():
	if current_index >= shuffled_questions.size():
		reset_questions() # Reseta pra nunca acabar as perguntas no protótipo
	var q = shuffled_questions[current_index]
	current_index += 1
	return shuffle_questions(q)

# ================================
# TASK COMBAT-2: FLUXO DE BATALHA COM HP
# ================================

# Variáveis do inimigo
var vida_maxima_inimigo: float = 100.0
var vida_atual_inimigo: float = 100.0

# [Combat-4] Dados do inimigo atual (definidos pelo EnemyTrigger da cena)
var _num_questoes: int = 5           ## Máximo de rodadas desta batalha
var _rodada_atual: int = 0           ## Contador de rodadas jogadas
var _duracao_batalha: float = 300.0  ## Duração total do timer (usado no cálculo de rapidez)

var _jogador_batalha: Node2D = null

var _acertos_batalha: int = 0
var _erros_batalha: int = 0
var _dano_causado: int = 0
var _tempo_inicio_batalha: float = 0

func iniciar_batalha(enemy_data: Dictionary = {}) -> void:
	if questions.size() == 0:
		print("Aguardando download do banco de dados das perguntas...")
		await DatabaseManager.perguntas_recebidas

	# [Combat-4] Carrega os dados do inimigo (com fallback seguro)
	_num_questoes   = enemy_data.get("num_questoes",   5)
	_duracao_batalha = enemy_data.get("duracao_batalha", 300.0)
	_rodada_atual   = 0
	print("[Combat-4] Batalha: %d questões / %.0fs — Golem do Andar 1" % [_num_questoes, _duracao_batalha])

	_acertos_batalha = 0
	_erros_batalha = 0
	_dano_causado = 0
	_tempo_inicio_batalha = Time.get_ticks_msec()

	print("Batalha Iniciada! Congelando o tempo do mundo...")
	get_tree().paused = true
	
	# Apenas resetamos a vida do inimigo, a vida do jogador é persistente no PlayerStats
	vida_atual_inimigo = vida_maxima_inimigo
	
	if ui_instancia == null:
		ui_instancia = batalha_ui_cena.instantiate()
		add_child(ui_instancia)
		ui_instancia.resposta_escolhida.connect(_on_resposta_recebida)
		
	# Inseta o Modelo Verdeiro do Mago ali dentro da tela
	if is_instance_valid(_jogador_batalha):
		_jogador_batalha.queue_free()
	
	var jogador_cena = load("res://scenes/player.tscn")
	_jogador_batalha = jogador_cena.instantiate()
	# Arranca fora todo o cérebro/script do Boneco-Clone para ele virar um manequim animado! 
	_jogador_batalha.set_script(null)
	
	# Arranca a Câmera, Colisão e Áudio da cópia para ela não bagunçar a tela
	for child in _jogador_batalha.get_children():
		if child is Camera2D or child is CollisionShape2D or child is AudioStreamPlayer2D:
			child.queue_free()
	
	# Põe ele na UI e vira ele pra Direita (pra ele olhar pro Golem)
	ui_instancia.get_node("Control/PosicaoMago").call_deferred("add_child", _jogador_batalha)
	_jogador_batalha.get_node("sprite").call_deferred("play", "idle_direita")
	
	# Reinicia Barras visuais
	ui_instancia.atualizar_vida(1.0, 1.0)

	# [Combat-4] Inicia o timer com a duração do inimigo (não resetado entre rodadas)
	ui_instancia.iniciar_timer(_duracao_batalha)
	
	# Puxa o Rodada 1
	_nova_rodada()

func _nova_rodada() -> void:
	# [Combat-4] Verifica se atingiu o limite de rodadas do inimigo
	_rodada_atual += 1
	if _rodada_atual > _num_questoes:
		print("[Combat-4] Todas as %d questões respondidas. Batalha encerrada!" % _num_questoes)
		ui_instancia.ocultar_interface()
		
		var vitoria = (vida_atual_inimigo <= 0)
		var tempo_decorrido = (Time.get_ticks_msec() - _tempo_inicio_batalha) / 1000.0
		var precisao = 0
		if (_acertos_batalha + _erros_batalha) > 0:
			precisao = float(_acertos_batalha) / float(_acertos_batalha + _erros_batalha) * 100.0
		var stats = {
			"tempo": tempo_decorrido,
			"precisao": int(precisao),
			"dano": _dano_causado
		}
		
		GlobalSignals.batalha_encerrada.emit(vitoria)
		PlayerStats.salvar()
		GlobalSignals.fim_de_jogo.emit(vitoria, stats)
		return
	print("[Combat-4] Rodada %d / %d" % [_rodada_atual, _num_questoes])
	pergunta_atual = get_random_question()
	ui_instancia.atualizar_pergunta(pergunta_atual["question"], pergunta_atual["options"])

func _on_resposta_recebida(indice_botao: int, tempo_sobrando: float) -> void:
	var acertou = (indice_botao == pergunta_atual["answer"])
	
	var dano_final = 0
	
	if acertou:
		_acertos_batalha += 1
		# [Combat-4] Multiplicador de rapidez relativo à duração real da batalha do inimigo
		# (Dano Base = 10. Bonus Máximo = 25 extras pela velocidade de resposta)
		var rapidez = clamp(tempo_sobrando / _duracao_batalha, 0.0, 1.0)
		dano_final = 10 + int(25 * rapidez)
		vida_atual_inimigo -= dano_final
		_dano_causado += dano_final
		print("✅ VEREDITO: Certa! Dano crítico de %s! Sangue Golem: %s/100" % [dano_final, vida_atual_inimigo])
	else:
		_erros_batalha += 1
		dano_final = 25
		PlayerStats.sofrer_dano(dano_final)
		print("❌ VEREDITO: Errou/Pausou! Dano de %s em você! Sangue Mago: %s/100" % [dano_final, PlayerStats.vida_atual_jogador])
		
		# Feedback Visual de Dano no Mago
		if is_instance_valid(_jogador_batalha) and _jogador_batalha.has_node("sprite"):
			var sprite_mago = _jogador_batalha.get_node("sprite")
			# set_pause_mode evita que o tween paralise por conta do jogo pausado
			var tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tween.tween_property(sprite_mago, "modulate", Color.RED, 0.1)
			tween.tween_property(sprite_mago, "modulate", Color.WHITE, 0.1)
	
	resultado_batalha.emit(acertou)
	
	# Chama o feedback visual da task Combat-6
	ui_instancia.mostrar_resultado(acertou, pergunta_atual["answer"], dano_final)
	
	# Manda UI cortar os rects verde e vermelho para animar perda
	ui_instancia.atualizar_vida(PlayerStats.vida_atual_jogador/PlayerStats.vida_maxima_jogador, vida_atual_inimigo/vida_maxima_inimigo)
	
	# Espera o jogador ver a barra caindo (process_always=true pra funcionar com o jogo pausado)
	await get_tree().create_timer(1.2, true).timeout
	
	if PlayerStats.vida_atual_jogador <= 0 or vida_atual_inimigo <= 0:
		ui_instancia.ocultar_interface()
		
		var vitoria = (vida_atual_inimigo <= 0)
		var tempo_decorrido = (Time.get_ticks_msec() - _tempo_inicio_batalha) / 1000.0
		var precisao = 0
		if (_acertos_batalha + _erros_batalha) > 0:
			precisao = float(_acertos_batalha) / float(_acertos_batalha + _erros_batalha) * 100.0
		var stats = {
			"tempo": tempo_decorrido,
			"precisao": int(precisao),
			"dano": _dano_causado
		}
		
		GlobalSignals.batalha_encerrada.emit(vitoria)
		PlayerStats.salvar()
		GlobalSignals.fim_de_jogo.emit(vitoria, stats)
	else:
		_nova_rodada()

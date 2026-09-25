extends Node

var questions = []
var shuffled_questions = []
var current_index = 0
var ultima_sala_sorteada: String = ""

# questoes proprias desse inimigo (substituem o banco)
var _questoes_locais_ativas: Array = []
var perguntas_usadas: Array = []

# Referências da Interface
var batalha_ui_cena = preload("res://scenes/ui/batalha_ui.tscn")
var game_over_cena = preload("res://scenes/ui/game_over.tscn")
var ui_instancia = null
var pergunta_atual = null
var em_batalha: bool = false
var _processando_resposta: bool = false
var _inimigo_atual_id: String = ""
var _nivel_dificuldade_alvo: int = 0
var _eh_chefe_atual: bool = false
var _furia_chefe_executada: bool = false

var sprite_frames_inimigos = {
	"slime_p": preload("res://assets/sprites/Sprite Frames/slime_p.tres"),
	"slime_azul": preload("res://assets/sprites/Sprite Frames/slime_p.tres"),
	"slime_verde": preload("res://assets/sprites/Sprite Frames/slime_verde.tres"),
	"slime_laranja": preload("res://assets/sprites/Sprite Frames/slime_g.tres"),
	"slime_g": preload("res://assets/sprites/Sprite Frames/slime_g.tres"),
	"slime_boss_roxo": preload("res://assets/sprites/Sprite Frames/slime_boss_roxo.tres"),
	"slime_g_boss": preload("res://assets/sprites/Sprite Frames/slime_boss_roxo.tres"),
	# monstros do andar de fisica
	"robo_p_laranja": preload("res://assets/sprites/Sprite Frames/robo_p_laranja.tres"),
	"robo_p_amarelo":  preload("res://assets/sprites/Sprite Frames/robo_p_amarelo.tres"),
	"robo_p_ciano":    preload("res://assets/sprites/Sprite Frames/robo_p_ciano.tres"),
	"robo_g":          preload("res://assets/sprites/Sprite Frames/robo_g.tres"),
}

var sprite_frame_inimigo_atual

# perguntas de v ou f pro boss slime roxo
const QUESTOES_VF_SLIME_BOSS = [
	{
		"question": "A queima completa de um pedaço de carvão é uma transformação física, pois a matéria não altera sua composição química.",
		"options": ["Verdadeiro", "Falso"],
		"answer": 1,
		"dica": "A combustão é uma reação química: o carbono reage com O₂ formando gás carbônico (CO₂) e cinzas."
	},
	{
		"question": "Na Tabela Periódica, os elementos do Grupo 18 (Gases Nobres) são conhecidos por sua altíssima estabilidade química.",
		"options": ["Verdadeiro", "Falso"],
		"answer": 0,
		"dica": "Os gases nobres possuem a última camada eletrônica completa, conferindo estabilidade em condições normais."
	},
	{
		"question": "Soluções aquosas com pH menor que 7 a 25°C são classificadas como ácidas devido ao excesso de íons H⁺.",
		"options": ["Verdadeiro", "Falso"],
		"answer": 0,
		"dica": "Na escala de pH: abaixo de 7 indica acidez; exatamente 7 é neutro; acima de 7 é básico/alcalino."
	},
	{
		"question": "O ponto de fusão do gelo puro sob pressão atmosférica normal de 1 atm ocorre a 100°C.",
		"options": ["Verdadeiro", "Falso"],
		"answer": 1,
		"dica": "O ponto de fusão ocorre a 0°C. 100°C é a temperatura de ebulição (vaporização) da água pura."
	},
	{
		"question": "Segundo Lavoisier, em um sistema fechado a massa total dos reagentes é rigorosamente igual à massa total dos produtos.",
		"options": ["Verdadeiro", "Falso"],
		"answer": 0,
		"dica": "Lei da Conservação das Massas: na natureza nada se cria, nada se perde, tudo se transforma."
	},
	{
		"question": "O cloreto de sódio (sal de cozinha - NaCl) é formado predominantemente por ligações puramente metálicas.",
		"options": ["Verdadeiro", "Falso"],
		"answer": 1,
		"dica": "O NaCl é um composto iônico, formado pela atração eletrostática entre o cátion Na⁺ e o ânion Cl⁻."
	},
	{
		"question": "Reações químicas exotérmicas são aquelas que liberam calor e energia térmica para o ambiente externo.",
		"options": ["Verdadeiro", "Falso"],
		"answer": 0,
		"dica": "Reações exotérmicas liberam calor (ΔH < 0). Reações endotérmicas absorvem calor (ΔH > 0)."
	},
	{
		"question": "O átomo é composto por um núcleo denso (prótons e nêutrons) e uma eletrosfera onde orbitam os elétrons.",
		"options": ["Verdadeiro", "Falso"],
		"answer": 0,
		"dica": "Prótons (+) e nêutrons (neutros) ficam no núcleo; elétrons (-) circulam na eletrosfera."
	},
	{
		"question": "A mistura de água pura e óleo de cozinha forma uma solução homogênea monofásica estável.",
		"options": ["Verdadeiro", "Falso"],
		"answer": 1,
		"dica": "Água e óleo são líquidos imiscíveis e formam uma mistura heterogênea bifásica visível."
	},
	{
		"question": "A sublimação é a transição física direta do estado sólido para o estado gasoso sem passar pela fase líquida.",
		"options": ["Verdadeiro", "Falso"],
		"answer": 0,
		"dica": "Gelo seco (CO₂ sólido) e bolinhas de naftalina são exemplos clássicos de sublimação à temperatura ambiente."
	},
	{
		"question": "Um catalisador químico acelera a velocidade da reação porque é totalmente consumido no processo.",
		"options": ["Verdadeiro", "Falso"],
		"answer": 1,
		"dica": "Catalisadores NÃO são consumidos na reação. Eles agem reduzindo a energia de ativação necessária."
	},
	{
		"question": "Metais alcalinos do Grupo 1 (como Sódio e Potássio) reagem vigorosamente com a água liberando gás hidrogênio.",
		"options": ["Verdadeiro", "Falso"],
		"answer": 0,
		"dica": "Metais alcalinos reagem com grande liberação de energia, gerando H₂ inflamável e hidróxido."
	},
	{
		"question": "O gás oxigênio vital que os seres humanos respiram da atmosfera possui fórmula molecular O₃.",
		"options": ["Verdadeiro", "Falso"],
		"answer": 1,
		"dica": "O oxigênio gasoso respiratório é O₂. O₃ é o ozônio, gás da camada protetora na estratosfera."
	},
	{
		"question": "A neutralização entre ácido clorídrico (HCl) e hidróxido de sódio (NaOH) produz sal comum e água.",
		"options": ["Verdadeiro", "Falso"],
		"answer": 0,
		"dica": "Ácido forte + Base forte: HCl + NaOH → NaCl (sal) + H₂O (água)."
	},
	{
		"question": "O número atômico (Z) de qualquer elemento representa a quantidade de nêutrons presentes em seu núcleo.",
		"options": ["Verdadeiro", "Falso"],
		"answer": 1,
		"dica": "O número atômico (Z) representa o número de PRÓTONS no núcleo atômico."
	},
	{
		"question": "A condensação é a mudança de estado físico na qual o vapor ou gás passa para o estado líquido.",
		"options": ["Verdadeiro", "Falso"],
		"answer": 0,
		"dica": "Também chamada de liquefação, ocorre quando o vapor perde calor e retorna à fase líquida."
	},
	{
		"question": "A água pura (H₂O) é considerada uma substância simples por ser composta por um único tipo de molécula.",
		"options": ["Verdadeiro", "Falso"],
		"answer": 1,
		"dica": "A água é uma substância COMPOSTA, pois suas moléculas são formadas por dois elementos: H e O."
	},
	{
		"question": "Na ligação covalente, ocorre o compartilhamento mútuo de pares de elétrons entre átomos ligantes.",
		"options": ["Verdadeiro", "Falso"],
		"answer": 0,
		"dica": "Átomos ametais compartilham elétrons para atingirem a estabilidade eletrônica do octeto."
	},
	{
		"question": "A densidade de um material é calculada dividindo-se o seu volume pela sua massa (d = V / m).",
		"options": ["Verdadeiro", "Falso"],
		"answer": 1,
		"dica": "A relação matemática correta da densidade é a massa dividida pelo volume: d = m / V."
	},
	{
		"question": "O símbolo químico do Ouro na tabela periódica é 'Au', derivado da palavra em latim 'Aurum'.",
		"options": ["Verdadeiro", "Falso"],
		"answer": 0,
		"dica": "'Au' vem do latim aurum (brilhante/dourado). 'Ag' representa a prata (argentum)."
	}
]

var _eh_slime_boss_roxo: bool = false
var _dano_erro_inimigo: float = 25.0

# sinal de inicio da batalha
signal resultado_batalha(acertou: bool)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS # Super importante para rodar no pause!
	randomize()
	
	# deixa o game over pronto na cena
	var go_inst = game_over_cena.instantiate()
	add_child(go_inst)
	
	# escuta o banco e carrega as perguntas do andar 1
	# se for outro andar o enemy_data avisa
	_andar_atual = 1
	DatabaseManager.perguntas_recebidas.connect(_on_perguntas_chegaram)
	DatabaseManager.puxar_perguntas(_andar_atual)
	
	# escuta quando encostar no inimigo
	GlobalSignals.iniciar_batalha.connect(iniciar_batalha)

func _on_perguntas_chegaram(dados: Array) -> void:
	# salva as perguntas baixadas na memoria
	questions = dados
	reset_questions()

func reset_questions():
	# sorteia seed nova
	randomize()
	
	var base_list: Array = []
	if _questoes_locais_ativas.size() > 0:
		base_list = _questoes_locais_ativas.duplicate()
	else:
		base_list = questions.duplicate()
		
	# define a dificuldade de acordo com a sala e o tipo do bicho
	var target_nivel: int = 1
	var current_scene_path = ""
	if get_tree() and get_tree().current_scene:
		current_scene_path = get_tree().current_scene.scene_file_path
		
	if _nivel_dificuldade_alvo > 0:
		target_nivel = _nivel_dificuldade_alvo
	elif current_scene_path.to_lower().find("boss") != -1:
		target_nivel = 3
	else:
		# dificuldade de acordo com a sala:
		var sala_idx = DungeonGenerator.get_index_da_cena(current_scene_path)
		var total_salas = DungeonGenerator.percurso_salas.size()
		if sala_idx != -1:
			if total_salas > 8:
				# salas de fisica:
				# salas 1 a 4: nivel facil
				# salas 5 a 8: nivel medio
				# salas 9+: nivel dificil
				if sala_idx <= 4:
					target_nivel = 1
				elif sala_idx <= 8:
					target_nivel = 2
				else:
					target_nivel = 3
			else:
				# salas de quimica:
				# salas 1 a 3: facil (slime azul)
				# salas 4 a 5: medio (slime verde)
				# salas 6 a 7: dificil (slime laranja)
				# sala 8: boss final (slime roxo)
				if sala_idx <= 3:
					target_nivel = 1
				elif sala_idx <= 5:
					target_nivel = 2
				else:
					target_nivel = 3
		else:
			target_nivel = 1
		
	print("[QuizManager] Inimigo: %s | Sala: %s (index: %d) -> Dificuldade alvo TRI: %d" % [_inimigo_atual_id, current_scene_path.get_file(), DungeonGenerator.get_index_da_cena(current_scene_path), target_nivel])
	
	var disponiveis: Array = []
	for q in base_list:
		var q_text = q.get("question", "")
		var q_nivel = int(q.get("nivel_progresso", 1))
		if q_nivel == int(target_nivel) and q_text != "" and not (q_text in perguntas_usadas):
			disponiveis.append(q)
			
	# se acabaram as do nivel, pega qualquer outra que sobrou
	if disponiveis.size() == 0 and base_list.size() > 0:
		print("[QuizManager] Esgotadas as perguntas do nível %d. Buscando de outros níveis não usados." % target_nivel)
		for q in base_list:
			var q_text = q.get("question", "")
			if q_text != "" and not (q_text in perguntas_usadas):
				disponiveis.append(q)
				
	# se usou todas do andar, reseta a lista
	if disponiveis.size() == 0 and base_list.size() > 0:
		print("[QuizManager] Todas as perguntas do andar foram usadas. Resetando histórico total.")
		for q in base_list:
			perguntas_usadas.erase(q.get("question", ""))
		# tenta pegar do nivel certo de novo
		for q in base_list:
			var q_text = q.get("question", "")
			var q_nivel = int(q.get("nivel_progresso", 1))
			if q_nivel == int(target_nivel) and q_text != "" and not (q_text in perguntas_usadas):
				disponiveis.append(q)
		# se ainda tiver vazio pega qualquer uma
		if disponiveis.size() == 0:
			disponiveis = base_list.duplicate()
		
	# sorteia a ordem das perguntas
	if disponiveis.size() > 0:
		shuffled_questions = disponiveis
		shuffled_questions.shuffle()
		current_index = 0
		
	if get_tree() and get_tree().current_scene:
		ultima_sala_sorteada = get_tree().current_scene.scene_file_path

# organiza as perguntas de facil pra dificil e embaralha dentro de cada grupo
func _ordenar_por_progressao(lista: Array) -> Array:
	var grupos: Dictionary = {}
	for pergunta in lista:
		var nivel: int = pergunta.get("nivel_progresso", 1)
		if not grupos.has(nivel):
			grupos[nivel] = []
		grupos[nivel].append(pergunta)
	
	var resultado: Array = []
	var niveis_ordenados = grupos.keys()
	niveis_ordenados.sort()  # Garante ordem 1, 2, 3...
	for nivel in niveis_ordenados:
		var grupo = grupos[nivel].duplicate()
		grupo.shuffle()  # Variedade dentro do mesmo nível
		resultado.append_array(grupo)
	
	return resultado

func shuffle_questions(q):
	var new_q = q.duplicate(true)
	
	# se for V ou F, mantem verdadeiro na 0 e falso na 1
	if new_q.has("options") and new_q["options"].size() == 2:
		var opt0 = str(new_q["options"][0]).strip_edges().to_lower()
		var opt1 = str(new_q["options"][1]).strip_edges().to_lower()
		if (opt0.begins_with("verdadeiro") or opt0 == "v") and (opt1.begins_with("falso") or opt1 == "f"):
			return new_q
			
	var correct_answer = new_q["options"][new_q["answer"]]
	
	# modo dev: forca resposta A correta
	var dev_mgr = get_node_or_null("/root/DevManager")
	if dev_mgr and dev_mgr.DEV_MODE_ENABLED and dev_mgr.god_mode_resposta_a:
		new_q["options"].erase(correct_answer)
		new_q["options"].shuffle()
		new_q["options"].insert(0, correct_answer)
		new_q["answer"] = 0
		return new_q
		
	new_q["options"].shuffle()
	new_q["answer"] = new_q["options"].find(correct_answer)
	return new_q

# modo dev: mata o inimigo na hora
func derrotar_inimigo_atual() -> void:
	if _processando_resposta:
		return
	if ui_instancia != null and is_instance_valid(ui_instancia) and pergunta_atual != null:
		print("auto-win: vencendo monstro...")
		vida_atual_inimigo = 0
		_on_resposta_recebida(pergunta_atual["answer"], _duracao_batalha)

func get_random_question():
	if current_index >= shuffled_questions.size():
		reset_questions() # Reseta pra nunca acabar as perguntas no protótipo
	var q = shuffled_questions[current_index]
	current_index += 1
	
	# guarda o texto pra nao repetir a pergunta
	var q_text = q.get("question", "")
	if q_text != "" and not (q_text in perguntas_usadas):
		perguntas_usadas.append(q_text)
		
	return shuffle_questions(q)

# fluxo da batalha e barra de vida

# Variáveis do inimigo
var vida_maxima_inimigo: float = 100.0
var vida_atual_inimigo: float = 100.0

# dados do inimigo da luta atual
var _num_questoes: int = 5           # maximo de rodadas
var _rodada_atual: int = 0           # rodadas jogadas
var _duracao_batalha: float = 300.0  # tempo da batalha
var _andar_atual: int = 1            # andar atual (1=Bio, 2=Quim, 3=Fis)

var _jogador_batalha: Node2D = null

var _acertos_batalha: int = 0
var _erros_batalha: int = 0
var _dano_causado: int = 0
var _tempo_inicio_batalha: float = 0

func iniciar_batalha(enemy_data: Dictionary = {}) -> void:
	if em_batalha:
		print("[QuizManager] Batalha já está em andamento. Ignorando solicitação duplicada.")
		return
	if get_node_or_null("/root/TransitionScreen") and TransitionScreen.is_transitioning:
		print("[QuizManager] Ignorando início de batalha pois transição de cena está ativa.")
		return
	em_batalha = true

	# se o inimigo tiver questoes proprias ja inicia sem esperar o banco
	_questoes_locais_ativas = enemy_data.get("questoes_locais", [])

	# so espera o banco se nao tiver questoes locais
	if _questoes_locais_ativas.size() == 0 and questions.size() == 0:
		print("Aguardando download do banco de dados das perguntas...")
		await DatabaseManager.perguntas_recebidas

	# carrega informacoes do monstro
	_num_questoes    = enemy_data.get("num_questoes",    5)
	_duracao_batalha = enemy_data.get("duracao_batalha", 300.0)
	_rodada_atual    = 0

	# Determina o andar correto para a batalha com base na masmorra ativa ou na cena atual:
	# 1 = Química, 2 = Física, 3 = Biologia
	var novo_andar: int = 1
	var active_mat = ""
	if get_node_or_null("/root/DatabaseManager") and DatabaseManager.active_dungeon != "":
		active_mat = DatabaseManager.active_dungeon
	elif get_node_or_null("/root/DungeonGenerator") and DungeonGenerator.masmorra_retorno_hub != "":
		active_mat = DungeonGenerator.masmorra_retorno_hub
		
	var c_path = ""
	if get_tree() and get_tree().current_scene:
		c_path = get_tree().current_scene.scene_file_path.to_lower()
		
	if active_mat == "Biologia" or "biologia" in c_path or "estufa" in c_path:
		novo_andar = 3
	elif active_mat == "Física" or "fisica" in c_path or "física" in c_path or "oficina" in c_path:
		novo_andar = 2
	elif active_mat == "Química" or "alquimia" in c_path or "quimica" in c_path or "laborat" in c_path:
		novo_andar = 1
	else:
		var id_low_check = enemy_data.get("id_inimigo", "").to_lower()
		if "flor" in id_low_check or "cogumelo" in id_low_check or "planta" in id_low_check or "carnivora" in id_low_check:
			novo_andar = 3
		elif "robo" in id_low_check:
			novo_andar = 2
		elif "slime" in id_low_check:
			novo_andar = 1
		else:
			novo_andar = int(enemy_data.get("andar_id", 1))

	var id_do_inimigo: String = enemy_data.get("id_inimigo", "")
	_inimigo_atual_id = id_do_inimigo
	var id_lower = id_do_inimigo.to_lower()
	var nivel_explicit: int = int(enemy_data.get("nivel_dificuldade", 0))
	
	# checa se e boss
	_eh_chefe_atual = enemy_data.get("eh_boss", false)
	var cena_atual_str = c_path
	if not _eh_chefe_atual:
		if "boss" in id_lower or "roxo" in id_lower or id_lower == "robo_g" or "carnivora" in id_lower or "wizard" in id_lower or "boss" in cena_atual_str or "fisica12" in cena_atual_str or "física12" in cena_atual_str or "biologia04" in cena_atual_str:
			_eh_chefe_atual = true

	_furia_chefe_executada = false
	if _eh_chefe_atual:
		print("[QuizManager] 👑 BATALHA CONTRA CHEFE DETECTADA! (Fúria do Chefe armada para 50% HP)")
	
	if nivel_explicit > 0:
		_nivel_dificuldade_alvo = nivel_explicit
	elif "boss" in id_lower or "roxo" in id_lower or "robo_g" in id_lower or "wizard" in id_lower or _eh_chefe_atual:
		_nivel_dificuldade_alvo = 3
	elif "laranja" in id_lower or "vermelho" in id_lower or "vermelha" in id_lower or id_lower == "slime_g" or "slime_g_" in id_lower or "carnivora" in id_lower:
		_nivel_dificuldade_alvo = 3
	elif "verde" in id_lower or "ciano" in id_lower or "roxa" in id_lower:
		_nivel_dificuldade_alvo = 2
	elif "azul" in id_lower or "amarelo" in id_lower or "amarela" in id_lower or "cogumelo" in id_lower or "slime_p" in id_lower or "robo_p" in id_lower:
		_nivel_dificuldade_alvo = 1
	else:
		_nivel_dificuldade_alvo = 0

	# checa se e o boss slime roxo
	_eh_slime_boss_roxo = ("slime_boss" in id_lower) or ("roxo" in id_lower) or ("slime_g_boss" in id_lower) or (("boss" in cena_atual_str or "sala_boss" in cena_atual_str) and "slime" in id_lower)

	# ajusta vida do monstro e dano de erro
	vida_maxima_inimigo = float(enemy_data.get("vida_maxima", 100.0))
	_dano_erro_inimigo = float(enemy_data.get("dano", 25.0))
	
	if _eh_slime_boss_roxo:
		_eh_chefe_atual = true
		vida_maxima_inimigo = 130.0
		_dano_erro_inimigo = 30.0
		_num_questoes = 5
		print("[QuizManager] 🟣 BOSS SLIME ROXO DETECTADO! 130 HP, dano de 30 por erro e Fúria do Chefe armada com V ou F!")

	# Checa se as perguntas na memória pertencem ao andar correto:
	var precisa_recarregar: bool = (novo_andar != _andar_atual) or questions.is_empty()
	if not precisa_recarregar and questions.size() > 0:
		var q_andar = int(questions[0].get("andar_id", 0))
		if q_andar > 0 and q_andar != novo_andar:
			precisa_recarregar = true

	if _questoes_locais_ativas.size() > 0:
		# usa as questoes locais direto
		print("[Local] Batalha com questões locais (%d questões)" % _questoes_locais_ativas.size())
		reset_questions()
	elif precisa_recarregar:
		_andar_atual = novo_andar
		print("[QuizManager] Carregando perguntas do andar: %d (Masmorra: %s)" % [_andar_atual, active_mat])
		DatabaseManager.puxar_perguntas(_andar_atual)
		await DatabaseManager.perguntas_recebidas
		reset_questions()
	else:
		# se ja sorteou antes mantem as mesmas pra bater com as dicas
		var sala_atual = ""
		if get_tree() and get_tree().current_scene:
			sala_atual = get_tree().current_scene.scene_file_path
			
		if ultima_sala_sorteada != sala_atual:
			reset_questions()
		else:
			print("[QuizManager] As perguntas desta sala já haviam sido sorteadas pelo Pergaminho. Mantendo-as.")

	print("iniciando batalha, andar: ", _andar_atual)

	_acertos_batalha = 0
	_erros_batalha = 0
	_dano_causado = 0
	_tempo_inicio_batalha = Time.get_ticks_msec()

	print("Batalha Iniciada! Congelando o tempo do mundo...")
	get_tree().paused = true
	
	# reseta a vida do monstro
	vida_atual_inimigo = vida_maxima_inimigo
	
	# poe a animacao certa do monstro (prioriza sprite_frames fornecido pela cena da criatura)
	var enemy_id = enemy_data.get("id_inimigo", "slime_g")
	if enemy_data.has("sprite_frames") and enemy_data["sprite_frames"] != null:
		sprite_frame_inimigo_atual = enemy_data["sprite_frames"]
	else:
		sprite_frame_inimigo_atual = sprite_frames_inimigos.get(enemy_id, sprite_frames_inimigos["slime_g"])
	
	if not is_instance_valid(ui_instancia):
		ui_instancia = batalha_ui_cena.instantiate()
		add_child(ui_instancia)
		ui_instancia.resposta_escolhida.connect(_on_resposta_recebida)
	else:
		ui_instancia.show() # Garante que está visível se foi reciclada
		var anim_sprite = ui_instancia.get_node_or_null("Control/SpriteMonstro/AnimatedSprite2D")
		if anim_sprite and sprite_frame_inimigo_atual:
			anim_sprite.sprite_frames = sprite_frame_inimigo_atual
			anim_sprite.play("default")

	# passa o sprite pro painel de batalha
	var current_id = enemy_data.get("id_inimigo", "")
	if sprite_frame_inimigo_atual != null:
		ui_instancia.configurar_inimigo(sprite_frame_inimigo_atual, current_id)
		
	# cria o bonequinho do mago na tela de luta
	if is_instance_valid(_jogador_batalha):
		_jogador_batalha.queue_free()
	
	var jogador_cena = load("res://scenes/Entidades/player.tscn")
	_jogador_batalha = jogador_cena.instantiate()
	# tira o script da copia do player pra nao se mover 
	_jogador_batalha.set_script(null)
	
	# remove camera, colisao e audio pra nao bugar a visualizacao da tela
	for child in _jogador_batalha.get_children():
		if child is Camera2D or child is CollisionShape2D or child is AudioStreamPlayer2D:
			_jogador_batalha.remove_child(child)
			child.free()
	
	# poe o boneco na ui virado pra direita
	ui_instancia.get_node("Control/PosicaoMago").call_deferred("add_child", _jogador_batalha)
	_jogador_batalha.get_node("sprite").call_deferred("play", "idle_direita")
	
	# reseta as barras de vida
	ui_instancia.atualizar_vida(PlayerStats.vida_atual_jogador / PlayerStats.vida_maxima_jogador, 1.0)

	# se for campeao runico abre o minigame de ligar pares
	var eh_runico: bool = enemy_data.get("eh_runico", false)
	if eh_runico:
		print("[QuizManager] Inimigo Campeão Rúnico detectado! Iniciando Conexão Rúnica...")
		var minigame_cena = load("res://scenes/ui/ligar_pares_ui.tscn")
		if minigame_cena:
			var minigame = minigame_cena.instantiate()
			add_child(minigame)
			minigame.iniciar_conexao(_andar_atual)
			var quebrou = await minigame.conexao_concluida
			if quebrou:
				print("[QuizManager] Barreira Rúnica DESTRUÍDA! Golpe Crítico de 40 HP!")
				vida_atual_inimigo = max(10.0, vida_atual_inimigo - 40.0)
				_dano_causado += 40
				if is_instance_valid(ui_instancia):
					ui_instancia.atualizar_vida(PlayerStats.vida_atual_jogador / PlayerStats.vida_maxima_jogador, vida_atual_inimigo / vida_maxima_inimigo)
					var sprite_m = ui_instancia.get_node_or_null("Control/SpriteMonstro/AnimatedSprite2D")
					if sprite_m:
						var tw_hit = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
						tw_hit.tween_property(sprite_m, "modulate", Color(2.5, 0.4, 0.4), 0.12)
						tw_hit.tween_property(sprite_m, "modulate", Color.WHITE, 0.18)
				if get_node_or_null("/root/AudioManager"):
					AudioManager.play_sfx("acerto_1")
			else:
				print("[QuizManager] Barreira Rúnica repeliu o ataque! Descarga de 20 HP no Mago!")
				PlayerStats.sofrer_dano(20.0)
				if is_instance_valid(ui_instancia):
					ui_instancia.atualizar_vida(PlayerStats.vida_atual_jogador / PlayerStats.vida_maxima_jogador, vida_atual_inimigo / vida_maxima_inimigo)
					if is_instance_valid(_jogador_batalha) and _jogador_batalha.has_node("sprite"):
						var sprite_mago = _jogador_batalha.get_node("sprite")
						var tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
						tween.tween_property(sprite_mago, "modulate", Color.RED, 0.1)
						tween.tween_property(sprite_mago, "modulate", Color.WHITE, 0.1)

	# inicia o tempo da batalha
	if is_instance_valid(ui_instancia):
		ui_instancia.iniciar_timer(_duracao_batalha)
	
	# comeca a primeira rodada
	_nova_rodada()

func _nova_rodada() -> void:
	if not is_instance_valid(ui_instancia):
		print("[QuizManager] _nova_rodada cancelada: ui_instancia é nula ou foi fechada.")
		return
	_rodada_atual += 1
	print("rodada: ", _rodada_atual, " de ", _num_questoes)
	pergunta_atual = get_random_question()
	if pergunta_atual != null and is_instance_valid(ui_instancia):
		ui_instancia.atualizar_pergunta(pergunta_atual["question"], pergunta_atual["options"])

func fechar_ui_batalha() -> void:
	em_batalha = false
	_processando_resposta = false
	if is_instance_valid(ui_instancia):
		ui_instancia.queue_free()
	ui_instancia = null

func _on_resposta_recebida(indice_botao: int, tempo_sobrando: float) -> void:
	if _processando_resposta:
		return
	_processando_resposta = true

	var acertou = (indice_botao == pergunta_atual["answer"])
	var dano_final = 0
	
	# manda a resposta pro painel admin
	if pergunta_atual.has("id"):
		var data_resp = {
			"pergunta_id": int(pergunta_atual["id"]),
			"acertou": acertou,
			"andar_id": int(pergunta_atual.get("andar_id", 1)),
			"aluno_nick": DatabaseManager.user_nick
		}
		# requisicao em background
		DatabaseManager.request_async("/rest/v1/respostas", HTTPClient.METHOD_POST, data_resp)
	
	if acertou:
		var rapidez = clamp(tempo_sobrando / _duracao_batalha, 0.0, 1.0)
		dano_final = 20 + int(15 * rapidez)
	else:
		dano_final = int(_dano_erro_inimigo)
	
	resultado_batalha.emit(acertou)
	
	# espera terminar o feedback de erro
	if is_instance_valid(ui_instancia):
		await ui_instancia.mostrar_resultado(acertou, pergunta_atual["answer"], dano_final, pergunta_atual)
	
	if acertou:
		_acertos_batalha += 1
		vida_atual_inimigo -= dano_final
		_dano_causado += dano_final
		print("✅ VEREDITO: Certa! Dano de %s! Sangue Golem: %s/100" % [dano_final, vida_atual_inimigo])
	else:
		_erros_batalha += 1
		PlayerStats.sofrer_dano(dano_final)
		print("❌ VEREDITO: Errou/Pausou! Dano de %s em você! Sangue Mago: %s/100" % [dano_final, PlayerStats.vida_atual_jogador])
		
		# pisca feedback
		if is_instance_valid(_jogador_batalha) and _jogador_batalha.has_node("sprite"):
			var sprite_mago = _jogador_batalha.get_node("sprite")
			var tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tween.tween_property(sprite_mago, "modulate", Color.RED, 0.1)
			tween.tween_property(sprite_mago, "modulate", Color.WHITE, 0.1)
			
	# atualiza a barra de vida se o no existir
	if is_instance_valid(ui_instancia):
		ui_instancia.atualizar_vida(float(PlayerStats.vida_atual_jogador) / float(PlayerStats.vida_maxima_jogador), float(vida_atual_inimigo) / float(vida_maxima_inimigo))
	
	# tempinho antes da proxima questao
	await get_tree().create_timer(1.2, true).timeout
	
	if not is_instance_valid(ui_instancia):
		_processando_resposta = false
		return
	
	# quando a vida do boss cai abaixo de 50% ativa a furia
	if _eh_chefe_atual and not _furia_chefe_executada and vida_atual_inimigo <= (vida_maxima_inimigo * 0.5) and vida_atual_inimigo > 0 and PlayerStats.vida_atual_jogador > 0:
		_furia_chefe_executada = true
		await _executar_furia_do_chefe()

	if not is_instance_valid(ui_instancia):
		_processando_resposta = false
		return

	# A batalha de RPG só termina quando o HP de um dos dois combatentes é zerado!
	var combate_concluido = (PlayerStats.vida_atual_jogador <= 0 or vida_atual_inimigo <= 0)
	if combate_concluido:
		if is_instance_valid(ui_instancia):
			ui_instancia.ocultar_interface()
		
		var vitoria = (vida_atual_inimigo <= 0)
		var tempo_decorrido = (Time.get_ticks_msec() - _tempo_inicio_batalha) / 1000.0
		var precisao = 0
		if (_acertos_batalha + _erros_batalha) > 0:
			precisao = float(_acertos_batalha) / float(_acertos_batalha + _erros_batalha) * 100.0
		var stats = {
			"tempo": tempo_decorrido,
			"precisao": int(precisao),
			"dano": _dano_causado,
			"eh_boss": _eh_chefe_atual,
			"andar_id": _andar_atual
		}
		
		if vitoria:
			print("[Combate] Você venceu o quiz!")
		else:
			print("[Combate] Mago derrotado por falta de HP (HP zerado)!")
			
		_processando_resposta = false
		em_batalha = false
		GlobalSignals.batalha_encerrada.emit(vitoria)
		PlayerStats.salvar()
		
		# Só abre a tela de fim_de_jogo se foi vitória OU se o jogador realmente morreu (HP <= 0)!
		if vitoria or PlayerStats.vida_atual_jogador <= 0:
			GlobalSignals.fim_de_jogo.emit(vitoria, stats)
	else:
		_processando_resposta = false
		_nova_rodada()

func _executar_furia_do_chefe() -> void:
	print("[QuizManager] ⚡ FÚRIA DO CHEFE INICIADA! Vida do Chefe: %.1f/%.1f" % [vida_atual_inimigo, vida_maxima_inimigo])
	
	# pausa o tempo enquanto rola a furia
	if is_instance_valid(ui_instancia):
		ui_instancia.tempo_rodando = false
		
	var furia_cena = load("res://scenes/ui/furia_chefe_ui.tscn")
	if furia_cena:
		var furia_inst = furia_cena.instantiate()
		add_child(furia_inst)
		furia_inst.iniciar_furia(_andar_atual)
		var sucesso: bool = await furia_inst.furia_concluida
		
		if sucesso:
			print("[QuizManager] 🛡️ PARRY PERFEITO! O jogador rebateu o golpe com sucesso!")
			var dano_parry = 40.0
			vida_atual_inimigo = max(0.0, vida_atual_inimigo - dano_parry)
			_dano_causado += int(dano_parry)
			_acertos_batalha += 1
			
			if is_instance_valid(ui_instancia):
				ui_instancia.atualizar_vida(
					float(PlayerStats.vida_atual_jogador) / float(PlayerStats.vida_maxima_jogador),
					float(vida_atual_inimigo) / float(vida_maxima_inimigo)
				)
				ui_instancia.mostrar_feedback_critico_parry("PARRY PERFEITO! CHEFE ATORDIDO (-40 HP)!", true)
		else:
			print("[QuizManager] 💥 FALHA NA FÚRIA! O chefe desferiu o golpe devastador!")
			var dano_golpe_chefe = 30
			_erros_batalha += 1
			PlayerStats.sofrer_dano(dano_golpe_chefe)
			
			if is_instance_valid(ui_instancia):
				ui_instancia.atualizar_vida(
					float(PlayerStats.vida_atual_jogador) / float(PlayerStats.vida_maxima_jogador),
					float(vida_atual_inimigo) / float(vida_maxima_inimigo)
				)
				ui_instancia.mostrar_feedback_critico_parry("GOLPE DO CHEFE ACERTOU! DANO DEVASTADOR (-30 HP)!", false)
				
		# tempinho pro jogador ver o resultado
		await get_tree().create_timer(2.2, true).timeout
		
	# volta o tempo da batalha se ninguem morreu
	if is_instance_valid(ui_instancia) and vida_atual_inimigo > 0 and PlayerStats.vida_atual_jogador > 0:
		ui_instancia.tempo_rodando = true

func resetar_historico_perguntas() -> void:
	perguntas_usadas.clear()
	print("[QuizManager] Histórico de perguntas usadas resetado.")

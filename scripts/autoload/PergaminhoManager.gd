extends Node

## Autoload responsável por gerar anotações de estudo ricas, detalhadas e explicativas.
## Fornece explicações profundas sobre os conceitos das questões do andar, com suporte a rolagem.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

## Gera até 4 páginas de anotações extensas com explicações detalhadas sobre os conceitos.
func obter_paginas_dicas(andar_id: int = 1, questoes_custom: Array = [], num_paginas: int = 4) -> Array[String]:
	var paginas: Array[String] = []
	var max_paginas = clamp(num_paginas, 1, 4)
	
	var lista_questoes: Array = []
	if questoes_custom.size() > 0:
		lista_questoes = questoes_custom.duplicate()
	else:
		lista_questoes = DatabaseManager.carregar_perguntas_locais(andar_id)
		if lista_questoes.is_empty():
			lista_questoes = DatabaseManager.carregar_perguntas_locais(0)
		
	if lista_questoes.is_empty() and get_node_or_null("/root/QuizManager"):
		lista_questoes = QuizManager.questions.duplicate()
		
	lista_questoes.shuffle()
	var total_para_pegar = min(max_paginas, lista_questoes.size())
	
	for i in range(total_para_pegar):
		var q = lista_questoes[i]
		if q is Dictionary:
			var nota = _formatar_anotacao_detalhada(q, andar_id)
			paginas.append(nota)
			
	if paginas.is_empty():
		paginas = _gerar_anotacoes_extensas(andar_id)
		
	return paginas

func _formatar_anotacao_detalhada(q: Dictionary, andar_id: int) -> String:
	var pergunta = str(q.get("question", "")).strip_edges()
	var opcoes = q.get("options", [])
	var idx_correto = int(q.get("answer", 0))
	var resposta_correta = ""
	if idx_correto >= 0 and idx_correto < opcoes.size():
		resposta_correta = str(opcoes[idx_correto]).strip_edges()
		
	var titulo = _get_titulo_anotacao(andar_id)
	
	var texto = titulo + "\n\n"
	texto += "QUESTÃO DE ESTUDO:\n" + pergunta + "\n\n"
	texto += "ANÁLISE E EXPLICAÇÃO DO CONCEITO:\n"
	texto += _gerar_explicacao_conceitual(pergunta, resposta_correta, andar_id)
	
	return texto

func _gerar_explicacao_conceitual(pergunta: String, resposta: String, andar_id: int) -> String:
	var p_lower = pergunta.to_lower()
	var r_lower = resposta.to_lower()
	
	# Biologia
	if p_lower.contains("célula") or p_lower.contains("regenera") or p_lower.contains("divisão") or r_lower.contains("mitose"):
		return "A Mitose é o processo de divisão celular no qual uma célula-mãe diploide gera duas células-filhas geneticamente idênticas. Esse processo é fundamental para o crescimento do organismo, regeneração de tecidos feridos e reposição celular diária. É dividida nas fases: Prófase, Metáfase, Anáfase e Telófase."
	elif p_lower.contains(" slime") or p_lower.contains("fungo") or p_lower.contains("nutrição") or r_lower.contains("absorção"):
		return "Os fungos e certos seres unicelulares realizam a nutrição heterotrófica por absorção. Diferente dos animais que ingerem o alimento para digeri-lo internamente, eles lançam enzimas digestivas no meio externo para decompor a matéria orgânica e em seguida absorvem os nutrientes já simplificados."
	elif p_lower.contains("luz") or p_lower.contains("planta") or p_lower.contains("glicose") or r_lower.contains("cloroplasto"):
		return "O Cloroplasto é a organela vegetal encarregada da Fotossíntese. Ela contém clorofila, o pigmento capaz de captar a luz solar para converter dióxido de carbono e água em glicose e oxigênio gasoso, alimentando a cadeia alimentar."
	elif p_lower.contains("atp") or p_lower.contains("respiração") or r_lower.contains("mitocôndria"):
		return "A Mitocôndria é a usina energética da célula. Ela realiza a Respiração Celular aeróbica, consumindo glicose e oxigênio para sintetizar grandes quantidades de ATP (Adenosina Trifosfato), a moeda de energia utilizada em todas as reações metabólicas."
	elif p_lower.contains("proteína") or p_lower.contains("veneno") or r_lower.contains("ribossomo"):
		return "Os Ribossomos são estruturas celulares fundamentais responsáveis pela síntese de proteínas (Tradução). Eles leem as instruções codificadas no RNA mensageiro e unem os aminoácidos na ordem correta. Qualquer substância que paralise os ribossomos impede a produção proteica e interrompe a vida celular."
		
	# Química / Alquimia
	elif p_lower.contains("sódio") or p_lower.contains("água") or r_lower.contains("alcalino"):
		return "O Sódio (Na) pertence à família dos Metais Alcalinos (Grupo 1 da Tabela Periódica). Esses metais possuem apenas 1 elétron na camada de valência e tendem a doá-lo facilmente, reagindo de forma extremamente violenta ao entrar em contato com a água e liberando gás hidrogênio."
	elif p_lower.contains("hélio") or p_lower.contains("estável") or r_lower.contains("gases nobres"):
		return "Os Gases Nobres (Grupo 18) possuem a camada de valência completamente cheia (regra do octeto). Devido a essa estabilidade eletrônica natural, eles não têm tendência a ganhar ou perder elétrons, existindo na forma de gases monoatômicos que praticamente não reagem com outros elementos."
	elif p_lower.contains("pressão") or p_lower.contains("volume") or p_lower.contains("gás"):
		return "Pela Lei dos Gases Ideais e a Lei de Boyle (P * V = n * R * T), quando mantemos a temperatura constante em uma transformação isotérmica, a pressão e o volume são inversamente proporcionais. Se comprimirmos o gás dobrando sua pressão, seu volume será reduzido exatamente à metade."
	elif p_lower.contains("carbono") or p_lower.contains("grafite") or r_lower.contains("alotropia"):
		return "Alotropia é o fenômeno em que um mesmo elemento químico forma duas ou mais substâncias simples diferentes. O Carbono pode formar o Grafite (macio e condutor) ou o Diamante (extremamente duro e isolante), dependendo da organização cristalina dos seus átomos no espaço."
		
	# Física
	elif p_lower.contains("newton") or p_lower.contains("repouso") or r_lower.contains("inércia"):
		return "A Primeira Lei de Newton (Lei da Inércia) afirma que um corpo em repouso tende a permanecer em repouso, e um corpo em movimento retilíneo uniforme tende a continuar em movimento com velocidade constante, a menos que uma força resultante externa atue sobre ele mudando seu estado."
	elif p_lower.contains("peso") or p_lower.contains("massa") or p_lower.contains("gravidade"):
		return "Massa é a quantidade de matéria de um corpo (medida em kg) e não muda onde quer que ele esteja. Já o Peso é a força gravitacional exercida sobre essa massa (P = m * g), variando conforme a gravidade do local."
	elif p_lower.contains("velocidade") or p_lower.contains("tempo") or p_lower.contains("distância"):
		return "No Movimento Retilíneo Uniforme (MRU), a velocidade do objeto é constante e não nula. A velocidade média é definida pela variação do deslocamento dividida pelo intervalo de tempo decorrido (v = delta_s / delta_t)."
		
	# Fallback genérico explicativo
	if resposta != "":
		return "Para responder corretamente a esta questão, é fundamental recordar que o princípio científico analisado demonstra que o resultado correto é: " + resposta + ". Estude as relações entre as variáveis e a teoria envolvida."
	return "Estude detalhadamente as propriedades e princípios apresentados nas aulas teóricas para dominar este assunto."

func _get_titulo_anotacao(andar_id: int) -> String:
	match andar_id:
		3: return "Manuscrito de Biologia Celular e Ecologia"
		1: return "Tratado de Química e Alquimia Elemental"
		2: return "Compêndio de Física Clássica e Mecânica"
		_: return "Anotações do Mago Pesquisador"

func _gerar_anotacoes_extensas(andar_id: int) -> Array[String]:
	match andar_id:
		3: # Biologia
			return [
				"Manuscrito de Biologia Celular - Divisão Celular:\n\nA Mitose é o processo responsável pela multiplicação das células somáticas em organismos eucariontes. Durante a mitose, uma célula diploide (2n) passa pelas etapas de Prófase (condensação dos cromossomos e rompimento da carioteca), Metáfase (alinhamento dos cromossomos na placa equatorial), Anáfase (separação das cromátides-irmãs) e Telófase (reorganização dos núcleos e citocinese), originando duas células filhas exatamente idênticas entre si e à célula original.\n\nEsse processo garante a regeneração de tecidos lesionados e o crescimento dos indivíduos.",
				"Manuscrito de Biologia Celular - Organelas e Energia:\n\nA respiração celular aeróbica é realizada nas Mitocôndrias, onde a glicose e o oxigênio são processados para gerar água, gás carbônico e alta quantidade de ATP (Adenosina Trifosfato), que funciona como a moeda energética da célula.\n\nNas plantas e algas, a produção inicial da glicose ocorre nos Cloroplastos por meio da Fotossíntese. Já a produção e síntese de proteínas a partir da leitura do RNA mensageiro é realizada pelos Ribossomos.",
				"Manuscrito de Biologia - Nutrição e Ecologia:\n\nOs seres vivos dividem-se quanto à forma de nutrição em Autótrofos (produzem seu próprio alimento) e Heterótrofos (precisam consumir matéria orgânica).\n\nOs fungos e slimes executam nutrição heterotrófica por absorção: eles secretam enzimas digestivas para fora do corpo para quebrar a matéria orgânica no ambiente e depois absorvem os nutrientes simplificados.\n\nNa cadeia alimentar, toxinas que não são biodegradáveis acumulam-se em maior proporção nos níveis tróficos mais altos (Magnificação Trófica).",
				"Manuscrito de Biologia - Genética e Reprodução:\n\nO DNA (Ácido Desoxirribonucleico) possui estrutura em dupla hélice e armazena o código genético de todos os seres vivos. Para transmitir essa informação sem alteração, muitos seres unicelulares e bactérias realizam reprodução assexuada por Cissiparidade (ou divisão binária), dividindo-se simplesmente ao meio."
			]
		1: # Química / Alquimia
			return [
				"Tratado de Química - Tabela Periódica e Elementos:\n\nA Tabela Periódica organiza os elementos em ordem crescente de número atômico. Os elementos da mesma coluna (Família ou Grupo) possuem propriedades químicas semelhantes porque apresentam a mesma quantidade de elétrons na camada de valência.\n\nOs Metais Alcalinos (Grupo 1, como Sódio e Potássio) são extremamente reativos e reagem com a água liberando hidrogênio. Os Gases Nobres (Grupo 18, como Hélio e Neônio) possuem 8 elétrons de valência (ou 2 no caso do Hélio), sendo quimicamente inertes e estáveis.",
				"Tratado de Química - Transformações e Reações:\n\nAs transformações físicas alteram apenas o estado ou a forma da matéria (como a fusão da água ou evaporação), sem mudar a composição química. Já as transformações químicas alteram a natureza das substâncias, formando novas ligações e compostos.\n\nReações que LIBERAM calor para o meio ambiente são chamadas de Exotérmicas (ex: combustão da madeira ou reação do sódio). Reações que ABSORVEM calor são Endotérmicas.",
				"Tratado de Química - Estudo dos Gases Ideais:\n\nO comportamento dos gases é descrito pela equação de estado dos gases ideais: P * V = n * R * T, onde P é a pressão, V é o volume, n é o número de mols, R é a constante universal e T é a temperatura em Kelvin.\n\nEm uma transformação Isotérmica (temperatura constante), a pressão e o volume são inversamente proporcionais: se reduzirmos o volume pela metade, a pressão do gás dobrará.",
				"Tratado de Química - Alotropia e Ligações:\n\nAlotropia é a capacidade de um único elemento químico formar diferentes substâncias simples. O Carbono é o exemplo mais famoso: na forma de Grafite, os átomos organizam-se em lâminas hexagonais macias que conduzem eletricidade; na forma de Diamante, formam uma rede tetraédrica tridimensional extremamente dura e isolante."
			]
		2: # Física
			return [
				"Compêndio de Física - Dinâmica e Leis de Newton:\n\n1ª Lei de Newton (Lei da Inércia): Todo corpo permanece em seu estado de repouso ou de movimento retilíneo uniforme (MRU), a menos que seja compelido a mudar esse estado por forças resultantes impressas sobre ele.\n\n2ª Lei de Newton (Princípio Fundamental da Dinâmica): A força resultante sobre um corpo é igual ao produto de sua massa pela aceleração adquirida (F = m * a).\n\n3ª Lei de Newton (Ação e Reação): A toda ação corresponde uma reação de mesmo módulo, mesma direção e sentido oposto, atuando sempre em corpos diferentes.",
				"Compêndio de Física - Gravitação e Força Peso:\n\nMassa é uma propriedade intrínseca da matéria (medida em quilogramas) e representa a resistência de um corpo à aceleração. Ela é constante em qualquer ponto do universo.\n\nPeso é a força de atração gravitacional exercida por um planeta ou astro sobre a massa do corpo (P = m * g, medida em Newtons). A aceleração da gravidade na Terra é aproximadamente 9,8 m/s².",
				"Compêndio de Física - Cinemática:\n\nNo Movimento Retilíneo Uniforme (MRU), a velocidade do objeto permanece constante e a aceleração é zero. O deslocamento percorrido varia linearmente com o tempo: S = S0 + v * t.\n\nA velocidade média é calculada dividindo-se o espaço total percorrido pelo tempo total gasto no trajeto (v_media = delta_S / delta_t).",
				"Compêndio de Física - Energia e Conservação:\n\nA Energia Cinética é a energia associada ao movimento de um corpo (Ec = m * v² / 2). A Energia Potencial Gravitacional é a energia armazenada devido à altura do corpo em um campo gravitacional (Ep = m * g * h).\n\nNo sistema conservativo (sem atrito), a Energia Mecânica Total (Emec = Ec + Ep) permanece constante em todos os pontos da trajetória."
			]
		_:
			return [
				"Anotações do Mago Pesquisador:\n\nEstude atentamente as propriedades da matéria, os processos biológicos e as leis do movimento descritas nesta masmorra. O conhecimento fundamentado é o segredo para superar os exames arcanos.",
				"Anotações do Mago Pesquisador:\n\nRevise as anotações das salas anteriores e consulte seu Grimório sempre que precisar de orientação nas salas de combate."
			]
